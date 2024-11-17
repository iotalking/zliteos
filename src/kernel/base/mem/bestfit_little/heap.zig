const std = @import("std");
const config = @import("../../../../config.zig");
const types = @import("../../../../utils/types.zig");
const memory_stat = @import("../../memory_stat.zig");
const memory = @import("../../memory.zig");
const slab = @import("../../slab.zig");

const HEAP_ALIGN: u32 = 16; //TODO: why 16?
const MALLOC_MAXSIZE = (0xFFFFFFFF - HEAP_ALIGN + 1);
pub inline fn ALIGNE(sz: u32) u32 {
    return (((sz) + HEAP_ALIGN - 1) & (~(HEAP_ALIGN - 1)));
}

pub const HeapManager = struct {
    head: ?*Node = null,
    tail: ?*Node = null,
    size: u32 = 0,
    stat: types.TypeIf(memory_stat.Memstat, config.LOSCFG_MEM_TASK_STAT),
    nextPool: types.TypeIf(*anyopaque, config.LOSCFG_MEM_MUL_POOL),
};

var g_heapMan: *HeapManager = undefined;

pub fn init(poolMem: []u8) !void {
    std.log.debug("poolMem :{*}", .{poolMem.ptr});
    g_heapMan = @alignCast(@ptrCast(poolMem.ptr));
    if (poolMem.len < @sizeOf(HeapManager)) {
        return error.size_small;
    }
    @memset(poolMem, 0);

    g_heapMan.size = @truncate(poolMem.len - @sizeOf(HeapManager));
    g_heapMan.head = @ptrFromInt(@intFromPtr(poolMem.ptr) + @sizeOf(HeapManager));
    g_heapMan.head.?.* = .{};
    std.log.debug("head:{any}", .{g_heapMan.head});
    if (g_heapMan.head) |node| {
        g_heapMan.tail = node;
        node.size = @truncate(g_heapMan.size - @sizeOf(Node));
    }
    try statInit(g_heapMan, poolMem.len);
    std.log.debug("heap init end", .{});
}
pub const Status = struct {
    totalUsedSize: u32 = 0,
    totalFreeSize: u32 = 0,
    maxFreeNodeSize: u32 = 0,
    usedNodeNum: u32 = 0,
    usageWaterLine: types.TypeIf(u32, config.LOSCFG_MEM_TASK_STAT) =
        types.ValueIf(0, config.LOSCFG_MEM_TASK_STAT),
};

pub const Node = packed struct {
    prev: ?*Node = null,
    taskId: types.TypeIf(u32, config.LOSCFG_MEM_TASK_STAT) =
        types.ValueIf(0, config.LOSCFG_MEM_TASK_STAT),
    size: u30 = 0,
    used: bool = false,
    _align: bool = false,
    data: void = {},
    pub fn getData(this: *Node) [*]u8 {
        const ret: [*]u8 = @alignCast(@ptrCast(&this.data));
        return ret;
    }
};

pub fn statInit(headMan: *HeapManager, size: usize) !void {
    _ = headMan;
    _ = size;
}

pub fn allocator() std.mem.Allocator {
    return std.mem.Allocator{
        .ptr = g_heapMan,
        .vtable = &.{
            .alloc = alloc,
            .resize = resize,
            .free = free,
        },
    };
}

fn alloc(ctx: *anyopaque, len: usize, ptr_align: u8, ret_addr: usize) ?[*]u8 {
    _ = ret_addr;
    std.log.debug("alloc len:{d} align:{} HEAD_ALIGN:{d} sizeof Node:{d}", .{ len, ptr_align, HEAP_ALIGN, @sizeOf(Node) });
    const heapMan: *HeapManager = @alignCast(@ptrCast(ctx));
    if (len > MALLOC_MAXSIZE) {
        std.log.err("allock len:{d} > MALLOC_MAXSIZE:{d}", .{ len, MALLOC_MAXSIZE });
        return null;
    }
    const alignSize = ALIGNE(@as(u32, @truncate(len)));
    std.log.debug("alignSize:{d}", .{alignSize});
    var best: ?*Node = null;
    var node: ?*Node = heapMan.tail;
    var ptr: ?[*]u8 = null;
    while (node) |n| {
        std.log.debug("node:{*}", .{n});
        if (n.used == false and n.size >= alignSize and
            (best == null or best.?.size > n.size))
        {
            best = n;
            if (best.?.size == alignSize) {
                std.log.debug("found align:{d} len:{d}", .{ alignSize, len });
                n.used = true;
                n._align = false;
                ptr = n.getData();
                return ptr;
            }
        }
        node = n.prev;
    }
    if (best == null) {
        std.log.err("alloc failed. len:{d} align:{d}", .{ len, ptr_align });
        return null;
    }
    const _best = best.?;
    if ((_best.size - alignSize) > @sizeOf(Node)) {
        //hole divide into 2
        const nextPtr: [*]u8 = @ptrFromInt(@intFromPtr(_best.getData()) + alignSize);
        std.log.debug("new node:{*}", .{nextPtr});
        const _node: *Node = @alignCast(@ptrCast(nextPtr));
        _node.used = false;
        _node.size = @intCast(@as(u30, @intCast(_best.size)) - alignSize - @as(u32, @truncate(@sizeOf(Node))));
        _node.prev = _best;
        if (best != heapMan.tail) {
            const next = prvGetNext(heapMan, _node);
            if (next) |_next| {
                _next.prev = _node;
            }
        } else {
            heapMan.tail = _node;
        }
        _best.size = @truncate(alignSize);
    }

    _best.used = true;
    _best._align = false;
    ptr = _best.getData();
    std.log.debug("alloc found:{*}", .{ptr});
    return ptr;
}

