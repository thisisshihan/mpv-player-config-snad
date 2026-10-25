-- hdr-helper.lua script written by snad
-- this lua is a part of
-- https://github.com/thisisshihan/mpv-player-config-snad
-- HDR video (PQ/HLG): enables HDR output
-- SDR video: disables HDR output

local mp = require 'mp'

local function is_hdr()
    local g = mp.get_property("video-params/gamma")
    return g == "pq" or g == "hlg"
end

local function apply()
    if is_hdr() then
        mp.set_property("target-colorspace-hint", "yes")
        mp.set_property("hdr-compute-peak", "yes")
    else
        mp.set_property("target-colorspace-hint", "no")
    end
end

mp.observe_property("video-params/gamma", "string", apply)
