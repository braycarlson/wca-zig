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

    const device = try enumerator.getDefaultAudioEndpoint(.Render, .Console);
    defer _ = device.release();

    try printFriendlyName(allocator, device, "Rendering to");

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

    std.debug.print("Default period: {d} ns\n", .{latency_ns});

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

    const render_client = try audio_client.getRenderClient();
    defer _ = render_client.release();

    try audio_client.start();
    defer audio_client.stop() catch |err| {
        std.debug.print("Stopping the audio client failed: {s}\n", .{@errorName(err)});
    };

    std.debug.print("Rendering silence for 2 seconds...\n", .{});

    try renderSilence(audio_client, render_client, mix_format, buffer_size, latency_ns);

    std.debug.print("Done.\n", .{});
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

fn renderSilence(
    audio_client: *wca.IAudioClient,
    render_client: *wca.IAudioRenderClient,
    mix_format: *const wca.WAVEFORMATEX,
    buffer_size: u32,
    latency_ns: i64,
) !void {
    var frames_written: u64 = 0;
    const target_frames = mix_format.samples_per_sec * 2;

    while (frames_written < target_frames) {
        const padding = try audio_client.getCurrentPadding();
        const available = buffer_size - padding;

        if (available > 0) {
            const buffer = try render_client.getBuffer(available);
            const byte_count = available * @as(u32, mix_format.block_align);

            @memset(buffer[0..byte_count], 0);

            try render_client.releaseBuffer(available, 0);
            frames_written += available;
        }

        Sleep(@intCast(@divTrunc(latency_ns, 2 * std.time.ns_per_ms)));
    }
}
