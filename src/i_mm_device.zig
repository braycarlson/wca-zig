const std = @import("std");
const com = @import("com.zig");
const guid = @import("guid.zig");
const wca = @import("wca.zig");
const IPropertyStore = @import("i_property_store.zig").IPropertyStore;
const IAudioClient = @import("i_audio_client.zig").IAudioClient;
const IAudioClient2 = @import("i_audio_client2.zig").IAudioClient2;
const IAudioClient3 = @import("i_audio_client3.zig").IAudioClient3;
const IAudioEndpointVolume = @import("i_audio_endpoint_volume.zig").IAudioEndpointVolume;

const GUID = guid.GUID;
const HRESULT = com.HRESULT;

pub const DeviceState = struct {
    pub const Active: u32 = 0x00000001;
    pub const Disabled: u32 = 0x00000002;
    pub const NotPresent: u32 = 0x00000004;
    pub const Unplugged: u32 = 0x00000008;
    pub const All: u32 = 0x0000000F;
};

pub const StorageMode = enum(u32) {
    Read = 0x0,
    Write = 0x1,
    ReadWrite = 0x2,
};

const IMMDeviceVtbl = extern struct {
    base: com.IUnknownVtbl,
    Activate: *const fn (
        *IMMDevice,
        *const GUID,
        u32,
        ?*anyopaque,
        *?*anyopaque,
    ) callconv(.winapi) HRESULT,

    OpenPropertyStore: *const fn (
        *IMMDevice,
        StorageMode,
        *?*IPropertyStore,
    ) callconv(.winapi) HRESULT,

    GetId: *const fn (
        *IMMDevice,
        *?[*:0]u16,
    ) callconv(.winapi) HRESULT,

    GetState: *const fn (
        *IMMDevice,
        *u32,
    ) callconv(.winapi) HRESULT,
};

pub const IMMDevice = extern struct {
    vtable: *const IMMDeviceVtbl,

    pub fn release(self: *IMMDevice) u32 {
        return @as(*com.IUnknown, @ptrCast(self)).release();
    }

    pub fn activate(
        self: *IMMDevice,
        comptime T: type,
        iid: *const GUID,
    ) wca.Error!*T {
        var obj: ?*anyopaque = null;
        const hr = self.vtable.Activate(self, iid, com.CLSCTX_ALL, null, &obj);

        try wca.hresultToError(hr);

        return @ptrCast(@alignCast(obj orelse return wca.Error.Unexpected));
    }

    pub fn activateAudioClient(self: *IMMDevice) wca.Error!*IAudioClient {
        return self.activate(IAudioClient, &guid.IID_IAudioClient);
    }

    pub fn activateAudioClient2(self: *IMMDevice) wca.Error!*IAudioClient2 {
        return self.activate(IAudioClient2, &guid.IID_IAudioClient2);
    }

    pub fn activateAudioClient3(self: *IMMDevice) wca.Error!*IAudioClient3 {
        return self.activate(IAudioClient3, &guid.IID_IAudioClient3);
    }

    pub fn activateEndpointVolume(self: *IMMDevice) wca.Error!*IAudioEndpointVolume {
        return self.activate(IAudioEndpointVolume, &guid.IID_IAudioEndpointVolume);
    }

    pub fn openPropertyStore(self: *IMMDevice, mode: StorageMode) wca.Error!*IPropertyStore {
        var store: ?*IPropertyStore = null;
        const hr = self.vtable.OpenPropertyStore(self, mode, &store);

        try wca.hresultToError(hr);

        return store orelse return wca.Error.Unexpected;
    }

    pub fn getId(self: *IMMDevice, allocator: std.mem.Allocator) wca.Error![]u8 {
        var id_ptr: ?[*:0]u16 = null;
        const hr = self.vtable.GetId(self, &id_ptr);

        try wca.hresultToError(hr);

        if (id_ptr) |ptr| {
            defer com.taskMemFree(@ptrCast(ptr));

            var len: usize = 0;

            while (ptr[len] != 0) : (len += 1) {}

            return std.unicode.utf16LeToUtf8Alloc(allocator, ptr[0..len]) catch {
                return wca.Error.Unexpected;
            };
        }

        return wca.Error.Unexpected;
    }

    pub fn getState(self: *IMMDevice) wca.Error!u32 {
        var state: u32 = 0;
        const hr = self.vtable.GetState(self, &state);

        try wca.hresultToError(hr);

        return state;
    }
};
