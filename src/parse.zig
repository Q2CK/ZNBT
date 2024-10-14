const std = @import("std");
const builtin = @import("builtin");

const constants_import = @import("constants.zig");
const ENABLE_DEBUG_PRINTS = constants_import.ENABLE_DEBUG_PRINTS;

const collections = @import("collections.zig");
const Compound = collections.Compound;
const List = collections.List;

const tag_import = @import("tag.zig");
const Tag = tag_import.Tag;
const TagType = tag_import.TagType;

const errors = @import("errors.zig");
const NbtError = errors.NbtError;

fn ParseResult(comptime T: type) type {
    return struct {
        size_bytes: u32,
        parsed_value: T,
    };
}

pub fn parseCompound(alloc: std.mem.Allocator, bin_slice: []const u8) NbtError!ParseResult(Compound) {
    var result = Compound.init(alloc);

    var tag: Tag = undefined;
    var tag_type_u8 = std.mem.readInt(u8, &bin_slice[0], .big);
    var tag_type: TagType = @enumFromInt(tag_type_u8);
    var offset: u32 = 1;

    while (tag_type != TagType.End) {
        // todo extract parse name function
        const tag_name_length = std.mem.readVarInt(u16, bin_slice[offset..offset+2], .big);
        offset += 2;
        const tag_name_end = offset + tag_name_length;
        const tag_name = bin_slice[offset..tag_name_end];
        offset += tag_name_length;

        if (ENABLE_DEBUG_PRINTS) {
            std.debug.print("\n", .{});
            std.debug.print("parseCompound\n", .{});
            std.debug.print("offset: {d}\n", .{offset});
            std.debug.print("tag_type: {?}\n", .{tag_type});
            std.debug.print("tag_name_length: {d}\n", .{tag_name_length});
            std.debug.print("tag_name: {s}\n", .{tag_name});
        }

        switch (tag_type) {
            TagType.End => unreachable,
            TagType.Byte => {
                const value = std.mem.readInt(i8, &bin_slice[offset], .big);
                tag = try Tag.from(alloc, value);
                offset += 1;
            },
            TagType.Short => {
                const value = std.mem.readVarInt(i16, bin_slice[offset..offset+2], .big);
                tag = try Tag.from(alloc, value);
                offset += 2;
            },
            TagType.Int => {
                const value = std.mem.readVarInt(i32, bin_slice[offset..offset+4], .big);
                tag = try Tag.from(alloc, value);
                offset += 4;
            },
            TagType.Long => {
                const value = std.mem.readVarInt(i64, bin_slice[offset..offset+8], .big);
                tag = try Tag.from(alloc, value);
                offset += 8;
            },
            TagType.Float => {
                const value = std.mem.readVarInt(u32, bin_slice[offset..offset+4], .big);
                const float_ptr: *const f32 = @ptrCast(&value);
                tag = try Tag.from(alloc, float_ptr.*);
                offset += 4;
            },
            TagType.Double => {
                const value = std.mem.readVarInt(u64, bin_slice[offset..offset+8], .big);
                const double_ptr: *const f64 = @ptrCast(&value);
                tag = try Tag.from(alloc, double_ptr.*);
                offset += 8;
            },
            TagType.ByteArray => {
                const parse_result = parseByteArray(bin_slice[offset..]);
                tag = try Tag.from(alloc, parse_result.parsed_value);
                offset += parse_result.size_bytes;
            },
            TagType.String => { 
                const parse_result = parseString(bin_slice[offset..]);
                tag = try Tag.from(alloc, parse_result.parsed_value);
                offset += parse_result.size_bytes;
            },
            TagType.List => {
                const parse_result = try parseList(alloc, bin_slice[offset..]);
                tag = try Tag.from(alloc, parse_result.parsed_value);
                offset += parse_result.size_bytes;
            },
            TagType.Compound => {
                const parse_result = try parseCompound(alloc, bin_slice[offset..]);
                tag = try Tag.from(alloc, parse_result.parsed_value);
                offset += parse_result.size_bytes;
            },
            TagType.IntArray => { 
                const parse_result = try parseIntArray(alloc, bin_slice[offset..]);
                defer alloc.free(parse_result.parsed_value);
                tag = try Tag.from(alloc, parse_result.parsed_value);
                offset += parse_result.size_bytes;
            },
            TagType.LongArray => { 
                const parse_result = try parseLongArray(alloc, bin_slice[offset..]);
                defer alloc.free(parse_result.parsed_value);
                tag = try Tag.from(alloc, parse_result.parsed_value);
                offset += parse_result.size_bytes;
            },
        }

        try result.putTag(tag_name, tag);

        tag_type_u8 = std.mem.readInt(u8, &bin_slice[offset], .big);
        tag_type = @enumFromInt(tag_type_u8);
    }

    const end_tag_size = 1;
    
    return .{
        .size_bytes = offset + end_tag_size,
        .parsed_value = result,
    };
}

