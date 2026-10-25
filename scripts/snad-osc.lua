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
    sub_lift = 22,              -- move subtitles up by this % of the window height while the controls are visible (0 = off)
    show_playlist_pos = true,   -- [02/10] next to the title when the playlist has more than one item
    context_menu = true,        -- right-click opens a themed copy of mpv's context menu (no = keep the native one)
    ctx_font_size = 13,         -- context menu text size (before the global scale)
    ctx_row_height = 30,        -- context menu row height
    ctx_shortcuts = true,
    ctx_shortcut_keys = 2,      -- max key bindings shown per entry (0 = same as ctx_shortcuts=no)
    ctx_min_width = 150,        -- narrowest menu panel
    ctx_max_width = 280,        -- widest menu panel (longer titles are cut with ...)       -- show key bindings on the right
    idle_logo = true,           -- empty player (nothing loaded): hand over to mpv's own OSC so its logo shows (needs osc=yes in mpv.conf)
    seek_wave = false,          -- Android-style animated wavy seek bar (played part waves, knob glows)
    wave_colors = "3B9DFF,9B5CF6,FF3B5C", -- gradient along the played part: comma-separated RRGGBB list
    wave_style = "fill",        -- fill = layered translucent humps over a white line (Android music-player look) | line = single wavy line
    wave_opacity = 0.65,        -- opacity of the humps (fill style)
    wave_baseline = "FFFFFF",   -- colour of the straight line under the humps (fill style); empty = follow the gradient
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
    show_clock = true,
    active_style = "border",    -- how a toggled-on button looks (tracks / loop / playlist / fullscreen / volume): border | fill | both | none
    active_fill = "darkglass",  -- fill look for active_style=fill|both: dark | glass | darkglass
    active_fill_color = "",     -- fill colour (RRGGBB); empty = taken from active_fill
    active_fill_opacity = -1,   -- fill opacity 0..1; -1 = taken from active_fill
    highlight_active = true,    -- accent-colour the tracks / loop icons when subtitles, non-1x speed or loop are active (open panels always get a ring)
    title_pinned = false,       -- keep the top-left title / path (with [02/10]) visible when the controls are hidden (click it to toggle)
    clock_pinned = false,       -- keep the clock + "Ends at" on screen when the controls are hidden (click the clock to toggle)
    show_window_controls = true,
    thumbfast = true,           -- use the thumbfast script for hover thumbnails if present
    volume_style = "vertical",  -- vertical = click the speaker to open a vertical slider popup | horizontal = inline slider
    winctl_color = "FFFFFF",    -- background of the pin / minimize / maximize / close group (RRGGBB)
    winctl_opacity = 0.22,      -- 0 = no background, 1 = solid
    show_layout_hint = false,   -- show "snad-osc vX  layout: name" on screen when a file starts (for troubleshooting)
    click_to_pause = false,    -- click on the video (not on a control) toggles pause

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
    if math.abs(f - math.floor(f + 0.5)) < 0.02 then return string.format("%d fps", math.floor(f + 0.5)) end
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
    local looping = get("loop-file") == "inf" or get("loop-file") == "yes"
    if sub then bx = bx + chip(bx, y, k, sub, o) + gap end
    if opts.pill_show_speed and math.abs(spd - 1) > 0.001 then
        bx = bx + chip(bx, y, k, string.format("%g", spd) .. "\195\151", o) + gap
    end
    if opts.pill_show_loop and looping then bx = bx + chip(bx, y, k, "Loop", o) + gap end
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
    local items = { "pin", "min", "max", "close" }
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
    ICON.pin(xr + 13 * k, cy, k * 0.5, S.clock_pinned and opts.accent or "9AA3AF")
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
    ICON.pin(mx - 11 * k, cy, k * 0.5, S.title_pinned and opts.accent or "9AA3AF")
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

