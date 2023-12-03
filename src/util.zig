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
