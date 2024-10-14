const std = @import("std");
const Allocator = std.mem.Allocator;

const NbtError = @import("errors.zig").NbtError;

const collections = @import("collections.zig");
const Compound = collections.Compound;
const List = collections.List;

pub fn byteCompound(alloc: Allocator) NbtError!Compound {
    var result = Compound.init(alloc);
    try result.putByte("byte", 1);
    return result;
}

pub fn shortCompound(alloc: Allocator) NbtError!Compound {
    var result = Compound.init(alloc);
    try result.putShort("short", 256);
    return result;
}

pub fn intCompound(alloc: Allocator) NbtError!Compound {
    var result = Compound.init(alloc);
    try result.putInt("int", 65536);
    return result;
}

pub fn longCompound(alloc: Allocator) NbtError!Compound {
    var result = Compound.init(alloc);
    try result.putLong("long", 4294967296);
    return result;
}

pub fn floatCompound(alloc: Allocator) NbtError!Compound {
    var result = Compound.init(alloc);
    try result.putFloat("float", 12.34);
    return result;
}

pub fn doubleCompound(alloc: Allocator) NbtError!Compound {
    var result = Compound.init(alloc);
    try result.putDouble("double", 12.34);
    return result;
}

pub fn listBytesCompound(alloc: Allocator) NbtError!Compound {
    var result = Compound.init(alloc);
    var list = List.init(alloc, .Byte);
    try list.append(@as(i8, 1));
    try list.append(@as(i8, 2));
    try list.append(@as(i8, 3));
    try result.put("list", list);
    return result;
}

pub fn listShortsCompound(alloc: Allocator) NbtError!Compound {
    var result = Compound.init(alloc);
    var list = List.init(alloc, .Short);
    try list.append(@as(i16, 1));
    try list.append(@as(i16, 2));
    try list.append(@as(i16, 3));
    try result.put("list", list);
    return result;
}

pub fn listIntsCompound(alloc: Allocator) NbtError!Compound {
    var result = Compound.init(alloc);
    var list = List.init(alloc, .Int);
    try list.append(@as(i32, 1));
    try list.append(@as(i32, 2));
    try list.append(@as(i32, 3));
    try result.put("list", list);
    return result;
}

pub fn listLongsCompound(alloc: Allocator) NbtError!Compound {
    var result = Compound.init(alloc);
    var list = List.init(alloc, .Long);
    try list.append(@as(i64, 1));
    try list.append(@as(i64, 2));
    try list.append(@as(i64, 3));
    try result.put("list", list);
    return result;
}

pub fn listFloatsCompound(alloc: Allocator) NbtError!Compound {
    var result = Compound.init(alloc);
    var list = List.init(alloc, .Float);
    try list.append(@as(f32, 12.34));
    try list.append(@as(f32, 23.45));
    try list.append(@as(f32, 34.56));
    try result.put("list", list);
    return result;
}

pub fn listDoublesCompound(alloc: Allocator) NbtError!Compound {
    var result = Compound.init(alloc);
    var list = List.init(alloc, .Double);
    try list.append(@as(f64, 12.34));
    try list.append(@as(f64, 23.45));
    try list.append(@as(f64, 34.56));
    try result.put("list", list);
    return result;
}

pub fn listCompoundsCompound(alloc: Allocator) NbtError!Compound {
    var result = Compound.init(alloc);
    var list = List.init(alloc, .Compound);
    var nested_compound1 = Compound.init(alloc);
    try nested_compound1.putByte("byte", 1);
    var nested_compound2 = Compound.init(alloc);
    try nested_compound2.putByte("byte", 2);
    try list.append(nested_compound1);
    try list.append(nested_compound2);
    try result.put("list", list);
    return result;
}

pub fn listComplexCompoundsCompound(alloc: Allocator) NbtError!Compound {
    var result = Compound.init(alloc);

    var list = List.init(alloc, .Compound);

    var c1 = Compound.init(alloc);
    var c2 = Compound.init(alloc);
    var c3 = Compound.init(alloc);

    try c1.put("number 1", @as(i16, 123));
    try c1.put("number 2", @as(i16, 456));
    try c1.put("number 3", @as(i16, 789));

    const str1: []const u8 = "str1";
    const str2: []const u8 = "str2";

    try c2.put("string 1", str1);
    try c2.put("string 2", str2);

    try c3.put("array", @as([]const i64, &[_]i64{ 1 }));
    try c3.put("double", @as(f64, 12.34));

    try list.append(c1);
    try list.append(c2);
    try list.append(c3);

    try result.put("list", list);

    return result;
}

pub fn byteArrayCompound(alloc: Allocator) NbtError!Compound {
    var result = Compound.init(alloc);
    try result.putByteArray("byteArray", &[_]i8{ 1, 2, 3 });
    return result;
}

pub fn intArrayCompound(alloc: Allocator) NbtError!Compound {
    var result = Compound.init(alloc);
    try result.putIntArray("intArray", &[_]i32{ 1, 2, 3 });
    return result;
}

pub fn longArrayCompound(alloc: Allocator) NbtError!Compound {
    var result = Compound.init(alloc);
    try result.putLongArray("longArray", &[_]i64{ 1, 2, 3 });
    return result;
}
