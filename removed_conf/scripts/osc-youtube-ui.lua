local assdraw = require 'mp.assdraw'
local msg = require 'mp.msg'
local opt = require 'mp.options'
local utils = require 'mp.utils'

--
-- Parameters
--
-- default user option values
-- may change them in osc.conf
local user_opts = {
    showwindowed = true,        -- show OSC when windowed?
    showfullscreen = true,      -- show OSC when fullscreen?
    idlescreen = true,          -- show mpv logo on idle
    scalewindowed = 1,          -- scaling of the controller when windowed
    scalefullscreen = 1.5,      -- scaling of the controller when fullscreen
    scaleforcedwindow = 1,      -- scaling when rendered on a forced window
    vidscale = false,           -- scale the controller with the video?
    hidetimeout = 2000,         -- duration in ms until the OSC hides if no
                                -- mouse movement. enforced non-negative for the
                                -- user, but internally negative is "always-on".
    fadeduration = 150,         -- duration of fade out in ms, 0 = no fade
    deadzonesize = 0,           -- size of deadzone
    minmousemove = 0,           -- minimum amount of pixels the mouse has to
                                -- move between ticks to make the OSC show up
    iamaprogrammer = false,     -- use native mpv values and disable OSC
                                -- internal track list management (and some
                                -- functions that depend on it)
    seekrange = true,           -- show seekrange overlay
    seekrangealpha = 192,       -- transparency of seekranges
    seekbarkeyframes = true,    -- use keyframes when dragging the seekbar
    title = "${media-title}",   -- string compatible with property-expansion
                                -- to be shown as OSC title
    timetotal = true,           -- display total time instead of remaining time?
    timems = false,             -- display timecodes with milliseconds?
    visibility = "auto",        -- only used at init to set visibility_mode(...)
    boxvideo = false,           -- apply osc_param.video_margins to video
    windowcontrols = "auto",    -- whether to show window controls
    windowcontrols_alignment = "right", -- which side to show window controls on
    livemarkers = true,         -- update seekbar chapter markers on duration change
    unicodeminus = false,       -- whether to use the Unicode minus sign character
    language = "eng",           -- eng=English, chs=Chinese
    thumbpad = 4,               -- thumbnail border size
}

-- read options from config and command-line
opt.read_options(user_opts, "osc", function(list) update_options(list) end)

-- Localization
local language = {
    ["eng"] = {
        welcome = "{\\fs24\\1c&H0&\\3c&HFFFFFF&}Drop files or URLs to play here.",  -- this text appears when mpv starts
        off = "Off",
        unknown = "unknown",
        none = "none",
        video_track = "Video track",
        video_tracks = "Video tracks",
        audio_track = "Audio track",
        audio_tracks = "Audio tracks",
        subtitle = "Subtitle",
        subtitles = "Subtitles",
        playlist = "Playlist",
        chapter = "Chapter",
        chapters = "Chapters",
    },
    ["chs"] = {
        welcome = "{\\1c&H00\\bord0\\fs30\\fn微软雅黑 light\\fscx125}MPV{\\fscx100} 播放器",  -- this text appears when mpv starts
        off = "关闭",
        na = "n/a",
        none = "无",
        video = "视频",
        audio = "音频",
        subtitle = "字幕",
        available = "可选",
        track = "：",
        playlist = "播放列表",
        nolist = "无列表信息",
        chapter = "章节",
        nochapter = "无章节信息",
    }
}

-- apply lang opts
local texts = language[user_opts.language]

local osc_param = { -- calculated by osc_init()
    playresy = 0,                           -- canvas size Y
    playresx = 0,                           -- canvas size X
    display_aspect = 1,
    unscaled_y = 0,
    areas = {},
    video_margins = {
        l = 0, r = 0, t = 0, b = 0,         -- left/right/top/bottom
    },
}

local osc_styles = {
    box = "{\\blur100\\bord0\\1c&H000000\\3c&H000000}",
    seekbar_bg = "{\\blur0\\bord0\\1c&HFFFFFF}",
    seekbar_fg = "{\\blur0\\bord0\\1c&HE39C42}",
    volumebar_bg = "{\\blur0\\bord0\\1c&HFFFFFF}",
    volumebar_fg = "{\\blur0\\bord0\\1c&HFFFFFF}",
    button = "{\\blur0\\bord0\\1c&HFFFFFF\\3c&HFFFFFF}",
    timecode = "{\\blur0\\bord0\\1c&HFFFFFF\\3c&H000000\\fs18}",
    tooltip = "{\\blur1.5\\bord0.01\\1c&HFFFFFF\\3c&H000000\\fs18}",
    title = "{\\1c&HFFFFFF\\fs24}",
}

-- internal states, do not touch
local state = {
    showtime,                               -- time of last invocation (last mouse move)
    osc_visible = false,
    anistart,                               -- time when the animation started
    anitype,                                -- current type of animation
    animation,                              -- current animation alpha
    mouse_down_counter = 0,                 -- used for softrepeat
    active_element = nil,                   -- nil = none, 0 = background, 1+ = see elements[]
    active_event_source = nil,              -- the "button" that issued the current event
    rightTC_trem = not user_opts.timetotal, -- if the right timecode should display total or remaining time
    tc_ms = user_opts.timems,               -- Should the timecodes display their time with milliseconds
    mp_screen_sizeX, mp_screen_sizeY,       -- last screen-resolution, to detect resolution changes to issue reINITs
    initREQ = false,                        -- is a re-init request pending?
    marginsREQ = false,                     -- is a margins update pending?
    last_mouseX, last_mouseY,               -- last mouse position, to detect significant mouse movement
    mouse_in_window = false,
    message_text,
    message_hide_timer,
    fullscreen = false,
    tick_timer = nil,
    tick_last_time = 0,                     -- when the last tick() was run
    hide_timer = nil,
    cache_state = nil,
    idle = false,
    enabled = true,
    input_enabled = true,
    showhide_enabled = false,
    windowcontrols_buttons = false,
    dmx_cache = 0,
    using_video_margins = false,
    border = true,
    maximized = false,
    osd = mp.create_osd_overlay("ass-events"),
    chapter_list = {},                      -- sorted by time
    last_visibility = user_opts.visibility, -- last visibility on pause
    mute = false,
}

local icons = {
    play = "{\\p1}m 0 0 m 24 24 m 8 5 l 8 19 l 19 12{\\p0}",
    pause = "{\\p1}m 0 0 m 24 24 m 6 19 l 10 19 l 10 5 l 6 5 l 6 19 m 14 5 l 14 19 l 18 19 l 18 5 l 14 5{\\p0}",
    close = "{\\p1}m 0 0 m 24 24 m 19 6.41 l 17.59 5 l 12 10.59 l 6.41 5 l 5 6.41 l 10.59 12 l 5 17.59 l 6.41 19 l 12 13.41 l 17.59 19 l 19 17.59 l 13.41 12{\\p0}",
    minimize = "{\\p1}m 0 0 m 24 24 m 4 18 l 20 18 l 20 20 l 4 20{\\p0}",
    maximize = "{\\p1}m 0 0 m 24 24 m 18 4 l 6 4 b 4.9 4 4 4.9 4 6 l 4 18 b 4 19.1 4.9 20 6 20 l 18 20 b 19.1 20 20 19.1 20 18 l 20 6 b 20 4.9 19.1 4 18 4 m 18 18 l 6 18 l 6 6 l 18 6 l 18 18{\\p0}",
    maximize_exit = "{\\p1}m 0 0 m 24 24 m 6 8 l 4 8 l 4 18 b 4 19.1 4.9 20 6 20 l 16 20 l 16 18 l 6 18 m 18 4 l 10 4 b 8.9 4 8 4.9 8 6 l 8 14 b 8 15.1 8.9 16 10 16 l 18 16 b 19.1 16 20 15.1 20 14 l 20 6 b 20 4.9 19.1 4 18 4 m 18 14 l 10 14 l 10 6 l 18 6{\\p0}",
    fs_enter = "{\\p1}m 0 0 m 24 24 m 7 14 l 5 14 l 5 19 l 10 19 l 10 17 l 7 17 l 7 14 m 5 10 l 7 10 l 7 7 l 10 7 l 10 5 l 5 5 l 5 10 m 17 17 l 14 17 l 14 19 l 19 19 l 19 14 l 17 14 l 17 17 m 14 5 l 14 7 l 17 7 l 17 10 l 19 10 l 19 5 l 14 5{\\p0}",
    fs_exit = "{\\p1}m 0 0 m 24 24 m 5 16 l 8 16 l 8 19 l 10 19 l 10 14 l 5 14 l 5 16 m 8 8 l 5 8 l 5 10 l 10 10 l 10 5 l 8 5 l 8 8 m 14 19 l 16 19 l 16 16 l 19 16 l 19 14 l 14 14 l 14 19 m 16 8 l 16 5 l 14 5 l 14 10 l 19 10 l 19 8 l 16 8{\\p0}",
    info = "{\\p1}m 0 0 m 24 24 m 11 7 l 13 7 l 13 9 l 11 9 m 11 11 l 13 11 l 13 17 l 11 17 m 12 2 b 6.48 2 2 6.48 2 12 b 2 17.52 6.48 22 12 22 b 17.52 22 22 17.52 22 12 b 22 6.48 17.52 2 12 2 m 12 20 b 7.59 20 4 16.41 4 12 b 4 7.59 7.59 4 12 4 b 16.41 4 20 7.59 20 12 b 20 16.41 16.41 20 12 20{\\p0}",
    cy_audio = "{\\p1}m 0 0 m 24 24 m 20 4 l 4 4 b 2.9 4 2 4.9 2 6 l 2 18 b 2 19.1 2.9 20 4 20 l 20 20 b 21.1 20 22 19.1 22 18 l 22 6 b 22 4.9 21.1 4 20 4 m 7.76 16.24 l 6.35 17.65 b 4.78 16.1 4 14.05 4 12 b 4 9.95 4.78 7.9 6.34 6.34 l 7.75 7.75 b 6.59 8.93 6 10.46 6 12 b 6 13.54 6.59 15.07 7.76 16.24 m 12 16 b 9.79 16 8 14.21 8 12 b 8 9.79 9.79 8 12 8 b 14.21 8 16 9.79 16 12 b 16 14.21 14.21 16 12 16 m 17.66 17.66 l 16.25 16.25 b 17.41 15.07 18 13.54 18 12 b 18 10.46 17.41 8.93 16.24 7.76 l 17.65 6.35 b 19.22 7.9 20 9.95 20 12 b 20 14.05 19.22 16.1 17.66 17.66 m 12 10 b 10.9 10 10 10.9 10 12 b 10 13.1 10.9 14 12 14 b 13.1 14 14 13.1 14 12 b 14 10.9 13.1 10 12 10{\\p0}",
    cy_sub = "{\\p1}m 0 0 m 24 24 m 20 4 l 4 4 b 2.9 4 2 4.9 2 6 l 2 18 b 2 19.1 2.9 20 4 20 l 20 20 b 21.1 20 22 19.1 22 18 l 22 6 b 22 4.9 21.1 4 20 4 m 4 12 l 8 12 l 8 14 l 4 14 l 4 12 m 14 18 l 4 18 l 4 16 l 14 16 l 14 18 m 20 18 l 16 18 l 16 16 l 20 16 l 20 18 m 20 14 l 10 14 l 10 12 l 20 12 l 20 14{\\p0}",
    pl_prev = "{\\p1}m 0 0 m 24 24 m 6 6 l 8 6 l 8 18 l 6 18 m 9.5 12 l 18 18 l 18 6{\\p0}",
    pl_next = "{\\p1}m 0 0 m 24 24 m 6 18 l 14.5 12 l 6 6 l 6 18 m 16 6 l 16 18 l 18 18 l 18 6 l 16 6{\\p0}",
    skipback = "{\\p1}m 0 0 m 24 24 m 11 18 l 11 6 l 2.5 12 l 11 18 m 11.5 12 l 20 18 l 20 6 l 11.5 12{\\p0}",
    skipfrwd = "{\\p1}m 0 0 m 24 24 m 4 18 l 12.5 12 l 4 6 l 4 18 m 13 6 l 13 18 l 21.5 12 l 13 6{\\p0}",
    volume_low = "{\\p1}m 0 0 m 24 24 m 3 9 l 3 15 l 7 15 l 12 20 l 12 4 l 7 9 l 3 9{\\p0}",
    volume_medium = "{\\p1}m 0 0 m 24 24 m 14 7.97 l 14 16.02 b 15.48 15.29 16.5 13.77 16.5 12 b 16.5 10.23 15.48 8.71 14 7.97 m 3 9 l 3 15 l 7 15 l 12 20 l 12 4 l 7 9 l 3 9{\\p0}",
    volume_high = "{\\p1}m 0 0 m 24 24 m 3 9 l 3 15 l 7 15 l 12 20 l 12 4 l 7 9 l 3 9 m 16.5 12 b 16.5 10.23 15.48 8.71 14 7.97 l 14 16.02 b 15.48 15.29 16.5 13.77 16.5 12 m 14 3.23 l 14 5.29 b 16.89 6.15 19 8.83 19 12 b 19 15.17 16.89 17.85 14 18.71 l 14 20.77 b 18.01 19.86 21 16.28 21 12 b 21 7.72 18.01 4.14 14 3.23{\\p0}",
    volume_over = "{\\p1}m 0 0 m 24 24 m 3 9 l 3 15 l 7 15 l 12 20 l 12 4 l 7 9 l 3 9 m 16 6 l 18 6 l 18 14 l 16 14 m 16 16 l 18 16 l 18 18 l 16 18{\\p0}",
    volume_mute = "{\\p1}m 0 0 m 24 24 m 16.5 12 b 16.5 10.23 15.48 8.71 14 7.97 l 14 10.18 l 16.45 12.63 b 16.48 12.43 16.5 12.22 16.5 12 m 19 12 b 19 12.94 18.8 13.82 18.46 14.64 l 19.97 16.15 b 20.63 14.91 21 13.5 21 12 b 21 7.72 18.01 4.14 14 3.23 l 14 5.29 b 16.89 6.15 19 8.83 19 12 m 4.27 3 l 3 4.27 l 7.73 9 l 3 9 l 3 15 l 7 15 l 12 20 l 12 13.27 l 16.25 17.52 b 15.58 18.04 14.83 18.45 14 18.7 l 14 20.76 b 15.38 20.45 16.63 19.81 17.69 18.95 l 19.73 21 l 21 19.73 l 12 10.73 l 4.27 3 m 12 4 l 9.91 6.09 l 12 8.18 l 12 4{\\p0}",
}

