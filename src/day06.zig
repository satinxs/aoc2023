const std = @import("std");

const util = @import("util.zig");

const UseTestData = false;

const data = if (UseTestData)
    \\Time:      7  15   30
    \\Distance:  9  40  200
else
    @embedFile("data/day06.txt");

pub fn main() !void {
    try part1();
    try part2();
}

fn part1() !void {
    const lines = comptime util.allLines(data);

    var iterator = PairIterator{
        .times = util.findNumbers(lines[0]),
        .distances = util.findNumbers(lines[1]),
    };

    var totalWins: usize = 1;

    while (iterator.next()) |pair| {
        var count: usize = 0;

        for (1..pair[0]) |i| {
            const travel = calculateTravel(pair[0], i);

            if (travel > pair[1])
                count += 1;
        }

        totalWins *= count;
    }

    std.debug.print("Total ways to win: {d}\n", .{totalWins});
}

fn part2() !void {
    const lines = comptime util.allLines(data);

    const time = parseAllDigits(lines[0]);
    const distance = parseAllDigits(lines[1]);

    var count: usize = 0;

    for (1..time) |i| {
        const travel = calculateTravel(time, i);

        if (travel > distance)
            count += 1;
    }

    std.debug.print("Total ways to win: {d}\n", .{count});
}

fn parseAllDigits(line: []const u8) usize {
    var value: usize = 0;
    for (line) |c| {
        if (std.ascii.isDigit(c)) {
            value *= 10;
            value += c - '0';
        }
    }

    return value;
}

fn calculateTravel(time: usize, charge: usize) usize {
    return (time - charge) * charge;
}

const PairIterator = struct {
    times: util.NumberIterator,
    distances: util.NumberIterator,

    pub fn next(self: *PairIterator) ?[2]usize {
        const time = self.times.next();
        const distance = self.distances.next();

        if (time != null and distance != null)
            return [2]usize{ time.?.value, distance.?.value };

        return null;
    }
};
