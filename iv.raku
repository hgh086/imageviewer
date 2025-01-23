use NativeCall;

constant LIBRAYLIB = 'raylib-raku';
constant LIBTINYFD = 'tinyfd';

class Vector2 is repr('CStruct') is rw {
    has num32 $.x;
    has num32 $.y;
    method init(num32 $x,num32 $y) returns Vector2 {
        malloc-Vector2($x,$y);
    }
    submethod DESTROY {
        free-Vector2(self);
    }
};
class Color is repr('CStruct') is rw {
    has uint8 $.r;
    has uint8 $.g;
    has uint8 $.b;
    has uint8 $.a;
    method init(uint8 $r,uint8 $g,uint8 $b,uint8 $a) returns Color {
        malloc-Color($r,$g,$b,$a);
    }
    submethod DESTROY {
        free-Color(self);
    }
};
class Texture is repr('CStruct') is rw {
    has uint32 $.id;
    has int32 $.width;
    has int32 $.height;
    has int32 $.mipmaps;
    has int32 $.format;
    method init(int32 $id,int32 $width,int32 $height,int32 $mipmaps,int32 $format) returns Texture {
        malloc-Texture($id,$width,$height,$mipmaps,$format);
    }
    submethod DESTROY {
        free-Texture(self);
    }
};
class Texture2D is Texture is repr('CStruct') {};

sub malloc-Color(uint8 $r,uint8 $g,uint8 $b,uint8 $a) returns Color is native(LIBRAYLIB) is symbol('malloc_Color') {*};
sub free-Color(Color $ptr) is native(LIBRAYLIB) is symbol('free_Color') {*};
sub malloc-Texture(int32 $id,int32 $width,int32 $height,int32 $mipmaps,int32 $format) returns Texture is native(LIBRAYLIB) is symbol('malloc_Texture') {*};
sub free-Texture(Texture $ptr) is native(LIBRAYLIB) is symbol('free_Texture') {*};
sub malloc-Vector2(num32 $x,num32 $y) returns Vector2 is native(LIBRAYLIB) is symbol('malloc_Vector2') {*};
sub free-Vector2(Vector2 $ptr) is native(LIBRAYLIB) is symbol('free_Vector2') {*};

