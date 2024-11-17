# ZNBT - Zig NBT Library

ZNBT is a Zig library for working with the Named Binary Tag (NBT) format, commonly used in Minecraft-related applications.

## Zig Version

Tested on Zig 0.13.0

## Features

- Read and write NBT data
- Support for all NBT tag types
- Compression options: None, Gzip, and Zlib
- Easy-to-use API for creating and manipulating NBT structures

## Installation

To use ZNBT in your Zig project, add it as a dependency in your `build.zig.zon` file

## Usage

```zig
const std = @import("std");
const znbt = @import("znbt.zig");
const Compound = znbt.collections.Compound;
const List = znbt.collections.List;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var root = Compound.init(alloc);

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

    try c3.put("array", @as([]const i64, &[_]i64{1}));
    try c3.put("double", @as(f64, 12.34));

    try list.append(c1);
    try list.append(c2);
    try list.append(c3);

    try root.put("list", list);

    const writer = std.io.getStdOut().writer();

    try znbt.io.writeSNBT(root, writer, .MultiLine);

    // Prints out:
    // {
    //     list: [
    //         {
    //             number 2: 456s,
    //             number 1: 123s,
    //             number 3: 789s
    //         },
    //         {
    //             string 1: "str1",
    //             string 2: "str2"
    //         },
    //         {
    //             array: [
    //                 L;
    //                 1l
    //             ],
    //             double: 12.34d
    //         }
    //     ]
    // }
}
```

## Test

```bash
zig run src/write_test_data.zig
zig test src/io_test.zig
zig test src/snbt_test.zig
```
