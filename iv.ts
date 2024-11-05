// Can run in deno 2.04
// deno -A iv.ts

let libSuffix = "";
switch (Deno.build.os) {
    case "windows":
        libSuffix = "dll";
        break;
    case "darwin":
        libSuffix = "dylib";
        break;
    default:
        libSuffix = "so";
        breakl
}

const libName = `./raylib.${libSuffix}`;
const raylib = Deno.dlopen(
    libName, 
    {
        "InitWindow": { parameters: ["i32", "i32", "buffer"], result: "void" },
        "WindowShouldClose": { parameters: [], result: "u8" },
        "BeginDrawing": { parameters: [], result: "void" },
        "EndDrawing": { parameters: [], result: "void" },
        "ClearBackground": { parameters: ["u32"], result: "void" },
        "DrawText": { parameters: ["buffer", "i32", "i32", "i32", "u32"], result: "void" },
        "CloseWindow": { parameters: [], result: "void" },
        "LoadTexture": { parameters: ["buffer"], result: {struct: ["u32", "i32", "i32", "i32", "i32"]} },
        "UnloadTexture": {parameters: [{struct: ["u32", "i32", "i32", "i32", "i32"]}], result: "void"},
        "DrawTexture": {parameters: [{struct: ["u32", "i32", "i32", "i32", "i32"]}, "i32", "i32", "u32"], result: "void"},
        "DrawTextureEx": {parameters: [{struct: ["u32", "i32", "i32", "i32", "i32"]}, {struct: ["f32", "f32"]}, "f32", "f32", "u32"], result: "void"},
        "GetKeyPressed": { parameters: [], result: "i32" },
        "SetWindowState": { parameters: ["u32"], result: "void" },
        "SetTargetFPS": { parameters: ["i32"], result: "void" },
        "ClearWindowState": { parameters: ["u32"], result: "void" },
        "ToggleFullscreen": { parameters: [], result: "void" },
        "MaximizeWindow": { parameters: [], result: "void" },
        "RestoreWindow": { parameters: [], result: "void" },
        "GetScreenWidth": { parameters: [], result: "i32" },
        "GetScreenHeight": { parameters: [], result: "i32" },
        "SetTraceLogLevel": { parameters: ["i32"], result: "void" },
        "GetMouseWheelMove": { parameters: [], result: "f32" },
        "IsMouseButtonPressed": { parameters: ["i32"], result: "u8" },
        "IsMouseButtonDown": { parameters: ["i32"], result: "u8" },
        "IsMouseButtonReleased": { parameters: ["i32"], result: "u8" },
        "IsMouseButtonUp": { parameters: ["i32"], result: "u8" },
        "GetMouseX": { parameters: [], result: "i32" },
        "GetMouseY": { parameters: [], result: "i32" },
        "SetMouseCursor": { parameters: ["i32"], result: "void" },
        "GetTime": { parameters: [], result: "f64" },
    } as const, 
);

const tfdlibName = `./tinyfd.${libSuffix}`;
const tfdlib = Deno.dlopen(
    tfdlibName,
    {
        "tinyfd_findImageFile": { parameters: ["buffer"], result: "pointer" }, 
        "tinyfd_utf8ToU16Char": { parameters: ["buffer", "buffer"], result: "void" }, 
    } as const,
);

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

// struct Texture { id:u32, width:i32 , height:i32, mipmaps:i32, format:i32 }
// struct Vector2 { x:f32, y:f32 }
function getTextureWidth(texArray) {
    if (texArray.length == 20) {
        let nRet = texArray[4] + texArray[5]*256 + texArray[6]*256*256 + texArray[7]*256*256*256;
        return nRet;
    } else {
        return 0;
    }
}
function getTextureHeight(texArray) {
    if (texArray.length == 20) {
        let nRet = texArray[8] + texArray[9]*256 + texArray[10]*256*256 + texArray[11]*256*256*256;
        return nRet;
    } else {
        return 0;
    }
}

const encoder = new TextEncoder();
const decoder = new TextDecoder("utf-8");
const titleStringArray = encoder.encode("Image viewer using raylib\0");
const text1SArray = encoder.encode("No image to show\0");
const text2SArray = encoder.encode("A for prev image\0");
const text3SArray = encoder.encode("D for next image\0");
const text4SArray = encoder.encode("O for change folder\0");
const text5SArray = encoder.encode("F for toggle fullscreen\0");
const text6SArray = encoder.encode("M for maximize window\0");
const text7SArray = encoder.encode("R for restore window\0");
const text8SArray = encoder.encode("SPACE for toggle fix image size\0");

var winWidth = 1920;
var winHeight = 1080;
var bFix = false;
var lastsecond = raylib.symbols.GetTime();
var offsetx = 0;
var offsety = 0;
var mmovex = 0;
var mmovey = 0;

var sDir = "E:\\mycode\\tjs\\img";
var imglist = [];
var nPos = 0;
var tex = undefined;

