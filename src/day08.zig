const std = @import("std");
const util = @import("util.zig");
const Parallelize = @import("Parallelizer.zig").Parallelize;

const data = @embedFile("data/day08.txt");

pub fn main() !void {
    try util.benchDay("08", part1, part2);
}

fn part1() !usize {
    @setEvalBranchQuota(100000);
    const lines = comptime util.allLines(data);
    const ctx = try Context.init(lines);

    const node = ctx.mappings.get("AAA").?;

    return countSteps(node, ctx, isFullZs);
}

fn part2() !usize {
    @setEvalBranchQuota(100000);
    const lines = comptime util.allLines(data);
    const ctx = try Context.init(lines);

    const startingNodes = comptime findAllStartingNodes(lines);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const distances = try Parallelize(Context, Node, usize, (struct {
        fn map(_ctx: Context, in: Node) usize {
            return countSteps(in, _ctx, endsWithZ);
        }
    }).map, .{})
        .run(gpa.allocator(), ctx, startingNodes);

    defer gpa.allocator().free(distances);

    return findLeastCommonMultiple(distances);
}

const Map = std.StringArrayHashMap(Node);

fn findLeastCommonMultiple(nums: []usize) usize {
    var m: usize = nums[0];
    for (1..nums.len) |i|
        m = (nums[i] * m) / greatestCommonDivisor(nums[i], m);
    return m;
}

fn greatestCommonDivisor(a: usize, b: usize) usize {
    return if (b == 0) a else greatestCommonDivisor(b, a % b);
}

fn findAllStartingNodes(comptime lines: []const []const u8) []const Node {
    var nodes: []const Node = &[0]Node{};

    for (lines[1..]) |line| {
        const node = parseNode(line);

        if (node.key[2] == 'A')
            nodes = nodes ++ [_]Node{node};
    }

    return nodes;
}

const Context = struct {
    gpa: std.heap.GeneralPurposeAllocator(.{}),
    mappings: Map,
    instructions: []const u1,

    pub fn init(comptime lines: []const []const u8) !Context {
        const instructions = comptime getInstructions(lines[0]);

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        var mappings = Map.init(gpa.allocator());

        for (lines[1..]) |line| {
            const node = parseNode(line);
            try mappings.put(node.key, node);
        }

        return .{
            .mappings = mappings,
            .instructions = instructions,
            .gpa = gpa,
        };
    }

    fn deinit(ctx: *Context) void {
        ctx.mappings.deinit();
        _ = ctx.gpa.deinit();
    }
};

fn isFullZs(s: []const u8) bool {
    return s[0] == 'Z' and s[1] == 'Z' and s[2] == 'Z';
}

fn endsWithZ(s: []const u8) bool {
    return s[2] == 'Z';
}

fn countSteps(startingNode: Node, ctx: Context, comptime isEnd: *const fn ([]const u8) bool) usize {
    const ops = ctx.instructions;
    const mappings = ctx.mappings;

    var currentOp: usize = 0;
    var steps: usize = 0;
    var node = startingNode;
    while (!isEnd(node.key)) {
        node = mappings.get(node.leaves[ops[currentOp]]).?;
        currentOp = (currentOp + 1) % ctx.instructions.len;
        steps += 1;
    }

    return steps;
}

const Node = struct {
    key: []const u8,
    leaves: [2][]const u8,

    fn print(self: Node) void {
        std.debug.print("{s} [{s}, {s}]\n", .{ self.key, self.leaves[0], self.leaves[1] });
    }
};

fn parseNode(line: []const u8) Node {
    return .{
        .key = line[0..3],
        .leaves = [2][]const u8{
            line[7..10],
            line[12..15],
        },
    };
}

fn getInstructions(comptime line: []const u8) []const u1 {
    var ops: []const u1 = &[0]u1{};

    for (line) |c|
        ops = ops ++ [_]u1{@as(u1, if (c == 'R') 1 else 0)};

    return ops;
}

test "Day 08 pt 1" {
    try std.testing.expect(try part1() == 18827);
}
test "Day 08 pt 2" {
    try std.testing.expect(try part2() == 20220305520997);
}
