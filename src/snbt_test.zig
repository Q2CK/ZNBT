const std = @import("std");
const znbt = @import("znbt.zig");

test "integer" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    try root.put("a", @as(i32, 42));

    try test_snbt(&root, "{a:42}");
}

test "string" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    try root.put("b", @as([]const u8, "Hello, SNBT!"));

    try test_snbt(&root, "{b:\"Hello, SNBT!\"}");
}

test "nested compound" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    var nested_compound = znbt.collections.Compound.init(std.testing.allocator);
    try nested_compound.put("nested_key", @as([]const u8, "nested_value"));
    try root.put("c", nested_compound);

    try test_snbt(&root, "{c:{nested_key:\"nested_value\"}}");
}

test "multiple tags" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    try root.put("a", @as(i32, 1));
    try root.put("b", @as([]const u8, "str"));

    try test_snbt(&root, "{b:\"str\",a:1}");
}

fn test_snbt(root: *znbt.collections.Compound, expected: []const u8) !void {
    var actual_arraylist = std.ArrayList(u8).init(std.testing.allocator);
    defer actual_arraylist.deinit();
    try znbt.io.writeSNBT(root.*, actual_arraylist.writer());
    const actual = try actual_arraylist.toOwnedSlice();
    try std.testing.expectEqualSlices(u8, expected, actual);
    std.testing.allocator.free(actual);
}
