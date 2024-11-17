const std = @import("std");
const config = @import("../../config.zig");
const types = @import("../../utils/types.zig");

pub fn init() !void {}
//TODO:
pub fn MEM_LOCK(state: *u32) !void {
    _ = state;
}
//TODO:
pub fn MEM_UNLOCK(state: *u32) !void {
    _ = state;
}

pub fn allocator() std.mem.Allocator {
    if (config.LOSCFG_KERNEL_MEM_BESTFIT) {
        return @import("./mem/bestfit/memory.zig").allocator();
    } else {
        const memory = @import("./mem/bestfit_little/memory.zig");
        return memory.allocator();
    }
}

test "allocator" {
    std.testing.log_level = .debug;
    const buf = try std.testing.allocator.alignedAlloc(u8, 8, config.OS_SYS_MEM_SIZE());
    defer std.testing.allocator.free(buf);

    if (config.LOSCFG_KERNEL_MEM_BESTFIT) {} else {
        const memory = @import("./mem/bestfit_little/memory.zig");

        std.log.debug("[[systemInit", .{});
        try memory.systemInit(buf.ptr);
        std.log.debug("]]systemInit", .{});
    }
    const _alloctor = allocator();

    const array = try _alloctor.alloc(u8, 1024 * 10);
    _ = &array;
    defer _alloctor.free(array);
    std.log.debug("array:{*}", .{array});

    const Data = struct {
        id: u64 = 0,
        name: [32]u8 = undefined,
    };
    const data = try _alloctor.create(Data);
    defer _alloctor.destroy(data);

    const s1 = try _alloctor.create(struct { u8, [37]u8 });
    defer _alloctor.destroy(s1);
}
