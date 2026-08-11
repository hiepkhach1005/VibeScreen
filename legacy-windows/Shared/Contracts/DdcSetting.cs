using System.Text.Json.Serialization;

namespace ColorControl.Shared.Contracts;

public class DdcSetting
{
    public enum ValueChangeTypes
    {
        Fixed = 0,
        Increase = 1,
        Decrease = 2
    }

    public byte VcpCode { get; set; }
    public uint Value { get; set; }
    public ValueChangeTypes ValueChangeType { get; set; }

    [JsonIgnore]
    public uint MaxValue { get; set; }

    public string VcpHexCode
    {
        get => $"{VcpCode:X2}";
        set => VcpCode = byte.Parse(value, System.Globalization.NumberStyles.HexNumber);
    }

    public DdcSetting()
    {
    }

    public DdcSetting(DdcSetting setting)
    {
        setting ??= new DdcSetting();

        VcpCode = setting.VcpCode;
        Value = setting.Value;
        ValueChangeType = setting.ValueChangeType;
    }

    public override string ToString()
    {
        return $"VCP: {GetVcpName()}, Value: {GetVcpValueName()}";
    }

    public string GetVcpName()
    {
        var code = VcpCode.ToString("X2");
        var value = VcpCodes.CodeList[code];

        return value == "" ? $"Unknown ({code})" : value;
    }

    public string GetVcpValueName()
    {
        return ValueChangeType switch
        {
            ValueChangeTypes.Increase => $"+{Value}",
            ValueChangeTypes.Decrease => $"-{Value}",
            _ => $"{Value}"
        };
    }
}
