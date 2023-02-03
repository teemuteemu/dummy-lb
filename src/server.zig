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
            var upstream = self.config.upstream[self.rrIndex];

            self.rrIndex = if (self.rrIndex == self.config.upstream.len - 1)
                0
            else
                self.rrIndex + 1;

            var upstreamAddress = std.net.Address.parseIp(upstream.address, upstream.port) catch unreachable;
            var inConnection = try self.streamServer.accept();
            var outConnection = std.net.tcpConnectToAddress(upstreamAddress) catch {
                std.log.warn("Upstream {s}:{d} is not reachable", .{ upstream.address, upstream.port });
                inConnection.stream.close();
                continue;
            };

            var incomingClient = try self.allocator.create(client.Client);
            std.log.info("Serving to upstream {s}:{d}...", .{ upstream.address, upstream.port });

            incomingClient.* = client.Client{
                .inConnection = inConnection,
                .outConnection = outConnection,
                .handle_frame = async incomingClient.handle(),
            };
        }
    }
};