local thumbfast = {
    width = 0,
    height = 0,
    disabled = true,
    available = false
}

local window_control_box_width = 138
local tick_delay = 0.03

--
-- Helperfunctions
--

function kill_animation()
    state.anistart = nil
    state.animation = nil
    state.anitype =  nil
end

function set_osd(res_x, res_y, text)
    if state.osd.res_x == res_x and
       state.osd.res_y == res_y and
       state.osd.data == text then
        return
    end
    state.osd.res_x = res_x
    state.osd.res_y = res_y
    state.osd.data = text
    state.osd.z = 1000
    state.osd:update()
end

local margins_opts = {
    {"l", "video-margin-ratio-left"},
    {"r", "video-margin-ratio-right"},
    {"t", "video-margin-ratio-top"},
    {"b", "video-margin-ratio-bottom"},
}

-- scale factor for translating between real and virtual ASS coordinates
function get_virt_scale_factor()
    local w, h = mp.get_osd_size()
    if w <= 0 or h <= 0 then
        return 0, 0
    end
    return osc_param.playresx / w, osc_param.playresy / h
end

-- return mouse position in virtual ASS coordinates (playresx/y)
function get_virt_mouse_pos()
    if state.mouse_in_window then
        local sx, sy = get_virt_scale_factor()
        local x, y = mp.get_mouse_pos()
        return x * sx, y * sy
    else
        return -1, -1
    end
end

function set_virt_mouse_area(x0, y0, x1, y1, name)
    local sx, sy = get_virt_scale_factor()
    mp.set_mouse_area(x0 / sx, y0 / sy, x1 / sx, y1 / sy, name)
end

function scale_value(x0, x1, y0, y1, val)
    local m = (y1 - y0) / (x1 - x0)
    local b = y0 - (m * x0)
    return (m * val) + b
end

-- returns hitbox spanning coordinates (top left, bottom right corner)
-- according to alignment
function get_hitbox_coords(x, y, an, w, h)

    local alignments = {
      [1] = function () return x, y-h, x+w, y end,
      [2] = function () return x-(w/2), y-h, x+(w/2), y end,
      [3] = function () return x-w, y-h, x, y end,

      [4] = function () return x, y-(h/2), x+w, y+(h/2) end,
      [5] = function () return x-(w/2), y-(h/2), x+(w/2), y+(h/2) end,
      [6] = function () return x-w, y-(h/2), x, y+(h/2) end,

      [7] = function () return x, y, x+w, y+h end,
      [8] = function () return x-(w/2), y, x+(w/2), y+h end,
      [9] = function () return x-w, y, x, y+h end,
    }

    return alignments[an]()
end

function get_hitbox_coords_geo(geometry)
    return get_hitbox_coords(geometry.x, geometry.y, geometry.an,
        geometry.w, geometry.h)
end

function get_element_hitbox(element)
    return element.hitbox.x1, element.hitbox.y1,
        element.hitbox.x2, element.hitbox.y2
end

function mouse_hit(element)
    return mouse_hit_coords(get_element_hitbox(element))
end

function mouse_hit_coords(bX1, bY1, bX2, bY2)
    local mX, mY = get_virt_mouse_pos()
    return (mX >= bX1 and mX <= bX2 and mY >= bY1 and mY <= bY2)
end

function limit_range(min, max, val)
    if val > max then
        val = max
    elseif val < min then
        val = min
    end
    return val
end

-- translate value into element coordinates
function get_slider_ele_pos_for(element, val)

    local ele_pos = scale_value(
        element.slider.min.value, element.slider.max.value,
        element.slider.min.ele_pos, element.slider.max.ele_pos,
        val)

    return limit_range(
        element.slider.min.ele_pos, element.slider.max.ele_pos,
        ele_pos)
end

-- translates global (mouse) coordinates to value
function get_slider_value_at(element, glob_pos)

    local val = scale_value(
        element.slider.min.glob_pos, element.slider.max.glob_pos,
        element.slider.min.value, element.slider.max.value,
        glob_pos)

    return limit_range(
        element.slider.min.value, element.slider.max.value,
        val)
end

-- get value at current mouse position
function get_slider_value(element)
    return get_slider_value_at(element, get_virt_mouse_pos())
end

function countone(val)
    if not (user_opts.iamaprogrammer) then
        val = val + 1
    end
    return val
end

-- align:  -1 .. +1
-- frame:  size of the containing area
-- obj:    size of the object that should be positioned inside the area
-- margin: min. distance from object to frame (as long as -1 <= align <= +1)
function get_align(align, frame, obj, margin)
    return (frame / 2) + (((frame / 2) - margin - (obj / 2)) * align)
end

-- multiplies two alpha values, formular can probably be improved
function mult_alpha(alphaA, alphaB)
    return 255 - (((1-(alphaA/255)) * (1-(alphaB/255))) * 255)
end

function add_area(name, x1, y1, x2, y2)
    -- create area if needed
    if (osc_param.areas[name] == nil) then
        osc_param.areas[name] = {}
    end
    table.insert(osc_param.areas[name], {x1=x1, y1=y1, x2=x2, y2=y2})
end

function ass_append_alpha(ass, alpha, modifier)
    local ar = {}

    for ai, av in pairs(alpha) do
        av = mult_alpha(av, modifier)
        if state.animation then
            av = mult_alpha(av, state.animation)
        end
        ar[ai] = av
    end

    ass:append(string.format("{\\1a&H%X&\\2a&H%X&\\3a&H%X&\\4a&H%X&}",
               ar[1], ar[2], ar[3], ar[4]))
end

function ass_draw_cir_cw(ass, x, y, r)
    ass:round_rect_cw(x-r, y-r, x+r, y+r, r)
end

function ass_draw_rr_h_cw(ass, x0, y0, x1, y1, r1, hexagon, r2)
    if hexagon then
        ass:hexagon_cw(x0, y0, x1, y1, r1, r2)
    else
        ass:round_rect_cw(x0, y0, x1, y1, r1, r2)
    end
end

function ass_draw_rr_h_ccw(ass, x0, y0, x1, y1, r1, hexagon, r2)
    if hexagon then
        ass:hexagon_ccw(x0, y0, x1, y1, r1, r2)
    else
        ass:round_rect_ccw(x0, y0, x1, y1, r1, r2)
    end
end


--
-- Tracklist Management
--

local nicetypes = {video = texts.video_track, audio = texts.audio_track, sub = texts.subtitle}
local nicetypes_pl = {video = texts.video_tracks, audio = texts.audio_tracks, sub = texts.subtitles}

-- updates the OSC internal playlists, should be run each time the track-layout changes
function update_tracklist()
    local tracktable = mp.get_property_native("track-list", {})

    -- by osc_id
    tracks_osc = {}
    tracks_osc.video, tracks_osc.audio, tracks_osc.sub = {}, {}, {}
    -- by mpv_id
    tracks_mpv = {}
    tracks_mpv.video, tracks_mpv.audio, tracks_mpv.sub = {}, {}, {}
    for n = 1, #tracktable do
        if not (tracktable[n].type == "unknown") then
            local type = tracktable[n].type
            local mpv_id = tonumber(tracktable[n].id)

            -- by osc_id
            table.insert(tracks_osc[type], tracktable[n])

            -- by mpv_id
            tracks_mpv[type][mpv_id] = tracktable[n]
            tracks_mpv[type][mpv_id].osc_id = #tracks_osc[type]
        end
    end
end

