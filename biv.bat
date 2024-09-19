del iv.obj
del tinyfiledialogs.obj
del iv.exe
cl iv.c tinyfiledialogs.c /I ..\raylib\include /I ..\ray\deps /EHsc /c
link /RELEASE /OUT:iv.exe /LIBPATH:..\raylib\lib iv.obj tinyfiledialogs.obj iv.res user32.lib ole32.lib shell32.lib comdlg32.lib raylib.lib
