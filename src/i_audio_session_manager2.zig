const com = @import("com.zig");
const guid = @import("guid.zig");
const wca = @import("wca.zig");
const IAudioSessionManager = @import("i_audio_session_manager.zig").IAudioSessionManager;
const IAudioSessionControl = @import("i_audio_session_control.zig").IAudioSessionControl;
const IAudioSessionEnumerator = @import("i_audio_session_enumerator.zig").IAudioSessionEnumerator;
const ISimpleAudioVolume = @import("i_simple_audio_volume.zig").ISimpleAudioVolume;

const GUID = guid.GUID;
const HRESULT = com.HRESULT;
const IAudioSessionManagerVtbl = @import("i_audio_session_manager.zig").IAudioSessionManagerVtbl;

pub const IAudioSessionManager2Vtbl = extern struct {
    base: IAudioSessionManagerVtbl,
    GetSessionEnumerator: *const fn (
        *IAudioSessionManager2,
        *?*IAudioSessionEnumerator,
    ) callconv(.winapi) HRESULT,

    RegisterSessionNotification: *const fn (
        *IAudioSessionManager2,
        ?*anyopaque,
    ) callconv(.winapi) HRESULT,

    UnregisterSessionNotification: *const fn (
        *IAudioSessionManager2,
        ?*anyopaque,
    ) callconv(.winapi) HRESULT,

    RegisterDuckNotification: *const fn (
        *IAudioSessionManager2,
        ?[*:0]const u16,
        ?*anyopaque,
    ) callconv(.winapi) HRESULT,

    UnregisterDuckNotification: *const fn (
        *IAudioSessionManager2,
        ?*anyopaque,
    ) callconv(.winapi) HRESULT,
};

pub const IAudioSessionManager2 = extern struct {
    vtable: *const IAudioSessionManager2Vtbl,

    pub fn release(self: *IAudioSessionManager2) u32 {
        return @as(*com.IUnknown, @ptrCast(self)).release();
    }

    pub fn asSessionManager(self: *IAudioSessionManager2) *IAudioSessionManager {
        return @ptrCast(self);
    }

    pub fn getAudioSessionControl(
        self: *IAudioSessionManager2,
        session_guid: ?*const GUID,
        stream_flags: u32,
    ) wca.Error!*IAudioSessionControl {
        return self.asSessionManager().getAudioSessionControl(session_guid, stream_flags);
    }

    pub fn getSimpleAudioVolume(
        self: *IAudioSessionManager2,
        session_guid: ?*const GUID,
        stream_flags: u32,
    ) wca.Error!*ISimpleAudioVolume {
        return self.asSessionManager().getSimpleAudioVolume(session_guid, stream_flags);
    }

    pub fn getSessionEnumerator(self: *IAudioSessionManager2) wca.Error!*IAudioSessionEnumerator {
        var enumerator: ?*IAudioSessionEnumerator = null;
        const hr = self.vtable.GetSessionEnumerator(self, &enumerator);

        try wca.hresultToError(hr);

        return enumerator orelse return wca.Error.Unexpected;
    }

    pub fn registerSessionNotification(
        self: *IAudioSessionManager2,
        notification: ?*anyopaque,
    ) wca.Error!void {
        const hr = self.vtable.RegisterSessionNotification(self, notification);

        try wca.hresultToError(hr);
    }

    pub fn unregisterSessionNotification(
        self: *IAudioSessionManager2,
        notification: ?*anyopaque,
    ) wca.Error!void {
        const hr = self.vtable.UnregisterSessionNotification(self, notification);

        try wca.hresultToError(hr);
    }

    pub fn registerDuckNotification(
        self: *IAudioSessionManager2,
        session_id: ?[*:0]const u16,
        notification: ?*anyopaque,
    ) wca.Error!void {
        const hr = self.vtable.RegisterDuckNotification(self, session_id, notification);

        try wca.hresultToError(hr);
    }

    pub fn unregisterDuckNotification(
        self: *IAudioSessionManager2,
        notification: ?*anyopaque,
    ) wca.Error!void {
        const hr = self.vtable.UnregisterDuckNotification(self, notification);

        try wca.hresultToError(hr);
    }
};
