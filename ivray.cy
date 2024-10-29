use os

type Texture:
    id int
    width int
    height int
    mipmaps int
    format int

type Vector2:
    x float
    y float

var ffi = os.newFFI()
ffi.cbind(Texture, {symbol.uint, symbol.int, symbol.int, symbol.int, symbol.int})
ffi.cbind(Vector2, {symbol.float, symbol.float})
ffi.cfunc('InitWindow', {symbol.int, symbol.int, symbol.voidPtr},  symbol.void)
ffi.cfunc('WindowShouldClose', {_},  symbol.bool)
ffi.cfunc('BeginDrawing', {_},  symbol.void)
ffi.cfunc('EndDrawing', {_},  symbol.void)
ffi.cfunc('ClearBackground', {symbol.uint},  symbol.void)
ffi.cfunc('DrawText', {symbol.voidPtr, symbol.int, symbol.int, symbol.int, symbol.uint},  symbol.void)
ffi.cfunc('CloseWindow', {_},  symbol.void)
ffi.cfunc('LoadTexture', {symbol.voidPtr}, Texture)
ffi.cfunc('UnloadTexture', {Texture}, symbol.void)
ffi.cfunc('DrawTexture', {Texture, symbol.int, symbol.int, symbol.uint}, symbol.void)
ffi.cfunc('DrawTextureEx', {Texture, Vector2, symbol.float, symbol.float, symbol.uint}, symbol.void)
ffi.cfunc('GetKeyPressed', {_}, symbol.int)
ffi.cfunc('SetWindowState', {symbol.uint}, symbol.void)
ffi.cfunc('ClearWindowState', {symbol.uint}, symbol.void)
ffi.cfunc('ToggleFullscreen', {_}, symbol.void)
ffi.cfunc('MaximizeWindow', {_}, symbol.void)
ffi.cfunc('RestoreWindow', {_}, symbol.void)
ffi.cfunc('GetScreenWidth', {_}, symbol.int)
ffi.cfunc('GetScreenHeight', {_}, symbol.int)
ffi.cfunc('SetTraceLogLevel', {symbol.int}, symbol.void)
ffi.cfunc('GetMouseWheelMove', {_}, symbol.float)
ffi.cfunc('IsMouseButtonPressed', {symbol.int}, symbol.bool)
ffi.cfunc('IsMouseButtonDown', {symbol.int}, symbol.bool)
ffi.cfunc('IsMouseButtonReleased', {symbol.int}, symbol.bool)
ffi.cfunc('IsMouseButtonUp', {symbol.int}, symbol.bool)
ffi.cfunc('GetMouseX', {_}, symbol.int)
ffi.cfunc('GetMouseY', {_}, symbol.int)
ffi.cfunc('SetMouseCursor', {symbol.int}, symbol.void)
ffi.cfunc('GetTime', {_}, symbol.double)
dyn rylib = ffi.bindLib('./raylib.dll')

ffi.cfunc("tinyfd_findImageFile", {symbol.voidPtr},  symbol.voidPtr)
ffi.cfunc("tinyfd_utf8toMbcs", {symbol.voidPtr},  symbol.voidPtr)
dyn fdlib = ffi.bindLib('./tinyfd.dll')

var .clrWhite = 0xffffffff
var .clrRed = 0xff0000ff
var .clrBlack = 0xff000000
var .KEY_SPACE int = 32
var .KEY_A int = 65
var .KEY_D int = 68
var .KEY_F int = 70
var .KEY_M int = 77
var .KEY_O int = 79
var .KEY_R int = 82
var .FLAG_WINDOW_RESIZABLE int = 4

var .imageDir String = "E:\\mycode\\cyber\\img"
var .imageFiles = List[String]{}
var .currentPos = 0
var .bFix = false
var .winWidth = 1920
var .winHeight = 1080
var .tex Texture = Texture{}
var .lastsecond float = 0.0
var .offsetx int = 0
var .offsety int = 0
var .mmovex int = 0
var .mmovey int = 0

func changeDirectory(libt dyn):
    var files = libt.tinyfd_findImageFile(libt.tinyfd_utf8toMbcs(os.cstr(imageDir)))
    var strfiles = files.fromCstr(0)
    var parts = strfiles.split(";")
    if parts.len() > 1:
        imageDir = parts[0]
        imageFiles.resize(0)
        for 1 .. parts.len() -> i:
            imageFiles.append(parts[i])

func loadFirstImage(libr dyn, libt dyn):
    if imageFiles.len() > 0:
        currentPos = 0
        if tex.width > 0 :
            libr.UnloadTexture(tex)
        var imgpath = imageDir + '\' + imageFiles[currentPos]
        tex = libr.LoadTexture(libt.tinyfd_utf8toMbcs(os.cstr(imgpath)))
        offsetx = 0
        offsety = 0

