const std = @import("std");

const util = @import("util.zig");

const data = @embedFile("data/day04.txt");

pub fn main() !void {
    try util.benchDay("04", part1, part2);
}

fn part1() !usize {
    var lines = std.mem.tokenize(u8, data, "\r\n");

    var sum: usize = 0;

    while (lines.next()) |line|
        sum += getCardPoints(line, true);

    return sum;
}

fn part2() !usize {
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

    return totalCards;
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

test "Day 04 pt 1" {
    try std.testing.expect(try part1() == 21138);
}
test "Day 04 pt 2" {
    try std.testing.expect(try part2() == 7185540);
}