sub init-window (int32 $width, int32 $height, Str $title) is native(LIBRAYLIB) is symbol('InitWindow_Normal'){ * };
sub term:<close-window> () is native(LIBRAYLIB) is symbol('CloseWindow_Normal'){ * };
sub term:<window-should-close> () returns bool is native(LIBRAYLIB) is symbol('WindowShouldClose_Normal'){ * };
sub term:<begin-drawing> () is native(LIBRAYLIB) is symbol('BeginDrawing_Normal'){ * };
sub term:<end-drawing> () is native(LIBRAYLIB) is symbol('EndDrawing_Normal'){ * };
sub clear-background (Color $color) is native(LIBRAYLIB) is symbol('ClearBackground_pointerized'){ * };
sub draw-text (Str $text, int32 $posX, int32 $posY, int32 $fontSize, Color $color) is native(LIBRAYLIB) is symbol('DrawText_pointerized'){ * };
sub load-texture (Str $fileName) returns Texture2D is native(LIBRAYLIB) is symbol('LoadTexture_pointerized'){ * };
sub load-texture-utf8 (Str $fileName) returns Texture2D is export is native(LIBRAYLIB) is symbol('LoadTextureUtf8_pointerized'){ * }
sub draw-texture (Texture2D $texture, int32 $posX, int32 $posY, Color $tint) is native(LIBRAYLIB) is symbol('DrawTexture_pointerized'){ * };
sub unload-texture (Texture2D $texture) is native(LIBRAYLIB) is symbol('UnloadTexture_pointerized'){ * };
sub draw-texture-ex (Texture2D $texture, Vector2 $position, num32 $rotation, num32 $scale, Color $tint) is native(LIBRAYLIB) is symbol('DrawTextureEx_pointerized'){ * };
sub term:<get-key-pressed> () returns int32 is native(LIBRAYLIB) is symbol('GetKeyPressed_Normal'){ * };
sub set-window-state (uint32 $flags) is native(LIBRAYLIB) is symbol('SetWindowState_Normal'){ * };
sub clear-window-state (uint32 $flags) is native(LIBRAYLIB) is symbol('ClearWindowState_Normal'){ * };
sub set-target-fps (int32 $fps) is native(LIBRAYLIB) is symbol('SetTargetFPS_Normal'){ * };
sub term:<toggle-fullscreen> () is native(LIBRAYLIB) is symbol('ToggleFullscreen_Normal'){ * };
sub term:<maximize-window> () is native(LIBRAYLIB) is symbol('MaximizeWindow_Normal'){ * };
sub term:<restore-window> () is native(LIBRAYLIB) is symbol('RestoreWindow_Normal'){ * };
sub term:<get-screen-width> () returns int32 is native(LIBRAYLIB) is symbol('GetScreenWidth_Normal'){ * };
sub term:<get-screen-height> () returns int32 is native(LIBRAYLIB) is symbol('GetScreenHeight_Normal'){ * };
sub set-trace-log-level (int32 $logLevel) is native(LIBRAYLIB) is symbol('SetTraceLogLevel_Normal'){ * };
sub term:<get-mouse-wheel-move> () returns num32 is native(LIBRAYLIB) is symbol('GetMouseWheelMove_Normal'){ * };
sub is-mouse-button-pressed (int32 $button) returns bool is native(LIBRAYLIB) is symbol('IsMouseButtonPressed_Normal'){ * };
sub is-mouse-button-down (int32 $button) returns bool is native(LIBRAYLIB) is symbol('IsMouseButtonDown_Normal'){ * };
sub is-mouse-button-released (int32 $button) returns bool is native(LIBRAYLIB) is symbol('IsMouseButtonReleased_Normal'){ * };
sub is-mouse-button-up (int32 $button) returns bool is native(LIBRAYLIB) is symbol('IsMouseButtonUp_Normal'){ * };
sub term:<get-mouse-x> () returns int32 is native(LIBRAYLIB) is symbol('GetMouseX_Normal'){ * };
sub term:<get-mouse-y> () returns int32 is native(LIBRAYLIB) is symbol('GetMouseY_Normal'){ * };
sub set-mouse-cursor (int32 $cursor) is native(LIBRAYLIB) is symbol('SetMouseCursor_Normal'){ * };
sub term:<get-time> () returns num64 is native(LIBRAYLIB) is symbol('GetTime_Normal'){ * };

sub find-image-files (Str $dirname) returns Str is native(LIBTINYFD) is symbol('tinyfd_findImageFile'){ * };

my $clrWhite = Color.init(255, 255, 255, 255);
my $clrBlack = Color.init(0, 0, 0, 255);
my $clrRed = Color.init(255, 0, 0, 255);

my $winWidth = 1920;
my $winHeight = 1080;
my $bFix = False;
my $lastsecond = get-time;
my $offsetx = 0;
my $offsety = 0;
my $mmovex = 0;
my $mmovey = 0;
my $sDir = "E:\\mycode\\rakudo\\img";
my @imglist = ();
my $nPos = 0;
my Texture $tex = Texture.init(0, 0, 0, 0, 0);

sub loadFirstImage {
    if (@imglist.elems > 0) {
        $nPos = 0;
        if $tex.width > 0 { unload-texture($tex); }
        $tex = load-texture-utf8(@imglist[$nPos]);
        $offsetx = 0;
        $offsety = 0;
    }
}
sub prevImage {
    if (@imglist.elems > 0) {
        if $nPos > 0 {
            $nPos--;
            if $tex.width > 0 { unload-texture($tex); }
            $tex = load-texture-utf8(@imglist[$nPos]);
            $offsetx = 0;
            $offsety = 0;
        }
    }
}
sub nextImage {
    if (@imglist.elems > 0) {
        if $nPos < (@imglist.elems - 1) {
            $nPos++;
            if $tex.width > 0 { unload-texture($tex); }
            $tex = load-texture-utf8(@imglist[$nPos]);
            $offsetx = 0;
            $offsety = 0;
        }
    }
}

