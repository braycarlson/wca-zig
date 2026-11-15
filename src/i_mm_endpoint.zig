const com = @import("com.zig");
const wca = @import("wca.zig");

const HRESULT = com.HRESULT;
const EDataFlow = @import("i_mm_device_enumerator.zig").EDataFlow;

const IMMEndpointVtbl = extern struct {
    base: com.IUnknownVtbl,
    GetDataFlow: *const fn (*IMMEndpoint, *EDataFlow) callconv(.winapi) HRESULT,
};

pub const IMMEndpoint = extern struct {
    vtable: *const IMMEndpointVtbl,

    pub fn release(self: *IMMEndpoint) u32 {
        return @as(*com.IUnknown, @ptrCast(self)).release();
    }

    pub fn getDataFlow(self: *IMMEndpoint) wca.Error!EDataFlow {
        var data_flow: EDataFlow = .Render;
        const hr = self.vtable.GetDataFlow(self, &data_flow);

        try wca.hresultToError(hr);

        return data_flow;
    }
};
