// ============================================================================
//  main.zig —— 基于 raylib 的 Windows 图片查看器 (Zig 0.16.0, x86_64)
//
//  快捷键:
//    O        打开"选择文件夹"对话框，加载该目录下第一张图片
//    A / D    上一张 / 下一张（首尾循环）
//    空格     适应窗口 <-> 原尺寸（原尺寸使用最近邻过滤）
//    右键拖拽  原尺寸模式下移动图片位置
//    F        全屏 <-> 窗口
//    Q        退出（ESC 也可以）
//
//  编译（raylib 源码目录假设为当前目录下的 raylib）:
//    zig build-exe main.zig -O ReleaseFast -target x86_64-windows-gnu -lc -lole32 -I raylib\src -L raylib\src -lraylib
//  运行: 把 raylib.dll 放到 main.exe 同目录，双击运行（无控制台黑窗口需再加 -mwindows）
// ============================================================================

const std = @import("std");

const c = @cImport({
    @cInclude("raylib.h");
});

// ===========================================================================
// Windows COM 最小声明：IFileDialog "选择文件夹" 对话框（无需 windows.h）
// vtable 槽位严格对照 Windows SDK shobjidl_core.h 的 IFileDialog 定义
// ===========================================================================

const GUID = extern struct {
    d1: u32,
    d2: u16,
    d3: u16,
    d4: [8]u8,
};

// CLSID_FileOpenDialog: {DC1C5A9C-E88A-4dde-A5A1-60F82A20AEF7}
const CLSID_FileOpenDialog = GUID{
    .d1 = 0xDC1C5A9C,
    .d2 = 0xE88A,
    .d3 = 0x4DDE,
    .d4 = .{ 0xA5, 0xA1, 0x60, 0xF8, 0x2A, 0x20, 0xAE, 0xF7 },
};

// IID_IFileDialog: {D57C7288-D4AD-4768-BE02-9D969532D960}
const IID_IFileDialog = GUID{
    .d1 = 0xD57C7288,
    .d2 = 0xD4AD,
    .d3 = 0x4768,
    .d4 = .{ 0xBE, 0x02, 0x9D, 0x96, 0x95, 0x32, 0xD9, 0x60 },
};


const DEFAULT_WIDTH = 1600;
const DEFAULT_HEIGHT = 900;
const CLSCTX_ALL: u32 = 0x17;
const FOS_PICKFOLDERS: u32 = 0x20; // 选文件夹模式
const SIGDN_FILESYSPATH: u32 = 0x80058000;
const S_OK: i32 = 0;

extern fn CoInitializeEx(pv: ?*anyopaque, dw: u32) callconv(.c) i32;
extern fn CoUninitialize() callconv(.c) void;
extern fn CoCreateInstance(rclsid: *const GUID, outer: ?*anyopaque, ctx: u32, riid: *const GUID, ppv: *?*anyopaque) callconv(.c) i32;
extern fn CoTaskMemFree(pv: *anyopaque) callconv(.c) void;

// 未使用的 vtable 槽位统一用占位函数指针（布局上都是 8 字节指针）
const CFunc = *const fn () callconv(.c) i32;

const IShellItem = extern struct {
    vtbl: *const Vtbl,
    pub const Vtbl = extern struct {
        _0: CFunc, // QueryInterface
        _1: CFunc, // AddRef
        release: *const fn (self: *anyopaque) callconv(.c) u32,
        _3: CFunc, // BindToHandler
        _4: CFunc, // GetParent
        get_display_name: *const fn (self: *anyopaque, sigdn: u32, name: **u16) callconv(.c) i32,
        _6: CFunc, // GetAttributes
        _7: CFunc, // Compare
    };
};

