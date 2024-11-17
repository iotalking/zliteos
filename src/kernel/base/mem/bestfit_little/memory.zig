const std = @import("std");
const config = @import("../../../../config.zig");
const types = @import("../../../../utils/types.zig");
const memory_stat = @import("../../memory_stat.zig");
pub const memory = @import("../../memory.zig");
const heap = @import("./heap.zig");
const slab = @import("../../slab.zig");

var m_aucSysMem0: ?[*]u8 = null;
var m_aucSysMem1: ?[*]u8 = null;
var g_excInteractMemSize: usize linksection(".data.init") = 0;
var g_sysMemAddrEnd: usize linksection(".data.init") = 0;

pub const POOL_ADDR_ALIGNSIZE = 64;

pub const MemPoolInfo = types.TypeIfElse(struct {}, struct {
    const HeadNode = @This();
    head: ?*HeadNode = null,
    tail: ?*HeadNode = null,
    size: u32 = 0,
}, config.LOSCFG_KERNEL_MEM_BESTFIT);

pub fn init(pool: []u8) !void {
    if (pool.len <= @sizeOf(heap.HeapManager)) {
        return error.init;
    }
    var intSave: u32 = 0;
    try memory.MEM_LOCK(&intSave);
    defer memory.MEM_UNLOCK(&intSave) catch unreachable;

    try mulPoolInit(pool);
    errdefer mulPoolDeInit(pool) catch unreachable;

    try heap.init(pool);

    try slab.memInit(pool);
}

pub fn mulPoolInit(pool: []u8) !void {
    _ = pool;
}
pub fn mulPoolDeInit(pool: []u8) !void {
    _ = pool;
}

test "init" {
    std.testing.log_level = .debug;
    std.log.debug("memory init", .{});
    const buf = try std.testing.allocator.alignedAlloc(u8, 8, config.OS_SYS_MEM_SIZE());
    defer std.testing.allocator.free(buf);

    try init(buf);
}
pub fn ExcInteractionInit(memStart: [*]u8) !void {
    _ = &memStart;
    m_aucSysMem0 = @alignCast(@ptrCast(memStart + (POOL_ADDR_ALIGNSIZE - 1)));

    g_excInteractMemSize = config.EXC_INTERACT_MEM_SIZE;

    try init(m_aucSysMem0[0..g_excInteractMemSize]);
}

pub fn systemInit(memStart: [*]u8) !void {
    std.log.debug("systemInit :{*}", .{memStart});

    m_aucSysMem1 = @as([*]u8, @ptrFromInt((@intFromPtr(memStart) + (POOL_ADDR_ALIGNSIZE - 1)) & ~(@as(usize, POOL_ADDR_ALIGNSIZE - 1))));
    if (m_aucSysMem1) |mem1| {
        try init(mem1[0..config.OS_SYS_MEM_SIZE()]);
        if (config.LOSCFG_EXC_INTERACTION) {
            m_aucSysMem0 = m_aucSysMem1;
        }
    } else {
        return error.auc_sys_mem1;
    }
}

pub fn allocator() std.mem.Allocator {
    return heap.allocator();
}
