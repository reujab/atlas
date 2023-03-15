snap install --dangerous ./atlas*.snap
snap connect atlas:hardware-observe
snap connect atlas:process-control
snap connect atlas:alsa
snap connect atlas:joystick
snap connect atlas:shutdown
