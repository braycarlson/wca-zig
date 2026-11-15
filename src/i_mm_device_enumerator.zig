const com = @import("com.zig");
const guid = @import("guid.zig");
const wca = @import("wca.zig");
const IMMDevice = @import("i_mm_device.zig").IMMDevice;
const IMMDeviceCollection = @import("i_mm_device_collection.zig").IMMDeviceCollection;

const HRESULT = com.HRESULT;

pub const EDataFlow = enum(u32) {
    Render = 0,
    Capture = 1,
    All = 2,
};

pub const ERole = enum(u32) {
    Console = 0,
    Multimedia = 1,
    Communications = 2,
};

const IMMDeviceEnumeratorVtbl = extern struct {
    base: com.IUnknownVtbl,
    EnumAudioEndpoints: *const fn (
        *IMMDeviceEnumerator,
        EDataFlow,
        u32,
        *?*IMMDeviceCollection,
    ) callconv(.winapi) HRESULT,

    GetDefaultAudioEndpoint: *const fn (
        *IMMDeviceEnumerator,
        EDataFlow,
        ERole,
        *?*IMMDevice,
    ) callconv(.winapi) HRESULT,

    GetDevice: *const fn (
        *IMMDeviceEnumerator,
        ?[*:0]const u16,
        *?*IMMDevice,
    ) callconv(.winapi) HRESULT,

    RegisterEndpointNotificationCallback: *const fn (
        *IMMDeviceEnumerator,
        ?*anyopaque,
    ) callconv(.winapi) HRESULT,

    UnregisterEndpointNotificationCallback: *const fn (
        *IMMDeviceEnumerator,
        ?*anyopaque,
    ) callconv(.winapi) HRESULT,
};

pub const IMMDeviceEnumerator = extern struct {
    vtable: *const IMMDeviceEnumeratorVtbl,

    pub fn create() !*IMMDeviceEnumerator {
        return com.createInstance(
            IMMDeviceEnumerator,
            &guid.CLSID_MMDeviceEnumerator,
            &guid.IID_IMMDeviceEnumerator,
        );
    }

    pub fn release(self: *IMMDeviceEnumerator) u32 {
        return @as(*com.IUnknown, @ptrCast(self)).release();
    }

    pub fn enumAudioEndpoints(
        self: *IMMDeviceEnumerator,
        data_flow: EDataFlow,
        state_mask: u32,
    ) wca.Error!*IMMDeviceCollection {
        var collection: ?*IMMDeviceCollection = null;
        const hr = self.vtable.EnumAudioEndpoints(self, data_flow, state_mask, &collection);

        try wca.hresultToError(hr);

        return collection orelse return wca.Error.Unexpected;
    }

    pub fn getDefaultAudioEndpoint(
        self: *IMMDeviceEnumerator,
        data_flow: EDataFlow,
        role: ERole,
    ) wca.Error!*IMMDevice {
        var device: ?*IMMDevice = null;
        const hr = self.vtable.GetDefaultAudioEndpoint(self, data_flow, role, &device);

        try wca.hresultToError(hr);

        return device orelse return wca.Error.Unexpected;
    }

    pub fn getDevice(self: *IMMDeviceEnumerator, device_id: [*:0]const u16) wca.Error!*IMMDevice {
        var device: ?*IMMDevice = null;
        const hr = self.vtable.GetDevice(self, device_id, &device);

        try wca.hresultToError(hr);

        return device orelse return wca.Error.Unexpected;
    }

    pub fn registerEndpointNotificationCallback(
        self: *IMMDeviceEnumerator,
        client: *anyopaque,
    ) wca.Error!void {
        const hr = self.vtable.RegisterEndpointNotificationCallback(self, client);

        try wca.hresultToError(hr);
    }

    pub fn unregisterEndpointNotificationCallback(
        self: *IMMDeviceEnumerator,
        client: *anyopaque,
    ) wca.Error!void {
        const hr = self.vtable.UnregisterEndpointNotificationCallback(self, client);

        try wca.hresultToError(hr);
    }
};