// IFileDialog vtable（IUnknown 3 个 + IModalWindow::Show 之后）：
//   3 Show, 4 SetFileTypes, 5 SetFileTypeIndex, 6 GetFileTypeIndex,
//   7 GetOptions, 8 SetOptions, 9 SetDefaultFolder, 10 SetFolder,
//   11 GetFolder, 12 GetCurrentFolder, 13 SetFileName, 14 GetFileName,
//   15 SetTitle, 16 SetOkButtonLabel, 17 SetFileNameLabel, 18 GetResult,
//   19 AddPlace, 20 SetDefaultExtension, 21 Close, 22 SetClientGuid,
//   23 ClearClientData, 24 SetFilter
const IFileDialog = extern struct {
    vtbl: *const Vtbl,
    pub const Vtbl = extern struct {
        // IUnknown
        _0: CFunc, // QueryInterface
        _1: CFunc, // AddRef
        release: *const fn (self: *anyopaque) callconv(.c) u32,
        // IModalWindow
        show: *const fn (self: *anyopaque, owner: ?*anyopaque) callconv(.c) i32,
        // IFileDialog
        _4: CFunc, // SetFileTypes
        _5: CFunc, // SetFileTypeIndex
        _6: CFunc, // GetFileTypeIndex
        _7: CFunc, // Advise
        _8: CFunc, // Unadvise
        set_options: *const fn (self: *anyopaque, fos: u32) callconv(.c) i32, // 9
        _10: CFunc, // GetOptions
        _11: CFunc, // SetDefaultFolder
        _12: CFunc, // SetFolder
        _13: CFunc, // GetFolder
        _14: CFunc, // GetCurrentFolder
        _15: CFunc, // SetFileName
        _16: CFunc, // GetFileName
        set_title: *const fn (self: *anyopaque, title: [*:0]const u16) callconv(.c) i32, // 17
        _18: CFunc, // SetOkButtonLabel
        _19: CFunc, // SetFileNameLabel
        get_result: *const fn (self: *anyopaque, item: **IShellItem) callconv(.c) i32, // 20
        _21: CFunc, // AddPlace
        _22: CFunc, // SetDefaultExtension
        _23: CFunc, // Close
        _24: CFunc, // SetClientGuid
        _25: CFunc, // ClearClientData
        _26: CFunc, // SetFilter
    };
};

// 对话框标题"选择图片所在目录"的 UTF-16 形式（显式哨兵 0 结尾）
const dialog_title_arr = [_:0]u16{ 0x9009, 0x62e9, 0x56fe, 0x7247, 0x6240, 0x5728, 0x76ee, 0x5f55, 0 };
const DIALOG_TITLE: [*:0]const u16 = &dialog_title_arr;

fn utf16ZLen(p:[*]const u16) usize {
    var i: usize = 0;
    while (p[i] != 0) : (i += 1) {}
    return i;
}

/// UTF-16 -> UTF-8（处理代理对）
fn utf16ToUtf8(alloc: std.mem.Allocator, s: []const u16) ![]u8 {
    var total: usize = 0;
    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        const ch = s[i];
        if (ch >= 0xD800 and ch <= 0xDBFF) {
            if (i + 1 >= s.len) return error.InvalidUtf16;
            i += 1;
            total += 4;
        } else if (ch >= 0x800) total += 3
        else if (ch >= 0x80) total += 2
        else total += 1;
    }
    const out = try alloc.alloc(u8, total);
    var o: usize = 0;
    i = 0;
    while (i < s.len) : (i += 1) {
        const ch = s[i];
        if (ch >= 0xD800 and ch <= 0xDBFF) {
            const lo = s[i + 1];
            const cp: u32 = 0x10000 + (((@as(u32, ch)) - 0xD800) << 10) + (@as(u32, lo) - 0xDC00);
            out[o] = @as(u8, 0xF0) | @as(u8, @intCast(cp >> 18));
            out[o + 1] = 0x80 | @as(u8, @intCast((cp >> 12) & 0x3F));
            out[o + 2] = 0x80 | @as(u8, @intCast((cp >> 6) & 0x3F));
            out[o + 3] = 0x80 | @as(u8, @intCast(cp & 0x3F));
            o += 4;
            i += 1;
        } else if (ch >= 0x800) {
            out[o] = @as(u8, 0xE0) | @as(u8, @intCast(ch >> 12));
            out[o + 1] = 0x80 | @as(u8, @intCast((ch >> 6) & 0x3F));
            out[o + 2] = 0x80 | @as(u8, @intCast(ch & 0x3F));
            o += 3;
        } else if (ch >= 0x80) {
            out[o] = @as(u8, 0xC0) | @as(u8, @intCast(ch >> 6));
            out[o + 1] = 0x80 | @as(u8, @intCast(ch & 0x3F));
            o += 2;
        } else {
            out[o] = @intCast(ch);
            o += 1;
        }
    }
    return out[0..o];
}

