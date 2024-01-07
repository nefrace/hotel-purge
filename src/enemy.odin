package main

import "tic"
import "core:math/rand"

PeopleType :: enum {
    ENEMY,
    CIVILIAN
}

People :: struct {
    type: PeopleType,
    pos : vec2,
    sprite: i32,
    reaction_time: i16,
    dead_timer: i16,
    direction: i8,
    is_dead : bool,
    to_free : bool,
    is_running: bool,
    is_saved: bool,
    running_time: i16,
    ray: ShotRay,
}

ENEMY_ANIMATION_IDLE : i32 = 288
ENEMY_ANIMATION_RELOAD := [?]i32{290, 292, 290}
ENEMY_ANIMATION_DEAD := [?]i32{294, 296}
CIV_ANIMATION_IDLE : i32 = 320
CIV_ANIMATION_RUNNING := [?]i32{322, 324}
CIV_ANIMATION_DEAD := [?]i32{326, 328}

draw_enemy :: proc(enemy: ^People, game: ^Game) {
    cam := game.camera
    if enemy.dead_timer < 140 || enemy.dead_timer % 2 == 0 {
        tic.sprite(
            enemy.sprite,
            enemy.pos.x - cam.x, enemy.pos.y - cam.y,
            0,
            1,
            enemy.direction == 1 ? 0 : 1,
            0,
            2,
            2,
        )
    }
}

draw_civilian :: proc(civ: ^People, game: ^Game) {
    cam := game.camera
    if civ.dead_timer < 140 || civ.dead_timer % 2 == 0 {
        tic.sprite(
            civ.sprite,
            civ.pos.x - cam.x, civ.pos.y - cam.y,
            0,
            1,
            civ.direction == 1 ? 0 : 1,
            0,
            2,
            2,
        )
    }
}

update_civilian :: proc(civ: ^People, game: ^Game) {
    if civ.is_dead {
        switch civ.dead_timer {
            case 1: civ.sprite = CIV_ANIMATION_DEAD[0]
            case 20: civ.sprite = CIV_ANIMATION_DEAD[1]
        }
        civ.dead_timer += 1
        if civ.dead_timer > 180 {
            civ.to_free = true
        }
        return
    }
    if game.game_over do return
    if !civ.is_running {
        civ.sprite = CIV_ANIMATION_IDLE
    } else {
        civ.pos.x += i32(civ.direction)
        if abs(civ.pos.x - game.player.pos.x) < 5 {
            civ.to_free = true
            civ.is_saved = true
        }
        civ.running_time += 1
        switch civ.running_time % 40 {
            case 0: civ.sprite = CIV_ANIMATION_RUNNING[0]
            case 20: civ.sprite = CIV_ANIMATION_RUNNING[1]
        }
    }
    civ.direction = civ.pos.x > game.player.pos.x ? -1 : 1
}

update_enemy :: proc(enemy: ^People, game: ^Game) {
    if enemy.is_dead {
        switch enemy.dead_timer {
            case 1: enemy.sprite = ENEMY_ANIMATION_DEAD[0]
            case 20: enemy.sprite = ENEMY_ANIMATION_DEAD[1]
        }
        enemy.dead_timer += 1
        if enemy.dead_timer > 180 {
            enemy.to_free = true
        }
        return
    }
    if game.game_over do return
    enemy.reaction_time -= 1
    switch enemy.reaction_time {
        case 40: enemy.sprite = ENEMY_ANIMATION_RELOAD[0]
        case 20: {
            enemy.sprite = ENEMY_ANIMATION_RELOAD[1]
        }
        case 15: {
            enemy.sprite = ENEMY_ANIMATION_RELOAD[2]
            tic.sfx(1, 0, 5, speed=4, channel = 2, volume_left=5, volume_right=5)
        }
        case 10: enemy.sprite = ENEMY_ANIMATION_IDLE
        case 0: enemy_shoot(enemy, game)
    }
    enemy.direction = enemy.pos.x > game.player.pos.x ? -1 : 1

}

enemy_shoot :: proc(enemy: ^People, game: ^Game) {
    if game.player.health == 0 {
        return
    }
    tic.sfx(0, 0, 4, speed=0, channel=2)
    enemy.reaction_time = i16(rand.int_max(120) + 120)
    ray_start := vec2{
        enemy.pos.x + (enemy.direction > 0 ? 16 : 0),
        enemy.pos.y + 8,
    }
    ray_end := ray_start
    ray_direction := vec2{i32(enemy.direction), 0}
    ray_hit := false
    player := &game.player
    rayloop: for x := 1; x < 240; x += 4 {
        ray_end = ray_start + ray_direction * i32(x)
        if (!player.is_sitting && !(player.health <= 0) &&
                ray_end.x > player.pos.x &&
                ray_end.y > player.pos.y &&
                ray_end.x < player.pos.x + 16 &&
                ray_end.y < player.pos.y + 16) {
            ray_hit = true
            player_hit(player)
            break rayloop
        }
        // for _, i in game.people {
        //     other := &game.people[i]
        //     if other == enemy || other.direction == enemy.direction do continue
        //     if (ray_end.x > other.pos.x &&
        //         ray_end.y > other.pos.y &&
        //         ray_end.x < other.pos.x + 16 &&
        //         ray_end.y < other.pos.y + 16) {
        //         ray_hit = true
        //         other.is_dead = true
        //         break rayloop
        //     }
        // }
    }
    ray := ShotRay{
        start = ray_start,
        end = ray_end,
        lifetime = 5,
    }
    append(&game.shot_rays, ray)
}