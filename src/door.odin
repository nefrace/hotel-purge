package main 

import "tic"
import "core:math/rand"
import "core:strings"

SPR_DOOR_CLOSED :: 2
SPR_DOOR_OPENED :: 4

Door :: struct {
    pos: vec2,
    time_to_spawn: i16,
}

spawn_door :: proc(pos: vec2, time_to_spawn: i16) -> Door {
    return Door{
        pos,
        time_to_spawn,
    }
}

update_door :: proc(door: ^Door, game: ^Game) {
    if door.time_to_spawn == -1 do return
    door.time_to_spawn -= 1
    if door.time_to_spawn == 0 {
        enemy := Enemy {
            reaction_time = i16(rand.int_max(50) + 30),
            pos = door.pos,
            sprite = 288,
        }
        append(&game.enemies, enemy)
    }
}

draw_door :: proc(door: ^Door, game: ^Game) {
    sprite : i32 = SPR_DOOR_CLOSED
    if door.time_to_spawn <= 30 && door.time_to_spawn > 0 do sprite = SPR_DOOR_OPENED
    tic.sprite(sprite, door.pos.x - game.camera.x, door.pos.y - game.camera.y, -1, 1, 0, 0, 2, 2)
}