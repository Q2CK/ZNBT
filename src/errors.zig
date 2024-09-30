const std = @import("std");

pub const NbtError = error {
    ListTypeMismatch,
    TagNotFound,
    ValueOutOfBounds,
    NameTooLong
} || std.mem.Allocator.Error || FileError;

// TODO: Use some error namespace from std that I could not find instead of this
pub const FileError = error {
    AccessDenied,
    Unexpected,
    SystemResources,
    FileTooBig,
    NoSpaceLeft,
    DeviceBusy,
    WouldBlock,
    DiskQuota,
    InputOutput,
    InvalidArgument,
    BrokenPipe,
    OperationAborted,
    NotOpenForWriting,
    LockViolation,
    ConnectionResetByPeer
};