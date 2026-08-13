-- this lua script written by snad
-- this lua is a part of
-- https://github.com/thisisshihan/mpv-player-config-snad

--[[
    debug-log.lua - turns on full verbose logging to a file
    ---------------------------------------------------------
    Drop this in scripts\debug-log.lua

    Every time mpv starts, it will write a complete debug log
    (curl calls, on_load hook activity, ffmpeg/demuxer errors,
    yt-dlp/ytdl_hook activity, etc.) to a file called:

        mpv-debug.log

    ...placed in the SAME folder as mpv.exe (i.e. right next to
    mpv.exe, doc, installer, portable_config, etc.
    The file is overwritten fresh each time mpv starts.
]]

local mp = require 'mp'

-- mp.get_script_directory() (which only works for scripts loaded as a
-- folder, not a plain .lua file).
local info = debug.getinfo(1, "S")
local script_path = info.source:sub(1, 1) == "@" and info.source:sub(2) or info.source

-- script_path looks like: .../portable_config/scripts/debug-log.lua
local mpv_root = script_path:match("^(.*)[/\\][Pp]ortable_config[/\\][Ss]cripts[/\\]")
    or script_path:match("^(.*)[/\\][Ss]cripts[/\\]")

if not mpv_root then
    -- fallback: just log next to the script itself
    mpv_root = script_path:match("^(.*)[/\\][^/\\]+$") or "."
end

local log_path = mpv_root .. "/mpv-debug.log"

mp.set_property("options/log-file", log_path)
mp.set_property("options/msg-level", "all=debug")

mp.msg.info("[debug-log] verbose logging enabled -> " .. log_path)
mp.osd_message("Debug logging ON -> " .. log_path, 3)
