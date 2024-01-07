package main

import "tic"
import "core:slice"
import "core:strings"

SPR_PLAYER_IDLE :: 256
SPR_PLAYER_SITTING :: 258
SPR_PLAYER_DEAD :: [?]i32{260, 262}

PLAYER_MAX_AMMO :: 6
PLAYER_RELOAD_TIME :: 60

Player :: struct {
    health : u8,
    ammo : u8,
    direction : i8,
    hit_timer : i8,
    reload_time : i16,
    dead_timer : i16,
    pos : vec2,
    is_sitting : bool,
    is_dead: bool,
}


init_player :: proc(pos: vec2) -> Player {
    player := Player{
        ammo = 6,
        direction = 1,
        health = 6,
        reload_time = -1,
        is_sitting = false,
        is_dead = false,
        dead_timer = 0,
        pos = {104 * 8, 133 * 8},
    }
    return player
}


update_player :: proc(player: ^Player, game: ^Game) {
    if game.game_over do return
    if player.reload_time > -1 {
        player.reload_time -= 1
        if player.reload_time == 0 {
            player.ammo = PLAYER_MAX_AMMO
            tic.sfx(1, 0, 5, speed=4)
        }
    }
    if player.health == 0 {
        player.dead_timer += 1
    }

    if tic.button(tic.BUTTONS.LEFT) { player.direction = -1 }
    if tic.button(tic.BUTTONS.RIGHT) { player.direction = 1 }
    if tic.button_pressed(tic.BUTTONS.A) { player_shoot(player, game); player_call_civilian(player, game) }
    if tic.button_pressed(tic.BUTTONS.B) { player.reload_time = PLAYER_RELOAD_TIME }
    player.is_sitting = tic.button(tic.BUTTONS.DOWN)
}

player_shoot :: proc(player: ^Player, game: ^Game) {
    if player.is_sitting { return }
    if player.ammo == 0 { return }
    if player.reload_time > 0 { return }
    player.ammo -= 1
    tic.sfx(0, 0, 4, speed=1)
    ray_start := vec2{
        player.pos.x + (player.direction > 0 ? 16 : 0),
        player.pos.y + 7,
    }
    ray_end := ray_start
    ray_direction := vec2{i32(player.direction), 0}
    ray_hit := false
    rayloop: for x := 1; x < 120; x += 4 {
        ray_end = ray_start + ray_direction * i32(x)
        for _, i in game.people {
            enemy := &game.people[i]
            if (!enemy.is_dead && !enemy.is_running &&
                ray_end.x > enemy.pos.x &&
                ray_end.y > enemy.pos.y &&
                ray_end.x < enemy.pos.x + 16 &&
                ray_end.y < enemy.pos.y + 16) {
                ray_hit = true
                enemy.is_dead = true
                game.people_alive -= 1
                if enemy.type == .CIVILIAN {
                    game.game_over = true
                } else {
                    game.killed += 1
                }
                break rayloop
            }
        }
    }
    ray := ShotRay{
        start = ray_start,
        end = ray_end,
        lifetime = 5,
    }
    append(&game.shot_rays, ray)
}

player_call_civilian :: proc(player: ^Player, game: ^Game) {
    if !player.is_sitting { return }
    ray_start := vec2{
        player.pos.x + (player.direction > 0 ? 16 : 0),
        player.pos.y + 7,
    }
    ray_end := ray_start
    ray_direction := vec2{i32(player.direction), 0}
    ray_hit := false
    rayloop: for x := 1; x < 120; x += 4 {
        ray_end = ray_start + ray_direction * i32(x)
        for _, i in game.people {
            people := &game.people[i]
            if (!people.is_dead && !people.is_running && 
                ray_end.x > people.pos.x &&
                ray_end.y > people.pos.y &&
                ray_end.x < people.pos.x + 16 &&
                ray_end.y < people.pos.y + 16) {
                if people.type == .CIVILIAN {
                    people.is_running = true
                    game.people_alive -= 1
                    people.sprite = CIV_ANIMATION_RUNNING[0]
                }
                break rayloop
            }
        }
    }
}


draw_player :: proc(game: ^Game) {
    player := &game.player
    cam := game.camera
    sprite : i32
    if player.health > 0 {
        sprite = SPR_PLAYER_IDLE
        if player.is_sitting {
            sprite = SPR_PLAYER_SITTING
        }
    }
    else {
        if player.dead_timer > 0 do sprite = SPR_PLAYER_DEAD[0]
        if player.dead_timer > 30 do sprite = SPR_PLAYER_DEAD[1]
    }
    tic.sprite(
        sprite,
        player.pos.x - cam.x, player.pos.y - cam.y,
        0,
        1,
        player.direction == 1 ? 0 : 1,
        0,
        2,
        2,
    )


    if player.hit_timer > -1 {
        tic.BORDER_COLOR^ = u8(8 + (4 - player.hit_timer / 3))
        player.hit_timer -= 1
    } else {
        tic.BORDER_COLOR^ = 0
    }
}

player_hit :: proc(player: ^Player) {
    player.health -= 1
    player.hit_timer = 15
}