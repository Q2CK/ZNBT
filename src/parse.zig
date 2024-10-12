const std = @import("std");

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
        std.debug.print("->offset: {d}\n", .{offset});
        std.debug.print("->tag_name_length: {d}\n", .{tag_name_length});
        const tag_name = bin_slice[offset..tag_name_end];
        offset += tag_name_length;

        std.debug.print("\n", .{});
        std.debug.print("parseCompound\n", .{});
        std.debug.print("offset: {d}\n", .{offset});
        std.debug.print("tag_type: {?}\n", .{tag_type});
        std.debug.print("tag_name_length: {d}\n", .{tag_name_length});
        std.debug.print("tag_name: {s}\n", .{tag_name});

        switch (tag_type) {
            TagType.Byte => {
                const value = std.mem.readInt(i8, &bin_slice[offset], .big);
                tag = Tag.from(value);
                offset += 1;
            },
            TagType.Short => {
                const value = std.mem.readVarInt(i16, bin_slice[offset..offset+2], .big);
                tag = Tag.from(value);
                offset += 2;
                std.debug.print("value: {d}\n", .{value});
            },
            TagType.Compound => {
                const parse_result = try parseCompound(alloc, bin_slice[offset..]);
                tag = Tag.from(parse_result.parsed_value);
                offset += parse_result.size_bytes;
            },
            TagType.List => {
                const parse_result = try parseList(alloc, bin_slice[offset..]);
                tag = Tag.from(parse_result.parsed_value);
                offset += parse_result.size_bytes;
            },
            TagType.ByteArray => {
                const parse_result = try parseByteArray(alloc, bin_slice[offset..]);
                tag = Tag.from(parse_result.parsed_value);
                offset += parse_result.size_bytes;
            },
            else => {
                return NbtError.NotImplemented;
                // std.debug.panic("Not supported tag type {?}", .{tag_type});
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
    // var tag: Tag = undefined;
    const tag_type_u8 = std.mem.readInt(u8, &bin_slice[0], .big);
    const tag_type: TagType = @enumFromInt(tag_type_u8);
    var offset: u32 = 1;
    const list_size = std.mem.readVarInt(u32, bin_slice[offset..offset+4], .big);
    offset += 4;

    var result = List.init(alloc, tag_type);

    std.debug.print("\n", .{});
    std.debug.print("parseList\n", .{});
    std.debug.print("tag_type: {?}\n", .{tag_type});
    std.debug.print("list_size: {d}\n", .{list_size});

    switch (tag_type) {
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
        TagType.Compound => {
            for (0..list_size) |_| {
                const parse_result = try parseCompound(alloc, bin_slice[offset..]);
                try result.append(parse_result.parsed_value);
                offset += parse_result.size_bytes;
            }
        },
        // TagType.List => {
        //     const parse_result = try parseList(alloc, bin_slice[offset..]);
        //     tag = Tag.from(parse_result.parsed_value);
        //     offset += parse_result.size_bytes;
        // },
        else => {
            return NbtError.NotImplemented;
            // std.debug.panic("Not supported tag type {?}", .{tag_type});
        },
    }

    return .{
        .size_bytes = offset, // todo
        .parsed_value = result,
    };
}

pub fn parseByteArray(alloc: std.mem.Allocator, bin_slice: []const u8) NbtError!ParseResult([]const i8) {
    const size = std.mem.readVarInt(u32, bin_slice[0..4], .big);
    const value_u8 = try alloc.dupe(u8, bin_slice[4..size+4]);
    // const value_u8 = bin_slice[4..size+4];
    const value_i8: []const i8 = @ptrCast(value_u8);
    
    std.debug.print("parseByteArray size: {d}\n", .{size});
    std.debug.print("parseByteArray value: {any}\n", .{value_i8});

    return .{
        .size_bytes = size + 4,
        .parsed_value = value_i8,
    };
}
