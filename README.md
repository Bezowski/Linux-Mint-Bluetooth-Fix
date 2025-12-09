# Linux Mint 22.2 Bluetooth Audio Stuttering Fix

## Problem
On Linux Mint 22.2 with PipeWire/Wireplumber, Bluetooth audio becomes choppy and stutters after a few hours of use. The only temporary workaround was a full Bluez purge/reinstall.

## Root Cause
Wireplumber attempts to negotiate HFP (Hands-Free Profile) with Bluetooth devices even though HFP is disabled in the Bluez daemon. This creates conflicting connection states that degrade audio quality over time, causing stuttering and eventually complete audio transport failures.

## Solution
Disable HFP entirely in Wireplumber's configuration, keeping only A2DP (stereo audio) and LE Audio profiles.

## Installation

1. Copy the config file:
```bash
sudo cp 50-bluez-config.lua /etc/wireplumber/bluetooth.lua.d/
```

2. Restart Wireplumber:
```bash
systemctl --user restart wireplumber
```

3. Re-pair your Bluetooth devices in Blueman or Settings.

## Verification

Check that Wireplumber is running without HFP errors:
```bash
journalctl --user-unit wireplumber -n 20
```

You should NOT see messages like:
- "RFCOMM receive command but modem not available"
- "Failure in Bluetooth audio transport"
- "Acquire returned error"

## Testing
Audio should remain stable indefinitely. If stuttering returns after several days, check the logs above.

## What this changes
- **Disabled**: hfp_hf, hfp_ag, hsp_hs, hsp_ag (Hands-Free and Headset profiles)
- **Enabled**: a2dp_sink, a2dp_source, bap_sink, bap_source (Stereo audio profiles)

Since most users only need stereo audio from Bluetooth headphones/speakers, HFP is unnecessary and was actually causing the problem.
