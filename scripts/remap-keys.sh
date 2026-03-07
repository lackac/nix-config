#!/bin/sh

# All keyboards: Caps Lock → Left Control, Left Control → F19
hidutil property \
  --matching '{"PrimaryUsagePage":1,"PrimaryUsage":6}' \
  --set '{"UserKeyMapping":[
    {"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000e0},
    {"HIDKeyboardModifierMappingSrc":0x7000000e0,"HIDKeyboardModifierMappingDst":0x70000006e}
  ]}'

# Internal keyboard: same + § (ISO extra key) ↔ Escape
hidutil property \
  --matching '{"ProductID":0x0,"VendorID":0x0,"PrimaryUsagePage":1,"PrimaryUsage":6}' \
  --set '{"UserKeyMapping":[
    {"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000e0},
    {"HIDKeyboardModifierMappingSrc":0x7000000e0,"HIDKeyboardModifierMappingDst":0x70000006e},
    {"HIDKeyboardModifierMappingSrc":0x700000064,"HIDKeyboardModifierMappingDst":0x700000035},
    {"HIDKeyboardModifierMappingSrc":0x700000035,"HIDKeyboardModifierMappingDst":0x700000064}
  ]}'

# ZSA Voyager: no remapping (firmware handles everything)
hidutil property \
  --matching '{"ProductID":0x1977,"VendorID":0x3297}' \
  --set '{"UserKeyMapping":[]}'

# splitkb keyboards: no remapping (firmware handles everything)
hidutil property \
  --matching '{"ProductID":0x3a07,"VendorID":0x8d1d}' \
  --set '{"UserKeyMapping":[]}'
