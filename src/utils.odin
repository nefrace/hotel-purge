package main

import "core:strings"
import "core:fmt"

printf :: proc(format: string, args: ..any) -> string {
    print_buf: [255]byte
    sb := strings.builder_from_bytes(print_buf[:])
    search_string := format[:]
    arg_index := 0
    for {
        index := strings.index(search_string, "%")
        if index == -1 {
            strings.write_string(&sb, search_string[:])
            break
        }
        strings.write_string(&sb, search_string[:index])
        base_arg := args[arg_index]
        switch a in base_arg {
            case bool: strings.write_string(&sb, bool(a)? "true" : "false")
            case int: strings.write_int(&sb, int(a))
            case i8: strings.write_int(&sb, int(a))
            case i16: strings.write_int(&sb, int(a))
            case i32: strings.write_int(&sb, int(a))
            case u8: strings.write_uint(&sb, uint(a))
            case u16: strings.write_uint(&sb, uint(a))
            case u32: strings.write_uint(&sb, uint(a))
            case f32: strings.write_float(&sb, f64(a), 'f', 3, 64) 
        }
        arg_index += 1
        search_string = search_string[index+1:]
    }
    return strings.to_string(sb)
}

