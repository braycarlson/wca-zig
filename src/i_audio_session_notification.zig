const com = @import("com.zig");
const guid = @import("guid.zig");
const IAudioSessionControl = @import("i_audio_session_control.zig").IAudioSessionControl;

const GUID = guid.GUID;
const HRESULT = com.HRESULT;

pub const IAudioSessionNotificationVtbl = extern struct {
    QueryInterface: *const fn (
        *IAudioSessionNotification,
        *const GUID,
        *?*anyopaque,
    ) callconv(.winapi) HRESULT,
    AddRef: *const fn (*IAudioSessionNotification) callconv(.winapi) u32,
    Release: *const fn (*IAudioSessionNotification) callconv(.winapi) u32,
    OnSessionCreated: *const fn (
        *IAudioSessionNotification,
        *IAudioSessionControl,
    ) callconv(.winapi) HRESULT,
};

pub const IAudioSessionNotification = extern struct {
    vtable: *const IAudioSessionNotificationVtbl,
};
