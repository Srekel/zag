const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;
usingnamespace @import("../main/util.zig");

pub const systemFunc = fn (self: *SystemSelf, params: VariantMap) void;

pub const SystemFuncDef = struct {
    pass: []const u8,
    phase: u8 = 0,
    run_before: [][]const u8 = [_][]const u8{},
    run_after: [][]const u8 = [_][]const u8{},
    params: [][]const u8 = [_][]const u8{},
    func: systemFunc,
};

pub const SystemSelf = @OpaqueType();
pub const System = struct {
    name: []const u8,
    funcs: []const SystemFuncDef,
    self: *SystemSelf,

    pub fn init(name: []const u8, funcs: []const SystemFuncDef, self: var) System {
        var system = System{
            .name = name,
            .funcs = funcs,
            .self = self,
        };
        return system;
    }
};

pub fn systemFunctionWrap(comptime SystemT: type, comptime sysFunc: var, comptime ContextT: type) fn (self: *SystemSelf, params: VariantMap) void {
    return struct {
        fn func(self: *SystemSelf, params: VariantMap) void {
            var sys = @ptrCast(*SystemT, @alignCast(@alignOf(*SystemT), self));
            var context = fillContext(params, ContextT);
            sysFunc(sys, context);
        }
    }.func;
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
        var params = VariantMap.init(self.allocator);
        params.putNoClobber("allocator", Variant.create_ptr(self.allocator, stringTag("allocator"))) catch unreachable;
        params.putNoClobber("max_entity_count", Variant.create_int(128)) catch unreachable;
        for (self.systems.toSlice()) |system| {
            // params.putNoClobber(system.name, Variant{ .psystem = &system }) catch unreachable;
        }

        for (self.systems.toSlice()) |system| {
            for (system.funcs) |func| {
                if (std.mem.eql(u8, func.pass, pass)) {
                    func.func(system.self, params);
                }
            }
        }
    }

    fn systemSorter(s1: System, s2: System) bool {
        return s1.name[0] < s2.name[0];
    }
};