-- return a nice list of tracks of the given type (video, audio, sub)
function get_tracklist(type)
    local msg = nicetypes_pl[type] .. ": "
    if not tracks_osc or #tracks_osc[type] == 0 then
        msg = msg .. texts.none
    else
        for n = 1, #tracks_osc[type] do
            local track = tracks_osc[type][n]
            local lang, title, selected = texts.unknown, "", "○"
            if not(track.lang == nil) then lang = track.lang end
            if not(track.title == nil) then title = track.title end
            if (track.id == tonumber(mp.get_property(type))) then
                selected = "●"
            end
            msg = msg.."\n"..selected.." "..n..". ["..lang.."] "..title
        end
    end
    return msg
end

-- relatively change the track of given <type> by <next> tracks
    --(+1 -> next, -1 -> previous)
function set_track(type, next)
    local current_track_mpv, current_track_osc
    if (mp.get_property(type) == "no") then
        current_track_osc = 0
    else
        current_track_mpv = tonumber(mp.get_property(type))
        current_track_osc = tracks_mpv[type][current_track_mpv].osc_id
    end
    local new_track_osc = (current_track_osc + next) % (#tracks_osc[type] + 1)
    -- never set 0 for audio/video
    if new_track_osc == 0 and type ~= "sub" then
        new_track_osc = (current_track_osc + next - 1) % #tracks_osc[type] + 1
    end
    local new_track_mpv
    if new_track_osc == 0 then
        new_track_mpv = "no"
    else
        new_track_mpv = tracks_osc[type][new_track_osc].id
    end

    mp.commandv("set", type, new_track_mpv)

    if (new_track_osc == 0) then
        show_message(nicetypes[type] .. ": " .. texts.off)
    else
        show_message(nicetypes[type] .. ": "
            .. new_track_osc .. "/" .. #tracks_osc[type]
            .. " [" .. (tracks_osc[type][new_track_osc].lang or texts.unknown) .. "] "
            .. (tracks_osc[type][new_track_osc].title or ""))
    end
end

-- get the currently selected track of <type>, OSC-style counted
function get_track(type)
    local track = mp.get_property(type)
    if track ~= "no" and track ~= nil then
        local tr = tracks_mpv[type][tonumber(track)]
        if tr then
            return tr.osc_id
        end
    end
    return 0
end

-- WindowControl helpers
function window_controls_enabled()
    val = user_opts.windowcontrols
    if val == "auto" then
        return not state.border
    else
        return val ~= "no"
    end
end

function window_controls_alignment()
    return user_opts.windowcontrols_alignment
end

--
-- Element Management
--

local elements = {}

function prepare_elements()

    -- remove elements without layout or invisble
    local elements2 = {}
    for n, element in pairs(elements) do
        if not (element.layout == nil) and (element.visible) then
            table.insert(elements2, element)
        end
    end
    elements = elements2

    function elem_compare (a, b)
        return a.layout.layer < b.layout.layer
    end

    table.sort(elements, elem_compare)


    for _,element in pairs(elements) do

        local elem_geo = element.layout.geometry

        -- Calculate the hitbox
        local bX1, bY1, bX2, bY2 = get_hitbox_coords_geo(elem_geo)
        element.hitbox = {x1 = bX1, y1 = bY1, x2 = bX2, y2 = bY2}

        local style_ass = assdraw.ass_new()

        -- prepare static elements
        style_ass:append("{}") -- hack to troll new_event into inserting a \n
        style_ass:new_event()
        style_ass:pos(elem_geo.x, elem_geo.y)
        style_ass:an(elem_geo.an)
        style_ass:append(element.layout.style)

        element.style_ass = style_ass

        local static_ass = assdraw.ass_new()


        if (element.type == "box") then
            --draw box
            static_ass:draw_start()
            ass_draw_rr_h_cw(static_ass, 0, 0, elem_geo.w, elem_geo.h,
                             element.layout.box.radius, element.layout.box.hexagon)
            static_ass:draw_stop()

        elseif (element.type == "slider") then
            --draw static slider parts

            local slider_lo = element.layout.slider

            -- calculate positions of min and max points
            element.slider.min.ele_pos = slider_lo.pad + slider_lo.handle_size / 2
            element.slider.max.ele_pos = elem_geo.w - element.slider.min.ele_pos
            element.slider.min.glob_pos = element.hitbox.x1 + element.slider.min.ele_pos
            element.slider.max.glob_pos = element.hitbox.x1 + element.slider.max.ele_pos

            -- -- --

            static_ass:draw_start()

            -- a hack which prepares the whole slider area to allow center placements such like an=5
            static_ass:rect_cw(0, 0, elem_geo.w, elem_geo.h)
            static_ass:rect_ccw(0, 0, elem_geo.w, elem_geo.h)

            -- marker nibbles
            if not (element.slider.markerF == nil) and (slider_lo.gap > 0) then
                local markers = element.slider.markerF()
                for _,marker in pairs(markers) do
                    if (marker >= element.slider.min.value) and
                        (marker <= element.slider.max.value) then

                        local s = get_slider_ele_pos_for(element, marker)

                        if (slider_lo.gap > 5) then -- draw triangles

                            --top
                            if (slider_lo.nibbles_top) then
                                static_ass:move_to(s - 3, slider_lo.gap - 5)
                                static_ass:line_to(s + 3, slider_lo.gap - 5)
                                static_ass:line_to(s, slider_lo.gap - 1)
                            end

                            --bottom
                            if (slider_lo.nibbles_bottom) then
                                static_ass:move_to(s - 3, elem_geo.h - slider_lo.gap + 5)
                                static_ass:line_to(s, elem_geo.h - slider_lo.gap + 1)
                                static_ass:line_to(s + 3, elem_geo.h - slider_lo.gap + 5)
                            end

                        else -- draw 2x1px nibbles

                            --top
                            if (slider_lo.nibbles_top) then
                                static_ass:rect_cw(s - 1, 0, s + 1, slider_lo.gap);
                            end

                            --bottom
                            if (slider_lo.nibbles_bottom) then
                                static_ass:rect_cw(s - 1, elem_geo.h - slider_lo.gap, s + 1, elem_geo.h);
                            end
                        end
                    end
                end
            end
        end

        element.static_ass = static_ass


        -- if the element is supposed to be disabled,
        -- style it accordingly and kill the eventresponders
        if not (element.enabled) then
            element.layout.alpha[1] = 153
            element.eventresponder = nil
        end
    end
end


--
-- Element Rendering
--

-- returns nil or a chapter element from the native property chapter-list
function get_chapter(possec)
    local cl = state.chapter_list  -- sorted, get latest before possec, if any

    for n=#cl,1,-1 do
        if possec >= cl[n].time then
            return cl[n]
        end
    end
end

function render_elements(master_ass)

    for n=1, #elements do
        local element = elements[n]

        -- false if other element is active
        local activatable = (state.active_element == nil) or (state.active_element == n)

        local style_ass = assdraw.ass_new()
        style_ass:merge(element.style_ass)
        ass_append_alpha(style_ass, element.layout.alpha, 0)

        if element.eventresponder and (state.active_element == n) then

            -- run render event functions
            if not (element.eventresponder.render == nil) then
                element.eventresponder.render(element)
            end

            if mouse_hit(element) then
                -- mouse down styling
                if (element.styledown) then
                    ass_append_alpha(style_ass, element.layout.alpha, 102)
                end

                if (element.softrepeat) and (state.mouse_down_counter >= 15
                    and state.mouse_down_counter % 5 == 0) then

                    element.eventresponder[state.active_event_source.."_down"](element)
                end
                state.mouse_down_counter = state.mouse_down_counter + 1
            end

        end

        local elem_ass = assdraw.ass_new()

        elem_ass:merge(style_ass)

        if not (element.type == "button") then
            elem_ass:merge(element.static_ass)
        end

        if (element.type == "slider") then

            local slider_lo = element.layout.slider
            local elem_geo = element.layout.geometry
            local s_min = element.slider.min.value
            local s_max = element.slider.max.value

            -- draw pos marker
            local pos = element.slider.posF()
            local foH = elem_geo.h / 2
            local r = slider_lo.handle_size / 2
            local bar_r = slider_lo.bar_height / 2
            local range_r = bar_r + 2
            local pad = slider_lo.pad

            if element.slider.seekRangesF ~= nil then
                local seekRanges = element.slider.seekRangesF()
            end

            if seekRanges then
                elem_ass:merge(element.style_ass)
                elem_ass:append(slider_lo.bg_style)
                ass_append_alpha(elem_ass, element.layout.alpha, user_opts.seekrangealpha)
                elem_ass:merge(element.static_ass)

                for _,range in pairs(seekRanges) do
                    local pstart = get_slider_ele_pos_for(element, range["start"])
                    local pend = get_slider_ele_pos_for(element, range["end"])
                    ass_draw_rr_h_cw(elem_ass, pstart - range_r, foH - range_r,
                                     pend + range_r, foH + range_r,
                                     range_r, false)
                end
            end

            if pos then
                local xp = get_slider_ele_pos_for(element, pos)

                elem_ass:merge(element.style_ass)
                elem_ass:append(slider_lo.bg_style)
                ass_append_alpha(elem_ass, slider_lo.alpha, slider_lo.bg_alpha)
                elem_ass:merge(element.static_ass)

                -- inactive bar
                ass_draw_rr_h_cw(elem_ass, xp, foH - bar_r,
                                 elem_geo.w - (pad + r - bar_r), foH + bar_r,
                                 0, false, bar_r)

                elem_ass:merge(element.style_ass)
                ass_append_alpha(elem_ass, element.layout.alpha, 0)
                elem_ass:merge(element.static_ass)

                -- active bar
                ass_draw_rr_h_cw(elem_ass, pad + r - bar_r, foH - bar_r,
                                 xp, foH + bar_r,
                                 bar_r, false, 0)

                -- handle
                ass_draw_rr_h_cw(elem_ass, xp - r, foH - r,
                                 xp + r, foH + r,
                                 r, false)

                elem_ass:merge(element.style_ass)
                ass_append_alpha(elem_ass, element.layout.alpha, 0)
                elem_ass:merge(element.static_ass)
            end

            if element.enabled and not (slider_lo.adjust_tooltip) then
                if mouse_hit(element) and activatable then
                    element.layout.alpha[1] = 0
                else
                    element.layout.alpha[1] = 51
                end
            end

            elem_ass:draw_stop()

            -- add tooltip
            if not (element.slider.tooltipF == nil) and element.enabled then

                if mouse_hit(element) and activatable then
                    local sliderpos = get_slider_value(element)
                    local tooltiplabel = element.slider.tooltipF(sliderpos)

                    local an = slider_lo.tooltip_an

                    local ty

                    if (an == 2) then
                        ty = element.hitbox.y1 - 4
                    else
                        ty = element.hitbox.y1 + elem_geo.h/2
                    end

                    local tx = get_virt_mouse_pos()
                    if (slider_lo.adjust_tooltip) then
                        if (an == 2) then
                            if (sliderpos < (s_min + 3)) then
                                an = an - 1
                            elseif (sliderpos > (s_max - 3)) then
                                an = an + 1
                            end
                        elseif (sliderpos > (s_max-s_min)/2) then
                            an = an + 1
                            tx = tx - 5
                        else
                            an = an - 1
                            tx = tx + 10
                        end
                    else
                        -- for volumebar
                        tx = element.hitbox.x1 + elem_geo.w / 2
                        ty = element.hitbox.y1 - 20
                    end

                    -- tooltip label
                    elem_ass:new_event()
                    elem_ass:pos(tx, ty)
                    elem_ass:an(an)
                    elem_ass:append(slider_lo.tooltip_style)
                    ass_append_alpha(elem_ass, slider_lo.alpha, 0)
                    elem_ass:append(tooltiplabel)

                    -- thumbnail
                    if element.thumbnail and not thumbfast.disabled then
                        local osd_w = mp.get_property_number("osd-width")
                        if osd_w then
                            local r_w, r_h = get_virt_scale_factor()

                            local thumb_pad = user_opts.thumbpad
                            local thumb_margin_x = 16 / r_w + thumb_pad
                            local thumb_margin_y = 24 / r_h + thumb_pad
                            local thumb_x = math.min(osd_w - thumbfast.width - thumb_margin_x, math.max(thumb_margin_x, tx / r_w - thumbfast.width / 2))
                            local thumb_y = ty / r_h - thumbfast.height - thumb_margin_y

                            thumb_x = math.floor(thumb_x + 0.5)
                            thumb_y = math.floor(thumb_y + 0.5)

                            elem_ass:new_event()
                            elem_ass:pos(thumb_x * r_w, thumb_y * r_h)
                            elem_ass:append(slider_lo.tooltip_style)
                            elem_ass:draw_start()
                            elem_ass:rect_cw(-thumb_pad * r_w, -thumb_pad * r_h, (thumbfast.width + thumb_pad) * r_w, (thumbfast.height + thumb_pad) * r_h)
                            elem_ass:draw_stop()

                            mp.commandv("script-message-to", "thumbfast", "thumb",
                                mp.get_property_number("duration", 0) * (sliderpos / 100),
                                thumb_x,
                                thumb_y
                            )
                        end
                    end
                else
                    if element.thumbnail and thumbfast.available then
                        mp.commandv("script-message-to", "thumbfast", "clear")
                    end
                end
            end

        elseif (element.type == "button") then

            local buttontext
            if type(element.content) == "function" then
                buttontext = element.content() -- function objects
            elseif not (element.content == nil) then
                buttontext = element.content -- text objects
            end

            buttontext = buttontext:gsub(':%((.?.?.?)%) unknown ', ':%(%1%)')  --gsub('%) unknown %(\'', '')

            local maxchars = element.layout.button.maxchars
            -- 认为1个中文字符约等于1.5个英文字符
            local charcount = (buttontext:len() + select(2, buttontext:gsub('[^\128-\193]', ''))*2) / 3
            if not (maxchars == nil) and (charcount > maxchars) then
                local limit = math.max(0, maxchars - 3)
                if (charcount > limit) then
                    while (charcount > limit) do
                        buttontext = buttontext:gsub('.[\128-\191]*$', '')
                        charcount = (buttontext:len() + select(2, buttontext:gsub('[^\128-\193]', ''))*2) / 3
                    end
                    buttontext = buttontext .. "..."
                end
            end

            if element.enabled then
                if mouse_hit(element) and activatable then
                    element.layout.alpha[1] = 0
                else
                    element.layout.alpha[1] = 51
                end
            end

            elem_ass:append(buttontext)

            -- add tooltip
            if not (element.tooltipF == nil) and element.enabled then
                if mouse_hit(element) and activatable then
                    local tooltiplabel = element.tooltipF
                    local an = 2
                    local ty = element.hitbox.y1 - 20
                    local tx = (element.hitbox.x1 + element.hitbox.x2) / 2

                    if ty < osc_param.playresy / 2 then
                        ty = element.hitbox.y2
                        an = 7
                    end

                    -- tooltip label
                    if type(element.tooltipF) == "function" then
                        tooltiplabel = element.tooltipF()
                    else
                        tooltiplabel = element.tooltipF
                    end
                    elem_ass:new_event()
                    elem_ass:pos(tx, ty)
                    elem_ass:an(an)
                    elem_ass:append(element.tooltip_style)
                    elem_ass:append(tooltiplabel)
                end
            end
        end

        master_ass:merge(elem_ass)
    end
end

--
-- Message display
--

-- pos is 1 based
function limited_list(prop, pos)
    local proplist = mp.get_property_native(prop, {})
    local count = #proplist
    if count == 0 then
        return count, proplist
    end

    local fs = tonumber(mp.get_property('options/osd-font-size'))
    local max = math.ceil(osc_param.unscaled_y*0.75 / fs)
    if max % 2 == 0 then
        max = max - 1
    end
    local delta = math.ceil(max / 2) - 1
    local begi = math.max(math.min(pos - delta, count - max + 1), 1)
    local endi = math.min(begi + max - 1, count)

    local reslist = {}
    for i=begi, endi do
        local item = proplist[i]
        item.current = (i == pos) and true or nil
        table.insert(reslist, item)
    end
    return count, reslist
end

function get_playlist()
    local pos = mp.get_property_number('playlist-pos', 0) + 1
    local count, limlist = limited_list('playlist', pos)
    if count == 0 then
        return texts.playlist .. ': ' .. texts.none
    end

    local message = string.format(texts.playlist .. ' [%d/%d]:\n', pos, count)
    for i, v in ipairs(limlist) do
        local title = v.title
        local _, filename = utils.split_path(v.filename)
        if title == nil then
            title = filename
        end
        message = string.format('%s %s %s. %s\n', message,
            (v.current and '●' or '○'), i, title)
    end
    return message
end

function get_chapterlist()
    local pos = mp.get_property_number('chapter', 0) + 1
    local count, limlist = limited_list('chapter-list', pos)
    if count == 0 then
        return texts.chapters .. ': ' .. texts.none
    end

    local message = string.format(texts.chapters .. ' [%d/%d]:\n', pos, count)
    for i, v in ipairs(limlist) do
        local time = mp.format_time(v.time)
        local title = v.title
        if title == nil then
            title = string.format(texts.chapter .. ' %02d', i)
        end
        message = string.format('%s %s [%s] %s\n', message,
            (v.current and '●' or '○'), time, title)
    end
    return message
end

function show_message(text, duration)

    --print("text: "..text.."   duration: " .. duration)
    if duration == nil then
        duration = tonumber(mp.get_property("options/osd-duration")) / 1000
    elseif not type(duration) == "number" then
        print("duration: " .. duration)
    end

    -- cut the text short, otherwise the following functions
    -- may slow down massively on huge input
    text = string.sub(text, 0, 4000)

    -- replace actual linebreaks with ASS linebreaks
    text = string.gsub(text, "\n", "\\N")

    state.message_text = text

    if not state.message_hide_timer then
        state.message_hide_timer = mp.add_timeout(0, request_tick)
    end
    state.message_hide_timer:kill()
    state.message_hide_timer.timeout = duration
    state.message_hide_timer:resume()
    request_tick()
end

function render_message(ass)
    if state.message_hide_timer and state.message_hide_timer:is_enabled() and
       state.message_text
    then
        local _, lines = string.gsub(state.message_text, "\\N", "")

        local fontsize = tonumber(mp.get_property("options/osd-font-size"))
        local outline = tonumber(mp.get_property("options/osd-border-size"))
        local maxlines = math.ceil(osc_param.unscaled_y*0.75 / fontsize)
        local counterscale = osc_param.playresy / osc_param.unscaled_y

        fontsize = fontsize * counterscale / math.max(0.65 + math.min(lines/maxlines, 1), 1)
        outline = outline * counterscale / math.max(0.75 + math.min(lines/maxlines, 1)/2, 1)

        local style = "{\\bord" .. outline .. "\\fs" .. fontsize .. "}"


        ass:new_event()
        ass:append(style .. state.message_text)
    else
        state.message_text = nil
    end
end

--
-- Initialisation and Layout
--

function new_element(name, type)
    elements[name] = {}
    elements[name].type = type

    -- add default stuff
    elements[name].eventresponder = {}
    elements[name].visible = true
    elements[name].enabled = true
    elements[name].softrepeat = false
    elements[name].styledown = (type == "button")
    elements[name].state = {}

    if (type == "slider") then
        elements[name].slider = {min = {value = 0}, max = {value = 100}}
    end


    return elements[name]
end

function add_layout(name)
    if not (elements[name] == nil) then
        -- new layout
        elements[name].layout = {}

        -- set layout defaults
        elements[name].layout.layer = 50
        elements[name].layout.alpha = {[1] = 0, [2] = 255, [3] = 255, [4] = 255}

        if (elements[name].type == "button") then
            elements[name].layout.button = {
                maxchars = nil,
            }
        elseif (elements[name].type == "slider") then
            -- slider defaults
            elements[name].layout.slider = {
                border = 1,
                gap = 1,
                pad = 0,
                handle_size = 16,
                bar_height = 4,
                bg_style = "",
                bg_alpha = 192,
                nibbles_top = false,
                nibbles_bottom = true,
                adjust_tooltip = true,
                tooltip_style = "",
                tooltip_an = 2,
                alpha = {[1] = 0, [2] = 255, [3] = 88, [4] = 255},
            }
        elseif (elements[name].type == "box") then
            elements[name].layout.box = {radius = 0, hexagon = false}
        end

        return elements[name].layout
    else
        msg.error("Can't add_layout to element \""..name.."\", doesn't exist.")
    end
end

-- Window Controls
function window_controls()
    local wc_geo = {
        x = 0,
        y = 32,
        an = 1,
        w = osc_param.playresx,
        h = 32,
    }

    local alignment = window_controls_alignment()
    local controlbox_w = window_control_box_width
    local titlebox_w = wc_geo.w - controlbox_w

    -- Default alignment is "right"
    local controlbox_left = wc_geo.w - controlbox_w
    local titlebox_left = wc_geo.x
    local titlebox_right = wc_geo.w - controlbox_w

    if alignment == "left" then
        controlbox_left = wc_geo.x
        titlebox_left = wc_geo.x + controlbox_w
        titlebox_right = wc_geo.w
    end

    add_area("window-controls",
             get_hitbox_coords(controlbox_left, wc_geo.y, wc_geo.an,
                               controlbox_w, wc_geo.h))

    local lo

    -- Background Bar
    new_element("wcbar", "box")
    lo = add_layout("wcbar")
    lo.geometry = {
        x = wc_geo.x - 200,
        y = 0,
        an = 4,
        w = wc_geo.w + 400,
        h = 160,
    }
    lo.layer = 10
    lo.style = osc_styles.box
    lo.alpha[1] = 0
    lo.alpha[3] = 0

    local button_y = wc_geo.y - (wc_geo.h / 2)
    local first_geo =
        {x = controlbox_left + 27, y = button_y, an = 5, w = 40, h = wc_geo.h}
    local second_geo =
        {x = controlbox_left + 69, y = button_y, an = 5, w = 40, h = wc_geo.h}
    local third_geo =
        {x = controlbox_left + 115, y = button_y, an = 5, w = 40, h = wc_geo.h}

    -- Window control buttons use symbols in the custom mpv osd font
    -- because the official unicode codepoints are sufficiently
    -- exotic that a system might lack an installed font with them,
    -- and libass will complain that they are not present in the
    -- default font, even if another font with them is available.

    -- Close: 🗙
    ne = new_element("close", "button")
    ne.content = icons.close
    ne.eventresponder["mbtn_left_up"] =
        function () mp.commandv("quit") end
    lo = add_layout("close")
    lo.geometry = alignment == "left" and first_geo or third_geo
    lo.style = osc_styles.button

    -- Minimize: 🗕
    ne = new_element("minimize", "button")
    ne.content = icons.minimize
    ne.eventresponder["mbtn_left_up"] =
        function () mp.commandv("cycle", "window-minimized") end
    lo = add_layout("minimize")
    lo.geometry = alignment == "left" and second_geo or first_geo
    lo.style = osc_styles.button

    -- Maximize: 🗖 /🗗
    ne = new_element("maximize", "button")
    if state.maximized or state.fullscreen then
        ne.content = icons.maximize_exit
    else
        ne.content = icons.maximize
    end
    ne.eventresponder["mbtn_left_up"] =
        function ()
            if state.fullscreen then
                mp.commandv("cycle", "fullscreen")
            else
                mp.commandv("cycle", "window-maximized")
            end
        end
    lo = add_layout("maximize")
    lo.geometry = alignment == "left" and third_geo or second_geo
    lo.style = osc_styles.button

    -- deadzone below window controls
    local sh_area_y0, sh_area_y1
    sh_area_y0 = 0
    sh_area_y1 = osc_param.playresy * (1 - user_opts.deadzonesize)
    add_area("showhide_wc", wc_geo.x, sh_area_y0, wc_geo.w, sh_area_y1)

    -- Window Title
    ne = new_element("wctitle", "button")
    ne.content = function ()
        local title = mp.command_native({"expand-text", user_opts.title})
        -- escape ASS, and strip newlines and trailing slashes
        title = title:gsub("\\n", " "):gsub("\\$", ""):gsub("{","\\{")
        return not (title == "") and title or "mpv"
    end
    local left_pad = 16
    local right_pad = 8
    lo = add_layout("wctitle")
    lo.geometry =
        { x = titlebox_left + left_pad, y = wc_geo.y, an = 1,
          w = titlebox_w, h = wc_geo.h }
    lo.style = string.format("%s{\\clip(%f,%f,%f,%f)}",
        osc_styles.title,
        titlebox_left + left_pad, wc_geo.y - wc_geo.h,
        titlebox_right - right_pad , wc_geo.y + wc_geo.h)

    add_area("window-controls-title",
             titlebox_left, 0, titlebox_right, wc_geo.h)
end

--
-- Layouts
--

function layouts()
    local osc_geo = {
        x = 0,
        y = osc_param.playresy,
        an = 1,
        w = osc_param.playresx,
        h = 72,
    }

    local refX = osc_geo.w / 2
    local refY = osc_geo.y

    local btnY = refY - 28
    local btnW = 40
    local btnH = 56
    local tcW = osc_geo.w - 520

    osc_param.areas = {} -- delete areas

    -- area for active mouse input
    add_area("input", get_hitbox_coords(osc_geo.x, osc_geo.y, osc_geo.an,
                                        osc_geo.w, osc_geo.h))

    -- deadzone above OSC
    local sh_area_y0, sh_area_y1
    sh_area_y0 = osc_param.playresy * user_opts.deadzonesize
    sh_area_y1 = osc_param.playresy
    add_area("showhide", 0, sh_area_y0, osc_param.playresx, sh_area_y1)

    local lo, geo

    -- Background bar
    new_element("bgbox", "box")
    lo = add_layout("bgbox")
    lo.geometry = {
        x = osc_geo.x - 200,
        y = osc_geo.y,
        an = 4,
        w = osc_geo.w + 400,
        h = 160,
    }
    lo.layer = 10
    lo.style = osc_styles.box
    lo.alpha[3] = 0

    -- Seekbar
    lo = add_layout("seekbar")
    lo.geometry = {x = refX, y = refY - 64, an = 5, w = osc_geo.w - 40, h = 16}
    lo.style = osc_styles.seekbar_fg
    lo.slider.gap = 7
    lo.slider.pad = 0
    lo.slider.handle_size = 16
    lo.slider.bar_height = 2
    lo.slider.bg_style = osc_styles.seekbar_bg
    lo.slider.bg_alpha = 192
    lo.slider.tooltip_style = osc_styles.tooltip

    -- Volumebar
    lo = add_layout("volumebar")
    lo.geometry = {x = 248, y = btnY, an = 4, w = 80, h = btnH}
    lo.style = osc_styles.volumebar_fg
    lo.slider.gap = 3
    lo.slider.pad = 0
    lo.slider.handle_size = 12
    lo.slider.bar_height = 2
    lo.slider.bg_style = osc_styles.volumebar_bg
    lo.slider.bg_alpha = 192
    lo.slider.tooltip_style = osc_styles.tooltip
    lo.slider.adjust_tooltip = false

    -- buttons
    lo = add_layout("pl_prev")
    lo.geometry = {x = 28, y = btnY, an = 5, w = btnW, h = btnH}
    lo.style = osc_styles.button

    lo = add_layout("skipback")
    lo.geometry = {x = 68, y = btnY, an = 5, w = btnW, h = btnH}
    lo.style = osc_styles.button

    lo = add_layout("playpause")
    lo.geometry = {x = 108, y = btnY, an = 5, w = btnW, h = btnH}
    lo.style = osc_styles.button

    lo = add_layout("skipfrwd")
    lo.geometry = {x = 148, y = btnY, an = 5, w = btnW, h = btnH}
    lo.style = osc_styles.button

    lo = add_layout("pl_next")
    lo.geometry = {x = 188, y = btnY, an = 5, w = btnW, h = btnH}
    lo.style = osc_styles.button

    -- Timecode
    lo = add_layout("timecode")
    lo.geometry = {x = 340, y = btnY, an = 4, w = tcW, h = btnH}
    lo.style = osc_styles.timecode
    lo.button.maxchars = tcW / 6

    lo = add_layout("cy_audio")
    lo.geometry = {x = osc_geo.w - 108, y = btnY, an = 5, w = btnW, h = btnH}
    lo.style = osc_styles.button

    lo = add_layout("cy_sub")
    lo.geometry = {x = osc_geo.w - 148, y = btnY, an = 5, w = btnW, h = btnH}
    lo.style = osc_styles.button

    -- Subtitle marker
    lo = new_element("sub_marker", "box")
    lo.visible = (get_track("sub") > 0) and (osc_param.playresx >= 496)
    lo = add_layout("sub_marker")
    lo.geometry = {x = osc_geo.w - 148, y = btnY + 13, an = 5, w = 24, h = 2}
    lo.style = osc_styles.seekbar_fg

    lo = add_layout("volume")
    lo.geometry = {x = 228, y = btnY, an = 5, w = btnW, h = btnH}
    lo.style = osc_styles.button

    lo = add_layout("tog_fs")
    lo.geometry = {x = osc_geo.w - 28, y = btnY, an = 5, w = btnW, h = btnH}
    lo.style = osc_styles.button

    lo = add_layout("tog_info")
    lo.geometry = {x = osc_geo.w - 68, y = btnY, an = 5, w = btnW, h = btnH}
    lo.style = osc_styles.button
end

-- Validate string type user options
function validate_user_opts()
    if user_opts.windowcontrols ~= "auto" and
       user_opts.windowcontrols ~= "yes" and
       user_opts.windowcontrols ~= "no" then
        msg.warn("windowcontrols cannot be \"" ..
                user_opts.windowcontrols .. "\". Ignoring.")
        user_opts.windowcontrols = "auto"
    end
    if user_opts.windowcontrols_alignment ~= "right" and
       user_opts.windowcontrols_alignment ~= "left" then
        msg.warn("windowcontrols_alignment cannot be \"" ..
                user_opts.windowcontrols_alignment .. "\". Ignoring.")
        user_opts.windowcontrols_alignment = "right"
    end
end

function update_options(list)
    validate_user_opts()
    request_tick()
    visibility_mode(user_opts.visibility, true)
    update_duration_watch()
    request_init()
end

local UNICODE_MINUS = string.char(0xe2, 0x88, 0x92)  -- UTF-8 for U+2212 MINUS SIGN

-- OSC INIT
function osc_init()
    msg.debug("osc_init")

    -- set canvas resolution according to display aspect and scaling setting
    local baseResY = 720
    local display_w, display_h, display_aspect = mp.get_osd_size()
    local scale = 1

    if (mp.get_property("video") == "no") then -- dummy/forced window
        scale = user_opts.scaleforcedwindow
    elseif state.fullscreen then
        scale = user_opts.scalefullscreen
    else
        scale = user_opts.scalewindowed
    end

    if user_opts.vidscale then
        osc_param.unscaled_y = baseResY
    else
        osc_param.unscaled_y = display_h
    end
    osc_param.playresy = osc_param.unscaled_y / scale
    if (display_aspect > 0) then
        osc_param.display_aspect = display_aspect
    end
    osc_param.playresx = osc_param.playresy * osc_param.display_aspect

    -- stop seeking with the slider to prevent skipping files
    state.active_element = nil

    osc_param.video_margins = {l = 0, r = 0, t = 0, b = 0}

    elements = {}

    -- some often needed stuff
    local pl_count = mp.get_property_number("playlist-count", 0)
    local have_pl = (pl_count > 1)
    local pl_pos = mp.get_property_number("playlist-pos", 0) + 1
    local have_ch = (mp.get_property_number("chapters", 0) > 0)
    local loop = mp.get_property("loop-playlist", "no")

    local ne

    -- playlist buttons

    -- prev
    ne = new_element("pl_prev", "button")

    ne.content = icons.pl_prev
    ne.enabled = (pl_pos > 1) or (loop ~= "no")
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = "Previous"
    ne.eventresponder["mbtn_left_up"] =
        function ()
            mp.commandv("playlist-prev", "weak")
        end
    ne.eventresponder["shift+mbtn_left_up"] =
        function () show_message(get_playlist(), 3) end
    ne.eventresponder["mbtn_right_up"] =
        function () show_message(get_playlist(), 3) end

    --next
    ne = new_element("pl_next", "button")

    ne.content = icons.pl_next
    ne.enabled = (have_pl and (pl_pos < pl_count)) or (loop ~= "no")
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = "Next"
    ne.eventresponder["mbtn_left_up"] =
        function ()
            mp.commandv("playlist-next", "weak")
        end
    ne.eventresponder["shift+mbtn_left_up"] =
        function () show_message(get_playlist(), 3) end
    ne.eventresponder["mbtn_right_up"] =
        function () show_message(get_playlist(), 3) end


    --play control buttons

    --playpause
    ne = new_element("playpause", "button")

    ne.content = function ()
        if mp.get_property("pause") == "yes" then
            return icons.play
        else
            return icons.pause
        end
    end
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = function ()
        if mp.get_property("pause") == "yes" then
            return "Play"
        else
            return "Pause"
        end
    end
    ne.eventresponder["mbtn_left_up"] =
        function () mp.commandv("cycle", "pause") end
    --ne.eventresponder["mbtn_right_up"] =
    --    function () mp.commandv("script-binding", "open-file-dialog") end

    --skipback
    ne = new_element("skipback", "button")

    ne.softrepeat = true
    ne.content = icons.skipback
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = "Seek backward"
    ne.eventresponder["mbtn_left_down"] =
        function () mp.commandv("seek", -5, "exact") end
    ne.eventresponder["shift+mbtn_left_down"] =
        function () mp.commandv("frame-back-step") end
    ne.eventresponder["mbtn_right_down"] =
        function () mp.commandv("seek", -60, "exact") end

    --skipfrwd
    ne = new_element("skipfrwd", "button")

    ne.softrepeat = true
    ne.content = icons.skipfrwd
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = "Seek forward"
    ne.eventresponder["mbtn_left_down"] =
        function () mp.commandv("seek", 5, "exact") end
    ne.eventresponder["shift+mbtn_left_down"] =
        function () mp.commandv("frame-step") end
    ne.eventresponder["mbtn_right_down"] =
        function () mp.commandv("seek", 60, "exact") end

    --
    update_tracklist()

    --cy_audio
    ne = new_element("cy_audio", "button")
    ne.enabled = (#tracks_osc.audio > 1)
    ne.visible = (osc_param.playresx >= 456)
    ne.content = icons.cy_audio
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = function ()
        local msg = texts.off
        if not (get_track("audio") == 0) then
            local lang = mp.get_property("current-tracks/audio/lang") or texts.unknown
            local title = mp.get_property("current-tracks/audio/title")
            if title then
                msg = title
            else
                msg = "[" .. lang .. "]"
            end
        end
        return texts.audio_track .. ": " .. msg
    end
    ne.eventresponder["mbtn_left_up"] =
        function () set_track("audio", 1) end
    ne.eventresponder["mbtn_right_up"] =
        function () set_track("audio", -1) end
    ne.eventresponder["shift+mbtn_left_up"] =
        function () show_message(get_tracklist("audio"), 2) end
    ne.eventresponder["wheel_up_press"] =
        function () set_track("audio", -1) end
    ne.eventresponder["wheel_down_press"] =
        function () set_track("audio", 1) end

    --cy_sub
    ne = new_element("cy_sub", "button")
    ne.enabled = (#tracks_osc.sub > 0)
    ne.visible = (osc_param.playresx >= 496)
    ne.content = icons.cy_sub
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = function ()
        local msg = texts.off
        if not (get_track("sub") == 0) then
            local lang = mp.get_property("current-tracks/sub/lang") or texts.unknown
            local title = mp.get_property("current-tracks/sub/title")
            if title then
                msg = title
            else
                msg = "[" .. lang .. "]"
            end
        end
        return texts.subtitle .. ": " .. msg
    end
    ne.eventresponder["mbtn_left_up"] =
        function () set_track("sub", 1) end
    ne.eventresponder["mbtn_right_up"] =
        function () set_track("sub", -1) end
    ne.eventresponder["shift+mbtn_left_up"] =
        function () show_message(get_tracklist("sub"), 2) end
    ne.eventresponder["wheel_up_press"] =
        function () set_track("sub", -1) end
    ne.eventresponder["wheel_down_press"] =
        function () set_track("sub", 1) end

    -- volume
    ne = new_element("volume", "button")
    ne.enabled = (#tracks_osc.audio > 0)
    ne.content = function ()
        local volume = mp.get_property_number("volume", 0)
        local volicon = {icons.volume_low, icons.volume_medium,
                         icons.volume_high, icons.volume_over}
        if volume == 0 or state.mute then
            return icons.volume_mute
        else
            return volicon[math.min(4,math.ceil(volume / (100/3)))]
        end
    end
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = function ()
        if state.mute then
            return "Unmute"
        else
            return "Mute"
        end
    end
    ne.eventresponder["mbtn_left_up"] =
        function () mp.commandv("cycle", "mute") end

    ne.eventresponder["wheel_up_press"] =
        function ()
            if state.mute then
                mp.commandv("cycle", "mute")
            end
            mp.commandv("osd-msg", "add", "volume", 5)
        end
    ne.eventresponder["wheel_down_press"] =
        function ()
            if state.mute then
                mp.commandv("cycle", "mute")
            end
            mp.commandv("osd-msg", "add", "volume", -5)
        end

    --tog_fs
    ne = new_element("tog_fs", "button")
    ne.content = function ()
        if (state.fullscreen) then
            return icons.fs_exit
        else
            return icons.fs_enter
        end
    end
    ne.visible = (osc_param.playresx >= 376)
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = function ()
        if (state.fullscreen) then
            return "Exit full screen"
        else
            return "Full screen"
        end
    end
    ne.eventresponder["mbtn_left_up"] =
        function () mp.commandv("cycle", "fullscreen") end

    --tog_info
    ne = new_element("tog_info", "button")
    ne.content = icons.info
    ne.visible = (osc_param.playresx >= 416)
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = "Information"
    ne.eventresponder["mbtn_left_up"] =
        function () mp.commandv("script-binding", "stats/display-stats-toggle") end

    --seekbar
    ne = new_element("seekbar", "slider")

    ne.enabled = not (mp.get_property("percent-pos") == nil)
    ne.thumbnail = true
    ne.slider.markerF = function ()
        local duration = mp.get_property_number("duration", nil)
        if not (duration == nil) then
            local chapters = mp.get_property_native("chapter-list", {})
            local markers = {}
            for n = 1, #chapters do
                markers[n] = (chapters[n].time / duration * 100)
            end
            return markers
        else
            return {}
        end
    end
    ne.slider.posF =
        function () return mp.get_property_number("percent-pos", nil) end
    ne.slider.tooltipF = function (pos)
        local duration = mp.get_property_number("duration", nil)
        if not ((duration == nil) or (pos == nil)) then
            local possec = duration * (pos / 100)
            local chapters = mp.get_property_native("chapter-list", {})
            if #chapters > 0 then
                local ch = #chapters
                local i
                for i = 1, #chapters do
                    if chapters[i].time / duration * 100 >= pos then
                        ch = i - 1
                        break
                    end
                end
                if ch == 0 then
                    return mp.format_time(possec)
                elseif chapters[ch].title then
                    return mp.format_time(possec) .. " • " .. chapters[ch].title
                end
            end
            return mp.format_time(possec)
        else
            return ""
        end
    end
    ne.slider.seekRangesF = function()
        if not user_opts.seekrange then
            return nil
        end
        local cache_state = state.cache_state
        if not cache_state then
            return nil
        end
        local duration = mp.get_property_number("duration", nil)
        if (duration == nil) or duration <= 0 then
            return nil
        end
        local ranges = cache_state["seekable-ranges"]
        if #ranges == 0 then
            return nil
        end
        local nranges = {}
        for _, range in pairs(ranges) do
            nranges[#nranges + 1] = {
                ["start"] = 100 * range["start"] / duration,
                ["end"] = 100 * range["end"] / duration,
            }
        end
        return nranges
    end
    ne.eventresponder["mouse_move"] = --keyframe seeking when mouse is dragged
        function (element)
            if not element.state.mbtnleft then return end -- allow drag for mbtnleft only!

            -- mouse move events may pile up during seeking and may still get
            -- sent when the user is done seeking, so we need to throw away
            -- identical seeks
            local seekto = get_slider_value(element)
            if (element.state.lastseek == nil) or
                (not (element.state.lastseek == seekto)) then
                    local flags = "absolute-percent"
                    if not user_opts.seekbarkeyframes then
                        flags = flags .. "+exact"
                    end
                    mp.commandv("seek", seekto, flags)
                    element.state.lastseek = seekto
            end

        end
    ne.eventresponder["mbtn_left_down"] = --exact seeks on single clicks
        function (element)
            mp.commandv("seek", get_slider_value(element), "absolute-percent", "exact")
            element.state.mbtnleft = true
        end
    ne.eventresponder["mbtn_left_up"] =
        function (element) element.state.mbtnleft = false end
    ne.eventresponder["mbtn_right_down"] = --seeks to chapter start
        function (element)
            local duration = mp.get_property_number("duration", nil)
            if not (duration == nil) then
                local chapters = mp.get_property_native("chapter-list", {})
                if #chapters > 0 then
                    local pos = get_slider_value(element)
                    local ch = #chapters
                    for n = 1, ch do
                        if chapters[n].time / duration * 100 >= pos then
                            ch = n - 1
                            break
                        end
                    end
                    mp.commandv("set", "chapter", ch - 1)
                end
            end
        end
    ne.eventresponder["wheel_up_press"] =
        function () mp.commandv("seek", 5, "relative-percent", "exact") end
    ne.eventresponder["wheel_down_press"] =
        function () mp.commandv("seek", -5, "relative-percent", "exact") end
    ne.eventresponder["reset"] =
        function (element) element.state.lastseek = nil end

    --volumebar
    ne = new_element("volumebar", "slider")
    ne.enabled = (#tracks_osc.audio > 0)
    ne.slider.tooltipF =
        function ()
            return "Volume"
        end
    ne.slider.markerF = nil
    ne.slider.seekRangesF = nil
    ne.slider.posF =
        function () return mp.get_property_number("volume", 0) end
    ne.eventresponder["mouse_move"] = --volume seeking when mouse is dragged
        function (element)
            local seekto = get_slider_value(element)
            if (element.state.lastseek == nil) or
                (not (element.state.lastseek == seekto)) then
                    mp.commandv("osd-msg", "set", "volume", seekto)
                    element.state.lastseek = seekto
            end
        end
    ne.eventresponder["mbtn_left_down"] = --exact seeks on single clicks
        function (element)
            if state.mute then
                mp.commandv("cycle", "mute")
            end
            mp.commandv("osd-msg", "set", "volume", get_slider_value(element))
        end
    ne.eventresponder["wheel_up_press"] =
        function ()
            if state.mute then
                mp.commandv("cycle", "mute")
            end
            mp.commandv("osd-msg", "add", "volume", 5)
        end
    ne.eventresponder["wheel_down_press"] =
        function ()
            if state.mute then
                mp.commandv("cycle", "mute")
            end
            mp.commandv("osd-msg", "add", "volume", -5)
        end
    ne.eventresponder["reset"] =
        function (element) element.state.lastseek = nil end

    -- timecode (current pos + total/remaining time)
    ne = new_element("timecode", "button")

    ne.visible = (mp.get_property_number("duration", 0) > 0) and (osc_param.playresx >= 560)
    ne.content = function ()
        local possec = mp.get_property_number("playback-time", 0)
        local ch = get_chapter(possec)
        local chapter_title = ""
        if ch and ch.title and ch.title ~= "" then
            chapter_title = " • " .. ch.title
        end
        if (state.rightTC_trem) then
            local minus = user_opts.unicodeminus and UNICODE_MINUS or "-"
            if state.tc_ms then
                return (mp.get_property_osd("playback-time/full") .. " / "
                    .. minus .. mp.get_property_osd("playtime-remaining/full")
                    .. chapter_title)
            else
                return (mp.get_property_osd("playback-time") .. " / "
                    .. minus .. mp.get_property_osd("playtime-remaining")
                    .. chapter_title)
            end
        else
            if state.tc_ms then
                return (mp.get_property_osd("playback-time/full") .. " / "
                    .. mp.get_property_osd("duration/full")
                    .. chapter_title)
            else
                return (mp.get_property_osd("playback-time") .. " / "
                    .. mp.get_property_osd("duration")
                    .. chapter_title)
            end
        end
    end
    ne.eventresponder["mbtn_left_up"] =
        function () state.rightTC_trem = not state.rightTC_trem end
    ne.eventresponder["mbtn_right_up"] = function ()
        state.tc_ms = not state.tc_ms
        request_init()
    end

    -- load layout
    layouts()

    -- load window controls
    if window_controls_enabled() then
        window_controls()
    end

    --do something with the elements
    prepare_elements()

    update_margins()
end

function reset_margins()
    if state.using_video_margins then
        for _, opt in ipairs(margins_opts) do
            mp.set_property_number(opt[2], 0.0)
        end
        state.using_video_margins = false
    end
end

function update_margins()
    local margins = osc_param.video_margins

    -- Don't use margins if it's visible only temporarily.
    if (not state.osc_visible) or (get_hidetimeout() >= 0) or
       (state.fullscreen and not user_opts.showfullscreen) or
       (not state.fullscreen and not user_opts.showwindowed)
    then
        margins = {l = 0, r = 0, t = 0, b = 0}
    end

    if user_opts.boxvideo then
        -- check whether any margin option has a non-default value
        local margins_used = false

        if not state.using_video_margins then
            for _, opt in ipairs(margins_opts) do
                if mp.get_property_number(opt[2], 0.0) ~= 0.0 then
                    margins_used = true
                end
            end
        end

        if not margins_used then
            for _, opt in ipairs(margins_opts) do
                local v = margins[opt[1]]
                if (v ~= 0) or state.using_video_margins then
                    mp.set_property_number(opt[2], v)
                    state.using_video_margins = true
                end
            end
        end
    else
        reset_margins()
    end

    utils.shared_script_property_set("osc-margins",
        string.format("%f,%f,%f,%f", margins.l, margins.r, margins.t, margins.b))
    -- mp.set_property_native("user-data/osc/margins", margins)
end

function shutdown()
    reset_margins()
    utils.shared_script_property_set("osc-margins", nil)
    -- mp.del_property("user-data/osc")
end

--
-- Other important stuff
--


function show_osc()
    -- show when disabled can happen (e.g. mouse_move) due to async/delayed unbinding
    if not state.enabled then return end

    msg.trace("show_osc")
    --remember last time of invocation (mouse move)
    state.showtime = mp.get_time()

    if (user_opts.fadeduration > 0) then
        if not(state.osc_visible == false) and not state.animation then
            state.anitype = nil
        else
            state.anitype = "in"
        end
    else
        osc_visible(true)
    end
end

function hide_osc()
    msg.trace("hide_osc")
    if not state.enabled then
        -- typically hide happens at render() from tick(), but now tick() is
        -- no-op and won't render again to remove the osc, so do that manually.
        state.osc_visible = false
        render_wipe()
    elseif (user_opts.fadeduration > 0) then
        if not(state.osc_visible == false) then
            state.anitype = "out"
            request_tick()
        end
    else
        osc_visible(false)
    end
end

function osc_visible(visible)
    if state.osc_visible ~= visible then
        state.osc_visible = visible
        update_margins()
    end
    request_tick()
end

function pause_state(name, enabled)
    state.paused = enabled
    state.showtime = mp.get_time()
    if enabled then
        visibility_mode("always", true)
    else
        visibility_mode(state.last_visibility, true)
    end
    request_tick()
end

function cache_state(name, st)
    state.cache_state = st
    request_tick()
end

-- Request that tick() is called (which typically re-renders the OSC).
-- The tick is then either executed immediately, or rate-limited if it was
-- called a small time ago.
function request_tick()
    if state.tick_timer == nil then
        state.tick_timer = mp.add_timeout(0, tick)
    end

    if not state.tick_timer:is_enabled() then
        local now = mp.get_time()
        local timeout = tick_delay - (now - state.tick_last_time)
        if timeout < 0 then
            timeout = 0
        end
        state.tick_timer.timeout = timeout
        state.tick_timer:resume()
    end
end

function mouse_leave()
    if get_hidetimeout() >= 0 then
        hide_osc()
    end
    -- reset mouse position
    state.last_mouseX, state.last_mouseY = nil, nil
    state.mouse_in_window = false
end

function request_init()
    state.initREQ = true
    request_tick()
end

-- Like request_init(), but also request an immediate update
function request_init_resize()
    request_init()
    -- ensure immediate update
    state.tick_timer:kill()
    state.tick_timer.timeout = 0
    state.tick_timer:resume()
end

function render_wipe()
    msg.trace("render_wipe()")
    state.osd.data = "" -- allows set_osd to immediately update on enable
    state.osd:remove()
end

function render()
    msg.trace("rendering")
    local current_screen_sizeX, current_screen_sizeY, aspect = mp.get_osd_size()
    local mouseX, mouseY = get_virt_mouse_pos()
    local now = mp.get_time()

    -- check if display changed, if so request reinit
    if not (state.mp_screen_sizeX == current_screen_sizeX
        and state.mp_screen_sizeY == current_screen_sizeY) then

        request_init_resize()

        state.mp_screen_sizeX = current_screen_sizeX
        state.mp_screen_sizeY = current_screen_sizeY
    end

    -- init management
    if state.active_element then
        -- mouse is held down on some element - keep ticking and igore initReq
        -- till it's released, or else the mouse-up (click) will misbehave or
        -- get ignored. that's because osc_init() recreates the osc elements,
        -- but mouse handling depends on the elements staying unmodified
        -- between mouse-down and mouse-up (using the index active_element).
        request_tick()
    elseif state.initREQ then
        osc_init()
        state.initREQ = false

        -- store initial mouse position
        if (state.last_mouseX == nil or state.last_mouseY == nil)
            and not (mouseX == nil or mouseY == nil) then

            state.last_mouseX, state.last_mouseY = mouseX, mouseY
        end
    end


    -- fade animation
    if not(state.anitype == nil) then

        if (state.anistart == nil) then
            state.anistart = now
        end

        if (now < state.anistart + (user_opts.fadeduration/1000)) then

            if (state.anitype == "in") then --fade in
                osc_visible(true)
                state.animation = scale_value(state.anistart,
                    (state.anistart + (user_opts.fadeduration/1000)),
                    255, 0, now)
            elseif (state.anitype == "out") then --fade out
                state.animation = scale_value(state.anistart,
                    (state.anistart + (user_opts.fadeduration/1000)),
                    0, 255, now)
            end

        else
            if (state.anitype == "out") then
                osc_visible(false)
            end
            kill_animation()
        end
    else
        kill_animation()
    end

    --mouse show/hide area
    for k,cords in pairs(osc_param.areas["showhide"]) do
        set_virt_mouse_area(cords.x1, cords.y1, cords.x2, cords.y2, "showhide")
    end
    if osc_param.areas["showhide_wc"] then
        for k,cords in pairs(osc_param.areas["showhide_wc"]) do
            set_virt_mouse_area(cords.x1, cords.y1, cords.x2, cords.y2, "showhide_wc")
        end
    else
        set_virt_mouse_area(0, 0, 0, 0, "showhide_wc")
    end
    do_enable_keybindings()

    --mouse input area
    local mouse_over_osc = false

    for _,cords in ipairs(osc_param.areas["input"]) do
        if state.osc_visible then -- activate only when OSC is actually visible
            set_virt_mouse_area(cords.x1, cords.y1, cords.x2, cords.y2, "input")
        end
        if state.osc_visible ~= state.input_enabled then
            if state.osc_visible then
                mp.enable_key_bindings("input")
            else
                mp.disable_key_bindings("input")
            end
            state.input_enabled = state.osc_visible
        end

        if (mouse_hit_coords(cords.x1, cords.y1, cords.x2, cords.y2)) then
            mouse_over_osc = true
        end
    end

    if osc_param.areas["window-controls"] then
        for _,cords in ipairs(osc_param.areas["window-controls"]) do
            if state.osc_visible then -- activate only when OSC is actually visible
                set_virt_mouse_area(cords.x1, cords.y1, cords.x2, cords.y2, "window-controls")
            end
            if state.osc_visible ~= state.windowcontrols_buttons then
                if state.osc_visible then
                    mp.enable_key_bindings("window-controls")
                else
                    mp.disable_key_bindings("window-controls")
                end
                state.windowcontrols_buttons = state.osc_visible
            end

            if (mouse_hit_coords(cords.x1, cords.y1, cords.x2, cords.y2)) then
                mouse_over_osc = true
            end
        end
    end

    if osc_param.areas["window-controls-title"] then
        for _,cords in ipairs(osc_param.areas["window-controls-title"]) do
            if (mouse_hit_coords(cords.x1, cords.y1, cords.x2, cords.y2)) then
                mouse_over_osc = true
            end
        end
    end

    -- autohide
    if not (state.showtime == nil) and (get_hidetimeout() >= 0) then
        local timeout = state.showtime + (get_hidetimeout()/1000) - now
        if timeout <= 0 then
            if (state.active_element == nil) and not (mouse_over_osc) then
                hide_osc()
            end
        else
            -- the timer is only used to recheck the state and to possibly run
            -- the code above again
            if not state.hide_timer then
                state.hide_timer = mp.add_timeout(0, tick)
            end
            state.hide_timer.timeout = timeout
            -- re-arm
            state.hide_timer:kill()
            state.hide_timer:resume()
        end
    end


    -- actual rendering
    local ass = assdraw.ass_new()

    -- Messages
    render_message(ass)

    -- actual OSC
    if state.osc_visible then
        render_elements(ass)
    end

    -- submit
    set_osd(osc_param.playresy * osc_param.display_aspect,
            osc_param.playresy, ass.text)
end

--
-- Eventhandling
--

local function element_has_action(element, action)
    return element and element.eventresponder and
        element.eventresponder[action]
end

function process_event(source, what)
    local action = string.format("%s%s", source,
        what and ("_" .. what) or "")

    if what == "down" or what == "press" then

        for n = 1, #elements do

            if mouse_hit(elements[n]) and
                elements[n].eventresponder and
                (elements[n].eventresponder[source .. "_up"] or
                    elements[n].eventresponder[action]) then

                if what == "down" then
                    state.active_element = n
                    state.active_event_source = source
                end
                -- fire the down or press event if the element has one
                if element_has_action(elements[n], action) then
                    elements[n].eventresponder[action](elements[n])
                end

            end
        end

    elseif what == "up" then

        if elements[state.active_element] then
            local n = state.active_element

            if n == 0 then
                --click on background (does not work)
            elseif element_has_action(elements[n], action) and
                mouse_hit(elements[n]) then

                elements[n].eventresponder[action](elements[n])
            end

            --reset active element
            if element_has_action(elements[n], "reset") then
                elements[n].eventresponder["reset"](elements[n])
            end

        end
        state.active_element = nil
        state.mouse_down_counter = 0

    elseif source == "mouse_move" then

        state.mouse_in_window = true

        local mouseX, mouseY = get_virt_mouse_pos()
        if (user_opts.minmousemove == 0) or
            (not ((state.last_mouseX == nil) or (state.last_mouseY == nil)) and
                ((math.abs(mouseX - state.last_mouseX) >= user_opts.minmousemove)
                    or (math.abs(mouseY - state.last_mouseY) >= user_opts.minmousemove)
                )
            ) then
            show_osc()
        end
        state.last_mouseX, state.last_mouseY = mouseX, mouseY

        local n = state.active_element
        if element_has_action(elements[n], action) then
            elements[n].eventresponder[action](elements[n])
        end
    end

    -- ensure rendering after any (mouse) event - icons could change etc
    request_tick()
end

function show_logo()
    local osd_w, osd_h, osd_aspect = mp.get_osd_size()
    osd_w, osd_h = 360*osd_aspect, 360
    local logo_x, logo_y = osd_w/2, osd_h/2-20
    local ass = assdraw.ass_new()
    ass:new_event()
    ass:pos(logo_x, logo_y)
    ass:append('{\\1c&H8E348D&\\3c&H0&\\3a&H60&\\blur1\\bord0.5}')
    ass:draw_start()
    ass_draw_cir_cw(ass, 0, 0, 100)
    ass:draw_stop()

    ass:new_event()
    ass:pos(logo_x, logo_y)
    ass:append('{\\1c&H632462&\\bord0}')
    ass:draw_start()
    ass_draw_cir_cw(ass, 6, -6, 75)
    ass:draw_stop()

    ass:new_event()
    ass:pos(logo_x, logo_y)
    ass:append('{\\1c&HFFFFFF&\\bord0}')
    ass:draw_start()
    ass_draw_cir_cw(ass, -4, 4, 50)
    ass:draw_stop()

    ass:new_event()
    ass:pos(logo_x, logo_y)
    ass:append('{\\1c&H632462&\\bord&}')
    ass:draw_start()
    ass:move_to(-20, -20)
    ass:line_to(23.3, 5)
    ass:line_to(-20, 30)
    ass:draw_stop()

    ass:new_event()
    ass:pos(logo_x, logo_y+110)
    ass:an(8)
    ass:append(texts.welcome)
    set_osd(osd_w, osd_h, ass.text)
end

-- called by mpv on every frame
function tick()
    if state.marginsREQ == true then
        update_margins()
        state.marginsREQ = false
    end

    if (not state.enabled) then return end

    if (state.idle) then
        show_logo()
        -- render idle message
        msg.trace("idle message")

        if state.showhide_enabled then
            mp.disable_key_bindings("showhide")
            mp.disable_key_bindings("showhide_wc")
            state.showhide_enabled = false
        end


    elseif (state.fullscreen and user_opts.showfullscreen)
        or (not state.fullscreen and user_opts.showwindowed) then

        -- render the OSC
        render()
    else
        -- Flush OSD
        render_wipe()
    end

    state.tick_last_time = mp.get_time()

    if state.anitype ~= nil then
        -- state.anistart can be nil - animation should now start, or it can
        -- be a timestamp when it started. state.idle has no animation.
        if not state.idle and
           (not state.anistart or
            mp.get_time() < 1 + state.anistart + user_opts.fadeduration/1000)
        then
            -- animating or starting, or still within 1s past the deadline
            request_tick()
        else
            kill_animation()
        end
    end
end

function do_enable_keybindings()
    if state.enabled then
        if not state.showhide_enabled then
            mp.enable_key_bindings("showhide", "allow-vo-dragging+allow-hide-cursor")
            mp.enable_key_bindings("showhide_wc", "allow-vo-dragging+allow-hide-cursor")
        end
        state.showhide_enabled = true
    end
end

function enable_osc(enable)
    state.enabled = enable
    if enable then
        do_enable_keybindings()
    else
        hide_osc() -- acts immediately when state.enabled == false
        if state.showhide_enabled then
            mp.disable_key_bindings("showhide")
            mp.disable_key_bindings("showhide_wc")
        end
        state.showhide_enabled = false
    end
end

-- duration is observed for the sole purpose of updating chapter markers
-- positions. live streams with chapters are very rare, and the update is also
-- expensive (with request_init), so it's only observed when we have chapters
-- and the user didn't disable the livemarkers option (update_duration_watch).
function on_duration() request_init() end

local duration_watched = false
function update_duration_watch()
    local want_watch = user_opts.livemarkers and
                       (mp.get_property_number("chapters", 0) or 0) > 0 and
                       true or false  -- ensure it's a boolean

    if (want_watch ~= duration_watched) then
        if want_watch then
            mp.observe_property("duration", nil, on_duration)
        else
            mp.unobserve_property(on_duration)
        end
        duration_watched = want_watch
    end
end

validate_user_opts()
update_duration_watch()

mp.register_event("shutdown", shutdown)
mp.register_event("start-file", request_init)
mp.observe_property("track-list", nil, request_init)
mp.observe_property("playlist", nil, request_init)
mp.observe_property("chapter-list", "native", function(_, list)
    list = list or {}  -- safety, shouldn't return nil
    table.sort(list, function(a, b) return a.time < b.time end)
    state.chapter_list = list
    update_duration_watch()
    request_init()
end)

mp.register_script_message("osc-message", show_message)
mp.register_script_message("osc-chapterlist", function(dur)
    show_message(get_chapterlist(), dur)
end)
mp.register_script_message("osc-playlist", function(dur)
    show_message(get_playlist(), dur)
end)
mp.register_script_message("osc-tracklist", function(dur)
    local msg = {}
    for k,v in pairs(nicetypes) do
        table.insert(msg, get_tracklist(k))
    end
    show_message(table.concat(msg, '\n\n'), dur)
end)

mp.observe_property("mute", "bool",
    function(name, val)
        state.mute = val
    end
)
mp.observe_property("fullscreen", "bool",
    function(name, val)
        state.fullscreen = val
        state.marginsREQ = true
        request_init_resize()
    end
)
mp.observe_property("border", "bool",
    function(name, val)
        state.border = val
        request_init_resize()
    end
)
mp.observe_property("window-maximized", "bool",
    function(name, val)
        state.maximized = val
        request_init_resize()
    end
)
mp.observe_property("idle-active", "bool",
    function(name, val)
        state.idle = val
        request_tick()
    end
)
mp.observe_property("pause", "bool", pause_state)
mp.observe_property("demuxer-cache-state", "native", cache_state)
mp.observe_property("vo-configured", "bool", function(name, val)
    request_tick()
end)
mp.observe_property("playback-time", "number", function(name, val)
    request_tick()
end)
mp.observe_property("osd-dimensions", "native", function(name, val)
    -- (we could use the value instead of re-querying it all the time, but then
    --  we might have to worry about property update ordering)
    request_init_resize()
end)

-- mouse show/hide bindings
mp.set_key_bindings({
    {"mouse_move",              function(e) process_event("mouse_move", nil) end},
    {"mouse_leave",             mouse_leave},
}, "showhide", "force")
mp.set_key_bindings({
    {"mouse_move",              function(e) process_event("mouse_move", nil) end},
    {"mouse_leave",             mouse_leave},
}, "showhide_wc", "force")
do_enable_keybindings()

--mouse input bindings
mp.set_key_bindings({
    {"mbtn_left",           function(e) process_event("mbtn_left", "up") end,
                            function(e) process_event("mbtn_left", "down")  end},
    {"shift+mbtn_left",     function(e) process_event("shift+mbtn_left", "up") end,
                            function(e) process_event("shift+mbtn_left", "down")  end},
    {"mbtn_right",          function(e) process_event("mbtn_right", "up") end,
                            function(e) process_event("mbtn_right", "down")  end},
    -- alias to shift_mbtn_left for single-handed mouse use
    {"mbtn_mid",            function(e) process_event("shift+mbtn_left", "up") end,
                            function(e) process_event("shift+mbtn_left", "down")  end},
    {"wheel_up",            function(e) process_event("wheel_up", "press") end},
    {"wheel_down",          function(e) process_event("wheel_down", "press") end},
    {"mbtn_left_dbl",       "ignore"},
    {"shift+mbtn_left_dbl", "ignore"},
    {"mbtn_right_dbl",      "ignore"},
}, "input", "force")
mp.enable_key_bindings("input")

mp.set_key_bindings({
    {"mbtn_left",           function(e) process_event("mbtn_left", "up") end,
                            function(e) process_event("mbtn_left", "down")  end},
}, "window-controls", "force")
mp.enable_key_bindings("window-controls")

function get_hidetimeout()
    if user_opts.visibility == "always" then
        return -1 -- disable autohide
    end
    return user_opts.hidetimeout
end

function always_on(val)
    if state.enabled then
        if val then
            show_osc()
        else
            hide_osc()
        end
    end
end

-- mode can be auto/always/never/cycle
-- the modes only affect internal variables and not stored on its own.
function visibility_mode(mode, no_osd)
    if mode == "cycle" then
        if not state.enabled then
            mode = "auto"
        elseif user_opts.visibility ~= "always" then
            mode = "always"
        else
            mode = "never"
        end
    end

    if mode == "auto" then
        enable_osc(true)
    elseif mode == "always" then
        enable_osc(true)
        always_on(true)
    elseif mode == "never" then
        enable_osc(false)
    else
        msg.warn("Ignoring unknown visibility mode '" .. mode .. "'")
        return
    end

    user_opts.visibility = mode
    utils.shared_script_property_set("osc-visibility", mode)
    -- mp.set_property_native("user-data/osc/visibility", mode)

    if not no_osd and tonumber(mp.get_property("osd-level")) >= 1 then
        mp.osd_message("OSC visibility: " .. mode)
    end

    -- Reset the input state on a mode change. The input state will be
    -- recalculated on the next render cycle, except in 'never' mode where it
    -- will just stay disabled.
    mp.disable_key_bindings("input")
    mp.disable_key_bindings("window-controls")
    state.input_enabled = false

    update_margins()
    request_tick()
end

function idlescreen_visibility(mode, no_osd)
    if mode == "cycle" then
        if user_opts.idlescreen then
            mode = "no"
        else
            mode = "yes"
        end
    end

    if mode == "yes" then
        user_opts.idlescreen = true
    else
        user_opts.idlescreen = false
    end

    utils.shared_script_property_set("osc-idlescreen", mode)
    -- mp.set_property_native("user-data/osc/idlescreen", user_opts.idlescreen)

    if not no_osd and tonumber(mp.get_property("osd-level")) >= 1 then
        mp.osd_message("OSC logo visibility: " .. tostring(mode))
    end

    request_tick()
end

visibility_mode(user_opts.visibility, true)
mp.register_script_message("osc-visibility", visibility_mode)
mp.add_key_binding(nil, "visibility", function() visibility_mode("cycle") end)

mp.register_script_message("osc-idlescreen", idlescreen_visibility)

mp.register_script_message("thumbfast-info", function(json)
    local data = utils.parse_json(json)
    if type(data) ~= "table" or not data.width or not data.height then
        msg.error("thumbfast-info: received json didn't produce a table with thumbnail information")
    else
        thumbfast = data
    end
end)

set_virt_mouse_area(0, 0, 0, 0, "input")
set_virt_mouse_area(0, 0, 0, 0, "window-controls")
