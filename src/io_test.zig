const std = @import("std");
const znbt = @import("znbt.zig");

test "read" {
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
        \\                1
        \\            ],
        \\            double: 12.34
        \\        }
        \\    ]
        \\}
    ;

    try test_read("data/test_read/list.nbt", expected);   
}

// test "write byte nbt" {
//     var root = znbt.collections.Compound.init(std.testing.allocator);
//     defer root.deinit();

//     try root.put("byte", @as(i8, 56));

//     const file = try std.fs.cwd().createFile("data/test_read/byte.nbt", .{});
//     defer file.close();
//     const file_writer = file.writer();

//     try znbt.io.writeBin(std.testing.allocator, "test_read", root, file_writer, .Gzip);
// }

test "read byte" {
    const expected =
        \\{
        \\    byte: 56b
        \\}
    ;

    try test_read("data/test_read/byte.nbt", expected);
}

test "read short" {
    const expected =
        \\{
        \\    short: 256s
        \\}
    ;

    try test_read("data/test_read/short.nbt", expected);
}

fn test_read(input_path: []const u8, expected: []const u8) !void {
    var actual_compound = try znbt.io.readBin(std.testing.allocator, input_path);
    defer actual_compound.deinit();
    var actual_array_list = std.ArrayList(u8).init(std.testing.allocator);
    try znbt.io.writeSNBT(actual_compound, actual_array_list.writer(), .MultiLine);
    const actual = try actual_array_list.toOwnedSlice();
    defer std.testing.allocator.free(actual);

    try std.testing.expectEqualStrings(expected, actual);   
}
