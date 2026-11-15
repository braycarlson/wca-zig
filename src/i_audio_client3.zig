const std = @import("std");
const com = @import("com.zig");
const guid = @import("guid.zig");
const wca = @import("wca.zig");
const IAudioClient2 = @import("i_audio_client2.zig").IAudioClient2;
const IAudioClient = @import("i_audio_client.zig").IAudioClient;
const IAudioRenderClient = @import("i_audio_render_client.zig").IAudioRenderClient;
const IAudioCaptureClient = @import("i_audio_capture_client.zig").IAudioCaptureClient;
const IAudioClock = @import("i_audio_clock.zig").IAudioClock;
const ISimpleAudioVolume = @import("i_simple_audio_volume.zig").ISimpleAudioVolume;

const GUID = guid.GUID;
const HRESULT = com.HRESULT;
const REFERENCE_TIME = @import("i_audio_client.zig").REFERENCE_TIME;
const WAVEFORMATEX = @import("i_audio_client.zig").WAVEFORMATEX;
const ShareMode = @import("i_audio_client.zig").ShareMode;
const IAudioClient2Vtbl = @import("i_audio_client2.zig").IAudioClient2Vtbl;

pub const IAudioClient3Vtbl = extern struct {
    base: IAudioClient2Vtbl,
    GetSharedModeEnginePeriod: *const fn (
        *IAudioClient3,
        *const WAVEFORMATEX,
        *u32,
        *u32,
        *u32,
        *u32,
    ) callconv(.winapi) HRESULT,

    GetCurrentSharedModeEnginePeriod: *const fn (
        *IAudioClient3,
        *?*WAVEFORMATEX,
        *u32,
    ) callconv(.winapi) HRESULT,

    InitializeSharedAudioStream: *const fn (
        *IAudioClient3,
        u32,
        u32,
        *const WAVEFORMATEX,
        ?*const GUID,
    ) callconv(.winapi) HRESULT,
};

pub const IAudioClient3 = extern struct {
    vtable: *const IAudioClient3Vtbl,

    pub fn release(self: *IAudioClient3) u32 {
        return @as(*com.IUnknown, @ptrCast(self)).release();
    }

    pub fn asAudioClient(self: *IAudioClient3) *IAudioClient {
        return @ptrCast(self);
    }

    pub fn asAudioClient2(self: *IAudioClient3) *IAudioClient2 {
        return @ptrCast(self);
    }

    pub fn initialize(
        self: *IAudioClient3,
        share_mode: ShareMode,
        stream_flags: u32,
        buffer_duration: REFERENCE_TIME,
        periodicity: REFERENCE_TIME,
        format: *const WAVEFORMATEX,
        session_guid: ?*const GUID,
    ) wca.Error!void {
        return self.asAudioClient().initialize(
            share_mode,
            stream_flags,
            buffer_duration,
            periodicity,
            format,
            session_guid,
        );
    }

    pub fn getBufferSize(self: *IAudioClient3) wca.Error!u32 {
        return self.asAudioClient().getBufferSize();
    }

    pub fn getStreamLatency(self: *IAudioClient3) wca.Error!REFERENCE_TIME {
        return self.asAudioClient().getStreamLatency();
    }

    pub fn getCurrentPadding(self: *IAudioClient3) wca.Error!u32 {
        return self.asAudioClient().getCurrentPadding();
    }

    pub fn getMixFormat(self: *IAudioClient3) wca.Error!*WAVEFORMATEX {
        return self.asAudioClient().getMixFormat();
    }

    pub fn getDevicePeriod(
        self: *IAudioClient3,
    ) wca.Error!struct { default: REFERENCE_TIME, minimum: REFERENCE_TIME } {
        const period = try self.asAudioClient().getDevicePeriod();
        return .{ .default = period.default, .minimum = period.minimum };
    }

    pub fn start(self: *IAudioClient3) wca.Error!void {
        return self.asAudioClient().start();
    }

    pub fn stop(self: *IAudioClient3) wca.Error!void {
        return self.asAudioClient().stop();
    }

    pub fn reset(self: *IAudioClient3) wca.Error!void {
        return self.asAudioClient().reset();
    }

    pub fn setEventHandle(self: *IAudioClient3, handle: std.os.windows.HANDLE) wca.Error!void {
        return self.asAudioClient().setEventHandle(handle);
    }

    pub fn getRenderClient(self: *IAudioClient3) wca.Error!*IAudioRenderClient {
        return self.asAudioClient().getRenderClient();
    }

    pub fn getCaptureClient(self: *IAudioClient3) wca.Error!*IAudioCaptureClient {
        return self.asAudioClient().getCaptureClient();
    }

    pub fn getClock(self: *IAudioClient3) wca.Error!*IAudioClock {
        return self.asAudioClient().getClock();
    }

    pub fn getSimpleVolume(self: *IAudioClient3) wca.Error!*ISimpleAudioVolume {
        return self.asAudioClient().getSimpleVolume();
    }

    pub fn getSharedModeEnginePeriod(
        self: *IAudioClient3,
        format: *const WAVEFORMATEX,
    ) wca.Error!struct {
        period_frames_default: u32,
        period_frames_fundamental: u32,
        period_frames_min: u32,
        period_frames_max: u32,
    } {
        var default: u32 = 0;
        var fundamental: u32 = 0;
        var min: u32 = 0;
        var max: u32 = 0;

        const hr = self.vtable.GetSharedModeEnginePeriod(
            self,
            format,
            &default,
            &fundamental,
            &min,
            &max,
        );

        try wca.hresultToError(hr);

        return .{
            .period_frames_default = default,
            .period_frames_fundamental = fundamental,
            .period_frames_min = min,
            .period_frames_max = max,
        };
    }

    pub fn getCurrentSharedModeEnginePeriod(self: *IAudioClient3) wca.Error!struct {
        format: *WAVEFORMATEX,
        period_frames_current: u32,
    } {
        var format: ?*WAVEFORMATEX = null;
        var period: u32 = 0;
        const hr = self.vtable.GetCurrentSharedModeEnginePeriod(self, &format, &period);

        try wca.hresultToError(hr);

        return .{
            .format = format orelse return wca.Error.Unexpected,
            .period_frames_current = period,
        };
    }

    pub fn initializeSharedAudioStream(
        self: *IAudioClient3,
        stream_flags: u32,
        period_in_frames: u32,
        format: *const WAVEFORMATEX,
        session_guid: ?*const GUID,
    ) wca.Error!void {
        const hr = self.vtable.InitializeSharedAudioStream(
            self,
            stream_flags,
            period_in_frames,
            format,
            session_guid,
        );

        try wca.hresultToError(hr);
    }
};
