const com = @import("com.zig");
const wca = @import("wca.zig");

const HRESULT = com.HRESULT;

const IAudioRenderClientVtbl = extern struct {
    base: com.IUnknownVtbl,
    GetBuffer: *const fn (*IAudioRenderClient, u32, *?[*]u8) callconv(.winapi) HRESULT,
    ReleaseBuffer: *const fn (*IAudioRenderClient, u32, u32) callconv(.winapi) HRESULT,
};

pub const IAudioRenderClient = extern struct {
    vtable: *const IAudioRenderClientVtbl,

    pub fn release(self: *IAudioRenderClient) u32 {
        return @as(*com.IUnknown, @ptrCast(self)).release();
    }

    pub fn getBuffer(self: *IAudioRenderClient, frame_count_requested: u32) wca.Error![*]u8 {
        var data: ?[*]u8 = null;
        const hr = self.vtable.GetBuffer(self, frame_count_requested, &data);

        try wca.hresultToError(hr);

        return data orelse return wca.Error.Unexpected;
    }

    pub fn releaseBuffer(
        self: *IAudioRenderClient,
        frame_count_written: u32,
        flags: u32,
    ) wca.Error!void {
        const hr = self.vtable.ReleaseBuffer(self, frame_count_written, flags);

        try wca.hresultToError(hr);
    }

    pub fn getBufferSlice(
        self: *IAudioRenderClient,
        frame_count_requested: u32,
        block_align: u16,
    ) wca.Error![]u8 {
        const data = try self.getBuffer(frame_count_requested);
        const byte_count = frame_count_requested * @as(u32, block_align);

        return data[0..byte_count];
    }
};
