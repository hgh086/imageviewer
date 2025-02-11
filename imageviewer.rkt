#lang racket

(require ffi/unsafe ffi/unsafe/define)
(define-ffi-definer define-raylib (ffi-lib "raylib"))
(define-ffi-definer define-tfdlib (ffi-lib "tinyfd"))

(define-cstruct _Texture ([id _uint] [width _int] [height _int] [mipmaps _int] [format _int]))
(define-cstruct _Vector2 ([x _float] [y _float]))

(define-raylib InitWindow (_fun _int _int _string -> _void))
(define-raylib CloseWindow (_fun -> _void))
(define-raylib WindowShouldClose (_fun -> _int))
(define-raylib ClearBackground (_fun _uint -> _void))
(define-raylib BeginDrawing (_fun -> _void))
(define-raylib EndDrawing (_fun -> _void))
;;(define-raylib LoadTexture (_fun _string -> _Texture)) 中文问题
(define-raylib LoadTexture (_fun _bytes -> _Texture))
(define-raylib UnloadTexture (_fun _Texture -> _void))
(define-raylib DrawText (_fun _string _int _int _int _uint -> _void))
(define-raylib DrawTexture (_fun _Texture _int _int _uint -> _void))
(define-raylib DrawTextureEx (_fun _Texture _Vector2 _float _float _uint -> _void))
(define-raylib GetKeyPressed (_fun -> _int))
(define-raylib SetWindowState (_fun _uint -> _void))
(define-raylib ClearWindowState (_fun _uint -> _void))
(define-raylib SetTargetFPS (_fun _int -> _void))
(define-raylib ToggleFullscreen (_fun -> _void))
(define-raylib MaximizeWindow (_fun -> _void))
(define-raylib RestoreWindow (_fun -> _void))
(define-raylib GetScreenWidth (_fun -> _int))
(define-raylib GetScreenHeight (_fun -> _int))
(define-raylib SetTraceLogLevel (_fun _int -> _void))
(define-raylib GetMouseWheelMove (_fun -> _float))
(define-raylib IsMouseButtonPressed (_fun _int -> _int))
(define-raylib IsMouseButtonDown (_fun _int -> _int))
(define-raylib IsMouseButtonReleased (_fun _int -> _int))
(define-raylib IsMouseButtonUp (_fun _int -> _int))
(define-raylib GetMouseX (_fun -> _int))
(define-raylib GetMouseY (_fun -> _int))
(define-raylib SetMouseCursor (_fun _int -> _void))
(define-raylib GetTime (_fun -> _double))

(define-tfdlib tinyfd_findImageFile (_fun _string -> _string))
;(define-tfdlib tinyfd_utf8toMbcs (_fun _string -> _string )) 中文问题
(define-tfdlib tinyfd_utf8toMbcs (_fun _string -> _bytes ))

