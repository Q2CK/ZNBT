const std = @import("std");
const tag_import = @import("tag.zig");
const Tag = tag_import.Tag;
const TagType = tag_import.TagType;

const NbtError = @import("errors.zig").NbtError;
const INDENT_SIZE_IN_SPACES = @import("constants.zig").INDENT_SIZE_IN_SPACES;
const ENABLE_DEBUG_PRINTS = @import("constants.zig").ENABLE_DEBUG_PRINTS;

pub fn listSnbtCompact(tags: std.ArrayList(Tag), writer: anytype) NbtError!void {
    _ = try writer.write("[");
    
    for (tags.items, 0..) |tag, i| {
        _ = try tag.snbtCompact(writer);
        const is_last_tag = tags.items.len - 1 == i;
        if (!is_last_tag) {
            _ = try writer.write(",");
        }
    }
    _ = try writer.write("]");

}

pub fn listSnbtMultiline(tags: std.ArrayList(Tag), writer: anytype, indent: usize) NbtError!void {
    _ = try writer.write("[");

    for (tags.items, 0..) |tag, i| {
        _ = try writer.write("\n",);
        _ = try writer.writeByteNTimes(' ', indent + INDENT_SIZE_IN_SPACES);
        try tag.snbtMultiline(writer, indent + INDENT_SIZE_IN_SPACES);
        const is_last_tag = tags.items.len - 1 == i;
        if (!is_last_tag) {
            _ = try writer.write(",");
        }
    }

    _ = try writer.write("\n");
    _ = try writer.writeByteNTimes(' ', indent);
    _ = try writer.write("]");
}

pub fn compoundSnbtCompact(tags: std.StringHashMap(Tag), writer: anytype) NbtError!void {
    _ = try writer.write("{");

    var it = tags.iterator();
    var i: usize = 0;
    while (it.next()) |entry| {
        _ = try writer.write(entry.key_ptr.*);
        _ = try writer.write(":");
        const tag = entry.value_ptr.*;
        try tag.snbtCompact(writer);
        const is_last_tag = tags.count() - 1 == i;
        if (!is_last_tag) {
            _ = try writer.write(",");
        }
        i += 1;
    }

    _ = try writer.write("}");
}

pub fn compoundSnbtMultiline(tags: std.StringHashMap(Tag), writer: anytype, indent: usize) NbtError!void {
    _ = try writer.write("{");
    if (ENABLE_DEBUG_PRINTS) {
        std.debug.print("tags count: {d}\n", .{tags.count()});
    }

    var it = tags.iterator();
    var i: i32 = 0;

    while (it.next()) |entry| {
        _ = try writer.write("\n");
        _ = try writer.writeByteNTimes(' ', indent + INDENT_SIZE_IN_SPACES);
        if (ENABLE_DEBUG_PRINTS) {
            std.debug.print("entry key: {s}\n", .{entry.key_ptr.*});
        }
        _ = try writer.write(entry.key_ptr.*);
        _ = try writer.write(": ");
        const tag = entry.value_ptr.*;
        try tag.snbtMultiline(writer, indent + INDENT_SIZE_IN_SPACES);
        const is_last_tag = i == tags.count() - 1;
        if (!is_last_tag) {
            _ = try writer.write(",");
        }
        i += 1;            
    }

    _ = try writer.write("\n");
    _ = try writer.writeByteNTimes(' ', indent);
    _ = try writer.write("}");
}

pub fn writeArrayCompact(comptime T: type, array: []const T, writer: anytype, prefix: u8, suffix: ?u8) NbtError!void {
    _ = try writer.print("[{c};", .{prefix});

    for (array, 0..) |tag, i| {
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

    _ = try writer.write("]");
}

pub fn writeArrayMultiline(comptime T: type, array: []const T, writer: anytype, indent: usize, prefix: u8, suffix: ?u8) NbtError!void {
    _ = try writer.write("[");

    _ = try writer.write("\n");
    _ = try writer.writeByteNTimes(' ', indent + INDENT_SIZE_IN_SPACES);
    _ = try writer.writeByte(prefix);
    _ = try writer.write(";");

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