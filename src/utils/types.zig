const std = @import("std");
pub fn TypeIf(T: type, comptime on: bool) type {
    return if (on) T else void;
}
pub fn ValueIf(val: anytype, comptime on: bool) if (on) @TypeOf(val) else void {
    return if (on) val else {};
}
pub fn TypeIfElse(T: type, T2: type, comptime on: bool) type {
    return if (on) T else T2;
}
pub fn ValueIfElse(val: anytype, val2: anytype, comptime on: bool) if (on) @TypeOf(val) else @TypeOf(val2) {
    return if (on) val else val2;
}
