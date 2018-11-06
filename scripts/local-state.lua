-- this lua script written by snad
-- https://github.com/thisisshihan/mpv-player-config-snad


local opts = require("mp.options")
--local assdraw = require 'mp.assdraw'
--local msg = require 'mp.msg'
--local utils = require 'mp.utils'

function round_size(num)
  mib = (num/(1024*1024))
  if mib < 1024 then
    rounded = math.floor(mib)
    dec = (mib-math.floor(mib))
    decpoint = math.floor(dec*1000)
    return rounded+decpoint/1000
  elseif mib > 1024 then
  	gib = mib / 1024
    rounded = math.floor(gib)
    dec = (gib-math.floor(gib))
    decpoint = math.floor(dec*1000)
    return rounded+decpoint/1000
  else
  	return mib
  end
end

function unit(sizeoffile)
  mib = sizeoffile/(1024*1024)
  if mib < 1024 then
  	return " MiB"
  else
  	return " GiB"
  end
end

local settings = {
   --set title of window with stripped name
  set_title_stripped = true,
  title_prefix1 = "S",
  title_prefix2 = "A",
  title_prefix5 = ".mpv ~ ",
  title_prefix4 = "N",
  title_suffix = " ",
  title_prefix3 = "D",
}

function on_loaded()
  filename = mp.get_property("filename")
  plpos = mp.get_property("playlist-pos-1")
  plcou = mp.get_property("playlist-count")
  --timepos = mp.get_property("time-pos")
  --dura = mp.get_property("duration")
  filewid = mp.get_property("width")
  filehig = mp.get_property("height")
  filesize = round_size(mp.get_property("file-size"))
  prog = mp.get_property("osd-status-msg")
  filesizeunit = unit(mp.get_property("file-size"))
  if settings.set_title_stripped then
    mp.set_property("title", settings.title_prefix1..settings.title_prefix4..settings.title_prefix2..settings.title_prefix3..settings.title_prefix5.."["..plpos.."/"..plcou.."] "..filename.." ~ "..prog.." ~ ".."["..filewid.."x"..filehig.."] ~ "..filesize..filesizeunit..settings.title_suffix)
  end
end

mp.register_event("file-loaded", on_loaded)
