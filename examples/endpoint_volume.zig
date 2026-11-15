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

    const property_store = try device.openPropertyStore(.Read);
    defer _ = property_store.release();

    const key = &wca.property.PKEY_Device_FriendlyName;
    const name = try property_store.getStringValue(key, allocator);
    defer allocator.free(name);

    if (name.len > 0) std.debug.print("Device: {s}\n", .{name});

    const endpoint_volume = try device.activateEndpointVolume();
    defer _ = endpoint_volume.release();

    const volume = try endpoint_volume.getMasterVolumeLevelScalar();
    const muted = try endpoint_volume.getMute();
    const volume_range = try endpoint_volume.getVolumeRange();
    const channel_count = try endpoint_volume.getChannelCount();

    std.debug.print("----------------------------------------\n", .{});
    std.debug.print("Current volume: {d:.1}%\n", .{volume * 100});
    std.debug.print("Muted: {}\n", .{muted});

    std.debug.print("Volume range: {d:.1} dB to {d:.1} dB (increment: {d:.2} dB)\n", .{
        volume_range.db_min,
        volume_range.db_max,
        volume_range.db_increment,
    });

    std.debug.print("Channels: {d}\n", .{channel_count});

    var i: u32 = 0;

    while (i < channel_count) : (i += 1) {
        const ch_volume = try endpoint_volume.getChannelVolumeLevelScalar(i);

        std.debug.print("  Channel {d}: {d:.1}%\n", .{ i, ch_volume * 100 });
    }

    std.debug.print("----------------------------------------\n", .{});

    std.debug.print("Setting volume to 50%...\n", .{});
    try endpoint_volume.setMasterVolumeLevelScalar(0.5, null);
    Sleep(1000);

    std.debug.print("Restoring volume to {d:.1}%...\n", .{volume * 100});
    try endpoint_volume.setMasterVolumeLevelScalar(volume, null);

    std.debug.print("Done.\n", .{});
}
