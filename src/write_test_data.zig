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
    const alloc = gpa.allocator();

    var byte_compound = try examples.byteCompound(alloc);
    defer byte_compound.deinit();
    try writeCompoundNbt("byte", byte_compound);

    var short_compound = try examples.shortCompound(alloc);
    defer short_compound.deinit();
    try writeCompoundNbt("short", short_compound);

    var int_compound = try examples.intCompound(alloc);
    defer int_compound.deinit();
    try writeCompoundNbt("int", int_compound);

    var long_compound = try examples.longCompound(alloc);
    defer long_compound.deinit();
    try writeCompoundNbt("long", long_compound);

    var float_compound = try examples.floatCompound(alloc);
    defer float_compound.deinit();
    try writeCompoundNbt("float", float_compound);

    var double_compound = try examples.doubleCompound(alloc);
    defer double_compound.deinit();
    try writeCompoundNbt("double", double_compound);

    var list_bytes_compound = try examples.listBytesCompound(alloc);
    defer list_bytes_compound.deinit();
    try writeCompoundNbt("list_bytes", list_bytes_compound);

    var list_shorts_compound = try examples.listShortsCompound(alloc);
    defer list_shorts_compound.deinit();
    try writeCompoundNbt("list_shorts", list_shorts_compound);

    var list_ints_compound = try examples.listIntsCompound(alloc);
    defer list_ints_compound.deinit();
    try writeCompoundNbt("list_ints", list_ints_compound);

    var list_longs_compound = try examples.listLongsCompound(alloc);
    defer list_longs_compound.deinit();
    try writeCompoundNbt("list_longs", list_longs_compound);

    var list_floats_compound = try examples.listFloatsCompound(alloc);
    defer list_floats_compound.deinit();
    try writeCompoundNbt("list_floats", list_floats_compound);

    var list_doubles_compound = try examples.listDoublesCompound(alloc);
    defer list_doubles_compound.deinit();
    try writeCompoundNbt("list_doubles", list_doubles_compound);

    var int_array_compound = try examples.intArrayCompound(alloc);
    defer int_array_compound.deinit();
    try writeCompoundNbt("int_array", int_array_compound);

    var long_array_compound = try examples.longArrayCompound(alloc);
    defer long_array_compound.deinit();
    try writeCompoundNbt("long_array", long_array_compound);

    var list_compounds_compound = try examples.listCompoundsCompound(alloc);
    defer list_compounds_compound.deinit();
    try writeCompoundNbt("list_compounds", list_compounds_compound);

    var list_complex_compounds_compound = try examples.listComplexCompoundsCompound(alloc);
    defer list_complex_compounds_compound.deinit();
    try writeCompoundNbt("list_complex_compounds", list_complex_compounds_compound);

    var byte_array_compound = try examples.byteArrayCompound(alloc);
    defer byte_array_compound.deinit();
    try writeCompoundNbt("byte_array", byte_array_compound);
}

fn writeCompoundNbt(name: []const u8, compound: Compound) !void {
    const alloc = std.heap.page_allocator;
    const snbt_file_path = try std.fmt.allocPrint(alloc, "test_data/snbt/{s}.snbt", .{name});
    defer alloc.free(snbt_file_path);
    const fileSnbt = try std.fs.cwd().createFile(snbt_file_path, .{});
    defer fileSnbt.close();
    const uncompressed_file_path = try std.fmt.allocPrint(alloc, "test_data/uncompressed/{s}_uncompressed.nbt", .{name});
    defer alloc.free(uncompressed_file_path);
    const fileUncompressed = try std.fs.cwd().createFile(uncompressed_file_path, .{});
    defer fileUncompressed.close();
    const gzip_file_path = try std.fmt.allocPrint(alloc, "test_data/gzip/{s}.nbt", .{name});
    defer alloc.free(gzip_file_path);
    const fileGzip = try std.fs.cwd().createFile(gzip_file_path, .{});
    defer fileGzip.close();
    try znbt_io.writeSNBT(compound, fileSnbt.writer(), .MultiLine);
    try znbt_io.writeBin(alloc, "znbt", compound, fileUncompressed.writer(), .None);
    try znbt_io.writeBin(alloc, "znbt", compound, fileGzip.writer(), .Gzip);
}
