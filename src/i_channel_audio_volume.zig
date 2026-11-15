const com = @import("com.zig");
const guid = @import("guid.zig");
const wca = @import("wca.zig");

const GUID = guid.GUID;
const HRESULT = com.HRESULT;

const IChannelAudioVolumeVtbl = extern struct {
    base: com.IUnknownVtbl,
    GetChannelCount: *const fn (*IChannelAudioVolume, *u32) callconv(.winapi) HRESULT,
    SetChannelVolume: *const fn (
        *IChannelAudioVolume,
        u32,
        f32,
        ?*const GUID,
    ) callconv(.winapi) HRESULT,
    GetChannelVolume: *const fn (*IChannelAudioVolume, u32, *f32) callconv(.winapi) HRESULT,
    SetAllVolumes: *const fn (
        *IChannelAudioVolume,
        u32,
        [*]const f32,
        ?*const GUID,
    ) callconv(.winapi) HRESULT,
    GetAllVolumes: *const fn (*IChannelAudioVolume, u32, [*]f32) callconv(.winapi) HRESULT,
};

pub const IChannelAudioVolume = extern struct {
    vtable: *const IChannelAudioVolumeVtbl,

    pub fn release(self: *IChannelAudioVolume) u32 {
        return @as(*com.IUnknown, @ptrCast(self)).release();
    }

    pub fn getChannelCount(self: *IChannelAudioVolume) wca.Error!u32 {
        var count: u32 = 0;
        const hr = self.vtable.GetChannelCount(self, &count);

        try wca.hresultToError(hr);

        return count;
    }

    pub fn setChannelVolume(
        self: *IChannelAudioVolume,
        channel: u32,
        level: f32,
        context: ?*const GUID,
    ) wca.Error!void {
        const hr = self.vtable.SetChannelVolume(self, channel, level, context);

        try wca.hresultToError(hr);
    }

    pub fn getChannelVolume(self: *IChannelAudioVolume, channel: u32) wca.Error!f32 {
        var level: f32 = 0;
        const hr = self.vtable.GetChannelVolume(self, channel, &level);

        try wca.hresultToError(hr);

        return level;
    }

    pub fn setAllVolumes(
        self: *IChannelAudioVolume,
        levels: []const f32,
        context: ?*const GUID,
    ) wca.Error!void {
        const hr = self.vtable.SetAllVolumes(self, @intCast(levels.len), levels.ptr, context);

        try wca.hresultToError(hr);
    }

    pub fn getAllVolumes(self: *IChannelAudioVolume, levels: []f32) wca.Error!void {
        const hr = self.vtable.GetAllVolumes(self, @intCast(levels.len), levels.ptr);

        try wca.hresultToError(hr);
    }
};