function changeDirectory() {
    let dirArray = encoder.encode(sDir + "\0");
    const tmpPtr = tfdlib.symbols.tinyfd_findImageFile(dirArray);
    let selArray1 = new Uint8Array(Deno.UnsafePointerView.getArrayBuffer(tmpPtr, 16384));
    let strLen = 0;
    for (let i=0;i<16384;i++) {
        if (selArray1[i] == 0) break;
        strLen++;
    }
    let selArray2 = selArray1.slice(0, strLen);
    let sSel = decoder.decode(selArray2);
    if (sSel != "") {
        let parts = sSel.split(";");
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
}

function loadFirstImage() {
    if (imglist.length > 0) {
        nPos = 0;
        if (tex != undefined) {
            raylib.symbols.UnloadTexture(tex);
            tex = undefined;
        }
        // solve chinese path problem
        let fileArray = encoder.encode(imglist[nPos] + "\0");
        let filenamebuf = new Uint8Array(2048);
        tfdlib.symbols.tinyfd_utf8ToU16Char(fileArray, filenamebuf);
        tex = raylib.symbols.LoadTexture(filenamebuf);
        offsetx = 0;
        offsety = 0;
    }
}

function prevImage() {
    if (imglist.length > 0) {
        if (nPos>0) {
            nPos--;
            if (tex != undefined) {
                raylib.symbols.UnloadTexture(tex);
                tex = undefined;
            }
            // solve chinese path problem
            let fileArray = encoder.encode(imglist[nPos] + "\0");
            let filenamebuf = new Uint8Array(2048);
            tfdlib.symbols.tinyfd_utf8ToU16Char(fileArray, filenamebuf);
            tex = raylib.symbols.LoadTexture(filenamebuf);
            offsetx = 0;
            offsety = 0;
        }
    }
}

function nextImage() {
    if (imglist.length > 0) {
        if (nPos<(imglist.length-1)) {
            nPos++;
            if (tex != undefined) {
                raylib.symbols.UnloadTexture(tex);
                tex = undefined;
            }
            // solve chinese path problem
            let fileArray = encoder.encode(imglist[nPos] + "\0");
            let filenamebuf = new Uint8Array(2048);
            tfdlib.symbols.tinyfd_utf8ToU16Char(fileArray, filenamebuf);
            tex = raylib.symbols.LoadTexture(filenamebuf);
            offsetx = 0;
            offsety = 0;
        }
    }
}

raylib.symbols.SetTraceLogLevel(4);
raylib.symbols.InitWindow(winWidth, winHeight, titleStringArray);
raylib.symbols.SetWindowState(FLAG_WINDOW_RESIZABLE);
raylib.symbols.SetTargetFPS(60); // lower CPU useage

while (raylib.symbols.WindowShouldClose() == 0) {
    // keyboard operation
    let nKeyPress = raylib.symbols.GetKeyPressed();
    switch (nKeyPress) {
        case KEY_A:
            prevImage();
            break;
        case KEY_D:
            nextImage();
            break;
        case KEY_F:
            raylib.symbols.ToggleFullscreen();
            break;
        case KEY_M:
            raylib.symbols.MaximizeWindow();
            break;
        case KEY_O:
            changeDirectory();
            break;
        case KEY_R:
            raylib.symbols.RestoreWindow();
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
    // mouse drag
    if (raylib.symbols.IsMouseButtonPressed(0) && !bFix) {
        mmovex = raylib.symbols.GetMouseX();
        mmovey = raylib.symbols.GetMouseY();
        raylib.symbols.SetMouseCursor(9);
    }
    if (raylib.symbols.IsMouseButtonReleased(0) && !bFix) {
        if ((mmovex>0) && (mmovey>0)) {
            offsetx += raylib.symbols.GetMouseX() - mmovex;
            offsety += raylib.symbols.GetMouseY() - mmovey;
        }
        raylib.symbols.SetMouseCursor(0);
    }
    // move wheel
    if (imglist.length>0) {
        let wheeloff = raylib.symbols.GetMouseWheelMove();
        if (wheeloff>0) {
            let clockdelta = raylib.symbols.GetTime() - lastsecond;
            lastsecond = raylib.symbols.GetTime();
            if (clockdelta > 0.2) {
                prevImage();
            }
        } else if (wheeloff<0) {
            let clockdelta = raylib.symbols.GetTime() - lastsecond;
            lastsecond = raylib.symbols.GetTime();
            if (clockdelta > 0.2) {
                nextImage();
            }
        }
    }
    // draw ui
    winWidth = raylib.symbols.GetScreenWidth();
    winHeight = raylib.symbols.GetScreenHeight();
    raylib.symbols.BeginDrawing();
    raylib.symbols.ClearBackground(clrBlack);
    if ((tex != undefined) && (getTextureWidth(tex) > 0)) {
        let texWidth = getTextureWidth(tex);
        let texHeight = getTextureHeight(tex);
        if (bFix) {
            let fScale = winWidth / texWidth;
            let newWidth = winWidth;
            let newHeight = texWidth * fScale;
            if (newHeight > winHeight) {
                // change scale
                fScale = winHeight / texHeight;
                newHeight = winHeight;
                newWidth = texWidth * fScale;
            }
            raylib.symbols.DrawTextureEx(tex, new Float32Array([(winWidth-newWidth)/2, (winHeight-newHeight)/2]), 0.0, fScale, clrWhite);
        } else {
            
            raylib.symbols.DrawTexture(tex, Math.floor((winWidth-texWidth)/2 + offsetx), Math.floor((winHeight-texHeight)/2 + offsety), clrWhite);
        }
    } else {
        raylib.symbols.DrawText(text1SArray, 50, 50, 20, clrWhite);
        raylib.symbols.DrawText(text2SArray, 50, 80, 20, clrWhite);
        raylib.symbols.DrawText(text3SArray, 50, 110, 20, clrWhite);
        raylib.symbols.DrawText(text4SArray, 50, 140, 20, clrWhite);
        raylib.symbols.DrawText(text5SArray, 50, 170, 20, clrWhite);
        raylib.symbols.DrawText(text6SArray, 50, 200, 20, clrWhite);
        raylib.symbols.DrawText(text7SArray, 50, 230, 20, clrWhite);
        raylib.symbols.DrawText(text8SArray, 50, 260, 20, clrWhite);
    }
    raylib.symbols.EndDrawing();
}
if (tex != undefined) {
    raylib.symbols.UnloadTexture(tex);
    tex = undefined;
}
raylib.symbols.CloseWindow();
