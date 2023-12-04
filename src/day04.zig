const std = @import("std");

const util = @import("util.zig");

const UseTestData = false;

const data = if (!UseTestData)
    @embedFile("data/day04.txt")
else
    \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
    \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
    \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
    \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
    \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
    \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    ;

pub fn main() !void {
    try part1();
    try part2();
}

fn part1() !void {
    var lines = std.mem.tokenize(u8, data, "\r\n");

    var sum: usize = 0;

    while (lines.next()) |line|
        sum += getCardPoints(line, true);

    std.debug.print("The total sum is: {d}\n", .{sum});
}

fn part2() !void {
    @setEvalBranchQuota(25000);
    const lineCount = comptime std.mem.count(u8, data, "\n") + 1;

    var cardsMultiplicity = [_]usize{1} ** lineCount;

    var lines = std.mem.tokenize(u8, data, "\r\n");

    var totalCards: usize = 0;

    var lineIndex: usize = 0;
    while (lines.next()) |line| {
        const points = getCardPoints(line, false);

        const mul = cardsMultiplicity[lineIndex];

        var i: usize = 1;
        while (i <= points and (lineIndex + i) < lineCount) : (i += 1)
            cardsMultiplicity[lineIndex + i] += mul;

        totalCards += mul;
        lineIndex += 1;
    }

    std.debug.print("Total cards: {d}\n", .{totalCards});
}

fn getCardPoints(line: []const u8, pow: bool) usize {
    const colon = util.indexOf(line, ':').? + 1;
    const pipe = util.indexOf(line, '|').? + 1;

    const winning = std.mem.trim(u8, line[colon .. pipe - 1], " ");
    const card = std.mem.trim(u8, line[pipe..], " ");

    var points: usize = 0;

    var numbers = util.findNumbers(card);
    while (numbers.next()) |n| {
        if (hasN(winning, n.value)) {
            if (pow) {
                if (points == 0) {
                    points = 1;
                } else {
                    points *= 2;
                }
            } else {
                points += 1;
            }
        }
    }

    return points;
}

fn hasN(line: []const u8, n: usize) bool {
    var numbers = util.findNumbers(line);
    while (numbers.next()) |w|
        if (n == w.value)
            return true;

    return false;
}
