const std = @import("std");
const wca = @import("wca");

pub fn main() !void {
    var gpa: std.heap.SafeAllocator = .init(std.heap.page_allocator, .{});
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    try wca.com.initialize(wca.com.COINIT_APARTMENTTHREADED);
    defer wca.com.uninitialize();

    const enumerator = try wca.IMMDeviceEnumerator.create();
    defer _ = enumerator.release();

    std.debug.print("=== Render Devices ===\n", .{});
    try listDevices(enumerator, .Render, allocator);

    std.debug.print("\n=== Capture Devices ===\n", .{});
    try listDevices(enumerator, .Capture, allocator);
}

fn listDevices(
    enumerator: *wca.IMMDeviceEnumerator,
    data_flow: wca.EDataFlow,
    allocator: std.mem.Allocator,
) !void {
    const collection = try enumerator.enumAudioEndpoints(data_flow, wca.DeviceState.Active);
    defer _ = collection.release();

    const count = try collection.getCount();

    std.debug.print("Found {d} devices:\n", .{count});

    const key_name = &wca.property.PKEY_Device_FriendlyName;
    const key_desc = &wca.property.PKEY_Device_DeviceDesc;
    var i: u32 = 0;

    while (i < count) : (i += 1) {
        const device = try collection.item(i);
        defer _ = device.release();

        const state = try device.getState();
        const id = try device.getId(allocator);
        defer allocator.free(id);

        const property_store = try device.openPropertyStore(.Read);
        defer _ = property_store.release();

        const name = try property_store.getStringValue(key_name, allocator);
        defer allocator.free(name);

        const desc = try property_store.getStringValue(key_desc, allocator);
        defer allocator.free(desc);

        std.debug.print("\n[{d}] {s}\n", .{ i, if (name.len > 0) name else "<unknown>" });
        std.debug.print("    Description: {s}\n", .{if (desc.len > 0) desc else "<none>"});
        std.debug.print("    State: {d}\n", .{state});
        std.debug.print("    ID: {s}\n", .{id});
    }
}
