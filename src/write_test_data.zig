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

    var list_bytes_compound = try examples.listBytesCompound(alloc);
    defer list_bytes_compound.deinit();
    try writeCompoundNbt("list_bytes", list_bytes_compound);

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
