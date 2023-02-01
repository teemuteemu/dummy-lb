const std = @import("std");
const net = std.net;

pub const Server = struct {
    address: net.Address,
    streamServer: net.StreamServer,
    allocator: std.mem.Allocator,

    pub fn init(name: []const u8, port: u16, allocator: std.mem.Allocator) Server {
        var address = net.Address.parseIp(name, port) catch unreachable;
        var streamServer = net.StreamServer.init(.{});

        return .{
            .address = address,
            .streamServer = streamServer,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Server) void {
        self.streamServer.deinit();
    }

    pub fn listen(self: *Server) !void {
        try self.streamServer.listen(self.address);
        std.log.info("Listening :{d}...", .{self.address.getPort()});

        while (true) {
            var con = try self.streamServer.accept();
            std.debug.print("{}\n", .{con});
        }
    }
};
