const std = @import("std");
const config = @import("../../config.zig");
const types = @import("../../utils/types.zig");
const TSK_ENTRY_FUNC = *allowzero const fn (?*anyopaque) callconv(.C) ?*anyopaque;
const lockdep = @import("../base/lockdep.zig");

pub const TaskCB = packed struct {
    stackPointer: [*]u8, //Task stack pointer
    taskStatus: u16 = 0, //Task status
    priority: u16 = 0, //Task priority
    taskFlags: u31 = 0, //Task extend flags: taskFlags uses 8 bits now. 23 bits left
    usrStack: bool = false, //Usr Stack uses the last bit
    stackSize: u32 = 0, //Task stack size
    topOfStack: [*]u8, //Task stack top
    taskId: u32 = 0, //Task ID
    taskEntry: TSK_ENTRY_FUNC, //ask entrance function
    taskSem: ?*anyopaque = null, //Task-held semaphore
    stackFrame: types.TypeIf(u32, config.LOSCFG_LAZY_STACK) =
        types.ValueIf(0, config.LOSCFG_LAZY_STACK), //Stack frame: 0=Basic, 1=Extended
    threadJoin: types.TypeIf(?*anyopaque, config.LOSCFG_COMPAT_POSIX) =
        types.ValueIf(null, config.LOSCFG_COMPAT_POSIX), //pthread adaption
    threadJoinRetval: types.TypeIf(?*anyopaque, config.LOSCFG_COMPAT_POSIX) =
        types.ValueIf(null, config.LOSCFG_COMPAT_POSIX), //pthread adaption
    taskMux: ?*anyopaque = null, //Task-held mutex
    args: types.TypeIfElse([4]?*anyopaque, ?*anyopaque, config.LOSCFG_OBSOLETE_API) =
        types.ValueIfElse(std.mem.zeroes([4]?*anyopaque), null, config.LOSCFG_OBSOLETE_API),

    taskName: [*]u8,
    currCpu: u16 = 0, //CPU core number of this task is running on
    lastCpu: u16 = 0, //CPU core number of this task is running on last time
    timerCpu: u32 = 0, //CPU core number of this task is delayed or pended
    cpuAffiMask: u16, //CPU affinity mask, support up to 16 cores
    syncSignal: types.TypeIf(u32, config.LOSCFG_KERNEL_SMP_TASK_SYNC) =
        types.ValueIf(0, config.LOSCFG_KERNEL_SMP_TASK_SYNC), //Synchronization for signal handling
    lockDep: types.TypeIf(lockdep.LockDep, config.LOSCFG_KERNEL_SMP_LOCKDEP) =
        types.ValueIf(.{}, config.LOSCFG_KERNEL_SMP_LOCKDEP),
};
// pLITE_OS_SEC_BSS LosTaskCB                       *g_taskCBArray;
// LITE_OS_SEC_BSS LOS_DL_LIST                     g_losFreeTask;
// LITE_OS_SEC_BSS LOS_DL_LIST                     g_taskRecycleList;
// LITE_OS_SEC_BSS UINT32                          g_taskMaxNum;
// LITE_OS_SEC_BSS UINT32                          g_taskScheduled; /* one bit for each cores */
// #ifdef LOSCFG_LAZY_STACK
// LITE_OS_SEC_BSS UINT16                          g_stackFrameOffLenInTcb;
// #endif

pub const TskInitParam = extern struct {
    pfnTaskEntry: TSK_ENTRY_FUNC = @ptrFromInt(0), //
    usTaskPrio: u16 = @import("std").mem.zeroes(u16),
    auwArgs: types.TypeIf([4]?*anyopaque, config.LOSCFG_OBSOLETE_API) = types.ValueIf(null, config.LOSCFG_OBSOLETE_API),
    pArgs: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    uwStackSize: usize = 0,
    pcName: [*c]c_char = @import("std").mem.zeroes([*c]c_char),
    usCpuAffiMask: types.TypeIf(u16, config.LOSCFG_KERNEL_SMP) = types.ValueIf(0, config.LOSCFG_KERNEL_SMP),
    uwResved: usize = 0,
};

pub fn init() !void {}
pub fn monInit() !void {}
