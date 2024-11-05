import FFI from 'tjs:ffi';

function main() {
    // file dialog define
    const libfd = new FFI.Lib("./tinyfd.dll");
    const fd_findImageFile = new FFI.CFunction(libfd.symbol('tinyfd_findImageFile'), FFI.types.string, [FFI.types.string])
    const fd_utf8ToU16Char = new FFI.CFunction(libfd.symbol('tinyfd_utf8ToU16Char'), FFI.types.void, [FFI.types.string, FFI.types.buffer])

    // ray struct define
    const ImageT = new FFI.StructType([
        ['data', FFI.types.pointer], 
        ['width', FFI.types.sint], 
        ['height', FFI.types.sint], 
        ['mipmaps', FFI.types.sint], 
        ['format', FFI.types.sint],        
    ], 'Image');
    const TextureT = new FFI.StructType([
        ['id', FFI.types.uint], 
        ['width', FFI.types.sint], 
        ['height', FFI.types.sint], 
        ['mipmaps', FFI.types.sint], 
        ['format', FFI.types.sint],        
    ], 'Texture');
    const Vector2T = new FFI.StructType([
        ['x', FFI.types.float], 
        ['y', FFI.types.float], 
    ], 'Vector2');
    
    // ray api define
    const libr = new FFI.Lib("./libraylib.dll");
    const ray_InitWindow = new FFI.CFunction(libr.symbol('InitWindow'), FFI.types.void, [FFI.types.sint32, FFI.types.sint32, FFI.types.string]);
    const ray_WindowShouldClose = new FFI.CFunction(libr.symbol('WindowShouldClose'), FFI.types.uint8, []);
    const ray_BeginDrawing = new FFI.CFunction(libr.symbol('BeginDrawing'), FFI.types.void, []);
    const ray_EndDrawing = new FFI.CFunction(libr.symbol('EndDrawing'), FFI.types.void, []);
    const ray_ClearBackground = new FFI.CFunction(libr.symbol('ClearBackground'), FFI.types.void, [FFI.types.uint32]);
    const ray_DrawText = new FFI.CFunction(libr.symbol('DrawText'), FFI.types.void, [FFI.types.string, FFI.types.sint32, FFI.types.sint32, FFI.types.sint32, FFI.types.uint32]);
    const ray_CloseWindow = new FFI.CFunction(libr.symbol('CloseWindow'), FFI.types.void, []);
    const ray_LoadImage = new FFI.CFunction(libr.symbol('LoadImage'), ImageT, [FFI.types.buffer]);
    const ray_UnloadImage = new FFI.CFunction(libr.symbol('UnloadImage'), FFI.types.void, [ImageT]);
    const ray_LoadTextureFromImage = new FFI.CFunction(libr.symbol('LoadTextureFromImage'), TextureT, [ImageT]);
    const ray_LoadTexture = new FFI.CFunction(libr.symbol('LoadTexture'), TextureT, [FFI.types.buffer]);
    const ray_UnloadTexture = new FFI.CFunction(libr.symbol('UnloadTexture'), FFI.types.void, [TextureT]);
    const ray_DrawTexture = new FFI.CFunction(libr.symbol('DrawTexture'), FFI.types.void, [TextureT, FFI.types.sint, FFI.types.sint, FFI.types.uint32]);
    const ray_GetKeyPressed = new FFI.CFunction(libr.symbol('GetKeyPressed'), FFI.types.sint, []);
    const ray_SetWindowState = new FFI.CFunction(libr.symbol('SetWindowState'), FFI.types.void, [FFI.types.uint32]);
    const ray_ClearWindowState = new FFI.CFunction(libr.symbol('ClearWindowState'), FFI.types.void, [FFI.types.uint32]);
    const ray_ToggleFullscreen = new FFI.CFunction(libr.symbol('ToggleFullscreen'), FFI.types.void, []);
    const ray_MaximizeWindow = new FFI.CFunction(libr.symbol('MaximizeWindow'), FFI.types.void, []);
    const ray_RestoreWindow = new FFI.CFunction(libr.symbol('RestoreWindow'), FFI.types.void, []);
    const ray_GetScreenWidth = new FFI.CFunction(libr.symbol('GetScreenWidth'), FFI.types.sint, []);
    const ray_GetScreenHeight = new FFI.CFunction(libr.symbol('GetScreenHeight'), FFI.types.sint, []);
    const ray_DrawTextureEx = new FFI.CFunction(libr.symbol('DrawTextureEx'), FFI.types.void, [TextureT, Vector2T, FFI.types.float, FFI.types.float, FFI.types.uint32]);
    const ray_SetTraceLogLevel = new FFI.CFunction(libr.symbol('SetTraceLogLevel'), FFI.types.void, [FFI.types.sint]);
    const ray_GetMouseWheelMove = new FFI.CFunction(libr.symbol('GetMouseWheelMove'), FFI.types.float, []);
    const ray_IsMouseButtonPressed = new FFI.CFunction(libr.symbol('IsMouseButtonPressed'), FFI.types.uint8, [FFI.types.sint]);
    const ray_IsMouseButtonDown = new FFI.CFunction(libr.symbol('IsMouseButtonDown'), FFI.types.uint8, [FFI.types.sint]);
    const ray_IsMouseButtonReleased = new FFI.CFunction(libr.symbol('IsMouseButtonReleased'), FFI.types.uint8, [FFI.types.sint]);
    const ray_IsMouseButtonUp = new FFI.CFunction(libr.symbol('IsMouseButtonUp'), FFI.types.uint8, [FFI.types.sint]);
    const ray_GetMouseX = new FFI.CFunction(libr.symbol('GetMouseX'), FFI.types.sint, []);
    const ray_GetMouseY = new FFI.CFunction(libr.symbol('GetMouseY'), FFI.types.sint, []);
    const ray_SetMouseCursor = new FFI.CFunction(libr.symbol('SetMouseCursor'), FFI.types.void, [FFI.types.sint]);
    
    const winWidth = 1920;
    const winHeight = 1080;    
    const clrWhite = 0xffffffff;
    const clrLGray = 0xff0000ff;
    const clrBlack = 0xff000000;
    const KEY_SPACE = 32;
    const KEY_A = 65;
    const KEY_D = 68;
    const KEY_F = 70;
    const KEY_M = 77;
    const KEY_O = 79;
    const KEY_R = 82;
    const FLAG_WINDOW_RESIZABLE = 4;

    // move control
    var lastsecond = Date.now();
    var offsetx = 0;
    var offsety = 0;
    var mmovex = 0;
    var mmovey = 0;
    // image path and file list
    var sDir = "E:\\mycode\\tjs\\img"; //"D:\\Tools";
    var imglist = [];
    
    // init window
    //ray_SetTraceLogLevel.call(4);
    ray_InitWindow.call(winWidth, winHeight, "Image viewer using raylib");
    ray_SetWindowState.call(FLAG_WINDOW_RESIZABLE);
    // load texture
    var bFix = false;
    var nPos = 0;
    var tex = undefined;

    function loadFirstImage() {
        if (imglist.length > 0) {
            nPos = 0;
            if ((tex != undefined) && (tex.width > 0)) ray_UnloadTexture.call(tex);
            // solve chinese path problem
            let filenamebuf = new Uint8Array(2048);
            fd_utf8ToU16Char.call(imglist[nPos], filenamebuf);
            tex = ray_LoadTexture.call(filenamebuf);
            offsetx = 0;
            offsety = 0;
        }
    }
    
    function prevImage() {
        if (imglist.length > 0) {
            if (nPos>0) {
                nPos--;
                if ((tex != undefined) && (tex.width > 0)) ray_UnloadTexture.call(tex);
                // solve chinese path problem
                let filenamebuf = new Uint8Array(2048);
                fd_utf8ToU16Char.call(imglist[nPos], filenamebuf);
                tex = ray_LoadTexture.call(filenamebuf);
                offsetx = 0;
                offsety = 0;
            }
        }
    }
    
    function nextImage() {
        if (imglist.length > 0) {
            if (nPos<(imglist.length-1)) {
                nPos++;
                if ((tex != undefined) && (tex.width > 0)) ray_UnloadTexture.call(tex);
                // solve chinese path problem
                let filenamebuf = new Uint8Array(2048);
                fd_utf8ToU16Char.call(imglist[nPos], filenamebuf);
                tex = ray_LoadTexture.call(filenamebuf);
                offsetx = 0;
                offsety = 0;
            }
        }
    }

    // main loop
    while (!ray_WindowShouldClose.call()) {
        // move operation
        if (ray_IsMouseButtonPressed.call(0) && !bFix) {
            mmovex = ray_GetMouseX.call();
            mmovey = ray_GetMouseY.call();
            ray_SetMouseCursor.call(9);
        }
        if (ray_IsMouseButtonReleased.call(0) && !bFix) {
            if ((mmovex>0) && (mmovey>0)) {
                offsetx += ray_GetMouseX.call() - mmovex;
                offsety += ray_GetMouseY.call() - mmovey;
            }
            ray_SetMouseCursor.call(0);
        }
        // keyboard operation
        let nKeyPress = ray_GetKeyPressed.call();
        switch (nKeyPress) {
            case KEY_A:
                prevImage();
                break;
            case KEY_D:
                nextImage();
                break;
            case KEY_F:
                ray_ToggleFullscreen.call();
                break;
            case KEY_M:
                ray_MaximizeWindow.call();
                break;
            case KEY_O:
                // change directory
                let sSelDir = fd_findImageFile.call(sDir);
                if (sSelDir != "") {
                    let parts = sSelDir.split(";");
                    if ((parts.length>1) && (parts[0] != "")) {
                        sDir = parts[0];
                        imglist = [];
                        for (let i=1;i<parts.length;i++) {
                            if (parts[i] != "") {
                                let sTmp = sDir + '\\' + parts[i];
                                imglist.push(sTmp);
                            }
                        }
                        loadFirstImage();
                    }
                }
                break;
            case KEY_R:
                ray_RestoreWindow.call();
                break;
            case KEY_SPACE:
                if (bFix) {
                    bFix = false;
                } else {
                    bFix = true;
                }
                break;
            default:
                break;
        }
        // mouse operation
        if (imglist.length>0) {
            let wheeloff = ray_GetMouseWheelMove.call();
            if (wheeloff>0) {
                let clockdelta = Date.now() - lastsecond;
                lastsecond = Date.now();
                if (clockdelta > 200) {
                    //println("wheel up, prev image:"+to_string(clockdelta));
                    prevImage();
                }
            } else if (wheeloff<0) {
                let clockdelta = Date.now() - lastsecond;
                lastsecond = Date.now();
                if (clockdelta > 200) {
                    //println("wheel down, next image:"+to_string(clockdelta));
                    nextImage();
                }
            }
        }
        // draw ui
        let winWidth = ray_GetScreenWidth.call();
        let winHeight = ray_GetScreenHeight.call();
        ray_BeginDrawing.call();
        ray_ClearBackground.call(clrBlack);
        if ((tex != undefined) && (tex.width > 0)) {
            if (bFix) {
                let fScale = winWidth / tex.width;
                let newWidth = winWidth;
                let newHeight = tex.height * fScale;
                if (newHeight > winHeight) {
                    // change scale
                    fScale = winHeight / tex.height;
                    newHeight = winHeight;
                    newWidth = tex.width * fScale;
                }
                ray_DrawTextureEx.call(tex, {x:(winWidth-newWidth)/2, y:(winHeight-newHeight)/2}, 0, fScale, clrWhite);
            } else {
                ray_DrawTexture.call(tex, (winWidth-tex.width)/2 + offsetx, (winHeight-tex.height)/2 + offsety, clrWhite);
            }
        } else {
            ray_DrawText.call("No image to show", 50, 50, 20, clrWhite);
            ray_DrawText.call("A for prev image", 50, 80, 20, clrWhite);
            ray_DrawText.call("D for next image", 50, 110, 20, clrWhite);
            ray_DrawText.call("O for change folder", 50, 140, 20, clrWhite);
            ray_DrawText.call("F for toggle fullscreen", 50, 170, 20, clrWhite);
            ray_DrawText.call("M for maximize window", 50, 200, 20, clrWhite);
            ray_DrawText.call("R for restore window", 50, 230, 20, clrWhite);
            ray_DrawText.call("SPACE for toggle fix image size", 50, 260, 20, clrWhite);
        }
        
        ray_EndDrawing.call();
    }
    // free resource
    if ((tex != undefined) && (tex.width > 0)) {
        ray_UnloadTexture.call(tex);
    }

    // close window
    ray_CloseWindow.call();
}

main();
