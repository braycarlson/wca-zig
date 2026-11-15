const std = @import("std");

pub const com = @import("com.zig");
pub const guid = @import("guid.zig");
pub const property = @import("property.zig");

pub const IMMDeviceEnumerator = @import("i_mm_device_enumerator.zig").IMMDeviceEnumerator;
pub const IMMDevice = @import("i_mm_device.zig").IMMDevice;
pub const IMMDeviceCollection = @import("i_mm_device_collection.zig").IMMDeviceCollection;
pub const IMMEndpoint = @import("i_mm_endpoint.zig").IMMEndpoint;
pub const IMMNotificationClient = @import("i_mm_notification_client.zig").IMMNotificationClient;

pub const IMMNotificationClientCallback =
    @import("i_mm_notification_client.zig").IMMNotificationClientCallback;

pub const IPropertyStore = @import("i_property_store.zig").IPropertyStore;

pub const IAudioClient = @import("i_audio_client.zig").IAudioClient;
pub const IAudioClient2 = @import("i_audio_client2.zig").IAudioClient2;
pub const IAudioClient3 = @import("i_audio_client3.zig").IAudioClient3;
pub const IAudioRenderClient = @import("i_audio_render_client.zig").IAudioRenderClient;
pub const IAudioCaptureClient = @import("i_audio_capture_client.zig").IAudioCaptureClient;
pub const CaptureBuffer = @import("i_audio_capture_client.zig").CaptureBuffer;
pub const IAudioClock = @import("i_audio_clock.zig").IAudioClock;
pub const IAudioClock2 = @import("i_audio_clock2.zig").IAudioClock2;
pub const IAudioClockAdjustment = @import("i_audio_clock_adjustment.zig").IAudioClockAdjustment;

pub const IAudioEndpointVolume = @import("i_audio_endpoint_volume.zig").IAudioEndpointVolume;

pub const IAudioEndpointVolumeCallback =
    @import("i_audio_endpoint_volume_callback.zig").IAudioEndpointVolumeCallback;

pub const AUDIO_VOLUME_NOTIFICATION_DATA =
    @import("i_audio_endpoint_volume_callback.zig").AUDIO_VOLUME_NOTIFICATION_DATA;

pub const IAudioMeterInformation = @import("i_audio_meter_information.zig").IAudioMeterInformation;
pub const ISimpleAudioVolume = @import("i_simple_audio_volume.zig").ISimpleAudioVolume;
pub const IChannelAudioVolume = @import("i_channel_audio_volume.zig").IChannelAudioVolume;
pub const IAudioStreamVolume = @import("i_audio_stream_volume.zig").IAudioStreamVolume;

pub const IAudioSessionControl = @import("i_audio_session_control.zig").IAudioSessionControl;
pub const IAudioSessionControl2 = @import("i_audio_session_control2.zig").IAudioSessionControl2;
pub const IAudioSessionManager = @import("i_audio_session_manager.zig").IAudioSessionManager;
pub const IAudioSessionManager2 = @import("i_audio_session_manager2.zig").IAudioSessionManager2;

pub const IAudioSessionEnumerator =
    @import("i_audio_session_enumerator.zig").IAudioSessionEnumerator;

pub const IAudioSessionEvents = @import("i_audio_session_events.zig").IAudioSessionEvents;

pub const AudioSessionDisconnectReason =
    @import("i_audio_session_events.zig").AudioSessionDisconnectReason;

pub const IAudioSessionNotification =
    @import("i_audio_session_notification.zig").IAudioSessionNotification;

pub const IAudioVolumeDuckNotification =
    @import("i_audio_volume_duck_notification.zig").IAudioVolumeDuckNotification;

pub const IPolicyConfigVista = @import("i_policy_config.zig").IPolicyConfigVista;
pub const CLSID_PolicyConfigVista = @import("i_policy_config.zig").CLSID_PolicyConfigVista;
pub const IID_IPolicyConfigVista = @import("i_policy_config.zig").IID_IPolicyConfigVista;

pub const GUID = guid.GUID;
pub const HRESULT = com.HRESULT;
pub const REFERENCE_TIME = @import("i_audio_client.zig").REFERENCE_TIME;
pub const WAVEFORMATEX = @import("i_audio_client.zig").WAVEFORMATEX;
pub const WAVEFORMATEXTENSIBLE = @import("i_audio_client.zig").WAVEFORMATEXTENSIBLE;
pub const AudioClientProperties = @import("i_audio_client2.zig").AudioClientProperties;
pub const AudioStreamCategory = @import("i_audio_client2.zig").AudioStreamCategory;
pub const AudioClientStreamOptions = @import("i_audio_client2.zig").AudioClientStreamOptions;
pub const WAVE_FORMAT_PCM = @import("i_audio_client.zig").WAVE_FORMAT_PCM;
pub const WAVE_FORMAT_IEEE_FLOAT = @import("i_audio_client.zig").WAVE_FORMAT_IEEE_FLOAT;
pub const WAVE_FORMAT_EXTENSIBLE = @import("i_audio_client.zig").WAVE_FORMAT_EXTENSIBLE;
pub const KSDATAFORMAT_SUBTYPE_PCM = @import("i_audio_client.zig").KSDATAFORMAT_SUBTYPE_PCM;

