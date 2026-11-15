const std = @import("std");
const com = @import("com.zig");
const guid = @import("guid.zig");
const wca = @import("wca.zig");

const GUID = guid.GUID;
const HRESULT = com.HRESULT;

pub const AudioSessionState = enum(u32) {
    Inactive = 0,
    Active = 1,
    Expired = 2,
};

pub const IAudioSessionControlVtbl = extern struct {
    base: com.IUnknownVtbl,
    GetState: *const fn (*IAudioSessionControl, *AudioSessionState) callconv(.winapi) HRESULT,
    GetDisplayName: *const fn (*IAudioSessionControl, *?[*:0]u16) callconv(.winapi) HRESULT,
    SetDisplayName: *const fn (
        *IAudioSessionControl,
        [*:0]const u16,
        ?*const GUID,
    ) callconv(.winapi) HRESULT,
    GetIconPath: *const fn (*IAudioSessionControl, *?[*:0]u16) callconv(.winapi) HRESULT,
    SetIconPath: *const fn (
        *IAudioSessionControl,
        [*:0]const u16,
        ?*const GUID,
    ) callconv(.winapi) HRESULT,
    GetGroupingParam: *const fn (*IAudioSessionControl, *GUID) callconv(.winapi) HRESULT,
    SetGroupingParam: *const fn (
        *IAudioSessionControl,
        *const GUID,
        ?*const GUID,
    ) callconv(.winapi) HRESULT,

    RegisterAudioSessionNotification: *const fn (
        *IAudioSessionControl,
        ?*anyopaque,
    ) callconv(.winapi) HRESULT,

    UnregisterAudioSessionNotification: *const fn (
        *IAudioSessionControl,
        ?*anyopaque,
    ) callconv(.winapi) HRESULT,
};

pub const IAudioSessionControl = extern struct {
    vtable: *const IAudioSessionControlVtbl,

    pub fn release(self: *IAudioSessionControl) u32 {
        return @as(*com.IUnknown, @ptrCast(self)).release();
    }

    pub fn getState(self: *IAudioSessionControl) wca.Error!AudioSessionState {
        var state: AudioSessionState = .Inactive;
        const hr = self.vtable.GetState(self, &state);

        try wca.hresultToError(hr);

        return state;
    }

    pub fn getDisplayName(
        self: *IAudioSessionControl,
        allocator: std.mem.Allocator,
    ) wca.Error![]u8 {
        var name_ptr: ?[*:0]u16 = null;
        const hr = self.vtable.GetDisplayName(self, &name_ptr);

        try wca.hresultToError(hr);

        if (name_ptr) |ptr| {
            defer com.taskMemFree(@ptrCast(ptr));

            var len: usize = 0;

            while (ptr[len] != 0) : (len += 1) {}

            return std.unicode.utf16LeToUtf8Alloc(allocator, ptr[0..len]) catch {
                return wca.Error.Unexpected;
            };
        }

        return &.{};
    }

    pub fn getIconPath(self: *IAudioSessionControl, allocator: std.mem.Allocator) wca.Error![]u8 {
        var path_ptr: ?[*:0]u16 = null;
        const hr = self.vtable.GetIconPath(self, &path_ptr);

        try wca.hresultToError(hr);

        if (path_ptr) |ptr| {
            defer com.taskMemFree(@ptrCast(ptr));

            var len: usize = 0;

            while (ptr[len] != 0) : (len += 1) {}

            return std.unicode.utf16LeToUtf8Alloc(allocator, ptr[0..len]) catch {
                return wca.Error.Unexpected;
            };
        }

        return &.{};
    }

    pub fn getGroupingParam(self: *IAudioSessionControl) wca.Error!GUID {
        var param: GUID = undefined;
        const hr = self.vtable.GetGroupingParam(self, &param);

        try wca.hresultToError(hr);

        return param;
    }

    pub fn setGroupingParam(
        self: *IAudioSessionControl,
        param: *const GUID,
        context: ?*const GUID,
    ) wca.Error!void {
        const hr = self.vtable.SetGroupingParam(self, param, context);

        try wca.hresultToError(hr);
    }
};
