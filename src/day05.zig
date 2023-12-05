const std = @import("std");

const util = @import("util.zig");

const UseTestData = false;
const UseParallel = true;

const data = if (!UseTestData)
    @embedFile("data/day05.txt")
else
    \\seeds: 79 14 55 13
    \\
    \\seed-to-soil map:
    \\50 98 2
    \\52 50 48
    \\
    \\soil-to-fertilizer map:
    \\0 15 37
    \\37 52 2
    \\39 0 15
    \\
    \\fertilizer-to-water map:
    \\49 53 8
    \\0 11 42
    \\42 0 7
    \\57 7 4
    \\
    \\water-to-light map:
    \\88 18 7
    \\18 25 70
    \\
    \\light-to-temperature map:
    \\45 77 23
    \\81 45 19
    \\68 64 13
    \\
    \\temperature-to-humidity map:
    \\0 69 1
    \\1 0 69
    \\
    \\humidity-to-location map:
    \\60 56 37
    \\56 93 4
    ;

const part2_parallelized = @import("day05_parallel_part2.zig").part2_parallelized;

pub fn main() !void {
    @setEvalBranchQuota(25000);
    const lines = comptime util.allLines(data);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const mappings = try readMappings(allocator, lines[1..]);

    try part1(lines, mappings);

    try util.bench(part2, .{ allocator, lines, mappings });
}

fn part1(comptime lines: []const []const u8, mappings: []const Mapper) !void {
    const seeds = comptime readSeeds(lines[0]); //Let's cheat and count seeds in comptime

    std.debug.print("{any}\n", .{seeds});

    var nearestLocation: usize = std.math.maxInt(usize);

    for (seeds) |seed| {
        const location = mapSeedToLocation(mappings, seed);

        if (location < nearestLocation)
            nearestLocation = location;
    }

    std.debug.print("\n\nNearest location: {d}\n\n", .{nearestLocation});
}

fn part2(allocator: std.mem.Allocator, comptime lines: []const []const u8, mappings: []const Mapper) !void {
    const seedRanges = comptime readSeedRanges(lines[0]); //Let's cheat and count seeds in comptime

    std.debug.print("Found {d} seed ranges\n", .{seedRanges.len});

    if (UseParallel) {
        try part2_parallelized(allocator, seedRanges, mappings);
    } else {
        var nearestLocation: usize = std.math.maxInt(usize);

        for (seedRanges) |seedRange| {
            const from = seedRange[0];

            std.debug.print("Calculating for range: {d}/{d}\n", .{ seedRange[0], seedRange[1] });

            var i: usize = 0;
            while (i < seedRange[1]) : (i += 1) {
                const seed = from + i;

                const location = mapSeedToLocation(mappings, seed);

                if (location < nearestLocation)
                    nearestLocation = location;
            }
        }

        std.debug.print("\n\nNearest location: {d}\n", .{nearestLocation});
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
        if (UseTestData)
            std.debug.print("\nMapping: {s}", .{mapper.name});

        for (mapper.ranges) |range| {
            const mapped = range.map(value);
            if (value != mapped) {
                value = mapped;
                break;
            }
        }

        if (UseTestData)
            std.debug.print(" => {d}", .{value});
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
