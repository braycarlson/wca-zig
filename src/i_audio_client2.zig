const std = @import("std");
const com = @import("com.zig");
const guid = @import("guid.zig");
const wca = @import("wca.zig");
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
const IAudioClientVtbl = @import("i_audio_client.zig").IAudioClientVtbl;

pub const AudioClientProperties = extern struct {
    cb_size: u32,
    is_offload: i32,
    category: AudioStreamCategory,
    options: AudioClientStreamOptions,
};

pub const AudioStreamCategory = enum(u32) {
    Other = 0,
    ForegroundOnlyMedia = 1,
    Communications = 3,
    Alerts = 4,
    SoundEffects = 5,
    GameEffects = 6,
    GameMedia = 7,
    GameChat = 8,
    Speech = 9,
    Movie = 10,
    Media = 11,
    FarFieldSpeech = 12,
    UniformSpeech = 13,
    VoiceTyping = 14,
};

pub const AudioClientStreamOptions = enum(u32) {
    None = 0,
    Raw = 1,
    MatchFormat = 2,
    Ambisonics = 4,
};

pub const IAudioClient2Vtbl = extern struct {
    base: IAudioClientVtbl,
    IsOffloadCapable: *const fn (*IAudioClient2, u32, *i32) callconv(.winapi) HRESULT,
    SetClientProperties: *const fn (
        *IAudioClient2,
        *const AudioClientProperties,
    ) callconv(.winapi) HRESULT,

    GetBufferSizeLimits: *const fn (
        *IAudioClient2,
        *const WAVEFORMATEX,
        i32,
        *REFERENCE_TIME,
        *REFERENCE_TIME,
    ) callconv(.winapi) HRESULT,
};

pub const IAudioClient2 = extern struct {
    vtable: *const IAudioClient2Vtbl,

    pub fn release(self: *IAudioClient2) u32 {
        return @as(*com.IUnknown, @ptrCast(self)).release();
    }

    pub fn asAudioClient(self: *IAudioClient2) *IAudioClient {
        return @ptrCast(self);
    }

    pub fn initialize(
        self: *IAudioClient2,
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

    pub fn getBufferSize(self: *IAudioClient2) wca.Error!u32 {
        return self.asAudioClient().getBufferSize();
    }

    pub fn getStreamLatency(self: *IAudioClient2) wca.Error!REFERENCE_TIME {
        return self.asAudioClient().getStreamLatency();
    }

    pub fn getCurrentPadding(self: *IAudioClient2) wca.Error!u32 {
        return self.asAudioClient().getCurrentPadding();
    }

    pub fn getMixFormat(self: *IAudioClient2) wca.Error!*WAVEFORMATEX {
        return self.asAudioClient().getMixFormat();
    }

    pub fn getDevicePeriod(
        self: *IAudioClient2,
    ) wca.Error!struct { default: REFERENCE_TIME, minimum: REFERENCE_TIME } {
        const period = try self.asAudioClient().getDevicePeriod();
        return .{ .default = period.default, .minimum = period.minimum };
    }

    pub fn start(self: *IAudioClient2) wca.Error!void {
        return self.asAudioClient().start();
    }

    pub fn stop(self: *IAudioClient2) wca.Error!void {
        return self.asAudioClient().stop();
    }

    pub fn reset(self: *IAudioClient2) wca.Error!void {
        return self.asAudioClient().reset();
    }

    pub fn setEventHandle(self: *IAudioClient2, handle: std.os.windows.HANDLE) wca.Error!void {
        return self.asAudioClient().setEventHandle(handle);
    }

    pub fn getRenderClient(self: *IAudioClient2) wca.Error!*IAudioRenderClient {
        return self.asAudioClient().getRenderClient();
    }

    pub fn getCaptureClient(self: *IAudioClient2) wca.Error!*IAudioCaptureClient {
        return self.asAudioClient().getCaptureClient();
    }

    pub fn getClock(self: *IAudioClient2) wca.Error!*IAudioClock {
        return self.asAudioClient().getClock();
    }

    pub fn getSimpleVolume(self: *IAudioClient2) wca.Error!*ISimpleAudioVolume {
        return self.asAudioClient().getSimpleVolume();
    }

    pub fn isOffloadCapable(self: *IAudioClient2, category: u32) wca.Error!bool {
        var capable: i32 = 0;
        const hr = self.vtable.IsOffloadCapable(self, category, &capable);

        try wca.hresultToError(hr);

        return capable != 0;
    }

    pub fn setClientProperties(
        self: *IAudioClient2,
        properties: *const AudioClientProperties,
    ) wca.Error!void {
        const hr = self.vtable.SetClientProperties(self, properties);

        try wca.hresultToError(hr);
    }

    pub fn getBufferSizeLimits(
        self: *IAudioClient2,
        format: *const WAVEFORMATEX,
        event_driven: bool,
    ) wca.Error!struct { min: REFERENCE_TIME, max: REFERENCE_TIME } {
        var min: REFERENCE_TIME = 0;
        var max: REFERENCE_TIME = 0;

        const hr = self.vtable.GetBufferSizeLimits(
            self,
            format,
            if (event_driven) 1 else 0,
            &min,
            &max,
        );

        try wca.hresultToError(hr);

        return .{ .min = min, .max = max };
    }
};
