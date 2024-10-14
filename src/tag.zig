const std = @import("std");
const NbtError = @import("errors.zig").NbtError;

const collections = @import("collections.zig");
const snbt = @import("snbt.zig");
const writeArrayMultiline = snbt.writeArrayMultiline;
const writeArrayCompact = snbt.writeArrayCompact;

const INDENT_SIZE_IN_SPACES = @import("constants.zig").INDENT_SIZE_IN_SPACES;

pub const TagType = enum(u8) {
    End = 0,

    Byte = 1,
    Short = 2,
    Int = 3,
    Long = 4,
    Float = 5,
    Double = 6,

    ByteArray = 7,
    String = 8,
    List = 9,
    Compound = 10,
    IntArray = 11,
    LongArray = 12,
};

pub const Tag = struct {
    const Self = @This();

    alloc: std.mem.Allocator,
    tag_union: TagUnion,

    /// Creates a `Tag` from a corresponding Zig type or znbt collection.
    /// 
    /// Important note: When you pass `List` and `Compound` collection
    /// then this `Tag` will own the collection and will free it in `deinit`.
    /// The ByteArray ([]i8), String ([]u8), IntArray ([]i32) and LongArray ([]i64)
    /// are cloned on `from` call, so the original slice should be freed by the caller.
    pub fn from(alloc: std.mem.Allocator, value: anytype) NbtError!Self {
        return Self{
            .alloc = alloc,
            .tag_union = try TagUnion.from(alloc, value),
        };
    }

    pub fn deinit(self: *Self) void {
        self.tag_union.deinit(self.alloc);
    }

    pub fn snbtCompact(self: Self, writer: anytype) NbtError!void {
        return self.tag_union.snbtCompact(writer);
    }

    pub fn snbtMultiline(self: Self, writer: anytype, indent: usize) NbtError!void {
        return self.tag_union.snbtMultiline(writer, indent);
    }

    pub fn writeBinRepr(self: Self, writer: anytype) NbtError!void {
        return self.tag_union.writeBinRepr(writer);
    }
};

