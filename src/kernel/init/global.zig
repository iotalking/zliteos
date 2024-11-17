pub const gBSSEnd: ?[*]u8 = null;
pub const gExcInteractMemSize: usize = 0;

pub var gOsSysClock: usize = 0;
pub var gSemLimit: usize = 0;
pub var gMuxLimit: usize = 0;
pub var gQueueLimit: usize = 0;

pub var gSwtmrLimit: usize = 0;
pub var gTaskLimit: usize = 0;
pub var gMinusOneTickPerSecond: usize = 0;
pub var gtaskMinStkSize: usize = 0;
pub var gTaskIdleStkSize: usize = 0;
pub var gTaskSwtmrStkSize: usize = 0;
pub var gTaskDfltStkSize: usize = 0;
pub var gTimeSliceTimeOut: usize = 0;

pub var gNxEnabled = false;
pub var gDlNxHeapBase: *anyopaque = undefined;
pub var gDlNxHeapSize: usize = 0;
