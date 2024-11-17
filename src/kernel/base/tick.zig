const std = @import("std");
const config = @import("../../config.zig");
const buildDef = @import("../../build/build_def.zig");
pub var gTickCount: [config.LOSCFG_KERNEL_CORE_NUM]u64 linksection(buildDef.LITE_OS_SEC_BSS) = std.mem.zeroes([config.LOSCFG_KERNEL_CORE_NUM]u64);
pub var gSysClock: usize linksection(buildDef.LITE_OS_SEC_DATA_VEC) = 0;
pub var gTickPerSecond: usize linksection(buildDef.LITE_OS_SEC_DATA_VEC) = 0;
pub var gCycle2NsScale: f64 linksection(buildDef.LITE_OS_SEC_BSS) = 0;

pub fn init(tickPerSecond: usize) !void {
    _ = tickPerSecond;
}

pub inline fn setSysClock(clock: usize) void {
    gSysClock = clock;
}
