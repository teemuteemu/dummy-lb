const std = @import("std");
const net = std.net;

const config = @import("config.zig");

pub const Client = struct {
    inConnection: net.StreamServer.Connection,
    outConnection: net.Stream,
    handle_frame: @Frame(handle),

    pub fn handle(self: *Client) !void {
        std.log.info("New connection: {}", .{self.inConnection.address});

        while (true) {
            var buffer: [1024]u8 = undefined;
            const len = try self.inConnection.stream.read(buffer[0..]);

            if (len == 0) break;

            const message = buffer[0..len];
            // std.debug.print("received: {d} {s}", .{ len, message });
            var writer = self.outConnection.writer();
            try writer.writeAll(message);
        }

        self.inConnection.stream.close();
        self.outConnection.close();
        std.log.info("Connection closed", .{});
    }
};
