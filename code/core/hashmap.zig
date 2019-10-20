// NOTE: Taken from https://github.com/rivten/carbon/blob/master/code/common.zig

pub fn hashmap(comptime V: type) type {
    return struct {
        values: []V,
        keys: []?u64,
        len: usize,
        allocator: *Allocator,

        const Self = @This();

        pub fn init(allocator: *Allocator) Self {
            return Self{
                .values = []align(@alignOf(V)) V{},
                .keys = []align(@alignOf(?u64)) ?u64{},
                .len = 0,
                .allocator = allocator,
            };
        }

        pub fn get(map: *Self, key: u64) ?V {
            if (map.len == 0) {
                return null;
            }
            var i = hash(key);
            while (true) {
                i &= map.values.len - 1;
                if (map.keys[i] == null) {
                    return null;
                } else if (map.keys[i].? == key) {
                    return map.values[i];
                }
                i += 1;
            }
        }

        pub fn put(map: *Self, key: u64, value: V) !void {
            if (2 * map.len >= map.values.len) {
                try map.grow(2 * map.values.len);
            }
            var i: u64 = hash(key);
            while (true) {
                i &= map.values.len - 1;
                if (map.keys[i] == null) {
                    map.len += 1;
                    map.keys[i] = key;
                    map.values[i] = value;
                    return;
                } else if (map.keys[i].? == key) {
                    map.values[i] = value;
                }
                i += 1;
            }
        }

        fn grow(map: *Self, new_cap: usize) !void {
            var cap = std.math.max(new_cap, 16);
            var new_map = Self{
                .allocator = map.allocator,
                .values = try map.allocator.alloc(V, cap),
                .keys = try map.allocator.alloc(?u64, cap),
                .len = map.len,
            };

            for (new_map.keys) |*k| {
                k.* = null;
            }

            for (map.values) |v, i| {
                if (map.keys[i]) |k| {
                    new_map.put(k, v) catch unreachable;
                }
            }

            map.allocator.free(map.values);
            map.allocator.free(map.keys);
            map.* = new_map;
        }

        fn hash(x: u64) u64 {
            var result: u64 = undefined;
            _ = @mulWithOverflow(u64, x, 0xff51afd7ed558ccd, &result);
            result ^= result >> 32;
            return result;
        }
    };
}

test "hash test" {
    var map = hashmap(u64).init(&std.heap.DirectAllocator.init().allocator);
    var i: u64 = 1;
    while (i < 1024) : (i += 1) {
        try map.put(i, i + 1);
    }

    i = 1;
    while (i < 1024) : (i += 1) {
        if (map.get(i)) |v| {
            std.debug.assert(v == i + 1);
        } else {
            unreachable;
        }
    }
}
