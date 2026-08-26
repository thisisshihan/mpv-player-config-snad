-- Simple live clock for mpv
-- this clock.lua script written by snad
-- this lua is a part of mpv.snad
-- https://github.com/thisisshihan/mpv-player-config-snad

local clock = mp.create_osd_overlay("ass-events")
local enabled = false

-- Clock position
-----------------------------------------------------------
local clock_x = 25
local clock_y = 700

local function update_clock()
    if not enabled then
        clock.data = ""
        clock:update()
        return
    end

    local time = os.date("%H:%M") -- ("%H:%M:%S")

    -- Get MPV OSD font settings
    local font = mp.get_property("osd-font") or "sans-serif"
    local font_size = mp.get_property_number("osd-font-size")*0.75 or 28

    clock.data = string.format(
        "{\\an1\\pos(%d,%d)\\fn%s\\fs%d\\bord2\\shad1}%s",
        clock_x,
        clock_y,
        font,
        font_size,
        time
    )

    clock:update()
end

-- TOGGLE
-----------------------------------------------------------
local function toggle_clock()
    enabled = not enabled

    update_clock()

    if enabled then
        mp.osd_message("Clock: ON", 1)
    else
        mp.osd_message("Clock: OFF", 1)
    end
end

mp.add_forced_key_binding("w", "toggle", toggle_clock)

-- Update/redraw every 30 seconds
-----------------------------------------------------------
mp.add_periodic_timer(30, update_clock)
update_clock()
