package main 

import "tic"
import "core:slice"
import "core:math/rand"
import "core:strings"

Game :: struct {
    player: Player,
    camera: vec2,
    people: [dynamic]People,
    doors: [dynamic]Door,
    shot_rays: [dynamic]ShotRay,
    people_to_spawn: u8,
    people_to_spawn_max: u8,
    game_over: bool,
    saved_people: i32,
    killed: i32,
    timer: i32,
    opening_time: i16,
    closing_time: i16,
    game_over_time: i16,
    going_up: bool,
    second_counter: u8,
    people_alive: u8,
    anyone_spawned: bool,
}
ShotRay :: struct{lifetime: i8, start: vec2, end: vec2}

doors_buf: [6]Door
people_buf: [6]People
rays_buf: [50]ShotRay

game_init :: proc () -> Game {
    rand.set_global_seed(u64(tic.tstamp()))
    game := Game{
        player = init_player({32,32}),
        camera = {90 * 8, 119 * 8},
        people = slice.into_dynamic(people_buf[:]),
        doors = slice.into_dynamic(doors_buf[:]),
        shot_rays = slice.into_dynamic(rays_buf[:]),
        people_to_spawn = 1,
        people_to_spawn_max = 1,
        opening_time = 60,
        closing_time = -1,
        going_up = true,
    }
    spawn_doors(&game)
    return game
}

spawn_doors :: proc(game: ^Game) {
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
        append(&game.doors, Door{
            pos = {doors_x[i], doors_y},
            time_to_spawn = i16(rand.int_max(100) + 60),
            type = rand.choice([]PeopleType{.CIVILIAN, .ENEMY}),
        })
    }
}

game_tic :: proc (game: ^Game) -> SwitchTo {
    tic.cls(13)
    if game.going_up {
        game.camera.y -= 1
        if game.camera.y <= 113 * 8 {
            game.going_up = false
            game.camera.y = 119 * 8
            game.opening_time = 60
            game.people_to_spawn_max += 1
            game.timer = i32(game.people_to_spawn_max)+4
            game.second_counter = 0
            game.people_to_spawn = game.people_to_spawn_max
            game.people_alive = game.people_to_spawn_max
            game.anyone_spawned = false
            tic.sfx(4, 0, 5, -1, 1, 6,6, -3)
            spawn_doors(game)
        }
        tic.draw_map(90,0,30,136,0,-game.camera.y)
        draw_ui(game)
        return .NO
    }
    if game.opening_time > -1 {
        tic.draw_map(90,0,30,136,0,-game.camera.y)
        game.opening_time -= 1
        if game.opening_time < 30 {
            tic.sprite(52, 13 * 8, 14 * 8, -1, 1, 0, 0, 4, 2)
        }
        draw_ui(game)
        return .NO
    }
    if game.closing_time > -1 {
        tic.draw_map(90,0,30,136,0,-game.camera.y)
        game.closing_time -= 1
        if game.closing_time > 30 {
            tic.sprite(52, 13 * 8, 14 * 8, -1, 1, 0, 0, 4, 2)
        } else if game.closing_time == 30 {
            tic.sfx(5, 0, 4, -1, 1, 6,6, 0)
        }
        draw_ui(game)
        if game.closing_time == -1 {
            game.going_up = true
        }
        return .NO
    }

    if !game.game_over && game.people_to_spawn == 0 && len(game.people) == 0 && game.anyone_spawned {
        game.closing_time = 60
        clear(&game.doors)
    }

    if game.game_over {
        game.game_over_time += 1
        if game.game_over_time > 200 {
            if game.killed > MAX_KILLED {
                MAX_KILLED = game.killed
            }
            if game.saved_people > MAX_SAVED {
                MAX_SAVED = game.saved_people
            }
            tic.pmem(0, MAX_KILLED)
            tic.pmem(1, MAX_SAVED)
            return .MENU
        }
    }
    game.second_counter += 1 
    if game.second_counter == 60 {
        game.second_counter = 0
        if game.people_alive > 0 {
            if game.timer > 0 {
                game.timer -= 1
            }
        }
        if game.timer == 0 {
            game.game_over = true
        }
    }
    update_player(&game.player, game)
    if game.player.dead_timer > 150 {
            if game.killed > MAX_KILLED {
                MAX_KILLED = game.killed
            }
            if game.saved_people > MAX_SAVED {
                MAX_SAVED = game.saved_people
            }
            tic.pmem(0, MAX_KILLED)
            tic.pmem(1, MAX_SAVED)
        return .MENU
    }

    
    // tic.draw_map(90, 119, sx = 0, sy = 0)

    tic.draw_map(90,0,30,136,0,-game.camera.y)
    // Elevator doors
    tic.sprite(52, 13 * 8, 14 * 8, -1, 1, 0, 0, 4, 2)
    for _, i in game.doors {
        door := &game.doors[i]
        update_door(door, game)
        draw_door(door, game)
    }
    #reverse for _, i in game.people {
        people := &game.people[i]
        switch people.type {
            case .ENEMY: {update_enemy(people, game); draw_enemy(people, game)}
            case .CIVILIAN: {update_civilian(people, game); draw_civilian(people, game)}
        }
        if people.to_free {
            if people.is_saved {
                game.saved_people += 1
            }
            unordered_remove(&game.people, i)
        }
    }
    
    draw_player(game)
    #reverse for _, i in game.shot_rays {
        ray := &game.shot_rays[i]
        tic.draw_line(vec2tof(ray.start) - vec2tof(game.camera), vec2tof(ray.end) - vec2tof(game.camera), 4 - (4 - ray.lifetime))
        ray.lifetime -= 1
        if ray.lifetime <= 0 {
            unordered_remove(&game.shot_rays, i)
        }
    }

    draw_ui(game)

    return .NO
}

draw_ui :: proc(game: ^Game) {
    tic.rect(0, 0, 240, 11, 13)
    // Рисуем патроны

    if game.player.reload_time == -1 {
        for i : u8 = 1; i <= game.player.ammo; i += 1 {
            tic.sprite(496, i32(i) * 8 - 7, 1, 0)
        }
    } else {
        tic.print("RELOADING", 1, 1, 9)
        max_width :: PLAYER_MAX_AMMO * 8
        if game.player.reload_time > -1 {
            tic.line(1, 9, 1 + max_width - f32(game.player.reload_time) / PLAYER_RELOAD_TIME * max_width, 9, 8)
        }
    }
    
    // Рисуем здоровье
    i : u8 = 0
    if !game.game_over {
        for i < game.player.health {
            i += 2
            sprite : i32 = 497
            if i > game.player.health {
                sprite = 498
            }
            tic.sprite(sprite, 140 + i32(i) * 5, 1, 0)
        }
    } else {
        tic.print_string("GAME OVER", 140, 3, 8)
    }
    if game.player.health == 0 {
        tic.print_string("GAME OVER", 140, 3, 8)
    }
    tic.print_string(printf("%", game.timer), 116, 3, 8)
    tic.print_string(printf("K:% S:%", game.killed, game.saved_people), 200, 3, 8)
    // tic.print_string(printf("K:% S:%", game.people_to_spawn, len(game.people)), 200, 3, 8)
}