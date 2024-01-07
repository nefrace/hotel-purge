package tic

foreign import tic "env"
import "core:strings"
import "core:runtime"

SCREEN_WIDTH :: 240
SCREEN_HEIGHT :: 136
SCREEN_LENGTH :: SCREEN_WIDTH * SCREEN_HEIGHT / 2

COLOR :: [3]u8

VRAM := (^[16320]u8)(uintptr(0))
SCREEN := (^[SCREEN_LENGTH]u8)(uintptr(0))
PALETTE := (^[16]COLOR)(uintptr(0x3FC0))
PALETTE_MAP := (^[8]u8)(uintptr(0x3FF0))
BORDER_COLOR := (^u8)(uintptr(0x3FF8))

@(default_calling_convention="c")
foreign tic {
    // System
    tstamp :: proc() -> u32 --- 
    time :: proc() -> f32 --- 

    // Memory
    @(link_name="pmem")
    pmem_sys :: proc(index: i32, val: i32) -> i32 ---

	// Graphics
    cls :: proc(color: i8 = 0) --- 
    line :: proc(x1: f32, y1: f32, x2: f32, y2: f32, color: i8) --- 
	print :: proc(text: cstring, x: i32 = 0, y: i32 = 0, color: i8 = 15, fixed: bool = false, scale: u8 = 1, smallfont: bool = false) -> i32---
    spr :: proc(id: i32, x, y: i32, transparent_colors: [^]i8 = {}, color_count: u8 = 0, scale: u8 = 1, flip: u8 = 0, rotate: u8 = 0, w: u8 = 1, h: u8 = 1) --- 
    pix :: proc(x: i32, y: i32, color: i8) -> i8 --- 
    @(link_name="map")
    tic_map :: proc(x: i32 = 0, y: i32 = 0, w: i32 = 30, h: i32 = 17, sx: i32 = 0, sy: i32 = 0, colorkey: [^]i8 = {}, color_count: u8 = 0, scale: i8 = 1, remap: i32 = 0) ---
    rect :: proc(x, y, w, h: i32, color: i8) --- 

    // Sound
    sfx :: proc(id: i8, note: i8 = -1, octave: i8 = -1, duration: i32 = -1, channel: u8 = 0, volume_left: u8 = 15, volume_right: u8 = 15, speed: i8 = 0) --- 

    // Input
    btn :: proc(id: i32) -> i32 ---
    btnp :: proc(id: i32, hold: i32 = -1, period: i32 = -1) -> bool ---

    // Debug
    trace :: proc(str: cstring, color: i32 = 12) ---
}

sprite_colorkey_slice :: proc "c" (id: i32, x, y: i32, colorkey: []i8 = {}, scale: u8 = 1, flip: u8 = 0, rotate: u8 = 0, w: u8 = 1, h: u8 = 1) {
    spr(id, x, y, raw_data(colorkey), u8(len(colorkey)), scale, flip, rotate, w, h)
}

sprite_colorkey_single :: proc "c" (id: i32, x, y: i32, colorkey: i8 = 0, scale: u8 = 1, flip: u8 = 0, rotate: u8 = 0, w: u8 = 1, h: u8 = 1) {
    sprite_colorkey_slice(id, x, y, {colorkey}, scale, flip, rotate, w, h)
}

sprite :: proc{sprite_colorkey_single, sprite_colorkey_slice}

draw_map :: proc "c" (x: i32 = 0, y: i32 = 0, w: i32 = 30, h: i32 = 17, sx: i32 = 0, sy: i32 = 0, colorkey: []i8 = {}, scale: i8 = 1, remap: i32 = 0) {
    tic_map(x, y, w, h, sx, sy, raw_data(colorkey), u8(len(colorkey)), scale, remap)
}

line_vec :: proc "c" (start: [2]f32, end: [2]f32, color: i8) {
    line(start.x, start.y, end.x, end.y, color)
}

draw_line :: proc{line, line_vec}

button :: proc "c" (button: BUTTONS) -> bool {
    return btn(i32(button)) != 0
}

button_bits :: proc "c" () -> u32 {
    return transmute(u32)btn(-1)
}

button_pressed :: proc "c" (button: BUTTONS, hold: i32 = -1, period: i32 = -1) -> bool {
    return btnp(i32(button), hold, period)
}

BUTTONS :: enum i32 {
    UP,
    DOWN,
    LEFT,
    RIGHT,
    A,
    B,
    X,
    Y
}

pix_set :: proc "c" (x, y: i32, color: i8) {
    pix(x, y, color)
}
pix_get :: proc "c" (x, y: i32) -> i8 {
    return pix(x, y, -1)
}

pmem_set :: proc "c" (index: i32, value: i32) -> i32 {
    return pmem_sys(index, value)
}
pmem_get :: proc "c" (index: i32) -> i32 {
    return pmem_sys(index, -1)
}
pmem :: proc{pmem_set, pmem_get}

trace_string :: proc "c" (str: string) {
    context = runtime.default_context()
    trace(strings.unsafe_string_to_cstring(str))
}

print_string :: proc "c" (str: string, x: i32 = 0, y: i32 = 0, color: i8 = 15, fixed: bool = false, scale: u8 = 1, smallfont: bool = false) -> i32 { 
    context = runtime.default_context()
    return print(strings.unsafe_string_to_cstring(str), x, y, color, fixed, scale, smallfont)
}