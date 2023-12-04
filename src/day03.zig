const std = @import("std");

const util = @import("util.zig");
const FindIterator = util.FindIterator;
const NumberIterator = util.NumberIterator;
const Number = util.Number;
const findNumbers = util.findNumbers;

const UseTestData = false;

const data = if (UseTestData)
    \\467..114..
    \\...*......
    \\..35..633.
    \\......#...
    \\617*......
    \\.....+.58.
    \\..592.....
    \\......755.
    \\...$.*....
    \\.664.598..
else
    @embedFile("data/day03.txt");

pub fn main() !void {
    try part1();
    try part2();
}

fn part1() !void {
    var lines = std.mem.tokenize(u8, data, "\r\n");

    var lineHistory = [_]?[]const u8{ null, null, lines.next() };

    var sum: usize = 0;
    while (lines.next()) |line| {
        //We rotate the lines
        lineHistory[0] = lineHistory[1];
        lineHistory[1] = lineHistory[2];
        lineHistory[2] = line;

        if (lineHistory[1] != null) {
            var numbers = findNumbers(lineHistory[1].?);
            sum += sumParts(lineHistory, &numbers);
        }
    }

    //Rotate one last time (just remove the furthermost line)
    lineHistory[0] = null;

    if (lineHistory[2] != null) {
        var numbers = findNumbers(lineHistory[2].?);
        sum += sumParts(lineHistory, &numbers);
    }

    std.debug.print("Total: {d}\n", .{sum});
}

fn part2() !void {
    var lines = std.mem.tokenize(u8, data, "\r\n");
    var lineHistory = [_]?[]const u8{ null, null, lines.next() };

    var sum: usize = 0;
    while (lines.next()) |line| {
        lineHistory[0] = lineHistory[1];
        lineHistory[1] = lineHistory[2];
        lineHistory[2] = line;

        var stars = FindIterator{ .src = lineHistory[1].?, .target = '*' };
        while (stars.next()) |starIndex|
            sum += getGearRatio(lineHistory, starIndex);
    }

    lineHistory[0] = null;
    if (lineHistory[2] != null) {
        var stars = FindIterator{ .src = lineHistory[2].?, .target = '*' };
        while (stars.next()) |starIndex|
            sum += getGearRatio(lineHistory, starIndex);
    }

    std.debug.print("Total: {d}\n", .{sum});
}

fn getGearRatio(lines: [3]?[]const u8, index: usize) usize {
    var count: usize = 0;
    var ratio: usize = 1;

    inline for (lines) |line| {
        if (line != null) {
            var numbers = findNumbers(line.?);
            while (numbers.next()) |n| {
                if (isAdjacent(index, n)) {
                    count += 1;
                    ratio *= n.value;
                }

                if (count > 2) //Shortcircuit
                    return 0;
            }
        }
    }

    return if (count == 2) ratio else 0;
}

fn isAdjacent(i: usize, n: Number) bool {
    const from = if (n.pos == 0) n.pos else n.pos - 1;
    const to = n.pos + n.length;

    return i >= from and i <= to;
}

fn sumParts(lines: [3]?[]const u8, numbers: *NumberIterator) usize {
    var sum: usize = 0;

    while (numbers.next()) |n|
        sum += getPartNumber(lines, n);

    return sum;
}

fn getPartNumber(lines: [3]?[]const u8, n: Number) usize {
    //God bless comptime
    inline for (lines) |line|
        if (line != null and hasAdjacentSymbol(line.?, n.pos, n.length))
            return n.value;

    return 0;
}

fn hasAdjacentSymbol(line: []const u8, pos: usize, length: usize) bool {
    var i: usize = if (pos == 0) 0 else pos - 1; //We start 1 step before

    while (i < pos + length + 1 and i < line.len) : (i += 1) {
        const c = line[i];

        if (c != '.' and !std.ascii.isDigit(c))
            return true;
    }

    return false;
}
