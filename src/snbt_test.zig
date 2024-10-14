const std = @import("std");
const znbt = @import("znbt.zig");
const constants = @import("constants.zig");
const ENABLE_DEBUG_PRINTS = constants.ENABLE_DEBUG_PRINTS;
const SNBTFormat = znbt.io.SNBTFormat;

test "compact byte" { try testCaseCompact("k", @as(i8, 42), "{k:42b}"); }
test "compact short" { try testCaseCompact("k", @as(i16, 42), "{k:42s}"); }
test "compact integer" { try testCaseCompact("k", @as(i32, 42), "{k:42}"); }
test "compact long" { try testCaseCompact("k", @as(i64, 42), "{k:42l}"); }
test "compact float" { try testCaseCompact("k", @as(f32, 12.34), "{k:12.34f}"); }
test "compact double" { try testCaseCompact("k", @as(f64, 12.34), "{k:12.34d}"); }
test "compact string" { try testCaseCompact("k", @as([]const u8, "Hello, SNBT!"), "{k:\"Hello, SNBT!\"}"); }
test "compact byte array" { try testCaseCompact("k", @as([]const i8, &[_]i8{-1, 2, 3}), "{k:[B;-1b,2b,3b]}"); }
test "compact int array" { try testCaseCompact("k", @as([]const i32, &[_]i32{-1, 2, 3}), "{k:[I;-1,2,3]}"); }
test "compact long array" { try testCaseCompact("k", @as([]const i64, &[_]i64{-1, 2, 3}), "{k:[L;-1l,2l,3l]}"); }

fn testCaseCompact(key: []const u8, value: anytype, expected: []const u8) !void {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();

    try root.put(key, value);
    try testSnbt(&root, expected, SNBTFormat.Compact);
}

test "compact nested compound" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    var nested_compound = znbt.collections.Compound.init(std.testing.allocator);
    try nested_compound.put("nested_key", @as([]const u8, "nested_value"));
    try root.put("c", nested_compound);

    try testSnbt(&root, "{c:{nested_key:\"nested_value\"}}", SNBTFormat.Compact);
}

test "compact multiple tags" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    try root.put("a", @as(i32, 1));
    try root.put("b", @as([]const u8, "str"));

    try testSnbt(&root, "{b:\"str\",a:1}", SNBTFormat.Compact);
}

test "compact list" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    var list = znbt.collections.List.init(std.testing.allocator, .Int);
    try list.append(@as(i32, 10));
    try list.append(@as(i32, 20));
    try list.append(@as(i32, 30));
    try root.put("d", list);

    try testSnbt(&root, "{d:[10,20,30]}", SNBTFormat.Compact);
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
    try testSnbt(&root, expected, SNBTFormat.MultiLine);
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
    try testSnbt(&root, expected, SNBTFormat.MultiLine);
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
    try testSnbt(&root, expected, SNBTFormat.MultiLine);
}

test "multiline byte" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    try root.put("a", @as(i8, 64));

    const expected =
        \\{
        \\    a: 64b
        \\}
    ;
    try testSnbt(&root, expected, SNBTFormat.MultiLine);
}

test "multiline short" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    try root.put("a", @as(i16, 64));

    const expected =
        \\{
        \\    a: 64s
        \\}
    ;
    try testSnbt(&root, expected, SNBTFormat.MultiLine);
}

test "multiline int" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    try root.put("a", @as(i32, 64));

    const expected =
        \\{
        \\    a: 64
        \\}
    ;
    try testSnbt(&root, expected, SNBTFormat.MultiLine);
}

test "multiline byte array" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    const byteArrayValue: [3]i8 = .{-1, 2, 3};
    try root.put("byteArray", @as([]const i8, &byteArrayValue));

    const expected =
        \\{
        \\    byteArray: [
        \\        B;
        \\        -1b,
        \\        2b,
        \\        3b
        \\    ]
        \\}
    ;
    try testSnbt(&root, expected, SNBTFormat.MultiLine);
}

test "multiline int array" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    const byteArrayValue: [3]i32 = .{-12, 24, 3345};
    try root.put("intArray", @as([]const i32, &byteArrayValue));

    const expected =
        \\{
        \\    intArray: [
        \\        I;
        \\        -12,
        \\        24,
        \\        3345
        \\    ]
        \\}
    ;
    try testSnbt(&root, expected, SNBTFormat.MultiLine);
}

test "multiline long array" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    const longArrayValue: [3]i64 = .{-12, 24, 3345};
    try root.put("longArray", @as([]const i64, &longArrayValue));

    const expected =
        \\{
        \\    longArray: [
        \\        L;
        \\        -12l,
        \\        24l,
        \\        3345l
        \\    ]
        \\}
    ;
    try testSnbt(&root, expected, SNBTFormat.MultiLine);
}

test "multiline float" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    try root.putFloat("a", 12.34);

    const expected =
        \\{
        \\    a: 12.34f
        \\}
    ;
    try testSnbt(&root, expected, SNBTFormat.MultiLine);
}

test "multiline double" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    try root.putDouble("a", 12.34);

    const expected =
        \\{
        \\    a: 12.34d
        \\}
    ;
    try testSnbt(&root, expected, SNBTFormat.MultiLine);
}

fn testSnbt(root: *znbt.collections.Compound, expected: []const u8, format: SNBTFormat) !void {
    var actual_arraylist = std.ArrayList(u8).init(std.testing.allocator);
    try znbt.io.writeSNBT(root.*, actual_arraylist.writer(), format);
    const actual = try actual_arraylist.toOwnedSlice();
    defer std.testing.allocator.free(actual);
    if (ENABLE_DEBUG_PRINTS) {
        std.debug.print("{s}\n", .{actual}); // Helps see the pretty printed value i nconsole
    }
    try std.testing.expectEqualStrings(expected, actual);
}
