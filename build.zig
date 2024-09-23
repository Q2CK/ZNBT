const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule("znbt", .{
        .root_source_file = b.path("src/znbt.zig"),
    });
}
