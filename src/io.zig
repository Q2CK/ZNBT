const std = @import("std");

const collections = @import("collections.zig");
const errors = @import("errors.zig");
const NbtError = errors.NbtError;

const tag_import = @import("tag.zig");
const Tag = tag_import.Tag;
const TagType = tag_import.TagType;

const constants_import = @import("constants.zig");
const ENABLE_DEBUG_PRINTS = constants_import.ENABLE_DEBUG_PRINTS;
const INDENT_SIZE_IN_SPACES = constants_import.INDENT_SIZE_IN_SPACES;

const parser = @import("parse.zig");

/// Compression method for the final binary NBT data
pub const Compression = enum { 
    None, Gzip, Zlib 
};

/// Text formatting method for SNBT data 
pub const SNBTFormat = enum {
    /// No unnecessary characters
    Compact,
    /// Readable single-line formatting
    SingleLine,
    /// Readable multi-line formatting
    MultiLine
};

/// Writes binary NBT data into the `writer`, using the given `name` and `compound` as the root tag.
///
/// Available compression methods: `.None`, `.Gzip`, `.Zlib`
pub fn writeBin(alloc: std.mem.Allocator, name: []const u8, compound: collections.Compound, writer: anytype, compression: Compression) NbtError!void {
    // Reserve memory for the temporary uncompressed data
    var raw = std.ArrayList(u8).init(alloc);
    defer raw.deinit();
    const raw_writer = raw.writer();

    // Write the root compound's type ID
    const tag_type = TagType.Compound;
    _ = try raw_writer.write(&.{@intFromEnum(tag_type)});

    // Write the tag's name length
    const name_len_usize = name.len;
    const name_len: u16 = if (name_len_usize < std.math.maxInt(u16)) @truncate(name_len_usize) else return errors.NbtError.NameTooLong;
    var name_len_buffer: [2]u8 = undefined;
    std.mem.writeInt(u16, &name_len_buffer, name_len, .big);
    _ = try raw_writer.write(&name_len_buffer);

    // Write the tag's name
    _ = try raw_writer.write(name);

    // Write the tag's contents
    const compound_tag = try Tag.from(alloc, compound);
    try compound_tag.writeBinRepr(raw_writer);

    // Create a reader from the uncompressed data
    var raw_stream = std.io.fixedBufferStream(raw.items);
    const raw_reader = raw_stream.reader();

    // Write the data into the writer with the selected compression method
    switch (compression) {
        .None => _ = try writer.write(raw.items),
        .Gzip => try std.compress.gzip.compress(raw_reader, writer, .{ .level = .best }),
        .Zlib => try std.compress.zlib.compress(raw_reader, writer, .{ .level = .best }),
    }
}

/// Reads binary NBT data from the file at `path` and returns the root compound as a `collections.Compound`.
pub fn readBin(alloc: std.mem.Allocator, path: []const u8) !collections.Compound {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var array_list = std.ArrayList(u8).init(std.testing.allocator);
    defer array_list.deinit();

    try std.compress.gzip.decompress(file.reader(), array_list.writer());

    const bin_slice = try array_list.toOwnedSlice();
    defer alloc.free(bin_slice);

    const tag_type = std.mem.readInt(u8, &bin_slice[0], .big);
    const tag_name_length = std.mem.readInt(u16, bin_slice[1..3], .big);
    const tag_name_end = tag_name_length + 3;
    const tag_name = bin_slice[3..tag_name_end];

    if (ENABLE_DEBUG_PRINTS) {
        std.debug.print("\n", .{});
        std.debug.print("tag_type: {d}\n", .{tag_type});
        std.debug.print("tag_name_length: {d}\n", .{tag_name_length});
        std.debug.print("typeof tag_name_length: {?}\n", .{@TypeOf(tag_name_length)});
        std.debug.print("tag_name: {s}\n", .{tag_name});
    }

    const parse_result = try parser.parseCompound(alloc, bin_slice[tag_name_end..]);

    return parse_result.parsed_value;
}

/// Writes NBT data in SNBT format into the `writer`, using the given `compound` as the root tag.
pub fn writeSNBT(compound: collections.Compound, writer: anytype, format: SNBTFormat) NbtError!void {
    switch (format) {
        .Compact => try compound.snbtCompact(writer),
        .MultiLine => try compound.snbtMultiline(writer, 0),
        else => std.debug.panic("SNBT Format {s} is not implemented.", .{@tagName(format)}),
    }
}
