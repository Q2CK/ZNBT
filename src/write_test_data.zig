const std = @import("std");

const znbt_io = @import("io.zig");

const examples = @import("examples.zig");

const collections = @import("collections.zig");
const Compound = collections.Compound;

const NbtError = @import("errors.zig").NbtError;

pub fn main() !void {
    try writeTestData();
}

fn writeTestData() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_instance = gpa.allocator();
    var arena_alloc = std.heap.ArenaAllocator.init(gpa_instance);
    const alloc = arena_alloc.allocator();
    defer arena_alloc.deinit();

    try writeCompoundNbt("byte", try examples.byteCompound(alloc));
    try writeCompoundNbt("short", try examples.shortCompound(alloc));
    try writeCompoundNbt("int", try examples.intCompound(alloc));
    try writeCompoundNbt("long", try examples.longCompound(alloc));
    try writeCompoundNbt("float", try examples.floatCompound(alloc));
    try writeCompoundNbt("double", try examples.doubleCompound(alloc));
    try writeCompoundNbt("list_bytes", try examples.listBytesCompound(alloc));
    try writeCompoundNbt("list_shorts", try examples.listShortsCompound(alloc));
    try writeCompoundNbt("list_ints", try examples.listIntsCompound(alloc));
    try writeCompoundNbt("list_longs", try examples.listLongsCompound(alloc));
    try writeCompoundNbt("list_floats", try examples.listFloatsCompound(alloc));
    try writeCompoundNbt("list_doubles", try examples.listDoublesCompound(alloc));
    try writeCompoundNbt("int_array", try examples.intArrayCompound(alloc));
    try writeCompoundNbt("long_array", try examples.longArrayCompound(alloc));
    try writeCompoundNbt("list_compounds", try examples.listCompoundsCompound(alloc));
    try writeCompoundNbt("list_lists", try examples.listListsCompound(alloc));
    try writeCompoundNbt("byte_array", try examples.byteArrayCompound(alloc));
    try writeCompoundNbt("list_complex_compounds", try examples.listComplexCompoundsCompound(alloc));
}

fn writeCompoundNbt(name: []const u8, compound: Compound) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_instance = gpa.allocator();
    var arena_alloc = std.heap.ArenaAllocator.init(gpa_instance);
    const alloc = arena_alloc.allocator();
    defer arena_alloc.deinit();

    try std.fs.cwd().makePath("test_data/snbt");
    try std.fs.cwd().makePath("test_data/uncompressed");
    try std.fs.cwd().makePath("test_data/gzip");

    const snbt_file_path = try std.fmt.allocPrint(alloc, "test_data/snbt/{s}.snbt", .{name});
    const fileSnbt = try std.fs.cwd().createFile(snbt_file_path, .{});
    
    const uncompressed_file_path = try std.fmt.allocPrint(alloc, "test_data/uncompressed/{s}_uncompressed.nbt", .{name});
    const fileUncompressed = try std.fs.cwd().createFile(uncompressed_file_path, .{});
    
    const gzip_file_path = try std.fmt.allocPrint(alloc, "test_data/gzip/{s}.nbt", .{name});
    const fileGzip = try std.fs.cwd().createFile(gzip_file_path, .{});

    try znbt_io.writeSNBT(compound, fileSnbt.writer(), .MultiLine);
    try znbt_io.writeBin(alloc, "znbt", compound, fileUncompressed.writer(), .None);
    try znbt_io.writeBin(alloc, "znbt", compound, fileGzip.writer(), .Gzip);
}
