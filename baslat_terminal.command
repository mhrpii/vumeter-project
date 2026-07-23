#!/bin/bash
cd "$(dirname "$0")"
pkill -f native_proto_mac 2>/dev/null
pkill -f "cava -p" 2>/dev/null
sleep 2
exec python3 -u native_proto_mac.py "Spektrum"
