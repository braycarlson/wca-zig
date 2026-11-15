const std = @import("std");
const com = @import("com.zig");
const guid = @import("guid.zig");
const wca = @import("wca.zig");
const IAudioRenderClient = @import("i_audio_render_client.zig").IAudioRenderClient;
const IAudioCaptureClient = @import("i_audio_capture_client.zig").IAudioCaptureClient;
const IAudioClock = @import("i_audio_clock.zig").IAudioClock;
const ISimpleAudioVolume = @import("i_simple_audio_volume.zig").ISimpleAudioVolume;

const GUID = guid.GUID;
const HRESULT = com.HRESULT;

pub const REFERENCE_TIME = i64;

pub const WAVEFORMATEX = extern struct {
    format_tag: u16,
    channels: u16,
    samples_per_sec: u32,
    byte_rate_avg: u32,
    block_align: u16,
    bits_per_sample: u16,
    cb_size: u16,

    pub fn init(
        channels: u16,
        samples_per_sec: u32,
        bits_per_sample: u16,
    ) WAVEFORMATEX {
        const block_align = (bits_per_sample / 8) * channels;

        return .{
            .format_tag = WAVE_FORMAT_PCM,
            .channels = channels,
            .samples_per_sec = samples_per_sec,
            .byte_rate_avg = samples_per_sec * @as(u32, block_align),
            .block_align = block_align,
            .bits_per_sample = bits_per_sample,
            .cb_size = 0,
        };
    }
};

pub const WAVEFORMATEXTENSIBLE = extern struct {
    format: WAVEFORMATEX,
    samples: extern union {
        valid_bits_per_sample: u16,
        samples_per_block: u16,
        reserved: u16,
    },
    channel_mask: u32,
    sub_format: GUID,
};

pub const WAVE_FORMAT_PCM: u16 = 0x0001;
pub const WAVE_FORMAT_IEEE_FLOAT: u16 = 0x0003;
pub const WAVE_FORMAT_EXTENSIBLE: u16 = 0xFFFE;

pub const KSDATAFORMAT_SUBTYPE_PCM = GUID{
    .data1 = 0x00000001,
    .data2 = 0x0000,
    .data3 = 0x0010,
    .data4 = .{ 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71 },
};

pub const KSDATAFORMAT_SUBTYPE_IEEE_FLOAT = GUID{
    .data1 = 0x00000003,
    .data2 = 0x0000,
    .data3 = 0x0010,
    .data4 = .{ 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71 },
};

pub const FormatSupport = union(enum) {
    exact,
    closest: *WAVEFORMATEX,
};

pub const ShareMode = enum(u32) {
    Shared = 0,
    Exclusive = 1,
};

pub const StreamFlags = struct {
    pub const CrossProcess: u32 = 0x00010000;
    pub const Loopback: u32 = 0x00020000;
    pub const EventCallback: u32 = 0x00040000;
    pub const NoPersist: u32 = 0x00080000;
    pub const RateAdjust: u32 = 0x00100000;
    pub const AutoConvertPcm: u32 = 0x80000000;
    pub const SrcDefaultQuality: u32 = 0x08000000;
};

pub const BufferFlags = struct {
    pub const DataDiscontinuity: u32 = 0x1;
    pub const Silent: u32 = 0x2;
    pub const TimestampError: u32 = 0x4;
};

