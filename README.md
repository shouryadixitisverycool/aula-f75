# AULA F75 Linux Controller

A userspace WebHID controller and configuration utility for the AULA F75 mechanical keyboard on Linux.

Official AULA driver software is exclusively distributed for Windows. This project provides full feature parity—including RGB lighting effects, static color configuration, per-key RGB painting, key remapping across layers, debounce adjustment, and sleep timers—directly from Chromium-based browsers without requiring Windows, Wine, or virtual machines.

> **Note:** If you open your eyes wide enough, there is a **"Connect keyboard"** button at the very top of the interface. You must click it and select the wired keyboard device before any settings or controls will work.

---

## Features

- **Backlight Effect Control:** Switch between all 18 built-in lighting patterns (plus Off) with configurable brightness and animation speed.
- **Custom Color Picker:** Select custom solid colors via a full RGB/Hex picker for supported effect modes.
- **Per-Key RGB Customization:** Interactive keyboard canvas to paint custom colors on individual keys.
- **Key Remapping:** Visual key remapping for both the **Default (Base)** and **FN1** layers with HID usage code validation (F1–F12 reserved by firmware).
- **Hardware Debounce Tuning:** Set switch debounce latency from 1 ms to 5 ms.
- **Sleep Timer Configuration:** Set automatic backlight sleep timeout from 0 (disabled) to 60 minutes.
- **Real-Time LED Streaming:** Stream live procedural and audio-reactive animations at up to 30 FPS.
- **Profile Management:** Save, load, and export/import configuration profiles via Base64 strings.
- **Non-Destructive Snapshots:** Backup current keyboard flash regions to local storage with one-click restore.
- **Hardware Factory Reset:** Trigger firmware defaults via software or built-in hardware combinations.

---

## Connection Modes & Hardware Compatibility

| Connection Mode | USB VID:PID | Supported Features |
| :--- | :--- | :--- |
| **Wired USB-C** | `258A:010C` | **Full Support:** RGB presets, colors, per-key lighting, Base/FN1 remapping, debounce, sleep timer, config snapshots. |
| **2.4GHz Wireless** | `3554:FA09` | **Partial Support:** Live per-key streaming animations only. Reading/writing persistent onboard settings over radio is unsupported by the receiver. |
| **Bluetooth** | N/A | **Unsupported:** WebHID cannot communicate with Bluetooth HID devices on Linux in this manner. |

> **Important:** Always connect via the USB-C cable with the physical switch set to **Wired** when configuring settings, colors, or keybinds.

---

## How It Works