/// 弹出"选择文件夹"对话框，成功返回 UTF-8 路径（调用方负责 free）
fn pickDirectory(alloc: std.mem.Allocator, hwnd: ?*anyopaque) ?[]u8 {
    
    var obj: ?*anyopaque = null;
    const hr = CoCreateInstance(&CLSID_FileOpenDialog, null, CLSCTX_ALL, &IID_IFileDialog, &obj);
    if (hr != S_OK or obj == null) return null;
    const dialog = @as(*IFileDialog, @ptrCast(@alignCast(obj.?))); // COM 对象至少指针对齐
    defer _ = dialog.vtbl.release(dialog);

    _ = dialog.vtbl.set_options(dialog, FOS_PICKFOLDERS);
    _ = dialog.vtbl.set_title(dialog, DIALOG_TITLE);

    // S_OK=确认, S_FALSE=取消
    if (dialog.vtbl.show(dialog, hwnd) != S_OK) return null;

    var item: *IShellItem = undefined;
    if (dialog.vtbl.get_result(dialog, &item) != S_OK) return null;
    defer _ = item.vtbl.release(item);

    var wname: *u16 = undefined;
    if (item.vtbl.get_display_name(item, SIGDN_FILESYSPATH, &wname) != S_OK) return null;
    
    //const wname_ptr: [*:0]const u16 = @ptrCast(wname);
    //const path = utf16ToUtf8(alloc, wname_ptr) catch null;
    
    const wname_ptr: [*]const u16 = @ptrCast(wname);
    const len = utf16ZLen(wname_ptr);
    
    const wname_slice = wname_ptr[0..len];
    const path = utf16ToUtf8(alloc, wname_slice) catch null;
    
    CoTaskMemFree(@ptrCast(wname));
    return path;
}

// ===========================================================================
// 应用部分
// ===========================================================================

const help_lines = [_][]const u8{
    "图 片 查 看 器   ( Zig + raylib )",
    "",
    "    O      打开 / 选择图片目录",
    "    A      上一张图片",
    "    D      下一张图片",
    "   空格     适应窗口 / 原尺寸  切换",
    "    F      全屏 / 窗口  切换",
    "    Q      退出程序",
    "",
    "  原尺寸模式下：按住鼠标右键拖动可移动图片",
    "  ( ESC 也可以退出 )",
};

const image_exts = [_][]const u8{ "png", "jpg", "jpeg", "bmp", "tga", "hdr" };

const BLACK = c.Color{ .r = 0, .g = 0, .b = 0, .a = 255 };
const WHITE = c.Color{ .r = 255, .g = 255, .b = 255, .a = 255 };
const TEXT_MAIN = c.Color{ .r = 230, .g = 230, .b = 230, .a = 255 };
const TEXT_WARN = c.Color{ .r = 255, .g = 200, .b = 90, .a = 255 };
const BAR_BG = c.Color{ .r = 22, .g = 22, .b = 22, .a = 215 };

const State = struct {
    alloc: std.mem.Allocator,
    io: std.Io, // 0.16 所有文件系统操作都要显式传 Io

    dir: ?std.Io.Dir = null, // 0.16: std.fs.Dir -> std.Io.Dir
    dir_path: ?[]u8 = null,
    // 每个文件名都是独立分配（且带 NUL 哨兵，供 C API 使用），排序在切片上原地进行
    files: ?[][]const u8 = null,
    cur: usize = 0,

    texture: ?c.Texture2D = null,
    tex_w: i32 = 0,
    tex_h: i32 = 0,

    fit: bool = true,
    pan_x: f32 = 0,
    pan_y: f32 = 0,
    dragging: bool = false,
    last_mx: f32 = 0,
    last_my: f32 = 0,

    font: ?c.Font = null,

    msg: ?[]const u8 = null,
    msg_static: bool = false,
};

