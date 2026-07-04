# simpkg
A simple package manager to install and remove packages.

## Usage
```
simpkg [flag] <target>
```

## flags
| Flag | Description |
|------|-------------|
| `install` | Install a package |
| `remote` | Remove an installed package |
| `query` | Get information about an installed package |
| `owns` | Check which package owns a specified file |
| `search-local` | Search through your installed packages |
| `search-remote` | Search through the remote packages |
| `files` | List files owned by a package |
| `update` | WIP |
| `list-local` | List your installed packages |
| `list-remote` | List the remote packages |
| `clear-cache` | Clear the package cache and temporary files |

## Getting it!
### Building
Requires [V](https://github.com/vlang/v) to be installed and in the system PATH
```
v make.vsh install
```

### Downloading a release
Download a prebuilt binary from the latest release.
