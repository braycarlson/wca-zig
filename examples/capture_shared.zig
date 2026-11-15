const std = @import("std");
const wca = @import("wca");

extern "kernel32" fn Sleep(dwMilliseconds: u32) callconv(.winapi) void;

pub fn main() !void {
    var gpa: std.heap.SafeAllocator = .init(std.heap.page_allocator, .{});
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    try wca.com.initialize(wca.com.COINIT_APARTMENTTHREADED);
    defer wca.com.uninitialize();

    const enumerator = try wca.IMMDeviceEnumerator.create();
    defer _ = enumerator.release();

    const device = try enumerator.getDefaultAudioEndpoint(.Capture, .Console);
    defer _ = device.release();

    try printFriendlyName(allocator, device, "Capturing from");

    const audio_client = try device.activateAudioClient();
    defer _ = audio_client.release();

    const mix_format = try audio_client.getMixFormat();
    defer wca.com.taskMemFree(@ptrCast(mix_format));

    std.debug.print("Format: {d} channels, {d} Hz, {d} bits\n", .{
        mix_format.channels,
        mix_format.samples_per_sec,
        mix_format.bits_per_sample,
    });

    const period = try audio_client.getDevicePeriod();
    const latency_ns = wca.referenceTimeToNs(period.default);

    try audio_client.initialize(
        .Shared,
        0,
        period.default,
        0,
        mix_format,
        null,
    );

    const buffer_size = try audio_client.getBufferSize();

    std.debug.print("Buffer size: {d} frames\n", .{buffer_size});

    const capture_client = try audio_client.getCaptureClient();
    defer _ = capture_client.release();

    try audio_client.start();
    defer audio_client.stop() catch |err| {
        std.debug.print("Stopping the audio client failed: {s}\n", .{@errorName(err)});
    };

    std.debug.print("Capturing for 2 seconds...\n", .{});

    const byte_count = try capture(allocator, capture_client, mix_format, latency_ns);

    std.debug.print("Captured {d} bytes of audio data.\n", .{byte_count});
}

fn printFriendlyName(
    allocator: std.mem.Allocator,
    device: *wca.IMMDevice,
    label: []const u8,
) !void {
    const property_store = try device.openPropertyStore(.Read);
    defer _ = property_store.release();

    const key = &wca.property.PKEY_Device_FriendlyName;
    const name = try property_store.getStringValue(key, allocator);
    defer allocator.free(name);

    if (name.len > 0) std.debug.print("{s}: {s}\n", .{ label, name });
}

fn capture(
    allocator: std.mem.Allocator,
    capture_client: *wca.IAudioCaptureClient,
    mix_format: *const wca.WAVEFORMATEX,
    latency_ns: i64,
) !usize {
    var frames_captured: u64 = 0;
    const target_frames = mix_format.samples_per_sec * 2;

    var captured_data: std.ArrayList(u8) = .empty;
    defer captured_data.deinit(allocator);

    while (frames_captured < target_frames) {
        const packet_size = try capture_client.getNextPacketSize();

        if (packet_size > 0) {
            const buffer = try capture_client.getBuffer();

            if (!buffer.isSilent()) {
                const data_slice = buffer.slice(mix_format.block_align);

                try captured_data.appendSlice(allocator, data_slice);
            }

            frames_captured += buffer.frame_count;

            try capture_client.releaseBuffer(buffer.frame_count);
        } else {
            Sleep(@intCast(@divTrunc(latency_ns, 2 * std.time.ns_per_ms)));
        }
    }

    return captured_data.items.len;
}
