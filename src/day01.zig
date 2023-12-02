const std = @import("std");
const Allocator = std.mem.Allocator;

const data = @embedFile("data/day01.txt");

pub fn main() !void {
    try part1();
    try part2();
}

fn part1() !void {
    var sum: u64 = 0;
    var tokenizer = std.mem.tokenize(u8, data, "\n");
    while (tokenizer.next()) |line| {
        var first: ?u64 = null;
        var last: ?u64 = null;
        for (std.mem.trim(u8, line, " \r\n")) |c| {
            if (std.ascii.isDigit(c)) {
                const n = c - '0';
                if (first == null)
                    first = n;
                last = n;
            }
        }

        sum += first.? * 10 + last.?;
    }

    std.debug.print("Total sum: {d}\n", .{sum});
}

fn part2() !void {
    var sum: u64 = 0;

    var tokenizer = std.mem.tokenize(u8, data, "\n");
    while (tokenizer.next()) |line| {
        var first: ?u64 = null;
        var last: ?u64 = null;

        var digitIterator = DigitIterator{ .source = line };
        while (digitIterator.next()) |digit| {
            if (first == null)
                first = digit;
            last = digit;
        }

        sum += first.? * 10 + last.?;
    }

    std.debug.print("Total sum: {d}\n", .{sum});
}

const DigitIterator = struct {
    source: []const u8,
    pos: usize = 0,

    fn match(self: *@This(), comptime pairs: anytype) ?u64 {
        const source = self.source[self.pos..];

        inline for (@typeInfo(@TypeOf(pairs)).Struct.fields) |field| {
            if (std.mem.startsWith(u8, source, field.name)) {
                self.pos += 1;
                return @field(pairs, field.name);
            }
        }

        return null;
    }

    fn next(self: *@This()) ?u64 {
        while (self.pos < self.source.len) {
            const c = self.source[self.pos];

            if (switch (c) {
                '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
                    defer self.pos += 1;
                    return c - '0';
                },
                'e' => self.match(.{ .eight = 8 }),
                'f' => self.match(.{ .four = 4, .five = 5 }),
                'n' => self.match(.{ .nine = 9 }),
                'o' => self.match(.{ .one = 1 }),
                's' => self.match(.{ .six = 6, .seven = 7 }),
                't' => self.match(.{ .two = 2, .three = 3 }),
                else => null,
            }) |value|
                return value;

            self.pos += 1;
        }

        return null;
    }
};
