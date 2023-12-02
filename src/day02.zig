const std = @import("std");
const isDigit = std.ascii.isDigit;
const isLetter = std.ascii.isAlphabetic;

const data = @embedFile("data/day02.txt");

// const data =
//     \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
//     \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
//     \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
//     \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
//     \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
//     \\
// ;

pub fn main() !void {
    try part1();
    try part2();
}

fn part1() !void {
    var sum: usize = 0;

    var lines = std.mem.tokenize(u8, data, "\r\n");

    while (lines.next()) |line| {
        var parser = Parser{ .lexer = Lexer{ .source = line } };

        const game = try parser.parse();

        if (game.isValid())
            sum += game.gameId;
    }

    std.debug.print("Total: {d}\n", .{sum});
}

fn part2() !void {
    var sum: usize = 0;

    var lines = std.mem.tokenize(u8, data, "\r\n");

    while (lines.next()) |line| {
        var parser = Parser{ .lexer = Lexer{ .source = line } };

        const game = try parser.parse();

        const power = game.red * game.green * game.blue;

        sum += power;
    }

    std.debug.print("Total: {d}\n", .{sum});
}

const TokenType = enum { Identifier, Number, Comma, Colon, Semicolon };

const Token = struct {
    value: []const u8,
    type: TokenType,
};

//Space-skipping lexer
const Lexer = struct {
    source: []const u8,
    pos: usize = 0,

    fn makeToken(self: *Lexer, tokenType: TokenType, length: usize) Token {
        defer self.pos += length;
        return .{ .type = tokenType, .value = self.source[self.pos .. self.pos + length] };
    }

    fn matchWithFn(self: *Lexer, tokenType: TokenType, testFn: *const fn (u8) bool) Token {
        const src = self.source;
        const pos = self.pos;

        var length: usize = 0;
        while ((pos + length) < src.len and testFn(src[pos + length]))
            length += 1;

        return self.makeToken(tokenType, length);
    }

    fn next(self: *Lexer) !?Token {
        while (!self.isDone()) {
            const c = self.source[self.pos];
            switch (c) {
                ' ' => self.pos += 1,
                ':' => return self.makeToken(.Colon, 1),
                ';' => return self.makeToken(.Semicolon, 1),
                ',' => return self.makeToken(.Comma, 1),
                else => {
                    if (isDigit(c))
                        return self.matchWithFn(.Number, isDigit);

                    if (isLetter(c))
                        return self.matchWithFn(.Identifier, isLetter);

                    return error.WrongFormat;
                },
            }
        }

        return null;
    }

    fn isDone(self: *Lexer) bool {
        return self.pos >= self.source.len;
    }
};

const Parser = struct {
    const Round = struct { r: usize = 0, g: usize = 0, b: usize = 0 };

    lexer: Lexer,
    gameId: usize = 0,
    colors: [3]usize = .{ 0, 0, 0 },

    currentToken: ?Token = null,

    fn isDone(self: *Parser) bool {
        return self.currentToken == null;
    }

    fn advance(self: *Parser) !void {
        self.currentToken = try self.lexer.next();
    }

    fn expect(self: *Parser, tokenType: TokenType) !void {
        _ = try self.expectToken(tokenType);
    }

    fn expectToken(self: *Parser, tokenType: TokenType) !Token {
        if (self.currentToken == null)
            return error.EndOfInput;

        const token = self.currentToken.?;

        if (token.type != tokenType)
            return error.UnexpectedToken;

        try self.advance();

        return token;
    }

    fn match(self: *Parser, tokenType: TokenType) !bool {
        return try self.matchToken(tokenType) != null;
    }

    fn matchToken(self: *Parser, tokenType: TokenType) !?Token {
        if (self.currentToken == null)
            return null;

        const token = self.currentToken.?;

        if (token.type == tokenType) {
            try self.advance();
            return token;
        }

        return null;
    }

    fn parseHeader(self: *Parser) !void {
        const header = try self.expectToken(.Identifier);

        if (!std.mem.eql(u8, header.value, "Game"))
            return error.WrongFormat;

        const id = try self.expectToken(.Number);

        self.gameId = try std.fmt.parseInt(usize, id.value, 10);

        try self.expect(.Colon);
    }

    fn parseRound(self: *Parser) !Round {
        var round = Round{};

        while (!try self.match(.Semicolon)) {
            const countTk = (try self.matchToken(.Number)).?;
            const colorTk = (try self.matchToken(.Identifier)).?;

            const count = try std.fmt.parseInt(usize, countTk.value, 10);

            switch (colorTk.value[0]) {
                'r' => round.r = @max(round.r, count),
                'g' => round.g = @max(round.g, count),
                'b' => round.b = @max(round.b, count),
                else => return error.WrongFormat,
            }

            if (!try self.match(.Comma))
                break;
        }

        _ = try self.match(.Semicolon);

        return round;
    }

    fn parse(self: *Parser) !GameInfo {
        try self.advance(); //Prime the lexer

        try self.parseHeader(); //Get the game id

        var colors = [_]usize{ 0, 0, 0 };

        while (!self.isDone()) {
            const round = try self.parseRound();

            colors[0] = @max(round.r, colors[0]);
            colors[1] = @max(round.g, colors[1]);
            colors[2] = @max(round.b, colors[2]);
        }

        return GameInfo.init(colors[0], colors[1], colors[2], self.gameId);
    }
};

const GameInfo = struct {
    red: usize,
    blue: usize,
    green: usize,
    gameId: usize,

    pub fn init(r: usize, g: usize, b: usize, id: usize) @This() {
        return .{ .red = r, .green = g, .blue = b, .gameId = id };
    }

    fn isValid(self: *const @This()) bool {
        return self.red <= 12 and self.green <= 13 and self.blue <= 14;
    }
};
