const com = @import("com.zig");
const guid = @import("guid.zig");
const wca = @import("wca.zig");

const GUID = guid.GUID;
const HRESULT = com.HRESULT;

const ISimpleAudioVolumeVtbl = extern struct {
    base: com.IUnknownVtbl,
    SetMasterVolume: *const fn (*ISimpleAudioVolume, f32, ?*const GUID) callconv(.winapi) HRESULT,
    GetMasterVolume: *const fn (*ISimpleAudioVolume, *f32) callconv(.winapi) HRESULT,
    SetMute: *const fn (*ISimpleAudioVolume, i32, ?*const GUID) callconv(.winapi) HRESULT,
    GetMute: *const fn (*ISimpleAudioVolume, *i32) callconv(.winapi) HRESULT,
};

pub const ISimpleAudioVolume = extern struct {
    vtable: *const ISimpleAudioVolumeVtbl,

    pub fn release(self: *ISimpleAudioVolume) u32 {
        return @as(*com.IUnknown, @ptrCast(self)).release();
    }

    pub fn setMasterVolume(
        self: *ISimpleAudioVolume,
        level: f32,
        context: ?*const GUID,
    ) wca.Error!void {
        const hr = self.vtable.SetMasterVolume(self, level, context);

        try wca.hresultToError(hr);
    }

    pub fn getMasterVolume(self: *ISimpleAudioVolume) wca.Error!f32 {
        var level: f32 = 0;
        const hr = self.vtable.GetMasterVolume(self, &level);

        try wca.hresultToError(hr);

        return level;
    }

    pub fn setMute(self: *ISimpleAudioVolume, mute: bool, context: ?*const GUID) wca.Error!void {
        const hr = self.vtable.SetMute(self, if (mute) 1 else 0, context);

        try wca.hresultToError(hr);
    }

    pub fn getMute(self: *ISimpleAudioVolume) wca.Error!bool {
        var mute: i32 = 0;
        const hr = self.vtable.GetMute(self, &mute);

        try wca.hresultToError(hr);

        return mute != 0;
    }
};
