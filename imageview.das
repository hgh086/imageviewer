require dasbind
require daslib/strings_boost

struct Texture
    id :uint
    width :int
    height :int
    mipmaps :int
    format :int

struct Vector2
    x :float
    y :float

[extern(stdcall,name="Ray_InitWindow",library="raylib-wrapper")]
def InitWindow (w: int;h: int; title:string):void
    pass
[extern(stdcall,name="Ray_CloseWindow",library="raylib-wrapper")]
def CloseWindow :void
    pass
[extern(stdcall,name="Ray_WindowShouldClose",library="raylib-wrapper")]
def WindowShouldClose :bool
    return [[bool]]
[extern(stdcall,name="Ray_BeginDrawing",library="raylib-wrapper")]
def BeginDrawing:void
    pass
[extern(stdcall,name="Ray_EndDrawing",library="raylib-wrapper")]
def EndDrawing:void
    pass
[extern(stdcall,name="Ray_ClearBackground",library="raylib-wrapper")]
def ClearBackground (clr:uint):void
    pass
[extern(stdcall,name="Ray_DrawText",library="raylib-wrapper")]
def DrawText (txt:string; x: int;y: int; fsize:int; clr:uint):void
    pass
[extern(stdcall,name="Ray_LoadTexture",library="raylib-wrapper")]
def LoadTexture(txt: string) :Texture?
    return [[Texture?]]
[extern(stdcall,name="Ray_LoadTextureUtf8",library="raylib-wrapper")]
def LoadTextureUtf8(txt: string) :Texture?
    return [[Texture?]]
[extern(stdcall,name="Ray_UnloadTexture",library="raylib-wrapper")]
def UnloadTexture(tex: Texture?) :void
    pass
[extern(stdcall,name="Ray_DrawTexture",library="raylib-wrapper")]
def DrawTexture(tex: Texture?; posx: int;  posy: int; clr:uint) :void
    pass
[extern(stdcall,name="Ray_DrawTextureEx",library="raylib-wrapper")]
def DrawTextureEx(tex: Texture?; position: Vector2?; rotation: float;  scale: float; clr:uint) :void
    pass
[extern(stdcall,name="Ray_GetKeyPressed",library="raylib-wrapper")]
def GetKeyPressed :int
    return [[int]]
[extern(stdcall,name="Ray_SetWindowState",library="raylib-wrapper")]
def SetWindowState(flags: uint) :void
    pass
[extern(stdcall,name="Ray_ClearWindowState",library="raylib-wrapper")]
def ClearWindowState(flags: uint) :void
    pass
[extern(stdcall,name="Ray_SetTargetFPS",library="raylib-wrapper")]
def SetTargetFPS(fps: uint) :void
    pass
[extern(stdcall,name="Ray_ToggleFullscreen",library="raylib-wrapper")]
def ToggleFullscreen :void
    pass
[extern(stdcall,name="Ray_MaximizeWindow",library="raylib-wrapper")]
def MaximizeWindow :void
    pass
[extern(stdcall,name="Ray_RestoreWindow",library="raylib-wrapper")]
def RestoreWindow :void
    pass
[extern(stdcall,name="Ray_GetScreenWidth",library="raylib-wrapper")]
def GetScreenWidth :int
    return [[int]]
[extern(stdcall,name="Ray_GetScreenHeight",library="raylib-wrapper")]
def GetScreenHeight :int
    return [[int]]
[extern(stdcall,name="Ray_GetMouseWheelMove",library="raylib-wrapper")]
def GetMouseWheelMove :float
    return [[float]]
[extern(stdcall,name="Ray_IsMouseButtonPressed",library="raylib-wrapper")]
def IsMouseButtonPressed(button: int) :bool
    return [[bool]]
[extern(stdcall,name="Ray_IsMouseButtonDown",library="raylib-wrapper")]
def IsMouseButtonDown(button: int) :bool
    return [[bool]]
[extern(stdcall,name="Ray_IsMouseButtonReleased",library="raylib-wrapper")]
def IsMouseButtonReleased(button: int) :bool
    return [[bool]]
[extern(stdcall,name="Ray_IsMouseButtonUp",library="raylib-wrapper")]
def IsMouseButtonUp(button: int) :bool
    return [[bool]]
[extern(stdcall,name="Ray_GetMouseX",library="raylib-wrapper")]
def GetMouseX :int
    return [[int]]
[extern(stdcall,name="Ray_GetMouseY",library="raylib-wrapper")]
def GetMouseY :int
    return [[int]]
[extern(stdcall,name="Ray_SetMouseCursor",library="raylib-wrapper")]
def SetMouseCursor(fps: int) :void
    pass
[extern(stdcall,name="Ray_SetTraceLogLevel",library="raylib-wrapper")]
def SetTraceLogLevel(fps: int) :void
    pass
[extern(stdcall,name="Ray_GetTime",library="raylib-wrapper")]
def GetTime :double
    return [[double]]
[extern(stdcall,name="tinyfd_findImageFile",library="tinyfd")]
def FindImageFile(dirname: string) :string
    return [[string]]

def ChangeImage(images:array<string>; pos:int; var rettex: Texture&)
    if (pos < 0) || (pos >= images.length())
        return
    if rettex.width > 0
        UnloadTexture(unsafe(addr(rettex)))
    //var ptex= LoadTexture(images[pos])
    var ptex= LoadTextureUtf8(images[pos])
    rettex.id = ptex.id
    rettex.width = ptex.width
    rettex.height = ptex.height
    rettex.mipmaps = ptex.mipmaps
    rettex.format = ptex.format

