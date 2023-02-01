const std = @import("std");
const net = std.net;

const server = @import("server.zig");
const debugPrint = std.debug.print;

const EXIT_SUCCESS = 0;
const EXIT_FAILURE = 1;

pub const io_mode = .evented;

pub fn main() !void {
    const address = "127.0.0.1";
    const port = 8080;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var tcpServer = server.Server.init(address, port, arena.allocator());
    defer tcpServer.deinit();

    tcpServer.listen() catch |err| {
        std.log.warn("Listening port failed: {}", .{err});
        std.process.exit(EXIT_FAILURE);
    };
}
