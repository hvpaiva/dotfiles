-- athena: loaded by the shared monitors.lua after its rules.

-- The dock's built-in display, never used.
hl.monitor({ output = "desc:Agilent Technologies 1080p60", disabled = true })

-- Laptop panel on the left, the ultrawide to its right.
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1 })
hl.monitor({ output = "desc:LG Electronics LG ULTRAWIDE", mode = "3440x1440@49.95", position = "1920x0", scale = 1, bitdepth = 8 })