/// 动态消息统一以 NUL 结尾分配，之后才能安全传给 DrawTextEx 等 C API
fn setMsg(st: *State, comptime fmt: []const u8, args: anytype) void {
    clearMsg(st);
    st.msg_static = false;
    const raw = std.fmt.allocPrint(st.alloc, fmt, args) catch {
        st.msg = "错误";
        st.msg_static = true;
        return;
    };
    st.msg = st.alloc.dupeZ(u8, raw) catch {
        st.alloc.free(raw);
        st.msg = "错误";
        st.msg_static = true;
        return;
    };
    st.alloc.free(raw);
}

fn clearMsg(st: *State) void {
    if (st.msg) |m| {
        if (!st.msg_static) st.alloc.free(m);
    }
    st.msg = null;
    st.msg_static = false;
}

fn freeFiles(st: *State) void {
    if (st.files) |f| {
        for (f) |n| st.alloc.free(n);
        st.alloc.free(f);
    }
    st.files = null;
}

fn hasImageExt(name: []const u8) bool {
    const dot = std.mem.lastIndexOfScalar(u8, name, '.') orelse return false;
    const ext = name[dot + 1 ..];
    for (image_exts) |e| {
        if (std.ascii.eqlIgnoreCase(ext, e)) return true;
    }
    return false;
}

fn nameLess(a: []const u8, b: []const u8) bool {
    const n = @min(a.len, b.len);
    for (0..n) |i| {
        const ca = std.ascii.toLower(a[i]);
        const cb = std.ascii.toLower(b[i]);
        if (ca != cb) return ca < cb;
    }
    return a.len < b.len;
}

/// 目录内文件数一般不大，插入排序足够；原地排序，元素可写
fn sortFiles(items: [][]const u8) void {
    var i: usize = 1;
    while (i < items.len) : (i += 1) {
        const key = items[i];
        var j = i;
        while (j > 0 and nameLess(key, items[j - 1])) : (j -= 1) {
            items[j] = items[j - 1];
        }
        items[j] = key;
    }
}

fn collectCodepoints(list: *std.ArrayList(u32), alloc: std.mem.Allocator, s: []const u8) !void {
    // 1. 修改返回值为 !void，以便正确传递错误，而不是静默忽略
    
    // 2. 使用 Utf8View 包装字符串，这会一次性验证整个字符串的 UTF-8 合法性
    // 如果 s 包含非法 UTF-8，这里会返回 error.InvalidUtf8
    var view = try std.unicode.Utf8View.init(s);
    
    // 3. 获取迭代器
    var iter = view.iterator();

    // 4. 遍历码点
    while (iter.nextCodepoint()) |cp| {
        // 只有在这里，cp 才是合法的 Unicode 码点
        if (cp >= 0x20) {
            // 使用 try 将内存分配错误向上传递
            try list.append(alloc, cp);
        }
    }
}

fn sortUnique(items: *[]u32) void {
    const arr = items.*;
    var i: usize = 1;
    while (i < arr.len) : (i += 1) {
        const key = arr[i];
        var j = i;
        while (j > 0 and arr[j - 1] > key) : (j -= 1) {
            arr[j] = arr[j - 1];
        }
        arr[j] = key;
    }
    var w: usize = 0;
    var r: usize = 0;
    while (r < arr.len) : (r += 1) {
        if (w == 0 or arr[r] != arr[w - 1]) {
            arr[w] = arr[r];
            w += 1;
        }
    }
    items.* = arr[0..w];
}

/// 重建字体图集：覆盖帮助文字 + 状态栏 + 目录路径 + 全部文件名中的码点，
/// 保证任意中文文件名都能正常显示
fn loadFont(st: *State) void {
    if (st.font) |f| c.UnloadFont(f);
    st.font = null;

    var cps: std.ArrayList(u32) = .empty;
    defer cps.deinit(st.alloc);

    for (help_lines) |line| collectCodepoints(&cps, st.alloc, line) catch {};
    
    collectCodepoints(&cps, st.alloc, "适应窗口原尺寸[()/0123456789.-|: ") catch {};
    if (st.dir_path) |p| collectCodepoints(&cps, st.alloc, p) catch {};
    if (st.files) |fs| for (fs) |name| collectCodepoints(&cps, st.alloc, name) catch {};
    if (st.msg) |m| collectCodepoints(&cps, st.alloc, m) catch {};

    sortUnique(&cps.items);

    // 注意：字符串字面量才有隐式哨兵；数组元素类型必须声明成 [*:0]const u16/u8
    const font_paths = [_][*:0]const u8{
        "C:\\Windows\\Fonts\\simhei.ttf", // 黑体
        "C:\\Windows\\Fonts\\simsun.ttc", // 宋体
        "C:\\Windows\\Fonts\\msjh.ttc",   // 微软正黑体
    };
    for (font_paths) |p| {
        //std.debug.print("------- {s}\n", .{p});
        // 参数类型是 [*c]c_int（C 指针，允许空值），不要包可选类型
        const cp_ptr: [*c]c_int = if (cps.items.len == 0)
            null
        else
            @ptrCast(cps.items.ptr);
        const f = c.LoadFontEx(p, 24, cp_ptr, @as(c_int, @intCast(cps.items.len)));
        if (f.texture.id != 0) {
            st.font = f;
            break;
        }
    }
}

