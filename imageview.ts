// bun.js code

import { dlopen, FFIType, suffix, ptr, CString, toArrayBuffer, read  } from "bun:ffi";

const raypath = `raylib-wrapper.${suffix}`;
const tfdpath = `tinyfd.${suffix}`;

const raylib = dlopen(raypath, {
    Ray_InitWindow: {
        args:[FFIType.i32,FFIType.i32,FFIType.ptr],
        returns:FFIType.void,
    },
    Ray_CloseWindow: {
        args:[], 
        returns:FFIType.void,
    }, 
    Ray_WindowShouldClose: {
        args:[],
        returns:FFIType.bool,
    },
    Ray_BeginDrawing: {
        args:[],
        returns:FFIType.void,
    },
    Ray_EndDrawing: {
        args:[],
        returns:FFIType.void,
    },
    Ray_ClearBackground: {
        args:[FFIType.u32],
        returns:FFIType.void,
    },
    Ray_DrawText: {
        args:[FFIType.ptr,FFIType.i32,FFIType.i32,FFIType.i32,FFIType.u32],
        returns:FFIType.void,
    },
    Ray_LoadTexture: {
        args:[FFIType.cstring], 
        returns:FFIType.ptr,
    }, 
    Ray_LoadTextureUtf8: {
        args:[FFIType.cstring], 
        returns:FFIType.ptr,
    }, 
    Ray_UnloadTexture: {
        args:[FFIType.ptr], 
        returns:FFIType.void,
    }, 
    Ray_DrawTexture: {
        args:[FFIType.ptr,FFIType.i32,FFIType.i32,FFIType.u32], 
        returns:FFIType.void,
    }, 
    Ray_DrawTextureEx: {
        args:[FFIType.ptr,FFIType.ptr,FFIType.f32,FFIType.f32,FFIType.u32], 
        returns:FFIType.void,
    }, 
    Ray_GetKeyPressed: {
        args:[], 
        returns:FFIType.i32,
    }, 
    Ray_SetWindowState: {
        args:[FFIType.u32], 
        returns:FFIType.void,
    }, 
    Ray_ClearWindowState: {
        args:[FFIType.u32], 
        returns:FFIType.void,
    }, 
    Ray_SetTargetFPS: {
        args:[FFIType.u32], 
        returns:FFIType.void,
    }, 
    Ray_ToggleFullscreen: {
        args:[], 
        returns:FFIType.void,
    }, 
    Ray_MaximizeWindow: {
        args:[], 
        returns:FFIType.void,
    }, 
    Ray_RestoreWindow: {
        args:[], 
        returns:FFIType.void,
    }, 
    Ray_GetScreenWidth: {
        args:[], 
        returns:FFIType.i32,
    }, 
    Ray_GetScreenHeight: {
        args:[], 
        returns:FFIType.i32,
    }, 
    Ray_GetMouseWheelMove: {
        args:[], 
        returns:FFIType.f32,
    }, 
    Ray_IsMouseButtonPressed: {
        args:[FFIType.i32], 
        returns:FFIType.bool,
    }, 
    Ray_IsMouseButtonDown: {
        args:[FFIType.i32], 
        returns:FFIType.bool,
    }, 
    Ray_IsMouseButtonReleased: {
        args:[FFIType.i32], 
        returns:FFIType.bool,
    }, 
    Ray_IsMouseButtonUp: {
        args:[FFIType.i32], 
        returns:FFIType.bool,
    }, 
    Ray_GetMouseX: {
        args:[], 
        returns:FFIType.i32,
    }, 
    Ray_GetMouseY: {
        args:[], 
        returns:FFIType.i32,
    }, 
    Ray_SetMouseCursor: {
        args:[FFIType.i32], 
        returns:FFIType.void,
    }, 
    Ray_SetTraceLogLevel: {
        args:[FFIType.i32], 
        returns:FFIType.void,
    }, 
    Ray_GetTime: {
        args:[], 
        returns:FFIType.f64,
    }
});
const tfdlib = dlopen(tfdpath, {
    tinyfd_findImageFile: {
        args:[FFIType.cstring],
        returns:FFIType.ptr,
    }
});

