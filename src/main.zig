const std = @import("std");
const net = std.net;

const server = @import("server.zig");
const config = @import("config.zig");

const debugPrint = std.debug.print;

const EXIT_SUCCESS = 0;
const EXIT_FAILURE = 1;

pub const io_mode = .evented;

const testConfigStr =
    \\ {
    \\   "listen": {
    \\     "address": "127.0.0.1",
    \\     "port": 8080
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

pub fn main() !void {
    var serverConfig = try config.Config.init(testConfigStr, std.heap.page_allocator);
    defer serverConfig.deinit(std.heap.page_allocator);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var tcpServer = server.Server.init(serverConfig, arena.allocator());
    defer tcpServer.deinit();

    tcpServer.listen() catch |err| {
        std.log.warn("Listening port failed: {}", .{err});
        std.process.exit(EXIT_FAILURE);
    };
}
