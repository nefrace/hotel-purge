package main

import "tic"
import "core:runtime"
import "core:mem"


vec2 :: [2]i32
vec2f :: [2]f32

vec2tof :: proc(vec: vec2) -> vec2f {
    return {f32(vec.x), f32(vec.y)}
}


State :: union {
    Game,
    Menu
}

current_state: State

@export
BOOT :: proc "c"() {
    current_state = menu_init()
}

@export
TIC :: proc "c"() {
    context = runtime.default_context()
    switch state in current_state {
        case Game:
            game_tic(&current_state.(Game))
        case Menu:
            menu_tic(&current_state.(Menu))
    }
}