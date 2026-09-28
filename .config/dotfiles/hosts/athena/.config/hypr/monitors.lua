-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- The dock's built-in display, never used.
hl.monitor({ output = "desc:Agilent Technologies 1080p60", disabled = true })

-- Any other monitor: preferred mode, automatic position, no scaling.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Laptop panel on the left, the ultrawide over HDMI on the right.
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "3440x1440@49.95", position = "1920x0", scale = 1, bitdepth = 8 })
