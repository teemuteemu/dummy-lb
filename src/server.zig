const std = @import("std");
const net = std.net;

const client = @import("client.zig");
const config = @import("config.zig");

pub const Server = struct {
    address: net.Address,
    streamServer: net.StreamServer,
    allocator: std.mem.Allocator,
    config: config.Config,
    rrIndex: u16,

    pub fn init(serverConfig: config.Config, allocator: std.mem.Allocator) Server {
        var address = net.Address.parseIp(serverConfig.listen.address, serverConfig.listen.port) catch unreachable;
        var streamServer = net.StreamServer.init(.{});

        return .{
            .address = address,
            .streamServer = streamServer,
            .allocator = allocator,
            .config = serverConfig,
            .rrIndex = 0,
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
            var upstream = self.config.upstream[self.rrIndex];

            std.log.info("Serving to upstream {s}:{d}...", .{ upstream.address, upstream.port });

            var inConnection = try self.streamServer.accept();
            var upstreamAddress = std.net.Address.parseIp(upstream.address, upstream.port) catch unreachable;
            var outConnection = try std.net.tcpConnectToAddress(upstreamAddress);

            incomingClient.* = client.Client{
                .inConnection = inConnection,
                .outConnection = outConnection,
                .handle_frame = async incomingClient.handle(),
            };

            self.rrIndex = if (self.rrIndex == self.config.upstream.len - 1)
                0
            else
                self.rrIndex + 1;
        }
    }
};