[export]
def main
    let clrWhite :uint = 0xffffffff
    let clrBlack :uint = 0xff000000
	let clrRed :uint = 0xff0000ff
	
    var winWidth = 1920
    var winHeight = 1080
    var bFix = false
    var lastsecond = GetTime()
    var mousestat = false
    var offsetx = 0
    var offsety = 0
    var mmovex = 0
    var mmovey = 0
    var sDir = "E:\\mycode\\dascript\\img"
    var imglist: array<string>
    var nPos = 0
    var tex = [[Texture id=0u, width=0, height=0, mipmaps=0, format=0]]
	
	//SetTraceLogLevel(4) // disable logging
    InitWindow(1920, 1080, "Demo of raylib")
    SetWindowState(4u) // FLAG_WINDOW_RESIZABLE
    SetTargetFPS(60u)

    while !WindowShouldClose()
        // keyboard operation
        var nKeyPress = GetKeyPressed()
        if nKeyPress == 65 // Key_A
            if imglist.length() > 0
                if nPos > 0
                    nPos--
                    ChangeImage(imglist, nPos, tex)
                    offsetx = 0
                    offsety = 0
        elif nKeyPress == 68 // Key_D
            if imglist.length() > 0
                if nPos < (imglist.length() - 1)
                    nPos++
                    ChangeImage(imglist, nPos, tex)
                    offsetx = 0
                    offsety = 0
        elif nKeyPress == 70 // Key_F
            ToggleFullscreen()
        elif nKeyPress == 77 // Key_M
            MaximizeWindow()
        elif nKeyPress == 79 // Key_O
            var findResult = FindImageFile(sDir)
            var parts = split(findResult, ";")
            if parts.length() > 1
                sDir = parts[0]
                imglist.clear()
                for i in range(1, parts.length())
                    imglist.push("{sDir}\\{parts[i]}")
                nPos = 0
                ChangeImage(imglist, nPos, tex)
                offsetx = 0
                offsety = 0
        elif nKeyPress == 82 // Key_R
            RestoreWindow()
        elif nKeyPress == 32 // Key_SPACE
            bFix = !bFix
        // mouse drag
        if (tex.width > 0) && IsMouseButtonPressed(0) && (!bFix)
            mmovex = GetMouseX()
            mmovey = GetMouseY()
            SetMouseCursor(9)
        if (tex.width > 0) && IsMouseButtonReleased(0) && (!bFix)
            if (mmovex > 0) && (mmovey > 0)
                offsetx += (GetMouseX() - mmovex)
                offsety += (GetMouseY() - mmovey)
            SetMouseCursor(0)
        // mouse wheel
        if imglist.length() > 0
            var wheeloff = GetMouseWheelMove()
            var clockdelta: double
            if wheeloff > 0.0
                clockdelta = GetTime() - lastsecond
                lastsecond = GetTime()
                if clockdelta > double(0.15)
                    // prev image
                    if imglist.length() > 0
                        if nPos > 0
                            nPos--
                            ChangeImage(imglist, nPos, tex)
                            offsetx = 0
                            offsety = 0
            elif wheeloff < 0.0
                clockdelta = GetTime() - lastsecond
                lastsecond = GetTime()
                if clockdelta > double(0.15)
                    // next image
                    if imglist.length() > 0
                        if nPos < (imglist.length() - 1)
                            nPos++
                            ChangeImage(imglist, nPos, tex)
                            offsetx = 0
                            offsety = 0
        // draw photo
        winWidth = GetScreenWidth()
        winHeight = GetScreenHeight()
        BeginDrawing()
        ClearBackground(clrBlack)
        if tex.width > 0
            if bFix
                var fScale: float = float(winWidth) / float(tex.width)
                var newWidth = winWidth;
                var newHeight = int(float(tex.height) * fScale)
                if newHeight > winHeight
                    fScale = float(winHeight) / float(tex.height)
                    newHeight = winHeight;
                    newWidth = int(float(tex.width) * fScale)
                var tmpx = (winWidth - newWidth) / 2
                var tmpy = (winHeight - newHeight) / 2
                var picpos = [[Vector2() x=float(tmpx), y=float(tmpy)]]
                DrawTextureEx(unsafe(addr(tex)), unsafe(addr(picpos)), 0.0, fScale, clrWhite)
            else
                DrawTexture(unsafe(addr(tex)), (winWidth-tex.width)/2+offsetx, (winHeight-tex.height)/2+offsety, clrWhite)
        else
            DrawText("No image to show", 120, 50, 20, clrRed);
            DrawText("A for prev image", 120, 80, 20, clrWhite);
            DrawText("D for next image", 120, 110, 20, clrWhite);
            DrawText("O for change folder", 120, 140, 20, clrWhite);
            DrawText("F for toggle fullscreen", 120, 170, 20, clrWhite);
            DrawText("M for maximize window", 120, 200, 20, clrWhite);
            DrawText("R for restore window", 120, 230, 20, clrWhite);
            DrawText("SPACE for toggle fix image size", 120, 260, 20, clrWhite);
        EndDrawing()

    if tex.width > 0
        UnloadTexture(unsafe(addr(tex)))
    CloseWindow()
