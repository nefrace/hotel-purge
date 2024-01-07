package main

import "tic"
import "core:slice"


Menu :: struct {
    text : cstring,
    y: f32,
    v: f32,
}

menu_init :: proc () -> Menu {
    return Menu{
        text = "Press A to start",
        y = 40,
        v = 0,
    }
} 

menu_tic :: proc (menu: ^Menu) -> SwitchTo {
    menu.v += .1
    menu.y += menu.v
    if menu.y > 130 {
        menu.y = 130
        menu.v = -4
    }
    if tic.button_pressed(tic.BUTTONS.A) {
        return .GAME
    }
    tic.cls(13)

    tic.draw_map(0, 0)
    tic.print("Operation Continental", 2, 2, 8, false, 2)
    tic.print("Press Z to start", 2, 50, 8)

    tic.print("Arrows to aim left/right", 2, 80, 9)
    tic.print("Z to shoot\nDown to crouch and\ndodge bullets", 2, 88, 9)
    tic.print("Down + Z to save civilian\nin front of you", 2, 108, 9)
    tic.print("X to reload", 2, 122, 9)
    tic.print_string(printf("Civilians saved record: %", MAX_SAVED), 110, 20, 9)
    tic.print_string(printf("Bandits killed record: %", MAX_KILLED), 110, 28, 9)

    return .NO
}
