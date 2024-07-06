#!/bin/bash
. /opt/frontend/env
export SERVER GOOGLE_LOCATION_KEY AUDIO_DEVICE
exec /opt/frontend/frontend
