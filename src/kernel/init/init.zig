const std = @import("std");
const memory = @import("./mem/bestfit_little/memory.zig");
const global = @import("./global.zig");
const config = @import("../../config.zig");
const shell_lk = @import("../../shell/full/src/base/shell_lk.zig");
const dmesg = @import("../../shell/full/src/cmds/dmesg.zig");
const hwi = @import("../base/hwi.zig");
const fault = @import("../../arch/arm64/src/fault.zig");
const tick = @import("../base/tick.zig");
const uart = @import("../../targets/bsp/drivers/uart/uart_debug.zig");
const task = @import("../base/task.zig");
const trace = @import("../extended/trace/trace.zig");
const cpup = @import("../extended/cpup/cpup.zig");
const swtmr = @import("../base/swtmr.zig");
const mp = @import("../base/mp.zig");
const dyload = @import("../base/dyn_load.zig");
const runstop = @import("../extended/lowpower/runstop/src/runstop.zig");
const perf = @import("../base/perf.zig");
const Test = @import("../../test/test.zig");
const misc = @import("../../kernel/base/misc.zig");
const sem = @import("../base/sem.zig");
const platformConfig = @import("../../targets/common/config.zig");
const mux = @import("../base/mux.zig");
const queue = @import("../base/queue.zig");
const vfs = @import("../../components/fs/vfs/vfs.zig");
const hal_timer = @import("../../targets/bsp/include/hal_timer.zig");
const tickless = @import("../extended/lowpower/tickless/tickless.zig");
pub fn init() !void {
    if (config.LOSCFG_EXC_INTERACTION) {
        if (global.gBSSEnd) |bssEnd| {
            try memory.excInteractionInit(bssEnd);
        }
    }
    if (global.gBSSEnd) |memStart| {
        try memory.systemInit(memStart + global.gExcInteractMemSize);
    }
    try register();
    if (config.LOSCFG_SHELL_LK) {
        try shell_lk.loggerInit(null);
    }
    if (config.LOSCFG_SHELL_DMESG) {
        try dmesg.mesgInit();
    }
    try hwi.init();
    try fault.archExcInit();
    try tick.init(config.LOSCFG_BASE_CORE_TICK_PER_SECOND);

    if (config.LOSCFG_PLATFORM_UART_WITHOUT_VFS) {
        try uart.init();
        if (config.LOSCFG_SHELL) {
            try uart.hwiCreate();
        }
    }

    try task.init();
    if (config.LOSCFG_KERNEL_TRACE) {
        trace.init(config.LOS_TRACE_BUFFER_SIZE);
    }
    if (config.LOSCFG_BASE_CORE_TSK_MONITOR) {
        task.monInit();
    }

    try ipcInit();

    //  CPUP should be inited before first task creation which depends on the semaphore
    //  when LOSCFG_KERNEL_SMP_TASK_SYNC is enabled. So don't change this init sequence
    //  if not necessary. The sequence should be like this:
    //  1. OsIpcInit
    //  2. OsCpupInit -> has first task creation
    //  3. other inits have task creation
    if (config.LOSCFG_KERNEL_CPUP) {
        try cpup.init();
    }

    if (config.LOSCFG_BASE_CORE_SWTMR) {
        try swtmr.init();
    }
    if (config.LOSCFG_KERNEL_SMP) {
        try mp.init();
    }
    if (config.LOSCFG_KERNEL_DYNLOAD) {
        try dyload.init();
    }
    if (config.LOSCFG_HW_RANDOM_ENABLE or config.LOSCFG_DRIVERS_RANDOM) {
        //TODO:
    }

    if (config.LOSCFG_KERNEL_RUNSTOP) {
        runstop.wowWriteFlashTaskCreate();
    }
    if (config.LOSCFG_DRIVERS_BASE) {
        //TODO:
    }
    if (config.LOSCFG_KERNEL_PERF) {
        perf.init(null, config.LOS_PERF_BUFFER_SIZE);
    }
    if (config.LOSCFG_PLATFORM_OSAPPINIT) {
        try appInit();
    } else {
        try Test.init();
    }
}

//TODO:
fn register() !void {
    if (config.LOSCFG_LIB_CONFIGURABLE) {
        global.gOsSysClock = config.OS_SYS_CLOCK_CONFIG;
        global.gTickPerSecond = config.LOSCFG_BASE_CORE_TICK_PER_SECOND_CONFIG; // tick per sencond
        global.gTaskLimit = config.LOSCFG_BASE_CORE_TSK_LIMIT_CONFIG;
        global.gTaskMaxNum = config.gTaskLimit + 1;
        global.gTaskMinStkSize = config.LOSCFG_BASE_CORE_TSK_MIN_STACK_SIZE_CONFIG;
        global.gTaskIdleStkSize = config.LOSCFG_BASE_CORE_TSK_IDLE_STACK_SIZE_CONFIG;
        global.gTaskDfltStkSize = config.LOSCFG_BASE_CORE_TSK_DEFAULT_STACK_SIZE_CONFIG;
        global.gTaskSwtmrStkSize = config.LOSCFG_BASE_CORE_TSK_SWTMR_STACK_SIZE_CONFIG;
        global.gSwtmrLimit = config.LOSCFG_BASE_CORE_SWTMR_LIMIT_CONFIG;
        global.gSemLimit = config.LOSCFG_BASE_IPC_SEM_LIMIT_CONFIG;
        global.gMuxLimit = config.LOSCFG_BASE_IPC_MUX_LIMIT_CONFIG;
        global.gQueueLimit = config.LOSCFG_BASE_IPC_QUEUE_LIMIT_CONFIG;
        global.gTimeSliceTimeOut = config.LOSCFG_BASE_CORE_TIMESLICE_TIMEOUT_CONFIG;
    } else {
        tick.gTickPerSecond = config.LOSCFG_BASE_CORE_TICK_PER_SECOND_CONFIG; // tick per sencond
    }

    tick.setSysClock(platformConfig.OS_SYS_CLOCK);

    if (config.LOSCFG_KERNEL_NX) {
        config.setNxCfg(true);
    } else {
        config.setNxCfg(false);
    }

    config.setDlNxHeapBase(config.LOS_DL_HEAP_SIZE);
}
fn ipcInit() !void {
    if (config.LOSCFG_BASE_IPC_SEM) {
        try sem.init();
    }
    if (config.LOSCFG_BASE_IPC_MUX) {
        try mux.init();
    }
    if (config.LOSCFG_BASE_IPC_QUEUE) {
        try queue.init();
    }
}
fn appInit() !void {
    if (config.LOSCFG_PLATFORM_OSAPPINIT) {
        if (config.LOSCFG_FS_VFS) {
            try vfs.init();
        }
        if (config.LOSCFG_COMPAT_LINUX) {
            if (config.LOSCFG_COMPAT_LINUX_HRTIMER) {
                try hal_timer.init();
            }
        }
        if (config.LOSCFG_BASE_CORE_SWTMR) {
            //TODO:
        }
        try appTaskCreate();
        if (config.LOSCFG_MEM_RECORDINFO) {
            try memShowTaskCreate();
        }
        if (config.LOSCFG_KERNEL_TICKLESS) {
            try tickless.lessEnable();
        }
    }
}

fn appTaskCreate() !void {
    var param: task.TskInitParam = .{};
    _ = &param;
    if (std.mem.len(param.pcName) == 0) {
        return error.pc_name_empty;
    }
}
fn memShowTaskCreate() !void {}
