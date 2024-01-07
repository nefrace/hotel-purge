package main

import "tic"


Menu :: struct {
    text : cstring,
    y: f32,
    v: f32
}

menu_init :: proc "c" () -> Menu {
    return Menu{
        text = "Press A to start",
        y = 40,
        v = 0,
    }
} 

menu_tic :: proc (menu: ^Menu) {
    menu.v += .1
    menu.y += menu.v
    if menu.y > 130 {
        menu.y = 130
        menu.v = -4
    }
    if tic.button_pressed(tic.BUTTONS.A) {
        current_state = game_init()
    }
    tic.cls()
    tic.print(menu.text, 20, i32(menu.y), 12)
}
