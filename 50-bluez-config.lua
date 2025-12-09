-- Disable HFP profiles to prevent Bluetooth audio stuttering
bluez_monitor.properties = {
  ["bluez5.roles"] = "[ a2dp_sink a2dp_source bap_sink bap_source ]",
}
