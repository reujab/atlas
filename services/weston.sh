#!/bin/bash

systemd-notify --status="Waiting for DBUS"
while [[ ! -e $XDG_RUNTIME_DIR ]]; do sleep 0.1; done

systemd-notify --ready --status="Starting weston"
weston
