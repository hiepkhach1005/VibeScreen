using static ColorControl.Shared.Native.WinApi;

namespace ColorControl.Shared.Contracts;

public class VcpInfo
{
    public uint Value { get; set; }
    public uint MaxValue { get; set; }
    public MC_VCP_CODE_TYPE CodeType { get; set; }
}
