const std = @import("std");
const GUID = @import("guid.zig").GUID;
const com = @import("com.zig");

pub const PROPERTYKEY = extern struct {
    fmtid: GUID,
    pid: u32,
};

pub const PROPVARIANT = extern struct {
    vt: u16,
    reserved1: u16,
    reserved2: u16,
    reserved3: u16,
    data: extern union {
        int_val: i32,
        uint_val: u32,
        int64_val: i64,
        uint64_val: u64,
        float_val: f32,
        double_val: f64,
        pwsz_val: ?[*:0]u16,
        blob: extern struct {
            size: u32,
            data: ?[*]u8,
        },
        raw: [8]u8,
    },

    pub fn clear(self: *PROPVARIANT) void {
        if (self.vt == VT_LPWSTR) {
            if (self.data.pwsz_val) |text| com.taskMemFree(@ptrCast(text));
        }

        self.* = std.mem.zeroes(PROPVARIANT);
    }

    pub fn getString(self: *const PROPVARIANT, allocator: std.mem.Allocator) ![]u8 {
        if (self.vt != VT_LPWSTR) return &.{};

        const ptr = self.data.pwsz_val orelse return &.{};
        var len: usize = 0;

        while (ptr[len] != 0) : (len += 1) {}

        const slice = ptr[0..len];
        return try std.unicode.utf16LeToUtf8Alloc(allocator, slice);
    }

    pub fn getInt(self: *const PROPVARIANT) ?i32 {
        return switch (self.vt) {
            VT_I4, VT_INT => self.data.int_val,
            else => null,
        };
    }

    pub fn getUint(self: *const PROPVARIANT) ?u32 {
        return switch (self.vt) {
            VT_UI4, VT_UINT => self.data.uint_val,
            else => null,
        };
    }
};

pub const VT_EMPTY: u16 = 0;
pub const VT_NULL: u16 = 1;
pub const VT_I2: u16 = 2;
pub const VT_I4: u16 = 3;
pub const VT_R4: u16 = 4;
pub const VT_R8: u16 = 5;
pub const VT_BSTR: u16 = 8;
pub const VT_BOOL: u16 = 11;
pub const VT_I1: u16 = 16;
pub const VT_UI1: u16 = 17;
pub const VT_UI2: u16 = 18;
pub const VT_UI4: u16 = 19;
pub const VT_I8: u16 = 20;
pub const VT_UI8: u16 = 21;
pub const VT_INT: u16 = 22;
pub const VT_UINT: u16 = 23;
pub const VT_LPWSTR: u16 = 31;
pub const VT_BLOB: u16 = 65;
pub const VT_CLSID: u16 = 72;

pub const PKEY_DeviceInterface_FriendlyName: PROPERTYKEY = .{
    .fmtid = .{
        .data1 = 0x026e516e,
        .data2 = 0xb814,
        .data3 = 0x414b,
        .data4 = .{ 0x83, 0xcd, 0x85, 0x6d, 0x6f, 0xef, 0x48, 0x22 },
    },
    .pid = 2,
};

pub const PKEY_Device_DeviceDesc: PROPERTYKEY = .{
    .fmtid = .{
        .data1 = 0xa45c254e,
        .data2 = 0xdf1c,
        .data3 = 0x4efd,
        .data4 = .{ 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0 },
    },
    .pid = 2,
};

pub const PKEY_Device_FriendlyName: PROPERTYKEY = .{
    .fmtid = .{
        .data1 = 0xa45c254e,
        .data2 = 0xdf1c,
        .data3 = 0x4efd,
        .data4 = .{ 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0 },
    },
    .pid = 14,
};

pub const PKEY_AudioEndpoint_FormFactor: PROPERTYKEY = .{
    .fmtid = .{
        .data1 = 0x1da5d803,
        .data2 = 0xd492,
        .data3 = 0x4edd,
        .data4 = .{ 0x8c, 0x23, 0xe0, 0xc0, 0xff, 0xee, 0x7f, 0x0e },
    },
    .pid = 0,
};

pub const PKEY_AudioEndpoint_GUID: PROPERTYKEY = .{
    .fmtid = .{
        .data1 = 0x1da5d803,
        .data2 = 0xd492,
        .data3 = 0x4edd,
        .data4 = .{ 0x8c, 0x23, 0xe0, 0xc0, 0xff, 0xee, 0x7f, 0x0e },
    },
    .pid = 4,
};

pub const PKEY_AudioEndpoint_Disable_SysFx: PROPERTYKEY = .{
    .fmtid = .{
        .data1 = 0x1da5d803,
        .data2 = 0xd492,
        .data3 = 0x4edd,
        .data4 = .{ 0x8c, 0x23, 0xe0, 0xc0, 0xff, 0xee, 0x7f, 0x0e },
    },
    .pid = 5,
};

pub const PKEY_AudioEngine_DeviceFormat: PROPERTYKEY = .{
    .fmtid = .{
        .data1 = 0xf19f064d,
        .data2 = 0x082c,
        .data3 = 0x4e27,
        .data4 = .{ 0xbc, 0x73, 0x68, 0x82, 0xa1, 0xbb, 0x8e, 0x4c },
    },
    .pid = 0,
};

pub const PKEY_AudioEngine_OEMFormat: PROPERTYKEY = .{
    .fmtid = .{
        .data1 = 0xe4870e26,
        .data2 = 0x3cc5,
        .data3 = 0x4cd2,
        .data4 = .{ 0xba, 0x46, 0xca, 0x0a, 0x9a, 0x70, 0xed, 0x04 },
    },
    .pid = 3,
};

pub const EndpointFormFactor = enum(u32) {
    RemoteNetworkDevice = 0,
    Speakers = 1,
    LineLevel = 2,
    Headphones = 3,
    Microphone = 4,
    Headset = 5,
    Handset = 6,
    UnknownDigitalPassthrough = 7,
    SPDIF = 8,
    DigitalAudioDisplayDevice = 9,
    UnknownFormFactor = 10,
};
