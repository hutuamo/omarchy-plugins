# Bar Stats for Omarchy

A compact Omarchy status-bar widget that shows CPU usage, memory usage and CPU temperature. Hover over it for a settings popup where each category can be toggled on/off individually.

## Preview

Bar label:

```text
3% 12% 53°C
```

Hover popup (Chinese UI):

- Per-category display toggles (CPU / 内存 / 温度) with the current value next to each switch
- At least one category stays enabled — the last remaining toggle refuses to turn off
- Toggle states persist in `~/.config/omarchy/shell.json` (`showCpu` / `showMem` / `showTemp`)

## Requirements

- Omarchy (Hyprland + Quickshell)
- `bash`
- Readable `/proc/stat` and `/proc/meminfo`
- A CPU temperature sensor under `/sys/class/hwmon/` or `/sys/class/thermal/`

## Install

This plugin is part of the `omarchy-plugins` monorepo, so `omarchy plugin add` cannot be used directly. Use the provided install script or copy the files manually.

### Install script

```bash
git clone https://github.com/hutuamo/omarchy-plugins.git
cd omarchy-plugins/barstats
./install.sh
```

### Manual install

```bash
cd barstats
mkdir -p ~/.config/omarchy/plugins/hutuamo.barstats
cp BarWidget.qml cpu-temp.sh manifest.json ~/.config/omarchy/plugins/hutuamo.barstats/
chmod +x ~/.config/omarchy/plugins/hutuamo.barstats/cpu-temp.sh
omarchy plugin enable hutuamo.barstats
omarchy bar put hutuamo.barstats --before omarchy.power
omarchy restart shell
```

## Uninstall

```bash
omarchy bar move hutuamo.barstats --section right --index -1
rm -rf ~/.config/omarchy/plugins/hutuamo.barstats
omarchy restart shell
```

## Customization

- **Default visibility**: add `"showCpu": false` (or `showMem` / `showTemp`) to the widget's entry in `~/.config/omarchy/shell.json`, or just use the hover popup toggles.
- **Refresh interval**: edit `BarWidget.qml` and change the `Timer` `interval` (default 3000 ms).
- **Hover popup delay**: change `closeTimer.interval` in `BarWidget.qml`.
- **Temperature source**: edit `cpu-temp.sh`; it prefers `coretemp` / `k10temp` / `zenpower` hwmon sensors and falls back to the first available sensor.

## License

MIT
