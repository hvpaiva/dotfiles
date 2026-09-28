-- Personal keybinding overrides. Omarchy's defaults come from require("default.hypr.omarchy")
-- in hyprland.lua; unbind a default before replacing it. List everything with:
--   omarchy menu keybindings --print

-- Upstream opens a Tmux terminal here; a herdr scratch session instead.
hl.unbind("SUPER + ALT + RETURN")
o.bind("SUPER + ALT + RETURN", "Herdr scratch", "omarchy-launch-terminal herdr --session scratch")