pub const KSDATAFORMAT_SUBTYPE_IEEE_FLOAT =
    @import("i_audio_client.zig").KSDATAFORMAT_SUBTYPE_IEEE_FLOAT;

pub const EDataFlow = @import("i_mm_device_enumerator.zig").EDataFlow;
pub const ERole = @import("i_mm_device_enumerator.zig").ERole;
pub const AudioSessionState = @import("i_audio_session_control.zig").AudioSessionState;
pub const DeviceState = @import("i_mm_device.zig").DeviceState;
pub const PROPVARIANT = property.PROPVARIANT;
pub const PROPERTYKEY = property.PROPERTYKEY;

pub const FormatSupport = @import("i_audio_client.zig").FormatSupport;
pub const ShareMode = @import("i_audio_client.zig").ShareMode;
pub const StreamFlags = @import("i_audio_client.zig").StreamFlags;
pub const BufferFlags = @import("i_audio_client.zig").BufferFlags;
pub const StorageMode = @import("i_mm_device.zig").StorageMode;

pub const Error = error{
    NotInitialized,
    AlreadyInitialized,
    WrongEndpointType,
    DeviceInvalidated,
    NotStopped,
    BufferTooLarge,
    OutOfOrder,
    UnsupportedFormat,
    InvalidSize,
    DeviceInUse,
    BufferOperationPending,
    ThreadNotRegistered,
    ExclusiveModeNotAllowed,
    EndpointCreateFailed,
    ServiceNotRunning,
    EventHandleNotExpected,
    ExclusiveModeOnly,
    BufferDurationPeriodNotEqual,
    EventHandleNotSet,
    IncorrectBufferSize,
    BufferSizeError,
    CpuUsageExceeded,
    BufferError,
    BufferSizeNotAligned,
    InvalidDevicePeriod,
    InvalidPointer,
    NoInterface,
    Unexpected,
    CreateInstanceFailed,
    InvalidArgument,
    NotFound,
    OutOfMemory,
};

pub fn hresultToError(hr: HRESULT) Error!void {
    if (hr >= 0) return;

    return switch (@as(u32, @bitCast(hr))) {
        0x88890001 => Error.NotInitialized,
        0x88890002 => Error.AlreadyInitialized,
        0x88890003 => Error.WrongEndpointType,
        0x88890004 => Error.DeviceInvalidated,
        0x88890005 => Error.NotStopped,
        0x88890006 => Error.BufferTooLarge,
        0x88890007 => Error.OutOfOrder,
        0x88890008 => Error.UnsupportedFormat,
        0x88890009 => Error.InvalidSize,
        0x8889000A => Error.DeviceInUse,
        0x8889000B => Error.BufferOperationPending,
        0x8889000C => Error.ThreadNotRegistered,
        0x8889000E => Error.ExclusiveModeNotAllowed,
        0x8889000F => Error.EndpointCreateFailed,
        0x88890010 => Error.ServiceNotRunning,
        0x88890011 => Error.EventHandleNotExpected,
        0x88890012 => Error.ExclusiveModeOnly,
        0x88890013 => Error.BufferDurationPeriodNotEqual,
        0x88890014 => Error.EventHandleNotSet,
        0x88890015 => Error.IncorrectBufferSize,
        0x88890016 => Error.BufferSizeError,
        0x88890017 => Error.CpuUsageExceeded,
        0x88890018 => Error.BufferError,
        0x88890019 => Error.BufferSizeNotAligned,
        0x88890020 => Error.InvalidDevicePeriod,
        0x80004003 => Error.InvalidPointer,
        0x80004002 => Error.NoInterface,
        0x80070057 => Error.InvalidArgument,
        0x80070490 => Error.NotFound,
        0x8007000E => Error.OutOfMemory,
        else => Error.Unexpected,
    };
}

pub fn succeeded(hr: HRESULT) bool {
    return hr >= 0;
}

pub fn failed(hr: HRESULT) bool {
    return hr < 0;
}

pub const referenceTimeToNs = @import("i_audio_client.zig").referenceTimeToNs;
pub const referenceTimeFromNs = @import("i_audio_client.zig").referenceTimeFromNs;
pub const referenceTimeToMs = @import("i_audio_client.zig").referenceTimeToMs;
pub const referenceTimeFromMs = @import("i_audio_client.zig").referenceTimeFromMs;
pub const referenceTimeToSeconds = @import("i_audio_client.zig").referenceTimeToSeconds;
pub const referenceTimeFromSeconds = @import("i_audio_client.zig").referenceTimeFromSeconds;

test "hresultToError names the documented endpoint lookup failures" {
    const testing = std.testing;

    try hresultToError(0);
    try testing.expectError(Error.InvalidArgument, hresultToError(@bitCast(@as(u32, 0x80070057))));
    try testing.expectError(Error.NotFound, hresultToError(@bitCast(@as(u32, 0x80070490))));
    try testing.expectError(Error.OutOfMemory, hresultToError(@bitCast(@as(u32, 0x8007000E))));
    try testing.expectError(Error.InvalidPointer, hresultToError(@bitCast(@as(u32, 0x80004003))));
    try testing.expectError(Error.Unexpected, hresultToError(@bitCast(@as(u32, 0x80004005))));
}
