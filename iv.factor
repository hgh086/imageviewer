! Imageviewer source

USING: kernel io math namespaces accessors prettyprint classes.struct alien alien.c-types alien.libraries
alien.syntax combinators sequences vectors splitting raylib ;
IN: pre-iv

<< "tinyfd" "tinyfd.dll" cdecl add-library >>
LIBRARY: tinyfd
FUNCTION: c-string tinyfd_findImageFile ( c-string aDefaultPath )

:: draw_loop ( -- )
    "E:\\mycode\\odin\\iv\\img" :> dirPath!
    128 <vector> :> imagelist
    0 :> currentPos!
    ! "001.png" load-texture :> tex!
    0 0 0 0 0 Texture2D <struct-boa> :> tex!
    get-time :> lastsecond!
    0 :> winWidth!
    0 :> winHeight!
    0 :> mmovex!
    0 :> mmovey!
    0 :> offsetx!
    0 :> offsety!
    f :> bFix!
    [
        ! keyboard operation
        get-key-pressed {
            { KEY_A [
                imagelist length 0 > [
                    currentPos 0 > [
                        currentPos 1 - currentPos!
                        tex width>> 0 > [ tex unload-texture ] when
                        dirPath "\\" currentPos imagelist nth 3append load-texture tex!
                        0 offsetx!
                        0 offsety!
                    ] when
                ] when
            ] }
            { KEY_D [
                imagelist length 0 > [
                    currentPos imagelist length 1 - < [
                        currentPos 1 + currentPos!
                        tex width>> 0 > [ tex unload-texture ] when
                        dirPath "\\" currentPos imagelist nth 3append load-texture tex!
                        0 offsetx!
                        0 offsety!
                    ] when
                ] when
            ] }
            { KEY_F [ toggle-fullscreen ] }
            { KEY_M [ maximize-window ] }
            { KEY_O [
                ! change directory
                dirPath tinyfd_findImageFile ";" split dup
                length 1 > [
                    dup 0 swap nth dirPath!
                    imagelist delete-all
                    0 swap remove-nth
                    [ imagelist push ] each
                    t
                ] when drop
                ! load first image
                imagelist length 0 > [
                    0 currentPos!
                    tex width>> 0 > [ tex unload-texture ] when
                    dirPath "\\" 0 imagelist nth 3append load-texture tex!
                    0 offsetx!
                    0 offsety!
                ] when
            ] }
            { KEY_R [ restore-window ] }
            { KEY_SPACE [ bFix not bFix! ] }
            [ drop ]
        } case
        ! mouse drag
        MOUSE_BUTTON_LEFT is-mouse-button-pressed bFix not and [
            get-mouse-x mmovex!
            get-mouse-y mmovey!
            MOUSE_CURSOR_RESIZE_ALL set-mouse-cursor
        ] when
        MOUSE_BUTTON_LEFT is-mouse-button-released bFix not and [
            get-mouse-x offsetx + mmovex - offsetx!
            get-mouse-y offsety + mmovey - offsety!
            MOUSE_CURSOR_DEFAULT set-mouse-cursor
        ] when
        ! mouse wheel
        imagelist length 0 > [
            get-mouse-wheel-move dup
            0 > [
                get-time lastsecond - 0.15 > [
                    imagelist length 0 > [
                        currentPos 0 > [
                            currentPos 1 - currentPos!
                            tex width>> 0 > [ tex unload-texture ] when
                            dirPath "\\" currentPos imagelist nth 3append load-texture tex!
                            0 offsetx!
                            0 offsety!
                        ] when
                    ] when
                ] when
                get-time lastsecond!
            ] when
            0 < [
                get-time lastsecond - 0.15 > [
                    imagelist length 0 > [
                        currentPos imagelist length 1 - < [
                            currentPos 1 + currentPos!
                            tex width>> 0 > [ tex unload-texture ] when
                            dirPath "\\" currentPos imagelist nth 3append load-texture tex!
                            0 offsetx!
                            0 offsety!
                        ] when
                    ] when
                ] when
                get-time lastsecond!
            ] when
        ] when
        ! draw ui
        get-screen-width winWidth!
        get-screen-height winHeight!
        begin-drawing
        BLACK clear-background
        tex width>> 0 > [
            bFix [
                winWidth tex width>> / :> fScale!
                winWidth :> newWidth!
                tex height>> fScale * :> newHeight!
                newHeight winHeight > [
                    winHeight tex height>> / fScale!
                    winHeight newHeight!
                    tex width>> fScale * newWidth!
                ] when
                winWidth newWidth - 2 / winHeight newHeight - 2 / Vector2 <struct-boa> :> iPos
                tex iPos 0 fScale WHITE draw-texture-ex
            ] [
                tex winWidth tex width>> - 2 / offsetx + winHeight tex height>> - 2 / offsety + WHITE draw-texture
            ] if
        ] [
            "No image to show" 50 50 20 WHITE draw-text
            "A for prev image" 50 80 20 WHITE draw-text
            "D for next image" 50 110 20 WHITE draw-text
            "O for change folder" 50 140 20 WHITE draw-text
            "F for toggle fullscreen" 50 170 20 WHITE draw-text
            "M for maximize window" 50 200 20 WHITE draw-text
            "R for restore window" 50 230 20 WHITE draw-text
            "SPACE for toggle fix image size" 50 260 20 WHITE draw-text
        ] if
        end-drawing
        window-should-close not
    ] loop
    tex width>> 0 > [ tex unload-texture ] when
    ;

: main ( -- )
    1920 1080 "Imageviewer test" init-window
    4  set-window-state
    60 set-target-fps
    draw_loop
    close-window
    ;

MAIN: main
