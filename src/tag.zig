const std = @import("std");
const errors = @import("errors.zig");

const collections = @import("collections.zig");

pub const TagType = enum(u8) {
    End = 0,

    Byte   = 1,
    Short  = 2,
    Int    = 3,
    Long   = 4,
    Float  = 5,
    Double = 6,

    ByteArray = 7,
    String    = 8,
    List      = 9,
    Compound  = 10,
    IntArray  = 11,
    LongArray = 12,
};

/// Union of all tag types
pub const Tag = union(TagType) {
    // Alias for the type of this struct
    const Self = @This();

    End:       void,

    Byte:      i8,
    Short:     i16,
    Int:       i32,
    Long:      i64,
    Float:     f32,
    Double:    f64,

    ByteArray: []const i8,
    String:    []const u8,
    List:      collections.List,
    Compound:  collections.Compound,
    IntArray:  []const i32,
    LongArray: []const i64,

    /// Creates a `Tag` from a corresponding Zig type.
    pub fn from(value: anytype) Self {
        const valueType = @TypeOf(value);

        return switch (valueType) {
            void => Self { .End = void },

            i8  => Self { .Byte   = value },
            i16 => Self { .Short  = value },
            i32 => Self { .Int    = value },
            i64 => Self { .Long   = value },
            f32 => Self { .Float  = value },
            f64 => Self { .Double = value },

            []const i8, []i8     => Self { .ByteArray = value },
            []const u8, []u8     => Self { .String    = value },
            collections.List     => Self { .List      = value },
            collections.Compound => Self { .Compound  = value },
            []const i32, []i32   => Self { .IntArray  = value },
            []const i64, []i64   => Self { .LongArray = value },

            else => @compileError("Type " ++ @typeName(valueType) ++ " can not be converted into an NBT tag")
        };
    }

    /// Deinitializes the `Tag`, freeing the memory of the contained tags and itself
    pub fn deinit(self: *Self) void {
        switch (self.*) {
            .List      => |*list|     list.deinit(),
            .Compound  => |*compound| compound.deinit(),
            else => {}
        }
    }

    /// Writes the binary representation of the `Tag` into `writer`.
    /// 
    /// This method only writes the `Tag`'s contents. The type ID and name of the `Tag`
    /// are written by the `Compound` that surrounds this `Tag`.
    pub fn writeBinRepr(self: Self, writer: anytype) !void {
        switch(self) {
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
                const array_len: i32 = if(array_len_usize < std.math.maxInt(i32)) @bitCast(array_len_trunc) else return errors.NbtError.ValueOutOfBounds;
                var array_len_buffer: [4]u8 = undefined;
                std.mem.writeInt(i32, &array_len_buffer, array_len, .big);
                _ = try writer.write(&array_len_buffer);

                // Write the contents of the array
                for(value) |item| {
                    _ = try writer.write(&.{@bitCast(item)});
                }
            },
            .String => |value| {
                // Write the array length
                const array_len_usize = value.len;
                const array_len: u16 = if(array_len_usize < std.math.maxInt(u16)) @truncate(array_len_usize) else return errors.NbtError.ValueOutOfBounds;
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
                const list_len: i32 = if(list_len_usize < std.math.maxInt(i32)) @bitCast(list_len_trunc) else return errors.NbtError.ValueOutOfBounds;
                var list_len_buffer: [4]u8 = undefined;
                std.mem.writeInt(i32, &list_len_buffer, list_len, .big);
                _ = try writer.write(&list_len_buffer);

                // Write the contents of the list
                for(value.tags.items) |tag| {
                    try tag.writeBinRepr(writer);
                }
            },
            .Compound => |value| {
                var tags_iter = value.tags.iterator();
                while(tags_iter.next()) |entry| {
                    // Write the tag's type ID
                    const tag = entry.value_ptr.*;
                    const tag_type: TagType = tag;
                    _ = try writer.write(&.{@intFromEnum(tag_type)});

                    // Write the tag's name length                
                    const tag_name = entry.key_ptr.*;
                    const tag_name_len_usize = tag_name.len;
                    const tag_name_len: u16 = if(tag_name_len_usize < std.math.maxInt(u16)) @truncate(tag_name_len_usize) else return errors.NbtError.NameTooLong;
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
                const array_len: i32 = if(array_len_usize < std.math.maxInt(i32)) @bitCast(array_len_trunc) else return errors.NbtError.ValueOutOfBounds;
                var array_len_buffer: [4]u8 = undefined;
                std.mem.writeInt(i32, &array_len_buffer, array_len, .big);
                _ = try writer.write(&array_len_buffer);

                // Write the contents of the array
                for(value) |item| {
                    var value_buffer: [4]u8 = undefined;
                    std.mem.writeInt(i32, &value_buffer, item, .big);
                    _ = try writer.write(&value_buffer);
                }
            },
            .LongArray => |value| {
                // Write the array length
                const array_len_usize = value.len;
                const array_len_trunc: u32 = @truncate(array_len_usize);
                const array_len: i32 = if(array_len_usize < std.math.maxInt(i32)) @bitCast(array_len_trunc) else return errors.NbtError.ValueOutOfBounds;
                var array_len_buffer: [4]u8 = undefined;
                std.mem.writeInt(i32, &array_len_buffer, array_len, .big);
                _ = try writer.write(&array_len_buffer);

                // Write the contents of the array
                for(value) |item| {
                    var value_buffer: [8]u8 = undefined;
                    std.mem.writeInt(i64, &value_buffer, item, .big);
                    _ = try writer.write(&value_buffer);
                }
            },
        }
    }
};
