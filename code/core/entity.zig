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

const EntityCreateCallback = struct {
    user_data: Variant,
    pass: u8,
    component_tags: []Tag,
    component_indices: []u16 = undefined,
    component_variants: []Variant = undefined,
};

const EntityCreateData = struct {
    count: u64,
    component_datas: EntityComponentDataList,
};

const EntityDestroyData = struct {
    tag: Tag,
    entities: ArrayList(Entity),
    pub fn init(allocator: *Allocator, tag: Tag, once: bool) EntityDestroyData {
        return .{
            .tag = tag,
            .entities = ArrayList(Entity).init(allocator),
            .allocator = allocator,
        };
    }
    pub fn deinit(self: *EntityDestroyData) void {
        self.entities.free();
    }
};

const EntityDestroyData = struct {
    entities: std.ArrayList(Entity),
};

const ComponentCreateData = struct {
    entities: std.ArrayList(Entity),
    component_data: std.ArrayList(u8),
    components:Variant,
    tag: FullTag,
    pub fn init(tag_string:String, allocator:*Allocator) ComponentCreateData{
        var component_data = ArrayList(u8).init(Allocator);
        var tag = FullTag.init(tag_string);
        return .{
            .entities = ArrayList(Entity).init(allocator),
            .component_data = component_data,
            .component = Variant.create_slice(component_data.toSlice(), tag.tag),
            .tag = tag,
        };
    }
};

const EntityManager = struct {
    max_entity_count: Entity,
    idlol: Entity = 1,
    create_data: [2]EntityCreateData,
    destroy_data: [2]EntityDestroyData,
    entities_to_create: []std.ArrayList(Entity),
    entities_to_destroy: []std.ArrayList(Entity),
    comps_to_create: std.ArrayList(ComponentCreateData),
    entity_create_callbacks: std.ArrayList(EntityCreateCallback),
    allocator: *Allocator,
    max_passes = 0,
    passes: []std.ArrayList(entityCreateBakeFunc),
    entity_create_buffers: DoubleBuffer(ArrayList(EntityCreateData)),
    entity_destroy_buffers: DoubleBuffer(EntityDestroyData),

    pub fn init(allocator: *Allocator) !EntityManager {
        return try EntityManager{
            .allocator = allocator,
            .entity_create_buffers = DoubleBuffer(Variant).init(allocator),
            .entity_destroy_buffers = DoubleBuffer(EntityDestroyData).init(allocator),
        };
    }

    pub fn deinit(self: EntityManager) void {
        self.entity_create_buffers.deinit();
    }

    pub fn registerComponent(self: *EntityManager, comptime CompT: type, tag_string: String) void {
        for (self.entity_create_buffers.buffers) |buf| {
            var comp_create_data = EntityCreateData.init(CompT, tag_string, self.allocator);
            buf.add(comp_create_data);
        }
    }

    // pub fn addEntitiesDestroyedNotification(self: *EntityManager, entities: []Entity, tag: Tag) void {}

    // pub fn registerCreateCallback(self: *EntityManager, comptime CompT: type, callback: EntityCreateCallback) void {
    //     var component_indices = self.allocator.alloc(u16, callback.component_tags.len);
    //     var component_variants = self.allocator.alloc(Variant, callback.component_tags.len);
    //     var component_count = 0;
    //     for (self.comps_to_create) |variant, index| {
    //         if (variant.tag == callback.component_tag) {
    //             component_indices[component_count] = index;
    //             component_variants[component_count] = variant;
    //             component_count += 1;
    //         }
    //     }asdas
    //     assert(component_count == callback.component_tags.len);
    // sadfdadasdas
    //     for (self.entity_create_callbacks) |cb, index| {
    //         if (callback.pass < cb.pass) {
    //             var cb_new = callback;
    //             cb_new.component_indices = component_indices;
    //             cb_new.component_variants = component_variants;
    //             self.entity_create_callbacks.insert(index, callback);
    //             return;
    //         }
    //     }

    //     var cb_new = callback;
    //     cb_new.component_indices = component_indices;
    //     cb_new.component_variants = component_variants;
    //     self.entity_create_callbacks.append(cb_new);
    // }

    pub fn commitPending(self: *EntityManager) void {
        while (self.entity_destroy_buffers.currHasData() || self.entity_create_buffers.currHasData()) {
            while (self.entities_to_destroy.count() > 0) {
                // while (self.entity_destroy_buffers.currHasData()) {
                for (self.comp_datas) |comp| {
                    comp.destroyed_entities.resize(0);
                    for (self.entities_to_destroy) |ent| {
                        if (comp.tracked_entities[ent]) {
                            comp.destroyed_entities.append(ent);
                        }
                    }
                }
                self.entities_to_destroy.resize(0);

                var params = VariantMap.init(self.allocator);
                params.putNoClobber("allocator", Variant.create_ptr(self.allocator, 0));
                for (self.comp_datas) |comp| {
                    params.putNoClobber(comp.tag, Variant.create_slice(comp.destroyed_entities.toSlice(), comp.tag));
                }
                self.system_manager.runSystemFunc("destroyEntities", params);
            }

            while (self.entity_create_buffers.currHasData()) {
                var create_datas = self.entity_create_buffers.currSlice();
                self.entity_create_buffers.swap();

                var params = VariantMap.init(self.allocator);
                params.putNoClobber("allocator", self.allocator);
                for (self.entity_create_buffers.currSlice()) |comp_variant| {
                    params.putNoClobber(comp_create_data.components.tag, comp_create_data);
                }
                self.system_manager.runSystemFunc("createEntities", params);
            }
        }
    }

    // fn createEntities(hierarchy: EntityCreateHierarchy, comp_datas: []EntityComponentDataList, out_ents: []Entity) void {
    //     for (out_ents) |*ent| {
    //         ent.* = idlol;
    //         idlol += 1;
    //     }

    //     var pass_max = 0;
    //     for (comp_datas) |data| {
    //         var entityCreate = self.funcs.get(data.hash);
    //         if (entityCreate.pass > pass_max) {
    //             pass_max = entityCreate.pass;
    //         }
    //     }

    //     // self.id_store.generate(out_ents);
    //     for (hierarchy.depth_offsets) |depth_offset, depth| {
    //         var pass = 0;
    //         while (pass <= pass_max) {
    //             for (comp_datas) |data| {
    //                 // TODO: Sort?
    //                 var entityCreate = self.funcs.get(data.id);
    //                 if (entityCreate.pass != pass) {
    //                     continue;
    //                 }

    //                 var ents: []Entity = self.allocator.alloc(Entity, data.tmp_ids);
    //                 for (ents) |*ent| {
    //                     ent.* = out_ents[ent.*];
    //                 }
    //                 entityCreate(sys, params, ents, data_list);
    //                 self.allocator.free(ents);
    //             }
    //             pass += 1;
    //         }
    //     }
    // }

    fn createEntities(self:*EntityManager, defs:[]EntityDef)void{
                var buf = self.entity_create_buffers.front();
        for (defs)|def|{
            for (def.components)|comp|{
                var comp_data = buf.comp_datas.get(comp.tag);
                comp_data.component_datas
            }
        }
    }

    fn destroyEntities(self: *EntityManager, entities: []Entity) void {
        self.entities_to_destroy.add(entities);
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
