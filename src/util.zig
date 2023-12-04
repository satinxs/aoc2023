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