func prevImage(libr dyn, libt dyn):
    if imageFiles.len() > 0:
        if currentPos > 0:
            currentPos = currentPos - 1
            if tex.width > 0 :
                libr.UnloadTexture(tex)
            var imgpath = imageDir + '\' + imageFiles[currentPos]
            tex = libr.LoadTexture(libt.tinyfd_utf8toMbcs(os.cstr(imgpath)))
            offsetx = 0
            offsety = 0
    
func nextImage(libr dyn, libt dyn):
    if imageFiles.len() > 0:
        if currentPos < (imageFiles.len() - 1):
            currentPos = currentPos + 1
            if tex.width > 0 :
                libr.UnloadTexture(tex)
            var imgpath = imageDir + '\' + imageFiles[currentPos]
            tex = libr.LoadTexture(libt.tinyfd_utf8toMbcs(os.cstr(imgpath)))
            offsetx = 0
            offsety = 0

rylib.SetTraceLogLevel(4)
rylib.InitWindow(winWidth, winHeight, os.cstr("raylib ffi demo"))
rylib.SetWindowState(FLAG_WINDOW_RESIZABLE)

while !rylib.WindowShouldClose() :
    -- keyboard operation
    var nKeyPress = rylib.GetKeyPressed()
    switch nKeyPress
    case KEY_A:
        prevImage(rylib, fdlib)
    case KEY_D:
        nextImage(rylib, fdlib)
    case KEY_F:
        rylib.ToggleFullscreen()
    case KEY_M:
        rylib.MaximizeWindow()
    case KEY_O:
        changeDirectory(fdlib)
        --print "current image path :$(imageDir)"
        --for imageFiles -> fff:
        --    print fff
        loadFirstImage(rylib, fdlib)
    case KEY_R:
        rylib.RestoreWindow()
    case KEY_SPACE:
        if bFix :
            bFix = false
        else:
            bFix = true

    -- mouse operation
    if rylib.IsMouseButtonPressed(0) and (not bFix) :
        mmovex = rylib.GetMouseX()
        mmovey = rylib.GetMouseY()
        rylib.SetMouseCursor(9)
    if rylib.IsMouseButtonReleased(0) and (not bFix) :
        if (mmovex > 0) and (mmovey > 0) :
            offsetx = offsetx + rylib.GetMouseX() - mmovex
            offsety = offsety + rylib.GetMouseY() - mmovey
        rylib.SetMouseCursor(0)
    if imageFiles.len() > 0:
        var wheeloff = rylib.GetMouseWheelMove()
        if wheeloff > 0.0 :
            var clockdelta = rylib.GetTime() - lastsecond
            lastsecond = rylib.GetTime()
            if clockdelta > 0.2:
                prevImage(rylib, fdlib)
        else wheeloff < 0.0 :
            var clockdelta = rylib.GetTime() - lastsecond
            lastsecond = rylib.GetTime()
            if clockdelta > 0.2:
                nextImage(rylib, fdlib)
    
    -- draw
    winWidth = rylib.GetScreenWidth()
    winHeight = rylib.GetScreenHeight()
    rylib.BeginDrawing()
    rylib.ClearBackground(clrBlack)
    if tex.width > 0 :
        if bFix :
            var fScale = float(winWidth) / float(tex.width)
            var newWidth = winWidth
            var newHeight = int(float(tex.height) * fScale)
            if newHeight > winHeight :
                fScale = float(winHeight) / float(tex.height)
                newHeight = winHeight
                newWidth =  int(float(tex.width) * fScale)
            var iPos = Vector2{x=float((winWidth-newWidth)/2), y=float((winHeight-newHeight)/2)}
            rylib.DrawTextureEx(tex, iPos, 0.0, fScale, clrWhite)
        else :
            rylib.DrawTexture(tex, (winWidth-tex.width)/2+offsetx, (winHeight-tex.height)/2+offsety, clrWhite)
    else :
        rylib.DrawText(os.cstr("No image to show"), 50, 50, 20, clrRed)
        rylib.DrawText(os.cstr("A for prev image"), 50, 80, 20, clrWhite)
        rylib.DrawText(os.cstr("D for next image"), 50, 110, 20, clrWhite)
        rylib.DrawText(os.cstr("O for change folder"), 50, 140, 20, clrWhite)
        rylib.DrawText(os.cstr("F for toggle fullscreen"), 50, 170, 20, clrWhite)
        rylib.DrawText(os.cstr("M for maximize window"), 50, 200, 20, clrWhite)
        rylib.DrawText(os.cstr("R for restore window"), 50, 230, 20, clrWhite)
        rylib.DrawText(os.cstr("SPACE for toggle fix image size"), 50, 260, 20, clrWhite)
    rylib.EndDrawing()

if tex.width > 0 :
	rylib.UnloadTexture(tex)

rylib.CloseWindow()
