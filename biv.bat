del iv.obj
del tinyfiledialogs.obj
del iv.exe
cl iv.c deps\tinyfiledialogs.c /I E:\mycode\c\vc\dist\raylib\include /I E:\mycode\c\vc\test\ray\deps /EHsc /c
link /RELEASE /OUT:iv.exe /LIBPATH:E:\mycode\c\vc\dist\raylib\lib iv.obj tinyfiledialogs.obj iv.res user32.lib ole32.lib shell32.lib comdlg32.lib raylib.lib
