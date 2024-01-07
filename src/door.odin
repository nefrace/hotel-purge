package main 

import "tic"
import "core:math/rand"
import "core:strings"

SPR_DOOR_CLOSED :: 2
SPR_DOOR_OPENED :: 4

Door :: struct {
    pos: vec2,
    time_to_spawn: i16,
    spawn_timer: i8,
    type: PeopleType,
    is_occupied: bool,
}

update_door :: proc(door: ^Door, game: ^Game) {
    if door.time_to_spawn == -1 do return
    door.time_to_spawn -= 1
    door.is_occupied = false
    for p in game.people {
        if p.pos == door.pos {
            door.is_occupied = true
        }
    }
    if door.time_to_spawn == 0 {
        door.time_to_spawn = i16(rand.int_max(100) + 120)
        if door.is_occupied { return }
        if len(game.people) >= 6 { return }
        if game.people_to_spawn == 0 { return }
        game.people_to_spawn -= 1
        door.spawn_timer = 1
    }
    if door.spawn_timer > 0 {
        door.spawn_timer += 1
        if door.spawn_timer == 60 {
            door.spawn_timer = 0
            people := People {
                reaction_time = i16(rand.int_max(50) + 30),
                pos = door.pos,
                sprite = 288,
                type = door.type,
            }
            game.anyone_spawned = true
            append(&game.people, people)
        }
    }
}

draw_door :: proc(door: ^Door, game: ^Game) {
    sprite : i32 = SPR_DOOR_CLOSED
    if door.spawn_timer > 30 {
        sprite = SPR_DOOR_OPENED
    }
    tic.sprite(sprite, door.pos.x - game.camera.x, door.pos.y - game.camera.y, -1, 1, 0, 0, 2, 2)
}