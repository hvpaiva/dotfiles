-- Ver https://wiki.hypr.land/Configuring/Monitors/
-- Monitores e modos disponíveis: hyprctl monitors all
-- Portado de ~/.config/hypr/monitors.conf (2026-09-22).

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Monitor da doca que não deve ser usado.
hl.monitor({ output = "desc:Agilent Technologies 1080p60", disabled = true })

-- Qualquer outro monitor: modo preferido, posição automática, sem escala.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Tela do notebook à esquerda e o ultrawide HDMI à direita.
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "3440x1440@49.95", position = "1920x0", scale = 1, bitdepth = 8 })
