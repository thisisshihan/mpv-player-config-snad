--[[
mpv 5-bands equalizer with visual feedback.
Copyright 2016 Avi Halachmi ( https://github.com/avih )
License: public domain
Default config:
- Enter/exit equilizer keys mode: ctrl+e
- Equalizer keys: 2/w control bass ... 6/y control treble, and middles in between
- Toggle equalizer without changing its values: ctrl+E (ctrl+shift+e)
- Reset equalizer values: alt+ctrl+e
- See ffmpeg filter description below the config section
--]]
-- ------ config -------
local start_keys_enabled = false  -- if true then choose the up/down keys wisely
local key_toggle_bindings = 'ctrl+e'  -- enable/disable equalizer key bindings
local key_toggle_equalizer = 'ctrl+E'  -- enable/disable equalizer
local key_reset_equalizer = 'alt+ctrl+e'
local bands = {
  -- octave is x2. e.g. two octaves range around f is from f/2 to f*2
  --      {up  down}
  {keys = {'2', 'w'}, filter = {'equalizer=f=64:width_type=o:w=3.3:g=', 0}}, -- 20-200
  {keys = {'3', 'e'}, filter = {'equalizer=f=400:width_type=o:w=2.0:g=', 0}}, -- 200-800
  {keys = {'4', 'r'}, filter = {'equalizer=f=1250:width_type=o:w=1.3:g=', 0}}, -- 800-2k
  {keys = {'5', 't'}, filter = {'equalizer=f=2830:width_type=o:w=1.0:g=', 0}}, -- 2k-4k
  {keys = {'6', 'y'}, filter = {'equalizer=f=5600:width_type=o:w=1.0:g=', 0}}, -- 4k-8k
--{keys = {'7', 'u'}, filter = {'equalizer=f=12500:width_type=o:w=1.3:g=', 0}} -- - 20k
}

--[[
https://ffmpeg.org/ffmpeg-filters.html#equalizer
Apply a two-pole peaking equalisation (EQ) filter. With this filter, the signal-level
at and around a selected frequency can be increased or decreased, whilst (unlike
bandpass and bandreject filters) that at all other frequencies is unchanged.
In order to produce complex equalisation curves, this filter can be given several
times, each with a different central frequency.
The filter accepts the following options:
frequency, f: Set the filter’s central frequency in Hz.
width_type: Set method to specify band-width of filter.
    h  Hz
    q  Q-Factor 
    o  octave 
    s  slope 
width, w: Specify the band-width of a filter in width_type units.
gain, g:  Set the required gain or attenuation in dB. Beware of clipping when
          using a positive gain. 
--]]


-- ------- utils --------
function iff(cc, a, b) if cc then return a else return b end end
function ss(s, from, to) return s:sub(from, to - 1) end
--[[-- utils
local mp_msg   = require 'mp.msg'
function midwidth(min, max)  -- range --> middle freq and width in octaves
  local wo = math.log(max / min) / math.log(2)
  mp_msg.info(min, max / (2 ^ (wo / 2)) .. ' <' .. wo .. '>', max)
end
function range(f, wo)  -- middle freq and width in octaves --> range
  local h = 2 ^ (wo / 2)
  mp_msg.info(f / h, '' .. f .. ' <' .. wo .. '>' , f * h)
end
--]]

-- return the filter as numbers {frequency, gain}
local function filter_data(filter)
  return { tonumber(ss(filter[1], 13, filter[1]:find(':', 14, true))), filter[2] }
end

-- the mpv command string for adding the filter (only used when gain != 0)
local function get_cmd(filter)
  return 'no-osd af add lavfi=[' .. filter[1] .. filter[2] .. ']'
end

-- these two vars are used globally
local bindings_enabled = start_keys_enabled
local eq_enabled = true  -- but af is not touched before the equalizer is modified


-- ------ OSD handling -------
local function ass(x)
  -- local gpo = mp.get_property_osd
  -- return gpo('osd-ass-cc/0') .. x .. gpo('osd-ass-cc/1')

  -- seemingly it's impossible to enable ass escaping with mp.set_osd_ass,
  -- so we're already in ass mode, and no need to unescape first.
  return x
end

local function fsize(s)  -- 100 is the normal font size
  return ass('{\\fscx' .. s .. '\\fscy' .. s ..'}')
end

local function color(c)  -- c is RRGGBB
  return ass('{\\1c&H' .. ss(c, 5, 7) .. ss(c, 3, 5) .. ss(c, 1, 3) .. '&}')
end

local function cnorm() return color('ffffff') end  -- white
local function cdis()  return color('909090') end  -- grey
local function ceq()   return iff(eq_enabled, color('ffff90'), cdis()) end  -- yellow-ish
local function ckeys() return iff(bindings_enabled, color('90FF90'), cdis()) end  -- green-ish

local DUR_DEFAULT = 1.5 -- seconds
local osd_timer = nil
-- duration: seconds, or default if missing/nil, or infinite if 0 (or negative)
local function ass_osd(msg, duration)  -- empty or missing msg -> just clears the OSD
  duration = duration or DUR_DEFAULT
  if not msg or msg == '' then
    msg = '{}'  -- the API ignores empty string, but '{}' works to clean it up
    duration = 0
  end
  mp.set_osd_ass(0, 0, msg)
  if osd_timer then
    osd_timer:kill()
    osd_timer = nil
  end
  if duration > 0 then
    osd_timer = mp.add_timeout(duration, ass_osd)  -- ass_osd() clears without a timer
  end
end

-- some visual messing about
local function updateOSD()
  local msg1 = fsize(70) .. 'Equalizer: ' .. ceq() .. iff(eq_enabled, 'On', 'Off')
            .. ' [' .. key_toggle_equalizer .. ']' .. cnorm()
  local msg2 = fsize(70)
            .. 'Key-bindings: ' .. ckeys() .. iff(bindings_enabled, 'On', 'Off')
            .. ' [' .. key_toggle_bindings .. ']' .. cnorm()
  local msg3 = ''

  for i = 1, #bands do
    local data = filter_data(bands[i].filter)
    local info =
      ceq() .. fsize(50) .. data[1] .. ' hz ' .. fsize(100)
      .. iff(data[2] ~= 0 and eq_enabled, '', cdis()) .. data[2] .. ceq()
      .. fsize(50) .. ckeys() .. ' [' .. bands[i].keys[1] .. '/' .. bands[i].keys[2] .. ']'
      .. ceq() .. fsize(100) .. cnorm()

    msg3 = msg3 .. iff(i > 1, '   ', '') .. info
  end

  local nlb = '\n' .. ass('{\\an1}')  -- new line and "align bottom for next"
  local msg = ass('{\\an1}') .. msg3 .. nlb .. msg2 .. nlb .. msg1
  local duration = iff(start_keys_enabled, iff(bindings_enabled and eq_enabled, 5, nil)
                                         , iff(bindings_enabled, 0, nil))
  ass_osd(msg, duration)
end


-- ------- actual functionality ------
local function updateAF()  -- setup an audio filter chain which applies the equalizer
  mp.command('no-osd af clr ""')  -- af clr must have two double-quotes
  if not eq_enabled then return end

  for i = 1, #bands do
    local f = bands[i].filter
    if f[2] ~= 0 then  -- insert filters only were the gain is non default
      mp.command(get_cmd(f))
    end
  end
end

local function getBind(filter, delta)
  return function()  -- onKey
    filter[2] = filter[2] + delta
    updateAF()
    updateOSD()
  end
end

local function update_key_binding(enable, key, name, fn)
  if enable then
    mp.add_forced_key_binding(key, name, fn, 'repeatable')
  else
    mp.remove_key_binding(name)
  end
end

local function toggle_bindings(explicit, no_osd)
  bindings_enabled = iff(explicit ~= nil, explicit, not bindings_enabled)
  for i = 1, #bands do
    local k = bands[i].keys
    local f = bands[i].filter
    update_key_binding(bindings_enabled, k[1], 'eq' .. k[1], getBind(f,  1)) -- up
    update_key_binding(bindings_enabled, k[2], 'eq' .. k[2], getBind(f, -1)) -- down
  end
  if not no_osd then updateOSD() end
end

local function toggle_equalizer()
  eq_enabled = not eq_enabled
  updateAF()
  updateOSD()
end

local function reset_equalizer()
  for i = 1, #bands do
    bands[i].filter[2] = 0
  end
  updateAF()
  updateOSD()
end

mp.add_forced_key_binding(key_toggle_equalizer, toggle_equalizer)
mp.add_forced_key_binding(key_toggle_bindings, toggle_bindings)
mp.add_forced_key_binding(key_reset_equalizer, reset_equalizer)
if bindings_enabled then toggle_bindings(true, true) end