pub fn parseList(alloc: std.mem.Allocator, bin_slice: []const u8) NbtError!ParseResult(List) {
    const tag_type_u8 = std.mem.readInt(u8, &bin_slice[0], .big);
    const tag_type: TagType = @enumFromInt(tag_type_u8);
    var offset: u32 = 1;
    const list_size = std.mem.readVarInt(u32, bin_slice[offset..offset+4], .big);
    offset += 4;

    var result = List.init(alloc, tag_type);

    if (ENABLE_DEBUG_PRINTS) {
        std.debug.print("\n", .{});
        std.debug.print("parseList\n", .{});
        std.debug.print("tag_type: {?}\n", .{tag_type});
        std.debug.print("list_size: {d}\n", .{list_size});
    }

    switch (tag_type) {
        TagType.End => unreachable,
        TagType.Byte => {
            for (0..list_size) |_| {
                const value = std.mem.readInt(i8, &bin_slice[offset], .big);
                try result.append(value);
                offset += 1;
            }
        },
        TagType.Short => {
           for (0..list_size) |_| {
                const value = std.mem.readVarInt(i16, bin_slice[offset..offset+2], .big);
                try result.append(value);
                offset += 2;
            }
        },
        TagType.Int => {
            for (0..list_size) |_| {
                const value = std.mem.readVarInt(i32, bin_slice[offset..offset+4], .big);
                try result.append(value);
                offset += 4;
            }
        },
        TagType.Long => {
            for (0..list_size) |_| {
                const value = std.mem.readVarInt(i64, bin_slice[offset..offset+8], .big);
                try result.append(value);
                offset += 8;
            }
        },
        TagType.Float => {
            for (0..list_size) |_| {
                const value = std.mem.readVarInt(u32, bin_slice[offset..offset+4], .big);
                const float_ptr: *const f32 = @ptrCast(&value);
                try result.append(float_ptr.*);
                offset += 4;
            }
        },
        TagType.Double => {
            for (0..list_size) |_| {
                const value = std.mem.readVarInt(u64, bin_slice[offset..offset+8], .big);
                const double_ptr: *const f64 = @ptrCast(&value);
                try result.append(double_ptr.*);
                offset += 8;
            }
        },
        TagType.ByteArray => {
            for (0..list_size) |_| {
                const parse_result = parseByteArray(bin_slice[offset..]);
                try result.append(parse_result.parsed_value);
                offset += parse_result.size_bytes;
            }
        },
        TagType.String => {
            for (0..list_size) |_| {
                const parse_result = parseString(bin_slice[offset..]);
                try result.append(parse_result.parsed_value);
                offset += parse_result.size_bytes;
            }
        },
        TagType.IntArray => {
            for (0..list_size) |_| {
                const parse_result = try parseIntArray(alloc, bin_slice[offset..]);
                defer alloc.free(parse_result.parsed_value);
                try result.append(parse_result.parsed_value);
                offset += parse_result.size_bytes;
            }
        },
        TagType.LongArray => {
            for (0..list_size) |_| {
                const parse_result = try parseLongArray(alloc, bin_slice[offset..]);
                defer alloc.free(parse_result.parsed_value);
                try result.append(parse_result.parsed_value);
                offset += parse_result.size_bytes;
            }
        },
        TagType.Compound => {
            for (0..list_size) |_| {
                const parse_result = try parseCompound(alloc, bin_slice[offset..]);
                try result.append(parse_result.parsed_value);
                offset += parse_result.size_bytes;
            }
        },
        TagType.List => {
            for (0..list_size) |_| {
                const parse_result = try parseList(alloc, bin_slice[offset..]);
                try result.append(parse_result.parsed_value);
                offset += parse_result.size_bytes;
            }
        },
    }

    return .{
        .size_bytes = offset,
        .parsed_value = result,
    };
}

pub fn parseByteArray(bin_slice: []const u8) ParseResult([]const i8) {
    const size = std.mem.readVarInt(u32, bin_slice[0..4], .big);
    const value_u8 = bin_slice[4..size+4];
    const value_i8: []const i8 = @ptrCast(value_u8);
    
    if (ENABLE_DEBUG_PRINTS) {
        std.debug.print("parseByteArray size: {d}\n", .{size});
        std.debug.print("parseByteArray value: {any}\n", .{value_i8});
    }

    return .{
        .size_bytes = size + 4,
        .parsed_value = value_i8,
    };
}

pub fn parseString(bin_slice: []const u8) ParseResult([]const u8) {
    const size = std.mem.readVarInt(u32, bin_slice[0..4], .big);
    const value = bin_slice[4..size+4];

    return .{
        .size_bytes = size + 4,
        .parsed_value = value,
    };
}

/// Allocates a new array of i32 and interprets the input byte slice as an array of big-endian i32.
/// Copies the values from byte slice to the allocated array.
/// Caller is responsible for freeing the returned array.
pub fn parseIntArray(alloc: std.mem.Allocator, bin_slice: []const u8) NbtError!ParseResult([]const i32) {
    const size = std.mem.readVarInt(u32, bin_slice[0..4], .big);
    const array_slice = bin_slice[4..][0..size*4];
    const result = try alloc.alloc(i32, size);

    for (0..size) |i| {
        const current_slice = array_slice[i*4..][0..4];
        const value = std.mem.readInt(i32, current_slice, .big);
        result[i] = value;
    }

    return .{
        .size_bytes = size * 4 + 4,
        .parsed_value = result,
    };
}

pub fn parseLongArray(alloc: std.mem.Allocator, bin_slice: []const u8) NbtError!ParseResult([]const i64) {
    const size = std.mem.readVarInt(u32, bin_slice[0..4], .big);
    const array_slice = bin_slice[4..][0..size*8];
    const result = try alloc.alloc(i64, size);

    for (0..size) |i| {
        const current_slice = array_slice[i*8..][0..8];
        const value = std.mem.readInt(i64, current_slice, .big);
        result[i] = value;
    }

    return .{
        .size_bytes = size * 8 + 4,
        .parsed_value = result,
    };
}