(define disptex (make-Texture 0 0 0 0 0))
(define clrWhite #xffffffff)
(define clrBlack #xff000000)
(define clrRed #xff0000ff)

(define strImagePath "E:\\mycode\\racket\\img")
(define imglist (list ))
(define currentPos 0)
(define offsetx 0)
(define offsety 0)
(define mmovex 0)
(define mmovey 0)

(define lastsecond (GetTime))
(define bFix #f)

(define (changeDirectory)
    (define parts (string-split (tinyfd_findImageFile strImagePath) ";"))
    (cond 
        [(> (length parts) 1)
            (set! strImagePath (first parts))
            (map
                (lambda (ss1)
                    (string-append (string-append strImagePath "\\") ss1)
                )
                (filter
                    (lambda (ss2)
                        (not (string=? ss2 strImagePath))
                    )
                    parts
                )
            )
        ]
        [else
            (list )
        ]
    )
)

(define (changImage)
    (when (and (not (<  currentPos 0)) (< currentPos (length imglist)))
        ;; unload texture
        (when (> (Texture-width disptex) 0)
            (UnloadTexture disptex)
            (set-Texture-id! disptex 0)
            (set-Texture-width! disptex 0)
            (set-Texture-height! disptex 0)
            (set-Texture-mipmaps! disptex 0)
            (set-Texture-format! disptex 0)
        )
        ;; load image
        ;; (define tmptex (LoadTexture (list-ref imglist currentPos))) 中文问题
        (define tmptex (LoadTexture (tinyfd_utf8toMbcs (list-ref imglist currentPos))))
        (set-Texture-id! disptex (Texture-id tmptex))
        (set-Texture-width! disptex (Texture-width tmptex))
        (set-Texture-height! disptex (Texture-height tmptex))
        (set-Texture-mipmaps! disptex (Texture-mipmaps tmptex))
        (set-Texture-format! disptex (Texture-format tmptex))
        (set! offsetx 0)
        (set! offsety 0)
    )
)

;;(SetTraceLogLevel 4)
(InitWindow 1920 1080 "Image viewer by raylib")
(SetWindowState 4)
(SetTargetFPS 60)

;;main loop
(let loop ()
    (when (= (WindowShouldClose) 0)
        ;; keyboard operation
        (define nKeyPress (GetKeyPressed))
        (cond
            [(= nKeyPress 65)
                ;; prev image
                (when (> currentPos 0)
                    (set! currentPos (sub1 currentPos))
                    (changImage)
                )
            ]
            [(= nKeyPress 68)
                ;; next image
                (when (< currentPos (sub1 (length imglist)))
                    (set! currentPos (add1 currentPos))
                    (changImage)
                )
            ]
            [(= nKeyPress 70)
                (ToggleFullscreen)
            ]
            [(= nKeyPress 77)
                (MaximizeWindow)
            ]
            [(= nKeyPress 79)
                (set! imglist (changeDirectory))
                (set! currentPos 0)
                (changImage)
            ]
            [(= nKeyPress 82)
                (RestoreWindow)
            ]
            [(= nKeyPress 32)
                (set! bFix (not bFix))
            ]
        )
        ;; mouse drag
        (when (> (Texture-width disptex) 0)
            (when (and (= 1 (IsMouseButtonPressed 1)) (not bFix))
                (set! mmovex (GetMouseX))
                (set! mmovey (GetMouseY))
                (SetMouseCursor 9)
            )
            (when (and (= 1 (IsMouseButtonReleased 1)) (not bFix))
                (when (and (> mmovex 0) (> mmovey 0))
                    (set! offsetx (- (+ offsetx (GetMouseX)) mmovex))
                    (set! offsety (- (+ offsety (GetMouseY)) mmovey))
                )
                (SetMouseCursor 0)
            )
        )
        ;; mouse wheel
        (when (> (length imglist) 0)
            (define wheeloff (GetMouseWheelMove))
            (when (> wheeloff 0.0)
                (when (> (- (GetTime) lastsecond) 0.15)
                    ;; prev image
                    (when (> currentPos 0)
                        (set! currentPos (sub1 currentPos))
                        (changImage)
                    )
                )
                (set! lastsecond (GetTime))
            )
            (when (< wheeloff 0.0)
                (when (> (- (GetTime) lastsecond) 0.15)
                    ;; next image
                    (when (< currentPos (sub1 (length imglist)))
                        (set! currentPos (add1 currentPos))
                        (changImage)
                    )
                )
                (set! lastsecond (GetTime))
            )
        )
        ;; draw ui
        (BeginDrawing)
        (ClearBackground clrBlack)
        (when (> (Texture-width disptex) 0)
            (cond
                [bFix
                    ;; exact->inexact 将有理数转换为实数，才能转换为C语言类型
                    (define fScale (exact->inexact (/ (GetScreenWidth) (Texture-width disptex))))
                    (define newWidth (GetScreenWidth))
                    (define newHeight (round (* (Texture-height disptex) fScale)))
                    (when (> newHeight (GetScreenHeight))
                        (set! fScale (exact->inexact (/ (GetScreenHeight) (Texture-height disptex))))
                        (set! newHeight (GetScreenHeight))
                        (set! newWidth (round (* (Texture-width disptex) fScale)))
                    )
                    (define picpos (make-Vector2 (exact->inexact (/ (- (GetScreenWidth) newWidth) 2)) (exact->inexact (/ (- (GetScreenHeight) newHeight) 2))))
                    (DrawTextureEx disptex picpos 0.0 fScale clrWhite)
                ]
                [else
                    (define tmpx (+ (round (/ (- (GetScreenWidth) (Texture-width disptex)) 2)) offsetx))
                    (define tmpy (+ (round (/ (- (GetScreenHeight) (Texture-height disptex)) 2)) offsety))
                    (DrawTexture disptex tmpx tmpy clrWhite)
                ]
            )
        )
        (unless (> (Texture-width disptex) 0)
            (DrawText "No image to show" 100 50 20 clrRed)
            (DrawText "A for prev image" 100 80 20 clrWhite)
            (DrawText "D for next image" 100 110 20 clrWhite)
            (DrawText "O for change folder" 100 140 20 clrWhite)
            (DrawText "F for toggle fullscreen" 100 170 20 clrWhite)
            (DrawText "M for maximize window" 100 200 20 clrWhite)
            (DrawText "R for restore window" 100 230 20 clrWhite)
            (DrawText "SPACE for toggle fix image size" 100 260 20 clrWhite)
        )
        (EndDrawing)
        (loop)
    )
)
(when (> (Texture-width disptex) 0)
    (UnloadTexture disptex))
(CloseWindow)
