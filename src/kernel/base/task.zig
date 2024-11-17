const std = @import("std");
const config = @import("../../config.zig");
const types = @import("../../utils/types.zig");
const TSK_ENTRY_FUNC = *allowzero const fn (?*anyopaque) callconv(.C) ?*anyopaque;
const lockdep = @import("../base/lockdep.zig");
const list = @import("../common/list.zig");
const event = @import("./event.zig");
const sched_debug = @import("./los_sched_debug.zig");
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
        types.ValueIfElse(std.mem.zeroes([4]?*anyopaque), null, config.LOSCFG_OBSOLETE_API), //Task name
    taskName: []const u8,
    pendList: list.DoublyList, //Task pend node
    sortList: list.DoublyList, //Task sortlink node
    event: types.TypeIf(event.EventCallback, config.LOSCFG_BASE_IPC_EVENT) =
        types.ValueIf(.{}, config.LOSCFG_BASE_IPC_EVENT),

    eventMask: types.TypeIf(u32, config.LOSCFG_BASE_IPC_EVENT) =
        types.ValueIf(0, config.LOSCFG_BASE_IPC_EVENT), //Event mask
    eventMode: types.TypeIf(u32, config.LOSCFG_BASE_IPC_EVENT) =
        types.ValueIf(0, config.LOSCFG_BASE_IPC_EVENT), //Event mode
    msg: ?*anyopaque = null, //Memory allocated to queues
    priBitMap: u32 = 0,
    signal: u32 = 0,
    //Remaining time slice
    timeSlice: types.TypeIf(u16, config.LOSCFG_BASE_CORE_TIMESLICE) =
        types.ValueIf(0, config.LOSCFG_BASE_CORE_TIMESLICE),
    //CPU core number of this task is running on
    currCpu: types.TypeIf(u16, config.LOSCFG_KERNEL_SMP) =
        types.ValueIf(0, config.LOSCFG_KERNEL_SMP),
    //CPU core number of this task is running on last time
    lastCpu: types.TypeIf(u16, config.LOSCFG_KERNEL_SMP) =
        types.ValueIf(0, config.LOSCFG_KERNEL_SMP),
    //CPU core number of this task is delayed or pended
    timerCpu: types.TypeIf(u16, config.LOSCFG_KERNEL_SMP) =
        types.ValueIf(0, config.LOSCFG_KERNEL_SMP),
    //CPU affinity mask, support up to 16 cores
    cpuAffiMask: types.TypeIf(u16, config.LOSCFG_BASE_CORE_TIMESLICE) =
        types.ValueIf(0, config.LOSCFG_BASE_CORE_TIMESLICE),
    //Synchronization for signal handling
    syncSignal: types.TypeIf(u32, config.LOSCFG_KERNEL_SMP and config.LOSCFG_KERNEL_SMP_TASK_SYNC) =
        types.ValueIf(0, config.LOSCFG_KERNEL_SMP and config.LOSCFG_KERNEL_SMP_TASK_SYNC),

    //Schedule statistics
    schedStat: types.TypeIf(sched_debug.SchedStat, config.LOSCFG_DEBUG_SCHED_STATISTICS) =
        types.ValueIf(.{}, config.LOSCFG_DEBUG_SCHED_STATISTICS),

    lockDep: types.TypeIf(lockdep.LockDep, config.LOSCFG_KERNEL_SMP and config.LOSCFG_KERNEL_SMP_LOCKDEP) =
        types.ValueIf(.{}, config.LOSCFG_KERNEL_SMP and config.LOSCFG_KERNEL_SMP_LOCKDEP),

    pc: types.TypeIf(?*anyopaque, config.LOSCFG_KERNEL_PERF) =
        types.ValueIf(null, config.LOSCFG_KERNEL_PERF),
    fp: types.TypeIf(?*anyopaque, config.LOSCFG_KERNEL_PERF) =
        types.ValueIf(null, config.LOSCFG_KERNEL_PERF),
};

var g_taskCBArray: ?[]TaskCB = null;
var g_freeTask: list.DoublyList = .{};
var g_taskRecycleList: list.DoublyList = .{};
var g_taskMaxNum: u32 = 0;
var g_taskScheduled: u32 = 0;
var g_stackFrameOffLenInTcb: types.TypeIf(u16, config.LOSCFG_LAZY_STACK) =
    types.ValueIf(0, config.LOSCFG_LAZY_STACK);

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

pub fn init() !void {
    g_taskMaxNum = config.LOSCFG_BASE_CORE_TSK_LIMIT_CONFIG;
    // g_taskCBArray =
}
pub fn monInit() !void {}
