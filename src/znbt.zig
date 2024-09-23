const tag_import = @import("tag.zig");
const collections_import = @import("collections.zig");
const io_import = @import("io.zig");

pub const tag = struct {
    pub const TagType = tag_import.TagType;
    pub const Tag = tag_import.Tag;
};

pub const collections = struct {
    pub const List = collections_import.List;
    pub const Compound = collections_import.Compound;
};

pub const io = struct {
    pub const write = io_import.write;
    pub const read = io_import.read;
    pub const Compression = io_import.Compression;
};
