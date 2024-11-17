const std = @import("std");
const config = @import("../../../../config.zig");
const types = @import("../../../../utils/types.zig");
const memory_stat = @import("../../memory_stat.zig");
pub const MemPoolInfo = struct {
    pool: *anyopaque,
    poolSize: u32,
    stat: types.TypeIf(memory_stat.Memstat, config.LOSCFG_MEM_TASK_STAT),
    nextPool: types.TypeIf(*anyopaque, config.LOSCFG_MEM_MUL_POOL),
};
var gpa = std.heap.GeneralPurposeAllocator(.{});
pub fn allocator() std.mem.Allocator {
    return gpa.allocator();
}