function Ptr2JsTexture(ptr) {
    let vRet = {
        id : read.u32(ptr, 0), 
        width : read.i32(ptr, 4), 
        height : read.i32(ptr, 8), 
        mipmaps : read.i32(ptr, 12), 
        format : read.i32(ptr, 16)
    };
    return vRet;
}
function JsTexture2Array(tex) {
    let tmpArray = new ArrayBuffer(20);
    let dvView = new DataView(tmpArray, 0, 20);
    dvView.setUint32(0, tex.id, true);
    dvView.setInt32(4, tex.width, true);
    dvView.setInt32(8, tex.height, true);
    dvView.setInt32(12, tex.mipmaps, true);
    dvView.setInt32(16, tex.format, true);
    let aRet = new Uint8Array(tmpArray, 0, 20);
    return aRet;
}
function Ptr2JsVector2(ptr) {
    let vRet = {
        x : read.f32(ptr, 0), 
        y : read.f32(ptr, 4), 
    };
    return vRet;
}
function JsVector22Array(vec2) {
    let tmpArray = new ArrayBuffer(8);
    let dvView = new DataView(tmpArray, 0, 8);
    dvView.setFloat32(0, vec2.x, true);
    dvView.setFloat32(4, vec2.y, true);
    let aRet = new Uint8Array(tmpArray, 0, 8);
    return aRet;
}

const strTitle = Buffer.from("Image viewer using raylib\0", "utf8");
const clrWhite = 0xffffffff;
const clrRed = 0xff0000ff;
const clrBlack = 0xff000000;
const KEY_SPACE = 32;
const KEY_A = 65;
const KEY_D = 68;
const KEY_F = 70;
const KEY_M = 77;
const KEY_O = 79;
const KEY_R = 82;
const FLAG_WINDOW_RESIZABLE = 4;

const txtenc = new TextEncoder();
const txtdec = new TextDecoder("utf-8");
const text1 = txtenc.encode("No image to show\0");
const text2 = txtenc.encode("A for prev image\0");
const text3 = txtenc.encode("D for next image\0");
const text4 = txtenc.encode("O for change folder\0");
const text5 = txtenc.encode("F for toggle fullscreen\0");
const text6 = txtenc.encode("M for maximize window\0");
const text7 = txtenc.encode("R for restore window\0");
const text8 = txtenc.encode("SPACE for toggle fix image size\0");

var winWidth = 1920;
var winHeight = 1080;
var bFix = false;
var lastsecond = raylib.symbols.Ray_GetTime();
var offsetx = 0;
var offsety = 0;
var mmovex = 0;
var mmovey = 0;

var sDir = "E:\\mycode\\tjs\\img";
var imglist = [];
var nPos = 0;
var tex =  {id:0, width:0, height:0, mipmaps:0, format:0};

function changeDirectory() {
    let dirArray = txtenc.encode(sDir + "\0");
    let pStr = tfdlib.symbols.tinyfd_findImageFile(ptr(dirArray));
    let sFiles = new CString(pStr);
    let parts = sFiles.split(";");
    if (parts.length > 1) {
        sDir = parts[0];
        imglist = [];
        for (let i=1;i<parts.length;i++) {
            if (parts[i] != "") {
                let sTmp = sDir + '\\' + parts[i];
                imglist.push(sTmp);
            }
        }
        nPos = 0;
        switchImage();
    }
}
function switchImage() {
    if ((nPos > 0) && (nPos >= imglist.length)) return;
    if (tex.width > 0) {
        raylib.symbols.Ray_UnloadTexture(ptr(JsTexture2Array(tex)));
        tex = {id:0, width:0, height:0, mipmaps:0, format:0};
    }
    let bsFileName = txtenc.encode(imglist[nPos] + "\0");
    let ptex = raylib.symbols.Ray_LoadTextureUtf8(ptr(bsFileName));
    tex = Ptr2JsTexture(ptex);
    offsetx = 0;
    offsety = 0;
}

// start raylib windows
//raylib.symbols.Ray_SetTraceLogLevel(4);
raylib.symbols.Ray_InitWindow(winWidth,winHeight,ptr(strTitle));
raylib.symbols.Ray_SetWindowState(FLAG_WINDOW_RESIZABLE);
raylib.symbols.Ray_SetTargetFPS(60);

// load texture
/*var sFileName = "001.png";
var bsFileName = txtenc.encode(sFileName + "\0");
var ptex = raylib.symbols.Ray_LoadTexture(ptr(bsFileName));
tex = Ptr2JsTexture(ptex);*/

