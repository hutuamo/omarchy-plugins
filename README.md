# omarchy-plugins

A collection of Omarchy shell plugins and utilities.

## Plugins

| Plugin | Directory | Description |
|--------|-----------|-------------|
| **Bar Stats** | [`barstats/`](barstats/) | Compact status-bar widget showing CPU usage, memory usage and CPU temperature, with a detailed hover popup. |

## Usage

Each plugin lives in its own subdirectory and includes its own `README.md` and `install.sh`. Most plugins are installed manually because this repository is a monorepo and `omarchy plugin add` expects a single plugin at the repository root.

Example:

```bash
cd barstats
./install.sh
```

## License

MIT unless otherwise noted in a plugin's directory.