/// 读取当前文件并解码上传为纹理；上传后立即释放 CPU 端 Image
fn loadTexture(st: *State) void {
    const fs = st.files orelse return;
    const dir = st.dir orelse return;
    const name = fs[st.cur];

    _ = dir; // 目录句柄仅用于遍历，读文件走 cwd + 绝对路径

    const dir_s = st.dir_path orelse return;
    // 避开 0.16 已知的 "iterate 句柄上 readFileAlloc 失败" 问题，改从 cwd 读绝对路径
    const full_path = std.fs.path.join(st.alloc, &.{ dir_s, name }) catch {
        setMsg(st, "内存不足", .{});
        return;
    };
    defer st.alloc.free(full_path);
    

    const data = std.Io.Dir.cwd().readFileAlloc(st.io, full_path, st.alloc, .limited(1 << 30)) catch {
        setMsg(st, "读取文件失败: {s}", .{name});
        return;
    };
    defer st.alloc.free(data);

    std.debug.print("loadTexture from file {s}, name is{s}, length is {d}!\n", .{full_path, name, data.len});
    
    // name 指向的内存紧跟 NUL 哨兵（dupeZ 分配），可安全作为 C 字符串
    const filetype = std.fs.path.extension(name);
    const img = c.LoadImageFromMemory(filetype.ptr, data.ptr, @as(c_int, @intCast(data.len)));
    
    std.debug.print("image width={d} height={d}\n", .{img.width, img.height});
    
    if (img.width <= 0 or img.height <= 0) {
        c.UnloadImage(img);
        setMsg(st, "图片解码失败: {s}", .{name});
        return;
    }

    const w = img.width;
    const h = img.height;
    const tex = c.LoadTextureFromImage(img);
    c.UnloadImage(img);

    if (st.texture) |old| c.UnloadTexture(old);
    st.texture = tex;
    st.tex_w = w;
    st.tex_h = h;
    st.pan_x = 0;
    st.pan_y = 0;

    c.SetTextureFilter(tex, if (st.fit) c.TEXTURE_FILTER_BILINEAR else c.TEXTURE_FILTER_POINT);
    clearMsg(st);
}

fn switchDir(st: *State, hwnd: ?*anyopaque) void {
    
    //std.debug.print("begin switchDir !\n", .{});
    
    const path = pickDirectory(st.alloc, hwnd) orelse return; // 取消则保持原状态
    defer st.alloc.free(path);
    
    std.debug.print("pickDirectory = {s} !\n", .{path});

    // ---- 释放旧目录的全部资源 ----
    if (st.texture) |t| c.UnloadTexture(t);
    st.texture = null;
    if (st.dir) |d| d.close(st.io);
    st.dir = null;
    if (st.dir_path) |p| st.alloc.free(p);
    st.dir_path = null;
    freeFiles(st);
    st.cur = 0;
    clearMsg(st);

    const dir = std.Io.Dir.cwd().openDir(st.io, path, .{ .iterate = true }) catch {
        setMsg(st, "无法打开目录: {s}", .{path});
        return;
    };
    st.dir = dir;
    st.dir_path = st.alloc.dupe(u8, path) catch {
        setMsg(st, "内存不足", .{});
        return;
    };

    // std.fs.Dir 没有 readSubAlloc；标准做法是用 iterate 逐个收集
    var names: std.ArrayList([]const u8) = .empty;
    defer names.deinit(st.alloc);

    var it = dir.iterate();
    while (it.next(st.io) catch null) |entry| {
        if (entry.kind != .file) continue; // 同时排除目录和符号链接
        if (!hasImageExt(entry.name)) continue;
        const dup = st.alloc.dupeZ(u8, entry.name) catch continue; // 带哨兵，供 C API 使用
        names.append(st.alloc, dup) catch {
            st.alloc.free(dup);
            continue;
        };
    }

    const arr = names.toOwnedSlice(st.alloc) catch {
        setMsg(st, "内存不足", .{});
        return;
    };
    sortFiles(arr);
    st.files = arr;

    if (arr.len == 0) {
        setMsg(st, "该目录下没有支持的图片（png / jpg / bmp / tga / hdr）", .{});
    } else {
        st.cur = 0;
        loadTexture(st);
    }
    //loadFont(st); // 重建字体图集，覆盖新目录的文件名
}