pub const IAudioClientVtbl = extern struct {
    base: com.IUnknownVtbl,
    Initialize: *const fn (
        *IAudioClient,
        ShareMode,
        u32,
        REFERENCE_TIME,
        REFERENCE_TIME,
        *const WAVEFORMATEX,
        ?*const GUID,
    ) callconv(.winapi) HRESULT,
    GetBufferSize: *const fn (*IAudioClient, *u32) callconv(.winapi) HRESULT,
    GetStreamLatency: *const fn (*IAudioClient, *REFERENCE_TIME) callconv(.winapi) HRESULT,
    GetCurrentPadding: *const fn (*IAudioClient, *u32) callconv(.winapi) HRESULT,
    IsFormatSupported: *const fn (
        *IAudioClient,
        ShareMode,
        *const WAVEFORMATEX,
        *?*WAVEFORMATEX,
    ) callconv(.winapi) HRESULT,
    GetMixFormat: *const fn (*IAudioClient, *?*WAVEFORMATEX) callconv(.winapi) HRESULT,
    GetDevicePeriod: *const fn (
        *IAudioClient,
        ?*REFERENCE_TIME,
        ?*REFERENCE_TIME,
    ) callconv(.winapi) HRESULT,
    Start: *const fn (*IAudioClient) callconv(.winapi) HRESULT,
    Stop: *const fn (*IAudioClient) callconv(.winapi) HRESULT,
    Reset: *const fn (*IAudioClient) callconv(.winapi) HRESULT,
    SetEventHandle: *const fn (*IAudioClient, std.os.windows.HANDLE) callconv(.winapi) HRESULT,
    GetService: *const fn (*IAudioClient, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
};

pub const IAudioClient = extern struct {
    vtable: *const IAudioClientVtbl,

    pub fn release(self: *IAudioClient) u32 {
        return @as(*com.IUnknown, @ptrCast(self)).release();
    }

    pub fn initialize(
        self: *IAudioClient,
        share_mode: ShareMode,
        stream_flags: u32,
        buffer_duration: REFERENCE_TIME,
        periodicity: REFERENCE_TIME,
        format: *const WAVEFORMATEX,
        session_guid: ?*const GUID,
    ) wca.Error!void {
        const hr = self.vtable.Initialize(
            self,
            share_mode,
            stream_flags,
            buffer_duration,
            periodicity,
            format,
            session_guid,
        );

        try wca.hresultToError(hr);
    }

    pub fn getBufferSize(self: *IAudioClient) wca.Error!u32 {
        var size: u32 = 0;
        const hr = self.vtable.GetBufferSize(self, &size);

        try wca.hresultToError(hr);

        return size;
    }

    pub fn getStreamLatency(self: *IAudioClient) wca.Error!REFERENCE_TIME {
        var latency: REFERENCE_TIME = 0;
        const hr = self.vtable.GetStreamLatency(self, &latency);

        try wca.hresultToError(hr);

        return latency;
    }

    pub fn getCurrentPadding(self: *IAudioClient) wca.Error!u32 {
        var padding: u32 = 0;
        const hr = self.vtable.GetCurrentPadding(self, &padding);

        try wca.hresultToError(hr);

        return padding;
    }

    pub fn isFormatSupported(
        self: *IAudioClient,
        share_mode: ShareMode,
        format: *const WAVEFORMATEX,
    ) wca.Error!FormatSupport {
        var closest: ?*WAVEFORMATEX = null;
        const hr = self.vtable.IsFormatSupported(self, share_mode, format, &closest);

        if (hr == 1) {
            if (closest) |match| return .{ .closest = match };
        }

        try wca.hresultToError(hr);

        return .exact;
    }

    pub fn getMixFormat(self: *IAudioClient) wca.Error!*WAVEFORMATEX {
        var format: ?*WAVEFORMATEX = null;
        const hr = self.vtable.GetMixFormat(self, &format);

        try wca.hresultToError(hr);

        return format orelse return wca.Error.Unexpected;
    }

    pub fn getDevicePeriod(
        self: *IAudioClient,
    ) wca.Error!struct { default: REFERENCE_TIME, minimum: REFERENCE_TIME } {
        var default: REFERENCE_TIME = 0;
        var minimum: REFERENCE_TIME = 0;

        const hr = self.vtable.GetDevicePeriod(self, &default, &minimum);

        try wca.hresultToError(hr);

        return .{ .default = default, .minimum = minimum };
    }

    pub fn start(self: *IAudioClient) wca.Error!void {
        const hr = self.vtable.Start(self);

        try wca.hresultToError(hr);
    }

    pub fn stop(self: *IAudioClient) wca.Error!void {
        const hr = self.vtable.Stop(self);

        try wca.hresultToError(hr);
    }

    pub fn reset(self: *IAudioClient) wca.Error!void {
        const hr = self.vtable.Reset(self);

        try wca.hresultToError(hr);
    }

    pub fn setEventHandle(self: *IAudioClient, handle: std.os.windows.HANDLE) wca.Error!void {
        const hr = self.vtable.SetEventHandle(self, handle);

        try wca.hresultToError(hr);
    }

    pub fn getService(self: *IAudioClient, comptime T: type, iid: *const GUID) wca.Error!*T {
        var obj: ?*anyopaque = null;
        const hr = self.vtable.GetService(self, iid, &obj);

        try wca.hresultToError(hr);

        return @ptrCast(@alignCast(obj orelse return wca.Error.Unexpected));
    }

    pub fn getRenderClient(self: *IAudioClient) wca.Error!*IAudioRenderClient {
        return self.getService(IAudioRenderClient, &guid.IID_IAudioRenderClient);
    }

    pub fn getCaptureClient(self: *IAudioClient) wca.Error!*IAudioCaptureClient {
        return self.getService(IAudioCaptureClient, &guid.IID_IAudioCaptureClient);
    }

    pub fn getClock(self: *IAudioClient) wca.Error!*IAudioClock {
        return self.getService(IAudioClock, &guid.IID_IAudioClock);
    }

    pub fn getSimpleVolume(self: *IAudioClient) wca.Error!*ISimpleAudioVolume {
        return self.getService(ISimpleAudioVolume, &guid.IID_ISimpleAudioVolume);
    }
};

pub fn referenceTimeToNs(reference_time: REFERENCE_TIME) i64 {
    return reference_time * 100;
}

pub fn referenceTimeFromNs(ns: i64) REFERENCE_TIME {
    return @divFloor(ns, 100);
}

pub fn referenceTimeToMs(reference_time: REFERENCE_TIME) i64 {
    return @divFloor(reference_time, 10000);
}

pub fn referenceTimeFromMs(ms: i64) REFERENCE_TIME {
    return ms * 10000;
}

pub fn referenceTimeToSeconds(reference_time: REFERENCE_TIME) f64 {
    return @as(f64, @floatFromInt(reference_time)) / 10_000_000.0;
}

pub fn referenceTimeFromSeconds(seconds: f64) REFERENCE_TIME {
    return @intFromFloat(seconds * 10_000_000.0);
}
