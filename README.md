# I-NOVA TV Lift ESPHome BLE Controller

ESPHome configuration to control an **I-NOVA TV lift** via Bluetooth Low Energy (BLE) using an ESP32 and Home Assistant.

The BLE protocol was reverse-engineered from the I-NOVA Android app (v1.7).

## Features

- **Up / Down / Stop** controls with configurable height limits
- **3 programmable height presets** adjustable from Home Assistant
- **Cover entity** with real position tracking (0% = down, 100% = up) and position commands
- **Real-time current height** sensor from BLE notifications
- **Device min/max limits** auto-detected from the lift controller
- **Automatic BLE device discovery** (no need to hardcode the MAC address)
- **WiFi captive portal** for easy setup (no hardcoded WiFi credentials)
- All settings **persist across reboots**

## Hardware Required

- **ESP32** development board (any ESP32 with BLE support)
- **I-NOVA TV lift** with BLE controller (tested with I-NOVA 1.7)

## Installation

### 1. Install ESPHome

```bash
pip install esphome
```

### 2. Create secrets file

Create a `secrets.yaml` file in the same directory:

```yaml
ota_password: "your_ota_password"
ap_password: "your_ap_password"  # min 8 characters
```

### 3. Flash the ESP32

Via USB:
```bash
esphome run tv_lift_esphome.yaml --device /dev/cu.usbserial-0001
```

Via OTA (if already running ESPHome):
```bash
esphome run tv_lift_esphome.yaml --device <IP_ADDRESS>
```

### 4. WiFi Setup

On first boot, the ESP32 creates a WiFi access point named **"TV Lift Setup"**.

1. Connect to it with the password from your `secrets.yaml`
2. A captive portal opens automatically
3. Enter your WiFi network credentials
4. The ESP32 saves them and connects on subsequent boots

### 5. BLE Pairing

The ESP32 automatically scans for I-NOVA devices on boot. When found, it saves the MAC address and connects. You can also manually set the BLE address from Home Assistant via the **"TV Lift BLE Address"** text entity.

## Home Assistant Entities

### Controls
| Entity | Type | Description |
|--------|------|-------------|
| TV Lift | Cover | Up/Down/Stop with real position slider |
| TV Lift Up | Button | Move to upper limit |
| TV Lift Down | Button | Move to lower limit |
| TV Lift Stop | Button | Stop movement |
| TV Lift Program 1 | Button | Go to Program 1 height |
| TV Lift Program 2 | Button | Go to Program 2 height |
| TV Lift Program 3 | Button | Go to Program 3 height |

### Configuration
| Entity | Type | Default | Description |
|--------|------|---------|-------------|
| TV Lift Upper Limit | Number | device max | Maximum height for Up button (clamped to device max) |
| TV Lift Lower Limit | Number | device min | Minimum height for Down button (clamped to device min) |
| TV Lift Program 1 Height | Number | 93.5 cm | Program 1 target height |
| TV Lift Program 2 Height | Number | 181 cm | Program 2 target height |
| TV Lift Program 3 Height | Number | 130 cm | Program 3 target height |

### Status
| Entity | Type | Description |
|--------|------|-------------|
| TV Lift Current Height | Sensor | Real-time height in cm |
| TV Lift Connected | Binary Sensor | BLE connection status |
| TV Lift Discovered Device | Text Sensor | Last discovered I-NOVA MAC |
| TV Lift BLE Address | Text | Configured BLE MAC address |
| TV Lift Device Min Height | Sensor | Device minimum height (diagnostic) |
| TV Lift Device Max Height | Sensor | Device maximum height (diagnostic) |

## BLE Protocol Reference

Reverse-engineered from the I-NOVA 1.7 Android APK.

### UUIDs

| Name | UUID |
|------|------|
| Service | `0000fee0-0000-1000-8000-00805f9b34fb` |
| Write Characteristic | `0000fee2-0000-1000-8000-00805f9b34fb` |
| Notify Characteristic | `0000fee1-0000-1000-8000-00805f9b34fb` |

### Commands

All commands start with `0xA5` (header), followed by length, command byte, optional parameters, and a checksum.

| Command | Bytes (hex) | Description |
|---------|-------------|-------------|
| Up | `A5 03 12 15` | Move up continuously |
| Down | `A5 03 14 17` | Move down continuously |
| Stop | `A5 03 10 13` | Stop movement |
| Go to height | `A5 05 31 HH LL CS` | Move to specific height |
| Get device info | `A5 03 21 24` | Query current height/limits |
| Lock | `A5 04 32 01 37` | Enable child lock |
| Unlock | `A5 04 32 00 36` | Disable child lock |

### Go-to-height encoding

Height is encoded as `height_cm * 10` in 16-bit big-endian:

```
HH = (height_cm * 10) >> 8) & 0xFF
LL = (height_cm * 10) & 0xFF
Checksum = (0x05 + 0x31 + HH + LL) & 0xFF
```

**Example:** 93.5 cm = 935 = `0x03A7`
```
A5 05 31 03 A7 E0
```

### Response format

Responses start with `0x5A`:

| Type | Format | Description |
|------|--------|-------------|
| Device info | `5A 09 21 [cur_h] [cur_l] [min_h] [min_l] [max_h] [max_l]` | Current height + device limits |
| Height update | `5A 06 xx [h_h] [h_l] [error]` | Real-time height during movement |

All height values are `value / 10.0` to get cm.

## License

MIT
