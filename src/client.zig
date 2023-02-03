const std = @import("std");
const net = std.net;

pub const Client = struct {
    conn: net.StreamServer.Connection,
    handle_frame: @Frame(handle),

    pub fn handle(self: *Client) !void {
        std.log.info("New connection: {}", .{self.conn.address});

        // var writer = self.conn.stream.writer();
        // try writer.print("moro\n", .{}); // TODO remove

        while (true) {
            var buffer: [1024]u8 = undefined;
            const len = try self.conn.stream.read(buffer[0..]);

            if (len == 0) break;

            const message = buffer[0..len];
            std.debug.print("received: {d} {s}", .{ len, message });
        }

        self.conn.stream.close();
        std.log.info("Connection closed", .{});
    }
};
