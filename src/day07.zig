const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("data/day07.txt");

pub fn main() !void {
    try util.benchDay("07", part1, part2);
}

fn part1() !usize {
    @setEvalBranchQuota(50000);
    const lines = comptime util.allLines(data);

    var hands = [_]Hand{undefined} ** lines.len;

    for (lines, 0..) |line, i|
        hands[i] = parseHand(line, true);

    util.quicksort(Hand, &hands, handIsLessThan);

    var winnings: usize = 0;
    for (hands, 0..) |h, i|
        winnings += (i + 1) * h.bid;

    return winnings;
}

fn part2() !usize {
    @setEvalBranchQuota(50000);
    const lines = comptime util.allLines(data);

    var hands = [_]Hand{undefined} ** lines.len;

    for (lines, 0..) |line, i|
        hands[i] = parseHand(line, false);

    util.quicksort(Hand, &hands, handIsLessThan);

    var winnings: usize = 0;

    for (hands, 0..) |h, i|
        winnings += (i + 1) * h.bid;

    return winnings;
}

fn getCardValue(card: u8, noJoke: bool) usize {
    const c = std.ascii.toUpper(card);

    if (noJoke) {
        return switch (c) {
            '2' => 0,
            '3' => 1,
            '4' => 2,
            '5' => 3,
            '6' => 4,
            '7' => 5,
            '8' => 6,
            '9' => 7,
            'T' => 8,
            'J' => 9,
            'Q' => 10,
            'K' => 11,
            'A' => 12,
            else => @panic("What"),
        };
    }

    return switch (c) {
        'J' => 0,
        '2' => 1,
        '3' => 2,
        '4' => 3,
        '5' => 4,
        '6' => 5,
        '7' => 6,
        '8' => 7,
        '9' => 8,
        'T' => 9,
        'Q' => 10,
        'K' => 11,
        'A' => 12,
        else => @panic("What"),
    };
}

const HandType = enum { High, Pair, Double, Three, Full, Four, Five };

const Hand = struct {
    type: HandType,
    cards: [5]usize,
    bid: usize,
};

fn parseNumber(line: []const u8) usize {
    var n: usize = 0;
    for (6..line.len) |i|
        n = n * 10 + (line[i] - '0');
    return n;
}

fn decideHandType(cards: [5]usize, noJoke: bool) HandType {
    var counts = [_]usize{0} ** 13;
    var maxCount: usize = 0;
    var diffCount: usize = 0;

    for (cards) |card| {
        if (counts[card] == 0)
            diffCount += 1;

        counts[card] += 1;

        //Get the next highest count if noJoke and card = 'J'
        if (noJoke) {
            maxCount = @max(counts[card], maxCount);
        } else if (card > 0)
            maxCount = @max(counts[card], maxCount);
    }

    if (!noJoke) {
        const highestCard: usize = brk: {
            for (1..counts.len) |i| {
                if (counts[i] == maxCount)
                    break :brk i;
            }
            unreachable;
        };

        //If the game is JJJJJ, we know it's a Five already
        if (counts[0] == 5)
            return .Five;

        if (counts[0] > 0) {
            counts[highestCard] += counts[0];

            maxCount = counts[highestCard];
            diffCount -= 1;

            counts[0] = 0;
        }
    }

    return switch (diffCount) {
        5 => .High,
        4 => .Pair,
        3 => if (maxCount == 3) .Three else .Double,
        2 => {
            const minCount = brk: {
                var min: usize = 9999999;
                for (counts) |c| {
                    if (c != 0)
                        min = @min(min, c);
                }
                break :brk min;
            };

            return if (minCount == 2) .Full else .Four;
        },
        1 => .Five,
        else => unreachable,
    };
}

fn parseHand(line: []const u8, noJoke: bool) Hand {
    var cards = [_]usize{0} ** 5;

    for (0..5) |i|
        cards[i] = getCardValue(line[i], noJoke);

    const bid = parseNumber(line);

    return .{
        .type = decideHandType(cards, noJoke),
        .cards = cards,
        .bid = bid,
    };
}

fn handIsLessThan(a: Hand, b: Hand) bool {
    if (a.type == b.type) {
        for (0..5) |i| {
            if (a.cards[i] != b.cards[i])
                return a.cards[i] < b.cards[i];
        }

        return false;
    }

    return @intFromEnum(a.type) < @intFromEnum(b.type);
}

test "Day 07 pt 1" {
    try std.testing.expect(try part1() == 254024898);
}
test "Day 07 pt 2" {
    try std.testing.expect(try part2() == 254115617);
}
