const std = @import("std");
const config = @import("../../config.zig");
const types = @import("../../utils/types.zig");
const list = @import("../common/list.zig");
// typedef struct tagEvent {
//     UINT32 uwEventID;        /**< Event mask in the event control block,
//                                   indicating the event that has been logically processed. */
//     LOS_DL_LIST stEventList; /**< Event control block linked list */
// } EVENT_CB_S, *PEVENT_CB_S;
pub const EventCallback = struct {
    uwEventID: u32 = 0, //Event mask in the event control block,
    //                    indicating the event that has been logically processed.
    stEventList: list.DoublyList = .{}, //Event control block linked list
};
