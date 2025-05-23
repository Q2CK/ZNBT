const std = @import("std");
const NbtError = @import("errors.zig").NbtError;
const Allocator = std.mem.Allocator;

const tag_import = @import("tag.zig");
const Tag = tag_import.Tag;
const TagType = tag_import.TagType;

const snbt_import = @import("snbt.zig");
const listSnbtCompact = snbt_import.listSnbtCompact;
const listSnbtMultiline = snbt_import.listSnbtMultiline;
const compoundSnbtCompact = snbt_import.compoundSnbtCompact;
const compoundSnbtMultiline = snbt_import.compoundSnbtMultiline;
const writeArrayMultiline = snbt_import.writeArrayMultiline;

const constants_import = @import("constants.zig");
const INDENT_SIZE_IN_SPACES = constants_import.INDENT_SIZE_IN_SPACES;

/// List of unnamed NBT tags of the same type, an NBT-compatible
/// wrapper around `std.ArrayList(Tag)`.
///
/// The tag's payload memory is managed by the List after the tag was succesfully added to the `List`.
///
/// If the tag was NOT succesfully added to the `List`, be it due to tag type mismatch or allocation
/// error, the tag's payload memory will not be managed by the `List` and must be freed accordingly
/// by the caller.
pub const List = struct {
    /// Alias for the type of this struct
    const Self = @This();

    /// Expected type of the contained tags
    tags_type: TagType,

    /// NBT tags contained in this List
    tags: std.ArrayList(Tag),

    alloc: Allocator,

    /// Initializes the List and sets the expected type of the contained tags.
    pub fn init(alloc: Allocator, tags_type: TagType) Self {
        return Self{
            .tags_type = tags_type,
            .tags = std.ArrayList(Tag).init(alloc),
            .alloc = alloc,
        };
    }

    /// Deinitializes the List, freeing the memory of the contained tags and itself.
    pub fn deinit(self: *Self) void {
        for (self.tags.items) |*tag| {
            tag.deinit();
        }
        self.tags.deinit();
    }

    /// Appends a new tag to the end of the `List`.
    /// Essentially an NBT-compatible wrapper around the `insert` method on `std.ArrayList`.
    ///
    /// The appended NBT tag's type corresponds to the type of the `value` parameter.
    /// Lack of a matching NBT type causes a compile error.
    ///
    /// If the function fails, the tag will NOT be appended, meaning its memory will NOT
    /// be managed by the `List`. The tag must then be freed accordingly by the caller.
    /// This only concerns `value`s of type `List` and `Compound`, as other tag types
    /// do not contain dynamically allocated memory
    pub fn append(self: *Self, value: anytype) NbtError!void {
        var tag = try Tag.from(self.alloc, value);
        errdefer tag.deinit();

        if (tag.tag_union != self.tags_type) {
            return NbtError.ListTypeMismatch;
        } else {
            try self.tags.append(tag);
        }
    }

    /// Inserts a new tag at index `i` in the List, moves following tags to higher indices.
    /// Essentially an NBT-compatible wrapper around the `insert` method on `std.ArrayList`.
    ///
    /// The inserted NBT tag's type corresponds to the type of the `value` parameter.
    /// Lack of a matching NBT type causes a compile error.
    ///
    /// If the function fails, the tag will NOT be inserted, meaning its memory will NOT
    /// be managed by the List. The tag must then be freed accordingly by the caller.
    /// This only concerns `value`s of type `List` and `Compound`, as other tag types
    /// do not contain dynamically allocated memory
    pub fn insert(self: *Self, i: usize, value: anytype) NbtError!void {
        var tag = try Tag.from(self.alloc, value);
        errdefer tag.deinit();

        if (tag != self.tags_type) {
            return NbtError.ListTypeMismatch;
        } else {
            try self.tags.insert(i, tag);
        }
    }

    /// An NBT-compatible wrapper around the `orderedRemove` method on `std.ArrayList`.
    ///
    /// From 'std.ArrayList`'s `orderedRemove` doc comment:
    ///
    /// "Remove the element at index i, shift elements after index i forward, and return the removed element.
    /// Invalidates element pointers to end of list. This operation is O(N). This preserves item order.
    /// Use swapRemove if order preservation is not important. Asserts that the index is in bounds.
    /// Asserts that the list is not empty."
    pub fn orderedRemove(self: *Self, i: usize) Tag {
        return self.tags.orderedRemove(i);
    }

    /// An NBT-compatible wrapper around the `swapRemove` method on `std.ArrayList`.
    ///
    /// From 'std.ArrayList`'s `swapRemove` doc comment:
    ///
    /// "Removes the element at the specified index and returns it. The empty slot is filled from the end of the list.
    /// This operation is O(1). This may not preserve item order. Use orderedRemove if you need to preserve order.
    /// Asserts that the list is not empty. Asserts that the index is in bounds."
    pub fn swapRemove(self: *Self, i: usize) Tag {
        return self.tags.swapRemove(i);
    }

    pub fn snbt(self: Self, writer: anytype) NbtError!void {
        try listSnbtCompact(self.tags, writer);
    }

    pub fn snbtMultiline(self: Self, writer: anytype, indent: usize) NbtError!void {
        try listSnbtMultiline(self.tags, writer, indent);
    }
};

