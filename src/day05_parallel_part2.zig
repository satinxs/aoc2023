const std = @import("std");
const Allocator = std.mem.Allocator;

const Parallelize = @import("Parallelizer.zig").Parallelize;
const Mapper = @import("day05.zig").Mapper;
const mapSeedToLocation = @import("day05.zig").mapSeedToLocation;

fn batchify(allocator: std.mem.Allocator, seedRanges: []const [2]usize) ![][2]usize {
    var ranges = std.ArrayList([2]usize).init(allocator);
    defer ranges.deinit();

    const BatchSize = 10 * 1000 * 1000;

    for (seedRanges) |range| {
        var length = range[1];
        var lastIndex = range[0];

        while (length > BatchSize) {
            try ranges.append([_]usize{ lastIndex, BatchSize });
            length -= BatchSize;
            lastIndex += BatchSize;
        }

        try ranges.append([_]usize{ lastIndex, length });
    }

    return try ranges.toOwnedSlice();
}

pub fn part2_parallelized(allocator: Allocator, seedRanges: []const [2]usize, mappings: []const Mapper) !usize {
    const ranges = try batchify(allocator, seedRanges);

    const output = try Parallelize([]const Mapper, [2]usize, usize, mappingFunction, .{ .showProgress = false })
        .run(allocator, mappings, ranges);
    defer allocator.free(output);

    var nearestLocation: usize = output[0];
    for (output) |n|
        nearestLocation = @min(nearestLocation, n);

    return nearestLocation;
}

fn mappingFunction(mappings: []const Mapper, range: [2]usize) usize {
    var nearestLocation: usize = std.math.maxInt(usize);

    const from = range[0];

    for (0..range[1]) |i| {
        const location = mapSeedToLocation(mappings, from + i);

        if (location < nearestLocation)
            nearestLocation = location;
    }

    return nearestLocation;
}
