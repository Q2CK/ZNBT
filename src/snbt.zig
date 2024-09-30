const NbtError = @import("errors.zig").NbtError;
const INDENT_SIZE_IN_SPACES = @import("constants.zig").INDENT_SIZE_IN_SPACES;


pub fn writeArray(comptime T: type, array: []const T, writer: anytype, indent: usize, suffix: ?u8) NbtError!void {
    _ = try writer.write("[");
    for (array, 0..) |tag, i| {
        _ = try writer.write("\n");
        _ = try writer.writeByteNTimes(' ', indent + INDENT_SIZE_IN_SPACES);
        if (suffix) |value| {
            _ = try writer.print("{d}{c}", .{tag, value});
        } else {
            _ = try writer.print("{d}", .{tag});
        }
        const is_last_tag = array.len - 1 == i;
        if (!is_last_tag) {
            _ = try writer.write(",");
        }
    }

    _ = try writer.write("\n");
    _ = try writer.writeByteNTimes(' ', indent);
    _ = try writer.write("]");
}