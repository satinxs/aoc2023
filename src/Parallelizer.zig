const std = @import("std");

fn Channel(comptime T: type) type {
    return struct {
        const Self = @This();
        const Deque = std.fifo.LinearFifo(T, .Dynamic);

        allocator: std.mem.Allocator,
        mutex: std.Thread.Mutex,
        fifo: Deque,

        pub fn init(allocator: std.mem.Allocator) !*Self {
            const self = try allocator.create(Self);
            self.* = .{
                .allocator = allocator,
                .mutex = std.Thread.Mutex{},
                .fifo = Deque.init(allocator),
            };
            return self;
        }

        pub fn deinit(self: *Self) void {
            while (self.fifo.readItem()) |elem| {
                if (comptime std.meta.hasFn(T, "deinit")) {
                    elem.deinit(); // Destroy data when possible
                }
            }
            self.fifo.deinit();
            self.allocator.destroy(self);
        }

        /// Push data to channel
        pub fn push(self: *Self, data: T) !void {
            self.mutex.lock();
            defer self.mutex.unlock();
            try self.fifo.writeItem(data);
        }

        /// Popped data from channel
        pub const PopResult = struct {
            allocator: std.mem.Allocator,
            elements: std.ArrayList(T),

            pub fn deinit(self: PopResult) void {
                for (self.elements.items) |*data| {
                    if (comptime std.meta.hasFn(T, "deinit")) {
                        data.deinit(); // Destroy data when possible
                    }
                }
                self.elements.deinit();
            }
        };

        /// Get data from channel, data will be destroyed together with PopResult
        pub fn popn(self: *Self, max_pop: usize) ?PopResult {
            self.mutex.lock();
            defer self.mutex.unlock();
            var result = PopResult{
                .allocator = self.allocator,
                .elements = std.ArrayList(T).init(self.allocator),
            };
            var count = max_pop;
            while (count > 0) : (count -= 1) {
                if (self.fifo.readItem()) |data| {
                    result.elements.append(data) catch unreachable;
                } else {
                    break;
                }
            }
            return if (count == max_pop) null else result;
        }

        /// Get data from channel, user take ownership
        pub fn pop(self: *Self) ?T {
            self.mutex.lock();
            defer self.mutex.unlock();
            return self.fifo.readItem();
        }
    };
}

pub const ParallelizeConfiguration = struct {
    showProgress: bool = false,
    workerCount: usize = 0,
};

const FakeProgress = struct {
    fn step(_: *FakeProgress) void {}
    fn deinit(_: *FakeProgress) void {}
};

const Progress = struct {
    progress: std.Progress,
    node: *std.Progress.Node,

    pub fn init(name: []const u8, estimated_total_items: usize, supports_ansi: bool) Progress {
        var progress = std.Progress{
            .terminal = std.io.getStdOut(),
            .supports_ansi_escape_codes = supports_ansi,
        };

        const node = progress.start(name, estimated_total_items);
        node.activate();

        return .{
            .progress = progress,
            .node = node,
        };
    }

    fn step(self: *Progress) void {
        self.node.completeOne();
    }

    fn deinit(self: *Progress) void {
        self.node.end();
    }
};

pub fn Parallelize(comptime Ctx: type, comptime In: type, comptime Out: type, comptime func: *const fn (Ctx, In) Out, comptime config: ParallelizeConfiguration) type {
    return struct {
        pub fn run(allocator: std.mem.Allocator, ctx: Ctx, input: []const In) ![]Out {
            const inputChannel = try Channel(In).init(allocator);
            defer inputChannel.deinit();

            const outputChannel = try Channel(Out).init(allocator);
            defer outputChannel.deinit();

            const cpuCount = if (config.workerCount != 0)
                config.workerCount
            else
                @min(try std.Thread.getCpuCount(), input.len);

            var workers = try allocator.alloc(std.Thread, cpuCount);
            defer allocator.free(workers);

            var output = try allocator.alloc(Out, input.len);

            for (input) |value|
                try inputChannel.push(value);

            //Start workers
            for (0..cpuCount) |i|
                workers[i] = try std.Thread.spawn(.{}, worker, .{ ctx, inputChannel, outputChannel });

            var progress = if (config.showProgress)
                Progress.init("Parallel work", input.len, false)
            else
                FakeProgress{};

            defer progress.deinit();

            for (0..input.len) |i| {
                while (true) {
                    if (outputChannel.pop()) |v| {
                        output[i] = v;
                        progress.step();
                        break;
                    } else {
                        std.time.sleep(std.time.ns_per_ms);
                    }
                }
            }

            for (workers) |wk|
                wk.join();

            return output;
        }

        fn worker(ctx: Ctx, input: *Channel(In), output: *Channel(Out)) !void {
            while (input.pop()) |v| {
                const response = func(ctx, v);
                try output.push(response);
            }
        }
    };
}
