const std = @import("std");

pub const Config = struct {
    listen: struct {
        address: []const u8,
        port: u16,
    },
    upstream: []struct {
        address: []const u8,
        port: u16,
    },

    pub fn init(jsonStr: []const u8, allocator: std.mem.Allocator) !Config {
        var stream = std.json.TokenStream.init(jsonStr);
        const config = try std.json.parse(Config, &stream, .{ .allocator = allocator });
        return config;
    }

    pub fn deinit(self: *Config, allocator: std.mem.Allocator) void {
        defer std.json.parseFree(Config, self.*, .{ .allocator = allocator });
    }
};

test "json config" {
    const expect = std.testing.expect;
    const testConfigStr =
        \\ {
        \\   "listen": {
        \\     "address": "127.0.0.1",
        \\     "port": 3030
        \\   },
        \\   "upstream": [
        \\     {
        \\       "address": "192.168.0.1",
        \\       "port": 5700
        \\     },
        \\     {
        \\       "address": "192.178.1.2",
        \\       "port": 5432
        \\     }
        \\   ]
        \\ }
    ;

    var config = try Config.init(testConfigStr, std.testing.allocator);
    defer config.deinit(std.testing.allocator);

    try expect(std.mem.eql(u8, config.listen.address, "127.0.0.1"));
    try expect(config.listen.port == 3030);

    try expect(std.mem.eql(u8, config.upstream[0].address, "192.168.0.1"));
    try expect(config.upstream[0].port == 5700);

    try expect(std.mem.eql(u8, config.upstream[1].address, "192.178.1.2"));
    try expect(config.upstream[1].port == 5432);
}
