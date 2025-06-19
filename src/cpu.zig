const std = @import("std");
const rl = @import("rl.zig").rl;
const MEMORY_SIZE = 4096;
var memory: [MEMORY_SIZE]u8 = [_]u8{0} ** MEMORY_SIZE;
var rV: [16]u8 = [_]u8{0} ** 16;
var rI: u16 = 0;
var pc: u16 = 0;
var sp: usize = 0;
var stack: [16]usize = undefined;
var rSound: u8 = 0;
var rDelay: u8 = 0;
const vram = &@import("renderer.zig").vram;

fn get_addr(i: u16) u16 {
    return i & 0x0FFF;
}

fn get_nibble(i: u16) u16 {
    return i & 0x000F;
}

fn get_x(i: u16) u16 {
    return i & (0x0F00) >> 8;
}

fn get_y(i: u16) u16 {
    return (i & 0x00F0) >> 4;
}

fn get_byte(i: u16) u16 {
    return i & 0x00FF;
}

pub fn click() void {
    if (rSound != 0) {
        rSound -= 1;
    }
    if (rDelay != 0) {
        rDelay -= 1;
    }
}

// SYS calls are ignored by modern interpreters.

fn run_instruction(code: u16) void {
    // Do zero calls first, as they are quick
    if (code == 0x00E0) {
        cls();
        return;
    }
    if (code == 0x00EE) {
        ret();
        return;
    }
    switch (code & 0xF000) {
        0x1000 => jp(code),
        0x2000 => call(code),
        0x3000 => se_r_byte(code),
    }
}

fn cls() void {
    for (vram) |*row| {
        @memset(row.*, false);
    }
}

fn ret() void {
    pc = stack[sp];
    sp -= 1;
}

fn jp(code: u16) void {
    pc = get_addr(code);
}

fn call(code: u16) void {
    sp += 1;
    stack[sp] = pc;
    pc = get_addr(code);
}

fn se_r_byte(code: u16) void {
    if (rV[get_x(code)] == get_byte(code)) pc += 2;
}

fn sne_r_byte(code: u16) void {
    if (rV[get_x(code)] != get_byte(code)) pc += 2;
}

fn se_rx_ry(code: u16) void {
    if (rV[get_x(code)] == rV[get_y(code)]) pc += 2;
}

fn sne_rx_ry(code: u16) void {
    if (rV[get_x(code)] != rV[get_y(code)]) pc += 2;
}

fn ld_r_byte(code: u16) void {
    rV[get_x(code)] = get_byte(code);
}

fn add_r_byte(code: u16) void {
    rV[get_x(code)] = @addWithOverflow(rV[get_x(code)], get_byte(code))[0];
}

fn ld_rx_ry(code: u16) void {
    rV[get_x(code)] = rV[get_y(code)];
}

fn or_rx_ry(code: u16) void {
    rV[get_x(code)] |= rV[get_y(code)];
}

fn and_rx_ry(code: u16) void {
    rV[get_x(code)] &= rV[get_y(code)];
}

fn xor_rx_ry(code: u16) void {
    rV[get_x(code)] ^= rV[get_y(code)];
}

fn add_rx_ry(code: u16) void {
    const res = @addWithOverflow(rV[get_x(code)], rV[get_y(code)]);
    rV[get_x(code)] = res[0];
    rV[15] = res[1];
}

fn sub_rx_ry(code: u16) void {
    const res = @subWithOverflow(rV[get_x(code)], rV[get_y(code)]);
    rV[get_x(code)] = res[0];
    rV[15] = res[1];
}

fn shr_rx(code: u16) void {
    rV[15] = rV[get_x(code)] % 2;
    rV[get_x(code)] >>= 1;
}

fn subn_rx_ry(code: u16) void {
    const res = @subWithOverflow(rV[get_y(code)], rV[get_x(code)]);
    rV[get_x(code)] = res[0];
    rV[15] = if (res[1] == 0) 1 else 0;
}

fn shl_rx(code: u16) void {
    const res = @shlWithOverflow(rV[get_x(code)], 1);
    rV[get_x] = res[0];
    rV[15] = res[1];
}

fn ld_ri_addr(code:u16) void {
    rI = get_addr(code);
}

fn jp_r0_addr(code:u16) void {
    pc = get_addr(code) + rV[0];
}

fn rnd_rx_byte(code:u16) void {
    _ = code; //TODO: implement random number generation
}

