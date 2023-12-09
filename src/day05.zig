const std = @import("std");

const util = @import("util.zig");

const UseParallel = true;

const data = @embedFile("data/day05.txt");

const part2_parallelized = @import("day05_parallel_part2.zig").part2_parallelized;

pub fn main() !void {
    try util.benchDay("05", part1, part2);
}

fn part1() !usize {
    @setEvalBranchQuota(25000);
    const lines = comptime util.allLines(data);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const mappings = try readMappings(allocator, lines[1..]);
    defer {
        for (mappings) |m|
            allocator.free(m.ranges);

        allocator.free(mappings);
    }

    const seeds = comptime readSeeds(lines[0]); //Let's cheat and count seeds in comptime

    var nearestLocation: usize = std.math.maxInt(usize);

    for (seeds) |seed| {
        const location = mapSeedToLocation(mappings, seed);

        if (location < nearestLocation)
            nearestLocation = location;
    }

    return nearestLocation;
}

fn part2() !usize {
    @setEvalBranchQuota(25000);
    const lines = comptime util.allLines(data);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const mappings = try readMappings(allocator, lines[1..]);
    defer {
        for (mappings) |m|
            allocator.free(m.ranges);

        allocator.free(mappings);
    }

    const seedRanges = comptime readSeedRanges(lines[0]); //Let's cheat and count seeds in comptime

    if (UseParallel) {
        return try part2_parallelized(allocator, seedRanges, mappings);
    } else {
        var nearestLocation: usize = std.math.maxInt(usize);

        for (seedRanges) |seedRange| {
            const from = seedRange[0];

            var i: usize = 0;
            while (i < seedRange[1]) : (i += 1) {
                const seed = from + i;

                const location = mapSeedToLocation(mappings, seed);

                if (location < nearestLocation)
                    nearestLocation = location;
            }
        }

        return nearestLocation;
    }
}

fn readMappings(allocator: std.mem.Allocator, lines: []const []const u8) ![]const Mapper {
    var mappers = std.ArrayList(Mapper).init(allocator);

    var lineIndex: usize = 0;
    while (lineIndex < lines.len) {
        const name = std.mem.trim(u8, lines[lineIndex], " :");

        lineIndex += 1;

        var ranges = std.ArrayList(Range).init(allocator);

        while (lineIndex < lines.len) {
            if (util.reverseIndexOf(lines[lineIndex], ':') != null)
                break;

            const range = parseRange(lines[lineIndex]);

            try ranges.append(range);

            lineIndex += 1;
        }

        try mappers.append(.{
            .name = name,
            .ranges = try ranges.toOwnedSlice(),
        });

        ranges.deinit();
    }

    //We convert the ArrayList into a simple slice for faster indexing
    defer mappers.deinit();
    return try mappers.toOwnedSlice();
}

pub const Mapper = struct {
    name: []const u8,
    ranges: []const Range,
};

pub fn mapSeedToLocation(mappers: []const Mapper, seed: usize) usize {
    var value: usize = seed;

    for (mappers) |mapper| {
        for (mapper.ranges) |range| {
            const mapped = range.map(value);
            if (value != mapped) {
                value = mapped;
                break;
            }
        }
    }

    return value;
}

fn parseRange(line: []const u8) Range {
    var numbers = util.findNumbers(line);

    const destinationFrom = numbers.next().?.value;
    const sourceFrom = numbers.next().?.value;
    const length = numbers.next().?.value;

    return .{
        .destinationFrom = destinationFrom,
        .sourceFrom = sourceFrom,
        .length = length,
    };
}

const Range = struct {
    destinationFrom: usize,
    sourceFrom: usize,
    length: usize,

    fn map(self: *const Range, value: usize) usize {
        if (self.sourceFrom <= value and value < self.sourceFrom + self.length)
            return self.destinationFrom + (value - self.sourceFrom);

        return value;
    }
};

//This is exclusively a comptime function
fn readSeeds(line: []const u8) []const usize {
    var result: []const usize = &[_]usize{};

    var iterator = util.findNumbers(line);
    while (iterator.next()) |n| {
        result = result ++ [_]usize{n.value};
    }

    return result;
}

//This is exclusively a comptime function
fn readSeedRanges(line: []const u8) []const [2]usize {
    var result: []const [2]usize = &[_][2]usize{};

    var iterator = util.findNumbers(line);
    while (iterator.next()) |from| {
        const length = iterator.next().?;

        result = result ++ [_][2]usize{.{ from.value, length.value }};
    }

    return result;
}

test "Day 05 pt 1" {
    try std.testing.expect(try part1() == 389056265);
}
test "Day 05 pt 2" {
    try std.testing.expect(try part2() == 137516820);
}
