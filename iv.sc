using import String

# import tinyfd library
vvv bind tfd
include
    """"short * tinyfd_selectFolderDialogW(short const * aTitle, short const * aDefaultPath);
        char * tinyfd_utf16toMbcs(short const * aUtf16string);
        short * tinyfd_mbcsTo16(char const * aMbcsString);
load-library "tinyfd.dll"
using tfd.extern

# import raylib library
let header = (include "./raylib/raylib.h")
load-library "raylib.dll"
let raylib =
    ..
        header.extern
        header.typedef
        header.define
        header.const
        header.struct
do
    let
        header
    .. raylib (locals)
run-stage;


# constant define
let clrWhite = (raylib.Color 255 255 255 255)
let clrRed = (raylib.Color 255 0 0 255)
let clrBlack = (raylib.Color 0 0 0 255)

global imagepath = (String "E:\\mycode\\scopes\\img")
global tex : raylib.Texture
global fpl : raylib.FilePathList
global currentPos = 0
global winWidth = 1920
global winHeight = 1080
global offsetx = 0
global offsety = 0
global mmovex = 0
global mmovey = 0

fn changeDirectory ()
    local ptrWTmp = (tinyfd_mbcsTo16 imagepath)
    local ptrWPath = (tinyfd_selectFolderDialogW null ptrWTmp)
    if (not (ptrWPath == null))
        # select folder and convert to char*
        local ptrPath = (tinyfd_utf16toMbcs ptrWPath)
        # count path string length
        local strlen = 0
        for i in (range 1024)
            if ((@ ptrPath i) == 0:i8)
                strlen = i
                break;
        if (strlen > 0)
            #if path valid, change iamge path
            local strPath = (String ptrPath strlen)
            imagepath = strPath
            #print "current path changeDirectory to :" imagepath
            if (fpl.count > 0)
                raylib.UnloadDirectoryFiles fpl;
            fpl = (raylib.LoadDirectoryFilesEx ptrPath (".png;.jpg" as rawstring) false)
            #print "found " fpl.count "images"

fn loadFirstImage ()
    if (fpl.count > 0)
        currentPos = 0
        if (tex.width > 0)
            raylib.UnloadTexture tex
        tex = (raylib.LoadTexture (@ fpl.paths currentPos))
        offsetx = 0;
        offsety = 0;

fn prevImage ()
    if (fpl.count > 0)
        if (currentPos > 0)
            currentPos = (currentPos - 1)
            if (tex.width > 0)
                raylib.UnloadTexture tex
            tex = (raylib.LoadTexture (@ fpl.paths currentPos))
            offsetx = 0;
            offsety = 0;

fn nextImage ()
    if (fpl.count > 0)
        local lastpos = ((fpl.count as i32) - 1)
        if (currentPos < lastpos)
            currentPos = (currentPos + 1)
            if (tex.width > 0)
                raylib.UnloadTexture tex
            tex = (raylib.LoadTexture (@ fpl.paths currentPos))
            offsetx = 0;
            offsety = 0;

do
    local lastsecond = (raylib.GetTime)
    local bFix = false
    
    raylib.InitWindow winWidth winHeight "Image viewer by raylib"
    (raylib.SetWindowState raylib.FLAG_WINDOW_RESIZABLE)
    #tex = (raylib.LoadTexture "./img/001.png")
    raylib.SetTargetFPS 60
    while ((raylib.WindowShouldClose) == 0)
        # keyboard operation
        local nKeyPress = (raylib.GetKeyPressed)
        switch nKeyPress
        case raylib.KEY_A
            (prevImage)
        case raylib.KEY_D
            (nextImage)
        case raylib.KEY_F
            (raylib.ToggleFullscreen)
        case raylib.KEY_M
            (raylib.MaximizeWindow)
        case raylib.KEY_O
            # Select directory
            (changeDirectory)
            (loadFirstImage)
        case raylib.KEY_R
            (raylib.RestoreWindow)
        case raylib.KEY_SPACE
            if bFix
                bFix = false
            else
                bFix = true
        default
            nKeyPress = 0
        # mouse drag
        if ((raylib.IsMouseButtonPressed 0) and (not bFix))
            mmovex = (raylib.GetMouseX)
            mmovey = (raylib.GetMouseY)
            (raylib.SetMouseCursor 9)
        if ((raylib.IsMouseButtonReleased 0) and (not bFix))
            if ((mmovex > 0) and (mmovey > 0))
                offsetx = offsetx + (raylib.GetMouseX) - mmovex;
                offsety = offsety + (raylib.GetMouseY) - mmovey;
            (raylib.SetMouseCursor 0)
        # mouse wheel
        if (fpl.count > 0)
            local wheeloff = (raylib.GetMouseWheelMove)
            local clockdelta = 0.0:f64
            if (wheeloff > 0.0)
                clockdelta = ((raylib.GetTime) - lastsecond)
                lastsecond = (raylib.GetTime)
                if (clockdelta > 0.2)
                    (prevImage)
            elseif (wheeloff < 0.0)
                clockdelta = ((raylib.GetTime) - lastsecond)
                lastsecond = (raylib.GetTime)
                if (clockdelta > 0.2)
                    (nextImage)
        # paint
        winWidth = (raylib.GetScreenWidth)
        winHeight = (raylib.GetScreenHeight)
        raylib.BeginDrawing
        raylib.ClearBackground clrBlack
        if (tex.width > 0)
            #raylib.DrawTexture tex  0 0 clrWhite
            if bFix
                local fScale = ((winWidth as f32) / (tex.width as f32))
                local newWidth = winWidth
                local newHeight = (((tex.height as f32) * fScale) as i32)
                if (newHeight > winHeight)
                    fScale = ((winHeight as f32) / (tex.height as f32))
                    newHeight = winHeight
                    newWidth = (((tex.width as f32) * fScale) as i32)
                local iPos : raylib.Vector2
                iPos.x = ((winWidth - newWidth) / 2)
                iPos.y = ((winHeight - newHeight) / 2)
                (raylib.DrawTextureEx tex iPos 0.0 fScale clrWhite)
            else
                (raylib.DrawTexture tex (((winWidth - tex.width) // 2) + offsetx) (((winHeight - tex.height) // 2) + offsety) clrWhite)
        else
            (raylib.DrawText "No image to show" 50 50 20 clrRed)
            (raylib.DrawText "A for prev image" 50 80 20 clrWhite)
            (raylib.DrawText "D for next image" 50 110 20 clrWhite)
            (raylib.DrawText "O for change folder" 50 140 20 clrWhite)
            (raylib.DrawText "F for toggle fullscreen" 50 170 20 clrWhite)
            (raylib.DrawText "M for maximize window" 50 200 20 clrWhite)
            (raylib.DrawText "R for restore window" 50 230 20 clrWhite)
            (raylib.DrawText "SPACE for toggle fix image size" 50 260 20 clrWhite)
        raylib.EndDrawing;
    if (tex.width > 0)
        raylib.UnloadTexture tex
    raylib.CloseWindow;