fn drawHelp(st: *State) void {
    const sw = @as(f32, @floatFromInt(c.GetScreenWidth()));
    const sh = @as(f32, @floatFromInt(c.GetScreenHeight()));
    const fsize: f32 = 22;
    const lh: f32 = 34;
    var y = (sh - @as(f32, @floatFromInt(help_lines.len)) * lh) / 2.0;
    for (help_lines) |line| {
        if (st.font) |f| {
            const tw = c.MeasureTextEx(f, line.ptr, fsize, 1.0).x;
            c.DrawTextEx(f, line.ptr, .{ .x = (sw - tw) / 2.0, .y = y }, fsize, 1.0, TEXT_MAIN);
        } else {
            const tw = @as(f32, @floatFromInt(c.MeasureText(line.ptr, 20)));
            c.DrawText(line.ptr, @as(i32, @intFromFloat((sw - tw) / 2.0)), @as(i32, @intFromFloat(y)), 20, TEXT_MAIN);
        }
        y += lh;
    }
    if (st.msg) |m| {
        if (st.font) |f| {
            const tw = c.MeasureTextEx(f, m.ptr, 20, 1.0).x;
            c.DrawTextEx(f, m.ptr, .{ .x = (sw - tw) / 2.0, .y = sh - 50 }, 20, 1.0, TEXT_WARN);
        }
    }
}

fn drawStatusBar(st: *State) void {
    const fs = st.files orelse return;
    if (fs.len == 0) return;
    const sw = c.GetScreenWidth();
    const sh = c.GetScreenHeight();
    const bar_h: i32 = 30;
    c.DrawRectangle(0, sh - bar_h, sw, bar_h, BAR_BG);
    const dir_s = st.dir_path orelse "";
    const name = fs[st.cur];
    const mode = if (st.fit) "适应窗口" else "原尺寸";
    const buf = std.fmt.allocPrint(st.alloc, "{s}   {s}   [{d}/{d}]   {s}", .{ dir_s, name, st.cur + 1, fs.len, mode }) catch return;
    defer st.alloc.free(buf);
    const bufZ = st.alloc.dupeZ(u8, buf) catch return;
    defer st.alloc.free(bufZ);
    if (st.font) |f| {
        c.DrawTextEx(f, bufZ, .{ .x = 10, .y = @as(f32, @floatFromInt(sh - bar_h + 4)) }, 20, 1.0, TEXT_MAIN);
    }
}

fn cleanup(st: *State) void {
    if (st.texture) |t| c.UnloadTexture(t);
    if (st.font) |f| c.UnloadFont(f);
    if (st.dir) |d| d.close(st.io);
    if (st.dir_path) |p| st.alloc.free(p);
    freeFiles(st);
    clearMsg(st);
}

