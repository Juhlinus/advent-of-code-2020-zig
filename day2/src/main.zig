const std = @import("std");
const print = std.debug.print;
const maxInt = std.math.maxInt;
const ArenaAllocator = std.heap.ArenaAllocator;

const Password = struct {
    min: u64,
    max: u64,
    letter: u8,
    password: []u8,
};

pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("src/input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var arena = ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var i: usize = 0;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var valid: usize = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| : (i += 1) {
        var j: usize = 0;
        var k: usize = 0;
        var line_buf = try gpa.allocator.alloc(u8, 32);
        defer _ = gpa.allocator.free(line_buf);

        var password: Password = undefined;

        while (j < line.len) : (j += 1) {
            const character: u8 = line[j];

            switch (character) {
                '-' => {
                    password.min = try parseU64(line_buf[0..k], 10);

                    k = 0;
                },
                ' ' => {
                    if (line[j - 1] != ':') {
                        password.max = try parseU64(line_buf[0..k], 10);
                    }

                    k = 0;
                },
                ':' => {
                    password.letter = line_buf[0];

                    k = 0;
                },
                else => {
                    line_buf[k] = character;

                    k += 1;
                },
            }
        }

        password.password = line_buf[0..k];

        var l: usize = 0;
        var letter_count: usize = 0;

        while (l < password.password.len) : (l += 1) {
            if (password.password[l] == password.letter) {
                letter_count += 1;
            }
        }

        if (letter_count >= password.min and letter_count <= password.max) {
            valid += 1;
        }
    }

    std.debug.print("{}", .{valid});
}

pub fn parseU64(buf: []const u8, radix: u8) !u64 {
    var x: u64 = 0;

    for (buf) |c| {
        const digit = charToDigit(c);

        if (digit >= radix) {
            return error.InvalidChar;
        }

        // x *= radix
        if (@mulWithOverflow(u64, x, radix, &x)) {
            return error.Overflow;
        }

        // x += digit
        if (@addWithOverflow(u64, x, digit, &x)) {
            return error.Overflow;
        }
    }

    return x;
}

fn charToDigit(c: u8) u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        'A'...'Z' => c - 'A' + 10,
        'a'...'z' => c - 'a' + 10,
        else => maxInt(u8),
    };
}
