local ffi = require("ffi")
ffi.cdef[[
	typedef struct Color {
		unsigned char r;
		unsigned char g;
		unsigned char b;
		unsigned char a;
	} Color;
	typedef struct Vector2 {
		float x;
		float y;
	} Vector2;
	typedef struct Texture {
		unsigned int id;
		int width;
		int height;
		int mipmaps;
		int format;
	} Texture2D;
	typedef struct FilePathList {
		unsigned int capacity;
		unsigned int count;
		char **paths;
	} FilePathList;
	
	void InitWindow(int width, int height, const char *title);
	void CloseWindow(void);
	bool WindowShouldClose(void);
	void ClearBackground(Color color);
	void BeginDrawing(void);
	void EndDrawing(void);
	void DrawText(const char *text, int posX, int posY, int fontSize, Color color);
	void CloseWindow(void);
	Texture2D LoadTexture(const char *fileName);
	void UnloadTexture(Texture2D texture);
	void DrawTexture(Texture2D texture, int posX, int posY, Color tint);
	void DrawTextureEx(Texture2D texture, Vector2 position, float rotation, float scale, Color tint);
	FilePathList LoadDirectoryFilesEx(const char *basePath, const char *filter, bool scanSubdirs);
	void UnloadDirectoryFiles(FilePathList files);
	int GetKeyPressed(void);
	void SetWindowState(unsigned int flags);
	void ClearWindowState(unsigned int flags);
	void SetTargetFPS(int fps);
	void ToggleFullscreen(void);
	void MaximizeWindow(void);
	void RestoreWindow(void);
	int GetScreenWidth(void);
	int GetScreenHeight(void);
	void SetTraceLogLevel(int logLevel);
	float GetMouseWheelMove(void);
	bool IsMouseButtonPressed(int button);
	bool IsMouseButtonDown(int button);
	bool IsMouseButtonReleased(int button);
	bool IsMouseButtonUp(int button);
	int GetMouseX(void);
	int GetMouseY(void);
	void SetMouseCursor(int cursor);
	double GetTime(void);
	
	wchar_t * tinyfd_selectFolderDialogW(wchar_t const * aTitle, wchar_t const * aDefaultPath);
	char * tinyfd_utf16toMbcs(wchar_t const * aUtf16string);
	wchar_t * tinyfd_mbcsTo16(char const * aMbcsString);

]]

rl = ffi.load("raylib.dll")
tfd = ffi.load("tinyfd.dll")

clrWhite = ffi.new("Color", 255, 255, 255, 255) -- r, g, b, a
clrBlack = ffi.new("Color", 0, 0, 0, 255) -- r, g, b, a
clrRed = ffi.new("Color", 255, 0, 0, 255) -- r, g, b, a
tex = nil
fpl = nil
strImagePath = "E:\\mycode\\terra\\img"
currentPos = 0
winWidth = 1920
winHeight = 1080
offsetx = 0
offsety = 0
mmovex = 0
mmovey = 0

function changeDirectory()
	local ptrTmp = tfd.tinyfd_utf16toMbcs(tfd.tinyfd_selectFolderDialogW(nil, tfd.tinyfd_mbcsTo16(strImagePath)))
	if (ptrTmp ~= nil) then
		local strTmp = ffi.string(ptrTmp)
		if (fpl ~= nil) then
			rl.UnloadDirectoryFiles(fpl)
			fpl = nil
		end
		fpl = rl.LoadDirectoryFilesEx(strTmp, ".png;.jpg", false)
		strImagePath = strTmp
	end
end

function loadFirstImage()
    if (fpl.count > 0) then
        currentPos = 0
        if (tex ~= nil) and (tex.width > 0) then rl.UnloadTexture(tex) end
        local tmpFilename = ffi.string(fpl.paths[currentPos])
        tex = rl.LoadTexture(tmpFilename)
        offsetx = 0
        offsety = 0
    end
end

function prevImage()
    if (fpl.count > 0) then
    	if (currentPos > 0) then
			currentPos = currentPos - 1
			if (tex ~= nil) and (tex.width > 0) then rl.UnloadTexture(tex) end
			local tmpFilename = ffi.string(fpl.paths[currentPos])
			tex = rl.LoadTexture(tmpFilename)
			offsetx = 0
			offsety = 0
        end
    end
end