pub fn main(init: std.process.Init) !void {
    const alloc = std.heap.page_allocator;
    const io = init.io; // 0.16: io 从进程初始化参数拿到

    _ = CoInitializeEx(null, 2); // COINIT_APARTMENTTHREADED

    c.SetConfigFlags(c.FLAG_VSYNC_HINT | c.FLAG_WINDOW_RESIZABLE);
    c.InitWindow(DEFAULT_WIDTH, DEFAULT_HEIGHT, "图片查看器");
    defer c.CloseWindow();
    defer CoUninitialize();

    // 窗口居中
    const mw = c.GetMonitorWidth(0);
    const mh = c.GetMonitorHeight(0);
    if (mw > DEFAULT_WIDTH and mh > DEFAULT_HEIGHT) {
        c.SetWindowPosition(@divFloor((mw - DEFAULT_WIDTH) , 2), @divFloor((mh - DEFAULT_HEIGHT) , 2));
    }

    var st: State = .{ .alloc = alloc, .io = io };
    defer cleanup(&st);

    loadFont(&st); // 先加载帮助文字字体（GL 上下文已就绪）

    const hwnd = c.GetWindowHandle(); // 返回值本身就是 ?*anyopaque
    
    while (!c.WindowShouldClose()) {
        // ---------------- 按键 ----------------
        if (c.IsKeyPressed(c.KEY_O)) {
            switchDir(&st, hwnd);
        } else if (c.IsKeyPressed(c.KEY_A)) {
            if (st.files) |fs| {
                if (fs.len > 0) {
                    st.cur = if (st.cur == 0) fs.len - 1 else st.cur - 1; // 循环
                    loadTexture(&st);
                }
            }
        } else if (c.IsKeyPressed(c.KEY_D)) {
            if (st.files) |fs| {
                if (fs.len > 0) {
                    st.cur = (st.cur + 1) % fs.len; // 循环
                    loadTexture(&st);
                }
            }
        } else if (c.IsKeyPressed(c.KEY_SPACE)) {
            st.fit = !st.fit;
            if (st.texture) |t| {
                c.SetTextureFilter(t, if (st.fit) c.TEXTURE_FILTER_BILINEAR else c.TEXTURE_FILTER_POINT);
            }
        } else if (c.IsKeyPressed(c.KEY_F)) {
            c.ToggleFullscreen();
        } else if (c.IsKeyPressed(c.KEY_Q)) {
            break; // q / Q 都对应 KEY_Q
        }

        // ---------------- 右键拖拽（仅原尺寸模式） ----------------
        if (st.fit) {
            st.dragging = false;
        } else {
            if (c.IsMouseButtonPressed(c.MOUSE_BUTTON_RIGHT)) {
                st.dragging = true;
                st.last_mx = @as(f32, @floatFromInt(c.GetMouseX()));
                st.last_my = @as(f32, @floatFromInt(c.GetMouseY()));
            } else if (c.IsMouseButtonReleased(c.MOUSE_BUTTON_RIGHT)) {
                st.dragging = false;
            }
            if (st.dragging) {
                const mx = @as(f32, @floatFromInt(c.GetMouseX()));
                const my = @as(f32, @floatFromInt(c.GetMouseY()));
                st.pan_x += mx - st.last_mx; // 图片跟随鼠标
                st.pan_y += my - st.last_my;
                st.last_mx = mx;
                st.last_my = my;
            }
        }

        // ---------------- 渲染 ----------------
        c.BeginDrawing();
        c.ClearBackground(BLACK);

        if (st.texture) |tex| {
            const sw = @as(f32, @floatFromInt(c.GetScreenWidth()));
            const sh = @as(f32, @floatFromInt(c.GetScreenHeight()));
            const iw = @as(f32, @floatFromInt(st.tex_w));
            const ih = @as(f32, @floatFromInt(st.tex_h));

            if (st.fit) {
                // 适应窗口：等比缩放 + 居中
                const scale = @min(sw / iw, sh / ih);
                const dw = iw * scale;
                const dh = ih * scale;
                c.DrawTextureEx(tex, .{ .x = (sw - dw) / 2.0, .y = (sh - dh) / 2.0 }, 0.0, scale, WHITE);
            } else {
                // 原尺寸：钳制偏移，保证图片始终部分可见
                var px = st.pan_x;
                var py = st.pan_y;
                px = if (iw <= sw) (sw - iw) / 2.0 else @max(sw - iw, @min(0.0, px));
                py = if (ih <= sh) (sh - ih) / 2.0 else @max(sh - ih, @min(0.0, py));
                st.pan_x = px;
                st.pan_y = py;
                c.DrawTextureEx(tex, .{ .x = px, .y = py }, 0.0, 1.0, WHITE);
            }
            drawStatusBar(&st);
        } else {
            drawHelp(&st);
        }

        c.EndDrawing();
    }
}
