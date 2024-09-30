const std = @import("std");
const znbt = @import("znbt.zig");
const SNBTFormat = znbt.io.SNBTFormat;

test "integer" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    try root.put("a", @as(i32, 42));

    try test_snbt(&root, "{a:42}", SNBTFormat.Compact);
}

test "string" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    try root.put("b", @as([]const u8, "Hello, SNBT!"));

    try test_snbt(&root, "{b:\"Hello, SNBT!\"}", SNBTFormat.Compact);
}

test "nested compound" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    var nested_compound = znbt.collections.Compound.init(std.testing.allocator);
    try nested_compound.put("nested_key", @as([]const u8, "nested_value"));
    try root.put("c", nested_compound);

    try test_snbt(&root, "{c:{nested_key:\"nested_value\"}}", SNBTFormat.Compact);
}

test "multiple tags" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    try root.put("a", @as(i32, 1));
    try root.put("b", @as([]const u8, "str"));

    try test_snbt(&root, "{b:\"str\",a:1}", SNBTFormat.Compact);
}

test "list" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    var list = znbt.collections.List.init(std.testing.allocator, .Int);
    try list.append(@as(i32, 10));
    try list.append(@as(i32, 20));
    try list.append(@as(i32, 30));
    try root.put("d", list);

    try test_snbt(&root, "{d:[10,20,30]}", SNBTFormat.Compact);
}

test "multiline nested" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    var nested_compound = znbt.collections.Compound.init(std.testing.allocator);
    try nested_compound.put("nested_key", @as([]const u8, "nested_value"));
    try root.put("c", nested_compound);

    const expected =
        \\{
        \\    c: {
        \\        nested_key: "nested_value"
        \\    }
        \\}
    ;
    try test_snbt(&root, expected, SNBTFormat.MultiLine);
}

test "multiline list" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    var list = znbt.collections.List.init(std.testing.allocator, .Int);
    try list.append(@as(i32, 10));
    try list.append(@as(i32, 20));
    try list.append(@as(i32, 30));
    try root.put("list", list);

    const expected =
        \\{
        \\    list: [
        \\        10,
        \\        20,
        \\        30
        \\    ]
        \\}
    ;
    try test_snbt(&root, expected, SNBTFormat.MultiLine);
}

test "multiline list of compounds" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    var list = znbt.collections.List.init(std.testing.allocator, .Compound);
    var compound1 = znbt.collections.Compound.init(std.testing.allocator); 
    try compound1.put("a", @as(i32, 42));
    var compound2 = znbt.collections.Compound.init(std.testing.allocator); 
    try compound2.put("b", @as([]const u8, "str"));
    try compound2.put("c", @as([]const u8, "str2"));
    try list.append(compound1);
    try list.append(compound2);
    try root.put("list", list);

    const expected =
        \\{
        \\    list: [
        \\        {
        \\            a: 42
        \\        },
        \\        {
        \\            b: "str",
        \\            c: "str2"
        \\        }
        \\    ]
        \\}
    ;
    try test_snbt(&root, expected, SNBTFormat.MultiLine);
}

test "multiline long array" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    var longArray = znbt.collections.List.init(std.testing.allocator, .Long);
    try longArray.append(@as(i64, 123));
    try longArray.append(@as(i64, 456));
    try longArray.append(@as(i64, 789));
    try root.put("longArray", longArray);

    const expected =
        \\{
        \\    longArray: [
        \\        123l,
        \\        456l,
        \\        789l
        \\    ]
        \\}
    ;
    try test_snbt(&root, expected, SNBTFormat.MultiLine);
}

fn test_snbt(root: *znbt.collections.Compound, expected: []const u8, format: SNBTFormat) !void {
    var actual_arraylist = std.ArrayList(u8).init(std.testing.allocator);
    try znbt.io.writeSNBT(root.*, actual_arraylist.writer(), format);
    const actual = try actual_arraylist.toOwnedSlice();
    std.debug.print("{s}\n", .{actual}); // Helps see the pretty printed value i nconsole
    try std.testing.expectEqualSlices(u8, expected, actual);
    std.testing.allocator.free(actual);
}