### Userspace WebHID Architecture
Rather than requiring a custom kernel module or background daemon running as root, this application operates entirely in userspace using the W3C [WebHID API](https://developer.mozilla.org/en-US/docs/Web/API/WebHID_API) in Chromium. Communication occurs directly between the browser process and the keyboard's `/dev/hidraw` device node.

### Protocol & Packet Handling
The AULA F75 keyboard family (SinoWealth architecture) uses two primary communication channels depending on the interface:

1. **Wired Protocol (520-Byte Feature Reports):**
   - Uses HID Feature Report ID `0x06`.
   - **Configuration Region (`0x00000100`, length 128 bytes):** Read using command `0x84`, written with command `0x04`. Byte offset 10 holds the active effect index. A per-effect table begins at offset 64, holding paired brightness and speed/color-mode bytes.
   - **Color Table (`0x00000100`, length 512 bytes):** Read using command `0x8a`, written with command `0x0a`. Stores RGB values for static palette and custom lighting slots.
   - **Keybind Blobs:** 520-byte payloads structured with a 8-byte header (`0x06 0x03 [layer] 0x00 0x01 0x00 0x00 0xff`), sequential 4-byte key slots (`0x08 + 4 * index`) encoding HID usage page and ID, and terminated with trailer bytes `0x5a 0xa5`.
   - **Direct LED Streaming:** 520-byte Feature Reports (Command `0x08`, zone `0x01`, 122 LEDs) carrying 366 bytes of interleaved RGB data at ~20 FPS.

2. **Wireless 2.4GHz Protocol (20-Byte Output Reports):**
   - Uses Output Report ID `0x13` with command byte `0x88`.
   - Color data is compressed into quantized RGB groups (`[R, G, B, count, index1, ..., indexN]`) and packed into 14-byte payload fragments with an XOR frame checksum.

### Onboard Persistence
When settings or keybinds are applied in Wired mode, changes are written directly to the keyboard microcontroller's flash memory. Once written, settings are permanent across system reboots, cable disconnects, and switching to 2.4GHz or Bluetooth modes.

---

## Requirements & Browser Compatibility

### Browser Requirements
The application requires a browser that implements the WebHID API:
- **Supported:** Chromium, Google Chrome, Brave, Microsoft Edge, Opera, Vivaldi.
- **Unsupported:** Firefox, Zen Browser, Safari, and WebKit-based browsers (these do not implement the WebHID standard).

### System Prerequisites

Here are the tools you need to run this controller. These are the package names for **Arch Linux**—find what they are called in your distribution accordingly (e.g., Debian/Ubuntu, Fedora, openSUSE):

- **`systemd`** (provides `udev` and `udevadm` for device permission management)
- **`git`** (to clone the repository)
- **`nodejs` & `npm`** (v18+ or `bun`) to build and serve the application
- **`chromium`** (or your preferred Chromium-based browser with WebHID support)
- **`curl`** (used by `start.sh` to wait until the local server is ready)

```bash
# On Arch Linux:
sudo pacman -S git nodejs npm chromium curl
```
*(Note: `systemd` / `udev` is already included in base Arch installations).*

---

## Quick Start

Getting started takes just three quick steps:

### 1. Clone the repository
```bash
git clone https://github.com/RustamSheoran/aula-f75.git
cd aula-f75
```

### 2. Install the udev rule (one-time)
Grant your user permission to communicate with the keyboard without root:
```bash
sudo cp udev/99-aula-f75.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger
```
*Unplug and reconnect the USB-C cable once after running this.*

### 3. Run the launcher script
```bash
./start.sh
```
`start.sh` automatically downloads npm dependencies if missing (`npm install`), builds the production app if needed (`npm run build`), and starts the local server at `http://localhost:3000`.

> **Browser Note:** The script looks for `chromium` and opens it automatically. If you use a different Chromium-based browser (such as Brave, Google Chrome, or Edge), simply open `http://localhost:3000` manually in your browser, or edit line 52 of `start.sh` to match your browser binary (also, shame on you if you use Edge on Arch Linux).

---

## Manual Setup / Development

If you prefer to run or build the application manually without `start.sh`:

```bash
cd web
npm install
npm run build
npm start
```
Then navigate to `http://localhost:3000` in Chromium.

For development with live hot-reloading:
```bash
cd web
npm run dev
```

---

## Basic Usage

1. **Connect the Device:**
   - Plug the keyboard in via USB-C and set the physical switch to **Wired**.
   - Open the web interface at `http://localhost:3000`.
   - Click the **Connect keyboard** button in the top navigation bar.
   - When the Chromium device picker appears, select the **AULA F75** vendor interface (the entry exposing Feature Report `0x06`).
2. **Configure Lighting:**
   - Go to the **Effects** tab.
   - Select an effect preset from the grid (e.g., *Reaction*, *Ripples shining*, *Neon stream*).
   - Adjust brightness, speed, and select a custom solid color or toggle colorful mode.
   - Click **Apply** to write changes to onboard memory.
3. **Remap Keys:**
   - Navigate to the **Remap** tab.
   - Select either the **Default** or **FN1** layer.
   - Click any unpinned key on the layout canvas.
   - Select the target key output or click *Disable* / *Reset key*.
   - Click **Apply Layer** to flash the 520-byte layer blob to the device.
4. **Hardware Settings:**
   - Navigate to the **Settings** tab to change debounce timing (1–5 ms) or configure the sleep timeout.

---

## Project Structure

```text
aula-f75-linux-drivers/
├── start.sh                      # Automated startup and browser launcher
├── udev/
│   └── 99-aula-f75.rules         # Udev rules for wired (258A) and wireless (3554:FA09) nodes
├── README.md                     # Project documentation
├── tools/                        # Offline reverse-engineering and verification tools
│   ├── gen-keymap.mjs            # Keymap JSON generator from raw vendor definitions
│   └── hidraw_lab.c              # C-based hidraw test harness for raw feature report probing
└── web/                          # Next.js WebHID web application
    ├── src/
    │   ├── components/           # Frontend user interface panels
    │   │   ├── ConnectionBar.tsx # Top device connection bar and status indicators
    │   │   ├── EffectsPanel.tsx  # Preset lighting effects and color selection
    │   │   ├── PerKeyPanel.tsx   # Visual canvas for per-key RGB assignment
    │   │   ├── RemapPanel.tsx    # Interactive key remapping interface
    │   │   ├── SettingsPanel.tsx # Debounce, sleep timer, and reset triggers
    │   │   ├── AnimationsPanel.tsx # Procedural and audio-reactive streaming engine
    │   │   ├── DeviceInfoCard.tsx# Connected hardware report and configuration reader
    │   │   ├── ProfilesCard.tsx  # Profile management, export, and import dialogs
    │   │   └── MacrosPanel.tsx   # Macro recording interface and hardware debug tools
    │   ├── lib/                  # Protocol implementation and hardware abstraction
    │   │   ├── webhid.ts         # High-level WebHID dispatch and device lifecycle
    │   │   ├── protocol.ts       # USB packet constants, command definitions, effect IDs
    │   │   ├── f75.ts            # 520-byte feature report framing and memory read/writes
    │   │   ├── f75-layout.ts     # Offset mapping, select-byte detection, and calibration
    │   │   ├── keybind.ts        # Layer blob validation, slot offsets, and serialization
    │   │   ├── direct-mode.ts    # Wired 520-byte per-LED streaming and keepalive frames
    │   │   ├── wireless-mode.ts  # 2.4GHz 20-byte output report packager
    │   │   ├── vkmap.ts          # Virtual keycode to HID usage mapping tables
    │   │   └── profiles.ts       # JSON and Base64 profile serialization
    │   └── data/
    │       └── f75-keymap.json   # 75% matrix coordinates, key geometry, and default bindings
    └── package.json              # Build scripts, dependencies, and test runner configurations
```

---

## Known Limitations

- **Onboard Macro Flashing:** The keyboard's proprietary wire format for writing macro sequences to onboard flash memory has not yet been reverse-engineered. Recorded macros are stored locally within the browser.
- **Pinned Function Keys:** Keys F1 through F12 are locked by the keyboard's internal firmware matrix and cannot be remapped.
- **Wireless Configuration:** The 2.4GHz wireless dongle only accepts output reports for real-time animation streaming; onboard lighting presets and keybindings cannot be read or written wirelessly.
- **Exclusive Access:** WebHID establishes an exclusive device claim. If another browser tab or application is holding the keyboard node, connection attempts will fail until the other session is closed.

---

## Safety & Recovery

- **Hardware Factory Reset:** If keyboard lighting or keybindings become unresponsive, press and hold **`Fn` + `Esc`** for 3–5 seconds. This triggers the hardware microcontroller's internal factory reset and restores factory firmware defaults.
- **Snapshot & Restore:** Before experimenting with custom layouts or offsets, use **Snapshot defaults** under the *Macros* tab to store a backup of your configuration region in browser storage. Click **Restore defaults** at any time to re-flash the baseline state.
- **Knob Mode Toggle:** The hardware rotary knob operates in two modes:
  - *Volume Mode (Default):* Rotate for audio volume, short-press for mute/unmute.
  - *Backlight Mode:* Rotate for backlight brightness, short-press to cycle effects.
  - *Toggle:* Press and hold the knob down for **3 to 5 seconds** until the backlights flash to switch modes.

---

## Technical Notes & Calibration

### Safe Offset Discovery
To avoid writing arbitrary test data across the configuration memory, the project implements a zero-write knob probe (`probeSelectViaKnob` in `f75-layout.ts`). By taking snapshots of the 128-byte configuration region while cycling effects via hardware shortcuts, the tool automatically detects which offset tracks the active effect index without performing destructive writes.

### Running Test Suites
The project includes automated unit tests covering keybind blob serialization, matrix offsets, layout mapping, and profile export/import:

```bash
cd web
npm test
```
All tests run locally via Vitest without requiring a physical keyboard connected.

---

## Contributing

Contributions, bug reports, and hardware packet captures are welcome. When submitting changes:
1. Verify TypeScript types: `cd web && npx tsc --noEmit`
2. Run test suites: `cd web && npm test`
3. Document any reverse-engineered offsets or packet structures in the relevant module under `web/src/lib/`.