function nextImage()
    if (fpl.count > 0) then
    	if (currentPos < (fpl.count - 1)) then
			currentPos = currentPos + 1
			if (tex ~= nil) and (tex.width > 0) then rl.UnloadTexture(tex) end
			local tmpFilename = ffi.string(fpl.paths[currentPos])
			tex = rl.LoadTexture(tmpFilename)
			offsetx = 0
			offsety = 0
        end
    end
end

function main()
	local lastsecond = rl.GetTime()
	local bFix = false
	
	rl.SetTraceLogLevel(4)
	rl.InitWindow(winWidth, winHeight, "Image view by raylib")
	rl.SetWindowState(4) -- FLAG_WINDOW_RESIZABLE
	rl.SetTargetFPS(60)
	
	-- tex = rl.LoadTexture("img/001.png")
	while (not rl.WindowShouldClose()) do
		-- keyboard operation
		local nKeyPress = rl.GetKeyPressed()
		if nKeyPress == 65 then -- KEY_A
			prevImage()
		elseif nKeyPress == 68 then -- KEY_D
			nextImage()
		elseif nKeyPress == 70 then -- KEY_F
			rl.ToggleFullscreen()
		elseif nKeyPress == 77 then -- KEY_M
			rl.MaximizeWindow()
		elseif nKeyPress == 79 then -- KEY_O
			changeDirectory()
			loadFirstImage()
		elseif nKeyPress == 82 then -- KEY_R
			rl.RestoreWindow()
		elseif nKeyPress == 32 then -- KEY_SPACE
			if bFix then
				bFix = false
			else
				bFix = true
			end
		else
			-- do nothing
		end
		-- mouse drag
        if (rl.IsMouseButtonPressed(0) and (not bFix)) then
            mmovex = rl.GetMouseX()
            mmovey = rl.GetMouseY()
            rl.SetMouseCursor(9)
        end
        if (rl.IsMouseButtonReleased(0) and (not bFix)) then
            if ((mmovex > 0) and (mmovey > 0)) then
                offsetx = offsetx + rl.GetMouseX() - mmovex
                offsety = offsety + rl.GetMouseY() - mmovey
            end
            rl.SetMouseCursor(0)
        end
		-- mouse wheel
        if (fpl ~= nil) and (fpl.count > 0) then
            local wheeloff = rl.GetMouseWheelMove()
            if (wheeloff > 0.0) then
                local clockdelta = rl.GetTime() - lastsecond
                lastsecond = rl.GetTime()
                if (clockdelta > 0.12) then prevImage() end
            elseif (wheeloff < 0.0) then
                local clockdelta = rl.GetTime() - lastsecond
                lastsecond = rl.GetTime()
                if (clockdelta > 0.12) then nextImage() end
            end
        end
		-- draw ui
		winWidth = rl.GetScreenWidth()
		winHeight = rl.GetScreenHeight()
		rl.BeginDrawing()
		rl.ClearBackground(clrBlack)
		
		if (tex ~= nil) and (tex.width > 0) then
		    if (bFix) then
		        local fScale = winWidth / tex.width
                local newWidth = winWidth
                local newHeight = tex.height * fScale
                if (newHeight > winHeight) then
                    fScale = winHeight / tex.height
                    newHeight = winHeight
                    newWidth = tex.width * fScale
                end
                local iPos = ffi.new("Vector2")
                iPos.x = (winWidth-newWidth) / 2
                iPos.y = (winHeight-newHeight) / 2
                rl.DrawTextureEx(tex, iPos, 0.0, fScale, clrWhite)
		    else
                rl.DrawTexture(tex, (winWidth-tex.width)/2+offsetx, (winHeight-tex.height)/2+offsety, clrWhite)
            end
		else
            rl.DrawText("No image to show", 50, 50, 20, clrRed)
            rl.DrawText("A for prev image", 50, 80, 20, clrWhite)
            rl.DrawText("D for next image", 50, 110, 20, clrWhite)
            rl.DrawText("O for change folder", 50, 140, 20, clrWhite)
            rl.DrawText("F for toggle fullscreen", 50, 170, 20, clrWhite)
            rl.DrawText("M for maximize window", 50, 200, 20, clrWhite)
            rl.DrawText("R for restore window", 50, 230, 20, clrWhite)
            rl.DrawText("SPACE for toggle fix image size", 50, 260, 20, clrWhite)
		end
		
		rl.EndDrawing()
	end
	
	-- release tex and fpl
	if (tex ~= nil) then
		rl.UnloadTexture(tex)
		tex = nil
	end
	if (fpl ~= nil) then
		rl.UnloadDirectoryFiles(fpl)
		fpl = nil
	end
	
	rl.CloseWindow()
end

main()
