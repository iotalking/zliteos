const builtin = @import("builtin");
pub const LOSCFG_EXC_INTERACTION = true;
pub const LOSCFG_SHELL_LK = false;
pub const LOSCFG_SHELL_DMESG = false;
pub const LOSCFG_BASE_CORE_TICK_PER_SECOND = 1000;
pub const LOSCFG_PLATFORM_UART_WITHOUT_VFS = false;
pub const LOSCFG_SHELL = false;
pub const LOSCFG_KERNEL_TRACE = false;
pub const LOS_TRACE_BUFFER_SIZE = 2048;
pub const LOSCFG_BASE_CORE_TSK_MONITOR = false;
pub const LOSCFG_KERNEL_CPUP = false;
pub const LOSCFG_KERNEL_SMP = false;
pub const LOSCFG_KERNEL_DYNLOAD = false;
pub const LOSCFG_HW_RANDOM_ENABLE = false;
pub const LOSCFG_DRIVERS_RANDOM = false;
pub const LOSCFG_KERNEL_PERF = false;
pub const LOS_PERF_BUFFER_SIZE = 2048;
pub const LOSCFG_PLATFORM_OSAPPINIT = true;
pub const LOSCFG_LIB_CONFIGURABLE = false;
pub const LOSCFG_BASE_CORE_SWTMR = true;
pub const LOSCFG_KERNEL_RUNSTOP = false;
pub const LOSCFG_DRIVERS_BASE = false;
pub const LOSCFG_KERNEL_CORE_NUM = 1;
pub const LOSCFG_KERNEL_SMP_TASK_SYNC = true;
pub const LOSCFG_BASE_CORE_TICK_PER_SECOND_CONFIG = 1000;
pub const OS_SYS_CLOCK_CONFIG = 0x6000000;
pub const LOSCFG_BASE_CORE_TSK_LIMIT_CONFIG = 12;
pub const LOSCFG_BASE_CORE_TSK_MIN_STACK_SIZE_CONFIG = 800;
pub const LOSCFG_BASE_CORE_TSK_IDLE_STACK_SIZE_CONFIG = 800;
pub const LOSCFG_BASE_CORE_TSK_DEFAULT_STACK_SIZE_CONFIG = 1536;
pub const LOSCFG_BASE_CORE_TSK_SWTMR_STACK_SIZE_CONFIG = 800;
pub const LOSCFG_BASE_CORE_SWTMR_LIMIT_CONFIG = 16;
pub const LOSCFG_BASE_IPC_SEM_LIMIT_CONFIG = 20;
pub const LOSCFG_BASE_IPC_MUX_LIMIT_CONFIG = 20;
pub const LOSCFG_BASE_IPC_QUEUE_LIMIT_CONFIG = 10;
pub const LOSCFG_BASE_CORE_TIMESLICE_TIMEOUT_CONFIG = 2;
pub const LOSCFG_BASE_IPC_EVENT = true;
pub const LOSCFG_BASE_IPC_SEM = true;
pub const LOSCFG_BASE_IPC_MUX = true;
pub const LOSCFG_BASE_IPC_QUEUE = true;
pub const LOSCFG_DEBUG_SCHED_STATISTICS = true;
pub const LOSCFG_MEM_TASK_STAT = true;
pub const LOSCFG_MEM_MUL_POOL = true;
pub const LOSCFG_KERNEL_MEM_SLAB_AUTO_EXPANSION_MODE = true;
pub const LOSCFG_COMPAT_LINUX = true;
pub const LOSCFG_COMPAT_LINUX_HRTIMER = true;
pub const EXC_INTERACT_MEM_SIZE = 1024;
pub const LOSCFG_MEM_RECORDINFO = false;

pub const LOSCFG_FS_VFS = true;
pub const LOSCFG_KERNEL_TICKLESS = false;

pub const LOSCFG_KERNEL_NX = false;
pub const LOSCFG_KERNLE_DYN_HEAPSIZE = 2;

pub const LOSCFG_KERNEL_MEM_BESTFIT = false;

pub const SYS_MEM_END = 0;

pub const LOS_DL_HEAP_SIZE: [*]allowzero u8 = val: {
    if (LOSCFG_KERNEL_NX and LOSCFG_KERNEL_DYNLOAD) {
        break :val @ptrFromInt(LOSCFG_KERNLE_DYN_HEAPSIZE * 0x100000);
    } else {
        break :val @ptrFromInt(0);
    }
};

extern var g_sysMemAddrEnd: usize;
extern var g_excInteractMemSize: usize;
extern var __bss_end: usize;
pub fn OS_SYS_MEM_SIZE() usize {
    if (builtin.is_test) {
        return 1024 * 1024;
    } else {
        return (g_sysMemAddrEnd -
            (@intFromPtr(LOS_DL_HEAP_SIZE) + g_excInteractMemSize + __bss_end));
    }
}

pub const LOS_DL_HEAP_BASE: [*]allowzero u8 = val: {
    if (LOSCFG_KERNEL_NX and LOSCFG_KERNEL_DYNLOAD) {
        break :val @ptrFromInt(SYS_MEM_END - LOS_DL_HEAP_SIZE);
    } else {
        break :val @ptrFromInt(0);
    }
};

pub fn setNxCfg(enable: bool) void {
    _ = enable;
}
pub fn setDlNxHeapBase(addr: [*]allowzero u8) void {
    _ = addr;
}

pub const LOSCFG_OBSOLETE_API = false;
