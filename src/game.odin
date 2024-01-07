package main 

import "tic"
import "core:slice"
import "core:math/rand"
import "core:strings"

Game :: struct {
    player: Player,
    camera: vec2,
    enemies: [dynamic]Enemy,
    doors: [dynamic]Door,
}

doors_buf: [6]Door
enemy_buf: [10]Enemy

game_init :: proc () -> Game {
    game := Game{
        player = init_player({32,32}),
        camera = {90 * 8, 119 * 8},
        enemies = slice.into_dynamic(enemy_buf[:]),
        doors = slice.into_dynamic(doors_buf[:]),
    }
    doors_y : i32 = 133 * 8
    doors_x := [6]i32{
        92 * 8,
        96 * 8,
        100 * 8,
        108 * 8,
        112 * 8,
        116 * 8,
    }
    for i := 0; i < 6; i+=1 {
        append(&game.doors, spawn_door(
            {doors_x[i], doors_y},
            i16(rand.int_max(100) + 60),
        ))
    }
    return game
}

game_tic :: proc (game: ^Game) {
    update_player(&game.player, game)

    tic.cls()
    
    tic.draw_map(90, 119, sx = 0, sy = 0)

    for _, i in game.doors {
        door := &game.doors[i]
        update_door(door, game)
        draw_door(door, game)
    }
    #reverse for _, i in game.enemies {
        enemy := &game.enemies[i]
        update_enemy(enemy, &game.player)
        draw_enemy(game, enemy)
        if enemy.is_dead {
            unordered_remove(&game.enemies, i)
        }
    }
    
    draw_player(game)

    // Рисуем патроны
    for i : u8 = 1; i <= game.player.ammo; i += 1 {
        tic.sprite(496, i32(i) * 8, 0, 0)
    }
    
    // Рисуем здоровье
    i : u8 = 0
    for i < game.player.health {
        i += 2
        sprite : i32 = 497
        if i > game.player.health {
            sprite = 498
        }
        tic.sprite(sprite, 120 + i32(i) * 5, 0, 0)
    }
}