-- this lua script written by snad
-- this lua is a part of
-- https://github.com/thisisshihan/mpv-player-config-snad

--[[
    podcast.lua - RSS Podcast Feed Reader for mpv
    ------------------------------------------------
    Author: snad

    WHAT IT DOES
    - Drag & drop (or open with mpv) a .pcst or .snad file that
      contains one
      or more podcast RSS feed URLs (one URL per line, "#" = comment).
    - The script downloads each feed with curl, parses out the episodes
      (title + audio/video enclosure URL + pubDate), and loads them into
      mpv's playlist in order (newest-first as published in the feed).
    - Press ALT+P (already bound in this user's input.conf to
      `script-binding podcast_toggle`) to open/close an on-screen podcast
      menu that lists episodes and lets you jump to any of them.

    REQUIREMENTS
    - curl.exe must be reachable (built into Windows 10 1803+ / Windows 11
      at C:\Windows\System32\curl.exe). No extra install needed normally.
    - yt-dlp.exe is OPTIONAL. Episodes loaded through this script skip it
      by default (mpv opens the direct enclosure URL itself - see the
      ytdl: directive below). It's only used if you explicitly turn it
      back on for a specific feed with "ytdl: yes".

    EPISODE CACHING
    - Episodes loaded through this script are cached whole (up to 512MB
      via mpv's own built-in demuxer cache, not a separate downloaded
      file) as they play - both ahead of your current position AND
      behind it, so once an episode has fully buffered, playback keeps
      going even if your connection drops, and seeking backward to
      anything already played is instant instead of re-fetching over
      the network. This isn't configurable per feed - it's applied
      automatically to every episode this script loads.

    [WORKAROUND] TLS VERIFICATION IS DISABLED
    - This script currently disables TLS certificate verification for all
      https streams mpv opens directly (mpv-level libcurl networking, not
      curl.exe/yt-dlp.exe), to work around a missing/broken CA bundle in
      this mpv build. Search this file for "[WORKAROUND]" for the full
      explanation and the proper long-term fix (a tls-ca-file in mpv.conf).
      This is a security trade-off, not a permanent solution.

    INSTALL
    - Save this file as:  portable_config\scripts\podcast.lua

    USAGE
    - Make a text file, e.g. feeds.pcst (or feeds.snad), containing:
        https://example.com/shows/sample-podcast/feed.rss
    - Drag that file onto the mpv window (or run: mpv.exe feeds.pcst)
      The mpv window opens instantly with a dark "loading" screen while
      the feed downloads in the background, then swaps in the episodes
      once ready - it no longer waits until the feed is fully loaded
      before showing anything.
    - Press ALT+P to open the podcast episode menu.
      Inside the menu: UP/DOWN (or K/J) to move, ENTER to play, ESC to close.

    FILTERING EPISODES (feeds.pcst syntax)
    - Lines starting with "#" are comments (ignored).
    - A line starting with "filter:" (alias "include:") sets a list of
      keywords - only episodes whose TITLE contains at least one of them
      will be loaded. Comma-separated, case-insensitive, plain substring
      match (not regex).
    - A line starting with "exclude:" sets a list of keywords - any
      episode whose title contains ANY of them is skipped, even if it
      also matches an include filter.
    - These filters are "sticky": once set, they apply to every feed URL
      listed below them, until changed again (or cleared with an empty
      value, e.g. "filter:" with nothing after the colon).
    - You can also attach a ONE-OFF filter to a single feed URL inline,
      which overrides (does not add to) the sticky filters for that URL
      only:
          https://example.com/feed.rss | filter=keyword1, keyword2
          https://example.com/feed.rss | exclude=ads, promo

      Example feeds.pcst:
        # only full-show episodes
        filter: FULL_SHOW, full show
        exclude: promo, ad break
        https://example.com/shows/sample-podcast/feed.rss

        # a second feed with no filtering (clear the sticky filters first)
        filter:
        exclude:
        https://example.com/another-podcast.rss

        # a third feed with its own one-off inline filter only
        https://example.com/yet-another.rss | filter=interview

    SKIPPING INTROS / ADS (start:/skip-intro: directive)
    - A line starting with "start:" (alias "skip-intro:") makes every
      episode below it begin playback N seconds in, skipping a fixed-
      length intro or ad block. Accepts plain seconds ("180"), seconds
      with a trailing "s" ("180s"), or "mm:ss" / "h:mm:ss" ("3:00").
    - Sticky, same as filter:/exclude: - applies to everything below it
      until changed (use "start:" with nothing after the colon, or
      "start: 0", to turn it back off).
    - Can also be set inline per-URL: "| start=180" or "| skip-intro=3:00"

      Example:
        start: 180
        https://example.com/shows/sample-podcast/feed.rss

        start: 0
        https://example.com/another-podcast.rss | start=45

    DISABLING YT-DLP (ytdl: directive)
    - By default, episodes loaded through this script skip yt-dlp
      entirely and let mpv open the enclosure URL directly. This is safe
      for the vast majority of podcast feeds, since RSS enclosures are
      already direct, playable media files - yt-dlp was only ever needed
      as a fallback for non-direct links (e.g. a page URL that needs
      extraction), and mpv opening the file itself is faster since it
      skips the extra subprocess call.
    - If a particular feed's enclosure links actually need yt-dlp (rare,
      but possible for some indie feeds that link to a hosting page
      instead of a direct file), turn it back on for that feed with:
        ytdl: yes
      Same sticky/inline rules as the other directives apply - "ytdl: no"
      (or nothing after the colon) turns it back off again, and
      "| ytdl=yes" / "| ytdl=no" can be set inline per-URL.
    - This only affects URLs loaded through this script. Any other file
      you open in mpv separately (YouTube links, etc.) is completely
      unaffected and still goes through yt-dlp normally.

      Example:
        ytdl: yes
        https://example.com/feed-that-needs-extraction.rss

        ytdl: no
        https://example.com/shows/sample-podcast/feed.rss

    REMOVING DUPLICATE EPISODES (remove-duplicates: directive)
    - A line starting with "remove-duplicates:" (alias "dedupe:") drops
      any episode whose title (case-insensitive, whitespace-trimmed)
      has already been seen earlier in this load - whether that's an
      earlier episode in the same feed, or from a different feed listed
      above it in the same file. Useful for feeds that list the same
      episode twice (e.g. a "best of" feed overlapping the main one).
    - Off by default (duplicates are kept). Sticky, same as the other
      directives - "remove-duplicates: no" turns it back off, and
      "| remove-duplicates=yes" / "| dedupe=no" work inline per-URL too.

      Example:
        remove-duplicates: yes
        https://example.com/shows/sample-podcast/feed.rss

    NOTES ON input.conf
    - This script does NOT bind any keys itself. It only registers the
      `podcast_toggle` script-binding, which your input.conf already maps
      to ALT+P. If you ever want a different key, just change the mapping
      in input.conf; nothing here needs to change.
]]

