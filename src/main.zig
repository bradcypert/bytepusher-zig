const std = @import("std");
const rl = @import("raylib");
const palette_test = @embedFile("./Scrolling Logo.BytePusher");

const MEMORY_SIZE = 0x1000008;
const KEY_MEM_SIZE = 16;
const VIDEO_BUFF_SIZE = 256 * 256;
const SCREEN_WIDTH = 256;
const SCREEN_HEIGHT = 256;
const FPS = 60;

const COLOR_STEP = 0x33;
const COLOR_BLACK = rl.Color{ .r = 0, .g = 0, .b = 0, .a = 255 };

var memory: [MEMORY_SIZE]u8 = undefined;
var keyMem: [KEY_MEM_SIZE]u8 = undefined;
var videoBuff: [VIDEO_BUFF_SIZE]u8 = undefined;

const color_map = initColorMap();

fn initColorMap() [256]rl.Color {
    var c: [256]rl.Color = undefined;
    for (0..6) |r| for (0..6) |g| for (0..6) |b| {
        c[r * 36 + g * 6 + b] = rl.Color.init(r * COLOR_STEP, g * COLOR_STEP, b * COLOR_STEP, 255);
    };
    @memset(c[216..], COLOR_BLACK);
    return c;
}

fn load(buff: []const u8) void {
    @memset(&memory, 0);
    const len = @min(buff.len, std.math.maxInt(u24));
    @memcpy(memory[0..len], buff[0..len]);
}

fn update() void {
    var pc = std.mem.readInt(u24, memory[2 .. 2 + 3], .big);
    for (0..65536) |_| {
        const a = std.mem.readInt(u24, @ptrCast(memory[pc..]), .big);
        const b = std.mem.readInt(u24, @ptrCast(memory[pc + 3 ..]), .big);
        const c = std.mem.readInt(u24, @ptrCast(memory[pc + 6 ..]), .big);

        memory[b] = memory[a];
        pc = c;
    }
}

fn draw() void {
    rl.beginDrawing();
    defer rl.endDrawing();
    const pixels_addr = @as(u24, memory[5]) << 16;
    const pixels: *[VIDEO_BUFF_SIZE]u8 = @ptrCast(memory[pixels_addr..]);

    for (pixels, 0..VIDEO_BUFF_SIZE) |color_index, i| {
        const y = i / SCREEN_WIDTH;
        const x = i % SCREEN_WIDTH;
        rl.drawPixel(@intCast(x), @intCast(y), color_map[color_index]);
    }
}

pub fn main() anyerror!void {
    // Initialization

    load(palette_test);
    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Bytepusher Zig");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(FPS);

    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        update();
        draw();
    }
}
