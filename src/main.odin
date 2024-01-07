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

SwitchTo :: enum{
    NO,
    MENU,
    GAME
}

MAX_SAVED : i32 = 0
MAX_KILLED : i32 = 0

@export
BOOT :: proc "c"() {
    MAX_SAVED = tic.pmem(0)
    MAX_KILLED = tic.pmem(1)
    context = runtime.default_context()
    current_state = menu_init()
}

@export
TIC :: proc "c"() {
    context = runtime.default_context()
    new_scene : SwitchTo
    switch state in current_state {
        case Game:
            new_scene = game_tic(&current_state.(Game))
        case Menu:
            new_scene = menu_tic(&current_state.(Menu))
    }
    switch new_scene {
        case .GAME: {tic.trace_string("to the game!"); current_state = game_init()}
        case .MENU: {tic.trace_string("to the menu!"); current_state = menu_init()}
        case .NO: {}
    }
}