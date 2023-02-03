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
            var inBuffer: [1024]u8 = undefined;
            const inLen = try self.inConnection.stream.read(inBuffer[0..]);

            if (inLen == 0) break;

            const inMsg = inBuffer[0..inLen];
            // std.debug.print("in: {d} {s}", .{ inLen, inMsg });
            var outWriter = self.outConnection.writer();
            try outWriter.writeAll(inMsg);

            while (true) {
                var outBuffer: [1024]u8 = undefined;
                const outLen = try self.outConnection.read(outBuffer[0..]);

                if (outLen == 0) break;
                const outMsg = outBuffer[0..outLen];
                // std.debug.print("out: {d} {s}", .{ outLen, outMsg });
                var inWriter = self.inConnection.stream.writer();
                try inWriter.writeAll(outMsg);
            }
        }

        self.inConnection.stream.close();
        self.outConnection.close();
        std.log.info("Connection closed", .{});
    }
};
