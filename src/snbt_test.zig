const std = @import("std");
const znbt = @import("znbt.zig");

test "integer" {
    var root = znbt.collections.Compound.init(std.testing.allocator);
    defer root.deinit();
    // try root.put("string", @as([]const u8, "Hello, SNBT!"));
    try root.put("a", @as(i32, 42));
    // try root.put("float", @as(f32, 3.14));

    // var nested_compound = znbt.collections.Compound.init(std.testing.allocator);
    // try nested_compound.put("nested_key", @as([]const u8, "nested_value"));
    // try root.put("nested", nested_compound);

    // var list = znbt.collections.List.init(std.testing.allocator, .Int);
    // try list.append(@as(i32, 1));
    // try list.append(@as(i32, 2));
    // try list.append(@as(i32, 3));
    // try root.put("list", list);

    // std.debug.print("\n{}\n", .{root});

    // const file = try std.fs.cwd().createFile("data/omg.nbt", .{});
    // try znbt.io.write(std.testing.allocator, "dafu", root, file.writer(), .Gzip);

    const actual = try root.snbt(std.testing.allocator);
    const expected: []const u8 = "{a:42}";
    try std.testing.expectEqualSlices(u8, expected, actual);
}

// test "nested compound" {
//     const example_compound = try znbt.io.read(std.testing.allocator, "data/example.nbt");
//     const example_snbt = example_compound.snbt();

//     var root = znbt.collections.Compound.init(std.testing.allocator);
//     defer root.deinit();

//     const actual = try root.snbt();
//     // const expected: []const u8 = "{}1";
//     const expected: [2]u8 = .{ '{', '}' };

//     try std.testing.expectEqual(example_snbt, actual);
//     try std.testing.expect(std.mem.eql(u8, actual, &expected));
//     try std.testing.expectEqualSlices(u8, &expected, actual);
// }