local utils = require 'mp.utils'
local msg   = require 'mp.msg'

----------------------------------------------------------------------
-- [WORKAROUND] Broken/missing CA bundle in this mpv build
----------------------------------------------------------------------
--[[
    *** WORKAROUND - NOT A REAL FIX - SECURITY TRADE-OFF ***

    Symptom seen in mpv-debug.log: every single HTTPS stream mpv tries to
    open directly fails with:
        SSL peer certificate or SSH remote key was not OK
        TLS certificate verification failed.
    ...even though curl.exe (used by this script to fetch the RSS feed)
    and yt-dlp.exe (mpv's automatic fallback) both connect to the exact
    same hosts without any problem. That's because curl.exe and yt-dlp
    use their own certificate stores, while mpv's bundled libcurl
    networking apparently can't find/validate one at all right now. The
    result: mpv fails to open every episode URL, falls back to yt-dlp,
    which resolves a working direct URL - but then mpv fails to open
    THAT url too, for the same reason, and the track gets skipped.

    WHAT THIS BLOCK DOES: disables TLS certificate verification for
    every https stream mpv opens directly - not just podcasts, ANY
    https URL, for as long as this script is loaded. With verification
    off, mpv can no longer detect a genuine man-in-the-middle attack on
    those connections.

    PROPER LONG-TERM FIX (recommended - do this, then delete this block):
      1. Download cacert.pem from https://curl.se/docs/caextract.html
      2. Put it in your portable_config folder
      3. Add this line to mpv.conf:
             tls-ca-file=~~/cacert.pem
      4. Confirm streams open with no TLS errors in the debug log, THEN
         delete this entire [WORKAROUND] block from podcast.lua.
]]
if mp.get_property("tls-verify") ~= "no" then
    mp.set_property("options/tls-verify", "no") -- WORKAROUND, see block comment above
    msg.warn("[podcast] WORKAROUND ACTIVE: tls-verify disabled (missing/broken CA bundle) - see [WORKAROUND] comment near the top of podcast.lua")
    mp.osd_message("[podcast] WORKAROUND: TLS verification disabled (see podcast.lua)", 4)
end

----------------------------------------------------------------------
-- Config
----------------------------------------------------------------------

local CURL_TIMEOUT = "20" -- seconds

----------------------------------------------------------------------
-- State
----------------------------------------------------------------------

-- episodes[i] = { title = "...", url = "...", pubdate = "...", feed = "Feed Title", start = 0 }
local episodes = {}
local feed_titles = {} -- list of loaded feed titles, for the header

-- url -> start-offset-in-seconds, used by the on_load hook to auto-seek
-- past intros/ads (see start:/skip-intro: directive in the feeds file)
local url_to_start = {}

-- url -> true/false, whether yt-dlp is allowed to run for this episode.
-- Defaults to false for everything loaded through this script (see
-- ytdl: directive) since podcast enclosures are direct media files and
-- mpv can open them on its own - yt-dlp is only needed as a fallback for
-- non-direct links, which is rare for podcast RSS.
local url_to_ytdl = {}

-- lowercased/trimmed title -> true, used to drop duplicate-titled
-- episodes across the whole load session (see remove-duplicates: directive)
local seen_titles = {}

-- path of the feeds file that was last opened, so the menu's Refresh
-- action knows what to re-fetch
local last_loaded_path = nil

local menu_active = false
local menu_selected = 1
local menu_overlay = nil
local menu_keys_bound = false

-- animated centered "Loading..." overlay shown while feeds are fetching
local loading_overlay = nil
local loading_timer = nil
local loading_dot_count = 0

----------------------------------------------------------------------
-- Small helpers
----------------------------------------------------------------------

local function trim(s)
    return (s or ""):match("^%s*(.-)%s*$")
end

-- Parses a duration string into whole seconds. Accepts:
--   "180"       -> 180
--   "180s"      -> 180
--   "3:00"      -> 180  (mm:ss)
--   "1:02:03"   -> 3723 (h:mm:ss)
-- Returns nil if it can't parse the string.
local function parse_duration(s)
    s = trim(s)
    if s == "" then return nil end
    local h, m, sec = s:match("^(%d+):(%d%d):(%d%d)$")
    if h then return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(sec) end
    local m2, sec2 = s:match("^(%d+):(%d%d)$")
    if m2 then return tonumber(m2) * 60 + tonumber(sec2) end
    local n = s:match("^(%d+%.?%d*)s?$")
    if n then return tonumber(n) end
    return nil
end

-- Formats whole seconds as "m:ss" or "h:mm:ss" for display in the menu.
local function format_seconds(sec)
    sec = math.floor(sec + 0.5)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s2 = sec % 60
    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, s2)
    end
    return string.format("%d:%02d", m, s2)