/// Union of all tag types
const TagUnion = union(TagType) {
    // Alias for the type of this struct
    const Self = @This();

    End: void,

    Byte: i8,
    Short: i16,
    Int: i32,
    Long: i64,
    Float: f32,
    Double: f64,

    ByteArray: []const i8,
    String: []const u8,
    List: collections.List,
    Compound: collections.Compound,
    IntArray: []const i32,
    LongArray: []const i64,

    /// Creates a `Tag` from a corresponding Zig type.
    pub fn from(alloc: std.mem.Allocator, value: anytype) NbtError!Self {
        const valueType = @TypeOf(value);

        return switch (valueType) {
            void => Self{ .End = void },

            i8 => Self{ .Byte = value },
            i16 => Self{ .Short = value },
            i32 => Self{ .Int = value },
            i64 => Self{ .Long = value },
            f32 => Self{ .Float = value },
            f64 => Self{ .Double = value },

            []const i8, []i8 => Self{ .ByteArray = try alloc.dupe(i8, value) },
            []const u8, []u8 => Self{ .String = try alloc.dupe(u8, value) },
            collections.List => Self{ .List = value },
            collections.Compound => Self{ .Compound = value },
            []const i32, []i32 => Self{ .IntArray = try alloc.dupe(i32, value) },
            []const i64, []i64 => Self{ .LongArray = try alloc.dupe(i64, value) },

            else => @compileError("Type " ++ @typeName(valueType) ++ " can not be converted into an NBT tag"),
        };
    }

    /// Deinitializes the `Tag`, freeing the memory of the contained tags and itself
    pub fn deinit(self: *Self, alloc: std.mem.Allocator) void {
        switch (self.*) {
            .List => |*list| list.deinit(),
            .Compound => |*compound| compound.deinit(),
            .ByteArray => |slice| alloc.free(slice),
            .String => |slice| alloc.free(slice),
            .IntArray => |slice| alloc.free(slice),
            .LongArray => |slice| alloc.free(slice),
            else => {},
        }
    }

    /// Writes the binary representation of the `Tag` into `writer`.
    ///
    /// This method only writes the `Tag`'s contents. The type ID and name of the `Tag`
    /// are written by the `Compound` that surrounds this `Tag`.
    pub fn writeBinRepr(self: Self, writer: anytype) NbtError!void {
        switch (self) {
            .End => {
                _ = try writer.write(&.{0});
            },
            .Byte => |value| {
                _ = try writer.write(&.{@bitCast(value)});
            },
            .Short => |value| {
                var value_buffer: [2]u8 = undefined;
                std.mem.writeInt(i16, &value_buffer, value, .big);
                _ = try writer.write(&value_buffer);
            },
            .Int => |value| {
                var value_buffer: [4]u8 = undefined;
                std.mem.writeInt(i32, &value_buffer, value, .big);
                _ = try writer.write(&value_buffer);
            },
            .Long => |value| {
                var value_buffer: [8]u8 = undefined;
                std.mem.writeInt(i64, &value_buffer, value, .big);
                _ = try writer.write(&value_buffer);
            },
            .Float => |value| {
                var value_buffer: [4]u8 = undefined;
                std.mem.writeInt(u32, &value_buffer, @bitCast(value), .big);
                _ = try writer.write(&value_buffer);
            },
            .Double => |value| {
                var value_buffer: [8]u8 = undefined;
                std.mem.writeInt(u64, &value_buffer, @bitCast(value), .big);
                _ = try writer.write(&value_buffer);
            },
            .ByteArray => |value| {
                // Write the array length
                const array_len_usize = value.len;
                const array_len_trunc: u32 = @truncate(array_len_usize);
                const array_len: i32 = if (array_len_usize < std.math.maxInt(i32)) @bitCast(array_len_trunc) else return NbtError.ValueOutOfBounds;
                var array_len_buffer: [4]u8 = undefined;
                std.mem.writeInt(i32, &array_len_buffer, array_len, .big);
                _ = try writer.write(&array_len_buffer);

                // Write the contents of the array
                for (value) |item| {
                    _ = try writer.write(&.{@bitCast(item)});
                }
            },
            .String => |value| {
                // Write the array length
                const array_len_usize = value.len;
                const array_len: u16 = if (array_len_usize < std.math.maxInt(u16)) @truncate(array_len_usize) else return NbtError.ValueOutOfBounds;
                var array_len_buffer: [2]u8 = undefined;
                std.mem.writeInt(u16, &array_len_buffer, array_len, .big);
                _ = try writer.write(&array_len_buffer);

                // Write the contents of the string
                _ = try writer.write(value);
            },
            .List => |value| {
                // Write the list tags' type ID
                _ = try writer.write(&.{@intFromEnum(value.tags_type)});

                // Write the list length
                const list_len_usize = value.tags.items.len;
                const list_len_trunc: u32 = @truncate(list_len_usize);
                const list_len: i32 = if (list_len_usize < std.math.maxInt(i32)) @bitCast(list_len_trunc) else return NbtError.ValueOutOfBounds;
                var list_len_buffer: [4]u8 = undefined;
                std.mem.writeInt(i32, &list_len_buffer, list_len, .big);
                _ = try writer.write(&list_len_buffer);

                // Write the contents of the list
                for (value.tags.items) |tag| {
                    try tag.writeBinRepr(writer);
                }
            },
            .Compound => |value| {
                var tags_iter = value.tags.iterator();
                while (tags_iter.next()) |entry| {
                    // Write the tag's type ID
                    const tag = entry.value_ptr.*;
                    const tag_type: TagType = tag.tag_union;
                    _ = try writer.write(&.{@intFromEnum(tag_type)});

                    // Write the tag's name length
                    const tag_name = entry.key_ptr.*;
                    const tag_name_len_usize = tag_name.len;
                    const tag_name_len: u16 = if (tag_name_len_usize < std.math.maxInt(u16)) @truncate(tag_name_len_usize) else return NbtError.NameTooLong;
                    var tag_name_len_buffer: [2]u8 = undefined;
                    std.mem.writeInt(u16, &tag_name_len_buffer, tag_name_len, .big);
                    _ = try writer.write(&tag_name_len_buffer);

                    // Write the tag's name
                    _ = try writer.write(tag_name);

                    // Write the tag's contents
                    _ = try tag.writeBinRepr(writer);
                }

                // Write the End tag
                _ = try writer.write(&.{0});
            },
            .IntArray => |value| {
                // Write the array length
                const array_len_usize = value.len;
                const array_len_trunc: u32 = @truncate(array_len_usize);
                const array_len: i32 = if (array_len_usize < std.math.maxInt(i32)) @bitCast(array_len_trunc) else return NbtError.ValueOutOfBounds;
                var array_len_buffer: [4]u8 = undefined;
                std.mem.writeInt(i32, &array_len_buffer, array_len, .big);
                _ = try writer.write(&array_len_buffer);

                // Write the contents of the array
                for (value) |item| {
                    var value_buffer: [4]u8 = undefined;
                    std.mem.writeInt(i32, &value_buffer, item, .big);
                    _ = try writer.write(&value_buffer);
                }
            },
            .LongArray => |value| {
                // Write the array length
                const array_len_usize = value.len;
                const array_len_trunc: u32 = @truncate(array_len_usize);
                const array_len: i32 = if (array_len_usize < std.math.maxInt(i32)) @bitCast(array_len_trunc) else return NbtError.ValueOutOfBounds;
                var array_len_buffer: [4]u8 = undefined;
                std.mem.writeInt(i32, &array_len_buffer, array_len, .big);
                _ = try writer.write(&array_len_buffer);

                // Write the contents of the array
                for (value) |item| {
                    var value_buffer: [8]u8 = undefined;
                    std.mem.writeInt(i64, &value_buffer, item, .big);
                    _ = try writer.write(&value_buffer);
                }
            },
        }
    }

    pub fn snbtCompact(self: Self, writer: anytype) NbtError!void {
        switch (self) {
            .End => {},
            .Byte => |value| _ = try writer.print("{d}b", .{value}),
            .Short => |value| _ = try writer.print("{d}s", .{value}),
            .Int => |value| _ = try writer.print("{d}", .{value}),
            .Long => |value| _ = try writer.print("{d}l", .{value}),
            .Double => |value| _ = try writer.print("{d}d", .{value}),
            .Float => |value| _ = try writer.print("{d}f", .{value}),
            .String => |value| _ = try writer.print("\"{s}\"", .{value}),
            .Compound => |value| try value.snbtCompact(writer),
            .List => |value| try value.snbt(writer),
            .ByteArray => |value| try writeArrayCompact(i8, value, writer, 'B', 'b'),
            .IntArray => |value| try writeArrayCompact(i32, value, writer, 'I', null),
            .LongArray => |value| try writeArrayCompact(i64, value, writer, 'L', 'l'), 
        }
    }

    pub fn snbtMultiline(self: Self, writer: anytype, indent: usize) NbtError!void {
        switch (self) {
            .End => {},
            .Byte => |value| _ = try writer.print("{d}b", .{value}),
            .Short => |value| _ = try writer.print("{d}s", .{value}),
            .Int => |value| _ = try writer.print("{d}", .{value}),
            .Long => |value| _ = try writer.print("{d}l", .{value}),
            .Double => |value| _ = try writer.print("{d}d", .{value}),
            .Float => |value| _ = try writer.print("{d}f", .{value}),
            .String => |value| _ = try writer.print("\"{s}\"", .{value}),
            .Compound => |value| try value.snbtMultiline(writer, indent),
            .List => |value| try value.snbtMultiline(writer, indent),
            .ByteArray => |value| try writeArrayMultiline(i8, value, writer, indent, 'B', 'b'),
            .IntArray => |value| try writeArrayMultiline(i32, value, writer, indent, 'I', null),
            .LongArray => |value| try writeArrayMultiline(i64, value, writer, indent, 'L', 'l'),
        }
    }
};
