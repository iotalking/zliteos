const std = @import("std");
const init = @import("./kernel/init/init.zig");

pub fn main() !void {
    try init.init();
}

comptime {
    _ = @import("./kernel/common/list.zig");
}
