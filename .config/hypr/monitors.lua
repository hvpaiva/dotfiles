-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all
--
-- Shared by every host: the same LG ultrawide sits on all of them (direct HDMI on zeus,
-- through the dock on athena), matched by description so the port does not matter.
-- What only one host has (a laptop panel, a dock display) goes in monitors.local.lua,
-- from hosts/<host>; a rule there for the same output replaces the one here.

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Any monitor: preferred mode, automatic position, no scaling.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- The ultrawide, at the mode it is stable on over HDMI.
hl.monitor({ output = "desc:LG Electronics LG ULTRAWIDE", mode = "3440x1440@49.95", position = "auto", scale = 1, bitdepth = 8 })

local local_rules = os.getenv("HOME") .. "/.config/hypr/monitors.local.lua"
local f = io.open(local_rules)
if f then
  f:close()
  dofile(local_rules)
end
