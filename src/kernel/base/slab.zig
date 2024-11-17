const std = @import("std");
const config = @import("../../config.zig");
const types = @import("../../utils/types.zig");

//number of slab class
pub const SLAB_MEM_COUNT = 4;
//step size of each class
pub const SLAB_MEM_CALSS_STEP_SIZE = 0x10;
//max slab block size
pub const SLAB_MEM_MAX_SIZE = (SLAB_MEM_CALSS_STEP_SIZE << (SLAB_MEM_COUNT - 1));

pub const Status = struct {
    totalSize: u32 = 0,
    usedSize: u32 = 0,
    freeSize: u32 = 0,
    allocCount: u32 = 0,
    freeCount: u32 = 0,
};

pub const BlockNode = struct {
    magic: u16 = 0,
    blkSz: u8 = 0,
    recordId: u8 = 0,
};

pub const AtomicBitset = struct {
    numBits: u32 = 0,
    pub fn words(this: *AtomicBitset) ?[*]u32 {
        _ = this;
        return null;
    }
};

pub const Allocator = struct {
    itemSz: u32 = 0,
    dataChunks: *u8,
    bitset: *AtomicBitset,
};
pub const MemAllocator =
    types.TypeIf(struct {
    next: ?*MemAllocator = null,
    slabAlloc: ?*Allocator = null,
}, config.LOSCFG_KERNEL_MEM_SLAB_AUTO_EXPANSION_MODE);

pub const Mem = struct {
    blkSz: u32 = 0,
    blkCnt: u32 = 0,
    blkUsedCnt: u32 = 0,
    allocatorCnt: types.TypeIf(u32, config.LOSCFG_KERNEL_MEM_SLAB_AUTO_EXPANSION_MODE),
    bucket: types.TypeIf(*MemAllocator, config.LOSCFG_KERNEL_MEM_SLAB_AUTO_EXPANSION_MODE),
    alloc: types.TypeIf(*Allocator, !config.LOSCFG_KERNEL_MEM_SLAB_AUTO_EXPANSION_MODE),
};
pub const ControlHeader = struct {
    allocatorBucket: types.TypeIf(*Allocator, config.LOSCFG_KERNEL_MEM_SLAB_AUTO_EXPANSION_MODE),
    slabClass: [SLAB_MEM_COUNT]Mem,
};

pub const SLAB_MEM_DFEAULT_BUCKET_CNT = 1;
pub const OS_SLAB_MAGIC = 0xdede;

pub fn memInit(pool: []u8) !void {
    _ = pool;
}
pub fn memDeinit(pool: []u8) !void {
    _ = pool;
}

pub fn memCheck(pool: *anyopaque, buf: []u8) u32 {
    _ = pool;
    _ = buf;
    return @bitCast(@as(i32, -1));
}