/// Collection of named NBT Tags, an NBT-compatible wrapper
/// around std.StringHashMap(Tag).
///
/// Tag name memory is managed by the caller. Tag payload memory is
/// managed by the Compound after the tag was succesfully inserted.
pub const Compound = struct {
    /// Alias for the type of this struct
    const Self = @This();

    /// NBT tags contained in this Compound
    tags: std.StringHashMap(Tag),

    alloc: Allocator,

    /// Initializes the Compound.
    pub fn init(alloc: Allocator) Self {
        return Self{ .tags = std.StringHashMap(Tag).init(alloc), .alloc = alloc };
    }

    /// Deinitializes the `Compound`, freeing the memory of the `std.StringHashMap`'s keys, contained tags and itself.
    pub fn deinit(self: *Self) void {
        var kv_iter = self.tags.iterator();
        while (kv_iter.next()) |kv| {
            kv.value_ptr.*.deinit();
            self.alloc.free(kv.key_ptr.*);
        }
        self.tags.deinit();
    }

    /// An NBT-compatible wrapper around the `put` method on `std.StringHashMap`.
    ///
    /// The added NBT tag's type corresponds to the type of the `value` parameter.
    /// Lack of a matching NBT type causes a compile error.
    ///
    /// Does NOT copy the memory referenced by `name`. The string referenced by `name`
    /// must live at least as long as the entire `Compound`
    ///
    /// If the function fails, the tag will NOT be put, meaning its memory will NOT
    /// be managed by the Compound. The tag must then be freed accordingly by the caller.
    /// This only concerns `value`s of type `List` and `Compound`, as other tag types
    /// do not contain dynamically allocated memory
    pub fn put(self: *Self, name: []const u8, value: anytype) NbtError!void {
        const new_tag = try Tag.from(self.alloc, value);
        try self.putTag(name, new_tag);
    }

    pub fn putTag(self: *Self, name: []const u8, tag: Tag) NbtError!void {
        const name_copy = try self.alloc.dupe(u8, name);
        try self.tags.put(name_copy, tag);
    }

    pub fn putByte(self: *Self, name: []const u8, value: i8) NbtError!void {
        try self.put(name, value);
    }

    pub fn putShort(self: *Self, name: []const u8, value: i16) NbtError!void {
        try self.put(name, value);
    }

    pub fn putInt(self: *Self, name: []const u8, value: i32) NbtError!void {
        try self.put(name, value);
    }

    pub fn putLong(self: *Self, name: []const u8, value: i64) NbtError!void {
        try self.put(name, value);
    }

    pub fn putFloat(self: *Self, name: []const u8, value: f32) NbtError!void {
        try self.put(name, value);
    }

    pub fn putDouble(self: *Self, name: []const u8, value: f64) NbtError!void {
        try self.put(name, value);
    }

    pub fn putByteArray(self: *Self, name: []const u8, value: []const i8) NbtError!void {
        try self.put(name, value);
    }

    pub fn putIntArray(self: *Self, name: []const u8, value: []const i32) NbtError!void {
        try self.put(name, value);
    }

    pub fn putLongArray(self: *Self, name: []const u8, value: []const i64) NbtError!void {
        try self.put(name, value);
    }

    /// An NBT-compatible wrapper around the `remove` method on `std.StringHashMap`.
    ///
    /// From `std.StringHashMap`'s `remove` doc comment:
    ///
    /// "If there is an Entry with a matching key, it is deleted from the hash map,
    /// and this function returns `true`. Otherwise this function returns `false`.
    pub fn remove(self: *Self, name: []const u8) bool {
        return self.tags.remove(name);
    }

    /// An NBT-compatible wrapper around the `contains` method on `std.StringHashMap`.
    ///
    /// From `std.StringHashMap`'s `contains` doc comment:
    ///
    /// "Check if the map contains a key"
    pub fn contains(self: Self, name: []const u8) bool {
        return self.tags.contains(name);
    }

    /// Returns string representation (SNBT) of this compound with all the nested values.
    ///
    /// Format: `{name1:123,name2:"sometext1",name3:{subname1:456,subname2:"sometext2"}}`
    ///
    /// https://minecraft.fandom.com/wiki/NBT_format#SNBT_format
    pub fn snbtCompact(self: Self, writer: anytype) NbtError!void {
        try compoundSnbtCompact(self.tags, writer);
    }

    /// Returns multi-line human readable string representation (SNBT) of this compound with all the nested values.
    /// 
    /// Example format:
    /// ```
    /// {
    ///     list: [
    ///         {
    ///             number1: 123,
    ///             number2: 456,
    ///             number3: 789
    ///         },
    ///         {
    ///             string1: "str1",
    ///             string2: "str2"
    ///         },
    ///         {
    ///             array: [
    ///                 1
    ///             ],
    ///             double: 12.34
    ///         }
    ///     ]
    /// }
    /// ```
    ///
    /// https://minecraft.fandom.com/wiki/NBT_format#SNBT_format
    pub fn snbtMultiline(self: Self, writer: anytype, indent: usize) NbtError!void {
       try compoundSnbtMultiline(self.tags, writer, indent);
    }
};
