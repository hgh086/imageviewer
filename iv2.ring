# use style 2
load "stdlibcore.ring"
load "libs/raylib/raylib.ring"
load "libs/tinyfd/tinyfd.ring"

sDir = "E:\mycode\ring\img"
imglist = []
nPos = 1
tex = NULL

winWidth = 1920
winHeight = 1080
offsetx = 0
offsety = 0
mmovex = 0
mmovey = 0
bFix = false
lastsecond = 0

def loadFirstImage 
	if Len(imglist) > 0
		nPos = 1
		if (tex != NULL) and (tex.width > 0)
			UnloadTexture(tex)
		end
		tex = LoadTexture(imglist[nPos])
		offsetx = 0
		offsety = 0
	end
end

def prevImage
	if Len(imglist) > 0
		if nPos > 1
			nPos = nPos - 1
			if (tex != NULL) and (tex.width > 0)
				UnloadTexture(tex)
			end
			tex = LoadTexture(imglist[nPos])
			offsetx = 0
			offsety = 0			
		end
	end
end

def nextImage
	if Len(imglist) > 0
		if nPos < Len(imglist)
			nPos = nPos + 1
			if (tex != NULL) and (tex.width > 0)
				UnloadTexture(tex)
			end
			tex = LoadTexture(imglist[nPos])
			offsetx = 0
			offsety = 0			
		end
	end
end

# main function is entrance
def main
	SetTraceLogLevel(4)
	InitWindow(winWidth, winHeight, "Image viewer using raylib")
	SetWindowState(FLAG_WINDOW_RESIZABLE)
	SetTargetFPS(60)
	lastsecond = GetTime()

	while !WindowShouldClose()
		# keyboard operation
		nKeyPress = GetKeyPressed()
		switch nKeyPress
		case KEY_A
			prevImage()
		case KEY_D
			nextImage()
		case KEY_F
			ToggleFullscreen()
		case KEY_M
			MaximizeWindow()
		case KEY_O
			# change directory
			tmpImages = find_image_file(sDir)
			parts = Split(tmpImages, ";")
			if (Len(parts) > 1) and (parts[1] != "")
				sDir = parts[1]
				imglist = []
				for i = 2 to Len(parts)
					sTmp = sDir + "\" + parts[i]
					Add(imglist, sTmp)
				end
				loadFirstImage()
			end
		case KEY_R
			RestoreWindow()
		case KEY_SPACE
			if bFix
				bFix = false
			else
				bFix = true
			end
		end
		# mouse drag
		if IsMouseButtonPressed(0) and (!bFix)
            mmovex = GetMouseX()
            mmovey = GetMouseY()
            SetMouseCursor(9)
		end
		if IsMouseButtonReleased(0) and (!bFix)
            if (mmovex > 0) and (mmovey > 0)
                offsetx = offsetx + GetMouseX() - mmovex
                offsety = offsety + GetMouseY() - mmovey
            end
            SetMouseCursor(0)
		end
		# mouse wheel
		if Len(imglist) > 0
			wheeloff = GetMouseWheelMove()
			if wheeloff > 0.0
				clockdelta = GetTime() - lastsecond
				lastsecond = GetTime()
				if clockdelta > 0.1 prevImage() end
			elseif wheeloff < 0.0
				clockdelta = GetTime() - lastsecond
                lastsecond = GetTime()
                if clockdelta > 0.1 nextImage() end
			end
		end
		# draw image or text
		winWidth = GetScreenWidth()
		winHeight = GetScreenHeight()
		BeginDrawing()
		ClearBackground(BLACK)
		if (tex != NULL) and (tex.width > 0)
			if bFix
                fScale = winWidth / tex.width
                newWidth = winWidth
                newHeight = tex.height * fScale
                if (newHeight > winHeight)
                    fScale = winHeight / tex.height
                    newHeight = winHeight
                    newWidth = tex.width * fScale
                end
                posxy = new Vector2((winWidth-newWidth)/2, (winHeight-newHeight)/2)
                DrawTextureEx(tex, posxy, 0, fScale, WHITE)
			else
				DrawTexture(tex, (winWidth-tex.width)/2 + offsetx, (winHeight-tex.height)/2 + offsety, WHITE)
			end
		else
			DrawText("No image to show", 50, 50, 20, WHITE)
			DrawText("A for prev image", 50, 80, 20, WHITE)
			DrawText("D for next image", 50, 110, 20, WHITE)
			DrawText("O for change folder", 50, 140, 20, WHITE)
			DrawText("F for toggle fullscreen", 50, 170, 20, WHITE)
			DrawText("M for maximize window", 50, 200, 20, WHITE)
			DrawText("R for restore window", 50, 230, 20, WHITE)
			DrawText("SPACE for toggle fix image size", 50, 260, 20, WHITE)
		end
		EndDrawing()
	end
	if tex != NULL
		if tex.width > 0
			UnloadTexture(tex)
		end
	end
	CloseWindow()
end