while (!raylib.symbols.Ray_WindowShouldClose()) {
    // keyboard operation
    let nKeyPress = raylib.symbols.Ray_GetKeyPressed();
    switch (nKeyPress) {
        case KEY_A:
            if (imglist.length > 0) {
                if (nPos>0) {
                    nPos--;
                    switchImage();
                }
            }
            break;
        case KEY_D:
            if (imglist.length > 0) {
                if (nPos<(imglist.length-1)) {
                    nPos++;
                    switchImage();
                }
            }
            break;
        case KEY_F:
            raylib.symbols.Ray_ToggleFullscreen();
            break;
        case KEY_M:
            raylib.symbols.Ray_MaximizeWindow();
            break;
        case KEY_O:
            changeDirectory();
            break;
        case KEY_R:
            raylib.symbols.Ray_RestoreWindow();
            break;
        case KEY_SPACE:
            bFix = !bFix;
            break;
        default:
            break;
    }
    // mouse drag
    if (tex.width > 0) {
        if (raylib.symbols.Ray_IsMouseButtonPressed(0) && !bFix) {
            mmovex = raylib.symbols.Ray_GetMouseX();
            mmovey = raylib.symbols.Ray_GetMouseY();
            raylib.symbols.Ray_SetMouseCursor(9);
        }
        if (raylib.symbols.Ray_IsMouseButtonReleased(0) && !bFix) {
            if ((mmovex>0) && (mmovey>0)) {
                offsetx += raylib.symbols.Ray_GetMouseX() - mmovex;
                offsety += raylib.symbols.Ray_GetMouseY() - mmovey;
            }
            raylib.symbols.Ray_SetMouseCursor(0);
        }
    }
    // move wheel
    if (imglist.length>0) {
        let wheeloff = raylib.symbols.Ray_GetMouseWheelMove();
        if (wheeloff>0) {
            let clockdelta = raylib.symbols.Ray_GetTime() - lastsecond;
            lastsecond = raylib.symbols.Ray_GetTime();
            if (clockdelta > 0.2) {
                prevImage();
            }
        } else if (wheeloff<0) {
            let clockdelta = raylib.symbols.Ray_GetTime() - lastsecond;
            lastsecond = raylib.symbols.Ray_GetTime();
            if (clockdelta > 0.2) {
                nextImage();
            }
        }
    }
    // draw image
    winWidth = raylib.symbols.Ray_GetScreenWidth();
    winHeight = raylib.symbols.Ray_GetScreenHeight();
    raylib.symbols.Ray_BeginDrawing();
    raylib.symbols.Ray_ClearBackground(clrBlack);
    if (tex.width > 0) {
        let texWidth = tex.width;
        let texHeight = tex.height;
        if (bFix) {
            let fScale = winWidth / texWidth;
            let newWidth = winWidth;
            let newHeight = texHeight * fScale;
            if (newHeight > winHeight) {
                // change scale
                fScale = winHeight / texHeight;
                newHeight = winHeight;
                newWidth = texWidth * fScale;
            }
            let imgpos = {x:(winWidth-newWidth)/2, y:(winHeight-newHeight)/2}
            raylib.symbols.Ray_DrawTextureEx(ptr(JsTexture2Array(tex)), ptr(JsVector22Array(imgpos)), 0.0, fScale, clrWhite);
        } else {
            raylib.symbols.Ray_DrawTexture(ptr(JsTexture2Array(tex)), Math.floor((winWidth-texWidth)/2 + offsetx), Math.floor((winHeight-texHeight)/2 + offsety), clrWhite);
        }
    } else {
        raylib.symbols.Ray_DrawText(text1, 120, 50, 20, clrRed);
        raylib.symbols.Ray_DrawText(text2, 120, 80, 20, clrWhite);
        raylib.symbols.Ray_DrawText(text3, 120, 110, 20, clrWhite);
        raylib.symbols.Ray_DrawText(text4, 120, 140, 20, clrWhite);
        raylib.symbols.Ray_DrawText(text5, 120, 170, 20, clrWhite);
        raylib.symbols.Ray_DrawText(text6, 120, 200, 20, clrWhite);
        raylib.symbols.Ray_DrawText(text7, 120, 230, 20, clrWhite);
        raylib.symbols.Ray_DrawText(text8, 120, 260, 20, clrWhite);
    }
    raylib.symbols.Ray_EndDrawing();
}

if (tex.width > 0) raylib.symbols.Ray_UnloadTexture(ptr(JsTexture2Array(tex)));
raylib.symbols.Ray_CloseWindow();
