const std = @import("std");

const collections = @import("collections.zig");
const errors = @import("errors.zig");

const tag_import = @import("tag.zig");
const Tag = tag_import.Tag;
const TagType = tag_import.TagType;

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
pub fn writeBin(alloc: std.mem.Allocator, name: []const u8, compound: collections.Compound, writer: anytype, compression: Compression) !void {
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
    const compound_tag = Tag.from(compound);
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
/// TODO: Implement this method and add tests
pub fn readBin(alloc: std.mem.Allocator, path: []const u8) !collections.Compound {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const reader = file.reader();
    const content = try reader.readAllAlloc(alloc, std.math.maxInt(usize));
    defer alloc.free(content);

    return collections.Compound.init(alloc);
}

/// Writes NBT data in SNBT format into the `writer`, using the given `compound` as the root tag.
pub fn writeSNBT(compound: collections.Compound, writer: anytype, format: SNBTFormat) !void {
    // TODO: Implement different text formatting methods
    _ = format;

    try compound.snbt(writer);
}