set-trace-log-level(4);
init-window(1920, 1080, "Image viewer by raylib");
set-window-state(4); # FLAG_WINDOW_RESIZABLE
set-target-fps(60);

while !window-should-close {
    # keyboard operation
    my $nKeyPress = get-key-pressed;
    given $nKeyPress {
        when 65 {
            # Key_A
            prevImage;
        }
        when 68 {
            # Key_D
            nextImage;
        }
        when 70 {
            # Key_F
            toggle-fullscreen;
        }
        when 77 {
            # Key_M
            maximize-window;
        }
        when 79 {
            # Key_O
            my $newDir = find-image-files($sDir);
            my @parts = split(";", $newDir);
            if @parts.elems > 1 {
                $sDir = @parts[0];
                @imglist = ();
                for 1 .. (@parts.elems - 1)  -> $i {
                    @imglist.push($sDir ~ "\\" ~ @parts[$i]);
                }
                loadFirstImage();
            }
        }
        when 82 {
            # Key_R
            restore-window;
        }
        when 32 {
            # Key_SPACE
            if $bFix {
                $bFix = False;
            } else {
                $bFix = True;
            }
        }
        default {;}
    }
    # mouse drag
    if is-mouse-button-pressed(0) && (! $bFix) {
        $mmovex = get-mouse-x;
        $mmovey = get-mouse-y;
        set-mouse-cursor(9);
    }
    if is-mouse-button-released(0) && (! $bFix) {
        if ($mmovex > 0) && ($mmovey > 0) {
            $offsetx = $offsetx + get-mouse-x - $mmovex;
            $offsety = $offsety + get-mouse-y - $mmovey;
        }
        set-mouse-cursor(0);
    }
    # mouse wheel
    if @imglist.elems > 0 {
        my $wheeloff = get-mouse-wheel-move;
        my $clockdelta = 0;
        if $wheeloff > 0 {
            $clockdelta = get-time - $lastsecond;
            $lastsecond = get-time;
            if $clockdelta > 0.15 {
                prevImage;
            }
        } elsif $wheeloff < 0 {
            $clockdelta = get-time - $lastsecond;
            $lastsecond = get-time;
            if $clockdelta > 0.15 {
                nextImage;
            }
        }
    }
    # draw image
    $winWidth = get-screen-width;
    $winHeight = get-screen-height;
    begin-drawing;
    clear-background($clrBlack);
    if $tex.width > 0 {
        if $bFix {
            my $fScale = $winWidth / $tex.width;
            my $newWidth = $winWidth;
            my $newHeight = ($tex.height * $fScale).round;
            if $newHeight > $winHeight {
                $fScale = $winHeight / $tex.height;
                $newHeight = $winHeight;
                $newWidth = ($tex.width * $fScale).round;
            }
            my num32 $posx = (($winWidth - $newWidth) / 2e0); # use / 2e0 convert to num32
            my num32 $posy = (($winHeight - $newHeight) / 2e0); # use / 2e0 convert to num32
            my $iPos = Vector2.init($posx, $posy);
            draw-texture-ex($tex, $iPos, 0e0, $fScale.Num , $clrWhite); # use .Num convert to num32
        } else {
            draw-texture($tex, ($winWidth - $tex.width) div 2 + $offsetx, ($winHeight - $tex.height) div 2 + $offsety, $clrWhite);
        }
    } else {
		draw-text("No image to show", 50, 50, 20, $clrRed);
		draw-text("A for prev image", 50, 80, 20, $clrWhite);
		draw-text("D for next image", 50, 110, 20, $clrWhite);
		draw-text("O for change folder", 50, 140, 20, $clrWhite);
		draw-text("F for toggle fullscreen", 50, 170, 20, $clrWhite);
		draw-text("M for maximize window", 50, 200, 20, $clrWhite);
		draw-text("R for restore window", 50, 230, 20, $clrWhite);
		draw-text("SPACE for toggle fix image size", 50, 260, 20, $clrWhite);
    }
    end-drawing;
}
if $tex.width > 0 { unload-texture($tex); }
close-window;
