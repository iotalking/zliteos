const std = @import("std");
const config = @import("../../config.zig");
const types = @import("../../utils/types.zig");

pub const SchedPercpu = struct {
    runtime: u64 = 0,
    contexSwitch: u32 = 0,
};
pub const SchedStat = struct {
    startRuntime: u64 = 0,
    allRuntime: u64 = 0,
    allContextSwitch: u64 = 0,
    schedPercpu: [config.LOSCFG_KERNEL_CORE_NUM]SchedPercpu = std.mem.zeroes([config.LOSCFG_KERNEL_CORE_NUM]SchedPercpu),
};
