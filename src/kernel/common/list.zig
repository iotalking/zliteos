const std = @import("std");
const config = @import("../../config.zig");
const types = @import("../../utils/types.zig");

pub const DoublyList = struct {
    pstPrev: ?*DoublyList = null,
    pstNext: ?*DoublyList = null,

    pub inline fn init(l: *DoublyList) void {
        l.pstNext = l;
        l.pstPrev = l;
    }
    pub inline fn first(this: *DoublyList) ?*DoublyList {
        return this.pstNext;
    }
    pub inline fn last(this: *DoublyList) ?*DoublyList {
        return this.pstPrev;
    }
    pub fn add(list: *DoublyList, node: *DoublyList) void {
        node.pstNext = list.pstNext;
        node.pstPrev = list;
        if (list.pstNext) |next| {
            // std.log.debug("add", .{});
            next.pstPrev = node;
        }
        list.pstNext = node;
    }
    pub inline fn tailInsert(list: *DoublyList, node: *DoublyList) void {
        if (list.pstPrev) |prev| {
            // std.log.debug("tailInsert", .{});
            prev.add(node);
        }
    }
    pub inline fn headInsert(list: *DoublyList, node: *DoublyList) void {
        list.add(node);
    }
    pub inline fn delete(node: *DoublyList) void {
        if (node.pstNext) |next| {
            next.pstPrev = node.pstPrev;
        }
        if (node.pstPrev) |prev| {
            prev.pstNext = node.pstNext;
        }
        node.pstNext = null;
        node.pstPrev = null;
    }
    pub inline fn empty(list: *DoublyList) bool {
        return list.pstNext == list;
    }

    pub inline fn forEachEntry(list: *DoublyList, T: type, memberName: []const u8, do: *const fn (item: *T, usize, userData: ?*anyopaque) anyerror!void, userData: ?*anyopaque) void {
        if (list.pstNext) |next| {
            var item: *T = @fieldParentPtr(memberName, next);
            var i: usize = 0;
            while (true) {
                const member: *DoublyList = &@field(item, memberName);
                if (member == list) {
                    break;
                }
                do(item, i, userData) catch {
                    break;
                };
                i += 1;
                if (member.pstNext) |_next| {
                    item = @fieldParentPtr(memberName, _next);
                } else {
                    break;
                }
            }
        }
    }
};

test "add" {
    std.testing.log_level = .debug;
    const A = struct {
        list: DoublyList = .{},
        name: []const u8 = "",
    };
    std.log.debug("test add", .{});

    var _list = DoublyList{};
    _list.init();
    _ = _list.first();
    var a = A{
        .name = "a",
    };
    var b = A{
        .name = "b",
    };
    var c = A{
        .name = "c",
    };
    var d = A{
        .name = "d",
    };
    _list.add(&a.list);
    _list.add(&b.list);
    _list.add(&c.list);
    _list.add(&d.list);

    _list.forEachEntry(A, "list", struct {
        fn do(item: *A, i: usize, _: ?*anyopaque) !void {
            var _array = [_][]const u8{ "d", "c", "b", "a" };
            _ = &_array;
            _ = &i;
            std.log.debug("i:{d} {s} {s}", .{ i, item.name, _array[i] });
            try std.testing.expect(std.mem.eql(u8, _array[i], item.name));
        }
    }.do, null);
}

test "tailInsert" {
    std.testing.log_level = .debug;
    const A = struct {
        list: DoublyList = .{},
        name: []const u8 = "",
    };
    var _list = DoublyList{};
    _list.init();
    _ = _list.first();
    var a = A{
        .name = "a",
    };
    var b = A{
        .name = "b",
    };
    var c = A{
        .name = "c",
    };
    var d = A{
        .name = "d",
    };
    std.log.debug("test tailInsert", .{});
    _list.tailInsert(&a.list);
    _list.tailInsert(&b.list);
    _list.tailInsert(&c.list);
    _list.tailInsert(&d.list);
    _list.forEachEntry(A, "list", struct {
        fn do(item: *A, i: usize, _: ?*anyopaque) !void {
            var _array = [_][]const u8{ "a", "b", "c", "d" };
            _ = &_array;
            _ = &i;
            std.log.debug("i:{d} {s} {s}", .{ i, item.name, _array[i] });
            try std.testing.expect(std.mem.eql(u8, _array[i], item.name));
        }
    }.do, null);
}
