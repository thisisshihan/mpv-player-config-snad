-- hdr-helper.lua script written by snad
-- this lua is a part of
-- https://github.com/thisisshihan/mpv-player-config-snad
-- HDR video (PQ/HLG): enables HDR output and shows an "HDR" badge (top right)
-- SDR video: disables HDR output and hides the badge

local mp = require 'mp'

local overlay = mp.create_osd_overlay("ass-events")
overlay.res_x = 1280
overlay.res_y = 720

local function hdr_kind()
    local g = mp.get_property("video-params/gamma")
    if g == "pq" then return "HDR" end
    if g == "hlg" then return "HDR (HLG)" end
    return nil
end

local function apply()
    local kind = hdr_kind()
    if kind then
        mp.set_property("target-colorspace-hint", "yes")
        mp.set_property("hdr-compute-peak", "yes")
        overlay.data = "{\\an9\\pos(1250,20)\\fs28\\b1\\bord2\\1c&HFFFFFF&\\3c&H000000&\\1a&H10&}" .. kind
        overlay:update()
    else
        mp.set_property("target-colorspace-hint", "no")
        overlay:remove()
    end
end

mp.observe_property("video-params/gamma", "string", apply)
mp.register_event("end-file", function() overlay:remove() end)