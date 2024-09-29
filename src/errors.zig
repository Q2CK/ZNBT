const std = @import("std");

pub const NbtError = error {
    ListTypeMismatch,
    TagNotFound,
    ValueOutOfBounds,
    NameTooLong
} || std.mem.Allocator.Error;