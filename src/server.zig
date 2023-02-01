const std = @import("std");
const net = std.net;

const client = @import("client.zig");

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
        std.log.info("Listening {}...", .{self.address});

        while (true) {
            var incomingClient = try self.allocator.create(client.Client);
            incomingClient.* = client.Client{
                .conn = try self.streamServer.accept(),
                .handle_frame = async incomingClient.handle(),
            };
        }
    }
};
