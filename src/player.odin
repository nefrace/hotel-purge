package main

import "tic"
import "core:slice"
import "core:strings"

Player :: struct {
    sprite : i32,
    health : u8,
    ammo : u8,
    reload_time: i16,
    direction : i8,
    pos : vec2,
    is_sitting : bool,
    shot_rays : [dynamic]ShotRay
}

ShotRay :: struct{lifetime: i8, start: vec2, end: vec2}
rays_buf : [10]ShotRay

init_player :: proc(pos: vec2) -> Player {
    player := Player{
        ammo = 6,
        direction = 1,
        health = 6,
        reload_time = -1,
        is_sitting = false,
        sprite = 256,
        pos = {104 * 8, 133 * 8},
        shot_rays = slice.into_dynamic(rays_buf[:]),
    }
    return player
}


update_player :: proc(player: ^Player, game: ^Game) {
    if player.reload_time > -1 {
        player.reload_time -= 1
        if player.reload_time == 0 {
            player.ammo = 6
            tic.sfx(1, 0, 5, speed=4)
        }
    }

    if tic.button(tic.BUTTONS.LEFT) { player.direction = -1 }
    if tic.button(tic.BUTTONS.RIGHT) { player.direction = 1 }
    if tic.button_pressed(tic.BUTTONS.A) { player_shoot(player, game) }
    if tic.button_pressed(tic.BUTTONS.B) { player.reload_time = 30 }
    if tic.button_pressed(tic.BUTTONS.X) { player.health -= 1 }
}

player_shoot :: proc(player: ^Player, game: ^Game) {
    if player.ammo == 0 { return }
    player.ammo -= 1
    tic.sfx(0, 0, 4, speed=1)
    ray_start := vec2{
        player.pos.x + (player.direction > 0 ? 16 : 0),
        player.pos.y + 7,
    }
    ray_end := ray_start
    ray_direction := vec2{i32(player.direction), 0}
    ray_hit := false
    rayloop: for x := 1; x < 120; x += 1 {
        ray_end = ray_start + ray_direction * i32(x)
        for _, i in game.enemies {
            enemy := &game.enemies[i]
            if (ray_end.x > enemy.pos.x &&
                ray_end.y > enemy.pos.y &&
                ray_end.x < enemy.pos.x + 16 &&
                ray_end.y < enemy.pos.y + 16) {
                ray_hit = true
                enemy.is_dead = true
                break rayloop
            }
        }
    }
    ray := ShotRay{
        start = ray_start,
        end = ray_end,
        lifetime = 5,
    }
    append(&player.shot_rays, ray)
}


draw_player :: proc(game: ^Game) {
    player := &game.player
    cam := game.camera
    tic.sprite(
        player.sprite,
        player.pos.x - cam.x, player.pos.y - cam.y,
        0,
        1,
        player.direction == 1 ? 0 : 1,
        0,
        2,
        2,
    )
    #reverse for _, i in player.shot_rays {
        ray := &player.shot_rays[i]
        tic.draw_line(vec2tof(ray.start) - vec2tof(cam), vec2tof(ray.end) - vec2tof(cam), 4 - (4 - ray.lifetime))
        ray.lifetime -= 1
        if ray.lifetime <= 0 {
            unordered_remove(&player.shot_rays, i)
        }
    }
}