const com = @import("com.zig");
const wca = @import("wca.zig");

const HRESULT = com.HRESULT;

const IAudioClockAdjustmentVtbl = extern struct {
    base: com.IUnknownVtbl,
    SetSampleRate: *const fn (*IAudioClockAdjustment, f32) callconv(.winapi) HRESULT,
};

pub const IAudioClockAdjustment = extern struct {
    vtable: *const IAudioClockAdjustmentVtbl,

    pub fn release(self: *IAudioClockAdjustment) u32 {
        return @as(*com.IUnknown, @ptrCast(self)).release();
    }

    pub fn setSampleRate(self: *IAudioClockAdjustment, sample_rate: f32) wca.Error!void {
        const hr = self.vtable.SetSampleRate(self, sample_rate);

        try wca.hresultToError(hr);
    }
};
