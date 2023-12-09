const std = @import("std");

pub const FindIterator = struct {
    src: []const u8,
    target: u8,
    pos: usize = 0,

    pub fn next(self: *FindIterator) ?usize {
        while (self.pos < self.src.len and self.target != self.src[self.pos])
            self.pos += 1;

        if (self.pos < self.src.len and self.src[self.pos] == self.target) {
            defer self.pos += 1;
            return self.pos;
        }

        return null;
    }
};

pub fn indexOf(line: []const u8, char: u8) ?usize {
    for (line, 0..) |c, i|
        if (c == char)
            return i;

    return null;
}

pub fn reverseIndexOf(line: []const u8, target: u8) ?usize {
    var i: usize = line.len - 1;

    while (i > 0 and line[i] != target)
        i -= 1;

    return if (line[i] == target) i else null;
}

pub fn findNumbers(line: []const u8) NumberIterator {
    return .{ .line = line };
}

pub const Number = struct { pos: usize, length: usize, value: usize };

pub const NumberIterator = struct {
    line: []const u8,
    pos: usize = 0,

    pub fn atEnd(self: *@This()) bool {
        return self.pos == self.line.len;
    }

    pub fn next(self: *@This()) ?Number {
        while (!self.atEnd() and !std.ascii.isDigit(self.line[self.pos]))
            self.pos += 1;

        if (!self.atEnd()) {
            var n: usize = 0;
            const startPos = self.pos;
            while (!self.atEnd() and std.ascii.isDigit(self.line[self.pos])) {
                n = n * 10 + (self.line[self.pos] - '0');
                self.pos += 1;
            }

            return .{ .pos = startPos, .length = self.pos - startPos, .value = n };
        } else {
            return null;
        }
    }
};

//This is exclusively a compile-time function
pub fn allLines(data: []const u8) []const []const u8 {
    var lines: []const []const u8 = &[_][]const u8{};

    var iterator = std.mem.tokenize(u8, data, "\r\n");

    while (iterator.next()) |line| {
        lines = lines ++ [_][]const u8{line};
    }

    return lines;
}

pub fn bench(comptime func: anytype, params: anytype) !void {
    var timer = try std.time.Timer.start();

    try @call(.auto, func, params);

    const elapsed = @as(f64, @floatFromInt(timer.read())) / 1000.0 / 1000.0;

    std.debug.print("Elapsed: {d}ms\n", .{elapsed});
}

fn LessFn(comptime T: type) type {
    return *const fn (a: T, b: T) bool;
}

pub fn quicksort(comptime T: type, items: []T, comptime lesserThan: LessFn(T)) void {
    _quicksort(T, items, 0, items.len - 1, lesserThan);
}

fn _quicksort(comptime T: type, items: []T, i: usize, j: usize, comptime lesserThan: LessFn(T)) void {
    //Validate partition indices
    if (!(i < j)) return;

    const partitionIndex = partition(T, items, i, j, lesserThan);

    if (partitionIndex != 0)
        _quicksort(T, items, i, partitionIndex - 1, lesserThan);

    _quicksort(T, items, partitionIndex + 1, j, lesserThan);
}

fn swap(comptime T: type, items: []T, a: usize, b: usize) void {
    const temp = items[a];
    items[a] = items[b];
    items[b] = temp;
}

fn partition(comptime T: type, items: []T, i: usize, j: usize, comptime lessThan: LessFn(T)) usize {
    //Get the pivot value and initialize the partition boundary.
    const value = items[i];
    var boundary: usize = i + 1;

    //Examine all values other than the pivot, swapping to enforce the
    //invariant. Every swap moves an observed "small" value to the left of the
    //boundary. "Large" values are left alone since they are already to the
    //right of the boundary.
    for (boundary..j + 1) |k| {
        if (lessThan(items[k], value)) {
            swap(T, items, k, boundary);
            boundary += 1;
        }
    }

    //Put pivot value between the two sides of the partition, and return that location.
    swap(T, items, i, boundary - 1);
    return boundary - 1;
}
