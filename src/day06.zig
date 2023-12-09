const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("data/day06.txt");

pub fn main() !void {
    try util.benchDay("06", part1, part2);
}

fn part1() !usize {
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

    return totalWins;
}

fn part2() !usize {
    const lines = comptime util.allLines(data);

    const time = parseAllDigits(lines[0]);
    const distance = parseAllDigits(lines[1]);

    var count: usize = 0;

    for (1..time) |i| {
        const travel = calculateTravel(time, i);

        if (travel > distance)
            count += 1;
    }

    return count;
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

test "Day 06 pt 1" {
    try std.testing.expect(try part1() == 275724);
}
test "Day 06 pt 2" {
    try std.testing.expect(try part2() == 37286485);
}
