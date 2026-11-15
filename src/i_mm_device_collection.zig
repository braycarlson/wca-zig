const com = @import("com.zig");
const wca = @import("wca.zig");
const IMMDevice = @import("i_mm_device.zig").IMMDevice;

const HRESULT = com.HRESULT;

const IMMDeviceCollectionVtbl = extern struct {
    base: com.IUnknownVtbl,
    GetCount: *const fn (*IMMDeviceCollection, *u32) callconv(.winapi) HRESULT,
    Item: *const fn (*IMMDeviceCollection, u32, *?*IMMDevice) callconv(.winapi) HRESULT,
};

pub const IMMDeviceCollection = extern struct {
    vtable: *const IMMDeviceCollectionVtbl,

    pub fn release(self: *IMMDeviceCollection) u32 {
        return @as(*com.IUnknown, @ptrCast(self)).release();
    }

    pub fn getCount(self: *IMMDeviceCollection) wca.Error!u32 {
        var count: u32 = 0;
        const hr = self.vtable.GetCount(self, &count);

        try wca.hresultToError(hr);

        return count;
    }

    pub fn item(self: *IMMDeviceCollection, index: u32) wca.Error!*IMMDevice {
        var device: ?*IMMDevice = null;
        const hr = self.vtable.Item(self, index, &device);

        try wca.hresultToError(hr);

        return device orelse return wca.Error.Unexpected;
    }

    pub fn iterator(self: *IMMDeviceCollection) Iterator {
        return .{ .collection = self, .index = 0 };
    }

    pub const Iterator = struct {
        collection: *IMMDeviceCollection,
        index: u32,

        pub fn next(self: *Iterator) ?*IMMDevice {
            const count = self.collection.getCount() catch return null;
            if (self.index >= count) return null;

            const device = self.collection.item(self.index) catch return null;
            self.index += 1;

            return device;
        }
    };
};
