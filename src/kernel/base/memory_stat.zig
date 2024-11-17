const std = @import("std");
const config = @import("../../config.zig");

pub const TASK_NUM = config.LOSCFG_BASE_CORE_TSK_LIMIT_CONFIG + 1;
pub const TaskMemUsedInfo = struct {
    memUsed: u32 = 0,
    memPeak: u32 = 0,
};
pub const Memstat = struct {
    memTotalUsed: u32 = 0,
    memTotalPeak: u32 = 0,
    taskMemstats: [TASK_NUM]TaskMemUsedInfo = std.mem.zeroes([TASK_NUM]TaskMemUsedInfo),
};
