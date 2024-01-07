package main

import "tic"

Enemy :: struct {
    pos : vec2,
    sprite: i32,
    reaction_time: i16,
    direction: i8,
    is_dead : bool,
}

ENEMY_ANIMATION_IDLE : i32 = 288
ENEMY_ANIMATION_RELOAD := [?]i32{290, 292, 290}

draw_enemy :: proc(game: ^Game, enemy: ^Enemy) {
    cam := game.camera
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

update_enemy :: proc(enemy: ^Enemy, player: ^Player) {
    enemy.reaction_time -= 1
    switch enemy.reaction_time {
        case 60: enemy.sprite = ENEMY_ANIMATION_RELOAD[0]
        case 45: {
            enemy.sprite = ENEMY_ANIMATION_RELOAD[1]
        }
        case 30: {
            enemy.sprite = ENEMY_ANIMATION_RELOAD[2]
            tic.sfx(1, 0, 5, speed=4, channel = 2, volume_left=5, volume_right=5)
        }
        case 15: enemy.sprite = ENEMY_ANIMATION_IDLE
        case 0: enemy_shoot(enemy, player)
    }
    enemy.direction = enemy.pos.x > player.pos.x ? -1 : 1
}

enemy_shoot :: proc(enemy: ^Enemy, player: ^Player) {
    tic.sfx(0, 0, 4, speed=0, channel=2)
}