const std = @import("std");
const config = @import("../../config.zig");
const types = @import("../../utils/types.zig");

pub const MAX_LOCK_DEPTH = 16;
pub const HeldLocks = struct {
    lockPtr: ?*anyopaque = null,
    lockAddr: ?*anyopaque = null,
    waitTime: u64 = 0,
    holdTime: u64 = 0,
};
pub const LockDep = struct {
    waitLock: ?*anyopaque = null,
    lockDepth: i32 = 0,
    heldLocks: [MAX_LOCK_DEPTH]HeldLocks = std.mem.zeroes([MAX_LOCK_DEPTH]HeldLocks),
};
