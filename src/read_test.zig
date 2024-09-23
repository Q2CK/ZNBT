const std = @import("std");
const znbt = @import("znbt.zig");

test "read" {
    const root = try znbt.io.read(std.testing.allocator, "data/test.nbt");
    std.debug.print("\n{any}\n", .{root});
}
