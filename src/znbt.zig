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
    pub const writeBin = io_import.writeBin;
    pub const readBin = io_import.readBin;
    pub const writeSNBT = io_import.writeSNBT;
    pub const Compression = io_import.Compression;
    pub const SNBTFormat = io_import.SNBTFormat;
};