end

local function decode_entities(s)
    if not s then return "" end
    s = s:gsub("&lt;", "<")
    s = s:gsub("&gt;", ">")
    s = s:gsub("&quot;", '"')
    s = s:gsub("&apos;", "'")
    s = s:gsub("&#0*39;", "'")
    s = s:gsub("&#0*34;", '"')
    s = s:gsub("&amp;", "&") -- must be last
    return s
end

local function ass_escape(s)
    if not s then return "" end
    s = s:gsub("\\", "\\\\")
    s = s:gsub("{", "\\{")
    s = s:gsub("}", "\\}")
    s = s:gsub("\n", " ")
    return s
end

-- strips a leading file:// (and URL-decodes) so we can open the path
-- with normal io.open on Windows
local function file_uri_to_path(path)
    if not path then return path end
    if path:match("^file://") then
        path = path:gsub("^file:///", "")
        path = path:gsub("^file://", "")
        path = path:gsub("%%20", " ")
        path = path:gsub("(%%[0-9A-Fa-f][0-9A-Fa-f])", function(h)
            return string.char(tonumber(h:sub(2), 16))
        end)
    end
    return path
end

----------------------------------------------------------------------
-- Fetch a URL via curl (blocking subprocess call - kept for reference /
-- possible future synchronous uses, not used by the main load path)
----------------------------------------------------------------------

-- Shared curl args. --compressed asks for (and transparently decompresses)
-- gzip/deflate/br - some ad-tech-backed podcast CDNs (e.g. AdsWizz-hosted
-- Simplecast feeds) serve compressed responses by default; without this
-- flag we'd try to regex-parse raw compressed bytes and silently fail
-- with "no items found". The browser-like UA and Accept header also
-- help avoid being blocked by hosts that filter out obvious bot/script
-- user agents - virtually all podcast apps spoof a normal UA for exactly
-- this reason.
local function curl_args(url)
    return {
        "curl", "-s", "-L", "--compressed", "--max-time", CURL_TIMEOUT,
        "-A", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36",
        "-H", "Accept: application/rss+xml, application/xml, text/xml, */*",
        url,
    }
end

