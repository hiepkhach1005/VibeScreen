namespace ColorControl.Shared.Contracts;

public class DdcSettings
{
    public bool ApplyDdc { get; set; }
    public List<DdcSetting> Settings { get; set; } = [];
    public bool RemoveOutOfRangeOsd { get; set; }

    public DdcSettings()
    {
    }

    public DdcSettings(DdcSettings settings)
    {
        settings ??= new DdcSettings();

        ApplyDdc = settings.ApplyDdc;
        Settings.Clear();
        Settings.AddRange(settings.Settings.Select(x => new DdcSetting(x)));
        RemoveOutOfRangeOsd = settings.RemoveOutOfRangeOsd;
    }

    public override string ToString()
    {
        return $"Settings: {Settings.Count}";
    }
}
