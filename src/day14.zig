const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("data/day14.txt");

pub fn main() !void {
    try util.benchDay("14", part1, part2);
}

fn part1() !usize {
    return 0;
}

fn part2() !usize {
    return 0;
}

test "Day 14 pt 1" {
    try std.testing.expect(try part1() == 0);
}
test "Day 14 pt 2" {
    try std.testing.expect(try part2() == 0);
}
