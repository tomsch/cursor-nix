# Cursor for NixOS

Unofficial Nix packages for [Cursor](https://cursor.com) - the AI-first code editor and Cursor Agent CLI.

## Installation

### Flake Input (NixOS/Home Manager)

```nix
{
  inputs.cursor.url = "github:tomsch/cursor-nix";

  outputs = { self, nixpkgs, cursor, ... }: {
    # NixOS
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [{
        nixpkgs.config.allowUnfree = true;
        environment.systemPackages = [
          cursor.packages.x86_64-linux.default
          cursor.packages.x86_64-linux.cursor-cli
        ];
      }];
    };
  };
}
```

### Direct Run (no install)

```bash
# GUI editor
nix run github:tomsch/cursor-nix --impure

# CLI agent
nix run github:tomsch/cursor-nix#cursor-cli --impure
```

### Imperative Install

```bash
# GUI editor
nix profile install github:tomsch/cursor-nix --impure

# CLI agent
nix profile install github:tomsch/cursor-nix#cursor-cli --impure
```

## Cursor CLI

The `cursor-cli` package installs Cursor's terminal agent as both `cursor-agent` and `agent`:

```bash
cursor-agent --version
agent --version
```

## Features

- **AI-powered coding** with Claude, GPT-4, and Cursor's own model
- **Composer** - frontier model built for low-latency agentic coding
- **AI Code Review** - find and fix bugs directly in the editor
- **Instant Grep** - lightning fast codebase search
- Native Wayland support with automatic detection
- VS Code extension compatibility

## Wayland Support

The package automatically enables Wayland support when `NIXOS_OZONE_WL=1` is set:

```bash
export NIXOS_OZONE_WL=1
```

This is typically set by NixOS desktop modules automatically.

## Update Packages

Maintainers can update both GUI and CLI packages:

```bash
./update.sh
```

## License

The Nix packaging is MIT. Cursor itself is proprietary software.

## Links

- [Cursor](https://cursor.com)
- [Cursor Changelog](https://cursor.com/changelog)
- [Cursor Features](https://cursor.com/features)
