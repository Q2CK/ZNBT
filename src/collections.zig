const std = @import("std");
const NbtError = @import("errors.zig").NbtError;
const Allocator = std.mem.Allocator;

const tag_import = @import("tag.zig");
const Tag = tag_import.Tag;
const TagType = tag_import.TagType;

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

    /// Initializes the List and sets the expected type of the contained tags.
    pub fn init(alloc: Allocator, tags_type: TagType) Self {
        return Self{
            .tags_type = tags_type,
            .tags = std.ArrayList(Tag).init(alloc),
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
        var tag = Tag.from(value);
        errdefer tag.deinit();

        if (tag != self.tags_type) {
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
        var tag = Tag.from(value);
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
        _ = try writer.write("[");
        var is_first_tag = true;
        for (self.tags.items) |tag| {
            if (!is_first_tag) {
                _ = try writer.write(",");
            }
            _ = try tag.snbt(writer);
            is_first_tag = false;
        }
        _ = try writer.write("]");
    }

    pub fn snbtMultiline(self: Self, writer: anytype, indent: usize) NbtError!void {
        _ = try writer.write("[");

        var is_first_tag = true;
        for (self.tags.items) |tag| {
            if (!is_first_tag) {
                _ = try writer.write(",");
            }
            _ = try writer.write("\n",);
            _ = try writer.writeByteNTimes(' ', indent + INDENT_SIZE_IN_SPACES);
            try tag.snbtMultiline(writer, indent + INDENT_SIZE_IN_SPACES);
            is_first_tag = false;
        }

        _ = try writer.write("\n");
        _ = try writer.writeByteNTimes(' ', indent);
        _ = try writer.write("]");
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

    /// Initializes the Compound.
    pub fn init(alloc: Allocator) Self {
        return Self{ .tags = std.StringHashMap(Tag).init(alloc) };
    }

    /// Deinitializes the List, freeing the memory of the contained tags and itself.
    pub fn deinit(self: *Self) void {
        var tags_iter = self.tags.valueIterator();
        while (tags_iter.next()) |tag| {
            tag.deinit();
        }
        self.tags.deinit();
    }

    /// An NBT-compatible wrapper around the `put` method on `std.StringHashMap`.
    ///
    /// The added NBT tag's type corresponds to the type of the `value` parameter.
    /// Lack of a matching NBT type causes a compile error.
    ///
    /// Does NOT copy the memory referenced by `name`. The string referenced by `name`
    /// must live at least as long as the entire `Compund`
    ///
    /// If the function fails, the tag will NOT be put, meaning its memory will NOT
    /// be managed by the Compound. The tag must then be freed accordingly by the caller.
    /// This only concerns `value`s of type `List` and `Compound`, as other tag types
    /// do not contain dynamically allocated memory
    pub fn put(self: *Self, name: []const u8, value: anytype) NbtError!void {
        const new_tag = Tag.from(value);
        try self.tags.put(name, new_tag);
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
    pub fn snbt(self: Self, writer: anytype) NbtError!void {
        _ = try writer.write("{");

        var it = self.tags.iterator();
        var is_first_tag = true;
        while (it.next()) |entry| {
            if (!is_first_tag) {
                _ = try writer.write(",");
            }
            _ = try writer.write(entry.key_ptr.*);
            _ = try writer.write(":");
            const tag = entry.value_ptr.*;
            try tag.snbt(writer);

            is_first_tag = false;
        }

        _ = try writer.write("}");
    }

    pub fn snbtMultiline(self: Self, writer: anytype, indent: usize) NbtError!void {
        _ = try writer.write("{");

        var it = self.tags.iterator();
        var is_last_tag = false;
        var i: i32 = 0;

        while (it.next()) |entry| {
            if (i == self.tags.count() - 1) {
                is_last_tag = true;
            }
            _ = try writer.write("$\n$");
            _ = try writer.writeByteNTimes(' ', indent + INDENT_SIZE_IN_SPACES);
            _ = try writer.write(entry.key_ptr.*);
            _ = try writer.write(": ");
            const tag = entry.value_ptr.*;
            try tag.snbtMultiline(writer, indent + INDENT_SIZE_IN_SPACES);
            if (!is_last_tag) {
                _ = try writer.write(",");
            }
            _ = try writer.write("\n");
            i += 1;            
        }

        _ = try writer.writeByteNTimes(' ', indent);
        _ = try writer.write("}");
    }
};
