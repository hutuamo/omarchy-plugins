# Bar Stats for Omarchy

A compact Omarchy status-bar widget that shows CPU usage, memory usage and CPU temperature. Hover over it for a detailed popup with a CPU history graph and memory/temperature readouts.

## Preview

Bar label:

```text
3% 12% 53°C
```

Hover popup:

- CPU utilization value + progress bar + mini history graph
- Memory used / total (GB) + usage percentage
- CPU temperature

## Requirements

- Omarchy (Hyprland + Quickshell)
- `bash`
- Readable `/proc/stat` and `/proc/meminfo`
- A CPU temperature sensor under `/sys/class/hwmon/` or `/sys/class/thermal/`

## Install via `omarchy plugin add`

```bash
omarchy plugin add https://github.com/hutuamo/omarchy-plugins.git --enable
omarchy bar put hutuamo.barstats --before omarchy.power
omarchy restart shell
```

## Manual install

```bash
git clone https://github.com/hutuamo/omarchy-plugins.git
cd omarchy-plugins
./install.sh
```

Or copy the files manually:

```bash
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

- **Refresh interval**: edit `BarWidget.qml` and change the `Timer` `interval` (default 3000 ms).
- **Hover popup delay**: change `closeTimer.interval` in `BarWidget.qml`.
- **Temperature source**: edit `cpu-temp.sh`; it prefers `coretemp` / `k10temp` / `zenpower` hwmon sensors and falls back to the first available sensor.

## License

MIT
