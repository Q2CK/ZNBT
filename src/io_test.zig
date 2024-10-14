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

test "read int" {
    const expected =
        \\{
        \\    int: 65536
        \\}
    ;

    try test_read("int.nbt", expected);
}

test "read long" {
    const expected =
        \\{
        \\    long: 4294967296l
        \\}
    ;

    try test_read("long.nbt", expected);
}

test "read float" {
    const expected =
        \\{
        \\    float: 12.34f
        \\}
    ;

    try test_read("float.nbt", expected);
}

test "read double" {
    const expected =
        \\{
        \\    double: 12.34d
        \\}
    ;

    try test_read("double.nbt", expected);
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

test "read int array" {
    const expected =
        \\{
        \\    intArray: [
        \\        I;
        \\        1,
        \\        2,
        \\        3
        \\    ]
        \\}
    ;

    try test_read("int_array.nbt", expected);
}

test "read long array" {
    const expected =
        \\{
        \\    longArray: [
        \\        L;
        \\        1l,
        \\        2l,
        \\        3l
        \\    ]
        \\}
    ;

    try test_read("long_array.nbt", expected);
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

test "read list shorts" {
    const expected =
        \\{
        \\    list: [
        \\        1s,
        \\        2s,
        \\        3s
        \\    ]
        \\}
    ;

    try test_read("list_shorts.nbt", expected);
}

test "read list ints" {
    const expected =
        \\{
        \\    list: [
        \\        1,
        \\        2,
        \\        3
        \\    ]
        \\}
    ;

    try test_read("list_ints.nbt", expected);
}

test "read list longs" {
    const expected =
        \\{
        \\    list: [
        \\        1l,
        \\        2l,
        \\        3l
        \\    ]
        \\}
    ;

    try test_read("list_longs.nbt", expected);
}

test "read list floats" {
    const expected =
        \\{
        \\    list: [
        \\        12.34f,
        \\        23.45f,
        \\        34.56f
        \\    ]
        \\}
    ;

    try test_read("list_floats.nbt", expected);
}

test "read list doubles" {
    const expected =
        \\{
        \\    list: [
        \\        12.34d,
        \\        23.45d,
        \\        34.56d
        \\    ]
        \\}
    ;

    try test_read("list_doubles.nbt", expected);
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

test "read list lists" {
    const expected =
        \\{
        \\    list: [
        \\        [
        \\            1b,
        \\            2b
        \\        ],
        \\        [
        \\            3b,
        \\            4b
        \\        ]
        \\    ]
        \\}
    ;

    try test_read("list_lists.nbt", expected);
}

// test "read list complex compounds" {
//     const expected = 
//         \\{
//         \\    list: [
//         \\        {
//         \\            number 1: 123s,
//         \\            number 2: 456s,
//         \\            number 3: 789s
//         \\        },
//         \\        {
//         \\            string 1: "str1",
//         \\            string 2: "str2"
//         \\        },
//         \\        {
//         \\            array: [
//         \\                L;
//         \\                1l
//         \\            ],
//         \\            double: 12.34d
//         \\        }
//         \\    ]
//         \\}
//     ;

//     try test_read("list_complex_compounds.nbt", expected);   
// }

fn test_read(input_filename: []const u8, expected: []const u8) !void {
    const alloc = std.testing.allocator;
    const filepath = try std.fmt.allocPrint(alloc, "test_data/gzip/{s}", .{input_filename});
    defer alloc.free(filepath);
    var actual_compound = try znbt.io.readBin(alloc, filepath);
    defer actual_compound.deinit();
    var actual_array_list = std.ArrayList(u8).init(alloc);
    try znbt.io.writeSNBT(actual_compound, actual_array_list.writer(), .MultiLine);
    const actual = try actual_array_list.toOwnedSlice();
    defer alloc.free(actual);

    try std.testing.expectEqualStrings(expected, actual);   
}
