const std = @import("std");
const com = @import("com.zig");
const guid = @import("guid.zig");
const wca = @import("wca.zig");
const IAudioSessionControl = @import("i_audio_session_control.zig").IAudioSessionControl;

const GUID = guid.GUID;
const HRESULT = com.HRESULT;
const AudioSessionState = @import("i_audio_session_control.zig").AudioSessionState;
const IAudioSessionControlVtbl = @import("i_audio_session_control.zig").IAudioSessionControlVtbl;

pub const IAudioSessionControl2Vtbl = extern struct {
    base: IAudioSessionControlVtbl,
    GetSessionIdentifier: *const fn (*IAudioSessionControl2, *?[*:0]u16) callconv(.winapi) HRESULT,
    GetSessionInstanceIdentifier: *const fn (
        *IAudioSessionControl2,
        *?[*:0]u16,
    ) callconv(.winapi) HRESULT,
    GetProcessId: *const fn (*IAudioSessionControl2, *u32) callconv(.winapi) HRESULT,
    IsSystemSoundsSession: *const fn (*IAudioSessionControl2) callconv(.winapi) HRESULT,
    SetDuckingPreference: *const fn (*IAudioSessionControl2, i32) callconv(.winapi) HRESULT,
};

pub const IAudioSessionControl2 = extern struct {
    vtable: *const IAudioSessionControl2Vtbl,

    pub fn release(self: *IAudioSessionControl2) u32 {
        return @as(*com.IUnknown, @ptrCast(self)).release();
    }

    pub fn asSessionControl(self: *IAudioSessionControl2) *IAudioSessionControl {
        return @ptrCast(self);
    }

    pub fn getState(self: *IAudioSessionControl2) wca.Error!AudioSessionState {
        return self.asSessionControl().getState();
    }

    pub fn getDisplayName(
        self: *IAudioSessionControl2,
        allocator: std.mem.Allocator,
    ) wca.Error![]u8 {
        return self.asSessionControl().getDisplayName(allocator);
    }

    pub fn getIconPath(self: *IAudioSessionControl2, allocator: std.mem.Allocator) wca.Error![]u8 {
        return self.asSessionControl().getIconPath(allocator);
    }

    pub fn getGroupingParam(self: *IAudioSessionControl2) wca.Error!GUID {
        return self.asSessionControl().getGroupingParam();
    }

    pub fn getSessionIdentifier(
        self: *IAudioSessionControl2,
        allocator: std.mem.Allocator,
    ) wca.Error![]u8 {
        var id_ptr: ?[*:0]u16 = null;
        const hr = self.vtable.GetSessionIdentifier(self, &id_ptr);

        try wca.hresultToError(hr);

        if (id_ptr) |ptr| {
            defer com.taskMemFree(@ptrCast(ptr));

            var len: usize = 0;

            while (ptr[len] != 0) : (len += 1) {}

            return std.unicode.utf16LeToUtf8Alloc(allocator, ptr[0..len]) catch {
                return wca.Error.Unexpected;
            };
        }

        return &.{};
    }

    pub fn getSessionInstanceIdentifier(
        self: *IAudioSessionControl2,
        allocator: std.mem.Allocator,
    ) wca.Error![]u8 {
        var id_ptr: ?[*:0]u16 = null;
        const hr = self.vtable.GetSessionInstanceIdentifier(self, &id_ptr);

        try wca.hresultToError(hr);

        if (id_ptr) |ptr| {
            defer com.taskMemFree(@ptrCast(ptr));

            var len: usize = 0;

            while (ptr[len] != 0) : (len += 1) {}

            return std.unicode.utf16LeToUtf8Alloc(allocator, ptr[0..len]) catch {
                return wca.Error.Unexpected;
            };
        }

        return &.{};
    }

    pub fn getProcessId(self: *IAudioSessionControl2) wca.Error!u32 {
        var pid: u32 = 0;
        const hr = self.vtable.GetProcessId(self, &pid);

        try wca.hresultToError(hr);

        return pid;
    }

    pub fn isSystemSoundsSession(self: *IAudioSessionControl2) wca.Error!bool {
        const hr = self.vtable.IsSystemSoundsSession(self);
        if (hr == 0) return true;
        if (hr == 1) return false;

        try wca.hresultToError(hr);

        return false;
    }

    pub fn setDuckingPreference(self: *IAudioSessionControl2, opt_out: bool) wca.Error!void {
        const hr = self.vtable.SetDuckingPreference(self, if (opt_out) 1 else 0);

        try wca.hresultToError(hr);
    }
};