-- Logs a short, sanitized preview of a failed/empty response so the
-- debug log actually explains WHY a feed failed (blocked, compressed,
-- redirected to an HTML page, etc.) instead of just "no items found".
local function log_response_preview(url, body)
    if not body or body == "" then
        msg.warn("[podcast] empty response body for " .. url)
        return
    end
    local preview = body:sub(1, 150):gsub("[\r\n]+", " "):gsub("[^\32-\126]", "?")
    msg.warn(string.format("[podcast] unexpected response for %s (%d bytes): %s",
        url, #body, preview))
end

local function http_get(url)
    local res = mp.command_native({
        name = "subprocess",
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false,
        args = curl_args(url),
    })
    if not res then
        msg.error("curl: failed to run subprocess")
        return nil
    end
    if res.status ~= 0 then
        msg.error("curl exited with status " .. tostring(res.status) ..
                   " for " .. url .. " -- " .. tostring(res.stderr))
        return nil
    end
    return res.stdout
end

----------------------------------------------------------------------
-- Fetch a URL via curl WITHOUT blocking the player (async subprocess).
-- IMPORTANT: this is what the feed-loading path actually uses. mpv's own
-- docs warn that on_load hooks must not do slow work synchronously,
-- because that freezes the ENTIRE player (not just the script) - which
-- is exactly why the mpv window used to stay blank/unresponsive until a
-- feed finished downloading. callback(xml_or_nil) is invoked once done.
----------------------------------------------------------------------

local function http_get_async(url, callback)
    mp.command_native_async({
        name = "subprocess",
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false,
        args = curl_args(url),
    }, function(success, res, err)
        if not success or not res then
            msg.error("curl async: failed to run subprocess for " .. url .. " -- " .. tostring(err))
            callback(nil)
            return
        end
        if res.status ~= 0 then
            msg.error("curl exited with status " .. tostring(res.status) ..
                       " for " .. url .. " -- " .. tostring(res.stderr))
            callback(nil)
            return
        end
        callback(res.stdout)
    end)
end

----------------------------------------------------------------------
-- Very small RSS parser (pattern based, no external XML lib needed)
----------------------------------------------------------------------

local function extract_tag(block, tag)
    -- prefer CDATA content
    local v = block:match("<" .. tag .. "[^>]*>%s*<!%[CDATA%[(.-)%]%]>%s*</" .. tag .. ">")
    if not v then
        v = block:match("<" .. tag .. "[^>]*>(.-)</" .. tag .. ">")
    end
    if v then
        v = trim(decode_entities(v))
    end
    return v
end

local function extract_enclosure(block)
    local url = block:match('<enclosure[^>]*url="(.-)"')
    if not url then
        url = block:match("<enclosure[^>]*url='(.-)'")
    end
    if not url then
        -- some feeds only provide a <link> or <guid isPermaLink="false"> media link
        url = block:match("<media:content[^>]*url=\"(.-)\"")
    end
    if url then
        -- IMPORTANT: XML attribute values escape "&" as "&amp;". Feed hosts
        -- that use signed/tokenized URLs (e.g. omny.fm/omnycontent.com) will
        -- reject a request that still has literal "&amp;" in the query
        -- string, which makes mpv fail to open the file and instantly
        -- skip to the next playlist entry. Decode it back to "&".
        url = decode_entities(trim(url))
    end
    return url
end

local function parse_feed(xml, feed_url)
    if not xml or xml == "" then
        return nil, "empty response"
    end

    local channel_block = xml:match("<channel[^>]*>(.-)<item")
    local feed_title = "Podcast"
    if channel_block then
        feed_title = extract_tag(channel_block, "title") or feed_title
    end

    local items = {}
    for item_block in xml:gmatch("<item[^>]*>(.-)</item>") do
        local title = extract_tag(item_block, "title") or "(untitled episode)"
        local url = extract_enclosure(item_block)
        local pubdate = extract_tag(item_block, "pubDate") or ""
        if url then
            table.insert(items, {
                title = title,
                url = trim(url),
                pubdate = pubdate,
                feed = feed_title,
            })
        end
    end

    if #items == 0 then
        -- log a preview of what we actually got - makes it possible to
        -- tell at a glance whether the host blocked us, redirected to an
        -- HTML page, sent something unexpected, etc., instead of just
        -- "no items found" with no further clue
        log_response_preview(feed_url, xml)
        return nil, "no playable <enclosure> items found in feed"
    end

    return feed_title, items
end

----------------------------------------------------------------------
-- Build episode list from a feeds file (.pcst / .snad containing URLs)
----------------------------------------------------------------------

-- splits a comma-separated keyword string into a trimmed, non-empty list
local function split_keywords(s)
    local out = {}
    if not s then return out end
    for token in (s .. ","):gmatch("(.-),") do
        token = trim(token)
        if token ~= "" then table.insert(out, token) end
    end
    return out
end

-- parses a yes/no-ish string into a boolean, falling back to `default`
local function parse_bool(s, default)
    s = trim(s):lower()
    if s == "" then return default end
    if s == "yes" or s == "true" or s == "1" or s == "on" then return true end
    if s == "no" or s == "false" or s == "0" or s == "off" then return false end
    return default
end

-- recognizes "filter:"/"include:"/"exclude:"/"start:"/"skip-intro:"/"ytdl:" directive lines
local function parse_directive_line(line)
    local val = line:match("^[Ff][Ii][Ll][Tt][Ee][Rr]%s*:%s*(.*)$")
        or line:match("^[Ii][Nn][Cc][Ll][Uu][Dd][Ee]%s*:%s*(.*)$")
    if val then return "include", val end
    val = line:match("^[Ee][Xx][Cc][Ll][Uu][Dd][Ee]%s*:%s*(.*)$")
    if val then return "exclude", val end
    val = line:match("^[Ss][Tt][Aa][Rr][Tt]%s*:%s*(.*)$")
        or line:match("^[Ss][Kk][Ii][Pp]%-?[Ii][Nn][Tt][Rr][Oo]%s*:%s*(.*)$")
    if val then return "start", val end
    val = line:match("^[Yy][Tt][Dd][Ll]%s*:%s*(.*)$")
    if val then return "ytdl", val end
    val = line:match("^[Rr][Ee][Mm][Oo][Vv][Ee]%-?[Dd][Uu][Pp][Ll][Ii][Cc][Aa][Tt][Ee][Ss]%s*:%s*(.*)$")
        or line:match("^[Dd][Ee][Dd][Uu][Pp][Ee]%s*:%s*(.*)$")
    if val then return "remove_duplicates", val end
    return nil
end

-- true if `title` should be kept given include/exclude keyword lists
-- (case-insensitive plain substring match; include is OR-matched)
local function episode_matches(title, include_list, exclude_list)
    local lt = (title or ""):lower()
    if exclude_list and #exclude_list > 0 then
        for _, kw in ipairs(exclude_list) do
            if lt:find(kw:lower(), 1, true) then
                return false
            end
        end
    end
    if include_list and #include_list > 0 then
        for _, kw in ipairs(include_list) do
            if lt:find(kw:lower(), 1, true) then
                return true
            end
        end
        return false -- had an include list but nothing matched
    end
    return true
end

-- Reads a feeds file and returns a list of
--   { url = "...", include = {...}, exclude = {...} }
-- honoring sticky filter:/exclude: directives and inline per-URL
-- "| filter=..." / "| exclude=..." overrides. See the header comment
-- at the top of this file for the full syntax and examples.
local function read_feed_entries(path)
    local f, err = io.open(path, "rb")
    if not f then
        msg.error("could not open feed list file: " .. tostring(err))
        return {}
    end
    local content = f:read("*a")
    f:close()

    local entries = {}
    local current_include, current_exclude = {}, {}
    local current_start = 0
    local current_ytdl = false -- default: skip yt-dlp, mpv opens episodes directly
    local current_remove_duplicates = false -- default: keep duplicate titles

    for raw_line in (content .. "\n"):gmatch("(.-)\r?\n") do
        local line = trim(raw_line)
        if line ~= "" and not line:match("^#") then
            local dtype, dval = parse_directive_line(line)
            if dtype == "include" then
                current_include = split_keywords(dval)
            elseif dtype == "exclude" then
                current_exclude = split_keywords(dval)
            elseif dtype == "start" then
                current_start = parse_duration(dval) or 0
            elseif dtype == "ytdl" then
                current_ytdl = parse_bool(dval, false)
            elseif dtype == "remove_duplicates" then
                current_remove_duplicates = parse_bool(dval, false)
            elseif line:match("^https?://") then
                -- split on "|" for optional inline overrides
                local segs = {}
                for seg in (line .. "|"):gmatch("(.-)|") do
                    table.insert(segs, trim(seg))
                end
                local url = segs[1]
                local inc, exc, st, yd, rd = current_include, current_exclude, current_start,
                    current_ytdl, current_remove_duplicates
                for i = 2, #segs do
                    local fv = segs[i]:match("^[Ff][Ii][Ll][Tt][Ee][Rr]%s*=%s*(.*)$")
                        or segs[i]:match("^[Ii][Nn][Cc][Ll][Uu][Dd][Ee]%s*=%s*(.*)$")
                    local ev = segs[i]:match("^[Ee][Xx][Cc][Ll][Uu][Dd][Ee]%s*=%s*(.*)$")
                    local sv = segs[i]:match("^[Ss][Tt][Aa][Rr][Tt]%s*=%s*(.*)$")
                        or segs[i]:match("^[Ss][Kk][Ii][Pp]%-?[Ii][Nn][Tt][Rr][Oo]%s*=%s*(.*)$")
                    local yv = segs[i]:match("^[Yy][Tt][Dd][Ll]%s*=%s*(.*)$")
                    local rv = segs[i]:match("^[Rr][Ee][Mm][Oo][Vv][Ee]%-?[Dd][Uu][Pp][Ll][Ii][Cc][Aa][Tt][Ee][Ss]%s*=%s*(.*)$")
                        or segs[i]:match("^[Dd][Ee][Dd][Uu][Pp][Ee]%s*=%s*(.*)$")
                    if fv then inc = split_keywords(fv) end
                    if ev then exc = split_keywords(ev) end
                    if sv then st = parse_duration(sv) or 0 end
                    if yv then yd = parse_bool(yv, current_ytdl) end
                    if rv then rd = parse_bool(rv, current_remove_duplicates) end
                end
                table.insert(entries, {
                    url = url, include = inc, exclude = exc, start = st,
                    ytdl = yd, remove_duplicates = rd,
                })
            end
        end
    end
    return entries
end

----------------------------------------------------------------------
-- Animated "Loading..." overlay, centered on screen, dots cycling
-- while feeds are being fetched in the background.
----------------------------------------------------------------------

local function loading_text()
    local ww, wh = mp.get_osd_size()
    ww = ww or 1280
    wh = wh or 720
    local dots = string.rep(".", loading_dot_count)
    return string.format(
        "{\\pos(%d,%d)\\an5\\fs60\\bord3\\shad2\\c&HFFFFFF&\\3c&H000000&}Loading%s",
        math.floor(ww / 2), math.floor(wh / 2), dots)
end

local loading_tick -- forward declaration (self-referencing timer callback)
loading_tick = function()
    loading_dot_count = (loading_dot_count + 1) % 4
    if loading_overlay then
        loading_overlay.data = loading_text()
        loading_overlay:update()
    end
    loading_timer = mp.add_timeout(0.5, loading_tick)
end

local function stop_loading_animation()
    if loading_timer then
        loading_timer:stop()
        loading_timer = nil
    end
    if loading_overlay then
        loading_overlay:remove()
    end
end

local function start_loading_animation()
    stop_loading_animation() -- clear any previous run first
    loading_dot_count = 0
    if not loading_overlay then
        loading_overlay = mp.create_osd_overlay("ass-events")
    end
    loading_overlay.data = loading_text()
    loading_overlay:update()
    loading_timer = mp.add_timeout(0.5, loading_tick)
end

-- Fetches all feeds in `entries` one at a time (async, non-blocking), then
-- builds the temp .m3u8 and swaps it in over the loading placeholder.
-- This never blocks the player - each curl call runs in the background
-- while mpv's window stays fully responsive and shows our loading screen.
local function load_feed_entries_async(entries)
    episodes = {}
    feed_titles = {}
    url_to_start = {}
    url_to_ytdl = {}
    seen_titles = {}

    local i = 0

    local function fetch_next()
        i = i + 1
        local entry = entries[i]

        if not entry then
            -- all feeds processed - finalize
            stop_loading_animation()

            if #episodes == 0 then
                mp.osd_message("Podcast: no episodes could be loaded.", 4)
                return
            end

            -- Build a temp M3U8 playlist and load it in place of the
            -- loading placeholder that's currently "playing".
            local tmp_dir = os.getenv("TEMP") or os.getenv("TMP") or "."
            local m3u_path = utils.join_path(tmp_dir, "mpv-podcast-" .. os.time() .. ".m3u8")

            local out, ferr = io.open(m3u_path, "wb")
            if not out then
                msg.error("could not write temp playlist: " .. tostring(ferr))
                mp.osd_message("Podcast: could not write temp playlist.", 4)
                return
            end
            out:write("#EXTM3U\n")
            for _, ep in ipairs(episodes) do
                out:write("#EXTINF:-1," .. ep.title:gsub("\n", " ") .. "\n")
                out:write(ep.url .. "\n")
            end
            out:close()

            mp.commandv("loadfile", m3u_path, "replace")
            mp.osd_message(
                "Podcast: loaded " .. #episodes .. " episode(s) from " ..
                table.concat(feed_titles, ", "), 4)
            return
        end

        local filter_note = ""
        if #entry.include > 0 then
            filter_note = filter_note .. " [filter: " .. table.concat(entry.include, ", ") .. "]"
        end
        if #entry.exclude > 0 then
            filter_note = filter_note .. " [exclude: " .. table.concat(entry.exclude, ", ") .. "]"
        end

        -- parses the fetched XML, applies filters/dedup, and adds
        -- matching episodes to the running playlist
        local function handle_xml(xml)
            local title, items_or_err = parse_feed(xml, entry.url)
            if not title then
                msg.error("Feed failed (" .. entry.url .. "): " .. tostring(items_or_err))
                mp.osd_message("Podcast: failed to load " .. entry.url, 3)
            else
                table.insert(feed_titles, title)
                local kept, total, deduped = 0, #items_or_err, 0
                for _, item in ipairs(items_or_err) do
                    if episode_matches(item.title, entry.include, entry.exclude) then
                        local dup = false
                        if entry.remove_duplicates then
                            local key = trim(item.title):lower()
                            if seen_titles[key] then
                                dup = true
                                deduped = deduped + 1
                            else
                                seen_titles[key] = true
                            end
                        end
                        if not dup then
                            item.start = entry.start or 0
                            table.insert(episodes, item)
                            url_to_start[item.url] = item.start
                            url_to_ytdl[item.url] = entry.ytdl
                            kept = kept + 1
                        end
                    end
                end
                msg.info(string.format("Feed '%s': kept %d of %d episode(s) after filtering%s",
                    title, kept, total,
                    deduped > 0 and (" [" .. deduped .. " duplicate title(s) removed]") or ""))
            end
            fetch_next() -- move on to the next feed, or finalize
        end

        msg.info("Fetching feed: " .. entry.url .. filter_note)
        mp.osd_message(string.format("Loading podcast feed %d/%d...", i, #entries), 30)

        http_get_async(entry.url, function(xml)
            if xml then
                handle_xml(xml)
            else
                msg.error("Feed failed (" .. entry.url .. "): fetch error")
                mp.osd_message("Podcast: failed to load " .. entry.url, 3)
                fetch_next()
            end
        end)
    end

    fetch_next()
end

-- Entry point called from the on_load hook. Reads the feed list file
-- (fast, local disk only) and kicks off the async fetch chain above.
-- Does NOT touch stream-open-filename itself - the caller is responsible
-- for putting up a loading placeholder before calling this.
local function load_feeds_from_file(path)
    path = file_uri_to_path(path)
    local entries = read_feed_entries(path)
    if #entries == 0 then
        stop_loading_animation()
        mp.osd_message("Podcast: no feed URLs found in " .. path, 3)
        return false
    end
    last_loaded_path = path
    load_feed_entries_async(entries)
    return true
end

----------------------------------------------------------------------
-- On-screen podcast menu helpers
----------------------------------------------------------------------

local function format_pubdate(pd)
    if not pd or pd == "" then return "" end
    -- RSS pubDate looks like: "Fri, 08 Aug 2026 09:00:00 +0000"
    local d, mo, y = pd:match("(%d%d?) (%a%a%a) (%d%d%d%d)")
    if d and mo and y then
        return string.format("%s %s %s", d, mo, y)
    end
    return ""
end

-- Forward declaration so refresh_feeds_async can call menu_render
local menu_render 

----------------------------------------------------------------------
-- Refresh: re-fetches the same feeds file and ADDS any genuinely new
-- episodes to the end of the existing mpv playlist (via "append", never
-- "replace"), so whatever is currently playing is never touched. Unlike
-- the initial load, this does not reset episodes/url_to_start/
-- seen_titles - it builds on top of that existing state so already-seen
-- episodes are correctly recognized and skipped rather than duplicated.
----------------------------------------------------------------------

local menu_refreshing = false
-- brief status text shown in the menu header after a refresh completes
-- (e.g. "3 new episodes added"), cleared automatically after a few
-- seconds - kept separate from mp.osd_message so it never visually
-- overlaps the menu itself
local menu_status = nil

local function refresh_feeds_async()
    if menu_refreshing then
        return
    end
    if not last_loaded_path then
        mp.osd_message("Podcast: nothing loaded yet to refresh.", 3)
        return
    end

    local ok_entries, entries = pcall(read_feed_entries, last_loaded_path)
    if not ok_entries then
        msg.error("Refresh: failed to read feeds file: " .. tostring(entries))
        mp.osd_message("Podcast: refresh failed (could not read feeds file).", 3)
        return
    end
    if #entries == 0 then
        mp.osd_message("Podcast: no feed URLs found in " .. last_loaded_path, 3)
        return
    end

    menu_refreshing = true
    -- When the menu is open, show refresh status IN the menu's own
    -- header (see menu_text()) instead of via mp.osd_message - both the
    -- menu overlay and osd_message render near the same top-left corner
    -- by default, and a lingering osd_message could visually collide
    -- with the menu, making it look broken/unresponsive even though the
    -- underlying key bindings are working fine. osd_message is only
    -- used as a fallback when there's no menu open to show status in.
    if menu_active then
        menu_render()
    else
        mp.osd_message("Podcast: refreshing feed...", 30)
    end

    -- Safety net: if something goes wrong badly enough that the async
    -- chain below never reaches finish() (a stuck subprocess, an error
    -- escaping the pcall boundary some other way, etc.), this forces
    -- menu_refreshing back to false after a while so "R" isn't
    -- permanently stuck doing nothing.
    local refresh_generation = (refresh_generation_counter or 0) + 1
    refresh_generation_counter = refresh_generation
    mp.add_timeout(25, function()
        if menu_refreshing and refresh_generation_counter == refresh_generation then
            msg.warn("Refresh: timed out without finishing, resetting state")
            menu_refreshing = false
        end
    end)

    local i = 0
    local new_count = 0

    local function finish()
        menu_refreshing = false
        local summary = new_count > 0
            and (new_count .. " new episode(s) added")
            or "no new episodes"
        if menu_active then
            menu_status = summary
            menu_render()
            mp.add_timeout(4, function()
                menu_status = nil
                if menu_active then menu_render() end
            end)
        else
            mp.osd_message("Podcast: refreshed - " .. summary, new_count > 0 and 4 or 3)
        end
    end

    local function fetch_next()
        i = i + 1
        local entry = entries[i]

        if not entry then
            finish()
            return
        end

        -- Everything that touches shared state (episodes, feed_titles,
        -- url_to_start, etc.) or parses external/untrusted data runs
        -- inside pcall: a malformed feed or an unexpected edge case in
        -- one entry must not be able to throw an uncaught error that
        -- kills the rest of the refresh (or, worse, this script's other
        -- key bindings like podcast_toggle) - it just gets logged and
        -- refresh moves on to the next feed instead.
        local function handle_xml(xml)
            local ok, err = pcall(function()
                local title, items_or_err = parse_feed(xml, entry.url)
                if not title then
                    msg.error("Refresh: feed failed (" .. entry.url .. "): " .. tostring(items_or_err))
                    return
                end

                local already_listed = false
                for _, ft in ipairs(feed_titles) do
                    if ft == title then already_listed = true break end
                end
                if not already_listed then
                    table.insert(feed_titles, title)
                end

                for _, item in ipairs(items_or_err) do
                    if episode_matches(item.title, entry.include, entry.exclude) then
                        local dup = false
                        if entry.remove_duplicates then
                            local key = trim(item.title):lower()
                            if seen_titles[key] then
                                dup = true
                            else
                                seen_titles[key] = true
                            end
                        end
                        -- url_to_start already having an entry for this
                        -- URL means we've already added this exact
                        -- episode in a previous load/refresh - skip it
                        if not dup and url_to_start[item.url] == nil then
                            item.start = entry.start or 0
                            table.insert(episodes, item)
                            url_to_start[item.url] = item.start
                            url_to_ytdl[item.url] = entry.ytdl
                            -- append only - never touches the currently
                            -- playing item or anything already queued
                            mp.commandv("loadfile", item.url, "append")
                            new_count = new_count + 1
                        end
                    end
                end
            end)
            if not ok then
                msg.error("Refresh: error handling feed " .. entry.url .. ": " .. tostring(err))
            end
            fetch_next()
        end

        http_get_async(entry.url, function(xml)
            if xml then
                handle_xml(xml)
            else
                msg.error("Refresh: fetch error for " .. entry.url)
                fetch_next()
            end
        end)
    end

    fetch_next()
end

----------------------------------------------------------------------
-- on_load hook: intercept .pcst / .snad files and redirect to our
-- generated playlist instead of letting mpv try to "play" a text file.
-- Also applies per-episode start offsets (start:/skip-intro: directive)
-- right before mpv opens a matching episode URL.
--
-- IMPORTANT: mpv's own docs warn that on_load hooks must not do slow
-- work synchronously, since that freezes the ENTIRE player (window
-- included), not just the script. So this hook does the bare minimum:
-- it swaps in an instant "loading" placeholder (a lavfi-generated dark
-- screen) so the mpv window appears immediately, then kicks off the
-- actual network fetch/parsing in the background via
-- load_feeds_from_file -> load_feed_entries_async. Once that finishes,
-- it replaces the placeholder with the real episode playlist.
----------------------------------------------------------------------

mp.add_hook("on_load", 50, function()
    local path = mp.get_property("stream-open-filename", "")
    if path == "" then return end

    local lower = path:lower()
    if lower:match("%.pcst$") or lower:match("%.snad$") then
        -- avoid re-triggering on the temp .m3u8 we generate ourselves
        if lower:match("mpv%-podcast%-%d+%.m3u8$") then return end

        -- Instant placeholder: a plain dark screen via mpv's lavfi
        -- pseudo-demuxer, so the window shows up right away instead of
        -- staying blank/absent while the feed downloads in the
        -- background. 3600s is just a generous ceiling; it gets
        -- replaced long before that by the real playlist.
        mp.set_property("stream-open-filename", "av://lavfi:color=c=0x14141e:s=1280x720:d=3600")
        start_loading_animation()

        load_feeds_from_file(path) -- async - returns immediately
        return
    end

    -- Apply the start seek offset for this specific URL, using the
    -- "file-local-options/" property namespace. This is mpv's documented
    -- mechanism for setting an option that applies to only the file about
    -- to be opened, and is automatically reset once that file's playback
    -- ends - unlike the plain "start" property (or "options/start"),
    -- which is not reliably picked up here for the *upcoming* file and
    -- would otherwise require manually tracking/clearing it ourselves.
    local offset = url_to_start[path]
    if offset ~= nil then
        if offset > 0 then
            mp.set_property("file-local-options/start", tostring(offset))
        end

        -- WORKAROUND: some external setups (audio-visualizer profiles via
        -- auto_profiles.lua or an mpv.conf [audio-file] profile, etc.)
        -- apply a "lavfi-complex" filter graph to audio-only files. If
        -- that graph references a filter unavailable in the current
        -- ffmpeg build, playback fails immediately with "AVFilterGraph:
        -- Error creating filters" and the track gets skipped - this has
        -- nothing to do with the podcast feed itself and would affect
        -- any audio-only file. Force-clearing it for our own episode
        -- URLs sidesteps that regardless of what's misconfigured
        -- elsewhere, at the cost of not showing that visualizer for
        -- podcast episodes specifically.
        mp.set_property("file-local-options/lavfi-complex", "")

        -- Cache the WHOLE episode (not just a small look-ahead buffer)
        -- while it plays, using mpv's own built-in demuxer cache -
        -- nothing external, no extra disk files to manage. Podcast
        -- episodes are audio-only and typically well under 200MB even
        -- for multi-hour shows, so holding an entire episode in mpv's
        -- cache is cheap. Practical effect: once buffered, a flaky
        -- connection won't interrupt playback, and seeking backward to
        -- anything already played is instant instead of re-fetching -
        -- demuxer-max-bytes controls how far AHEAD it buffers,
        -- demuxer-max-back-bytes controls how much already-played
        -- content it's allowed to keep BEHIND the current position, so
        -- both need to be large for the whole file to stay cached
        -- start-to-finish rather than trimming the beginning as you
        -- play through it.
        local EPISODE_CACHE_BYTES = "512MiB"
        mp.set_property("file-local-options/cache", "yes")
        mp.set_property("file-local-options/demuxer-max-bytes", EPISODE_CACHE_BYTES)
        mp.set_property("file-local-options/demuxer-max-back-bytes", EPISODE_CACHE_BYTES)
    end

    -- Skip yt-dlp entirely for our own episode URLs by default (see the
    -- ytdl: directive). Podcast enclosures are direct media files mpv
    -- can open on its own, so this avoids the extra subprocess call and
    -- its delay. Only applies to URLs that came from a loaded feed -
    -- anything else (e.g. a YouTube link opened separately) is left
    -- completely alone and still goes through yt-dlp normally.
    local ytdl_allowed = url_to_ytdl[path]
    if ytdl_allowed ~= nil then
        mp.set_property("file-local-options/ytdl", ytdl_allowed and "yes" or "no")
    end
end)

----------------------------------------------------------------------
-- On-screen podcast menu rendering & actions
----------------------------------------------------------------------

local function menu_text()
    local ww, wh = mp.get_osd_size()
    ww = ww or 1280
    wh = wh or 720

    local lines = {}
    local refresh_tag = menu_refreshing and "  {\\c&H55AAFF&}[Refreshing...]{\\c&HFFFFFF&}" or ""
    local status_tag = (not menu_refreshing and menu_status) and ("  {\\c&H70E070&}[" .. menu_status .. "]{\\c&HFFFFFF&}") or ""
    table.insert(lines, "{\\an7\\fs28\\bord2\\shad1\\c&HFFFFFF&}Podcast Episodes{\\fs20}  (UP/DOWN move, ENTER play, R refresh, ESC close)" .. refresh_tag .. status_tag .. "\\N\\N")

    if #episodes == 0 then
        table.insert(lines, "{\\fs22\\c&HAAAAAA&}No episodes loaded.\\NDrag & drop a .pcst/.snad file containing a podcast feed URL onto the mpv window.")
    else
        local max_visible = 18
        local first = 1
        if menu_selected > max_visible then
            first = menu_selected - max_visible + 1
        end
        local last = math.min(#episodes, first + max_visible - 1)

        for i = first, last do
            local ep = episodes[i]
            local date = format_pubdate(ep.pubdate)
            local label = ass_escape(ep.title)
            local prefix = (i == menu_selected) and "{\\c&H00D7FF&}\\h\\h> " or "{\\c&HFFFFFF&}\\h\\h\\h"
            local dateStr = date ~= "" and ("  {\\c&H888888&\\fs16}(" .. date .. "){\\fs20}") or ""
            local startTag = (ep.start and ep.start > 0)
                and ("  {\\c&H55AAFF&\\fs16}[starts @ " .. format_seconds(ep.start) .. "]{\\fs20}")
                or ""
            table.insert(lines, string.format("{\\fs20}%s%d. %s%s%s", prefix, i, label, dateStr, startTag))
        end
    end

    return "{\\pos(30,30)}" .. table.concat(lines, "\\N")
end

-- Assign definition to forward-declared local variable
menu_render = function()
    if not menu_overlay then
        menu_overlay = mp.create_osd_overlay("ass-events")
    end
    menu_overlay.data = menu_text()
    menu_overlay:update()
end

local function menu_close()
    menu_active = false
    if menu_overlay then
        menu_overlay:remove()
    end
    if menu_keys_bound then
        mp.remove_key_binding("podcast-menu-up")
        mp.remove_key_binding("podcast-menu-down")
        mp.remove_key_binding("podcast-menu-enter")
        mp.remove_key_binding("podcast-menu-esc")
        mp.remove_key_binding("podcast-menu-refresh")
        mp.remove_key_binding("podcast-menu-refresh-shift")
        menu_keys_bound = false
    end
end

local function menu_play_selected()
    local ep = episodes[menu_selected]
    if not ep then return end
    -- find matching entry in mpv's playlist by URL and jump to it
    local pl = mp.get_property_native("playlist")
    for i, entry in ipairs(pl) do
        if entry.filename == ep.url then
            mp.commandv("playlist-play-index", i - 1)
            menu_close()
            return
        end
    end
    -- fallback: just load it directly if not found in playlist
    mp.commandv("loadfile", ep.url, "replace", "title=" .. ep.title)
    menu_close()
end

local function menu_open()
    if #episodes == 0 then
        mp.osd_message("Podcast: no episodes loaded yet.\nDrag & drop a .pcst/.snad feed file onto mpv.", 3)
        return
    end
    menu_active = true
    menu_selected = 1

    mp.add_forced_key_binding("UP", "podcast-menu-up", function()
        menu_selected = math.max(1, menu_selected - 1)
        menu_render()
    end, { repeatable = true })
    mp.add_forced_key_binding("DOWN", "podcast-menu-down", function()
        menu_selected = math.min(#episodes, menu_selected + 1)
        menu_render()
    end, { repeatable = true })
    mp.add_forced_key_binding("ENTER", "podcast-menu-enter", menu_play_selected)
    mp.add_forced_key_binding("ESC", "podcast-menu-esc", menu_close)
    mp.add_forced_key_binding("r", "podcast-menu-refresh", refresh_feeds_async)
    mp.add_forced_key_binding("R", "podcast-menu-refresh-shift", refresh_feeds_async)
    menu_keys_bound = true

    menu_render()
end

local function podcast_toggle()
    if menu_active then
        menu_close()
    else
        menu_open()
    end
end

-- This matches the existing binding already present in this user's
-- input.conf:   alt+p script-binding podcast_toggle
mp.add_key_binding(nil, "podcast_toggle", podcast_toggle)
mp.add_key_binding(nil, "podcast_refresh", refresh_feeds_async)

msg.info("podcast.lua loaded - drag & drop a .pcst/.snad feed file, ALT+P to open the menu")