fn prvGetNext(heapMan: *HeapManager, node: *Node) ?*Node {
    return if (heapMan.tail == node) null else @as(*Node, @alignCast(@ptrCast(node.getData() + node.size)));
}
fn resize(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, ret_addr: usize) bool {

    //Zero-size requests are treated as free.
    if (new_len == 0) {
        free(ctx, buf, buf_align, ret_addr);
        return true;
    }
    var state: u32 = 0;
    var gapSize: u32 = 0;
    var cpySize: u32 = 0;
    {
        try memory.MEM_LOCK(&state);
        defer memory.MEM_UNLOCK(&state) catch unreachable;

        const oldSize = slab.memCheck(ctx, buf);
        if (oldSize != @as(u32, @bitCast(@as(i32, -1)))) {
            cpySize = if (new_len > oldSize) oldSize else @truncate(new_len);
        } else {
            gapSize = @truncate(@intFromPtr(buf.ptr) - @sizeOf(usize));
            if (OS_MEM_GET_ALIGN_FLAG(gapSize)) {
                return false;
            }
            var nodePtr: [*]Node = @alignCast(@ptrCast(buf.ptr));
            nodePtr -= 1;
            const node = &nodePtr[0];
            cpySize = if (new_len > (node.size)) (node.size) else @truncate(new_len);
        }
    }
    const retPtr = alloc(ctx, new_len, buf_align, ret_addr);
    if (retPtr) |ptr| {
        @memcpy(ptr, buf.ptr[0..cpySize]);
        free(ctx, buf, buf_align, ret_addr);
    } else {
        return false;
    }
    return true;
}

pub const OS_MEM_ALIGN_FLAG: u32 = 0x80000000;
pub inline fn OS_MEM_GET_ALIGN_FLAG(_align: u32) bool {
    return _align & OS_MEM_ALIGN_FLAG != 0;
}
pub inline fn OS_MEM_GET_ALIGN_GAPSIZE(_align: u32) u32 {
    return _align & ~OS_MEM_ALIGN_FLAG;
}

fn free(ctx: *anyopaque, buf: []u8, buf_align: u8, ret_addr: usize) void {
    _ = ret_addr;
    std.log.debug("free buf:{*} align:{d}", .{ buf.ptr, buf_align });

    var ptr: [*]u8 = buf.ptr;
    const heapMan: *HeapManager = @alignCast(@ptrCast(ctx));
    //find the real ptr through gap size
    var gapSize: u32 = @truncate(@intFromPtr(buf.ptr) - @sizeOf(usize));
    if (OS_MEM_GET_ALIGN_FLAG(gapSize)) {
        gapSize = OS_MEM_GET_ALIGN_GAPSIZE(gapSize);
        ptr = @ptrCast(ptr - gapSize);
    }
    const ptrInt = @intFromPtr(ptr);
    const headInt = @intFromPtr(heapMan.head.?);
    const tailInt = @intFromPtr(heapMan.tail.?);
    if (ptrInt < headInt or
        ptrInt > (tailInt + @sizeOf(Node)))
    {
        return;
    }
    var nodePtr: [*]Node = @alignCast(@ptrCast(ptr));
    nodePtr -= 1;
    const node = &nodePtr[0];
    if (node.prev) |prev| {
        const nodePrevInt = @intFromPtr(prev);
        if (node.used == false or
            (!(node == heapMan.head.?) and
            nodePrevInt < headInt or
            nodePrevInt > (tailInt + @sizeOf(Node)) or
            (prvGetNext(heapMan, prev).? != node)))
        {
            return;
        }
    }
    doFree(heapMan, node);
}
fn doFree(headMan: *HeapManager, curNode: *Node) void {
    var node = curNode;
    // set to unused status
    node.used = false;
    //unused region before and after combination
    while (node.prev) |prev| {
        if (!prev.used) {
            break;
        }
        node = prev;
    }
    var next: ?*Node = prvGetNext(headMan, node);
    while (next) |_next| {
        if (_next.used) {
            _next.prev = node;
            break;
        }
        node.size += @sizeOf(Node) + _next.size;
        if (headMan.tail == next) {
            headMan.tail = node;
        }
        next = prvGetNext(headMan, node);
    }
}
