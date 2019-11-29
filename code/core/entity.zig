const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;
usingnamespace @import("../main/util.zig");
const system = @import("system.zig");

const EntityComponentDataList = struct {
    hash: Hash,
    tmp_ids: []Entity,
    data_list: Variant,
};

const EntityCreateHierarchy = struct {
    tmp_ids: []Entity,
    child_offsets: []u32,
    child_counts: []u32,
    depth_offsets: []u32,
};

const entityCreateBakeFunc = fn (sys: *system.SystemSelf, params: VariantMap, ents: []Entity, data: EntityComponentDataList) void;
pub fn entityCreateWrapper(comptime SystemT: type, comptime sysFunc: var, comptime ContextT: type, comptime DataT: type) entityCreateBakeFunc {
    return struct {
        fn func(self: *system.SystemSelf, params: VariantMap, ents: []Entity, data: EntityComponentDataList) void {
            var sys = @ptrCast(*SystemT, @alignCast(@alignOf(*SystemT), self));
            var context = fillContext(params, ContextT);
            var dataSlice = data.data_list.get_slice(DataT, TagUnset);
            sysFunc(sys, context, ents, dataSlice);
        }
    }.func;
}

const EntityManager = struct {
    max_entity_count: Entity,
    idlol: Entity = 1,
    entities_to_create: []std.ArrayList(Entity),
    comps_to_create: std.ArrayList(Variant),
    entity_create_callbacks: std.ArrayList(EntityCreateCallback),
    allocator: *Allocator,
    max_passes = 0,
    passes: []std.ArrayList(entityCreateBakeFunc),

    pub fn registerComponent(self: *EntityManager, comptime CompT: type) void {
        var comps = self.allocator.alloc(CompT, max_entity_count);
        var comp_var: Variant = Variant.set_slice(comps, CompT, stringTag(@typeName(CompT)));
        self.comps_to_create.add(comp_var);
    }

    pub fn registerCreateCallback(self: *EntityManager, comptime CompT: type, callback: EntityCreateCallback) void {
        var component_index = std.math.maxInt(u16);
        for (self.comps_to_create) |variant, index| {
            if (variant.tag == callback.component_tag) {
                component_index = index;
            }
        }
        assert(component_index != std.math.maxInt(u16));

        for (self.entity_create_callbacks) |cb, index| {
            if (callback.pass < cb.pass) {
                var cb_new = callback;
                cb_new.index = component_index;
                self.entity_create_callbacks.insert(index, callback);
                return;
            }
        }

        var cb_new = callback;
        cb_new.index = component_index;
        self.entity_create_callbacks.append(cb_new);
        var comps = self.allocator.alloc(CompT, max_entity_count);
        var comp_var: Variant = Variant.set_slice(comps, TagUnset);
        self.comps_to_create.add(comp_var);
    }

    pub fn createEntities(self: *EntityManager) void {
        for (self.entity_create_callbacks) |callback| {
            var variant = self.comps_to_create[callback.component_index];
            if (variant.count == 0) {
                continue;
            }

            callback.func(callback.system, params, variant.get_slice());
        }
    }

    fn createEntities(hierarchy: EntityCreateHierarchy, comp_datas: []EntityComponentDataList, out_ents: []Entity) void {
        for (out_ents) |*ent| {
            ent.* = idlol;
            idlol += 1;
        }

        var pass_max = 0;
        for (comp_datas) |data| {
            var entityCreate = self.funcs.get(data.hash);
            if (entityCreate.pass > pass_max) {
                pass_max = entityCreate.pass;
            }
        }

        // self.id_store.generate(out_ents);
        for (hierarchy.depth_offsets) |depth_offset, depth| {
            var pass = 0;
            while (pass <= pass_max) {
                for (comp_datas) |data| {
                    // TODO: Sort?
                    var entityCreate = self.funcs.get(data.id);
                    if (entityCreate.pass != pass) {
                        continue;
                    }

                    var ents: []Entity = self.allocator.alloc(Entity, data.tmp_ids);
                    for (ents) |*ent| {
                        ent.* = out_ents[ent.*];
                    }
                    entityCreate(sys, params, ents, data_list);
                    self.allocator.free(ents);
                }
                pass += 1;
            }
        }
    }
};

fn lol() void {
    // var hierarchy = EntityCreateHierarchy {
    //     tmp_ids = 0,
    // }
    // var comp_datas = EntityComponentDataList{
    //     .hash = stringHash("transform"),
    //     .tmp_ids = {1},
    //     .data_list = {Variant.create_slice(math3d.Mat4.identity())},
    // };
    var entity_def = EntityDef{
        .components = .{
            .{
                .hash = stringHash("transform"),
                .value = Variant.set_ptr(&math3d.Mat4.identity()),
            },
            .{
                .hash = stringHash("model"),
                .value = Variant.set_slice("models/lol.model"),
            },
        },
        .child_entities = .{
            .components = .{
                .{
                    .hash = stringHash("transform"),
                    .value = math3d.Mat4.identity(),
                },
            },
        },
    };

    var init_data = entity_def.compile(allocator);

    entity_manager.createEntities(init_data);
    //  entity_manager.createEntities(hierarchy, comp_datas, out_ents);
}
