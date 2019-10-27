const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const zero_struct = @import("util.zig").zero_struct;
const Allocator = std.mem.Allocator;

pub const SystemParam = struct {
    lol: i32 = 0,
    // value: union {
    //     // buf_u8: *[]u8 = ,
    //     ptr_i32: i32,
    // },
};

pub const systemFunc = fn (params: []const SystemParam) void;

pub const SystemFuncDef = struct {
    pass: []const u8,
    phase: u8 = 0,
    run_before: [][]const u8 = [_][]const u8{},
    run_after: [][]const u8 = [_][]const u8{},
    // params: stretchy_buffer.stretchy_buffer(SystemParam),
    func: systemFunc,
};

pub const System = struct {
    name: []const u8,
    funcs: []const SystemFuncDef,

    pub fn init(name: []const u8, funcs: []const SystemFuncDef, allocator: *Allocator) System {
        var system = System{
            .name = name,
            .funcs = funcs,
        };

        // system.name = try allocator.alloc(u8, name.len);
        // std.mem.copy(u8, system.name[0..], name[0..]);
        return system;
    }
};

// pub const System = struct {
//     name: []u8,
//     funcs: stretchy_buffer.stretchy_buffer(SystemFuncDef),

//     pub fn init(name: []u8, allocator: *Allocator) System {
//         var system = System{
//             .name = name,
//             .funcs = stretchy_buffer.stretchy_buffer(SystemFuncDef).init(allocator),
//         };
//         return system;
//     }
// };

fn systemSorter(s1: System, s2: System) bool {
    return s1.name[0] < s2.name[0];
}

pub const SystemManager = struct {
    systems: std.ArrayList(System),
    allocator: *Allocator,

    pub fn init(allocator: *Allocator) SystemManager {
        var sm = SystemManager{
            .allocator = allocator,
            .systems = std.ArrayList(System).init(allocator),
        };
        return sm;
    }

    pub fn deinit(self: *SystemManager) void {}

    pub fn registerAllSystems(self: *SystemManager, systems: []const System) void {
        var err = self.systems.appendSlice(systems);
        std.sort.sort(System, self.systems.toSlice(), systemSorter);
    }

    pub fn runSystemFunc(self: *SystemManager, pass: []const u8) void {
        for (self.systems.toSlice()) |system| {
            for (system.funcs) |func| {
                if (std.mem.eql(u8, func.pass, pass)) {
                    var params: [0]SystemParam = undefined;
                    func.func(params);
                }
            }
        }
    }
};
