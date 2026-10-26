-- snad-osc.lua script written by snad
-- this lua is a part of
-- https://github.com/thisisshihan/mpv-player-config-snad
-- Config file: script-opts/snad_osc.conf
--
-- Features (all layouts): title, quality badges, chapter-segmented seek bar with buffer, hover
-- time / chapter (+ real thumbnails when the "thumbfast" script is installed), elapsed/remaining
-- toggle, prev/next, skip back/forward, volume slider + mute, one tracks button (subtitle / audio / speed menu) with
-- track lists and delay steppers, load-subtitle button (Windows), loop, playlist + chapters drawer,
-- fullscreen, clock with "Ends at", pin-on-top / minimize / maximize / close.

local mp = require "mp"
local utils = require "mp.utils"

local opts = {
    layout = "streamer",        -- streamer | pill | center | default (default = mpv's own OSC)
    accent = "1E9BE9",          -- RRGGBB
    font = "Segoe UI",
    symbol_font = "Segoe UI Symbol",
    scale = 0.85,               -- overall UI size multiplier
    hide_timeout = 3,           -- seconds of inactivity before the UI hides
    via = "mpv",                -- text after "via" in the info line
    use_12h = true,             -- 4:58 pm clock (false = 16:58)
    skip_seconds = 10,          -- back/forward button step
    seek_lift = 0,              -- raise the title + info pills + seek bar block this many px (streamer/center layouts; 0 = default)
    ind_enabled = true,  -- master switch for the volume/seek/speed/... indicator pills
    ind_hide_native_osd = true,  -- set osd-level=0 so mpv's own volume/seek text is not shown as well
    ind_position = "top",  -- top | bottom
    ind_margin = 18,  -- distance from the screen edge
    ind_scale = 1.0,  -- indicator size
    ind_duration = 1.2,  -- seconds visible
    ind_fade = 0.25,  -- fade-out seconds (0 = instant)
    ind_accent = "",  -- slider fill colour (RRGGBB); empty = use the main accent
    ind_style = "",  -- dark | glass (white, see-through) | darkglass (dark, see-through); empty = same as panel_style
    ind_panel_color = "",  -- pill colour (RRGGBB); empty = taken from the style
    ind_panel_opacity = -1,  -- 0 clear .. 1 solid; -1 = taken from the style
    ind_border = true,  -- thin light edge
    ind_shadow = true,  -- soft drop shadow
    ind_font = "",  -- empty = default font
    ind_font_size = 13,
    ind_bar_width = 110,  -- slider length
    ind_delay_buttons = true,  -- small - / + discs on the delay pills
    ind_seek_min = 1.0,  -- ignore seek jumps smaller than this (seconds)
    ind_show_volume = true,
    ind_show_mute = true,
    ind_show_speed = true,
    ind_show_seek = true,
    ind_show_sub_delay = true,
    ind_show_audio_delay = true,
    ind_show_picture = true,  -- brightness / contrast / gamma / saturation / hue
    sub_lift = 22,              -- move subtitles up by this % of the window height while the controls are visible (0 = off)
    show_playlist_pos = true,   -- [02/10] next to the title when the playlist has more than one item
    context_menu = true,        -- right-click opens a themed copy of mpv's context menu (no = keep the native one)
    ctx_font_size = 13,         -- context menu text size (before the global scale)
    ctx_row_height = 30,        -- context menu row height
    ctx_history = true,         -- "History" entry in the menu becomes a submenu listing recent files
    ctx_history_items = 12,     -- how many recent files it lists
    ctx_shortcuts = true,
    ctx_shortcut_keys = 2,      -- max key bindings shown per entry (0 = same as ctx_shortcuts=no)
    ctx_min_width = 150,        -- narrowest menu panel
    ctx_max_width = 280,        -- widest menu panel (longer titles are cut with ...)       -- show key bindings on the right
    idle_logo = true,           -- empty player (nothing loaded): hand over to mpv's own OSC so its logo shows (needs osc=yes in mpv.conf)
    seek_wave = false,          -- Android-style animated wavy seek bar (played part waves, knob glows)
    wave_follow_accent = true,  -- yes = the wave uses shades of `accent` (wave_colors is ignored)
    wave_colors = "3B9DFF,9B5CF6,FF3B5C", -- gradient along the played part: comma-separated RRGGBB list
    wave_style = "fill",        -- fill = layered translucent humps over a white line (Android music-player look) | line = single wavy line
    wave_opacity = 0.65,        -- opacity of the humps (fill style)
    wave_baseline = "accent",   -- straight line under the humps (fill style): accent | RRGGBB | empty = follow the gradient
    wave_amplitude = 12,         -- wave height in pixels (before the global scale)
    wave_length = 34,           -- distance between wave crests
    wave_speed = 1.0,           -- wave travel speed (0 = still)
    wave_fps = 20,              -- animation smoothness (frames per second while playing); lower = lighter
    wave_thickness = 3.5,         -- line thickness
    wave_flat_when_paused = true,  -- the wave settles to a straight line while paused
    show_chapter_buttons = true, -- previous / next CHAPTER buttons (|< >| icons) next to the playlist buttons (single triangle)
    disabled_color = "6B7078",  -- colour of a button that cannot be used now (no chapters, no playlist ...)
    history = true,             -- "History" tab in the playlist drawer (recently played files, kept between sessions)
    history_source = "auto",    -- auto | mpv | own: auto uses mpv's built-in watch history when save-watch-history=yes is set in mpv.conf, otherwise a list kept by this script
    history_max = 50,           -- how many entries to keep
    history_resume = true,      -- picking an entry resumes where you stopped
    history_file = "~~/snad-osc-history.json", -- where the list is stored (~~/ = your mpv config folder)
    loop_playlist = true,       -- the loop button cycles: off -> loop this file (1) -> loop the playlist (all) -> off (no = file loop only)
    show_clock = true,
    active_style = "border",    -- how a toggled-on button looks (tracks / loop / playlist / fullscreen / volume): border | fill | both | none
    active_fill = "darkglass",  -- fill look for active_style=fill|both: dark | glass | darkglass
    active_fill_color = "",     -- fill colour (RRGGBB); empty = taken from active_fill
    active_fill_opacity = -1,   -- fill opacity 0..1; -1 = taken from active_fill
    highlight_active = true,    -- accent-colour the tracks / loop icons when subtitles, non-1x speed or loop are active (open panels always get a ring)
    title_pinned = false,       -- keep the top-left title / path (with [02/10]) visible when the controls are hidden (click it to toggle)
    clock_pinned = false,       -- keep the clock + "Ends at" on screen when the controls are hidden (click the clock to toggle)
    show_window_controls = true,
    show_audio_button = true,   -- "audio only" switch in the window-control group (video files: show the audio skin instead of the picture)
    thumbfast = true,           -- use the thumbfast script for hover thumbnails if present
    volume_style = "vertical",  -- vertical = click the speaker to open a vertical slider popup | horizontal = inline slider
    winctl_color = "FFFFFF",    -- background of the pin / minimize / maximize / close group (RRGGBB)
    winctl_opacity = 0.22,      -- 0 = no background, 1 = solid
    show_layout_hint = false,   -- show "snad-osc vX  layout: name" on screen when a file starts (for troubleshooting)
    click_to_pause = false,    -- click on the video (not on a control) toggles pause
    exclusive_panels = true,   -- only one panel open at a time (tracks menu / playlist drawer / info card / volume popup / right-click menu)
    drawer_width = 0,          -- playlist drawer width in px (before scale); 0 = automatic
    drawer_width_pct = 0,      -- playlist drawer width as % of the window width; 0 = off (wins over drawer_width)
    info_lift = 0,             -- raise ONLY the title + info pills this many px (streamer/center layouts)
    center_pills_below = false, -- center layout: info pills on their own row below the title, left aligned
    ctx_hide = "",             -- right-click menu entries to remove, comma separated (e.g. "Stop, Quit and save position, Window/Stay on top")
    show_info_button = true,   -- media info card button in the right-hand button group
    audio_layout = "card",     -- skin for audio files (no real video): card = "Now Playing" card | off = use the normal layout
    audio_default = true,       -- yes = audio files open in the audio skin | no = they open in the normal layout (the note button switches the skin on)
    audio_fit_window = true,    -- audio files: crop a taller-than-16:9 window down to 16:9 when playback starts (Windows)
    audio_cover_pos = "left",  -- left (always the card layout) | center (stacked, opt-in only)
    audio_scale = 1.0,         -- size multiplier of the audio skin
    audio_bg = "0A0C12",       -- background colour of the audio skin (RRGGBB); also the colour outside the rounded cover
    audio_glow = true,
    audio_glow_color = "cover",  -- cover = glow colours taken from the album art | accent = accent colour + blue         -- soft accent glow behind the cover
    hide_buttons = "",         -- buttons to hide, comma separated: play prev next chprev chnext back fwd volume time clock info tracks loop playlist fullscreen pin min max close (window = all four window buttons)
    native_border = false,     -- no = the script sets border=no (frameless window, uses the window buttons of the OSC)
    window_corners = "default", -- Windows 11 window corners (set through DWM, like a normal OS window): default (leave as is) | round | small | none
    win_border = 0,            -- window border line width in px; 0 = off
    win_border_color = "FFFFFF",
    win_border_opacity = 0.35,
    time_pill = false,         -- filled pill behind the time label
    time_pill_style = "darkglass", -- dark | glass | darkglass | accent
    time_pill_color = "",      -- RRGGBB; empty = taken from the style
    time_pill_opacity = -1,    -- 0..1; -1 = taken from the style
    title_two_lines = false,   -- a title that is too long wraps onto a second line instead of shrinking / being cut (streamer + center layouts)

    -- tracks menu + playlist/chapters drawer (fonts are never scaled by these)
    panel_scale = 0.85,         -- geometry scale of the panels; 1 = original size, 0.7 = compact
    panel_round_rows = true,    -- fully rounded (pill) rows and round number badges in the menus / playlist drawer
    panel_row_height = 38,      -- height of track / playlist / chapter rows
    panel_pill_height = 26,     -- speed chips, tabs and +/- delay buttons
    panel_text_shadow = false,  -- text shadow inside the panels
    panel_style = "dark",       -- dark | glass (white, see-through) | darkglass (dark, see-through)
    panel_blur = false,         -- EXPERIMENTAL: blur the video behind the panels (needs vo=gpu or gpu-next)
    panel_blur_radius = 10,     -- blur strength in pixels
    panel_blur_taps = 32,       -- blur quality (samples per pixel): 16 fast ... 48 smooth
    panel_style_all = false,    -- yes = window controls, info pills and seek tooltip share the panel_* look (style / colour / opacity / blur)
    panel_color = "",           -- background colour (RRGGBB); empty = taken from panel_style
    panel_opacity = -1,         -- background opacity 0..1; -1 = taken from panel_style

    -- info pills (4K / HDR / audio / CC / speed / loop)
    pill_font_size = 12,        -- text size (before the global scale)
    pill_height = 17,           -- pill height
    pill_padding = 8,           -- left/right padding inside the pill
    pill_gap = 5,               -- space between pills
    pill_bold = true,
    pill_color = "FFFFFF",      -- fill colour (RRGGBB)
    pill_opacity = 0.22,        -- fill opacity: 0 = invisible, 1 = solid
    pill_text_color = "FFFFFF", -- text colour (use a dark colour with a high pill_opacity)
    pill_text_opacity = 1,
    pill_border_width = 0,      -- outline thickness, 0 = none
    pill_border_color = "FFFFFF",
    pill_border_opacity = 0.6,
    tip_position = "below",     -- seek hover time tooltip: above | below the seek bar (thumbnails always go above)
    tip_gap = 8,                -- distance between the seek bar and the tooltip
    tip_font_size = 13,         -- seek hover tooltip: time text size (before the global scale)
    tip_height = 21,            -- tooltip height (add ~14 more when a chapter name is shown)
    tip_color = "FFFFFF",       -- tooltip fill colour
    tip_opacity = 0.22,         -- tooltip fill opacity: 0 = invisible, 1 = solid
    tip_text_color = "FFFFFF",
    tip_shadow = false,         -- text shadow in the tooltip
    pill_fps_round = true,      -- round the frame rate: 23.976 -> 24, 29.97 -> 30, 59.94 -> 60 (no = exact)
    pill_show_fps = true,       -- frame rate (24 / 29.97 / 60 fps)
    pill_show_resolution = true,
    pill_show_hdr = true,       -- HDR10 / Dolby Vision / Atmos
    pill_show_vcodec = true,    -- video codec (H.264, HEVC, AV1 ...)
    pill_show_audio = true,     -- audio language + channels
    pill_show_acodec = true,    -- audio codec (AAC, E-AC-3, DTS ...)
    pill_show_subtitle = true,  -- currently selected subtitle track
    pill_show_speed = true,     -- only shown when speed is not 1x
    pill_show_loop = true,      -- only shown when loop is on
    pill_show_chapter = true,   -- chapter pill (streamer layout)
}
-- Own config reader (instead of mp.options) so comments may sit at the END of a line:
--     scale=0.85        # overall size
-- A comment starts at a "#" that follows whitespace; whole-line "#" comments work too.
-- --script-opts=snad_osc-<name>=<value> on the command line is honoured as well.
local function convert(key, raw)
    local def = opts[key]
    raw = raw:match("^%s*(.-)%s*$")
    if type(def) == "boolean" then
        local v = raw:lower()
        return v == "yes" or v == "true" or v == "1" or v == "on"
    elseif type(def) == "number" then
        return tonumber(raw) or def
    end
    return (raw:gsub('^"(.*)"$', "%1"))
end

local function load_options()
    local path = mp.find_config_file and mp.find_config_file("script-opts/snad_osc.conf")
    local fh = path and io.open(path, "r")
    if fh then
        for raw in fh:lines() do
            local line = raw:gsub("\r$", ""):gsub("^\239\187\191", "")
            if not line:match("^%s*#") then
                line = line:gsub("%s+#.*$", "")
                local key, val = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
                if key and opts[key] ~= nil then opts[key] = convert(key, val) end
            end
        end
        fh:close()
    end
    local ok, so = pcall(mp.get_property_native, "options/script-opts")
    if ok and type(so) == "table" then
        for k, v in pairs(so) do
            local key = tostring(k):match("^snad_osc%-(.+)$")
            if key and opts[key] ~= nil then opts[key] = convert(key, tostring(v)) end
        end
    end
end
load_options()

-- tolerate stray text after the layout name
local function norm_layout(v)
    v = tostring(v):gsub("#.*$", "")
    return (v:match("^%s*([%w_]+)") or ""):lower()
end
opts.layout = norm_layout(opts.layout)

-- ===== INDICATORS (volume / mute / speed / seek / delays / picture) =====
-- Floating glass pills; options are ind_* in snad_osc.conf.
-- Script message for your own pill:  script-message snad-indicator <icon> <text...>
local IND = {}                    -- shared with the blur engine further down
do
local o = setmetatable({}, { __index = function(_, k) return opts["ind_" .. k] end })

------------------------------------------------------------------ helpers
local function bgr(hex, fallback)
    hex = tostring(hex or ""):gsub("^#", "")
    if #hex ~= 6 or hex:match("%X") then hex = fallback or "FFFFFF" end
    return hex:sub(5, 6) .. hex:sub(3, 4) .. hex:sub(1, 2)
end

local ACCENT = bgr((o.accent ~= "") and o.accent or opts.accent, "FF0000")

-- pill look, same three modes as panel_style
local function look()
    local st = tostring((o.style ~= "") and o.style or opts.panel_style):lower():gsub("[%s_%-]", ""):match("^%a+") or "dark"
    local glass, dglass = st == "glass", st == "darkglass"
    local blur = opts.panel_blur and (glass or dglass) and true or false
    local c = (o.panel_color ~= "") and o.panel_color or (glass and "FFFFFF" or "0E141C")
    local op = o.panel_opacity
    if op < 0 then
        if blur then op = glass and 0.25 or 0.35
        else op = glass and 0.2 or (dglass and 0.55 or 0.9) end
    end
    return bgr(c, "0E141C"), op, blur
end

-- opacity (0..1) * fade -> ASS alpha byte (00 opaque .. FF clear)
local function A(op, f)
    local v = 255 - math.floor(255 * math.max(0, math.min(1, op * f)) + 0.5)
    return string.format("%02X", v)
end

local function nchars(s)
    return select(2, s:gsub("[^\128-\191]", ""))
end

local function esc(s)
    return (tostring(s):gsub("[{}\\]", "")):gsub("\n", " ")
end

local function fmt_time(t)
    t = math.max(0, math.floor(t + 0.5))
    local h, m, s = math.floor(t / 3600), math.floor(t / 60) % 60, t % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
    return string.format("%d:%02d", m, s)
end

local function fmt_delta(d)
    local sign = d < 0 and "-" or "+"
    d = math.abs(d)
    if d < 60 then return string.format("%s%d s", sign, math.floor(d + 0.5)) end
    local t = math.floor(d + 0.5)
    return string.format("%s%d:%02d", sign, math.floor(t / 60), t % 60)
end

local function fmt_num(v)  -- 1.50 -> 1.5, 2.00 -> 2
    local s = string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", "")
    return s
end

-- scale+translate a 24x24 path
local function tx(path, ox, oy, s)
    local i = 0
    return (path:gsub("%S+", function(tok)
        if tok:match("^%a$") then return tok end
        i = i + 1
        local v = tonumber(tok)
        if i % 2 == 1 then return string.format("%.1f", ox + v * s) end
        return string.format("%.1f", oy + v * s)
    end))
end

local function rrect(x0, y0, x1, y1, r)
    r = math.min(r, (x1 - x0) / 2, (y1 - y0) / 2)
    local c = r * 0.5523
    local f = function(...)
        local t = {...}
        for i = 1, #t do t[i] = string.format("%.1f", t[i]) end
        return table.concat(t, " ")
    end
    return table.concat({
        "m " .. f(x0 + r, y0),
        "l " .. f(x1 - r, y0),
        "b " .. f(x1 - r + c, y0, x1, y0 + r - c, x1, y0 + r),
        "l " .. f(x1, y1 - r),
        "b " .. f(x1, y1 - r + c, x1 - r + c, y1, x1 - r, y1),
        "l " .. f(x0 + r, y1),
        "b " .. f(x0 + r - c, y1, x0, y1 - r + c, x0, y1 - r),
        "l " .. f(x0, y0 + r),
        "b " .. f(x0, y0 + r - c, x0 + r - c, y0, x0 + r, y0),
    }, " ")
end

------------------------------------------------------------------ icons (24x24)
-- fill = solid shapes, stroke = lines (open lines are drawn there-and-back so
-- libass doesn't close them with a chord)
local SPK = "m 4 9 l 8 9 l 13 5 l 13 19 l 8 15 l 4 15"
local W1  = "m 16.5 8.5 b 18.2 10.2 18.2 13.8 16.5 15.5 b 18.2 13.8 18.2 10.2 16.5 8.5"
local W2  = "m 19 6 b 22 9 22 15 19 18 b 22 15 22 9 19 6"
local ICONS = {
    vol0     = { fill = SPK },
    vol1     = { fill = SPK, stroke = W1 },
    volume   = { fill = SPK, stroke = W1 .. " " .. W2 },
    mute     = { fill = SPK, stroke = "m 16 9 l 21 15 l 16 9 m 21 9 l 16 15 l 21 9" },
    sun      = { stroke = "m 16 12 b 16 14.21 14.21 16 12 16 b 9.79 16 8 14.21 8 12 b 8 9.79 9.79 8 12 8 b 14.21 8 16 9.79 16 12 "
        .. "m 12 2 l 12 4 l 12 2 m 12 20 l 12 22 l 12 20 m 2 12 l 4 12 l 2 12 m 20 12 l 22 12 l 20 12 "
        .. "m 4.9 4.9 l 6.3 6.3 l 4.9 4.9 m 17.7 17.7 l 19.1 19.1 l 17.7 17.7 "
        .. "m 4.9 19.1 l 6.3 17.7 l 4.9 19.1 m 17.7 6.3 l 19.1 4.9 l 17.7 6.3" },
    gauge    = { stroke = "m 4 17 b 4 7 20 7 20 17 b 20 7 4 7 4 17 m 12 17 l 16 12 l 12 17" },
    fwd      = { fill = "m 5 6 l 12 12 l 5 18 m 13 6 l 20 12 l 13 18" },
    back     = { fill = "m 19 6 l 12 12 l 19 18 m 11 6 l 4 12 l 11 18" },
    sub      = { stroke = "m 3 5 l 21 5 l 21 19 l 3 19 m 7 11 l 11 11 l 7 11 m 13 11 l 17 11 l 13 11 m 7 15 l 14 15 l 7 15" },
    contrast = { fill = "m 12 3 b 7.03 3 3 7.03 3 12 b 3 16.97 7.03 21 12 21",
                 stroke = "m 21 12 b 21 16.97 16.97 21 12 21 b 7.03 21 3 16.97 3 12 b 3 7.03 7.03 3 12 3 b 16.97 3 21 7.03 21 12" },
    drop     = { stroke = "m 12 3 b 12 3 5 11 5 15 b 5 19 8 21 12 21 b 16 21 19 19 19 15 b 19 11 12 3 12 3" },
    tune     = { stroke = "m 4 7 l 20 7 l 4 7 m 4 12 l 20 12 l 4 12 m 4 17 l 20 17 l 4 17" },
    none     = {},
}

------------------------------------------------------------------ state
local cur          -- parts of the visible pill
local t_show = 0
local quiet_until = 0
local seen = {}
local last_pos, seek_flag, seek_t = nil, false, 0

local overlay = mp.create_osd_overlay("ass-events")
overlay.z = 60
local timer

local function now() return mp.get_time() end

------------------------------------------------------------------ drawing
local function ev_fill(path, col, alpha)
    return string.format("{\\an7\\pos(0,0)\\bord0\\shad0\\blur0\\1c&H%s&\\1a&H%s&\\p1}%s{\\p0}", col, alpha, path)
end

local function ev_stroke(path, col, alpha, bw)
    return string.format("{\\an7\\pos(0,0)\\bord%.2f\\shad0\\blur0\\1a&HFF&\\3c&H%s&\\3a&H%s&\\p1}%s{\\p0}",
        bw, col, alpha, path)
end

local function measure(p, k, fs)
    if p.t == "icon" then return 18 * k end
    if p.t == "bar"  then return o.bar_width * k end
    if p.t == "btn"  then return 22 * k end
    local size = fs * (p.big and 1.15 or 1)
    if p.chars then return p.chars * 0.6 * size end
    return nchars(p.s) * 0.58 * size
end

local function render(f)
    if not cur then return end
    local w, h = mp.get_osd_size()
    if not w or w <= 0 or h <= 0 then return end
    local k   = h / 720 * o.scale
    local H   = 34 * k
    local pad = 14 * k
    local gap = 10 * k
    local fs  = o.font_size * k
    local bw  = 0.8 * k

    local total = pad * 2 + gap * (#cur - 1)
    for _, p in ipairs(cur) do
        p.w = measure(p, k, fs)
        total = total + p.w
    end

    local x0 = (w - total) / 2
    local y0 = (o.position == "bottom") and (h - o.margin * k - H) or (o.margin * k)
    local x1, y1 = x0 + total, y0 + H
    local cy = y0 + H / 2
    local ev = {}

    if o.shadow then
        ev[#ev + 1] = string.format("{\\an7\\pos(0,0)\\bord0\\shad0\\blur%.1f\\1c&H000000&\\1a&H%s&\\p1}%s{\\p0}",
            6 * k, A(0.30, f), rrect(x0, y0 + 4 * k, x1, y1 + 4 * k, H / 2))
    end
    local border = ""
    if o.border then
        border = string.format("\\bord%.1f\\3c&HFFFFFF&\\3a&H%s&", math.max(1, k * 0.8), A(0.14, f))
    else
        border = "\\bord0"
    end
    local pcol, pop, pblur = look()
    ev[#ev + 1] = string.format("{\\an7\\pos(0,0)%s\\shad0\\blur0\\1c&H%s&\\1a&H%s&\\p1}%s{\\p0}",
        border, pcol, A(pop, f), rrect(x0, y0, x1, y1, H / 2))
    -- real background blur for the glass modes (shares the panel_blur shader)
    local rect = pblur and { x0, y0, x1, y1, H / 2 } or nil
    local sig = rect and string.format("%d,%d,%d,%d", math.floor(x0 + 0.5), math.floor(y0 + 0.5), math.floor(x1 + 0.5), math.floor(y1 + 0.5)) or ""
    if sig ~= (IND.sig or "") then
        IND.sig, IND.rect = sig, rect
        local d = mp.get_property_native("osd-dimensions")
        if type(d) == "table" then IND.ml, IND.mt = d.ml, d.mt end
        if IND.refresh then IND.refresh() end
    end

    local white  = A(1, f)
    local dimmed = A(0.7, f)
    local fn = (o.font ~= "") and ("\\fn" .. o.font) or ""

    local x = x0 + pad
    for _, p in ipairs(cur) do
        if p.t == "icon" then
            local ic = ICONS[p.n] or ICONS.none
            local s  = 18 * k / 24
            local ox, oy = x, cy - 9 * k
            if ic.fill then
                ev[#ev + 1] = ev_fill(tx(ic.fill, ox, oy, s), "FFFFFF", white)
            end
            if ic.stroke then
                ev[#ev + 1] = ev_stroke(tx(ic.stroke, ox, oy, s), "FFFFFF", white, bw)
            end
        elseif p.t == "bar" then
            local th = 4 * k
            local by0, by1 = cy - th / 2, cy + th / 2
            ev[#ev + 1] = ev_fill(rrect(x, by0, x + p.w, by1, th / 2), "FFFFFF", A(0.28, f))
            local fw = p.w * math.max(0, math.min(1, p.frac or 0))
            if fw > 0 then
                ev[#ev + 1] = ev_fill(rrect(x, by0, x + math.max(fw, th), by1, th / 2), ACCENT, white)
            end
        elseif p.t == "btn" then
            local r = 11 * k
            ev[#ev + 1] = ev_fill(rrect(x, cy - r, x + 2 * r, cy + r, r), "FFFFFF", A(0.18, f))
            local mx = x + r
            local l = 4.5 * k
            local line = string.format("m %.1f %.1f l %.1f %.1f l %.1f %.1f", mx - l, cy, mx + l, cy, mx - l, cy)
            if p.sign == "+" then
                line = line .. string.format(" m %.1f %.1f l %.1f %.1f l %.1f %.1f", mx, cy - l, mx, cy + l, mx, cy - l)
            end
            ev[#ev + 1] = ev_stroke(line, "FFFFFF", white, bw)
        elseif p.t == "text" then
            local size = fs * (p.big and 1.15 or 1)
            local an, px = 4, x
            if p.right then an, px = 6, x + p.w end
            ev[#ev + 1] = string.format("{\\an%d\\pos(%.1f,%.1f)%s\\fs%d\\b1\\bord0\\shad0\\1c&HFFFFFF&\\1a&H%s&}%s",
                an, px, cy, fn, math.floor(size + 0.5), p.dim and dimmed or white, esc(p.s))
        end
        x = x + p.w + gap
    end

    overlay.res_x, overlay.res_y = w, h
    overlay.data = table.concat(ev, "\n")
    overlay:update()
end

local function clear()
    cur = nil
    overlay:remove()
    if IND.rect then
        IND.rect, IND.sig = nil, ""
        if IND.refresh then IND.refresh() end
    end
end

local function tick()
    if not cur then if timer then timer:kill() end return end
    local e = now() - t_show
    if e < o.duration then return end
    local fe = e - o.duration
    if o.fade <= 0 or fe >= o.fade then
        if timer then timer:kill() end
        clear()
    else
        render(1 - fe / o.fade)
    end
end

timer = mp.add_periodic_timer(0.03, tick)
timer:kill()

local function show(parts)
    if not o.enabled or not parts then return end
    cur = parts
    t_show = now()
    render(1)
    timer:resume()
end

------------------------------------------------------------------ specs
local function T(s, extra)
    local p = { t = "text", s = s }
    for k, v in pairs(extra or {}) do p[k] = v end
    return p
end

local function volume_spec()
    local vol   = mp.get_property_number("volume", 0)
    local vmax  = math.max(100, mp.get_property_number("volume-max", 100))
    local muted = mp.get_property_bool("mute", false)
    local ic = muted and "mute" or (vol <= 0 and "vol0" or (vol < 50 and "vol1" or "volume"))
    return {
        { t = "icon", n = ic },
        { t = "bar", frac = vol / vmax },
        T(string.format("%d", math.floor(vol + 0.5)), { right = true, chars = 3 }),
    }
end

local function mute_spec()
    local muted = mp.get_property_bool("mute", false)
    return { { t = "icon", n = muted and "mute" or "volume" }, T(muted and "Muted" or "Unmuted") }
end

local function speed_spec()
    local sp = mp.get_property_number("speed", 1)
    return { { t = "icon", n = "gauge" }, T(fmt_num(sp) .. "\195\151", { big = true }), T("Speed", { dim = true }) }
end

local function delay_spec(icon, val, label)
    local parts = {}
    if o.delay_buttons then parts[#parts + 1] = { t = "btn", sign = "-" } end
    parts[#parts + 1] = { t = "icon", n = icon }
    parts[#parts + 1] = T(string.format("%+.2f s", val))
    if label then parts[#parts + 1] = T(label, { dim = true }) end
    if o.delay_buttons then parts[#parts + 1] = { t = "btn", sign = "+" } end
    return parts
end

local PICTURE = {
    brightness = { "sun", nil },
    contrast   = { "contrast", "Contrast" },
    gamma      = { "tune", "Gamma" },
    saturation = { "drop", "Saturation" },
    hue        = { "tune", "Hue" },
}

local function picture_spec(name)
    local v = mp.get_property_number(name, 0)
    local def = PICTURE[name]
    local parts = { { t = "icon", n = def[1] } }
    if def[2] then parts[#parts + 1] = T(def[2], { dim = true }) end
    parts[#parts + 1] = { t = "bar", frac = (v + 100) / 200 }
    parts[#parts + 1] = T(string.format("%d", math.floor(v + 0.5)), { right = true, chars = 3 })
    return parts
end

local function seek_spec(delta, pos)
    local dur = mp.get_property_number("duration")
    local tm = fmt_time(pos)
    if dur and dur > 0 then tm = tm .. " / " .. fmt_time(dur) end
    return { { t = "icon", n = delta < 0 and "back" or "fwd" }, T(fmt_delta(delta)), T(tm, { dim = true }) }
end

------------------------------------------------------------------ wiring
local function quiet() return now() < quiet_until end

-- first callback of an observed property is just its current value
local function watch(name, enabled, fn)
    mp.observe_property(name, "native", function(_, v)
        if not seen[name] then seen[name] = true return end
        if v == nil or quiet() or not o[enabled] then return end
        show(fn(v))
    end)
end

watch("volume", "show_volume", volume_spec)
watch("mute",   "show_mute",   mute_spec)
watch("speed",  "show_speed",  speed_spec)
watch("sub-delay",   "show_sub_delay",   function(v) return delay_spec("sub", v) end)
watch("audio-delay", "show_audio_delay", function(v) return delay_spec("volume", v, "Audio") end)
for name in pairs(PICTURE) do
    watch(name, "show_picture", function() return picture_spec(name) end)
end

mp.observe_property("time-pos", "number", function(_, v)
    if v == nil then last_pos = nil return end
    if seek_flag then
        if now() - seek_t > 1.5 then
            seek_flag = false
        elseif last_pos and math.abs(v - last_pos) >= o.seek_min then
            seek_flag = false
            if o.show_seek and not quiet() then
                show(seek_spec(v - last_pos, v))
            end
        end
    end
    last_pos = v
end)

mp.register_event("seek", function()
    seek_flag, seek_t = true, now()
end)
mp.register_event("playback-restart", function() seek_flag = false end)

local function hush() quiet_until = now() + 1.0 end
mp.register_event("start-file", function() hush(); last_pos = nil; clear() end)
mp.register_event("file-loaded", hush)

mp.observe_property("osd-dimensions", "native", function()
    if cur then render(1) end
end)

mp.register_script_message("snad-indicator", function(icon, ...)
    local text = table.concat({...}, " ")
    local parts = {}
    if icon and icon ~= "none" and ICONS[icon] then parts[#parts + 1] = { t = "icon", n = icon } end
    if text ~= "" then parts[#parts + 1] = T(text) end
    if #parts > 0 then show(parts) end
end)

if o.hide_native_osd then
    mp.set_property("osd-level", "0")
end
hush()
end


-- layout=default: do nothing at all, so mpv's built-in OSC (script-opts/osc.conf) is used
if opts.layout == "default" then
    return
end

local LAYOUTS = { "streamer", "pill", "center" }
local function valid_layout(n)
    for _, v in ipairs(LAYOUTS) do if v == n then return n end end
    return "streamer"
end

-- background of the tracks menu, playlist/chapters drawer and volume popup
local function panel_bg()
    local st = tostring(opts.panel_style):lower():gsub("[%s_%-]", ""):match("^%a+") or "dark"
    local glass, dglass = st == "glass", st == "darkglass"
    local c = (opts.panel_color ~= "" and opts.panel_color) or (glass and "FFFFFF" or "0E141C")
    local o = opts.panel_opacity
    if o < 0 then
        if opts.panel_blur then
            o = glass and 0.25 or (dglass and 0.35 or 0.6)
        else
            o = glass and 0.2 or (dglass and 0.55 or 0.92)
        end
    end
    return c, o
end

-- colour/opacity for window controls, pills and tooltip: their own options, or the panel look
local function skin(c, o)
    if opts.panel_style_all then return panel_bg() end
    return c, o
end

local DOT = "  \226\128\162  "      -- "  •  "
local MID = " \194\183 "            -- " · "
local MINUS = "\226\136\146"        -- "−"
local ELLIPSIS = "\226\128\166"     -- "…"
local CRUMB = " \226\128\186 "      -- " › "

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------
local function bgr(hex)
    local r, g, b = tostring(hex):match("(%x%x)(%x%x)(%x%x)")
    if not r then return "FFFFFF" end
    return b .. g .. r
end

local function A(opacity)
    opacity = math.max(0, math.min(1, opacity))
    return string.format("%02X", math.floor((1 - opacity) * 255 + 0.5))
end

local function esc(s)
    s = s:gsub("\\", "\\\\")
    s = s:gsub("{", "\\{")
    s = s:gsub("}", "\\}")
    s = s:gsub("\n", " ")
    return s
end

local function ulen(s)
    local _, n = s:gsub("[^\128-\191]", "")
    return n
end

local function textw(s, fs, bold)
    return ulen(s) * fs * (bold and 0.58 or 0.54)
end

local function fit(s, fs, maxw, bold) -- truncate with ellipsis to an estimated width
    if textw(s, fs, bold) <= maxw then return s end
    local max = math.max(1, math.floor(maxw / (fs * (bold and 0.58 or 0.54))) - 1)
    local out, n = {}, 0
    for ch in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        n = n + 1
        if n > max then break end
        out[#out + 1] = ch
    end
    return table.concat(out) .. ELLIPSIS
end

-- split a long title at a space into two lines; the 2nd line is cut with ... if still too long
local function wrap2(s, fs, maxw, bold)
    if textw(s, fs, bold) <= maxw then return s end
    local best
    for pos in s:gmatch("()%s") do
        if textw(s:sub(1, pos - 1), fs, bold) <= maxw then best = pos else break end
    end
    if not best then return fit(s, fs, maxw, bold) end
    return s:sub(1, best - 1), fit(s:sub(best + 1), fs, maxw, bold)
end

local function fmt(t)
    t = math.max(0, math.floor((t or 0) + 0.5))
    local hh = math.floor(t / 3600)
    local mm = math.floor((t % 3600) / 60)
    local ss = t % 60
    if hh > 0 then return string.format("%d:%02d:%02d", hh, mm, ss) end
    return string.format("%d:%02d", mm, ss)
end

local function clock(t)
    if opts.use_12h then
        local s = os.date("%I:%M %p", t)
        s = s:gsub("^0", "")
        return s:lower()
    end
    return os.date("%H:%M", t)
end

local function f(n) return string.format("%.1f", n) end
local function clamp(v, a, b) return math.max(a, math.min(b, v)) end

-- "a, b | c" -> { "a", "b", "c" } (lower case, trimmed)
local function parse_list(str)
    local t = {}
    for raw in tostring(str or ""):gmatch("[^,;|]+") do
        local tok = raw:match("^%s*(.-)%s*$"):lower()
        if tok ~= "" then t[#t + 1] = tok end
    end
    return t
end

-- buttons hidden through hide_buttons
local HIDE = {}
do
    local alias = { mute = "volume", volbtn = "volume", vol = "volume", pause = "play", settings = "tracks",
                    subtitles = "tracks", ontop = "pin", minimize = "min", maximize = "max", exit = "close",
                    info = "info", ["chapter-prev"] = "chprev", ["chapter-next"] = "chnext" }
    for _, n in ipairs(parse_list(opts.hide_buttons)) do HIDE[alias[n] or n] = true end
    if HIDE.volume then HIDE.mute, HIDE.volbtn = true, true end
    if HIDE.window then HIDE.pin, HIDE.min, HIDE.max, HIDE.close = true, true, true, true end
    if HIDE.prev then HIDE.aprev = true end
    if HIDE.next then HIDE.anext = true end
    if HIDE.clock then opts.show_clock = false end
end

-- ASS drawing paths ---------------------------------------------------------
local function rrect(x0, y0, x1, y1, r)
    r = math.max(0, math.min(r, (x1 - x0) / 2, (y1 - y0) / 2))
    local c = r * 0.5523
    return table.concat({
        "m", f(x0 + r), f(y0),
        "l", f(x1 - r), f(y0),
        "b", f(x1 - r + c), f(y0), f(x1), f(y0 + r - c), f(x1), f(y0 + r),
        "l", f(x1), f(y1 - r),
        "b", f(x1), f(y1 - r + c), f(x1 - r + c), f(y1), f(x1 - r), f(y1),
        "l", f(x0 + r), f(y1),
        "b", f(x0 + r - c), f(y1), f(x0), f(y1 - r + c), f(x0), f(y1 - r),
        "l", f(x0), f(y0 + r),
        "b", f(x0), f(y0 + r - c), f(x0 + r - c), f(y0), f(x0 + r), f(y0),
    }, " ")
end

local function rrect_ccw(x0, y0, x1, y1, r)
    r = math.max(0, math.min(r, (x1 - x0) / 2, (y1 - y0) / 2))
    local c = r * 0.5523
    return table.concat({
        "m", f(x0 + r), f(y0),
        "b", f(x0 + r - c), f(y0), f(x0), f(y0 + r - c), f(x0), f(y0 + r),
        "l", f(x0), f(y1 - r),
        "b", f(x0), f(y1 - r + c), f(x0 + r - c), f(y1), f(x0 + r), f(y1),
        "l", f(x1 - r), f(y1),
        "b", f(x1 - r + c), f(y1), f(x1), f(y1 - r + c), f(x1), f(y1 - r),
        "l", f(x1), f(y0 + r),
        "b", f(x1), f(y0 + r - c), f(x1 - r + c), f(y0), f(x1 - r), f(y0),
        "l", f(x0 + r), f(y0),
    }, " ")
end

local function ring(x0, y0, x1, y1, r, t)
    return rrect(x0, y0, x1, y1, r) .. " " ..
           rrect_ccw(x0 + t, y0 + t, x1 - t, y1 - t, r - t)
end

local function rectp(x0, y0, x1, y1)
    return string.format("m %s %s l %s %s l %s %s l %s %s",
        f(x0), f(y0), f(x1), f(y0), f(x1), f(y1), f(x0), f(y1))
end

local function polyp(pts)
    local t = { "m", f(pts[1]), f(pts[2]) }
    for i = 3, #pts, 2 do
        t[#t + 1] = "l"; t[#t + 1] = f(pts[i]); t[#t + 1] = f(pts[i + 1])
    end
    return table.concat(t, " ")
end

-- ring sector; angles in degrees (screen coords, clockwise positive); sx = -1 mirrors horizontally
local function arcp(cx, cy, r, t, a0, a1, sx)
    sx = sx or 1
    local n = math.max(6, math.floor(math.abs(a1 - a0) / 10))
    local ro, ri = r + t / 2, r - t / 2
    local pts = {}
    for i = 0, n do
        local a = math.rad(a0 + (a1 - a0) * i / n)
        pts[#pts + 1] = cx + sx * ro * math.cos(a)
        pts[#pts + 1] = cy + ro * math.sin(a)
    end
    for i = n, 0, -1 do
        local a = math.rad(a0 + (a1 - a0) * i / n)
        pts[#pts + 1] = cx + sx * ri * math.cos(a)
        pts[#pts + 1] = cy + ri * math.sin(a)
    end
    return polyp(pts)
end

local function linep(x0, y0, x1, y1, t)
    local dx, dy = x1 - x0, y1 - y0
    local l = math.sqrt(dx * dx + dy * dy)
    if l == 0 then l = 1 end
    local nx, ny = -dy / l * t / 2, dx / l * t / 2
    return polyp({ x0 + nx, y0 + ny, x1 + nx, y1 + ny, x1 - nx, y1 - ny, x0 - nx, y0 - ny })
end

---------------------------------------------------------------------------
-- state
---------------------------------------------------------------------------
local ov = mp.create_osd_overlay("ass-events")
local S = {
    layout = valid_layout(opts.layout),
    visible = false, last_move = 0, last_render = 0,
    mx = -1, my = -1, hover = false,
    clock_pinned = false, title_pinned = false, pin_sec = -1,
    drag = nil, pending = nil, paused = false,
    menu = nil, drawer = nil, scroll = 0,
    remaining = false,
    segx = {}, vol = { x0 = 0, x1 = 1, y0 = 0, y1 = 1, vertical = false }, volpop = false,
    drawer_rect = nil,
    thumb_t = nil,
}
local regions, out = {}, {}
local grad_cache = {}
local info = { title = "", year = nil, meta = "", res = nil, hdr = {}, audio = nil, naud = 0, nsub = 0 }
local chapters = {}
S.clock_pinned = opts.clock_pinned
S.title_pinned = opts.title_pinned
local thumb = { width = 0, height = 0, disabled = true, available = false }

local panel_rects = {}
local function add_blur_rect(x0, y0, x1, y1, rad)
    if opts.panel_blur then panel_rects[#panel_rects + 1] = { x0, y0, x1, y1, rad } end
end

local function inside(x0, y0, x1, y1)
    return S.hover and S.mx >= x0 and S.mx <= x1 and S.my >= y0 and S.my <= y1
end

local function region(x0, y0, x1, y1, name, front)
    local r = { x0 = x0, y0 = y0, x1 = x1, y1 = y1, name = name }
    if front then table.insert(regions, 1, r) else regions[#regions + 1] = r end
end

local function hit(x, y)
    for _, r in ipairs(regions) do
        if x >= r.x0 and x <= r.x1 and y >= r.y0 and y <= r.y1 then return r.name end
    end
end

local function shape(path, rgb, op)
    out[#out + 1] = string.format(
        "{\\an7\\pos(0,0)\\p1\\bord0\\shad0\\1c&H%s&\\1a&H%s&}%s{\\p0}",
        bgr(rgb or "FFFFFF"), A(op or 1), path)
end

local function T(x, y, an, fs, str, rgb, op, bold, font, noshadow)
    out[#out + 1] = string.format(
        "{\\an%d\\pos(%s,%s)\\fn%s\\fs%s\\b%d\\bord0\\shad%s\\1c&H%s&\\1a&H%s&\\4c&H000000&\\4a&H70&}%s",
        an, f(x), f(y), font or opts.font, f(fs), bold and 1 or 0,
        noshadow and "0" or f(math.max(1, fs / 14)), bgr(rgb or "FFFFFF"), A(op or 1), esc(str))
end

local function get(p) return mp.get_property(p) end

-- loop state: "file", "playlist" or nil
local function loop_mode()
    local lf, lp = get("loop-file"), get("loop-playlist")
    if lf == "inf" or lf == "yes" then return "file" end
    if lp == "inf" or lp == "yes" or lp == "force" then return "playlist" end
    return nil
end

---------------------------------------------------------------------------
-- media info
---------------------------------------------------------------------------
local LANG = {
    eng = "English", jpn = "Japanese", spa = "Spanish", fre = "French", fra = "French",
    ger = "German", deu = "German", ita = "Italian", por = "Portuguese", rus = "Russian",
    kor = "Korean", chi = "Chinese", zho = "Chinese", hin = "Hindi", tam = "Tamil",
    sin = "Sinhala", ara = "Arabic", tur = "Turkish", dut = "Dutch", nld = "Dutch",
    swe = "Swedish", tha = "Thai", vie = "Vietnamese", pol = "Polish", ind = "Indonesian",
    may = "Malay", msa = "Malay", en = "English", ja = "Japanese", es = "Spanish",
    fr = "French", de = "German", it = "Italian", pt = "Portuguese", ru = "Russian",
    ko = "Korean", zh = "Chinese", hi = "Hindi", ta = "Tamil", si = "Sinhala",
}
local LAYOUT_NAME = { [1] = "1.0", [2] = "2.0", [3] = "2.1", [4] = "4.0", [5] = "5.0",
                      [6] = "5.1", [7] = "6.1", [8] = "7.1" }
local CODEC_NAME = { subrip = "SRT", ass = "ASS", ssa = "SSA", webvtt = "VTT",
                     hdmv_pgs_subtitle = "PGS", dvd_subtitle = "VobSub", mov_text = "TX3G",
                     eac3 = "E-AC-3", ac3 = "AC-3", truehd = "TrueHD", dts = "DTS", aac = "AAC",
                     flac = "FLAC", opus = "Opus", mp3 = "MP3", vorbis = "Vorbis" }
local VCODEC = { h264 = "H.264", avc = "H.264", hevc = "HEVC", h265 = "HEVC", av1 = "AV1", vp9 = "VP9",
                 vp8 = "VP8", mpeg4 = "MPEG-4", mpeg2video = "MPEG-2", vc1 = "VC-1", wmv3 = "WMV",
                 prores = "ProRes", theora = "Theora" }
local CUT_TOKENS = { "2160p", "1080p", "720p", "480p", "4k", "uhd", "bluray", "blu ray",
                     "brrip", "webrip", "web dl", "webdl", "hdr", "dv", "x264", "x265",
                     "h264", "h265", "hevc", "remux", "atmos" }

local function cleanup_name(fname)
    local t = fname:gsub("[%._]", " ")
    local cut, year = #t + 1, nil
    for pos, y in t:gmatch("()(%d%d%d%d)") do
        local n = tonumber(y)
        if n >= 1900 and n <= 2099 then year = y; cut = math.min(cut, pos); break end
    end
    local lower = t:lower()
    for _, tok in ipairs(CUT_TOKENS) do
        local p = lower:find("[%s%(%[%-]" .. tok:gsub("%-", "%%-"))
        if p then cut = math.min(cut, p) end
    end
    local title = t:sub(1, cut - 1):gsub("[%s%(%[%-]+$", "")
    if title == "" then title = fname end
    return title, year
end

local function track_name(t)
    local name = t.lang and (LANG[t.lang:lower()] or t.lang:upper()) or nil
    if not name then name = t.title or ("Track " .. tostring(t.id)) end
    return name
end

local function track_detail(t)
    local parts = {}
    if t.type == "audio" then
        local ch = t["demux-channel-count"]
        if ch then parts[#parts + 1] = LAYOUT_NAME[ch] or (ch .. "ch") end
        local codec = t.codec and (CODEC_NAME[t.codec] or t.codec:upper())
        local prof = (t["codec-profile"] or ""):lower()
        if prof:find("atmos") then codec = (codec or "") .. " Atmos" end
        if codec and codec ~= "" then parts[#parts + 1] = codec end
    else
        parts[#parts + 1] = t.external and "External" or "Embedded"
        if t.codec then parts[#parts + 1] = CODEC_NAME[t.codec] or t.codec:upper() end
    end
    if t.title and t.lang then parts[#parts + 1] = t.title end
    return table.concat(parts, MID)
end

-- audio-only detection: has an audio track and no real video (cover art / still images do not count)
local function is_audio()
    if opts.audio_layout == "off" then return false, false end
    local has_audio, real_video, cover = false, false, false
    for _, t in ipairs(mp.get_property_native("track-list") or {}) do
        if t.type == "audio" then has_audio = true
        elseif t.type == "video" then
            if t.albumart or t.image then cover = true else real_video = true end
        end
    end
    if S.aonly and has_audio then return true, cover, has_audio, real_video end
    local off = S.skin_off
    if off == nil then off = not opts.audio_default end
    if off and not real_video then return false, cover, has_audio, real_video end
    return has_audio and not real_video, cover, has_audio, real_video
end

-- the cover art is the file's video track: put it into the cover square through the video margins
local function audio_video_place(w, h, x, y, side, on)
    local key = on and string.format("%.0f,%.0f,%.0f,%.0f,%.0f", w, h, x, y, side) or "off"
    if S.vkey == key then return end
    S.vkey = key
    local l, r, t, b = 0, 0, 0, 0
    if on then l, r, t, b = x / w, 1 - (x + side) / w, y / h, 1 - (y + side) / h end
    mp.set_property_number("video-margin-ratio-left", l)
    mp.set_property_number("video-margin-ratio-right", r)
    mp.set_property_number("video-margin-ratio-top", t)
    mp.set_property_number("video-margin-ratio-bottom", b)
end

local audio_fit = function() end  -- defined with the window code below
local audio_palette = function() end  -- defined after mix_hex

local function audio_sync()
    local a, cover, has_a, real_v = is_audio()
    S.ha = has_a
    S.rv = has_a and real_v          -- a video file that has sound: the audio-only switch applies
    S.cover = a and cover
    if S.cover then audio_palette() else S.pal = nil end
    if a == S.audio then return end
    S.audio = a
    if a then
        if S.bg_orig == nil then S.bg_orig = get("background-color") or false end
        mp.set_property("background-color", "#" .. opts.audio_bg)
        if opts.audio_fit_window then
            if S.kaw_orig == nil then S.kaw_orig = get("keepaspect-window") or false end
            mp.set_property("keepaspect-window", "no")
            if not S.aonly then audio_fit() end
        end
    else
        if S.kaw_orig then mp.set_property("keepaspect-window", S.kaw_orig) end
        S.kaw_orig = nil
        S.vkey = nil
        audio_video_place(1, 1, 0, 0, 0, false)
        if S.bg_orig then mp.set_property("background-color", S.bg_orig) end
        S.bg_orig = nil
    end
end

local function refresh_chapters()
    chapters = mp.get_property_native("chapter-list") or {}
end

local function refresh_info()
    local fname = get("filename/no-ext") or ""
    local mt = get("media-title") or fname
    local year = (get("metadata/by-key/date") or get("metadata/by-key/year") or ""):match("(%d%d%d%d)")
    local title = mt
    if mt == fname then
        local t, y = cleanup_name(fname)
        title = t
        year = year or y
    end
    info.title, info.year = title, year

    local vw, vh = mp.get_property_number("video-params/w"), mp.get_property_number("video-params/h")
    info.res = nil
    if vw and vh then
        if vh >= 2000 or vw >= 3600 then info.res = "4K"
        elseif vh >= 1300 or vw >= 2400 then info.res = "1440p"
        elseif vh >= 1000 or vw >= 1800 then info.res = "1080p"
        elseif vh >= 700 or vw >= 1200 then info.res = "720p"
        else info.res = "SD" end
    end

    local hdr = {}
    local cm, gm = get("video-params/colormatrix"), get("video-params/gamma")
    local vprof = (get("current-tracks/video/codec-profile") or ""):lower()
    local lfn = (get("filename") or ""):lower()
    if cm == "dolbyvision" or vprof:find("dolby") or vprof:find("dovi") then
        hdr[#hdr + 1] = "Dolby Vision"
    elseif gm == "pq" then
        hdr[#hdr + 1] = lfn:find("hdr10%+") and "HDR10+" or "HDR10"
    elseif gm == "hlg" then
        hdr[#hdr + 1] = "HLG"
    end
    local aprof = ((get("current-tracks/audio/codec-profile") or "") .. " " ..
                   (get("current-tracks/audio/title") or "")):lower()
    if aprof:find("atmos") or lfn:find("atmos") then hdr[#hdr + 1] = "Atmos" end
    info.hdr = hdr
    local vc = get("current-tracks/video/codec")
    info.vcodec = vc and (VCODEC[vc:lower()] or vc:upper()) or nil
    local ac = get("current-tracks/audio/codec")
    info.acodec = ac and (CODEC_NAME[ac:lower()] or ac:upper()) or nil

    info.audio = nil
    local lang = get("current-tracks/audio/lang")
    local ch = mp.get_property_number("current-tracks/audio/demux-channel-count")
        or mp.get_property_number("audio-params/channel-count")
    if lang or ch then
        local name = lang and (LANG[lang:lower()] or lang:upper()) or "Audio"
        info.audio = name .. (ch and (" " .. (LAYOUT_NAME[ch] or (ch .. "ch"))) or "")
    end

    local na, ns = 0, 0
    for _, t in ipairs(mp.get_property_native("track-list") or {}) do
        if t.type == "audio" then na = na + 1 elseif t.type == "sub" then ns = ns + 1 end
    end
    info.naud, info.nsub = na, ns

    local parts = {}
    if year then parts[#parts + 1] = year end
    local genre = get("metadata/by-key/genre")
    if genre and genre ~= "" then
        parts[#parts + 1] = (genre:match("^[^,;/]+") or genre):gsub("^%s+", "")
    else
        local vf = get("video-format")
        if vf then parts[#parts + 1] = vf:upper() end
    end
    parts[#parts + 1] = "via " .. opts.via
    info.meta = table.concat(parts, DOT)
    audio_sync()
end

local function chapter_label()
    local idx = mp.get_property_number("chapter")
    if not idx or idx < 0 or #chapters == 0 then return nil end
    local c = chapters[idx + 1]
    local t = c and c.title or ""
    if t == "" then return "Chapter " .. (idx + 1) end
    if t:lower():find("^chapter") then return t end
    return "Chapter " .. (idx + 1) .. MID .. t
end

local function chapter_at(t)
    local name
    for i, c in ipairs(chapters) do
        if c.time <= t + 0.01 then name = (c.title and c.title ~= "") and c.title or ("Chapter " .. i) else break end
    end
    return name
end

local function breadcrumb()
    local p = get("path") or ""
    if p == "" then return get("media-title") or "" end
    if p:find("://") then return get("media-title") or p end
    local dir, file = utils.split_path(p)
    local parent = (dir or ""):gsub("[/\\]+$", ""):match("[^/\\]+$")
    if parent and parent ~= "" then return parent .. CRUMB .. (file or "") end
    return file or p
end

---------------------------------------------------------------------------
-- icons
---------------------------------------------------------------------------
local ICON = {}

function ICON.play(cx, cy, k, c)
    shape(polyp({ cx - 6 * k, cy - 11 * k, cx - 6 * k, cy + 11 * k, cx + 12 * k, cy }), c)
end
function ICON.pause(cx, cy, k, c)
    shape(rectp(cx - 8 * k, cy - 10 * k, cx - 2.5 * k, cy + 10 * k), c)
    shape(rectp(cx + 2.5 * k, cy - 10 * k, cx + 8 * k, cy + 10 * k), c)
end
-- playlist skip: a single triangle (chapter skip keeps the triangle-with-bar icons)
function ICON.plprev(cx, cy, k, c)
    shape(polyp({ cx + 7 * k, cy - 9 * k, cx + 7 * k, cy + 9 * k, cx - 8 * k, cy }), c)
end
function ICON.plnext(cx, cy, k, c)
    shape(polyp({ cx - 7 * k, cy - 9 * k, cx - 7 * k, cy + 9 * k, cx + 8 * k, cy }), c)
end
function ICON.prev(cx, cy, k, c)
    shape(rectp(cx - 9 * k, cy - 8 * k, cx - 6.5 * k, cy + 8 * k), c)
    shape(polyp({ cx + 9 * k, cy - 8.5 * k, cx + 9 * k, cy + 8.5 * k, cx - 5 * k, cy }), c)
end
function ICON.next(cx, cy, k, c)
    shape(rectp(cx + 6.5 * k, cy - 8 * k, cx + 9 * k, cy + 8 * k), c)
    shape(polyp({ cx - 9 * k, cy - 8.5 * k, cx - 9 * k, cy + 8.5 * k, cx + 5 * k, cy }), c)
end
local function skip_icon(cx, cy, k, c, sx)
    local r = 10 * k
    shape(arcp(cx, cy, r, 2 * k, -30, 270, sx), c)
    shape(polyp({ cx, cy - r - 4 * k, cx + sx * 5.5 * k, cy - r, cx, cy - r + 4 * k }), c)
    T(cx, cy + 1 * k, 5, 8 * k, tostring(opts.skip_seconds), c, 1, true)
end
function ICON.back(cx, cy, k, c) skip_icon(cx, cy, k, c, -1) end
function ICON.fwd(cx, cy, k, c) skip_icon(cx, cy, k, c, 1) end
function ICON.mute(cx, cy, k, c)
    local vol = mp.get_property_number("volume") or 100
    local muted = get("mute") == "yes"
    shape(polyp({ cx - 10 * k, cy - 3.5 * k, cx - 6 * k, cy - 3.5 * k, cx - 0.5 * k, cy - 8 * k,
                  cx - 0.5 * k, cy + 8 * k, cx - 6 * k, cy + 3.5 * k, cx - 10 * k, cy + 3.5 * k }), c)
    if muted or vol <= 0 then
        shape(linep(cx + 3 * k, cy - 4 * k, cx + 10 * k, cy + 4 * k, 2 * k), c)
        shape(linep(cx + 10 * k, cy - 4 * k, cx + 3 * k, cy + 4 * k, 2 * k), c)
    else
        shape(arcp(cx + 0.5 * k, cy, 5 * k, 1.8 * k, -45, 45), c)
        if vol > 40 then shape(arcp(cx + 0.5 * k, cy, 9.5 * k, 1.8 * k, -45, 45), c) end
    end
end
function ICON.cc(cx, cy, k, c)
    shape(ring(cx - 16 * k, cy - 11.5 * k, cx + 16 * k, cy + 11.5 * k, 5 * k, 2.1 * k), c)
    T(cx, cy + 0.5 * k, 5, 12.5 * k, "CC", c, 1, true)
end
function ICON.audio(cx, cy, k, c)
    shape(ring(cx - 11 * k, cy - 14 * k, cx + 11 * k, cy + 14 * k, 5 * k, 2.1 * k), c)
    shape(rectp(cx - 1 * k, cy - 8.5 * k, cx + 1 * k, cy + 8.5 * k), c)
    shape(rrect(cx - 5 * k, cy - 3 * k, cx + 5 * k, cy + 3 * k, 2 * k), c)
end
function ICON.speed(cx, cy, k, c)
    shape(arcp(cx, cy + 4 * k, 9.5 * k, 2 * k, 180, 360), c)
    shape(linep(cx, cy + 4 * k, cx + 5 * k, cy - 3 * k, 2 * k), c)
    shape(rrect(cx - 2 * k, cy + 2 * k, cx + 2 * k, cy + 6 * k, 2 * k), c)
end
-- sliders: subtitles, audio and speed all live in this one menu
function ICON.tracks(cx, cy, k, c)
    local rows = { { -6.5, -4 }, { 0, 4.5 }, { 6.5, -1 } }
    for _, r in ipairs(rows) do
        local y, kx = cy + r[1] * k, cx + r[2] * k
        shape(rectp(cx - 10 * k, y - 0.9 * k, cx + 10 * k, y + 0.9 * k), c)
        shape(rrect(kx - 3.2 * k, y - 3.2 * k, kx + 3.2 * k, y + 3.2 * k, 3.2 * k), c)
    end
end
function ICON.loop(cx, cy, k, c)
    T(cx, cy, 5, 28 * k, "\226\134\187", c, 1, true, opts.symbol_font)
end
function ICON.playlist(cx, cy, k, c)
    shape(rectp(cx - 11 * k, cy - 7 * k, cx + 2 * k, cy - 5 * k), c)
    shape(rectp(cx - 11 * k, cy - 1 * k, cx + 2 * k, cy + 1 * k), c)
    shape(rectp(cx - 11 * k, cy + 5 * k, cx - 3 * k, cy + 7 * k), c)
    shape(polyp({ cx + 4 * k, cy + 1 * k, cx + 4 * k, cy + 11 * k, cx + 12 * k, cy + 6 * k }), c)
end
function ICON.fullscreen(cx, cy, k, c)
    local s, len, t = 10 * k, 7 * k, 2.3 * k
    for _, sx in ipairs({ -1, 1 }) do
        for _, sy in ipairs({ -1, 1 }) do
            local x0 = sx < 0 and cx - s or cx + s
            local y0 = sy < 0 and cy - s or cy + s
            shape(rectp(math.min(x0, x0 - sx * len), math.min(y0, y0 - sy * t),
                        math.max(x0, x0 - sx * len), math.max(y0, y0 - sy * t)), c)
            shape(rectp(math.min(x0, x0 - sx * t), math.min(y0, y0 - sy * len),
                        math.max(x0, x0 - sx * t), math.max(y0, y0 - sy * len)), c)
        end
    end
end
function ICON.shuffle(cx, cy, k, c)
    shape(linep(cx - 10 * k, cy - 6 * k, cx - 3 * k, cy - 6 * k, 2 * k), c)
    shape(linep(cx - 3 * k, cy - 6 * k, cx + 3 * k, cy + 6 * k, 2 * k), c)
    shape(linep(cx + 3 * k, cy + 6 * k, cx + 8 * k, cy + 6 * k, 2 * k), c)
    shape(linep(cx - 10 * k, cy + 6 * k, cx - 3 * k, cy + 6 * k, 2 * k), c)
    shape(linep(cx - 3 * k, cy + 6 * k, cx + 3 * k, cy - 6 * k, 2 * k), c)
    shape(linep(cx + 3 * k, cy - 6 * k, cx + 8 * k, cy - 6 * k, 2 * k), c)
    shape(polyp({ cx + 7 * k, cy - 10 * k, cx + 12.5 * k, cy - 6 * k, cx + 7 * k, cy - 2 * k }), c)
    shape(polyp({ cx + 7 * k, cy + 2 * k, cx + 12.5 * k, cy + 6 * k, cx + 7 * k, cy + 10 * k }), c)
end
function ICON.audioonly(cx, cy, k, c)
    shape(rrect(cx - 8 * k, cy + 1.5 * k, cx + 1.5 * k, cy + 9 * k, 3.8 * k), c)
    shape(rectp(cx - 0.6 * k, cy - 9 * k, cx + 1.5 * k, cy + 5 * k), c)
    shape(polyp({ cx + 1.5 * k, cy - 9 * k, cx + 8.5 * k, cy - 5 * k, cx + 8.5 * k, cy - 1.5 * k, cx + 1.5 * k, cy - 5.5 * k }), c)
end
function ICON.info(cx, cy, k, c)
    shape(ring(cx - 10 * k, cy - 10 * k, cx + 10 * k, cy + 10 * k, 10 * k, 2 * k), c)
    shape(rrect(cx - 1.4 * k, cy - 6 * k, cx + 1.4 * k, cy - 3 * k, 1.4 * k), c)
    shape(rrect(cx - 1.4 * k, cy - 1.5 * k, cx + 1.4 * k, cy + 6 * k, 1.2 * k), c)
end
-- small vertical bar used as the "pinned" marker for the title and the clock
local function pin_bar(cx, cy, k, on)
    local w, h = 3 * k, 15 * k
    if on then
        shape(rrect(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2, w / 2), opts.accent, 1)
    else
        shape(rrect(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2, w / 2), "FFFFFF", 0.4)
    end
end

function ICON.pin(cx, cy, k, c)
    shape(polyp({ cx - 4 * k, cy - 10 * k, cx + 4 * k, cy - 10 * k, cx + 3 * k, cy - 2 * k,
                  cx + 6 * k, cy + 2 * k, cx - 6 * k, cy + 2 * k, cx - 3 * k, cy - 2 * k }), c)
    shape(linep(cx, cy + 2 * k, cx, cy + 10 * k, 2 * k), c)
end
function ICON.min(cx, cy, k, c) shape(rectp(cx - 7 * k, cy - 1 * k, cx + 7 * k, cy + 1 * k), c) end
function ICON.max(cx, cy, k, c) shape(ring(cx - 6.5 * k, cy - 6.5 * k, cx + 6.5 * k, cy + 6.5 * k, 2 * k, 1.8 * k), c) end
function ICON.close(cx, cy, k, c)
    shape(linep(cx - 6 * k, cy - 6 * k, cx + 6 * k, cy + 6 * k, 2 * k), c)
    shape(linep(cx + 6 * k, cy - 6 * k, cx - 6 * k, cy + 6 * k, 2 * k), c)
end
function ICON.check(cx, cy, k, c)
    shape(linep(cx - 6 * k, cy + 0.5 * k, cx - 2 * k, cy + 4.5 * k, 2.4 * k), c)
    shape(linep(cx - 2 * k, cy + 4.5 * k, cx + 6 * k, cy - 4 * k, 2.4 * k), c)
end
function ICON.plus(cx, cy, k, c)
    shape(rectp(cx - 6 * k, cy - 1 * k, cx + 6 * k, cy + 1 * k), c)
    shape(rectp(cx - 1 * k, cy - 6 * k, cx + 1 * k, cy + 6 * k), c)
end
function ICON.minus(cx, cy, k, c) shape(rectp(cx - 6 * k, cy - 1 * k, cx + 6 * k, cy + 1 * k), c) end
function ICON.chevron(cx, cy, k, c)
    shape(polyp({ cx - 4 * k, cy - 9 * k, cx - 1.5 * k, cy - 11.5 * k, cx + 7 * k, cy,
                  cx - 1.5 * k, cy + 11.5 * k, cx - 4 * k, cy + 9 * k, cx + 3 * k, cy }), c)
end

-- generic icon button: hover disc, optional ring, icon, optional count badge, hit region
-- toggled-on look for round buttons: accent border and/or a dark / glass / dark-glass fill
local function active_look()
    local st = tostring(opts.active_style):lower():match("^%s*(%a+)") or "border"
    return st == "border" or st == "both", st == "fill" or st == "both"
end

local function active_bg(cx, cy, r, k)
    local border, fill = active_look()
    if fill then
        local f = tostring(opts.active_fill):lower():gsub("[%s_%-]", ""):match("^%a+") or "darkglass"
        local c = opts.active_fill_color ~= "" and opts.active_fill_color or (f == "glass" and "FFFFFF" or "0E141C")
        local o = opts.active_fill_opacity
        if o < 0 then o = f == "glass" and 0.28 or (f == "dark" and 0.85 or 0.5) end
        shape(rrect(cx - r, cy - r, cx + r, cy + r, r), c, o)
    end
    if border then shape(ring(cx - r, cy - r, cx + r, cy + r, r, 1.5 * k), opts.accent, 1) end
end

local function btn(name, cx, cy, k, o)
    if HIDE[name] then return end
    o = o or {}
    local icon = o.icon or name
    local r = 22 * k
    if o.disabled then
        ICON[icon](cx, cy, k, opts.disabled_color)
        region(cx - r, cy - r, cx + r, cy + r, "panel")
        return
    end
    if inside(cx - r, cy - r, cx + r, cy + r) then
        shape(rrect(cx - r, cy - r, cx + r, cy + r, r), "FFFFFF", 0.16)
    end
    if o.ring or o.active then active_bg(cx, cy, r, k) end
    ICON[icon](cx, cy, k, o.color or "FFFFFF")
    if o.badge and o.badge > 0 then
        local bw = math.max(15 * k, textw(tostring(o.badge), 10 * k, true) + 6 * k)
        local bx, by = cx + r - 4 * k, cy - r + 10 * k
        shape(rrect(bx - bw, by - 7.5 * k, bx, by + 7.5 * k, 7.5 * k), opts.accent, 1)
        T(bx - bw / 2, by + 0.5 * k, 5, 10 * k, tostring(o.badge), "04121F", 1, true)
    end
    if o.tag then
        local bx, by, br = cx + r - 7 * k, cy - r + 11 * k, 7.5 * k
        shape(rrect(bx - br, by - br, bx + br, by + br, br), opts.accent, 1)
        T(bx, by + 0.5 * k, 5, 10 * k, o.tag, "FFFFFF", 1, true, nil, true)
    end
    region(cx - r, cy - r, cx + r, cy + r, name)
end

local function chip(x, y, k, str, o)
    o = o or {}
    local fs = opts.pill_font_size * k
    local h = opts.pill_height * k
    local w = textw(str, fs, opts.pill_bold) + 2 * opts.pill_padding * k
    local pc, po = skin(opts.pill_color, opts.pill_opacity)
    if po > 0 then
        shape(rrect(x, y - h / 2, x + w, y + h / 2, h / 2), pc, po)
        if opts.panel_style_all then add_blur_rect(x, y - h / 2, x + w, y + h / 2, h / 2) end
    end
    if opts.pill_border_width > 0 then
        shape(ring(x, y - h / 2, x + w, y + h / 2, h / 2, opts.pill_border_width * k),
              opts.pill_border_color, opts.pill_border_opacity)
    end
    T(x + w / 2, y, 5, fs, str, opts.pill_text_color, opts.pill_text_opacity, opts.pill_bold, nil, true)
    return w
end

-- label of the subtitle track that is currently selected (nil when subtitles are off)
local function selected_sub_label()
    local sid = get("sid")
    if not sid or sid == "no" or sid == "false" then return nil end
    for _, t in ipairs(mp.get_property_native("track-list") or {}) do
        if t.type == "sub" and t.selected then return "CC" .. MID .. track_name(t) end
    end
    return "CC"
end

local function fps_label()
    if get("current-tracks/video/albumart") == "yes" then return nil end
    local f = mp.get_property_number("container-fps") or mp.get_property_number("estimated-vf-fps")
    if not f or f < 5 then return nil end
    if opts.pill_fps_round or math.abs(f - math.floor(f + 0.5)) < 0.02 then return string.format("%d fps", math.floor(f + 0.5)) end
    return string.format("%.2f fps", f)
end

local function badges(x, y, k, o)
    o = o or {}
    local gap = opts.pill_gap * k
    local bx = x
    if opts.pill_show_resolution and info.res then bx = bx + chip(bx, y, k, info.res, o) + gap end
    if opts.pill_show_fps and info.res then
        local fl = fps_label()
        if fl then bx = bx + chip(bx, y, k, fl, o) + gap end
    end
    if opts.pill_show_hdr and #info.hdr > 0 then bx = bx + chip(bx, y, k, table.concat(info.hdr, DOT), o) + gap end
    if opts.pill_show_vcodec and info.vcodec then bx = bx + chip(bx, y, k, info.vcodec, o) + gap end
    if opts.pill_show_audio and info.audio then bx = bx + chip(bx, y, k, info.audio, o) + gap end
    if opts.pill_show_acodec and info.acodec then bx = bx + chip(bx, y, k, info.acodec, o) + gap end

    -- currently selected playback options
    local sub = opts.pill_show_subtitle and selected_sub_label()
    local spd = mp.get_property_number("speed") or 1
    local lmode = loop_mode()
    if sub then bx = bx + chip(bx, y, k, sub, o) + gap end
    if opts.pill_show_speed and math.abs(spd - 1) > 0.001 then
        bx = bx + chip(bx, y, k, string.format("%g", spd) .. "\195\151", o) + gap
    end
    if opts.pill_show_loop and lmode then bx = bx + chip(bx, y, k, lmode == "file" and "Loop 1" or "Loop all", o) + gap end
    return bx
end

---------------------------------------------------------------------------
-- shared bars: gradient, top bar, seek bar, volume, clusters
---------------------------------------------------------------------------
local function gradient(w, h, style)
    local key = w .. "x" .. h .. style
    if grad_cache[key] then return grad_cache[key] end
    local g = {}
    -- strips sit edge to edge on whole pixels: no overlap (double-alpha lines) and no
    -- anti-aliased seams between them
    local function strip(y0, y1, op)
        if y1 <= y0 then return end
        g[#g + 1] = string.format(
            "{\\an7\\pos(0,0)\\p1\\bord0\\shad0\\1c&H000000&\\1a&H%s&}m 0 %d l %d %d l %d %d l 0 %d{\\p0}",
            A(op), y0, w, y0, w, y1, y1)
    end
    local function band(ya, yb, n, alpha_at)
        ya, yb = math.floor(ya + 0.5), math.floor(yb + 0.5)
        local prev = ya
        for i = 1, n do
            local nxt = ya + math.floor((yb - ya) * i / n + 0.5)
            strip(prev, nxt, alpha_at((i - 0.5) / n))
            prev = nxt
        end
    end
    local top, peak = h * 0.38, 0.82
    if style == "pill" then top, peak = h * 0.62, 0.55 end
    local n = clamp(math.floor((h - top) / 7), 24, 80)
    band(top, h, n, function(t) return peak * t ^ 1.7 end)
    local th = h * 0.2
    band(0, th, clamp(math.floor(th / 7), 12, 40), function(t) return 0.55 * (1 - t) ^ 1.5 end)
    grad_cache[key] = table.concat(g, "\n")
    return grad_cache[key]
end

local function winctl(xr, cy, k)
    if not opts.show_window_controls then return xr end
    local items = {}
    for _, n in ipairs({ "audioonly", "pin", "min", "max", "close" }) do
        if not HIDE[n] and (n ~= "audioonly" or (opts.show_audio_button and (S.ha or S.aonly))) then items[#items + 1] = n end
    end
    if #items == 0 then return xr end
    local bw, pad = 40 * k, 3 * k
    local W = #items * bw + 2 * pad
    local x0 = xr - W
    local wc, wo = skin(opts.winctl_color, opts.winctl_opacity)
    if wo > 0 then
        shape(rrect(x0, cy - bw / 2 - pad, xr, cy + bw / 2 + pad, (bw + 2 * pad) / 2), wc, wo)
        if opts.panel_style_all then add_blur_rect(x0, cy - bw / 2 - pad, xr, cy + bw / 2 + pad, (bw + 2 * pad) / 2) end
    end
    for i, name in ipairs(items) do
        local color = "FFFFFF"
        if name == "pin" and get("ontop") == "yes" then color = opts.accent end
        if name == "audioonly" and ((S.rv and S.aonly) or (not S.rv and S.audio)) then color = opts.accent end
        btn(name, x0 + pad + bw * (i - 0.5), cy, k * 0.9, { color = color })
    end
    return x0
end

local function clock_strings()
    local now = os.time()
    local es
    local dur = mp.get_property_number("duration")
    if dur and dur > 0 then
        local pos = mp.get_property_number("time-pos") or 0
        local spd = mp.get_property_number("speed") or 1
        es = "Ends at " .. clock(now + (mp.get_property_number("playtime-remaining") or ((dur - pos) / spd)))
    end
    return clock(now), es
end

-- small pin marker + click target that toggles the pinned clock; xr = right edge of the clock text
local function clock_pin_button(xr, cy, k, cs, es)
    local tw = math.max(textw(cs, 22 * k, true), es and textw(es, 14 * k) or 0)
    pin_bar(xr + 13 * k, cy, k, S.clock_pinned)
    region(xr - tw - 6 * k, cy - 26 * k, xr + 22 * k, cy + 28 * k, "clockpin")
end

local function clock_block(xr, cy, k)
    if not opts.show_clock then return end
    local now = os.time()
    T(xr, cy - 9 * k, 6, 22 * k, clock(now), "FFFFFF", 1, true)
    clock_pin_button(xr, cy, k, clock(now), select(2, clock_strings()))
    local dur = mp.get_property_number("duration")
    if dur and dur > 0 then
        local pos = mp.get_property_number("time-pos") or 0
        local spd = mp.get_property_number("speed") or 1
        local remain = mp.get_property_number("playtime-remaining") or ((dur - pos) / spd)
        T(xr, cy + 15 * k, 6, 14 * k, "Ends at " .. clock(now + remain), "FFFFFF", 0.88)
    end
end

local function playlist_pos()
    if not opts.show_playlist_pos then return nil end
    local n = mp.get_property_number("playlist-count") or 0
    local i = mp.get_property_number("playlist-pos-1")
    if n < 2 or not i or i < 1 then return nil end
    local wd = math.max(2, #tostring(n))
    return string.format("[%0" .. wd .. "d/%0" .. wd .. "d]", i, n)
end

local function crumb_text()
    local pp = playlist_pos()
    return (pp and (pp .. "  ") or "") .. breadcrumb()
end

local function top_bar(ctx)
    local k, w = ctx.k, ctx.w
    local mx = w * 0.04
    local cy = 40 * k
    local xl = winctl(w - mx, cy, k)
    clock_block(xl - 24 * k, cy, k)
    local ct = fit(crumb_text(), 15 * k, w * 0.45)
    pin_bar(mx - 11 * k, cy, k, S.title_pinned)
    T(mx, cy, 4, 15 * k, ct, "FFFFFF", 0.88)
    region(mx - 20 * k, cy - 16 * k, mx + textw(ct, 15 * k) + 8 * k, cy + 16 * k, "titlepin")
end

-- seek bar split into chapter segments, with buffer, knob, hover tooltip (+ thumbfast)
local function build_segments(dur)
    local segs = {}
    if #chapters >= 2 and #chapters <= 60 and dur and dur > 0 then
        local starts = {}
        for i, c in ipairs(chapters) do starts[i] = clamp(c.time, 0, dur) end
        if starts[1] > 1 then table.insert(starts, 1, 0) end
        for i = 1, #starts do
            local t1 = starts[i + 1] or dur
            if t1 > starts[i] then segs[#segs + 1] = { starts[i], t1 } end
        end
    end
    if #segs == 0 then segs[1] = { 0, (dur and dur > 0) and dur or 1 } end
    return segs
end

local function t2x(segx, t)
    for _, sg in ipairs(segx) do
        if t <= sg[4] then
            return sg[1] + clamp((t - sg[3]) / (sg[4] - sg[3]), 0, 1) * (sg[2] - sg[1])
        end
    end
    return segx[#segx][2]
end

local function x2t(segx, x, dur)
    for i, sg in ipairs(segx) do
        local lim = (segx[i + 1] and (sg[2] + segx[i + 1][1]) / 2) or math.huge
        if x <= lim then
            return sg[3] + clamp((x - sg[1]) / (sg[2] - sg[1]), 0, 1) * (sg[4] - sg[3])
        end
    end
    return dur or 0
end

local function thumb_clear()
    if S.thumb_t then
        mp.commandv("script-message-to", "thumbfast", "clear")
        S.thumb_t = nil
    end
end

-- ---- Android-style wavy seek bar --------------------------------------------------------
local function hex_rgb(h)
    h = tostring(h):gsub("[^%x]", "")
    if #h < 6 then return 255, 255, 255 end
    return tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)
end

local function mix_hex(a, b, f)
    local ar, ag, ab = hex_rgb(a)
    local br, bg, bb = hex_rgb(b)
    return string.format("%02X%02X%02X", math.floor(ar + (br - ar) * f + 0.5),
        math.floor(ag + (bg - ag) * f + 0.5), math.floor(ab + (bb - ab) * f + 0.5))
end

-- glow colours from the cover art: sample the picture, take the two most vivid hue groups
audio_palette = function()
    if tostring(opts.audio_glow_color):lower() ~= "cover" then S.pal = nil; return end
    local path = get("path") or ""
    if S.pal_for == path then return end
    S.pal_for, S.pal = path, nil
    local tries = 0
    local function try()
        if S.pal_for ~= path or not S.cover then return end
        local ok, shot = pcall(mp.command_native, { "screenshot-raw", "video", "bgr0" })
        if not ok or type(shot) ~= "table" or type(shot.data) ~= "string" or (shot.w or 0) < 2 then
            tries = tries + 1
            if tries < 6 then mp.add_timeout(0.5, try) end
            return
        end
        local W, Hh, stride, data = shot.w, shot.h, shot.stride or shot.w * 4, shot.data
        local N = 24
        local bins = {}
        for i = 1, 12 do bins[i] = { w = 0, r = 0, g = 0, b = 0 } end
        local tot = 0
        for gy = 0, N - 1 do
            for gx = 0, N - 1 do
                local x = math.floor((gx + 0.5) * W / N)
                local y = math.floor((gy + 0.5) * Hh / N)
                local off = y * stride + x * 4 + 1
                local bb, gg, rr = data:byte(off, off + 2)
                if rr then
                    local r, g, b = rr / 255, gg / 255, bb / 255
                    local mx, mn = math.max(r, g, b), math.min(r, g, b)
                    local d = mx - mn
                    local sat = mx > 0 and d / mx or 0
                    if d > 0 and mx > 0.15 then
                        local hue
                        if mx == r then hue = ((g - b) / d) % 6 elseif mx == g then hue = (b - r) / d + 2 else hue = (r - g) / d + 4 end
                        local bi = math.min(12, math.floor(hue * 2) + 1)
                        local wt = sat * sat * mx
                        local B = bins[bi]
                        B.w, B.r, B.g, B.b = B.w + wt, B.r + wt * rr, B.g + wt * gg, B.b + wt * bb
                        tot = tot + wt
                    end
                end
            end
        end
        local b1, i1 = nil, 0
        for i = 1, 12 do if not b1 or bins[i].w > b1.w then b1, i1 = bins[i], i end end
        if not b1 or b1.w < N * N * 0.01 then return end   -- grey / black&white art: keep the default glow
        local function col(B) return string.format("%02X%02X%02X", math.floor(B.r / B.w + 0.5), math.floor(B.g / B.w + 0.5), math.floor(B.b / B.w + 0.5)) end
        local b2
        for i = 1, 12 do
            local dist = math.min((i - i1) % 12, (i1 - i) % 12)
            if dist >= 2 and bins[i].w >= b1.w * 0.25 and (not b2 or bins[i].w > b2.w) then b2 = bins[i] end
        end
        local c1 = col(b1)
        S.pal = { c1, b2 and col(b2) or mix_hex(c1, "1D3A63", 0.65) }
    end
    mp.add_timeout(0.3, try)
end

-- the wave's colour list: shades of the accent, or the user's wave_colors
local function wave_palette()
    if opts.wave_follow_accent then
        return { mix_hex(opts.accent, "FFFFFF", 0.45), opts.accent, mix_hex(opts.accent, "000000", 0.3) }
    end
    local l = {}
    for tok in tostring(opts.wave_colors):gmatch("[^,%s]+") do l[#l + 1] = tok end
    if #l == 0 then l[1] = opts.accent end
    return l
end

local wave_cache = { src = nil, list = {} }
local function wave_color(u)
    local key = opts.wave_follow_accent and ("accent:" .. tostring(opts.accent)) or tostring(opts.wave_colors)
    if wave_cache.src ~= key then
        wave_cache.src = key
        wave_cache.list = {}
        for _, tok in ipairs(wave_palette()) do
            wave_cache.list[#wave_cache.list + 1] = { hex_rgb(tok) }
        end
    end
    local l = wave_cache.list
    if #l == 1 then return string.format("%02X%02X%02X", l[1][1], l[1][2], l[1][3]) end
    u = clamp(u, 0, 1) * (#l - 1)
    local i = math.min(#l - 2, math.floor(u))
    local f = u - i
    local a, b = l[i + 1], l[i + 2]
    return string.format("%02X%02X%02X",
        math.floor(a[1] + (b[1] - a[1]) * f + 0.5), math.floor(a[2] + (b[2] - a[2]) * f + 0.5),
        math.floor(a[3] + (b[3] - a[3]) * f + 0.5))
end

-- draws the played part as a travelling sine wave with a colour gradient; returns knob colour
local function draw_wave(x0, x1, hx, y, k)
    local target = (S.paused and opts.wave_flat_when_paused) and 0 or 1
    S.wave_amp = (S.wave_amp or target) + (target - (S.wave_amp or target)) * 0.18
    if math.abs(S.wave_amp - target) < 0.01 then S.wave_amp = target end
    local amp = opts.wave_amplitude * k * S.wave_amp
    local lam = math.max(8, opts.wave_length) * k
    local played = hx - x0
    local th = opts.wave_thickness * k
    if tostring(opts.wave_style):lower():match("^%s*(%a+)") ~= "line" then
        -- layered translucent humps (like a music visualiser), drawn as filled polygons over a straight line
        local cols = wave_palette()
        local t = mp.get_time() * opts.wave_speed
        local step = math.max(2, 4 * k)
        local n = math.max(2, math.ceil(played / step))
        local layers = {
            { 1.00, 1.00, 2.6, 0.50 }, { 0.80, 1.35, -2.0, 0.62 }, { 0.62, 0.78, 3.3, 0.40 },
        }
        local grow = math.min(1, played / (90 * k))
        for li, L in ipairs(layers) do
            local col = cols[math.min(#cols, math.floor((li - 1) * (#cols - 1) / 2 + 1.5))]
            local pts = {}
            for i = 0, n do
                local x = math.min(hx, x0 + i * step)
                local u = clamp((x - x0) / math.max(1, played), 0, 1)
                local center = L[4]
                local env = math.exp(-((u - center) / 0.26) ^ 2) * math.sin(math.pi * u) ^ 0.5
                local h = ((1 + math.sin((x - x0) / (lam * L[2]) * 2 * math.pi - t * L[3])) / 2) ^ 1.4
                pts[#pts + 1] = x
                pts[#pts + 1] = y - amp * L[1] * grow * env * h
            end
            for i = n, 0, -1 do
                pts[#pts + 1] = math.min(hx, x0 + i * step)
                pts[#pts + 1] = y
            end
            shape(polyp(pts), col, opts.wave_opacity)
        end
        local bl = tostring(opts.wave_baseline)
        if bl:lower():match("^%s*accent") then bl = opts.accent
        elseif bl == "" then bl = nil end
        shape(rrect(x0, y - th / 2, hx, y + th / 2, th / 2), bl or wave_color(0.5), 1)
        return opts.wave_follow_accent and opts.accent or wave_color(1), y
    end
    local phase = mp.get_time() * opts.wave_speed * 2.6
    local step = math.max(2, 4 * k)
    local n = math.max(1, math.ceil(played / step))
    local grow = math.min(1, played / (90 * k))       -- little played yet: keep it calm
    local function yy(x)
        local u = (x - x0) / math.max(1, played)
        local env = math.sin(math.pi * clamp(u, 0, 1)) ^ 1.6        -- bump: flat at both ends, strongest mid-way
        return y - amp * grow * env * math.sin((x - x0) / lam * 2 * math.pi - phase)
    end
    local px, py = x0, yy(x0)
    for i = 1, n do
        local x = math.min(hx, x0 + i * step)
        local ny = yy(x)
        shape(linep(px, py, x, ny, th), wave_color(((px + x) / 2 - x0) / math.max(1, x1 - x0) ), 1)
        px, py = x, ny
    end
    -- round caps
    shape(rrect(x0 - th / 2, yy(x0) - th / 2, x0 + th / 2, yy(x0) + th / 2, th / 2), wave_color(0), 1)
    return wave_color((hx - x0) / math.max(1, x1 - x0)), y
end

local function draw_seek(x0, x1, y, k, thick, ctx)
    local dur, pos = ctx.dur or 0, ctx.pos
    local segs = build_segments(ctx.dur)
    local gap, n = 3 * k, #segs
    local total = (x1 - x0) - gap * (n - 1)
    local D = dur > 0 and dur or 1
    local segx, cx = {}, x0
    for i, s in ipairs(segs) do
        local w = math.max(2 * k, total * (s[2] - s[1]) / D)
        segx[i] = { cx, cx + w, s[1], s[2] }
        cx = cx + w + gap
    end
    S.segx = segx

    local hov = inside(x0 - 8, y - 16 * k, x1 + 8, y + 16 * k) or S.drag == "seek"
    local th = (hov and thick * 1.5 or thick)
    local cache = mp.get_property_number("demuxer-cache-time")
    local wave_hx = opts.seek_wave and t2x(segx, pos) or nil
    for _, sg in ipairs(segx) do
        local sw = sg[2] - sg[1]
        if wave_hx then
            -- wave mode: thin straight track only to the right of the knob
            if sg[2] > wave_hx then
                shape(rrect(math.max(sg[1], wave_hx), y - th * 0.3, sg[2], y + th * 0.3, th * 0.3), "FFFFFF", 0.35)
            end
        else
            shape(rrect(sg[1], y - th / 2, sg[2], y + th / 2, th / 2), "FFFFFF", 0.28)
        end
        if cache and cache > sg[3] and not wave_hx then
            local fr = math.min(1, (cache - sg[3]) / (sg[4] - sg[3]))
            shape(rrect(sg[1], y - th / 2, sg[1] + math.max(th, sw * fr), y + th / 2, th / 2), "FFFFFF", 0.5)
        end
        if pos > sg[3] and not opts.seek_wave then
            local fr = math.min(1, (pos - sg[3]) / (sg[4] - sg[3]))
            shape(rrect(sg[1], y - th / 2, sg[1] + math.max(th, sw * fr), y + th / 2, th / 2), opts.accent, 1)
        end
    end
    local hx = t2x(segx, pos)
    local kr = (hov and 7.5 or 4.5) * k
    if opts.seek_wave then
        local kc = draw_wave(x0, x1, hx, y, k)
        local ro = kr * 1.9
        shape(rrect(hx - ro, y - ro, hx + ro, y + ro, ro), kc, 0.28)          -- glow
        shape(rrect(hx - kr * 1.25, y - kr * 1.25, hx + kr * 1.25, y + kr * 1.25, kr * 1.25), "FFFFFF", 1)
        shape(rrect(hx - kr * 0.85, y - kr * 0.85, hx + kr * 0.85, y + kr * 0.85, kr * 0.85), kc, 1)
    else
        shape(rrect(hx - kr, y - kr, hx + kr, y + kr, kr), "FFFFFF", 1)
    end
    region(x0 - 8, y - 16 * k, x1 + 8, y + 16 * k, "seek")

    if hov and dur > 0 and S.hover then
        local t = x2t(segx, clamp(S.mx, x0, x1), dur)
        local label = fmt(t)
        local chap = chapter_at(t)
        local fs = opts.tip_font_size * k
        local cw = textw(label, fs, true)
        if chap then cw = math.max(cw, textw(chap, 13 * k, false)) end
        local use_thumb = opts.thumbfast and thumb.available and not thumb.disabled and thumb.width > 0
        cw = cw + 16 * k
        if use_thumb then cw = math.max(cw, thumb.width + 16 * k) end
        local ch = (opts.tip_height + (chap and 14 or 0)) * k
        local tx = clamp(S.mx, x0 + cw / 2, x1 - cw / 2)
        local below = not use_thumb and tostring(opts.tip_position):lower():match("^%s*(%a+)") == "below"
        local top = below and (y + opts.tip_gap * k + th / 2) or (y - 24 * k - ch)
        local th_h = use_thumb and (thumb.height + 10 * k) or 0
        shape(rrect(tx - cw / 2, top - th_h, tx + cw / 2, top + ch, math.min(10 * k, ch / 2)), skin(opts.tip_color, opts.tip_opacity))
        local ty = top + (opts.tip_height / 2) * k
        T(tx, ty, 5, fs, label, opts.tip_text_color, 1, true, nil, not opts.tip_shadow)
        if chap then T(tx, top + (opts.tip_height + 6) * k, 5, 12 * k, fit(chap, 12 * k, cw - 12 * k), opts.tip_text_color, 0.85, false, nil, not opts.tip_shadow) end
        if use_thumb then
            local px = tx - thumb.width / 2
            local py = top - th_h + 8 * k
            if S.thumb_t == nil or math.abs(S.thumb_t - t) > 0.4 then
                mp.commandv("script-message-to", "thumbfast", "thumb",
                    string.format("%.2f", t), string.format("%d", px), string.format("%d", py))
                S.thumb_t = t
            end
        end
    elseif S.thumb_t then
        thumb_clear()
    end
end

local function volume_ctl(cx, cy, k, sw, show_pct)
    if HIDE.volume then return end
    local vol = mp.get_property_number("volume") or 100
    local vmax = mp.get_property_number("volume-max") or 100
    local fr = clamp(vol / vmax, 0, 1)

    if opts.volume_style ~= "horizontal" and not S.force_h then
        -- one speaker button; clicking it opens a vertical slider above it
        btn("volbtn", cx, cy, k, { icon = "mute", active = S.volpop })
        S.vol.vertical = true
        if not S.volpop then return end
        local W, H = 46 * k, 156 * k
        local x0, x1 = cx - W / 2, cx + W / 2
        local y1 = cy - 30 * k
        local y0 = y1 - H
        shape(rrect(x0, y0, x1, y1, 18 * k), panel_bg())
        add_blur_rect(x0, y0, x1, y1, 18 * k)
        region(x0, y0, x1, y1, "panel", true)
        local muted = get("mute") == "yes"
        T(cx, y0 + 17 * k, 5, 13 * k, muted and "Muted" or string.format("%d%%", math.floor(vol + 0.5)),
          "FFFFFF", 0.9, true, nil, not opts.panel_text_shadow)
        local ty0, ty1 = y0 + 36 * k, y1 - 50 * k
        shape(rrect(cx - 2 * k, ty0, cx + 2 * k, ty1, 2 * k), "FFFFFF", 0.3)
        local fh = (ty1 - ty0) * (muted and 0 or fr)
        if fh > 0.5 then shape(rrect(cx - 2 * k, ty1 - math.max(fh, 4 * k), cx + 2 * k, ty1, 2 * k), "FFFFFF", 1) end
        local ky = ty1 - (ty1 - ty0) * (muted and 0 or fr)
        shape(rrect(cx - 7 * k, ky - 7 * k, cx + 7 * k, ky + 7 * k, 7 * k), "FFFFFF", 1)
        S.vol.y0, S.vol.y1 = ty0, ty1
        region(cx - 18 * k, ty0 - 8 * k, cx + 18 * k, ty1 + 8 * k, "vol", true)
        -- mute toggle at the bottom of the popup
        local my = y1 - 24 * k
        local r = 18 * k
        if inside(cx - r, my - r, cx + r, my + r) then shape(rrect(cx - r, my - r, cx + r, my + r, r), "FFFFFF", 0.16) end
        ICON.mute(cx, my, k * 0.9, muted and opts.accent or "FFFFFF")
        region(cx - r, my - r, cx + r, my + r, "mute", true)
        return
    end

    S.vol.vertical = false
    btn("mute", cx, cy, k)
    if sw < 24 * k then return end
    local sx0 = cx + 22 * k + 4 * k
    shape(rrect(sx0, cy - 2 * k, sx0 + sw, cy + 2 * k, 2 * k), "FFFFFF", 0.3)
    shape(rrect(sx0, cy - 2 * k, sx0 + math.max(4 * k, sw * fr), cy + 2 * k, 2 * k), "FFFFFF", 1)
    local kx = sx0 + sw * fr
    shape(rrect(kx - 6 * k, cy - 6 * k, kx + 6 * k, cy + 6 * k, 6 * k), "FFFFFF", 1)
    region(sx0 - 6 * k, cy - 14 * k, sx0 + sw + 6 * k, cy + 14 * k, "vol")
    S.vol.x0, S.vol.x1 = sx0, sx0 + sw
    if show_pct then T(sx0 + sw + 10 * k, cy, 4, 13 * k, string.format("%d%%", math.floor(vol + 0.5)), "FFFFFF", 0.85) end
end

local function play_btn(cx, cy, k, D)
    if HIDE.play then return end
    local r = D / 2
    local hov = inside(cx - r, cy - r, cx + r, cy + r)
    shape(rrect(cx - r, cy - r, cx + r, cy + r, r), "FFFFFF", hov and 1 or 0.96)
    if S.paused then ICON.play(cx, cy, k, "111111") else ICON.pause(cx, cy, k, "111111") end
    region(cx - r, cy - r, cx + r, cy + r, "play")
end

local function time_pill_bg()
    local st = tostring(opts.time_pill_style):lower():gsub("[%s_%-]", ""):match("^%a+") or "darkglass"
    local c, o
    if st == "accent" then c, o = opts.accent, 0.9
    elseif st == "glass" then c, o = "FFFFFF", (opts.panel_blur and 0.25 or 0.2)
    elseif st == "dark" then c, o = "0E141C", 0.9
    else c, o = "0E141C", (opts.panel_blur and 0.35 or 0.55) end
    if opts.time_pill_color ~= "" then c = opts.time_pill_color end
    if opts.time_pill_opacity >= 0 then o = opts.time_pill_opacity end
    return c, o, (opts.panel_blur and (st == "glass" or st == "darkglass")) and true or false
end

-- width the time label needs (text + pill padding); compact = elapsed only
local function time_width(k, fs, compact)
    local dur = mp.get_property_number("duration") or 0
    local pos = mp.get_property_number("time-pos") or 0
    local first = S.remaining and (MINUS .. fmt(math.max(0, dur - pos))) or fmt(pos)
    local wd = textw(first, fs, true)
    if not compact then wd = wd + textw(" / " .. fmt(dur), fs, false) end
    if opts.time_pill then wd = wd + 11 * k end
    return wd
end

local function time_label(xr, cy, k, fs, compact)
    if HIDE.time then return xr end
    local dur = mp.get_property_number("duration") or 0
    local pos = mp.get_property_number("time-pos") or 0
    local first = S.remaining and (MINUS .. fmt(math.max(0, dur - pos))) or fmt(pos)
    local total = compact and "" or (" / " .. fmt(dur))
    local wd = textw(first, fs, true) + textw(total, fs, false)
    local pad = opts.time_pill and 11 * k or 0
    if opts.time_pill then
        local ph = fs * 1.9
        local x0, y0, x1, y1 = xr - wd - pad, cy - ph / 2, xr + pad, cy + ph / 2
        local c, o, blur = time_pill_bg()
        shape(rrect(x0, y0, x1, y1, ph / 2), c, o)
        if blur then add_blur_rect(x0, y0, x1, y1, ph / 2) end
    end
    out[#out + 1] = string.format(
        "{\\an6\\pos(%s,%s)\\fn%s\\fs%s\\b1\\bord0\\shad%s\\1c&H%s&\\1a&H%s&\\4c&H000000&\\4a&H70&}%s{\\b0\\1a&H%s&}%s",
        f(xr), f(cy), opts.font, f(fs), f(math.max(1, fs / 14)), bgr("FFFFFF"), A(1),
        esc(first), A(0.7), esc(total))
    region(xr - wd - pad - 4 * k, cy - 14 * k, xr + pad + 2 * k, cy + 14 * k, "time")
    return xr - wd - pad
end

local function tools_items()
    local items = {}
    for _, n in ipairs({ "info", "tracks", "loop", "playlist", "fullscreen" }) do
        if not HIDE[n] and (n ~= "info" or opts.show_info_button) then items[#items + 1] = n end
    end
    return items
end

-- right cluster: info card, tracks & playback menu, loop, playlist, fullscreen. returns left edge
local function tools_cluster(xr, cy, k, list)
    local items = list or tools_items()
    local step = 46 * k
    local spd = mp.get_property_number("speed") or 1
    local sid = get("sid")
    local sub_on = sid and sid ~= "no" and sid ~= "false"
    local lmode = loop_mode()
    local looping = lmode ~= nil
    local hint = opts.highlight_active and opts.accent or "FFFFFF"
    local border = active_look()
    local on_icon = border and opts.accent or "FFFFFF"
    local fullscreen = get("fullscreen") == "yes"
    for i, name in ipairs(items) do
        local cx = xr - 22 * k - (#items - i) * step
        local o = {}
        if name == "info" then
            o.active = S.card
            o.color = S.card and on_icon or "FFFFFF"
        elseif name == "tracks" then
            o.active = S.menu
            o.color = S.menu and on_icon or ((sub_on or math.abs(spd - 1) > 0.001) and hint or "FFFFFF")
        elseif name == "loop" then
            o.active = looping
            o.tag = lmode == "file" and "1" or (lmode == "playlist" and "\226\136\158" or nil)
            o.color = looping and on_icon or "FFFFFF"
        elseif name == "playlist" then
            o.active = S.drawer
            o.color = S.drawer and on_icon or "FFFFFF"
        elseif name == "fullscreen" then
            o.active = fullscreen
            o.color = fullscreen and on_icon or "FFFFFF"
        end
        btn(name, cx, cy, k, o)
    end
    return xr - #items * step
end

---------------------------------------------------------------------------
-- menus: tracks & playback popover, chapters / playlist drawer
---------------------------------------------------------------------------
local SPEEDS = { 0.5, 0.75, 1, 1.25, 1.5, 2 }

-- Panels (tracks menu + drawer) use two scales: `k` (geometry, shrunk by panel_scale) and
-- `fk` (fonts, never shrunk), so the panels can be made compact without shrinking the text.
local function draw_menu(ctx, right, bottom)
    local fk = ctx.k
    local k = fk * opts.panel_scale
    local function PT(x, y, an, fs, str, rgb, op, bold)
        T(x, y, an, fs, str, rgb, op, bold, nil, not opts.panel_text_shadow)
    end
    local W, P = 420 * k, 18 * k
    local x1 = right
    local x0 = x1 - W
    local audio, subs = {}, {}
    for _, t in ipairs(mp.get_property_native("track-list") or {}) do
        if t.type == "audio" then audio[#audio + 1] = t elseif t.type == "sub" then subs[#subs + 1] = t end
    end
    local rowh = opts.panel_row_height * k
    local ph = opts.panel_pill_height * k
    local sth = ph + 6 * k
    local nrows = clamp(math.max(#audio, #subs + 1), 2, 6)
    local H = P + 20 * k + nrows * rowh + 10 * k + 11 * k + 18 * k + ph + 10 * k
              + 2 * sth + 6 * k + 26 * k + P
    local y0 = math.max(8 * k, bottom - H)
    local y1 = y0 + H

    shape(rrect(x0, y0, x1, y1, 20 * k), panel_bg())
    add_blur_rect(x0, y0, x1, y1, 20 * k)
    region(x0, y0, x1, y1, "panel", true)

    local colw = (W - 2 * P - 20 * k) / 2
    local cax, cbx = x0 + P, x0 + P + colw + 20 * k
    local y = y0 + P
    PT(cax, y + 7 * k, 4, 12 * fk, "AUDIO" .. MID .. #audio, "B8B8B8", 1, true)
    PT(cbx, y + 7 * k, 4, 12 * fk, "SUBTITLES" .. MID .. #subs, "B8B8B8", 1, true)
    y = y + 20 * k

    local function row(x, ry, name, sub, selected, rname)
        local rh = rowh - 3 * k
        local hov = inside(x, ry, x + colw, ry + rh)
        if selected or hov then shape(rrect(x, ry, x + colw, ry + rh, opts.panel_round_rows and rh / 2 or 9 * k), "FFFFFF", selected and 0.13 or 0.08) end
        if sub and sub ~= "" then
            PT(x + 9 * k, ry + rh * 0.32, 4, 14 * fk, fit(name, 14 * fk, colw - 36 * k, true), "FFFFFF", 1, true)
            PT(x + 9 * k, ry + rh * 0.72, 4, 12 * fk, fit(sub, 12 * fk, colw - 36 * k), "C4C4C4", 1)
        else
            PT(x + 9 * k, ry + rh / 2, 4, 14 * fk, name, "FFFFFF", 1, true)
        end
        if selected then ICON.check(x + colw - 15 * k, ry + rh / 2, k * 0.85, opts.accent) end
        region(x, ry, x + colw, ry + rh, rname, true)
    end

    for i = 1, math.min(#audio, nrows) do
        local t = audio[i]
        row(cax, y + (i - 1) * rowh, track_name(t), track_detail(t), t.selected, "aud:" .. t.id)
    end
    local sid = get("sid")
    local off = (sid == "no" or sid == "false" or sid == nil)
    row(cbx, y, "Off", nil, off, "sub:0")
    for i = 1, math.min(#subs, nrows - 1) do
        local t = subs[i]
        row(cbx, y + i * rowh, track_name(t), track_detail(t), t.selected, "sub:" .. t.id)
    end
    y = y + nrows * rowh + 10 * k

    shape(rectp(x0 + P, y, x1 - P, y + 1 * k), "FFFFFF", 0.14)
    y = y + 11 * k

    PT(x0 + P, y + 6 * k, 4, 12 * fk, "SPEED", "B8B8B8", 1, true)
    y = y + 18 * k
    local cur = mp.get_property_number("speed") or 1
    local cgap = 4 * k
    local cw = (W - 2 * P - 5 * cgap) / 6
    for i, sp in ipairs(SPEEDS) do
        local cx0 = x0 + P + (i - 1) * (cw + cgap)
        local sel = math.abs(cur - sp) < 0.001
        if sel then
            shape(rrect(cx0, y, cx0 + cw, y + ph, ph / 2), "FFFFFF", 1)
        else
            shape(ring(cx0, y, cx0 + cw, y + ph, ph / 2, 1.4 * k), "FFFFFF", inside(cx0, y, cx0 + cw, y + ph) and 0.7 or 0.3)
        end
        PT(cx0 + cw / 2, y + ph / 2, 5, 14 * fk, string.format("%g", sp) .. "\195\151", sel and "111111" or "FFFFFF", 1, true)
        region(cx0, y, cx0 + cw, y + ph, "spd:" .. sp, true)
    end
    y = y + ph + 10 * k

    local function stepper(label, prop, tag)
        local val = mp.get_property_number(prop) or 0
        local cy = y + sth / 2
        PT(x0 + P, cy, 4, 14 * fk, label, "FFFFFF", 1, true)
        local r = ph / 2
        local pc = x1 - P - r
        local vc = pc - 52 * k
        local mc = vc - 52 * k
        local function sbtn(cx, icon, name)
            local hv = inside(cx - r, cy - r, cx + r, cy + r)
            shape(ring(cx - r, cy - r, cx + r, cy + r, r, 1.4 * k), "FFFFFF", hv and 0.8 or 0.3)
            ICON[icon](cx, cy, k * 0.7, "FFFFFF")
            region(cx - r, cy - r, cx + r, cy + r, name, true)
        end
        sbtn(mc, "minus", "dly:" .. tag .. "-")
        PT(vc, cy, 5, 14 * fk, string.format("%+d ms", math.floor(val * 1000 + 0.5)):gsub("^%+0 ms$", "0 ms"), "FFFFFF", 1)
        sbtn(pc, "plus", "dly:" .. tag .. "+")
        y = y + sth
    end
    stepper("Audio delay", "audio-delay", "a")
    stepper("Subtitle delay", "sub-delay", "s")
    y = y + 6 * k

    local lx = x0 + P
    local lw = textw("Load subtitle file" .. ELLIPSIS, 14 * fk, true) + 30 * k
    ICON.plus(lx + 9 * k, y + 13 * k, k * 0.75, opts.accent)
    PT(lx + 24 * k, y + 13 * k, 4, 14 * fk, "Load subtitle file" .. ELLIPSIS, opts.accent, 1, true)
    region(lx, y, lx + lw, y + 26 * k, "loadsub", true)
end

---------------------------------------------------------------------------
-- media info card (video / audio / file details)
---------------------------------------------------------------------------
local function fmt_size(b)
    if not b or b <= 0 then return nil end
    local u, i = { "B", "KB", "MB", "GB", "TB" }, 1
    while b >= 1024 and i < #u do b = b / 1024; i = i + 1 end
    if i == 1 then return string.format("%d B", b) end
    return string.format("%.2f %s", b, u[i])
end

local function fmt_rate(bps)
    if not bps or bps <= 0 then return nil end
    if bps >= 1e6 then return string.format("%.2f Mb/s", bps / 1e6) end
    return string.format("%d kb/s", math.floor(bps / 1e3 + 0.5))
end

local function join(sep, ...)
    local r = {}
    for i = 1, select("#", ...) do
        local x = select(i, ...)
        if x and x ~= "" then r[#r + 1] = x end
    end
    return table.concat(r, sep)
end

local function card_rows()
    local rows = {}
    local function sec(t) rows[#rows + 1] = { head = t } end
    local function add(l, v)
        if v ~= nil and tostring(v) ~= "" then rows[#rows + 1] = { l = l, v = tostring(v) } end
    end
    local function pr(p) local v = get(p); if v == nil or v == "" then return nil end return v end
    local function pn(p) return mp.get_property_number(p) end

    sec("FILE")
    local fname = pr("filename")
    add("Name", fname)
    local mt = pr("media-title")
    if mt and mt ~= fname then add("Title", mt) end
    add("Container", pr("file-format"))
    add("Size", fmt_size(pn("file-size")))
    local dur = pn("duration")
    if dur and dur > 0 then add("Duration", fmt(dur)) end

    local vc = pr("current-tracks/video/codec")
    if vc then
        sec("VIDEO")
        add("Codec", join(MID, info.vcodec or vc:upper(), pr("current-tracks/video/codec-profile")))
        local vw, vh = pn("video-params/w"), pn("video-params/h")
        if vw and vh then
            add("Resolution", string.format("%d \195\151 %d", vw, vh) .. (info.res and (" (" .. info.res .. ")") or ""))
        end
        local fps = pn("container-fps") or pn("estimated-vf-fps")
        if fps and fps > 0 then
            local fs = string.format("%.3f", fps):gsub("0+$", ""):gsub("%.$", "")
            add("Frame rate", fs .. " fps")
        end
        add("Bitrate", fmt_rate(pn("video-bitrate")))
        add("Pixel format", pr("video-params/pixelformat"))
        add("Colour", join(" / ", pr("video-params/colormatrix"), pr("video-params/primaries"), pr("video-params/gamma")))
        if #info.hdr > 0 then add("HDR", table.concat(info.hdr, MID)) end
        local hw = pr("hwdec-current")
        add("Decoder", (hw == nil or hw == "no") and "Software" or hw)
        local dd, vd = pn("decoder-frame-drop-count"), pn("frame-drop-count")
        if dd or vd then add("Dropped", string.format("%d decoder" .. MID .. "%d output", dd or 0, vd or 0)) end
    end

    local ac = pr("current-tracks/audio/codec")
    if ac then
        sec("AUDIO")
        add("Codec", join(MID, info.acodec or ac:upper(), pr("current-tracks/audio/codec-profile")))
        local lang = pr("current-tracks/audio/lang")
        if lang then add("Language", LANG[lang:lower()] or lang:upper()) end
        add("Title", pr("current-tracks/audio/title"))
        add("Channels", pr("audio-params/hr-channels") or pr("audio-params/channels"))
        local sr = pn("audio-params/samplerate")
        if sr then add("Sample rate", string.format("%g kHz", sr / 1000)) end
        add("Format", pr("audio-params/format"))
        add("Bitrate", fmt_rate(pn("audio-bitrate")))
    end

    sec("SUBTITLES")
    local subtxt = "Off"
    for _, t in ipairs(mp.get_property_native("track-list") or {}) do
        if t.type == "sub" and t.selected then subtxt = join(MID, track_name(t), track_detail(t)) end
    end
    add("Track", subtxt)
    return rows
end

local function draw_card(ctx, right, bottom)
    local fk = ctx.k
    local k = fk * opts.panel_scale
    local function PT(x, y, an, fs, str, rgb, op, bold)
        T(x, y, an, fs, str, rgb, op, bold, nil, not opts.panel_text_shadow)
    end
    local rows = card_rows()
    local W, P = 400 * k, 18 * k
    local rh, hh, top = 21 * k, 26 * k, 26 * k
    local H = 2 * P + top
    for _, r in ipairs(rows) do H = H + (r.head and hh or rh) end
    local avail = bottom - 8 * k
    if H > avail then
        local sc = math.max(0.6, avail / H)
        rh, hh = rh * sc, hh * sc
        H = 2 * P + top
        for _, r in ipairs(rows) do H = H + (r.head and hh or rh) end
    end
    local x1 = right
    local x0 = x1 - W
    local y0 = math.max(8 * k, bottom - H)
    local y1 = y0 + H
    shape(rrect(x0, y0, x1, y1, 20 * k), panel_bg())
    add_blur_rect(x0, y0, x1, y1, 20 * k)
    region(x0, y0, x1, y1, "panel", true)

    PT(x0 + P, y0 + P + 6 * k, 4, 14 * fk, "Media info", "FFFFFF", 1, true)
    local y = y0 + P + top
    local lw = 100 * k
    for _, r in ipairs(rows) do
        if r.head then
            PT(x0 + P, y + hh * 0.62, 4, 12 * fk, r.head, "B8B8B8", 1, true)
            y = y + hh
        else
            PT(x0 + P, y + rh / 2, 4, 13 * fk, r.l, "C4C4C4", 0.9)
            PT(x0 + P + lw, y + rh / 2, 4, 13 * fk, fit(r.v, 13 * fk, W - 2 * P - lw), "FFFFFF", 1)
            y = y + rh
        end
    end
end

---------------------------------------------------------------------------
-- play history (recent files, saved to history_file)
---------------------------------------------------------------------------
local H = { list = {}, path = nil, dirty = false, loaded = false }

local function history_path()
    if H.path == nil then
        local ok, res = pcall(mp.command_native, { "expand-path", opts.history_file })
        H.path = (ok and type(res) == "string" and res ~= "") and res or false
    end
    return H.path
end

-- mpv's own watch history (save-watch-history=yes): JSON lines {time, path, title?}
local function mpv_history_enabled()
    local src = tostring(opts.history_source):lower():match("^%s*(%a+)") or "auto"
    if src == "own" then return false end
    local v = get("options/save-watch-history")
    return v == "yes" or v == "true"
end

local function mpv_history_read()
    local want = get("options/watch-history-path")
    if not want or want == "" then want = "~~state/watch_history.jsonl" end
    local ok, fp = pcall(mp.command_native, { "expand-path", want })
    if not ok or type(fp) ~= "string" or fp == "" then return end
    local fh = io.open(fp, "r")
    if not fh then return end
    local rows = {}
    for line in fh:lines() do
        if line:find("{", 1, true) then
            local ok2, e = pcall(utils.parse_json, line)
            if ok2 and type(e) == "table" and type(e.path) == "string" then rows[#rows + 1] = e end
        end
    end
    fh:close()
    local list, seen = {}, {}
    for i = #rows, 1, -1 do                      -- newest first, one entry per file
        local e = rows[i]
        if not seen[e.path] then
            seen[e.path] = true
            local title = e.title
            if not title or title == "" then
                local _, file = utils.split_path(e.path)
                title = (file or e.path):gsub("%.[^%.]+$", "")
            end
            list[#list + 1] = { path = e.path, title = title, t = tonumber(e.time) or 0, pos = 0, dur = 0 }
            if #list >= math.max(1, opts.history_max) then break end
        end
    end
    H.list = list
end

local function history_load()
    if opts.history and mpv_history_enabled() then
        if H.reload ~= false then H.reload = false; mpv_history_read() end
        return
    end
    if H.loaded then return end
    H.loaded = true
    local fp = history_path()
    if not fp then return end
    local fh = io.open(fp, "r")
    if not fh then return end
    local txt = fh:read("*a")
    fh:close()
    local ok, data = pcall(utils.parse_json, txt)
    if ok and type(data) == "table" then
        for _, e in ipairs(data) do
            if type(e) == "table" and type(e.path) == "string" then H.list[#H.list + 1] = e end
        end
    end
end

local function history_save()
    if not H.dirty or mpv_history_enabled() then return end
    local fp = history_path()
    if not fp then return end
    local ok, txt = pcall(utils.format_json, H.list)
    if not ok or not txt then return end
    local fh = io.open(fp, "w")
    if not fh then return end
    fh:write(txt)
    fh:close()
    H.dirty = false
end

local function history_touch()
    if not opts.history then return end
    if mpv_history_enabled() then H.reload = true; return end
    history_load()
    local path = mp.get_property("path")
    if not path or path == "" then return end
    local title = mp.get_property("media-title") or path
    local pos = mp.get_property_number("time-pos")
    local dur = mp.get_property_number("duration")
    for i = #H.list, 1, -1 do
        if H.list[i].path == path then table.remove(H.list, i) end
    end
    table.insert(H.list, 1, { path = path, title = title, pos = pos or 0, dur = dur or 0, t = os.time() })
    while #H.list > math.max(1, opts.history_max) do table.remove(H.list) end
    H.dirty = true
end

-- remember where the current file is (called periodically and when it ends)
local function history_pos()
    if not opts.history or not H.loaded or not H.list[1] or mpv_history_enabled() then return end
    local path = mp.get_property("path")
    if path ~= H.list[1].path then return end
    local pos = mp.get_property_number("time-pos")
    local dur = mp.get_property_number("duration")
    if pos then
        H.list[1].pos = pos
        if dur then H.list[1].dur = dur end
        H.dirty = true
    end
end

local function ago(t)
    local d = os.time() - (t or 0)
    if d < 90 then return "now" end
    if d < 3600 then return math.floor(d / 60 + 0.5) .. "m" end
    if d < 86400 then return math.floor(d / 3600 + 0.5) .. "h" end
    return math.floor(d / 86400 + 0.5) .. "d"
end

local function history_play(idx)
    local e = H.list[idx]
    if not e then return end
    local cmd = { name = "loadfile", url = e.path, flags = "replace" }
    if opts.history_resume and (e.pos or 0) > 10 and (e.dur or 0) > 0 and e.pos < e.dur - 15 then
        cmd.options = "start=" .. string.format("%.1f", e.pos)
    end
    mp.command_native(cmd)
end

local function draw_drawer(ctx)
    local fk, w, h = ctx.k, ctx.w, ctx.h
    local k = fk * opts.panel_scale
    local function PT(x, y, an, fs, str, rgb, op, bold)
        T(x, y, an, fs, str, rgb, op, bold, nil, not opts.panel_text_shadow)
    end
    local x0 = w * 0.04
    local W = (opts.history and 360 or 310) * k
    if opts.drawer_width_pct > 0 then W = w * opts.drawer_width_pct / 100
    elseif opts.drawer_width > 0 then W = opts.drawer_width * k end
    local y0 = h * 0.12
    local Hd = h * 0.46 * opts.panel_scale
    if S.audio then
        -- audio skin: line up with the card's left edge and use the room above the seek bar
        local Hc = math.min(h, w * 9 / 16)
        local oy = (h - Hc) / 2
        x0 = math.max(40 * math.min(w / 960, h / 540), w * 0.067)
        local floor_w = math.min(w * 0.34, 420 * k)       -- never narrower than this in the audio skin
        if opts.drawer_width_pct <= 0 and opts.drawer_width <= 0 then W = math.max(W, math.min(w * 0.4, 440 * k * 1.3)) end
        W = math.max(W, floor_w)
        y0 = oy + Hc * 0.13
        Hd = Hc * 0.59
    end
    W = math.max(160 * k, math.min(W, w - x0 - w * 0.02))
    local P = 12 * k
    local x1, y1 = x0 + W, y0 + Hd
    shape(rrect(x0, y0, x1, y1, 20 * k), panel_bg())
    add_blur_rect(x0, y0, x1, y1, 20 * k)
    region(x0, y0, x1, y1, "panel", true)
    S.drawer_rect = { x0, y0, x1, y1 }

    -- tabs
    local playlist = mp.get_property_native("playlist") or {}
    local ph = opts.panel_pill_height * k
    local tab_y, tab_h = y0 + P, ph
    shape(rrect(x0 + P, tab_y, x1 - P, tab_y + tab_h + 6 * k, (tab_h + 6 * k) / 2), "FFFFFF", 0.08)
    local tabs = { { "playlist", "Playlist" .. MID .. #playlist }, { "chapters", "Chapters" .. MID .. #chapters } }
    if opts.history then tabs[3] = { "history", "History" } end
    local tw = (W - 2 * P - 6 * k) / #tabs
    local tfs = 14 * fk                      -- shrink the tab text until every label fits its tab
    for _, t in ipairs(tabs) do
        local need = textw(t[2], 14 * fk, true)
        if need > tw - 12 * k then tfs = math.min(tfs, 14 * fk * (tw - 12 * k) / need) end
    end
    for i, t in ipairs(tabs) do
        local tx0 = x0 + P + 3 * k + (i - 1) * tw
        local sel = S.drawer == t[1]
        if sel then shape(rrect(tx0, tab_y + 3 * k, tx0 + tw, tab_y + 3 * k + tab_h, tab_h / 2), "FFFFFF", 1) end
        PT(tx0 + tw / 2, tab_y + 3 * k + tab_h / 2, 5, tfs, t[2], sel and "111111" or "DDDDDD", 1, true)
        region(tx0, tab_y + 3 * k, tx0 + tw, tab_y + 3 * k + tab_h, "tab:" .. t[1], true)
    end

    local ly = tab_y + tab_h + 6 * k + 10 * k
    local rowh = opts.panel_row_height * k
    local rh = rowh - 3 * k
    local visible = math.max(1, math.floor((y1 - P - ly) / rowh))
    local items = {}
    local cur_ch = mp.get_property_number("chapter") or -1
    if S.drawer == "history" then
        history_load()
        local curp = mp.get_property("path")
        for i, e in ipairs(H.list) do
            items[i] = { name = e.title or e.path, right = (e.path == curp) and "\226\150\182" or ago(e.t),
                         cur = e.path == curp, rname = "hi:" .. i }
        end
    elseif S.drawer == "chapters" then
        for i, c in ipairs(chapters) do
            local nm = (c.title and c.title ~= "") and c.title or ("Chapter " .. i)
            items[i] = { name = nm, right = fmt(c.time), cur = (i - 1) == cur_ch, rname = "ch:" .. (i - 1) }
        end
    else
        for i, e in ipairs(playlist) do
            local nm = e.title
            if not nm or nm == "" then
                local _, file = utils.split_path(e.filename or "")
                nm = (file or ""):gsub("%.[^%.]+$", "")
            end
            items[i] = { name = nm, right = e.current and "\226\150\182" or nil, cur = e.current, rname = "pl:" .. (i - 1) }
        end
    end
    local maxscroll = math.max(0, #items - visible)
    S.scroll = clamp(S.scroll, 0, maxscroll)
    if #items == 0 then
        PT(x0 + W / 2, ly + 24 * k, 5, 14 * fk, S.drawer == "history" and "No history yet" or (S.drawer == "chapters" and "No chapters in this file" or "Playlist is empty"), "C4C4C4", 1)
    end
    for i = 1, math.min(visible, #items - S.scroll) do
        local it = items[i + S.scroll]
        local ry = ly + (i - 1) * rowh
        local rx0, rx1 = x0 + P, x1 - P
        local hov = inside(rx0, ry, rx1, ry + rh)
        local rrad = opts.panel_round_rows and rh / 2 or rh / 2.6
        if it.cur then
            shape(rrect(rx0, ry, rx1, ry + rh, rrad), "FFFFFF", 0.12)
            shape(ring(rx0, ry, rx1, ry + rh, rrad, 1.4 * k), opts.accent, 1)
        elseif hov then
            shape(rrect(rx0, ry, rx1, ry + rh, rrad), "FFFFFF", 0.08)
        end
        local num = tostring(i + S.scroll)
        local bd = rh - 10 * k
        local bx0 = rx0 + (opts.panel_round_rows and 5 * k or 6 * k)
        local bx1 = opts.panel_round_rows and (bx0 + bd) or (rx0 + 30 * k)
        shape(rrect(bx0, ry + 5 * k, bx1, ry + rh - 5 * k, opts.panel_round_rows and bd / 2 or 5 * k), "FFFFFF", 0.1)
        PT((bx0 + bx1) / 2, ry + rh / 2, 5, 13 * fk, num, "FFFFFF", 0.85, true)
        local rw = it.right and (textw(it.right, 13 * fk) + 8 * k) or 0
        PT(rx0 + 40 * k, ry + rh / 2, 4, 14 * fk,
            fit(it.name, 14 * fk, (rx1 - rx0) - 48 * k - rw - 8 * k, it.cur), "FFFFFF", 1, it.cur)
        if it.right then PT(rx1 - 9 * k, ry + rh / 2, 6, 13 * fk, it.right, "FFFFFF", it.cur and 1 or 0.7) end
        region(rx0, ry, rx1, ry + rh, it.rname, true)
    end
    if maxscroll > 0 then
        local th = (y1 - P - ly)
        local bh = math.max(24 * k, th * visible / #items)
        local by = ly + (th - bh) * (S.scroll / maxscroll)
        shape(rrect(x1 - 6 * k, by, x1 - 4 * k, by + bh, 1 * k), "FFFFFF", 0.4)
    end
end

---------------------------------------------------------------------------
-- layouts
---------------------------------------------------------------------------
-- which skip buttons can do something right now
local function skip_state()
    local pc = mp.get_property_number("playlist-count") or 0
    local pos = mp.get_property_number("playlist-pos-1") or 1
    local loop = (get("loop-playlist") or "no") ~= "no"
    local nch = #chapters
    local ch = mp.get_property_number("chapter") or 0
    return {
        plprev = pc > 1 and (pos > 1 or loop),
        plnext = pc > 1 and (pos < pc or loop),
        chprev = nch > 0,
        chnext = nch > 0 and ch < nch - 1,
    }
end

local function skip_btn(name, cx, cy, k, st)
    local key = ({ prev = "plprev", next = "plnext", chprev = "chprev", chnext = "chnext" })[name]
    local icon = ({ prev = "plprev", next = "plnext", chprev = "prev", chnext = "next" })[name]
    btn(name, cx, cy, k, { disabled = not st[key], icon = icon })
end

-- the skip buttons in drawing order (chapter buttons can be dropped to make room)
local function skip_seq(skipch)
    local seq = { "prev" }
    if opts.show_chapter_buttons and not skipch then seq[#seq + 1] = "chprev" end
    seq[#seq + 1] = "back"
    seq[#seq + 1] = "fwd"
    if opts.show_chapter_buttons and not skipch then seq[#seq + 1] = "chnext" end
    seq[#seq + 1] = "next"
    return seq
end

-- x where the volume button would sit
local function left_end(mx, k, skipch)
    local cx = HIDE.play and (mx + 22 * k) or (mx + 52 * k + 8 * k + 22 * k)
    local n = 0
    for _, name in ipairs(skip_seq(skipch)) do
        if not HIDE[name] then n = n + 1 end
    end
    return cx + n * 46 * k + (n > 0 and 10 * k or 0)
end

-- play button + skip buttons; returns the x where the volume button goes
local function left_cluster(mx, cy, k, skipch)
    local D = 52 * k
    local cx
    if HIDE.play then
        cx = mx + 22 * k
    else
        play_btn(mx + D / 2, cy, k, D)
        cx = mx + D + 8 * k + 22 * k
    end
    local st = skip_state()
    local n = 0
    for _, name in ipairs(skip_seq(skipch)) do
        if not HIDE[name] then
            if name == "back" or name == "fwd" then btn(name, cx, cy, k) else skip_btn(name, cx, cy, k, st) end
            cx = cx + 46 * k
            n = n + 1
        end
    end
    if n > 0 then cx = cx + 10 * k end
    return cx
end

-- streamer/center bottom row. The volume button is kept as long as possible: on narrow windows
-- the time drops its total first, then the chapter buttons step aside; only then does volume go.
local function bottom_row(w, mx, cy, k)
    local xl = tools_cluster(w - mx, cy, k)
    local tr = xl - 16 * k
    local fs = 18 * k
    local compact, skipch = false, false
    local vol = not HIDE.volume
    if not HIDE.time then
        local function fits(c, sk)
            return tr - time_width(k, fs, c) >= left_end(mx, k, sk) + 22 * k + 6 * k
        end
        if vol then
            if fits(false, false) then
            elseif fits(true, false) then compact = true
            elseif fits(true, true) then compact, skipch = true, true
            else vol, compact = false, true end
        end
        if not vol and tr - time_width(k, fs, false) < left_end(mx, k, false) - 34 * k then compact = true end
    end
    local cx = left_cluster(mx, cy, k, skipch)
    local tl = tr
    if not HIDE.time then tl = time_label(tr, cy, k, fs, compact) end
    if vol then volume_ctl(cx, cy, k, clamp(tl - 14 * k - (cx + 26 * k), 0, 96 * k)) end
    return xl
end

---------------------------------------------------------------------------
-- audio-only skin: "Now Playing" card
---------------------------------------------------------------------------
local LOSSLESS = { flac = true, alac = true, truehd = true, wavpack = true, ape = true, tta = true }

local function audio_meta()
    local function md(key)
        local v = get("metadata/by-key/" .. key)
        if v == nil or v == "" then return nil end
        return v
    end
    local title = md("title")
    local artist = md("artist") or md("album_artist")
    if not title then
        title = get("media-title") or get("filename/no-ext") or ""
        if not artist then
            local a, t = title:match("^(.-)%s+%-%s+(.+)$")
            if a and t then artist, title = a, t end
        end
    end
    local year = (md("date") or md("year") or ""):match("(%d%d%d%d)")
    return title, artist, md("album"), year
end

local function audio_pill_list()
    local p = {}
    local raw = (get("current-tracks/audio/codec") or ""):lower()
    if info.acodec then p[#p + 1] = info.acodec end
    if LOSSLESS[raw] or raw:find("^pcm") then p[#p + 1] = "Lossless" end
    local sr = mp.get_property_number("audio-params/samplerate")
    if sr then p[#p + 1] = string.format("%g kHz", sr / 1000) end
    local ch = mp.get_property_number("current-tracks/audio/demux-channel-count")
        or mp.get_property_number("audio-params/channel-count")
    if ch then p[#p + 1] = (ch == 2 and "Stereo") or (ch == 1 and "Mono") or (LAYOUT_NAME[ch] or (ch .. "ch")) end
    local br = fmt_rate(mp.get_property_number("audio-bitrate"))
    if br then p[#p + 1] = br end
    return p
end

local function audio_next_title()
    local n = mp.get_property_number("playlist-count") or 0
    local i = mp.get_property_number("playlist-pos-1")
    if n < 2 or not i or i >= n then return nil end
    local e = (mp.get_property_native("playlist") or {})[i + 1]
    if not e then return nil end
    if e.title and e.title ~= "" then return e.title end
    local _, file = utils.split_path(e.filename or "")
    return ((file or ""):gsub("%.[^%.]+$", ""))
end

local function corner_path(x0, y0, sx, sy, r)
    local c = r * 0.5523
    local function P(x, y) return f(x0 + sx * x) .. " " .. f(y0 + sy * y) end
    -- reaches 2px past the picture edges so no sliver of the square picture shows along them
    local e = 2
    return "m " .. P(-e, -e) .. " l " .. P(r, -e) .. " l " .. P(r, 0) .. " b " .. P(r - c, 0) .. " " .. P(0, r - c) .. " " .. P(0, r)
        .. " l " .. P(-e, r) .. " l " .. P(-e, -e)
end


local function layout_audio(ctx)
    local w, h = ctx.w, ctx.h
    local stacked = opts.audio_cover_pos == "center"
    local ak = (stacked and math.min(w / 560, h / 800) or math.min(w / 960, h / 540)) * opts.audio_scale
    local bk = ak * 1.15
    local mx = stacked and w * 0.08 or math.max(40 * ak, w * 0.067)
    local title, artist, album, year = audio_meta()
    local cover = S.cover

    -- cover square
    -- the 16:9 composition is kept in taller windows: it is centred vertically instead of stretched
    local Hc = stacked and h or math.min(h, w * 9 / 16)
    local oy = (h - Hc) / 2
    local side, cx0, cy0
    local tk = ak
    if stacked then
        side = math.min(w * 0.5, h * 0.30); cx0 = (w - side) / 2; cy0 = h * 0.1
    else
        side = math.min(Hc * 0.49, w * 0.30); cx0 = mx; cy0 = oy + Hc * 0.19
        -- centre the whole block (cover + text) in the window: measure the widest text line first
        local gap0 = w * 0.05
        local avail = w - 2 * mx - side - gap0
        local parts0 = {}
        if album then parts0[#parts0 + 1] = album end
        if year then parts0[#parts0 + 1] = year end
        local pn0, pi0 = mp.get_property_number("playlist-count") or 0, mp.get_property_number("playlist-pos-1")
        if pn0 > 1 and pi0 then parts0[#parts0 + 1] = string.format("Track %d of %d", pi0, pn0) end
        local tfs0 = 40 * tk
        local m1, m2 = wrap2(title, tfs0, avail, true)
        local tw = textw(m1, tfs0, true)
        if m2 then tw = math.max(tw, textw(m2, tfs0, true)) end
        if artist then tw = math.max(tw, textw(fit(artist, 20 * tk, avail), 20 * tk)) end
        local ln0 = table.concat(parts0, DOT)
        if ln0 ~= "" then tw = math.max(tw, textw(fit(ln0, 15 * tk, avail), 15 * tk)) end
        local pk0, pw0 = tk * 1.2, 0
        for _, str in ipairs(audio_pill_list()) do
            local cwid = textw(str, opts.pill_font_size * pk0, opts.pill_bold) + 2 * opts.pill_padding * pk0
            if pw0 + cwid > avail then break end
            pw0 = pw0 + cwid + opts.pill_gap * pk0
        end
        tw = math.max(tw, pw0 - opts.pill_gap * pk0)
        local nxt0 = audio_next_title()
        if nxt0 then tw = math.max(tw, textw(fit("Up next" .. DOT .. nxt0, 14 * tk, avail), 14 * tk)) end
        tw = math.min(tw, avail)
        S.blk_w = side + gap0 + tw
        cx0 = (w - S.blk_w) / 2
    end
    local cr = math.min(26 * ak, side / 4)
    audio_video_place(w, h, cx0, cy0, side, cover)

    -- where the picture really sits (aspect-fit inside the square)
    local asp = mp.get_property_number("video-params/aspect") or 1
    if asp <= 0 then asp = 1 end
    local iw, ih = side, side
    if asp >= 1 then ih = side / asp else iw = side * asp end
    local ix0, iy0 = cx0 + (side - iw) / 2, cy0 + (side - ih) / 2
    local ix1, iy1 = ix0 + iw, iy0 + ih
    local r_img = math.min(cr, iw / 2, ih / 2)

    -- rounded cover: paint the square corners of the picture in the background colour
    if cover then
        shape(table.concat({ corner_path(ix0, iy0, 1, 1, r_img), corner_path(ix1, iy0, -1, 1, r_img),
            corner_path(ix0, iy1, 1, -1, r_img), corner_path(ix1, iy1, -1, -1, r_img) }, " "), opts.audio_bg, 1)
    end
    -- soft glows (rings with a hole where the picture is, so the art is never tinted)
    if opts.audio_glow then
        local hole = cover and rrect_ccw(ix0, iy0, ix1, iy1, r_img) or nil
        local gx, gy = cx0 + side / 2, cy0 + side / 2
        local pal = S.pal
        local gc = mix_hex(pal and pal[1] or opts.accent, "000000", pal and 0.5 or 0.55)
        local gc2 = pal and mix_hex(pal[2], "000000", 0.45) or "1D3A63"
        local n, r0, r1 = 16, side * 0.8, side * 2.0
        for i = 1, n do
            local r = r1 - (r1 - r0) * (i - 1) / (n - 1)
            local path = rrect(gx - r, gy - r, gx + r, gy + r, r)
            if hole then path = path .. " " .. hole end
            shape(path, gc, 0.5 / n)
        end
        local R1 = math.min(w * 0.55, h * 0.9)
        local R0 = R1 * 0.45
        for i = 1, n do
            local r = R1 - (R1 - R0) * (i - 1) / (n - 1)
            local ox, oy = w * 0.95, h * 1.05
            shape(rrect(ox - r, oy - r, ox + r, oy + r, r), gc2, 0.6 / n)
        end
    end
    if not cover then
        shape(rrect(cx0, cy0, cx0 + side, cy0 + side, cr), mix_hex(opts.accent, "000000", 0.5), 1)
        local ini = (title:match("[%z\1-\127\194-\244][\128-\191]*") or "\226\153\170"):upper()
        T(cx0 + side / 2, cy0 + side / 2, 5, side * 0.42, ini, "FFFFFF", 0.85, true, nil, true)
    end

    top_bar(ctx)

    -- text block
    local acc = mix_hex(opts.accent, "FFFFFF", 0.35)
    local function put(x, y, fs, str, rgb, op, bold)
        T(x, y, stacked and 5 or 4, fs, str, rgb, op, bold)
    end
    local tx, maxw, y
    if stacked then
        tx, maxw = w / 2, w - 2 * mx
        y = cy0 + side + h * 0.04
    else
        tx = cx0 + side + w * 0.05
        maxw = w - cx0 - tx + 3 * tk
        y = cy0 + math.max(8 * tk, (side - 215 * tk) / 2)
    end
    put(tx, y, 12 * tk, "NOW PLAYING", acc, 1, true)
    y = y + (stacked and 30 or 32) * tk
    local tfs = (stacked and 30 or 40) * tk
    local l1, l2 = wrap2(title, tfs, maxw, true)
    put(tx, y, tfs, l1, "FFFFFF", 1, true)
    if l2 then y = y + tfs * 1.12; put(tx, y, tfs, l2, "FFFFFF", 1, true) end
    y = y + tfs * 0.5 + 22 * tk
    if artist then
        put(tx, y, 20 * tk, fit(artist, 20 * tk, maxw), "E6E8EE", 1)
        y = y + 28 * tk
    end
    local parts = {}
    if album then parts[#parts + 1] = album end
    if year then parts[#parts + 1] = year end
    local pn, pi = mp.get_property_number("playlist-count") or 0, mp.get_property_number("playlist-pos-1")
    if pn > 1 and pi then parts[#parts + 1] = string.format("Track %d of %d", pi, pn) end
    local line = table.concat(parts, DOT)
    if line ~= "" then
        put(tx, y, 15 * tk, fit(line, 15 * tk, maxw), "B8BCC6", 1)
        y = y + 30 * tk
    end
    local pl = audio_pill_list()
    local pk = tk * 1.2
    local gap = opts.pill_gap * pk
    local function cw(str) return textw(str, opts.pill_font_size * pk, opts.pill_bold) + 2 * opts.pill_padding * pk end
    local px = tx
    if stacked then
        local tot = -gap
        for _, str in ipairs(pl) do tot = tot + cw(str) + gap end
        px = tx - tot / 2
    end
    for _, str in ipairs(pl) do
        if px + cw(str) <= tx + (stacked and maxw / 2 + 1 or maxw) then
            px = px + chip(px, y, pk, str) + gap
        end
    end
    y = y + 34 * tk
    local nxt = audio_next_title()
    if nxt then put(tx, y, 14 * tk, fit("Up next" .. DOT .. nxt, 14 * tk, maxw), "D4D7DE", 1) end

    -- seek bar + times
    local seek_y = stacked and h * 0.765 or (oy + Hc * 0.75)
    draw_seek(mx, w - mx, seek_y, bk, 4 * bk, ctx)
    if not HIDE.time then
        local ty2 = seek_y + 26 * bk
        local dur = ctx.dur or 0
        T(mx, ty2, 4, 13 * bk, fmt(ctx.pos), "FFFFFF", 1, true)
        local rt = S.remaining and fmt(dur) or (MINUS .. fmt(math.max(0, dur - ctx.pos)))
        T(w - mx, ty2, 6, 13 * bk, rt, "C4C8D0", 1)
        region(w - mx - 70 * bk, ty2 - 12 * bk, w - mx + 4, ty2 + 12 * bk, "time")
    end

    -- transport
    local st = skip_state()
    local cyc = stacked and h * 0.865 or (oy + Hc * 0.872)
    local xc = w / 2
    local lmode = loop_mode()
    local border = active_look()
    local on_icon = border and opts.accent or "FFFFFF"
    btn("shuffle", xc - 124 * ak, cyc, bk, { active = S.shuffled, color = S.shuffled and on_icon or "FFFFFF" })
    btn("aprev", xc - 66 * ak, cyc, bk, { icon = "prev", disabled = not (st.plprev or st.chprev) })
    play_btn(xc, cyc, bk, 56 * ak)
    btn("anext", xc + 66 * ak, cyc, bk, { icon = "next", disabled = not (st.plnext or st.chnext) })
    btn("loop", xc + 124 * ak, cyc, bk, {
        active = lmode ~= nil,
        tag = lmode == "file" and "1" or (lmode == "playlist" and "\226\136\158" or nil),
        color = (lmode ~= nil) and on_icon or "FFFFFF" })

    -- volume + tools
    local aitems = {}
    for _, n in ipairs({ "info", "tracks", "playlist", "fullscreen" }) do
        if not HIDE[n] and (n ~= "info" or opts.show_info_button) then aitems[#aitems + 1] = n end
    end
    if stacked then
        local cy2 = h * 0.95
        local total = (#aitems + 1) * 46 * bk
        local x0 = (w - total) / 2
        volume_ctl(x0 + 22 * bk, cy2, bk, 0)
        tools_cluster(x0 + total, cy2, bk, aitems)
    else
        -- both sides get the same width: the volume slider fills what the tool buttons take on the right
        local sw = math.max(0, (#aitems - 1) * 46 * bk - 6 * bk)
        S.force_h = true
        volume_ctl(mx + 22 * bk, cyc, bk, sw)
        S.force_h = nil
        tools_cluster(w - mx, cyc, bk, aitems)
    end
    return w - mx, seek_y - 34 * bk
end

local function layout_streamer(ctx)
    local w, h, k = ctx.w, ctx.h, ctx.k
    local mx = w * 0.04
    out[#out + 1] = gradient(w, h, "full")
    top_bar(ctx)

    local L = opts.seek_lift * k
    local I = opts.info_lift * k
    local tfs = 34 * k
    local pp = playlist_pos()
    local full = (pp and (pp .. " ") or "") .. info.title
    local tw = textw(full, tfs, true)
    local maxw = w * 0.62
    if tw > maxw then
        if opts.title_two_lines then
            local l1, l2 = wrap2(full, tfs, maxw, true)
            if l2 then T(mx, h * 0.61 - L - I - tfs * 1.05, 4, tfs, l1, "FFFFFF", 1, true) end
            full = l2 or l1
        else
            tfs = tfs * maxw / tw
        end
    end
    T(mx, h * 0.61 - L - I, 4, tfs, full, "FFFFFF", 1, true)

    local by = h * 0.68 - L - I
    local bx = badges(mx, by, k)
    local cl = chapter_label()
    if cl and opts.pill_show_chapter then
        local cwid = textw(cl, opts.pill_font_size * k, opts.pill_bold) + 2 * opts.pill_padding * k
        if bx + cwid < w - mx then chip(bx, by, k, cl) end
    end

    T(mx, h * 0.733 - L - I, 4, 17 * k, info.meta, "C9C9C9", 1)
    local cache = mp.get_property_number("demuxer-cache-duration")
    if cache and cache > 0 then
        T(w - mx, h * 0.733 - L - I, 6, 14 * k, string.format("Cache %d s", math.floor(cache + 0.5)), "C4C4C4", 1)
    end

    local byy = h * 0.778 - L
    draw_seek(mx, w - mx, byy, k, 4 * k, ctx)

    local cy = h * 0.87
    bottom_row(w, mx, cy, k)
    return w - mx, byy - 26 * k
end

local function layout_center(ctx)
    local w, h, k = ctx.w, ctx.h, ctx.k
    local mx = w * 0.04
    out[#out + 1] = gradient(w, h, "full")
    top_bar(ctx)

    local cy = h * 0.915
    local sy = cy - (50 + opts.seek_lift) * k
    local I = opts.info_lift * k
    local below = opts.center_pills_below
    local py, ty
    if below then
        py = sy - (opts.seek_wave and (opts.wave_amplitude + 12) or 28) * k - I   -- pills row, clear of the wave
        ty = py - 26 * k                                                         -- title row above it
    else
        ty = sy - 36 * k - I
    end
    -- title row
    local cl = chapter_label()
    local ppc = playlist_pos()
    local tfull = (ppc and (ppc .. " ") or "") .. info.title
    local pills_left
    if below then
        pills_left = w - mx
    else
        -- measure the pills first: title and chapter label must stop before them
        local tmp = #out
        local bw = badges(0, -1000, k, { compact = true })
        for i = #out, tmp + 1, -1 do out[i] = nil end
        pills_left = w - mx - (bw - opts.pill_gap * k)
    end
    local room = pills_left - mx - 18 * k
    local tshown, line1 = tfull, nil
    if textw(tfull, 22 * k, true) > room then
        if opts.title_two_lines then
            local l1, l2 = wrap2(tfull, 22 * k, room, true)
            if l2 then line1, tshown = l1, l2 else tshown = l1 end
        else
            tshown = fit(tfull, 22 * k, room, true)
        end
    end
    if line1 then T(mx, ty - 25 * k, 4, 22 * k, line1, "FFFFFF", 1, true) end
    T(mx, ty, 4, 22 * k, tshown, "FFFFFF", 1, true)
    local tx2 = mx + textw(tshown, 22 * k, true) + 14 * k
    if cl then
        local avail = pills_left - tx2 - 14 * k
        local lbl = MID:sub(2) .. cl
        if textw(lbl, 15 * k) <= avail then
            T(tx2, ty + 2 * k, 4, 15 * k, lbl, "E0E0E0", 1)
        elseif avail > 90 * k then
            T(tx2, ty + 2 * k, 4, 15 * k, fit(lbl, 15 * k, avail), "E0E0E0", 1)
        end                                  -- too tight: leave the chapter label out
    end
    if below then badges(mx, py, k, { compact = true }) else badges(pills_left, ty, k, { compact = true }) end

    draw_seek(mx, w - mx, sy, k, 4 * k, ctx)

    bottom_row(w, mx, cy, k)
    return w - mx, ty - 22 * k - (line1 and 25 * k or 0)
end

local function layout_pill(ctx)
    local w, h, k = ctx.w, ctx.h, ctx.k
    local mx = w * 0.04
    out[#out + 1] = gradient(w, h, "pill")

    -- top-left: title chip + badges
    local cl = chapter_label()
    local sub = cl and (cl .. MID .. (mp.get_property_number("chapter") or 0) + 1 .. " of " .. #chapters) or info.meta
    local ppp = playlist_pos()
    if ppp then sub = ppp .. "  " .. sub end
    local line1w = textw(info.title, 20 * k, true) + (info.year and textw("  (" .. info.year .. ")", 20 * k) or 0)
    local cw = math.max(line1w, textw(sub, 14 * k)) + 36 * k
    cw = math.min(cw, w * 0.5)
    local ctop = 22 * k
    shape(rrect(mx, ctop, mx + cw, ctop + 60 * k, 18 * k), "0C121A", 0.66)
    T(mx + 18 * k, ctop + 20 * k, 4, 20 * k, fit(info.title, 20 * k, cw - 40 * k, true), "FFFFFF", 1, true)
    if info.year then T(mx + 18 * k + textw(info.title, 20 * k, true) + 6 * k, ctop + 20 * k, 4, 20 * k, "(" .. info.year .. ")", "FFFFFF", 0.7) end
    T(mx + 18 * k, ctop + 42 * k, 4, 14 * k, fit(sub, 14 * k, cw - 40 * k), "E0E0E0", 1)
    badges(mx, ctop + 60 * k + 10 * k + 12 * k, k, { compact = true })

    -- top-right: clock chip + window controls
    local cy = ctop + 30 * k
    local xl = winctl(w - mx, cy, k)
    if opts.show_clock then
        local now = os.time()
        local dur = mp.get_property_number("duration")
        local cs = clock(now)
        local es
        if dur and dur > 0 then
            local pos = mp.get_property_number("time-pos") or 0
            local spd = mp.get_property_number("speed") or 1
            es = "Ends at " .. clock(now + (mp.get_property_number("playtime-remaining") or ((dur - pos) / spd)))
        end
        local cw2 = math.max(textw(cs, 16 * k, true), es and textw(es, 12 * k) or 0) + 32 * k
        local cx1 = xl - 14 * k
        shape(rrect(cx1 - cw2, cy - 22 * k, cx1, cy + 22 * k, 18 * k), "0C121A", 0.66)
        T(cx1 - 16 * k, cy - 8 * k, 6, 16 * k, cs, "FFFFFF", 1, true)
        pin_bar(cx1 - cw2 + 14 * k, cy, k, S.clock_pinned)
        region(cx1 - cw2, cy - 22 * k, cx1, cy + 22 * k, "clockpin")
        if es then T(cx1 - 16 * k, cy + 11 * k, 6, 12 * k, es, "E0E0E0", 1) end
    end

    -- pill (widens on narrow windows so the buttons never collide)
    local pw = math.max(w * 0.78, math.min(w - 24 * k, (opts.show_chapter_buttons and 700 or 600) * k))
    local px0 = (w - pw) / 2
    local px1 = px0 + pw
    local ph = 116 * k
    local py1 = h - h * 0.05
    local py0 = py1 - ph
    shape(rrect(px0, py0, px1, py1, 30 * k), "0E141C", 0.8)

    local dur = ctx.dur or 0
    local r1 = py0 + 32 * k
    local first = S.remaining and (MINUS .. fmt(math.max(0, dur - ctx.pos))) or fmt(ctx.pos)
    local rest = S.remaining and fmt(ctx.pos) or (MINUS .. fmt(math.max(0, dur - ctx.pos)))
    T(px0 + 24 * k, r1, 4, 14 * k, first, "FFFFFF", 1, true)
    T(px1 - 24 * k, r1, 6, 14 * k, rest, "FFFFFF", 0.85, true)
    region(px0 + 20 * k, r1 - 14 * k, px0 + 84 * k, r1 + 14 * k, "time")
    draw_seek(px0 + 24 * k + 66 * k, px1 - 24 * k - 70 * k, r1, k, 4 * k, ctx)

    local r2 = py0 + 84 * k
    local vcx = px0 + 24 * k + 22 * k                  -- mute button centre
    local tools_left = px1 - 24 * k - #tools_items() * 46 * k   -- left edge of the tools cluster
    local lft, rgt = {}, {}
    for _, n in ipairs({ "back", "chprev", "prev" }) do
        if not HIDE[n] and (opts.show_chapter_buttons or n ~= "chprev") then lft[#lft + 1] = n end
    end
    for _, n in ipairs({ "fwd", "chnext", "next" }) do
        if not HIDE[n] and (opts.show_chapter_buttons or n ~= "chnext") then rgt[#rgt + 1] = n end
    end
    local nb = #lft + #rgt + (HIDE.play and 0 or 1)
    local group = (nb * 46 + 18) * k
    local free = (tools_left - 8 * k) - (vcx + 22 * k + 8 * k) - group
    local vol_ok = (not HIDE.volume) and free >= 0     -- no room: the volume button steps aside
    local sw = 0
    if vol_ok and opts.volume_style == "horizontal" and free > 70 * k then sw = math.min(88 * k, free - 14 * k) end
    if vol_ok then volume_ctl(vcx, r2, k, sw) end
    local cstart = vol_ok and (vcx + 22 * k + 8 * k + (sw > 0 and (4 * k + sw + 10 * k) or 0)) or (px0 + 24 * k)
    local mid = (cstart + tools_left - 8 * k) / 2
    local st = skip_state()
    local function put(n, x)
        if n == "back" or n == "fwd" then btn(n, x, r2, k) else skip_btn(n, x, r2, k, st) end
    end
    for i, n in ipairs(lft) do put(n, mid - (56 + (i - 1) * 46) * k) end
    play_btn(mid, r2, k, 52 * k)
    for i, n in ipairs(rgt) do put(n, mid + (56 + (i - 1) * 46) * k) end
    tools_cluster(px1 - 24 * k, r2, k)
    return px1, py0 - 12 * k
end

---------------------------------------------------------------------------
-- render
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- experimental panel blur (GLSL user shader on the OUTPUT stage, regenerated when panels change)
---------------------------------------------------------------------------
local B = { sig = "", path = nil, gen = 0, last = 0, checked = false, ok = true }

local SHADER_HEAD = [==[
//!HOOK OUTPUT
//!BIND HOOKED
//!DESC snad-osc panel blur
#define RADIUS %.1f
#define TAPS %d

float snad_cov(vec2 p, vec4 r, float rad) {
    vec2 c = (r.xy + r.zw) * 0.5;
    vec2 h = (r.zw - r.xy) * 0.5;
    vec2 q = abs(p - c) - h + vec2(rad);
    float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - rad;
    return clamp(0.5 - d, 0.0, 1.0);
}

vec4 hook() {
    vec2 p = HOOKED_pos * HOOKED_size;
    vec4 base = HOOKED_tex(HOOKED_pos);
    float m = 0.0;
]==]
local SHADER_TAIL = [==[
    if (m <= 0.0) return base;
    float sigma = RADIUS * 0.5;
    vec4 acc = base;
    float wsum = 1.0;
    for (int i = 1; i <= TAPS; i++) {
        float fi = float(i);
        float r = sqrt(fi / float(TAPS)) * RADIUS;
        float a = fi * 2.39996323;
        vec2 o = vec2(cos(a), sin(a)) * r;
        float w = exp(-(r * r) / (2.0 * sigma * sigma));
        acc += HOOKED_tex(HOOKED_pos + o * HOOKED_pt) * w;
        wsum += w;
    }
    return mix(base, acc / wsum, m);
}
]==]

local function blur_shader_text(rects, ml, mt)
    local t = { string.format(SHADER_HEAD, clamp(opts.panel_blur_radius, 1, 60),
                              math.floor(clamp(opts.panel_blur_taps, 8, 96))) }
    for _, r in ipairs(rects) do
        t[#t + 1] = string.format("    m = max(m, snad_cov(p, vec4(%.1f, %.1f, %.1f, %.1f), %.1f));\n",
            r[1] - ml, r[2] - mt, r[3] - ml, r[4] - mt, r[5])
    end
    t[#t + 1] = SHADER_TAIL
    return table.concat(t)
end

local function blur_remove()
    if B.path then
        mp.commandv("change-list", "glsl-shaders", "remove", B.path)
        os.remove(B.path)
        B.path = nil
    end
end

-- rects: list of {x0, y0, x1, y1, radius} in OSD pixels. force = skip the 0.35 s rate limit.
local function blur_apply(rects, force)
    if not opts.panel_blur or not B.ok then return end
    B.main = rects
    if IND.rect then
        local m = {}
        for _, r in ipairs(rects) do m[#m + 1] = r end
        m[#m + 1] = IND.rect
        rects = m
        force = true
    end
    if not B.checked then
        B.checked = true
        local vo = get("current-vo") or ""
        if vo ~= "" and not vo:find("gpu") then
            mp.msg.warn("snad-osc: panel_blur needs vo=gpu or gpu-next (current: " .. vo .. ") - disabled")
            B.ok = false
            return
        end
    end
    local ml, mt = S.ml or IND.ml or 0, S.mt or IND.mt or 0
    local sig = ""
    if #rects > 0 then
        local t = {}
        for _, r in ipairs(rects) do
            t[#t + 1] = string.format("%d,%d,%d,%d,%d", math.floor(r[1] + 0.5), math.floor(r[2] + 0.5),
                math.floor(r[3] + 0.5), math.floor(r[4] + 0.5), math.floor(r[5] + 0.5))
        end
        sig = table.concat(t, ";") .. "|" .. math.floor(ml) .. "," .. math.floor(mt)
    end
    if sig == B.sig then return end
    local now = mp.get_time()
    if not force and sig ~= "" and now - B.last < 0.35 then return end   -- retried by the next render
    B.last = now
    blur_remove()
    B.sig = sig
    if sig == "" then return end
    B.gen = B.gen + 1
    local dir = os.getenv("TEMP") or os.getenv("TMP") or os.getenv("TMPDIR") or "/tmp"
    local path = utils.join_path(dir, string.format("snad-osc-blur-%d-%d.glsl", os.time(), B.gen))
    local fh = io.open(path, "w")
    if not fh then
        mp.msg.warn("snad-osc: cannot write " .. path .. " - panel_blur disabled")
        B.ok = false
        return
    end
    fh:write(blur_shader_text(rects, ml, mt))
    fh:close()
    B.path = path
    mp.commandv("change-list", "glsl-shaders", "append", path)
end

IND.refresh = function() blur_apply(B.main or {}, true) end

---------------------------------------------------------------------------
-- right-click context menu (mpv's own menu-data, drawn in the panel theme)
---------------------------------------------------------------------------
local function listof(x)
    if type(x) ~= "table" then return {} end
    if x.items and type(x.items) == "table" then return x.items end
    return x
end

local FALLBACK_MENU = {
    { title = "Pause", cmd = "cycle pause" },
    { title = "Stop", cmd = "stop" },
    { type = "separator" },
    { title = "Playlist", submenu = {
        { title = "Previous", cmd = "playlist-prev" }, { title = "Next", cmd = "playlist-next" },
        { title = "Shuffle", cmd = "playlist-shuffle" } } },
    { title = "Audio", submenu = {
        { title = "Next track", cmd = "cycle audio" }, { title = "Mute", cmd = "cycle mute" } } },
    { title = "Subtitle", submenu = {
        { title = "Next track", cmd = "cycle sub" }, { title = "Toggle visibility", cmd = "cycle sub-visibility" } } },
    { title = "Window", submenu = {
        { title = "Fullscreen", cmd = "cycle fullscreen" }, { title = "Stay on top", cmd = "cycle ontop" },
        { title = "Minimize", cmd = "set window-minimized yes" }, { title = "Maximize", cmd = "cycle window-maximized" } } },
    { title = "Screenshot", cmd = "screenshot" },
    { type = "separator" },
    { title = "Quit", cmd = "quit" },
    { title = "Quit and save position", cmd = "quit-watch-later" },
}

local function has_state(it, name)
    if it[name] == true then return true end
    if type(it.state) == "table" then
        for _, v in pairs(it.state) do if v == name then return true end end
    end
    return false
end

local function key_map()
    local m = {}
    if not opts.ctx_shortcuts then return m end
    local ok, binds = pcall(mp.get_property_native, "input-bindings")
    if not ok or type(binds) ~= "table" then return m end
    for _, b in ipairs(binds) do
        if b.cmd and b.key and not tostring(b.cmd):find("snad") and not tostring(b.cmd):find("^ignore") then
            local l = m[b.cmd]
            if not l then l = {}; m[b.cmd] = l end
            local dup = false
            for _, k0 in ipairs(l) do if k0 == b.key then dup = true end end
            if not dup and #l < opts.ctx_shortcut_keys then l[#l + 1] = b.key end
        end
    end
    return m
end

local function ctx_hidden(title, path)
    local list = parse_list(opts.ctx_hide)
    if #list == 0 then return false end
    local t = title:lower()
    for _, n in ipairs(list) do
        if n == t or n == path then return true end
    end
    return false
end

local function norm_menu(list, keys, path)
    local res = {}
    for _, it in ipairs(listof(list)) do
        if type(it) == "table" and not has_state(it, "hidden") then
            local e = {}
            if it.type == "separator" then
                e.sep = true
            else
                e.title = tostring(it.title or ""):gsub("&&", "\1"):gsub("&", ""):gsub("\1", "&")
                local pth = (path and (path .. "/") or "") .. e.title:lower()
                if ctx_hidden(e.title, pth) then e.hide = true end
                e.cmd = it.cmd
                e.disabled = has_state(it, "disabled")
                e.checked = has_state(it, "checked")
                if it.submenu then e.sub = norm_menu(it.submenu, keys, pth) end
                if e.sub and #e.sub == 0 then e.sub = nil end
                if not e.sub and opts.ctx_history and opts.history and e.title:lower() == "history" then
                    history_load()
                    local sub = {}
                    for i, h in ipairs(H.list) do
                        if i > opts.ctx_history_items then break end
                        sub[#sub + 1] = { title = h.title or h.path, hist = i }
                    end
                    if #sub > 0 then e.sub = sub end
                end
                local sc = opts.ctx_shortcuts and opts.ctx_shortcut_keys > 0 and it.shortcut or nil
                if type(sc) == "string" and opts.ctx_shortcut_keys > 0 then
                    local parts, n = {}, 0
                    for part in sc:gmatch("[^,]+") do
                        n = n + 1
                        if n > opts.ctx_shortcut_keys then break end
                        parts[#parts + 1] = part
                    end
                    sc = table.concat(parts, ",")
                end
                if not sc and opts.ctx_shortcuts and e.cmd and keys[e.cmd] then sc = table.concat(keys[e.cmd], ",") end
                e.shortcut = sc
            end
            if not e.hide then res[#res + 1] = e end
        end
    end
    -- tidy separators left behind by hidden entries
    local tidy, last_sep = {}, true
    for _, e in ipairs(res) do
        if e.sep then
            if not last_sep then tidy[#tidy + 1] = e; last_sep = true end
        else
            tidy[#tidy + 1] = e; last_sep = false
        end
    end
    if #tidy > 0 and tidy[#tidy].sep then tidy[#tidy] = nil end
    return tidy
end

local function ctx_close()
    if S.ctx then
        S.ctx = nil
        mp.remove_key_binding("snad_ctx_esc")
    end
end

local function ctx_open()
    S.menu, S.volpop = nil, false
    local md = mp.get_property_native("menu-data")
    local keys = key_map()
    local items = norm_menu(md, keys)
    if #items == 0 then items = norm_menu(FALLBACK_MENU, keys) end
    S.ctx = { stack = { { items = items, ax = S.mx, ay = S.my } } }
    mp.add_forced_key_binding("ESC", "snad_ctx_esc", ctx_close)
end

-- lays out and draws the open menu cascade; also stores geometry for hover hit-testing
local function draw_ctx(ctx)
    local c = S.ctx
    if not c then return end
    local k = ctx.k * opts.panel_scale
    local fs = opts.ctx_font_size * ctx.k
    local rowh, sepc = opts.ctx_row_height * k, 10 * k
    local pad = 6 * k
    -- menu text is narrower than the generic estimate (0.54 em/char); use a tighter one here
    local CF = 0.47
    local function mw(str, size) return ulen(str) * size * CF end
    region(0, 0, ctx.w, ctx.h, "ctxbg", true)
    for lvl, pnl in ipairs(c.stack) do
        local wmax = opts.ctx_min_width * k
        for _, it in ipairs(pnl.items) do
            if not it.sep then
                local w = 22 * k + mw(it.title, fs) + 30 * k + 14 * k
                if it.shortcut and it.shortcut ~= "" then w = w + 26 * k + mw(it.shortcut, fs * 0.9) end
                if w > wmax then wmax = w end
            end
        end
        wmax = math.min(wmax, opts.ctx_max_width * k, ctx.w * 0.6)
        local H = 2 * pad
        for _, it in ipairs(pnl.items) do H = H + (it.sep and sepc or rowh) end
        local x, y
        if lvl == 1 then
            x, y = pnl.ax, pnl.ay
        else
            local par = c.stack[lvl - 1]
            local pg = par.g
            x = pg.x1 - 4 * k
            y = pg.rows[par.sel].y0 - pad
            if x + wmax > ctx.w - 6 * k then x = pg.x0 - wmax + 4 * k end
        end
        x = clamp(x, 6 * k, math.max(6 * k, ctx.w - wmax - 6 * k))
        y = clamp(y, 6 * k, math.max(6 * k, ctx.h - H - 6 * k))
        local g = { x0 = x, y0 = y, x1 = x + wmax, y1 = y + H, rows = {} }
        pnl.g = g
        shape(rrect(g.x0, g.y0, g.x1, g.y1, 14 * k), panel_bg())
        add_blur_rect(g.x0, g.y0, g.x1, g.y1, 14 * k)
        region(g.x0, g.y0, g.x1, g.y1, "panel", true)
        local ry = g.y0 + pad
        for i, it in ipairs(pnl.items) do
            if it.sep then
                shape(rectp(g.x0 + 12 * k, ry + sepc / 2 - 0.5 * k, g.x1 - 12 * k, ry + sepc / 2 + 0.5 * k), "FFFFFF", 0.18)
                g.rows[i] = { y0 = ry, y1 = ry + sepc }
                ry = ry + sepc
            else
                local r = { y0 = ry, y1 = ry + rowh }
                g.rows[i] = r
                local cy = ry + rowh / 2
                local dim = it.disabled and 0.35 or 1
                if pnl.sel == i and not it.disabled then
                    shape(rrect(g.x0 + 4 * k, ry + 1 * k, g.x1 - 4 * k, ry + rowh - 1 * k, 9 * k), "FFFFFF", 0.16)
                end
                if it.checked then ICON.check(g.x0 + 17 * k, cy, k * 0.75, opts.accent) end
                local scw = (it.shortcut and it.shortcut ~= "") and (mw(it.shortcut, fs * 0.9) + 26 * k) or 0
                local avail = (g.x1 - g.x0) - 32 * k - 14 * k - 14 * k - (it.sub and 18 * k or 0) - scw
                T(g.x0 + 32 * k, cy, 4, fs, fit(it.title, fs, avail * 0.54 / CF), "FFFFFF", dim, false, nil, true)
                local rx = g.x1 - 14 * k
                if it.sub then
                    shape(linep(rx - 8 * k, cy - 4.5 * k, rx - 3.5 * k, cy, 1.6 * k), "FFFFFF", 0.7 * dim)
                    shape(linep(rx - 3.5 * k, cy, rx - 8 * k, cy + 4.5 * k, 1.6 * k), "FFFFFF", 0.7 * dim)
                    rx = rx - 18 * k
                end
                if it.shortcut and it.shortcut ~= "" then
                    T(rx, cy, 6, fs * 0.9, it.shortcut, "FFFFFF", 0.55 * dim, false, nil, true)
                end
                if not it.disabled then region(g.x0, ry, g.x1, ry + rowh, "ctx:" .. lvl .. ":" .. i, true) end
                ry = ry + rowh
            end
        end
    end
end

-- hover: highlights the row under the mouse and opens / closes cascades
local function ctx_hover()
    local c = S.ctx
    if not c or not S.hover then return end
    for lvl = #c.stack, 1, -1 do
        local pnl = c.stack[lvl]
        local g = pnl.g
        if g and S.mx >= g.x0 and S.mx <= g.x1 and S.my >= g.y0 and S.my <= g.y1 then
            for i, r in ipairs(g.rows) do
                if S.my >= r.y0 and S.my < r.y1 then
                    local it = pnl.items[i]
                    if it and not it.sep then
                        if pnl.sel ~= i or #c.stack > lvl + ((it.sub and not it.disabled) and 1 or 0) then
                            for j = #c.stack, lvl + 1, -1 do c.stack[j] = nil end
                            pnl.sel = i
                            if it.sub and not it.disabled then c.stack[lvl + 1] = { items = it.sub } end
                        end
                    end
                    return
                end
            end
            return
        end
    end
end

local function ctx_activate(arg)
    local c = S.ctx
    local lvl, idx = arg:match("^(%d+):(%d+)$")
    lvl, idx = tonumber(lvl), tonumber(idx)
    if not c or not lvl or not c.stack[lvl] then return end
    local it = c.stack[lvl].items[idx]
    if not it or it.disabled or it.sep then return end
    if it.sub then
        for j = #c.stack, lvl + 1, -1 do c.stack[j] = nil end
        c.stack[lvl].sel = idx
        c.stack[lvl + 1] = { items = it.sub }
    elseif it.hist then
        ctx_close()
        history_play(it.hist)
    elseif it.cmd and it.cmd ~= "" then
        local cmd = it.cmd
        ctx_close()
        mp.command(cmd)
    end
end

local function render()
    local d = mp.get_property_native("osd-dimensions")
    if not d or not d.w or d.w <= 0 or d.h <= 0 then return end
    local w, h = d.w, d.h
    ov.res_x, ov.res_y = w, h
    S.last_render = mp.get_time()
    S.paused = mp.get_property_bool("pause") and true or false

    local ctx = {
        w = w, h = h, k = h / 562 * opts.scale,
        dur = mp.get_property_number("duration"),
        pos = mp.get_property_number("time-pos") or 0,
    }
    regions, out = {}, {}
    S.drawer_rect = nil
    panel_rects = {}
    S.ml, S.mt = d.ml or 0, d.mt or 0

    local mright, mbottom
    if S.audio then mright, mbottom = layout_audio(ctx)
    elseif S.layout == "pill" then mright, mbottom = layout_pill(ctx)
    elseif S.layout == "center" then mright, mbottom = layout_center(ctx)
    else mright, mbottom = layout_streamer(ctx) end

    if S.drawer then draw_drawer(ctx) end
    if S.menu then draw_menu(ctx, mright, mbottom) end
    if S.card then draw_card(ctx, mright, mbottom) end
    if S.ctx then draw_ctx(ctx) end
    if opts.panel_blur then blur_apply(panel_rects) end

    ov.data = table.concat(out, "\n")
    ov:update()
end

---------------------------------------------------------------------------
-- visibility / input
---------------------------------------------------------------------------
-- keep subtitles clear of the controls: raise sub-pos while visible, restore when hidden
local function lift_subs(on)
    if opts.sub_lift <= 0 then return end
    if on and S.sub_orig == nil then
        local cur = mp.get_property_number("sub-pos")
        if not cur then return end
        S.sub_orig = cur
        mp.set_property_number("sub-pos", math.max(0, cur - opts.sub_lift))
    elseif not on and S.sub_orig ~= nil then
        mp.set_property_number("sub-pos", S.sub_orig)
        S.sub_orig = nil
    end
end

local function draw_pinned_clock()
    local d = mp.get_property_native("osd-dimensions")
    if not d or not d.w or d.w <= 0 or d.h <= 0 then return end
    ov.res_x, ov.res_y = d.w, d.h
    local k = d.h / 562 * opts.scale
    out = {}
    local xr, cy = d.w - d.w * 0.04, 40 * k
    if S.clock_pinned and opts.show_clock then
        local cs, es = clock_strings()
        T(xr, cy - 9 * k, 6, 22 * k, cs, "FFFFFF", 1, true)
        if es then T(xr, cy + 15 * k, 6, 14 * k, es, "FFFFFF", 0.88) end
    end
    if S.title_pinned then
        local mx = d.w * 0.04
        T(mx, cy, 4, 15 * k, fit(crumb_text(), 15 * k, d.w * 0.45), "FFFFFF", 0.88)
    end
    ov.data = table.concat(out, "\n")
    ov:update()
    S.pin_sec = os.time()
end

local function clear_overlay()
    S.visible = false
    ctx_close()
    lift_subs(false)
    thumb_clear()
    if opts.panel_blur then blur_apply({}, true) end
    ov:remove()
end

local function hide()
    clear_overlay()
    if (S.clock_pinned and opts.show_clock) or S.title_pinned then draw_pinned_clock() end
end

local function show()
    if S.idle then return end
    S.visible = true
    lift_subs(true)
    S.last_move = mp.get_time()
    if mp.get_time() - S.last_render > 0.03 then render() end
end

local function seek_to_mouse(exact)
    local dur = mp.get_property_number("duration")
    if not dur or #S.segx == 0 then return end
    local t = x2t(S.segx, S.mx, dur)
    mp.commandv("no-osd", "seek", string.format("%.3f", clamp(t, 0, dur)),
        exact and "absolute+exact" or "absolute+keyframes")
end

local function set_volume_from_mouse()
    local vmax = mp.get_property_number("volume-max") or 100
    local fr
    if S.vol.vertical then fr = clamp((S.vol.y1 - S.my) / (S.vol.y1 - S.vol.y0), 0, 1)
    else fr = clamp((S.mx - S.vol.x0) / (S.vol.x1 - S.vol.x0), 0, 1) end
    mp.set_property_number("volume", math.floor(fr * vmax + 0.5))
    mp.set_property("mute", "no")
end

local function set_wheel(on)
    if on then
        mp.add_forced_key_binding("WHEEL_UP", "snad_wheel_up", function()
            local r = S.drawer_rect
            if r and S.hover and S.mx >= r[1] and S.mx <= r[3] and S.my >= r[2] and S.my <= r[4] then
                S.scroll = S.scroll - 1; render()
            else mp.commandv("no-osd", "add", "volume", "2") end
        end)
        mp.add_forced_key_binding("WHEEL_DOWN", "snad_wheel_down", function()
            local r = S.drawer_rect
            if r and S.hover and S.mx >= r[1] and S.mx <= r[3] and S.my >= r[2] and S.my <= r[4] then
                S.scroll = S.scroll + 1; render()
            else mp.commandv("no-osd", "add", "volume", "-2") end
        end)
    else
        mp.remove_key_binding("snad_wheel_up")
        mp.remove_key_binding("snad_wheel_down")
    end
end

-- opening a panel closes the others (exclusive_panels)
local function close_others(keep)
    if not opts.exclusive_panels then return end
    if keep ~= "menu" then S.menu = nil end
    if keep ~= "card" then S.card = nil end
    if keep ~= "volpop" then S.volpop = false end
    if keep ~= "drawer" and S.drawer then S.drawer = nil; set_wheel(false) end
    if keep ~= "ctx" then ctx_close() end
end

local function toggle_menu()
    local on = not S.menu
    if on then close_others("menu") end
    S.menu = on and "tracks" or nil
    S.volpop = false
    show(); render()
end
local function toggle_drawer()
    S.volpop = false
    if S.drawer then S.drawer = nil; set_wheel(false)
    else
        close_others("drawer")
        S.drawer = (#chapters > 0) and "chapters" or "playlist"
        S.scroll = 0; set_wheel(true)
    end
    show(); render()
end

local function toggle_info()
    if S.card then
        S.card = nil
    else
        close_others("card")
        S.card = true
    end
    S.volpop = false
    show(); render()
end

local function prev_next(dir)
    local pc = mp.get_property_number("playlist-count") or 0
    if pc > 1 then mp.commandv(dir > 0 and "playlist-next" or "playlist-prev")
    elseif not opts.show_chapter_buttons then mp.commandv("no-osd", "add", "chapter", tostring(dir)) end
end

local function load_subtitle()
    if mp.get_property("platform") ~= "windows" then
        mp.osd_message("Drop a subtitle file onto the window to load it", 3)
        return
    end
    local ps = "Add-Type -AssemblyName System.Windows.Forms; " ..
        "$f=New-Object System.Windows.Forms.OpenFileDialog; " ..
        "$f.Filter='Subtitles|*.srt;*.ass;*.ssa;*.vtt;*.sub;*.sup|All files|*.*'; " ..
        "if($f.ShowDialog() -eq 'OK'){[Console]::Out.Write($f.FileName)}"
    mp.command_native_async({
        name = "subprocess", args = { "powershell", "-NoProfile", "-STA", "-Command", ps },
        capture_stdout = true, playback_only = false,
    }, function(ok, res)
        if ok and res and res.status == 0 and res.stdout and res.stdout ~= "" then
            mp.commandv("sub-add", res.stdout, "select")
            mp.osd_message("Subtitle loaded")
        end
    end)
end

local function bump(prop, step)
    local cur = mp.get_property_number(prop) or 0
    mp.set_property_number(prop, math.floor((cur + step) * 1000 + 0.5) / 1000)
end

-- audio-only switch: show the audio skin for a video file too (the picture is turned off, the window is not resized)
local function toggle_audio_only()
    if not S.rv and not S.aonly then   -- an audio file: switch the audio skin on / off
        local off = S.skin_off
        if off == nil then off = not opts.audio_default end
        S.skin_off = not off
        S.vkey = nil
        audio_sync()
        return
    end
    if S.aonly then
        S.aonly = false
        if S.vid_off then mp.set_property("vid", "auto"); S.vid_off = nil end
    else
        S.aonly = true
        if S.rv then mp.set_property("vid", "no"); S.vid_off = true end
    end
    S.vkey = nil
    audio_sync()
end

local ACTIONS = {
    audioonly = toggle_audio_only,
    play = function() mp.commandv("no-osd", "cycle", "pause") end,
    chprev = function() mp.commandv("no-osd", "add", "chapter", "-1") end,
    chnext = function() mp.commandv("no-osd", "add", "chapter", "1") end,
    prev = function() prev_next(-1) end,
    next = function() prev_next(1) end,
    back = function() mp.commandv("no-osd", "seek", tostring(-opts.skip_seconds)) end,
    fwd = function() mp.commandv("no-osd", "seek", tostring(opts.skip_seconds)) end,
    mute = function() mp.commandv("no-osd", "cycle", "mute") end,
    volbtn = function()
        local on = not S.volpop
        if on then close_others("volpop") end
        S.volpop = on
        S.menu = nil
    end,
    tracks = toggle_menu,
    info = toggle_info,
    aprev = function()
        if (mp.get_property_number("playlist-count") or 0) > 1 then mp.commandv("playlist-prev")
        else mp.commandv("no-osd", "add", "chapter", "-1") end
    end,
    anext = function()
        if (mp.get_property_number("playlist-count") or 0) > 1 then mp.commandv("playlist-next")
        else mp.commandv("no-osd", "add", "chapter", "1") end
    end,
    shuffle = function()
        if S.shuffled then mp.commandv("playlist-unshuffle") else mp.commandv("playlist-shuffle") end
        S.shuffled = not S.shuffled
    end,
    loop = function()
        if not opts.loop_playlist then mp.commandv("osd-auto", "cycle-values", "loop-file", "inf", "no"); return end
        local m = loop_mode()
        if m == nil then
            mp.set_property("loop-file", "inf"); mp.set_property("loop-playlist", "no")
        elseif m == "file" then
            mp.set_property("loop-file", "no"); mp.set_property("loop-playlist", "inf")
        else
            mp.set_property("loop-playlist", "no"); mp.set_property("loop-file", "no")
        end
    end,
    playlist = toggle_drawer,
    fullscreen = function() mp.commandv("cycle", "fullscreen") end,
    time = function() S.remaining = not S.remaining end,
    clockpin = function() S.clock_pinned = not S.clock_pinned end,
    titlepin = function() S.title_pinned = not S.title_pinned end,
    pin = function() mp.commandv("cycle", "ontop") end,
    min = function() mp.set_property("window-minimized", "yes") end,
    max = function() mp.commandv("cycle", "window-maximized") end,
    close = function() mp.commandv("quit") end,
    loadsub = load_subtitle,
    ctxbg = function() ctx_close() end,
}

local function act(name)
    if ACTIONS[name] then ACTIONS[name](); return end
    local kind, arg = name:match("^(%a+):(.+)$")
    if kind == "aud" then mp.set_property("aid", arg)
    elseif kind == "sub" then mp.set_property("sid", arg == "0" and "no" or arg)
    elseif kind == "spd" then mp.set_property_number("speed", tonumber(arg))
    elseif kind == "dly" then
        local prop = arg:sub(1, 1) == "a" and "audio-delay" or "sub-delay"
        bump(prop, arg:sub(2, 2) == "+" and 0.05 or -0.05)
    elseif kind == "ch" then mp.set_property_number("chapter", tonumber(arg))
    elseif kind == "pl" then mp.commandv("playlist-play-index", arg)
    elseif kind == "hi" then history_play(tonumber(arg))
    elseif kind == "tab" then S.drawer = arg; S.scroll = 0; if arg == "history" then H.reload = true end
    elseif kind == "ctx" then ctx_activate(arg)
    end
end

mp.observe_property("mouse-pos", "native", function(_, p)
    if not p then return end
    local moved = (p.x ~= S.mx or p.y ~= S.my)
    S.mx, S.my, S.hover = p.x, p.y, p.hover
    if S.drag == "seek" then seek_to_mouse(false)
    elseif S.drag == "vol" then set_volume_from_mouse() end
    if moved and p.hover then show() end
    if S.ctx and moved then ctx_hover(); render() end
end)

mp.add_forced_key_binding("MBTN_LEFT", "snad_click", function(e)
    if e.event == "down" then
        local r = S.visible and hit(S.mx, S.my) or nil
        if r == "seek" then S.drag = "seek"; seek_to_mouse(false)
        elseif r == "vol" then S.drag = "vol"; set_volume_from_mouse()
        else S.pending = r or "_blank" end
    elseif e.event == "up" then
        if S.drag == "seek" then S.drag = nil; seek_to_mouse(true)
        elseif S.drag == "vol" then S.drag = nil
        elseif S.pending then
            local r = S.visible and hit(S.mx, S.my) or "_blank"
            if r == S.pending then
                if r == "_blank" then
                    if S.menu or S.drawer or S.volpop or S.card then
                        S.menu = nil
                        S.card = nil
                        S.volpop = false
                        if S.drawer then S.drawer = nil; set_wheel(false) end
                    elseif opts.click_to_pause then
                        mp.commandv("no-osd", "cycle", "pause")
                    end
                elseif r ~= "panel" then
                    if r ~= "volbtn" and r ~= "mute" then S.volpop = false end
                    act(r)
                end
            end
            S.pending = nil
        end
    end
    show(); render()
end, { complex = true })

if opts.context_menu then
    mp.add_forced_key_binding("MBTN_RIGHT", "snad_rclick", function()
        if S.ctx then ctx_close() else close_others("ctx"); ctx_open() end
        show(); render()
    end)
end

mp.add_forced_key_binding("MBTN_LEFT_DBL", "snad_dblclick", function()
    if S.visible and hit(S.mx, S.my) then return end
    mp.commandv("cycle", "fullscreen")
end)

mp.add_key_binding(nil, "toggle-title", function() S.title_pinned = not S.title_pinned; if not S.visible then hide() end end)
mp.add_key_binding(nil, "toggle-clock", function() S.clock_pinned = not S.clock_pinned; if not S.visible then hide() end end)
mp.add_key_binding(nil, "toggle-audio-only", toggle_audio_only)
mp.add_key_binding(nil, "toggle-menu", toggle_menu)
mp.add_key_binding(nil, "toggle-drawer", toggle_drawer)
mp.add_key_binding(nil, "toggle-info", toggle_info)

mp.register_script_message("thumbfast-info", function(json)
    local d = utils.parse_json(json)
    if type(d) == "table" then
        thumb.width, thumb.height = d.width or 0, d.height or 0
        thumb.disabled, thumb.available = d.disabled and true or false, d.available and true or false
    end
end)

mp.observe_property("pause", "bool", function() show() end)
mp.observe_property("track-list", "native", function() refresh_info() end)
mp.observe_property("video-params", "native", function() refresh_info() end)
mp.observe_property("media-title", "string", function() refresh_info() end)
mp.observe_property("chapter-list", "native", function() refresh_chapters() end)

local VERSION = "v2.57"
local layout_known = false
for _, v in ipairs(LAYOUTS) do if v == opts.layout then layout_known = true end end
mp.msg.info("snad-osc " .. VERSION .. "  layout=" .. S.layout ..
    (layout_known and "" or ("  (unknown layout '" .. tostring(opts.layout) .. "' in snad_osc.conf)")))
local announced = false

mp.register_event("file-loaded", function()
    if not announced then
        announced = true
        if not layout_known then
            mp.osd_message("snad-osc " .. VERSION .. ": unknown layout '" .. tostring(opts.layout) ..
                "' (use streamer | pill | center | default) - using streamer", 6)
        elseif opts.show_layout_hint then
            mp.osd_message("snad-osc " .. VERSION .. "  layout: " .. S.layout, 2)
        end
    end
    refresh_chapters()
    refresh_info()
    history_touch()
    history_save()
    show()
end)
mp.register_event("end-file", clear_overlay)
mp.register_event("end-file", function() history_pos(); history_save() end)
mp.register_event("shutdown", function() history_pos(); history_save() end)
mp.add_periodic_timer(15, function() history_pos(); history_save() end)

-- Stock OSC and its "Drop files or URLs" logo. The stock OSC only wipes the logo from its tick(), and
-- tick() does nothing once visibility is "never" -- so if "never" arrives while the logo is still on
-- screen (drag-and-drop onto an idle player), the logo stays forever. Release it in two steps:
-- turn the idle screen off and let the OSC tick once (visibility "auto" wipes it), then set "never".
local osc_release_timer
local function stock_osc_release()
    if mp.get_property_bool("idle-active") then return end
    if opts.idle_logo then S.idle = false end
    mp.commandv("script-message", "osc-idlescreen", "no", "no-osd")
    mp.commandv("script-message", "osc-visibility", "auto", "no-osd")
    if osc_release_timer then osc_release_timer:kill() end
    osc_release_timer = mp.add_timeout(0.25, function()
        if mp.get_property_bool("idle-active") then return end
        mp.commandv("script-message", "osc-visibility", "never", "no-osd")
    end)
end

mp.observe_property("idle-active", "bool", function(_, idle)
    if idle then
        if opts.idle_logo then
            S.idle = true
            clear_overlay()
            mp.commandv("script-message", "osc-idlescreen", "yes", "no-osd")
            mp.commandv("script-message", "osc-visibility", "auto", "no-osd")
        else
            mp.commandv("script-message", "osc-idlescreen", "no", "no-osd")
        end
    else
        stock_osc_release()
    end
end)
mp.register_event("file-loaded", stock_osc_release)

mp.add_periodic_timer(0.1, function()
    if not S.visible then
        if ((S.clock_pinned and opts.show_clock) or S.title_pinned) and S.pin_sec ~= os.time() then draw_pinned_clock() end
        return
    end
    local over = S.hover and hit(S.mx, S.my)
    if not S.paused and not S.drag and not S.menu and not S.drawer and not S.volpop and not S.card and not S.ctx and not S.audio and not over
       and mp.get_time() - S.last_move > opts.hide_timeout then
        hide()
    else
        render()
    end
end)

if opts.seek_wave then
    mp.add_periodic_timer(1 / clamp(opts.wave_fps, 5, 60), function()
        if S.visible and not S.paused and mp.get_time() - S.last_render > 0.6 / clamp(opts.wave_fps, 5, 60) then
            render()
        end
    end)
end

---------------------------------------------------------------------------
-- window frame: frameless window (border=no), OS-style rounded corners, border line
---------------------------------------------------------------------------
if not opts.native_border then mp.set_property("border", "no") end

local CORNER_MODE = tostring(opts.window_corners):lower():match("^%s*(%a+)") or "default"

-- radius the OS uses for that corner style (so the border line follows the real window shape)
local function corner_radius()
    local sc = mp.get_property_number("display-hidpi-scale") or 1
    if CORNER_MODE == "round" then return 8 * sc elseif CORNER_MODE == "small" then return 4 * sc end
    return 0
end

-- Windows 11: ask DWM for real rounded corners (DWMWA_WINDOW_CORNER_PREFERENCE) on the player window
local corners_done = false
local function apply_corners()
    local pref = ({ none = 1, round = 2, small = 3 })[CORNER_MODE]
    if corners_done or not pref or mp.get_property("platform") ~= "windows" then return end
    local id = tostring(get("window-id") or "")
    if not id:match("^%d+$") then return end
    corners_done = true
    local ps = '$s=\'[DllImport("dwmapi.dll")] public static extern int DwmSetWindowAttribute(IntPtr h,int a,ref int v,int s);\'; ' ..
        'Add-Type -MemberDefinition $s -Name W -Namespace SnadOsc; $v=' .. pref ..
        '; [void][SnadOsc.W]::DwmSetWindowAttribute([IntPtr][int64]' .. id .. ',33,[ref]$v,4)'
    mp.command_native_async({
        name = "subprocess", args = { "powershell", "-NoProfile", "-Command", ps }, playback_only = false,
    }, function() end)
end
mp.register_event("file-loaded", apply_corners)
mp.register_event("file-loaded", function()
    if not S.aonly then return end
    mp.set_property("vid", "auto"); S.vid_off = nil
    mp.add_timeout(0.2, function()
        if S.aonly and S.rv then mp.set_property("vid", "no"); S.vid_off = true end
    end)
end)

-- audio files: the cover art would make the window square; crop it to 16:9 (Windows, once per file)
audio_fit = function()
    if mp.get_property("platform") ~= "windows" or not opts.audio_fit_window then return end
    if get("fullscreen") == "yes" or get("window-maximized") == "yes" then return end
    mp.add_timeout(0.25, function()
        if not S.audio then return end
        local d = mp.get_property_native("osd-dimensions")
        if type(d) ~= "table" or not d.w or d.w <= 0 or d.h <= d.w * 9 / 16 + 4 then return end
        local id = tostring(get("window-id") or "")
        if not id:match("^%d+$") then return end
        local ps = '$s=\'[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h,int[] r); ' ..
            '[DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h,int[] r); ' ..
            '[DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h,IntPtr a,int x,int y,int cx,int cy,uint f);\'; ' ..
            'Add-Type -MemberDefinition $s -Name W -Namespace SnadFit; $h=[IntPtr][int64]' .. id .. '; ' ..
            '$w=New-Object int[] 4; $c=New-Object int[] 4; [void][SnadFit.W]::GetWindowRect($h,$w); [void][SnadFit.W]::GetClientRect($h,$c); ' ..
            '$cw=$c[2]-$c[0]; $ch=$c[3]-$c[1]; $want=[int]($cw*9/16); ' ..
            'if($ch -gt $want+4){[void][SnadFit.W]::SetWindowPos($h,[IntPtr]::Zero,0,0,($w[2]-$w[0]),($w[3]-$w[1])-($ch-$want),0x16)}'
        mp.command_native_async({
            name = "subprocess", args = { "powershell", "-NoProfile", "-Command", ps }, playback_only = false,
        }, function() end)
    end)
end

local frame_ov = mp.create_osd_overlay("ass-events")
frame_ov.z = 90
local function draw_frame()
    local bw = opts.win_border
    local d = mp.get_property_native("osd-dimensions")
    if bw <= 0 or type(d) ~= "table" or not d.w or d.w <= 0 or d.h <= 0
       or get("fullscreen") == "yes" or get("window-maximized") == "yes" then
        frame_ov:remove()
        return
    end
    local w, h = d.w, d.h
    frame_ov.res_x, frame_ov.res_y = w, h
    frame_ov.data = string.format("{\\an7\\pos(0,0)\\p1\\bord0\\shad0\\1c&H%s&\\1a&H%s&}%s{\\p0}",
        bgr(opts.win_border_color), A(opts.win_border_opacity), ring(0, 0, w, h, corner_radius(), bw))
    frame_ov:update()
end
mp.observe_property("osd-dimensions", "native", draw_frame)
mp.observe_property("fullscreen", "bool", draw_frame)
mp.observe_property("window-maximized", "bool", draw_frame)
refresh_chapters()
refresh_info()
