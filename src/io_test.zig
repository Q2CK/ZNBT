const std = @import("std");
const znbt = @import("znbt.zig");

test "read byte" {
    const expected =
        \\{
        \\    byte: 1b
        \\}
    ;

    try test_read("byte.nbt", expected);
}

test "read short" {
    const expected =
        \\{
        \\    short: 256s
        \\}
    ;

    try test_read("short.nbt", expected);
}

test "read list bytes" {
    const expected =
        \\{
        \\    list: [
        \\        1b,
        \\        2b,
        \\        3b
        \\    ]
        \\}
    ;

    try test_read("list_bytes.nbt", expected);
}

test "read list compounds" {
    const expected = 
        \\{
        \\    list: [
        \\        {
        \\            byte: 1b
        \\        },
        \\        {
        \\            byte: 2b
        \\        }
        \\    ]
        \\}
    ;

    try test_read("list_compounds.nbt", expected);   
}

test "read byte array" {
    const expected =
        \\{
        \\    byteArray: [
        \\        B;
        \\        1b,
        \\        2b,
        \\        3b
        \\    ]
        \\}
    ;

    try test_read("byte_array.nbt", expected);
}

test "read list complex compounds" {
    const expected = 
        \\{
        \\    list: [
        \\        {
        \\            number 1: 123s,
        \\            number 2: 456s,
        \\            number 3: 789s
        \\        },
        \\        {
        \\            string 1: "str1",
        \\            string 2: "str2"
        \\        },
        \\        {
        \\            array: [
        \\                L;
        \\                1l
        \\            ],
        \\            double: 12.34d
        \\        }
        \\    ]
        \\}
    ;

    try test_read("list_complex_compounds.nbt", expected);   
}

fn test_read(input_filename: []const u8, expected: []const u8) !void {
    const filepath = try std.fmt.allocPrint(std.testing.allocator, "test_data/gzip/{s}", .{input_filename});
    var actual_compound = try znbt.io.readBin(std.testing.allocator, filepath);
    defer actual_compound.deinit();
    var actual_array_list = std.ArrayList(u8).init(std.testing.allocator);
    try znbt.io.writeSNBT(actual_compound, actual_array_list.writer(), .MultiLine);
    const actual = try actual_array_list.toOwnedSlice();
    defer std.testing.allocator.free(actual);

    try std.testing.expectEqualStrings(expected, actual);   
}
