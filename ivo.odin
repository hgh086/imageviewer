// run command: odin run ivo.odin -file

package main

import "core:fmt"
import "core:strings"
import "core:dynlib"
import rl "vendor:raylib"

Symbols :: struct {
	findImageFile : proc "c" (cstring) -> cstring,
	utf8toMbcs : proc "c" (cstring) -> cstring,
	_my_lib_handle : dynlib.Library,
}

tex := rl.Texture {}
currentPos :i32 = 0
winWidth :i32 = 1920
winHeight :i32 = 1080
offsetx :i32 = 0
offsety :i32 = 0
mmovex :i32 = 0
mmovey :i32 = 0
imagepath : string = "D:\\"
imagelist : [dynamic]string

changeDirectory :: proc(s:Symbols) {
	sb1 := strings.builder_make()
	strings.write_string(&sb1, imagepath)
	strImages := string(s.findImageFile(s.utf8toMbcs(strings.to_cstring(&sb1))))
	parts := strings.split(strImages, ";")
	if (len(parts) > 1) {
		clear(&imagelist)
		imagepath = parts[0]
		for i in 1..<(len(parts)) {
			strTmp :string
			strTmp = strings.concatenate({imagepath , "\\" , parts[i]})
			append(&imagelist, strTmp)
		}
	}
}

loadFirstImage :: proc(s:Symbols) {
	if (len(imagelist) > 0) {
        currentPos = 0
        if (tex.width > 0) { rl.UnloadTexture(tex) }
        // solve chinese path problem, use utf8toMbcs
        sb1 := strings.builder_make()
        strings.write_string(&sb1, imagelist[currentPos])
        tex = rl.LoadTexture(s.utf8toMbcs(strings.to_cstring(&sb1)))
        offsetx = 0;
        offsety = 0;
    }
}

prevImage :: proc(s:Symbols) {
	if (len(imagelist) > 0) {
		if (currentPos > 0) {
			currentPos -= 1
			if (tex.width > 0) { rl.UnloadTexture(tex) }
			// solve chinese path problem, use utf8toMbcs
			sb1 := strings.builder_make()
			strings.write_string(&sb1, imagelist[currentPos])
			tex = rl.LoadTexture(s.utf8toMbcs(strings.to_cstring(&sb1)))
			offsetx = 0;
			offsety = 0;				
		}
    }
}

nextImage :: proc(s:Symbols) {
	if (len(imagelist) > 0) {
		if (currentPos < i32(len(imagelist) - 1)) {
			currentPos += 1
			if (tex.width > 0) { rl.UnloadTexture(tex) }
			// solve chinese path problem, use utf8toMbcs
			sb1 := strings.builder_make()
			strings.write_string(&sb1, imagelist[currentPos])
			tex = rl.LoadTexture(s.utf8toMbcs(strings.to_cstring(&sb1)))
			offsetx = 0;
			offsety = 0;
		}
	}
}

main :: proc() {
	// init data
	sym : Symbols
	tfd_path := "tinyfd.dll"
	count, ok := dynlib.initialize_symbols(&sym, tfd_path, "tinyfd_", "_my_lib_handle")
	defer dynlib.unload_library(sym._my_lib_handle)
	fmt.printf("load tinyfd.dll result:%v %v\n", count, ok)
	
    lastsecond :f64 = rl.GetTime()
    bFix :bool = false
    
    //rl.SetTraceLogLevel(rl.TraceLogLevel.NONE)
	rl.InitWindow(winWidth, winHeight, "Ray image viewer")
	wndstst := rl.ConfigFlags {rl.ConfigFlag.WINDOW_RESIZABLE, rl.ConfigFlag.WINDOW_TOPMOST}
	rl.SetWindowState(wndstst)
	rl.SetTargetFPS(60)
	
	// main loop
	for (!rl.WindowShouldClose()) {
		// keyboard operation
		nKeyPress := rl.GetKeyPressed()
		#partial switch nKeyPress {
			case rl.KeyboardKey.A :
				prevImage(sym)
			case rl.KeyboardKey.D :
				nextImage(sym)
			case rl.KeyboardKey.F :
				rl.ToggleFullscreen()
			case rl.KeyboardKey.M :
				rl.MaximizeWindow()
			case rl.KeyboardKey.O :
				changeDirectory(sym)
				loadFirstImage(sym)
			case rl.KeyboardKey.R :
				rl.RestoreWindow()
			case rl.KeyboardKey.SPACE :
                if (bFix) {
                    bFix = false;
                } else {
                    bFix = true;
                }
		}
	    // mouse drag
        if (rl.IsMouseButtonPressed(rl.MouseButton.LEFT) && !bFix) {
            mmovex = rl.GetMouseX();
            mmovey = rl.GetMouseY();
            rl.SetMouseCursor(rl.MouseCursor.RESIZE_ALL)
        }
        if (rl.IsMouseButtonReleased(rl.MouseButton.LEFT) && !bFix) {
            if ((mmovex > 0) && (mmovey > 0)) {
                offsetx = offsetx + rl.GetMouseX() - mmovex
                offsety = offsety + rl.GetMouseY() - mmovey
            }
            rl.SetMouseCursor(rl.MouseCursor.DEFAULT)
        }
        // mouse wheel
        if (len(imagelist) > 0) {
            wheeloff := rl.GetMouseWheelMove()
            clockdelta : f64
            if (wheeloff > 0) {
                clockdelta = rl.GetTime() - lastsecond
                lastsecond = rl.GetTime()
                if (clockdelta > 0.15) {
                    prevImage(sym)
                }
            } else if (wheeloff<0) {
                clockdelta = rl.GetTime() - lastsecond
                lastsecond = rl.GetTime()
                if (clockdelta > 0.15) {
                    nextImage(sym)
                }
            }
        }
	    // draw ui
        winWidth = rl.GetScreenWidth()
        winHeight = rl.GetScreenHeight()
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		if (tex.width > 0) {
		    if (bFix) {
		        fScale :f32
		        newWidth, newHeight : i32
		        fScale = f32(winWidth) / f32(tex.width)
                newWidth = winWidth
                newHeight = i32(f32(tex.height) * fScale)
                if (newHeight > winHeight) {
                    fScale = f32(winHeight) / f32(tex.height)
                    newHeight = winHeight
                    newWidth = i32(f32(tex.width) * fScale)
                }
                iPos := rl.Vector2 {}
                iPos.x = f32((winWidth-newWidth)/2)
                iPos.y = f32((winHeight-newHeight)/2)
                rl.DrawTextureEx(tex, iPos, 0.0, fScale, rl.WHITE)
		    } else {
                rl.DrawTexture(tex, (winWidth-tex.width)/2+offsetx, (winHeight-tex.height)/2+offsety, rl.WHITE)
            }
		} else {
            rl.DrawText("No image to show", 50, 50, 20, rl.RED)
            rl.DrawText("A for prev image", 50, 80, 20, rl.WHITE)
            rl.DrawText("D for next image", 50, 110, 20, rl.WHITE)
            rl.DrawText("O for change folder", 50, 140, 20, rl.WHITE)
            rl.DrawText("F for toggle fullscreen", 50, 170, 20, rl.WHITE)
            rl.DrawText("M for maximize window", 50, 200, 20, rl.WHITE)
            rl.DrawText("R for restore window", 50, 230, 20, rl.WHITE)
            rl.DrawText("SPACE for toggle fix image size", 50, 260, 20, rl.WHITE)
		}
		rl.EndDrawing()
	}
	if (tex.width > 0) { rl.UnloadTexture(tex) }
	rl.CloseWindow()
}
