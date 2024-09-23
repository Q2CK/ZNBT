const std = @import("std");
const znbt = @import("znbt.zig");

test "example" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();

    var result = std.ArrayList(u8).init(std.testing.allocator);
    defer result.deinit();

    const file = try std.fs.cwd().createFile("test.nbt", .{});
    const file_writer = file.writer();

    var list = znbt.collections.List.init(std.testing.allocator, .Compound);

    var c1 = znbt.collections.Compound.init(std.testing.allocator);
    var c2 = znbt.collections.Compound.init(std.testing.allocator);
    var c3 = znbt.collections.Compound.init(std.testing.allocator);

    try c1.put("number 1", @as(i16, 123));
    try c1.put("number 2", @as(i16, 456));
    try c1.put("number 3", @as(i16, 789));

    const str1: []const u8 = "str1";
    const str2: []const u8 = "str2";

    try c2.put("string 1", str1);
    try c2.put("string 2", str2);

    var a: i64 = 0;
    a = 1;

    var arr = [_]i64{a};

    const array: []i64 = arr[0..];

    try c3.put("array", array);
    try c3.put("double", @as(f64, 12.34));

    try list.append(c1);
    try list.append(c2);
    try list.append(c3);

    try root.put("list", list);

    try znbt.io.write(std.testing.allocator, "znbt test", root, file_writer, .Gzip);

    for (result.items) |byte| {
        std.debug.print("{x:0>2} ", .{byte});
    }

    std.debug.print("\n", .{});
}