local wave_cache = { src = nil, list = {} }
local function wave_color(u)
    if wave_cache.src ~= opts.wave_colors then
        wave_cache.src = opts.wave_colors
        wave_cache.list = {}
        for tok in tostring(opts.wave_colors):gmatch("[^,%s]+") do
            wave_cache.list[#wave_cache.list + 1] = { hex_rgb(tok) }
        end
        if #wave_cache.list == 0 then wave_cache.list[1] = { hex_rgb(opts.accent) } end
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
        local cols = {}
        for tok in tostring(opts.wave_colors):gmatch("[^,%s]+") do cols[#cols + 1] = tok end
        if #cols == 0 then cols[1] = opts.accent end
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
        local bl = opts.wave_baseline ~= "" and opts.wave_baseline or nil
        shape(rrect(x0, y - th / 2, hx, y + th / 2, th / 2), bl or wave_color(0.5), 1)
        return wave_color(1), y
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
    local vol = mp.get_property_number("volume") or 100
    local vmax = mp.get_property_number("volume-max") or 100
    local fr = clamp(vol / vmax, 0, 1)

    if opts.volume_style ~= "horizontal" then
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
    local r = D / 2
    local hov = inside(cx - r, cy - r, cx + r, cy + r)
    shape(rrect(cx - r, cy - r, cx + r, cy + r, r), "FFFFFF", hov and 1 or 0.96)
    if S.paused then ICON.play(cx, cy, k, "111111") else ICON.pause(cx, cy, k, "111111") end
    region(cx - r, cy - r, cx + r, cy + r, "play")
end

local function time_label(xr, cy, k, fs)
    local dur = mp.get_property_number("duration") or 0
    local pos = mp.get_property_number("time-pos") or 0
    local first = S.remaining and (MINUS .. fmt(math.max(0, dur - pos))) or fmt(pos)
    local total = " / " .. fmt(dur)
    out[#out + 1] = string.format(
        "{\\an6\\pos(%s,%s)\\fn%s\\fs%s\\b1\\bord0\\shad%s\\1c&H%s&\\1a&H%s&\\4c&H000000&\\4a&H70&}%s{\\b0\\1a&H%s&}%s",
        f(xr), f(cy), opts.font, f(fs), f(math.max(1, fs / 14)), bgr("FFFFFF"), A(1),
        esc(first), A(0.7), esc(total))
    local wd = textw(first, fs, true) + textw(total, fs, false)
    region(xr - wd - 4 * k, cy - 14 * k, xr + 2 * k, cy + 14 * k, "time")
    return xr - wd
end

-- right cluster: tracks & playback menu, loop, playlist, fullscreen. returns left edge
local function tools_cluster(xr, cy, k)
    local items = { "tracks", "loop", "playlist", "fullscreen" }
    local step = 46 * k
    local spd = mp.get_property_number("speed") or 1
    local sid = get("sid")
    local sub_on = sid and sid ~= "no" and sid ~= "false"
    local looping = get("loop-file") == "inf" or get("loop-file") == "yes"
    local hint = opts.highlight_active and opts.accent or "FFFFFF"
    local border = active_look()
    local on_icon = border and opts.accent or "FFFFFF"
    local fullscreen = get("fullscreen") == "yes"
    for i, name in ipairs(items) do
        local cx = xr - 22 * k - (#items - i) * step
        local o = {}
        if name == "tracks" then
            o.active = S.menu
            o.color = S.menu and on_icon or ((sub_on or math.abs(spd - 1) > 0.001) and hint or "FFFFFF")
        elseif name == "loop" then
            o.active = looping
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
    local y0 = h * 0.12
    local Hd = h * 0.46 * opts.panel_scale
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
    for i, t in ipairs(tabs) do
        local tx0 = x0 + P + 3 * k + (i - 1) * tw
        local sel = S.drawer == t[1]
        if sel then shape(rrect(tx0, tab_y + 3 * k, tx0 + tw, tab_y + 3 * k + tab_h, tab_h / 2), "FFFFFF", 1) end
        PT(tx0 + tw / 2, tab_y + 3 * k + tab_h / 2, 5, 14 * fk, t[2], sel and "111111" or "DDDDDD", 1, true)
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

local function layout_streamer(ctx)
    local w, h, k = ctx.w, ctx.h, ctx.k
    local mx = w * 0.04
    out[#out + 1] = gradient(w, h, "full")
    top_bar(ctx)

    local tfs = 34 * k
    local pp = playlist_pos()
    local full = (pp and (pp .. " ") or "") .. info.title
    local tw = textw(full, tfs, true)
    local maxw = w * 0.62
    if tw > maxw then tfs = tfs * maxw / tw end
    T(mx, h * 0.61, 4, tfs, full, "FFFFFF", 1, true)

    local by = h * 0.68
    local bx = badges(mx, by, k)
    local cl = chapter_label()
    if cl and opts.pill_show_chapter then
        local cwid = textw(cl, opts.pill_font_size * k, opts.pill_bold) + 2 * opts.pill_padding * k
        if bx + cwid < w - mx then chip(bx, by, k, cl) end
    end

    T(mx, h * 0.733, 4, 17 * k, info.meta, "C9C9C9", 1)
    local cache = mp.get_property_number("demuxer-cache-duration")
    if cache and cache > 0 then
        T(w - mx, h * 0.733, 6, 14 * k, string.format("Cache %d s", math.floor(cache + 0.5)), "C4C4C4", 1)
    end

    local byy = h * 0.778
    draw_seek(mx, w - mx, byy, k, 4 * k, ctx)

    local cy = h * 0.87
    local D = 52 * k
    local cx = mx + D / 2
    play_btn(cx, cy, k, D)
    cx = cx + D / 2 + 8 * k + 22 * k
    local st = skip_state()
    skip_btn("prev", cx, cy, k, st); cx = cx + 46 * k
    if opts.show_chapter_buttons then skip_btn("chprev", cx, cy, k, st); cx = cx + 46 * k end
    btn("back", cx, cy, k); cx = cx + 46 * k
    btn("fwd", cx, cy, k); cx = cx + 46 * k
    if opts.show_chapter_buttons then skip_btn("chnext", cx, cy, k, st); cx = cx + 46 * k end
    skip_btn("next", cx, cy, k, st); cx = cx + 56 * k
    local xl = tools_cluster(w - mx, cy, k)
    local tl = time_label(xl - 16 * k, cy, k, 18 * k)
    volume_ctl(cx, cy, k, clamp(tl - 14 * k - (cx + 26 * k), 0, 96 * k))
    return w - mx, byy - 26 * k
end

local function layout_center(ctx)
    local w, h, k = ctx.w, ctx.h, ctx.k
    local mx = w * 0.04
    out[#out + 1] = gradient(w, h, "full")
    top_bar(ctx)

    local cy = h * 0.915
    local sy = cy - 50 * k
    local ty = sy - 36 * k
    -- title row
    local cl = chapter_label()
    local ppc = playlist_pos()
    local tfull = (ppc and (ppc .. " ") or "") .. info.title
    -- measure the pills first: title and chapter label must stop before them
    local tmp = #out
    local bw = badges(0, -1000, k, { compact = true })
    for i = #out, tmp + 1, -1 do out[i] = nil end
    local pills_left = w - mx - (bw - opts.pill_gap * k)
    local room = pills_left - mx - 18 * k
    local tshown = tfull
    if textw(tfull, 22 * k, true) > room then tshown = fit(tfull, 22 * k, room, true) end
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
    badges(pills_left, ty, k, { compact = true })

    draw_seek(mx, w - mx, sy, k, 4 * k, ctx)

    local D = 52 * k
    local cx = mx + D / 2
    play_btn(cx, cy, k, D)
    cx = cx + D / 2 + 8 * k + 22 * k
    local st = skip_state()
    skip_btn("prev", cx, cy, k, st); cx = cx + 46 * k
    if opts.show_chapter_buttons then skip_btn("chprev", cx, cy, k, st); cx = cx + 46 * k end
    btn("back", cx, cy, k); cx = cx + 46 * k
    btn("fwd", cx, cy, k); cx = cx + 46 * k
    if opts.show_chapter_buttons then skip_btn("chnext", cx, cy, k, st); cx = cx + 46 * k end
    skip_btn("next", cx, cy, k, st); cx = cx + 56 * k
    local xl = tools_cluster(w - mx, cy, k)
    local tl = time_label(xl - 16 * k, cy, k, 18 * k)
    volume_ctl(cx, cy, k, clamp(tl - 14 * k - (cx + 26 * k), 0, 96 * k))
    return w - mx, ty - 22 * k
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
        ICON.pin(cx1 - cw2 + 14 * k, cy, k * 0.5, S.clock_pinned and opts.accent or "9AA3AF")
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
    local tools_left = px1 - 24 * k - 4 * 46 * k       -- left edge of the tools cluster
    local group = (opts.show_chapter_buttons and 340 or 248) * k                              -- prev..next block (5 buttons)
    local free = (tools_left - 8 * k) - (vcx + 22 * k + 8 * k) - group
    local sw = 0
    if opts.volume_style == "horizontal" and free > 70 * k then sw = math.min(88 * k, free - 14 * k) end
    volume_ctl(vcx, r2, k, sw)
    local cstart = vcx + 22 * k + 8 * k + (sw > 0 and (4 * k + sw + 10 * k) or 0)
    local mid = (cstart + tools_left - 8 * k) / 2
    local st = skip_state()
    local o1 = opts.show_chapter_buttons and 148 or 102
    skip_btn("prev", mid - o1 * k, r2, k, st)
    if opts.show_chapter_buttons then skip_btn("chprev", mid - 102 * k, r2, k, st) end
    btn("back", mid - 56 * k, r2, k)
    play_btn(mid, r2, k, 52 * k)
    btn("fwd", mid + 56 * k, r2, k)
    if opts.show_chapter_buttons then skip_btn("chnext", mid + 102 * k, r2, k, st) end
    skip_btn("next", mid + o1 * k, r2, k, st)
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
    if not B.checked then
        B.checked = true
        local vo = get("current-vo") or ""
        if vo ~= "" and not vo:find("gpu") then
            mp.msg.warn("snad-osc: panel_blur needs vo=gpu or gpu-next (current: " .. vo .. ") - disabled")
            B.ok = false
            return
        end
    end
    local ml, mt = S.ml or 0, S.mt or 0
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

local function norm_menu(list, keys)
    local res = {}
    for _, it in ipairs(listof(list)) do
        if type(it) == "table" and not has_state(it, "hidden") then
            local e = {}
            if it.type == "separator" then
                e.sep = true
            else
                e.title = tostring(it.title or ""):gsub("&&", "\1"):gsub("&", ""):gsub("\1", "&")
                e.cmd = it.cmd
                e.disabled = has_state(it, "disabled")
                e.checked = has_state(it, "checked")
                if it.submenu then e.sub = norm_menu(it.submenu, keys) end
                if e.sub and #e.sub == 0 then e.sub = nil end
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
            res[#res + 1] = e
        end
    end
    return res
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
    if S.layout == "pill" then mright, mbottom = layout_pill(ctx)
    elseif S.layout == "center" then mright, mbottom = layout_center(ctx)
    else mright, mbottom = layout_streamer(ctx) end

    if S.drawer then draw_drawer(ctx) end
    if S.menu then draw_menu(ctx, mright, mbottom) end
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

local function toggle_menu() S.menu = (not S.menu) and "tracks" or nil; S.volpop = false; show(); render() end
local function toggle_drawer()
    S.volpop = false
    if S.drawer then S.drawer = nil; set_wheel(false)
    else
        S.drawer = (#chapters > 0) and "chapters" or "playlist"
        S.scroll = 0; set_wheel(true)
    end
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

local ACTIONS = {
    play = function() mp.commandv("no-osd", "cycle", "pause") end,
    chprev = function() mp.commandv("no-osd", "add", "chapter", "-1") end,
    chnext = function() mp.commandv("no-osd", "add", "chapter", "1") end,
    prev = function() prev_next(-1) end,
    next = function() prev_next(1) end,
    back = function() mp.commandv("no-osd", "seek", tostring(-opts.skip_seconds)) end,
    fwd = function() mp.commandv("no-osd", "seek", tostring(opts.skip_seconds)) end,
    mute = function() mp.commandv("no-osd", "cycle", "mute") end,
    volbtn = function() S.volpop = not S.volpop; S.menu = nil end,
    tracks = toggle_menu,
    loop = function() mp.commandv("osd-auto", "cycle-values", "loop-file", "inf", "no") end,
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
                    if S.menu or S.drawer or S.volpop then
                        S.menu = nil
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
        if S.ctx then ctx_close() else ctx_open() end
        show(); render()
    end)
end

mp.add_forced_key_binding("MBTN_LEFT_DBL", "snad_dblclick", function()
    if S.visible and hit(S.mx, S.my) then return end
    mp.commandv("cycle", "fullscreen")
end)

mp.add_key_binding(nil, "toggle-title", function() S.title_pinned = not S.title_pinned; if not S.visible then hide() end end)
mp.add_key_binding(nil, "toggle-clock", function() S.clock_pinned = not S.clock_pinned; if not S.visible then hide() end end)
mp.add_key_binding(nil, "toggle-menu", toggle_menu)
mp.add_key_binding(nil, "toggle-drawer", toggle_drawer)

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

local VERSION = "v2.47"
local layout_known = false
for _, v in ipairs(LAYOUTS) do if v == opts.layout then layout_known = true end end
mp.msg.info("snad-osc " .. VERSION .. "  layout=" .. S.layout ..
    (layout_known and "" or ("  (unknown layout '" .. tostring(opts.layout) .. "' in snad_osc.conf)")))
local announced = false

mp.register_event("file-loaded", function()
    mp.commandv("script-message", "osc-visibility", "never", "no-osd")
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

-- nothing loaded: let mpv's stock OSC draw its logo; take over again once a file loads
mp.observe_property("idle-active", "bool", function(_, idle)
    if not opts.idle_logo then return end
    S.idle = idle and true or false
    if S.idle then
        clear_overlay()
        mp.commandv("script-message", "osc-visibility", "auto", "no-osd")
    else
        mp.commandv("script-message", "osc-visibility", "never", "no-osd")
    end
end)

mp.add_periodic_timer(0.1, function()
    if not S.visible then
        if ((S.clock_pinned and opts.show_clock) or S.title_pinned) and S.pin_sec ~= os.time() then draw_pinned_clock() end
        return
    end
    local over = S.hover and hit(S.mx, S.my)
    if not S.paused and not S.drag and not S.menu and not S.drawer and not S.volpop and not S.ctx and not over
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

refresh_chapters()
refresh_info()
