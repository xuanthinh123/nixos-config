# Fleet-Ready Standardized NixOS Flake Configuration

A production-grade, modular, and extensible NixOS Flake configuration engineered for mass/fleet deployment across diverse hardware architectures. Originally surveyed and tailored from an Acer Aspire A515-58GM running Aurora OS (Universal Blue / Kinoite), this configuration cleanly decouples machine-specific hardware profiles from shared system baselines, KDE Plasma 6 Wayland desktop sessions, automated maintenance pipelines, and tiered application runtimes.

---

## Table of Contents

1. [Architecture & Directory Structure](#1-architecture--directory-structure)
2. [Host Profiles](#2-host-profiles)
3. [Fleet Installation Runbook](#3-fleet-installation-runbook)
4. [Hardware Customization & Abstraction](#4-hardware-customization--abstraction)
5. [Automated Maintenance & Self-Healing](#5-automated-maintenance--self-healing)
6. [Tiered Software Ecosystem & App Store](#6-tiered-software-ecosystem--app-store)
7. [Rollback & Emergency Recovery](#7-rollback--emergency-recovery)
8. [Testing & Verification Harness](#8-testing--verification-harness)
9. [Authoritative Standards & References](#9-authoritative-standards--references)

---

## 1. Architecture & Directory Structure

The repository adheres to a strict separation of concerns. All fleet feature toggles are unified under the declarative typed option namespace `config.custom.*`.

```
nixos_config/
├── flake.nix                          # Flake entry point (inputs, outputs, mkHost helper)
├── README.md                          # Comprehensive fleet operations manual
├── hosts/                             # Host profiles
│   ├── default/                       # Minimal generic fleet baseline (iGPU / AMD)
│   │   ├── default.nix                # Host-level feature selections & defaults
│   │   └── hardware-configuration.nix # Minimal ext4/UEFI storage definition
│   ├── vm/                            # Dedicated Virtual Machine profile (QEMU/KVM, VirtualBox, VMware)
│   │   ├── default.nix                # Disables dGPU/S3; enables qemu-guest & spice-vdagent
│   │   └── hardware-configuration.nix # Storage & virtual controller definitions
│   └── me/                            # Primary host profile (Acer Aspire A515-58GM)
│       ├── default.nix                # Enables NVIDIA proprietary, S3 sleep, KDE, suites
│       └── hardware-configuration.nix # Pure Linux Btrfs subvolumes & surveyed hardware
├── modules/                           # Reusable modular library
│   ├── core/                          # Fundamental system baseline
│   │   ├── default.nix                # Core module aggregator
│   │   ├── options.nix                # Declarative `custom.*` option definitions
│   │   ├── nix.nix                    # Nix daemon, Flakes, GC, store optimisation
│   │   ├── boot.nix                   # Pure Linux UEFI bootloader (systemd-boot, zero os-prober)
│   │   ├── system.nix                 # Locales, timeZone, zram swap, networking base
│   │   └── security.nix               # Sudo, Polkit, PAM limits, realtime audio
│   ├── hardware/                      # Hardware abstraction layer
│   │   ├── default.nix                # Hardware module aggregator
│   │   ├── nvidia.nix                 # Proprietary NVIDIA driver, PRIME offload/sync, unfree predicate
│   │   ├── power.nix                  # ACPI S3 deep sleep enforcement (mem_sleep_default=deep, extraConfig)
│   │   └── filesystem.nix             # Pure Linux filesystem support (btrfs, ext4, xfs, zero NTFS)
│   ├── desktop/                       # Graphical desktop environment
│   │   ├── default.nix                # Desktop aggregator
│   │   ├── kde.nix                    # KDE Plasma 6 Wayland session & PipeWire pro-audio stack
│   │   └── display-manager.nix        # SDDM with Wayland greeter for KDE Plasma 6
│   ├── services/                      # System services & containerization
│   │   ├── default.nix                # Services aggregator
│   │   ├── flatpak.nix                # Flatpak daemon & automated Flathub repo registration
│   │   ├── distrobox.nix              # Rootless Podman & Distrobox for non-Nix mutable environments
│   │   ├── tailscale.nix              # Tailscale mesh VPN daemon & KTailctl GUI integration
│   │   └── nix-ld.nix                 # Dynamic linker shim (nix-ld) for foreign FHS binaries
│   ├── suites/                        # Toggleable application suites
│   │   ├── default.nix                # Suites aggregator
│   │   ├── development.nix            # Dev toolchain (Git, Direnv, Mise, Rust, Python, compilers)
│   │   ├── gaming.nix                 # Clean Steam & GameMode (zero legacy saves or wineprefixes)
│   │   ├── gui-apps.nix               # Browsers, LibreOffice, KDE utilities, Discover store
│   │   └── cli-tools.nix              # Modern CLI tools, Ollama AI daemon, nh search, comma, starship
│   └── home/                          # User space configuration via Home Manager
│       ├── default.nix                # Home Manager module integration & user provisioning
│       └── users/
│           └── me.nix                 # User environment (shells, dotfiles, Git, Starship, Mise, sessionPath)
└── tests/                             # Multi-tier verification harness
    ├── verify-config.sh               # Syntax, AST, contract, and exclusion test suite
    └── run-distrobox-test.sh          # Containerized NixOS evaluation harness
```

---

## 2. Host Profiles

| Host Configuration | Target Machine | Graphics Stack | Sleep Mode | Display Manager | Default State |
|-------------------|----------------|----------------|------------|-----------------|---------------|
| `nixosConfigurations.me` | Acer Aspire A515-58GM | Intel UHD (`PCI:0:2:0`) + NVIDIA RTX 2050 (`PCI:1:0:0`) with proprietary driver & PRIME offload | S3 Deep Sleep (`mem_sleep_default=deep`) | SDDM (Wayland) | Production / Tailored |
| `nixosConfigurations.vm` | Virtual Machine (QEMU/KVM, VirtualBox, VMware) | Virtualized 3D / Mesa (qemu-guest, spice-vdagent) | Standard VM ACPI (s3Sleep disabled) | SDDM (Wayland) | Dedicated VM Profile |
| `nixosConfigurations.default` | Generic PC / iGPU Laptop | Non-NVIDIA / Mesa open-source stack | Standard Desktop (s3Sleep disabled) | SDDM Wayland | Fleet Baseline |

---

## 3. Fleet Installation Runbook

### 3.1 Target Disk Partitioning (Pure Linux Btrfs Layout)

Wipe the target drive (e.g. `/dev/nvme0n1`) and create pure Linux GPT partitions without Windows or NTFS artifacts:

```bash
# 1. Create GPT partition table
parted /dev/nvme0n1 -- mklabel gpt

# 2. Create EFI System Partition (ESP) - 1 GiB
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1025MiB
parted /dev/nvme0n1 -- set 1 esp on

# 3. Create Root Btrfs Partition - Remaining space
parted /dev/nvme0n1 -- mkpart root btrfs 1025MiB 100%

# 4. Format filesystems
mkfs.vfat -F 32 -n boot /dev/nvme0n1p1
mkfs.btrfs -L nixos -f /dev/nvme0n1p2

# 5. Create subvolume hierarchy
mount /dev/disk/by-label/nixos /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@swap
umount /mnt

# 6. Mount subvolumes with zstd compression and noatime
mount -o subvol=@,compress=zstd,noatime /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/{boot,home,nix,.snapshots,swap}
mount -o subvol=@home,compress=zstd,noatime /dev/disk/by-label/nixos /mnt/home
mount -o subvol=@nix,compress=zstd,noatime /dev/disk/by-label/nixos /mnt/nix
mount -o subvol=@snapshots,compress=zstd,noatime /dev/disk/by-label/nixos /mnt/.snapshots
mount -o subvol=@swap,noatime /dev/disk/by-label/nixos /mnt/swap
mount -o fmask=0077,dmask=0077 /dev/disk/by-label/boot /mnt/boot
```

### 3.2 Installing via Flake

Clone the configuration repository to the installer environment and build:

```bash
# Install targeted profile on surveyed machine:
nixos-install --flake /path/to/nixos_config#me

# Or install generic baseline profile on any other fleet machine:
nixos-install --flake /path/to/nixos_config#default
```

### 3.3 Remote Mass Deployment via `nixos-anywhere`

For unattended deployment across remote servers or workstations over SSH:

```bash
# Deploy to remote target using SSH keys
nixos-anywhere --flake .#default root@192.168.1.50
```

### 3.4 Post-Install Deployment on a Fresh NixOS System (GUI / Calamares Installed)

If you installed NixOS freshly using the official KDE Plasma Graphical Installer (Calamares) or a standard minimal install, follow these steps from inside your running desktop session:

1. **Open Konsole (Terminal) and enter an environment with Git**:
   ```bash
   nix-shell -p git
   ```

2. **Backup default configuration and clone this repository**:
   ```bash
   # Backup original default configuration generated by installer:
   sudo mv /etc/nixos /etc/nixos.bak 2>/dev/null || true

   # Clone your Flake configuration:
   sudo git clone https://github.com/xuanthinh123/nixos-config.git /etc/nixos

   # Set ownership to your user account:
   sudo chown -R $USER:users /etc/nixos
   cd /etc/nixos
   ```

3. **Incorporate your machine's hardware-configuration**:
   The installer automatically generated `/etc/nixos.bak/hardware-configuration.nix` with the exact filesystem UUIDs and kernel modules for this specific machine.
   
   - **For your primary laptop (`me`)**:
     ```bash
     # Copy the freshly generated hardware configuration:
     cp /etc/nixos.bak/hardware-configuration.nix /etc/nixos/hosts/me/hardware-configuration.nix
     ```
   - **For a Virtual Machine (`vm`)**:
     ```bash
     cp /etc/nixos.bak/hardware-configuration.nix /etc/nixos/hosts/vm/hardware-configuration.nix
     ```
   - **For any other machine in your fleet (`default`)**:
     ```bash
     cp /etc/nixos.bak/hardware-configuration.nix /etc/nixos/hosts/default/hardware-configuration.nix
     ```

4. **Track changes in Git (Mandatory for Flakes)**:
   Nix Flakes strictly require all files to be tracked by Git before evaluation:
   ```bash
   git add -A
   ```

5. **Apply the configuration (Switch)**:
   - **For your primary laptop**:
     ```bash
     sudo nixos-rebuild switch --flake /etc/nixos#me
     ```
   - **For a Virtual Machine**:
     ```bash
     sudo nixos-rebuild switch --flake /etc/nixos#vm
     ```
   - **For any other machine in the fleet**:
     ```bash
     sudo nixos-rebuild switch --flake /etc/nixos#default
     ```

6. **Sync Custom Proprietary Fonts**:
   ```bash
   git clone https://github.com/xuanthinh123/custom-fonts.git ~/.local/share/fonts/custom-fonts
   fc-cache -f ~/.local/share/fonts
   ```

7. **Reboot**:
   ```bash
   reboot
   ```
   After rebooting, your system will be running the fully customized NixOS environment with proprietary NVIDIA drivers, S3 deep sleep, KDE Plasma 6 Wayland, Zen Browser, complete dev toolchains, and automated maintenance.

### 3.5 Clean Reset & Re-installation Runbook (Wipe & Re-run)

If you want to completely erase any previous attempt and start freshly from scratch on a virtual machine or physical PC:

1. **Preserve machine-specific hardware configuration**:
   ```bash
   sudo cp /etc/nixos.bak/hardware-configuration.nix /tmp/hardware-configuration.nix 2>/dev/null || sudo cp /etc/nixos/hardware-configuration.nix /tmp/hardware-configuration.nix 2>/dev/null || sudo nixos-generate-config --show-hardware-config > /tmp/hardware-configuration.nix
   ```

2. **Purge old configuration directories**:
   ```bash
   sudo rm -rf /etc/nixos /etc/nixos.bak
   ```

3. **Clone the pristine repository from GitHub**:
   ```bash
   sudo git clone https://github.com/xuanthinh123/nixos-config.git /etc/nixos
   ```

4. **Restore hardware configuration into target host profile**:
   ```bash
   # For Virtual Machine (VM):
   sudo cp /tmp/hardware-configuration.nix /etc/nixos/hosts/vm/hardware-configuration.nix

   # Or for primary laptop:
   # sudo cp /tmp/hardware-configuration.nix /etc/nixos/hosts/me/hardware-configuration.nix
   ```

5. **Stage and apply cleanly**:
   ```bash
   cd /etc/nixos
   git add -A
   sudo nixos-rebuild switch --flake /etc/nixos#vm
   ```

---

## 4. Hardware Customization & Abstraction

All hardware behaviors are parameterized in `modules/core/options.nix` and invoked in host profiles:

### 4.1 NVIDIA Proprietary Driver & Hybrid PRIME

Per requirement R2 and the user's Stable LTS directive, official closed-source proprietary drivers from the production stable branch are strictly enforced:
- `hardware.nvidia.open = false;`
- `hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;`
- Unfree packages (`nvidia-x11`, `nvidia-settings`, `nvidia-persistenced`, and Steam packages) are whitelisted via `allowUnfreePredicate`.

To toggle or customize NVIDIA in a host profile (`hosts/<hostName>/default.nix`):

```nix
custom.hardware.nvidia = {
  enable = true; # Set to false on AMD, Intel iGPU, or VM systems
  prime = {
    enable = true;
    mode = "offload"; # "offload" for battery efficiency, "sync" for max performance
    intelBusId = "PCI:0:2:0";  # Check with: lspci | grep -E "VGA|3D"
    nvidiaBusId = "PCI:1:0:0"; # Check with: lspci | grep -E "VGA|3D"
  };
};
```

When `mode = "offload"` is active, `powerManagement.finegrained = true` powers down the discrete GPU to 0W when idle. Launch heavy applications or games on the dGPU using the bundled wrapper:

```bash
prime-run steam
prime-run blender
nvidia-offload vkmark
```

### 4.2 S3 Deep Sleep Power Management

To prioritize ACPI S3 (Suspend-to-RAM) over modern standby (`s2idle`), set:

```nix
custom.hardware.power.s3Sleep = true;
```

This sets `boot.kernelParams = [ "mem_sleep_default=deep" ];` and configures `systemd.sleep.settings.Sleep.MemorySleepMode = "deep"`. If deployed on an ultrabook where the OEM stripped S3 tables from BIOS, the Linux kernel logs an ACPI notice and gracefully defaults to `s2idle` without crashing.

### 4.3 Pure Linux Filesystem Enforcement

Windows dual-boot scanning (`os-prober`) and NTFS filesystem drivers (`ntfs3`, `ntfs-3g`) are strictly eliminated from the system closure. Only native Linux filesystems (`btrfs`, `ext4`, `xfs`) are loaded by the kernel (`boot.supportedFilesystems`).

---

## 5. Automated Maintenance & Self-Healing

Fleet machines self-maintain via declarative systemd timers, preventing generation bloat and disk exhaustion:

```nix
custom.maintenance = {
  autoUpgrade = {
    enable = true;
    flake = "path:/etc/nixos#me"; # Or remote: "github:org/nixos-fleet#default"
    dates = "04:00";              # Runs daily at 04:00 AM
    randomizedDelaySec = "45min"; # Random jitter prevents network mirror stampedes
    allowReboot = false;          # Does not interrupt active desktop sessions
  };

  garbageCollection = {
    enable = true;
    dates = "weekly";
    olderThan = "14d";            # Prunes generations older than 14 days
  };

  storeOptimise = true;           # Hardlink deduplication at build time & weekly scan
  minFreeSpaceGB = 3;             # Triggers emergency GC if free space < 3 GiB
  maxFreeSpaceGB = 10;            # Emergency GC recovers up to 10 GiB
};
```

### 5.1 Automated Self-Maintenance Pipeline
The system automatically executes scheduled maintenance tasks in the background:
- **Daily at 04:00 AM**: Automatic flake update & system rebuild (`system.autoUpgrade`) with 45-minute jitter to protect network mirrors.
- **Weekly**: Automated garbage collection purging system generations older than 14 days (`nix.gc`).
- **Real-time Deduplication**: Hardlink deduplication (`auto-optimise-store = true`) saving gigabytes of disk space.
- **Emergency Protection**: Automatic emergency GC trigger if free root disk space drops below 3 GiB, reclaiming up to 10 GiB.

### 5.2 Manual Garbage & Disk Space Cleaning Runbook

Whenever you want to immediately purge old generations and reclaim disk space:

#### Method 1: Visual & Interactive Cleaning with `nh` (Fastest & Recommended)
The pre-installed `nh` tool displays interactive summaries and confirmation prompts:
```bash
# Clean both system and user generations, keeping the 3 most recent:
nh clean all --keep 3

# Or clean generations older than 7 days:
nh clean all --keep-since 7d
```

#### Method 2: Traditional Nix Deep Clean
```bash
# 1. Delete all old generations for both root and user profiles (keeps only active generation):
sudo nix-collect-garbage -d
nix-collect-garbage -d

# 2. Re-deduplicate identical binaries and libraries in /nix/store:
sudo nix-store --optimise

# 3. Refresh bootloader entries in systemd-boot:
sudo /run/current-system/bin/switch-to-configuration boot
```

#### Method 3: Cleaning Flatpak & Container Disk Caches
If you frequently test applications from Flathub or run local containers:
```bash
# Prune orphaned Flatpak runtimes:
flatpak uninstall --unused -y

# Prune unused Podman/Docker container caches:
podman system prune -af
```

### 5.3 Local AI Ecosystem & Agent Workflows

The system includes a pre-configured local LLM runtime powered by Ollama and dynamic binary compatibility for advanced multi-agent CLIs:

#### 1. Background Ollama Daemon (`services.ollama.enable = true;`)
The Ollama service starts automatically as a systemd background daemon (`ollama.service`). You can query lightweight, high-performance local AI models directly from your terminal at zero token cost:

```bash
# Qwen 2.5 (1.5B) - Recommended: High Vietnamese & multilingual fluency, fast reasoning:
ollama run qwen2.5:1.5b

# Llama 3.2 (1B) - Instantaneous responses for text transformation & classification:
ollama run llama3.2:1b

# DeepSeek R1 (1.5B) - Chain-of-thought logic reasoning and traceback analysis:
ollama run deepseek-r1:1.5b
```

#### 2. Pre-Compiled Multi-Agent CLIs via `nix-ld`
Dynamically-linked external AI tools (such as Google Antigravity `agy`, xAI Grok `grok`, and `opencode`) are fully supported out-of-the-box via `programs.nix-ld` and pre-configured in `home.sessionPath` (`~/.local/bin`, `~/.grok/bin`, `~/.opencode/bin`).
To migrate your existing agent sessions and credentials from your current machine to a new NixOS installation, simply copy:
- `~/.local/bin/agy` & `~/.gemini/` (Antigravity CLI & sessions)
- `~/.grok/` (Grok CLI, configs, and credentials)
- `~/.opencode/` (OpenCode CLI)

---

## 6. Tiered Software Ecosystem & App Store

Following user directives, the unmaintained `nix-software-center` project was cancelled. Software delivery is structured into 4 distinct, rock-solid tiers:

```
┌─────────────────────────────────────────────────────────────┐
│  Tier 1: Native Nixpkgs Declarative Packages                │
│  (System-wide immutable reproducibility, Flake-pinned)       │
├─────────────────────────────────────────────────────────────┤
│  Tier 2: Flatpak + Flathub & KDE Discover GUI App Store    │
│  (Point-and-click GUI software installation for users)      │
├─────────────────────────────────────────────────────────────┤
│  Tier 3: Distrobox & Podman Mutable Container Layer        │
│  (Ubuntu, Fedora, Arch containers with full GUI/GPU pass)   │
├─────────────────────────────────────────────────────────────┤
│  Tier 4: Dynamic Linker Emulation (nix-ld)                  │
│  (Run unpatched foreign precompiled FHS binaries directly)  │
└─────────────────────────────────────────────────────────────┘
```

### 6.1 GUI Software Center (KDE Discover)
- Enabled via `custom.suites.guiApps = true;` and `custom.services.flatpak = true;`.
- Installs `kdePackages.discover` with the Flatpak backend enabled and automatically provisions the official Flathub remote repository via systemd on first boot.
- Users can browse, search, install, and update graphical applications (Spotify, Discord, LibreOffice, Zen Browser) visually without touching the terminal.

### 6.2 Interactive CLI Discovery Tools
- **`nh search <query>`**: Blazing-fast interactive terminal search powered by the `nh` CLI helper (`custom.suites.cliTools = true;`).
- **`comma` (`, <command>`)**: Instantly runs any binary from Nixpkgs without permanently installing it (e.g. `, cowsay "Fleet ready!"`).
- **`nix-index`**: Indexes all packages and files for instantaneous `command-not-found` suggestions and `nix-locate` searches.

### 6.3 Mutable Containers (Distrobox)
When a legacy proprietary tool requires an Ubuntu or Arch environment:

```bash
distrobox create -n ubuntu-dev -i docker.io/library/ubuntu:latest
distrobox enter ubuntu-dev
```

### 6.4 Precompiled FHS Binaries (`nix-ld`)
Precompiled binaries (e.g. custom VS Code server extensions, downloaded Go/Rust/C executables) work out of the box through `/lib64/ld-linux-x86-64.so.2` emulation backed by common shared C libraries.

### 6.5 Custom Proprietary Fonts Synchronization
While standard developer Nerd Fonts (JetBrainsMono, FiraCode, CascadiaCode, SourceCodePro, etc.) and international Noto fonts are declaratively provisioned in `modules/desktop/kde.nix`, the proprietary Microsoft & specialized UI fonts (~45 MB) are maintained in a dedicated lightweight repository:
```bash
git clone https://github.com/xuanthinh123/custom-fonts.git ~/.local/share/fonts/custom-fonts
fc-cache -f ~/.local/share/fonts
```
Home Manager automatically indexes this user font directory via `fonts.fontconfig.enable = true;`.

---

## 7. Rollback & Emergency Recovery

Because NixOS maintains generation immutability:

### 7.1 Instant Bootloader Rollback
If an upgrade causes an issue, simply reboot. In the `systemd-boot` menu (which displays the 10 most recent generations), use the arrow keys to select a previous generation and press Enter.

### 7.2 Command-Line Rollback
```bash
# Roll back running system to previous generation:
sudo nixos-rebuild switch --rollback

# Inspect all historical generations:
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Switch directly to a specific generation number (e.g. gen 42):
sudo nix-env --switch-generation 42 --profile /nix/var/nix/profiles/system
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

---

## 8. Testing & Verification Harness

The repository includes a comprehensive, multi-tier verification harness in `tests/`:

### 8.1 Static AST, Grammar, and Contract Verification
Run the automated verification suite to validate file layout, 100% English comment compliance, strict exclusion of unmaintained tools and Windows/NTFS artifacts, and option contract semantics:

```bash
./tests/verify-config.sh
```

### 8.2 Containerized Evaluation (Tier 1 Distrobox)
To perform full Nix Flake evaluation inside a clean NixOS container on the host Aurora OS:

```bash
./tests/run-distrobox-test.sh
```

Or manually:
```bash
distrobox create -n nixos-fleet-validator -i docker.io/nixos/nix:latest --yes
distrobox enter nixos-fleet-validator -- nix flake check /path/to/nixos_config --extra-experimental-features 'nix-command flakes'
```

### 8.3 Virtual Machine Dry-Run (Tier 2 QEMU VM)
Build and run a test virtual machine without modifying host disk state:

```bash
nix build .#nixosConfigurations.default.config.system.build.vm
./result/bin/run-nixos-default-vm
```

---

## 9. Authoritative Standards & References

- **NixOS Official Manual**: https://nixos.org/manual/nixos/stable/
- **Nixpkgs Manual**: https://nixos.org/manual/nixpkgs/stable/
- **Nix Reference Manual (Flakes & Settings)**: https://nix.dev/manual/nix/2.34/
- **Home Manager Manual**: https://nix-community.github.io/home-manager/
- **ArchWiki — NVIDIA Optimus & PRIME**: https://wiki.archlinux.org/title/PRIME
- **ArchWiki — Power Management & Suspend-to-RAM (S3)**: https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate
- **ArchWiki — Btrfs Subvolume Layout**: https://wiki.archlinux.org/title/Btrfs#Subvolumes
