#pragma comment(linker, "/subsystem:\"windows\" /entry:\"mainCRTStartup\"")

#include "raylib.h"
#include "deps/tinyfiledialogs.h"
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>

#define MAX_PATH_SIZE 1024

double lastsecond = 0;
// image path list
char ImagePath[MAX_PATH_SIZE];
char ImageFile[MAX_PATH_SIZE*2];
FilePathList fplist = {0};
int nPos = 0;
// control variant
bool bFix = false;
int offsetx = 0;
int offsety = 0;
int mmovex = 0;
int mmovey = 0;
// texture
Texture2D tex = {0};

void changeImage() {
    // nPos invalid
    if ((nPos < 0) || (nPos >= fplist.count)) return;
    if (tex.width > 0) {
        // free texture
        UnloadTexture(tex);
        tex.id = 0;
        tex.width = 0;
        tex.height = 0;
        tex.mipmaps = 0;
        tex.format = 0;
    }
    memset(ImageFile, 0, MAX_PATH_SIZE*2);
    strcpy(ImageFile, ImagePath);
    strcpy(ImageFile, "\\");
    strcpy(ImageFile, fplist.paths[nPos]);
    tex = LoadTexture(ImageFile);
    offsetx = 0;
    offsety = 0;
}

int main()
{
    memset(ImagePath, 0, MAX_PATH_SIZE);
    strcpy(ImagePath, "D:\\Tools");
    //setlocale(LC_ALL, ".utf8");
    setlocale(LC_ALL, "chinese"); // chinese code , gbk?
	
    SetTraceLogLevel(LOG_NONE); // don't display log
    InitWindow(1920, 1080, "Image viewer");
    SetWindowState(FLAG_WINDOW_RESIZABLE); // window resizable
    SetTargetFPS(60);
    lastsecond = GetTime();
    
    while (!WindowShouldClose())
    {
        // keyboard operation
        int nKeyPress = GetKeyPressed();
        switch(nKeyPress) {
            case KEY_A:
                // prev image
                if (nPos>0) {
                    nPos--;
                    changeImage();
                }
                break;
            case KEY_D:
                // next image
                if (nPos<(fplist.count-1)) {
                    nPos++;
                    changeImage();
                }
                break;
            case KEY_F:
                ToggleFullscreen();
                break;
            case KEY_M:
                MaximizeWindow();
                break;
            case KEY_O:
                // select folder
                wchar_t* wsImagePath = tinyfd_mbcsTo16(ImagePath);
                wchar_t* wsTmp = tinyfd_selectFolderDialogW(L"Select folder", wsImagePath); // use widechar
                if (NULL != wsTmp) {
                    char* sTmp = tinyfd_utf16toMbcs(wsTmp); // convert to gbk? succeed!
                    memset(ImagePath, 0, MAX_PATH_SIZE);
                    strcpy(ImagePath, sTmp);
                    // unload Filepaths
                    if (fplist.count > 0) {
                        UnloadDirectoryFiles(fplist);
                    }
                    // load new Filepaths
                    fplist = LoadDirectoryFilesEx(ImagePath, ".png;.jpg", false);
                    // load first image
                    if (fplist.count > 0) {
                        nPos = 0;
                        changeImage();
                    }
                }
                break;
            case KEY_R:
                RestoreWindow();
                break;
            case KEY_SPACE:
                bFix = !bFix;
                break;
            default:
                break;
        }
        // mouse operation
        if (tex.width > 0) {
            if (IsMouseButtonPressed(MOUSE_BUTTON_RIGHT) && !bFix) {
                mmovex = GetMouseX();
                mmovey = GetMouseY();
                SetMouseCursor(MOUSE_CURSOR_RESIZE_ALL);
            }
            if (IsMouseButtonReleased(MOUSE_BUTTON_RIGHT) && !bFix) {
                if ((mmovex>0) && (mmovey>0)) {
                    offsetx += GetMouseX() - mmovex;
                    offsety += GetMouseY() - mmovey;
                }
                SetMouseCursor(MOUSE_CURSOR_DEFAULT);
            }
        }
        // mouse wheel
        if (fplist.count > 0) {
            float wheeloff = GetMouseWheelMove();
            if (wheeloff>0) {
                double clockdelta = GetTime() - lastsecond;
                lastsecond = GetTime();
                if (clockdelta > 0.15) {
                    // wheel up, prev image
                    if (nPos>0) {
                        nPos--;
                        changeImage();
                    }
                }
            } else if (wheeloff<0) {
                double clockdelta = GetTime() - lastsecond;
                lastsecond = GetTime();
                if (clockdelta > 0.15) {
                    // wheel down, next image
                    if (nPos<(fplist.count-1)) {
                        nPos++;
                        changeImage();
                    }
                }
            }
        }
        // draw
        int winWidth = GetScreenWidth();
        int winHeight = GetScreenHeight();
        BeginDrawing();
        ClearBackground(BLACK);
        if (tex.width > 0) {
            // draw image
            if (bFix) {
                float fScale = ((float)winWidth) / ((float)tex.width);
                int newWidth = winWidth;
                int newHeight = (int)(tex.height * fScale);
                if (newHeight > winHeight) {
                    fScale = ((float)winHeight) / ((float)tex.height);
                    newHeight = winHeight;
                    newWidth = (int)(tex.width * fScale);
                }
                Vector2 vvv = {(winWidth-newWidth)/2, (winHeight-newHeight)/2};
                DrawTextureEx(tex, vvv, 0, fScale, WHITE);
            } else {
                DrawTexture(tex, (winWidth-tex.width)/2 + offsetx, (winHeight-tex.height)/2 + offsety, WHITE);
            }
        } else {
            // prompt
            DrawText("No image to show", 50, 50, 20, RED);
            DrawText("A for prev image", 50, 80, 20, RAYWHITE);
            DrawText("D for next image", 50, 110, 20, RAYWHITE);
            DrawText("O for change folder", 50, 140, 20, RAYWHITE);
            DrawText("F for toggle fullscreen", 50, 170, 20, RAYWHITE);
            DrawText("M for maximize window", 50, 200, 20, RAYWHITE);
            DrawText("R for restore window", 50, 230, 20, RAYWHITE);
            DrawText("SPACE for toggle fix image size", 50, 260, 20, RAYWHITE);
        }
        EndDrawing();
    }
    if (tex.width > 0) {
        // free texture
        UnloadTexture(tex);
    }
    CloseWindow();
    return 0;
}
