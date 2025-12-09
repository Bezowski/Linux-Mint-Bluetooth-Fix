# Linux Mint 22.2 Bluetooth Audio Stuttering Fix

## Problem
On Linux Mint 22.2 with PipeWire/Wireplumber, Bluetooth audio becomes choppy and stutters after a few hours of use.

## Root Causes
Two separate issues can cause this:

### Issue 1: HFP Profile Conflicts (Fixed)
Wireplumber attempts to negotiate HFP (Hands-Free Profile) with Bluetooth devices even though HFP is disabled in the Bluez daemon. This creates conflicting connection states that degrade audio quality over time.

Some devices (notably Bose QuietComfort 35 II) actively advertise Headset and Handsfree UUIDs even after plugins are disabled, causing bluetoothd to repeatedly try to use these profiles.

**Solution:** Disable HFP entirely in Wireplumber's configuration and block problematic UUIDs in Bluetooth's main.conf.

### Issue 2: Bluetooth Driver Settings (Fixed)
On Intel Centrino Bluetooth adapters (ID 8087:07da), the Enhanced Retransmission Mode (ERTM) and autosuspend in the Bluetooth driver cause link layer timeouts and connection failures.

**Solution:** Disable ERTM and autosuspend in the btusb driver configuration.

## Installation

### Step 1: Disable HFP in Wireplumber

Copy the config file:
```bash
sudo mkdir -p /etc/wireplumber/bluetooth.lua.d
sudo cp 50-bluez-config.lua /etc/wireplumber/bluetooth.lua.d/
systemctl --user restart wireplumber
```

### Step 2: Fix Bluetooth Driver Settings

Create/edit the driver config:
```bash
sudo nano /etc/modprobe.d/bluetooth.conf
```

Add:
```
options btusb disable_autosuspend=1
options bluetooth disable_ertm=1
options btusb enable_autosuspend=0
options hci_usb disable_sco=1
```

Reload the driver:
```bash
sudo modprobe -r btusb
sudo modprobe btusb
sudo systemctl restart bluetooth
```

### Step 2: Fix Bluetooth Driver Settings

Create/edit the driver config:
```bash
sudo nano /etc/modprobe.d/bluetooth.conf
```

Add:
```
options btusb disable_autosuspend=1
options bluetooth disable_ertm=1
options btusb enable_autosuspend=0
options hci_usb disable_sco=1
```

Reload the driver:
```bash
sudo modprobe -r btusb
sudo modprobe btusb
sudo systemctl restart bluetooth
```

### Step 3: Block Problematic UUIDs (For Devices Like Bose QC35 II)

Some devices (especially Bose QuietComfort 35 II) advertise Headset and Handsfree UUIDs even though these profiles are disabled. This causes bluetoothd to repeatedly try using these profiles, causing stuttering.

Edit the Bluetooth configuration:
```bash
sudo nano /etc/bluetooth/main.conf
```

Find the `[General]` section and add/modify:
```
[General]
Disable=headset,gateway,hfp
```

Then scroll to the bottom and add a new section:
```
[BlockedUUIDs]
# Block Headset and Handsfree profiles for devices that advertise them
00001108-0000-1000-8000-00805f9b34fb=true
0000111e-0000-1000-8000-00805f9b34fb=true
```

Save and restart:
```bash
sudo systemctl daemon-reload
sudo systemctl restart bluetooth
systemctl --user restart wireplumber
```

### Step 4: Re-pair Devices

```bash
bluetoothctl
[bluetooth]# remove <device_mac>
[bluetooth]# scan on
[bluetooth]# pair <device_mac>
[bluetooth]# connect <device_mac>
[bluetooth]# exit
```

Then restart Wireplumber:
```bash
systemctl --user restart wireplumber
```

## Verification

Check that Wireplumber is running without HFP errors:
```bash
journalctl --user-unit wireplumber -n 20
```

Check that Bluetooth link layer is stable:
```bash
dmesg | grep -i timeout
```

You should NOT see:
- "RFCOMM receive command but modem not available"
- "Failure in Bluetooth audio transport"
- "link tx timeout"

## What This Changes

### Wireplumber
- **Disabled**: hfp_hf, hfp_ag, hsp_hs, hsp_ag (Hands-Free and Headset profiles)
- **Enabled**: a2dp_sink, a2dp_source, bap_sink, bap_source (Stereo audio profiles)

### Bluetooth Driver
- **Disabled**: ERTM (Enhanced Retransmission Mode) - incompatible with certain codecs
- **Disabled**: Autosuspend - keeps adapter fully powered
- **Disabled**: SCO (voice over Bluetooth) - not needed for audio streaming

### Audio Codec
- **Works fine**: All codecs (SBC-XQ, AAC, aptX, etc.) once driver is properly configured

## Hardware Info
Tested on:
- Intel Centrino Bluetooth Wireless Transceiver (ID 8087:07da)
- Linux Mint 22.2 (Ubuntu 24.04)
- AirPods Pro
- Bose QuietComfort 35 II

## Troubleshooting

**Still getting stuttering?**
- Check that the driver config was properly loaded: `cat /etc/modprobe.d/bluetooth.conf`
- Verify ERTM is disabled: `sudo modprobe -r btusb && sudo modprobe btusb`
- Run `dmesg | grep -i timeout` - if you see "link tx timeout", the driver fix didn't load properly
- Try restarting Bluetooth: `sudo systemctl restart bluetooth`

**For Bose or similar devices that keep causing HFP errors:**
- Check `/etc/bluetooth/main.conf` has the `[BlockedUUIDs]` section with the two UUIDs listed
- Remove and re-pair the device: `bluetoothctl remove <mac>`
- Check logs: `journalctl -f | grep -i "bluetooth\|audio"` - should not show HFP-related errors
