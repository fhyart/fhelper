-- fHelper for MoonLoader (Arizona RP)
-- /fhelp opens the menu, /fhelpreload reloads it if the window sticks.
-- UTF-8 file. ImGui gets these strings as UTF-8. Chat is converted to CP1251.

local VER = '1.11.1'
script_name('fHelper')
script_author('fhelp')
script_version(VER)
script_version_number(17)
script_description('fHelper. Команда /fhelp')
script_properties('work-in-pause')

local imgui_ok, imgui = pcall(require, 'mimgui')
local enc_ok, encoding = pcall(require, 'encoding')
local fa_ok, fa = pcall(require, 'fAwesome5')
local lfs_ok, lfs = pcall(require, 'lfs')
local ffi_ok, ffi = pcall(require, 'ffi')
if enc_ok then encoding.default = 'CP1251' end

local show = false
local hidden = false
local page = 'home'
local collapsed = false
local maximized = false
local placed = false
local force_center = false
local capture = false
local dirty = false
local save_at = 0
-- Play time and traffic change every frame, so they go to disk less often.
local stat_dirty = false
local stat_at = 0
local modal = nil
local job = nil
local chats = {}
local logs = {}
local notes = {}
local binds = {}
local favs = {}
local filter_cat, filter_st = 'Все', 'Все'
local bind_vk, bind_kind = 0, 'page'
local capture_what = 'menu'
local show_details = false
local file_list = {}
local need_scan = true
local notice = ''
local notice_t = 0
local booted = 0
local fps = 0
local release_back = false
local release_until = 0
local anim = 0
local anim_from = 0
local anim_goal = 0
local anim_t0 = 0
local user_drag = false
local disk_stamp = nil
local disk_wait = nil
local boot_try = 0
local font_main, font_bold, font_title
local font_ranges, font_builder, fa_range
local font_keep = {}
local font_warn = ''
local frame = nil
local hud_frame = nil

local cfg = {
  notify = 1,
  opacity = 1,
  key = 0,
  open = 0,
  x = -1,
  y = -1,
  last = '',
  lock = 1,
  scale = 1,
  hidekey = 0,
  bg = 1,
  hud_fps = 1,
  hud_net = 1,
  hud_ping = 1,
  hud_place = 1,
  hud_x = 78,
  hud_y = 4,
  hud_scale = 1,
  draw = 800,
  draw_on = 0,
  fps_free = 0,
  accent_on = 1,
  accent = '',
  off = 0,
  money_real = -1,
  bank = -1,
  depo = -1,
  seen_ver = '',
  calc_win = 0,
  calc_mode = 0,
  calc_pad = 1,
  calc_key = 0,
  calc_x = -1,
  calc_y = -1,
  fav_mode = 0,
  fav_close = 0,
  proj = 'arz',
  alt_money_real = -1,
  alt_bank = -1,
  alt_depo = -1,
  time_on = 1,
  time_mode = 0,
  time_utc = 3,
  time_clock = 1,
  time_sec = 1,
  time_date = 1,
  time_wday = 0,
  time_zone = 1,
  time_h12 = 0,
  time_fmt = 0,
  time_place = 0,
  time_x = 50,
  time_y = 94,
  time_scale = 1,
  car_on = 1,
  car_bar = 1,
  inc_per = 1,
  inc_from = 0,
  inc_to = 0,
  toast_on = 1,
  toast_pay = 1,
  toast_inc = 1,
  toast_exp = 1,
  toast_item = 1,
  toast_car = 1,
  toast_sys = 0,
  toast_min = 0,
  toast_place = 0,
  toast_x = 98,
  toast_y = 30,
  toast_scale = 1,
  toast_w = 320,
  toast_alpha = 0.94,
  toast_time = 6,
  toast_max = 5,
  toast_menu = 1,
  toast_merge = 1,
  toast_sound = 0,
  toast_bar = 1,
  upd_on = 1,
  upd_skip = 0,
  shop_on = 1,
}

-- Saved as plain numbers, each with its allowed range.
local CFG_NUM = {
  {'alt_money_real', -1, 1e15}, {'alt_bank', -1, 1e15}, {'alt_depo', -1, 1e15},
  {'time_on', 0, 1}, {'time_mode', 0, 2}, {'time_utc', -12, 14}, {'time_clock', 0, 1}, {'time_sec', 0, 1},
  {'time_date', 0, 1}, {'time_wday', 0, 1}, {'time_zone', 0, 1}, {'time_h12', 0, 1}, {'time_fmt', 0, 3},
  {'time_place', 0, 1}, {'time_x', 0, 100}, {'time_y', 0, 100}, {'time_scale', 0.6, 2},
  {'car_on', 0, 1}, {'car_bar', 0, 1},
  {'inc_per', 1, 7}, {'inc_from', 0, 999999999999}, {'inc_to', 0, 999999999999},
  {'toast_on', 0, 1}, {'toast_pay', 0, 1}, {'toast_inc', 0, 1}, {'toast_exp', 0, 1}, {'toast_item', 0, 1},
  {'toast_car', 0, 1}, {'toast_sys', 0, 1}, {'toast_min', 0, 1e12}, {'toast_place', 0, 4},
  {'toast_x', 0, 100}, {'toast_y', 0, 100}, {'toast_scale', 0.6, 2}, {'toast_w', 220, 520},
  {'toast_alpha', 0.3, 1}, {'toast_time', 2, 30}, {'toast_max', 1, 10}, {'toast_menu', 0, 1},
  {'toast_merge', 0, 1}, {'toast_sound', 0, 1}, {'toast_bar', 0, 1},
  {'upd_on', 0, 1}, {'upd_skip', 0, 1e9}, {'shop_on', 0, 1},
}

local net ={inn = 0, outn = 0, sin = 0, sout = 0, bw = 210, bh = 58, force = false}

local play = {
  total = 0,
  day = 0,
  day_id = '',
  session = 0,
  server = '',
  beat = 0,
  online = false,
  slice = 0,
}

local live = {
  nick = '—',
  nick_raw = '',
  id = '—',
  ping = '—',
  server = '—',
  ip = '—',
  fps = '—',
  session = '00:00:00',
  players = '—',
  online = false,
  money = '—',
  health = '—',
  armour = '—',
  score = '—',
  wanted = '—',
  zone = '—',
  pos = '—',
  weapon = '—',
  veh = '—',
  clock = '—',
  interior = '—',
}

local ui_opacity, ui_notify, ui_lock, ui_search
local ui_cmd, ui_fav, ui_bind, ui_scale, ui_hfps, ui_hnet, ui_hudx, ui_hudy
local ui_hudscale, ui_hping, ui_draw, ui_drawon, ui_fpsfree, ui_ntype, ui_ntext
if imgui_ok then
  ui_opacity = imgui.new.float(100)
  ui_notify = imgui.new.bool(true)
  ui_lock = imgui.new.bool(true)
  ui_search = imgui.new.char[80]()
  ui_cmd = imgui.new.char[180]()
  ui_fav = imgui.new.char[180]()
  ui_bind = imgui.new.char[240]()
  ui_scale = imgui.new.float(100)
  ui_hfps = imgui.new.bool(true)
  ui_hnet = imgui.new.bool(true)
  ui_hudx = imgui.new.float(78)
  ui_hudy = imgui.new.float(4)
  ui_hudscale = imgui.new.float(100)
  ui_hping = imgui.new.bool(true)
  ui_draw = imgui.new.float(800)
  ui_drawon = imgui.new.bool(false)
  ui_fpsfree = imgui.new.bool(false)
  ui_ntype = imgui.new.char[80]()
  ui_ntext = imgui.new.char[2048]()
end

-- Newer fields live in one table, the main chunk is close to the local limit.
local ui = {}
if imgui_ok then
  ui.calc = imgui.new.char[160]()
  ui.int_q = imgui.new.char[80]()
  ui.lib_q = imgui.new.char[80]()
  ui.led_q = imgui.new.char[80]()
  ui.note_q = imgui.new.char[80]()
  ui.clog_q = imgui.new.char[80]()
  ui.fav_text = imgui.new.char[240]()
  ui.fav_label = imgui.new.char[80]()
  ui.fav_group = imgui.new.char[60]()
  ui.craft_name = imgui.new.char[120]()
  ui.craft_tries = imgui.new.char[24]()
  ui.craft_chance = imgui.new.char[24]()
  ui.craft_out = imgui.new.char[24]()
  ui.craft_sell = imgui.new.char[24]()
  ui.time_utc = imgui.new.float(3)
  ui.time_x = imgui.new.float(50)
  ui.time_y = imgui.new.float(94)
  ui.time_scale = imgui.new.float(100)
  ui.car_q = imgui.new.char[80]()
  ui.car_alias = imgui.new.char[60]()
  ui.item_q = imgui.new.char[80]()
  ui.shop_q = imgui.new.char[80]()
  ui.rng_h = imgui.new.float(0)
  ui.rng_m = imgui.new.float(0)
  ui.toast_x = imgui.new.float(98)
  ui.toast_y = imgui.new.float(30)
  ui.toast_scale = imgui.new.float(100)
  ui.toast_w = imgui.new.float(320)
  ui.toast_alpha = imgui.new.float(94)
  ui.toast_time = imgui.new.float(6)
  ui.toast_max = imgui.new.float(5)
end

local NAV = {
  {'home', 'ICON_FA_HOME', 'Главная'},
  {'income', 'ICON_FA_COINS', 'Доходы'},
  {'chat', 'ICON_FA_COMMENTS', 'Чат'},
  {'scripts', 'ICON_FA_CODE', 'Скрипты'},
  {'binds', 'ICON_FA_BOLT', 'Бинды'},
  {'notes', 'ICON_FA_STICKY_NOTE', 'Заметки'},
  {'calc', 'ICON_FA_CALCULATOR', 'Калькулятор'},
  {'craft', 'ICON_FA_HAMMER', 'Крафт'},
  {'hotkeys', 'ICON_FA_KEYBOARD', 'Клавиши'},
  {'screen', 'ICON_FA_DESKTOP', 'Экран'},
  {'exp', 'ICON_FA_FLASK', 'Эксперимент'},
  {'logs', 'ICON_FA_FILE_ALT', 'Журнал'},
  {'settings', 'ICON_FA_COG', 'Настройки'},
}

local F = {}
function F.wd()
  return getWorkingDirectory()
end

function F.cfg_dir()
  return F.wd() .. '\\config'
end

function F.cfg_path()
  return F.cfg_dir() .. '\\fhelp.ini'
end

-- The script works for one project at a time, switching restarts it.
F.PROJ = {
  arz = {name = 'Arizona RP', folder = 'arizona', pack = 'fhelp_lib'},
  rod = {name = 'Rodina RP', folder = 'rodina', pack = 'fhelp_lib_rodina'},
}

function F.proj()
  return F.PROJ[cfg.proj] or F.PROJ.arz
end

function F.is_rod()
  return cfg.proj == 'rod'
end

-- Money and items differ between the projects, so these files are kept apart.
F.PROJ_FILES = {
  ['fhelp_income.txt'] = true, ['fhelp_ledger.txt'] = true,
  ['fhelp_ints.txt'] = true, ['fhelp_craft.txt'] = true,
  ['fhelp_cars.txt'] = true, ['fhelp_items.txt'] = true, ['fhelp_shops.txt'] = true,
}

function F.log_path()
  return F.cfg_dir() .. '\\fhelp.log'
end

function F.mkdir(path)
  if doesDirectoryExist(path) then return true end
  createDirectory(path)
  return doesDirectoryExist(path)
end

local RU_LOW = {
  ['А']='а',['Б']='б',['В']='в',['Г']='г',['Д']='д',['Е']='е',['Ё']='ё',
  ['Ж']='ж',['З']='з',['И']='и',['Й']='й',['К']='к',['Л']='л',['М']='м',
  ['Н']='н',['О']='о',['П']='п',['Р']='р',['С']='с',['Т']='т',['У']='у',
  ['Ф']='ф',['Х']='х',['Ц']='ц',['Ч']='ч',['Ш']='ш',['Щ']='щ',['Ъ']='ъ',
  ['Ы']='ы',['Ь']='ь',['Э']='э',['Ю']='ю',['Я']='я',
}

function F.lower_text(s)
  s = tostring(s or ''):lower()
  for up, low in pairs(RU_LOW) do
    if s:find(up, 1, true) then s = s:gsub(up, low) end
  end
  return s
end

function F.trim(s)
  if not s then return '' end
  s = s:gsub('^%s+', ''):gsub('%s+$', '')
  s = s:gsub('%z', '')
  return s
end

function F.plain_samp(s)
  s = tostring(s or '')
  s = s:gsub('{%x+}', '')
  return F.trim(s)
end

function F.faico(key)
  if not fa_ok or not fa or not fa[key] then return '' end
  return fa[key]
end

function F.utf8_ok(s)
  local i, n = 1, #s
  while i <= n do
    local b = s:byte(i)
    local len
    if b < 128 then len = 1
    elseif b >= 194 and b <= 223 then len = 2
    elseif b >= 224 and b <= 239 then len = 3
    elseif b >= 240 and b <= 244 then len = 4
    else return false end
    if i + len - 1 > n then return false end
    for j = 2, len do
      local c = s:byte(i + j - 1)
      if c < 128 or c > 191 then return false end
    end
    i = i + len
  end
  return true
end

function F.qmark(s)
  return tostring(s or ''):match('^%?+$') ~= nil
end

function F.game_text(s)
  s = F.plain_samp(s)
  if s == '' or F.qmark(s) then return '' end
  if not s:find('[\128-\255]') then return s end
  if F.utf8_ok(s) then return s end
  if not enc_ok then return '' end
  local ok, out = pcall(function() return encoding.UTF8:encode(s) end)
  if ok and type(out) == 'string' and out ~= '' and not F.qmark(out) then return out end
  return ''
end

function F.to_utf8(s)
  local out = F.game_text(s)
  if out == '' then return '—' end
  return out
end

function F.fmt_money(n)
  n = tonumber(n)
  if not n then return nil end
  local neg = n < 0
  n = math.floor(math.abs(n) + 0.5)
  -- tostring turns big sums into 1e+15, %.0f never does.
  local s = string.format('%.0f', n)
  local parts = {}
  while #s > 3 do
    parts[#parts + 1] = s:sub(-3)
    s = s:sub(1, -4)
  end
  parts[#parts + 1] = s
  local body = ''
  for i = #parts, 1, -1 do
    if body ~= '' then body = body .. ' ' end
    body = body .. parts[i]
  end
  if F.is_rod() then return (neg and '-' or '') .. body .. ' руб.' end
  if neg then return '-$' .. body end
  return '$' .. body
end

function F.to_cp(s)
  if not s then return '' end
  if not enc_ok then return s end
  local ok, out = pcall(function() return encoding.UTF8:decode(s) end)
  if ok and out then return out end
  return s
end

function F.key_name(vk)
  vk = tonumber(vk) or 0
  if vk == 0 then return 'нет' end
  if vk >= 0x30 and vk <= 0x39 then return string.char(vk) end
  if vk >= 0x41 and vk <= 0x5A then return string.char(vk) end
  if vk >= 0x60 and vk <= 0x69 then return 'Num ' .. tostring(vk - 0x60) end
  if vk >= 0x70 and vk <= 0x87 then return 'F' .. tostring(vk - 0x6F) end
  local names = {
    [0x08] = 'Backspace', [0x09] = 'Tab', [0x0D] = 'Enter', [0x10] = 'Shift',
    [0x11] = 'Ctrl', [0x12] = 'Alt', [0x14] = 'Caps', [0x1B] = 'Esc',
    [0x20] = 'Space', [0x21] = 'Page Up', [0x22] = 'Page Down',
    [0x23] = 'End', [0x24] = 'Home', [0x25] = 'Left', [0x26] = 'Up',
    [0x27] = 'Right', [0x28] = 'Down', [0x2D] = 'Insert', [0x2E] = 'Delete',
    [0x5B] = 'Win', [0x5C] = 'Win', [0xFF] = 'Fn',
    [0xA0] = 'Shift', [0xA1] = 'Shift', [0xA2] = 'Ctrl', [0xA3] = 'Ctrl',
    [0xA4] = 'Alt', [0xA5] = 'Alt',
    [0x6A] = 'Num *', [0x6B] = 'Num +', [0x6D] = 'Num -', [0x6E] = 'Num .', [0x6F] = 'Num /',
    [0x13] = 'Pause', [0x91] = 'Scroll Lock', [0x90] = 'Num Lock', [0x2C] = 'Print Screen',
    [0xBA] = ';', [0xBB] = '=', [0xBC] = ',', [0xBD] = '-', [0xBE] = '.', [0xBF] = '/',
    [0xC0] = '`', [0xDB] = '[', [0xDC] = '\\', [0xDD] = ']', [0xDE] = "'", [0xE2] = '\\',
  }
  return names[vk] or ('VK ' .. tostring(vk))
end

function F.mod_bit(vk)
  if vk == 0x11 or vk == 0xA2 or vk == 0xA3 then return 1 end
  if vk == 0x12 or vk == 0xA4 or vk == 0xA5 then return 2 end
  if vk == 0x10 or vk == 0xA0 or vk == 0xA1 then return 4 end
  if vk == 0x5B or vk == 0x5C then return 8 end
  if vk == 0xFF then return 16 end
  return 0
end

function F.is_mod_vk(vk)
  return F.mod_bit(vk) ~= 0
end

function F.mods_mask()
  local m = 0
  if isKeyDown(0x11) or isKeyDown(0xA2) or isKeyDown(0xA3) then m = m + 1 end
  if isKeyDown(0x12) or isKeyDown(0xA4) or isKeyDown(0xA5) then m = m + 2 end
  if isKeyDown(0x10) or isKeyDown(0xA0) or isKeyDown(0xA1) then m = m + 4 end
  if isKeyDown(0x5B) or isKeyDown(0x5C) then m = m + 8 end
  if isKeyDown(0xFF) then m = m + 16 end
  return m
end

function F.bitlib()
  if F._bit ~= nil then return F._bit or nil end
  local ok, lib = pcall(require, 'bit')
  if ok and type(lib) == 'table' then F._bit = lib else F._bit = false end
  return F._bit or nil
end

function F.band(a, b)
  local lib = F.bitlib()
  if not lib then return 0 end
  return lib.band(a or 0, b or 0)
end

function F.bor(a, b)
  local lib = F.bitlib()
  if not lib then return a or 0 end
  return lib.bor(a or 0, b or 0)
end

function F.bnot(a)
  local lib = F.bitlib()
  if not lib then return 0 end
  return lib.bnot(a or 0)
end

function F.held_mods(vk)
  local held = F.mods_mask()
  local own = F.mod_bit(vk)
  if own ~= 0 then held = F.band(held, F.bnot(own)) end
  return held
end

function F.chord_name(vk, mods)
  local names = {}
  mods = tonumber(mods) or 0
  if F.band(mods, 1) ~= 0 then names[#names + 1] = 'Ctrl' end
  if F.band(mods, 2) ~= 0 then names[#names + 1] = 'Alt' end
  if F.band(mods, 4) ~= 0 then names[#names + 1] = 'Shift' end
  if F.band(mods, 8) ~= 0 then names[#names + 1] = 'Win' end
  if F.band(mods, 16) ~= 0 then names[#names + 1] = 'Fn' end
  vk = tonumber(vk) or 0
  if vk ~= 0 then names[#names + 1] = F.key_name(vk) end
  if #names == 0 then return 'нет' end
  return table.concat(names, ' + ')
end

function F.log_line(msg)
  msg = tostring(msg or '')
  local low = msg:lower()
  if low:find('password', 1, true) or low:find('token', 1, true) or low:find('парол', 1, true) or low:find('/login', 1, true) then
    msg = 'Запись скрыта'
  end
  notes[#notes + 1] = {t = os.date('%H:%M'), text = msg}
  if #notes > 40 then table.remove(notes, 1) end
  local line = os.date('%Y-%m-%d %H:%M:%S') .. '  ' .. msg
  logs[#logs + 1] = line
  if #logs > 3000 then table.remove(logs, 1) end
  pcall(function()
    F.mkdir(F.cfg_dir())
    if lfs_ok then
      local size = lfs.attributes(F.log_path(), 'size')
      if size and size > 262144 then
        os.remove(F.log_path() .. '.old')
        os.rename(F.log_path(), F.log_path() .. '.old')
      end
    end
    local f = io.open(F.log_path(), 'a')
    if f then
      f:write(line .. '\n')
      f:close()
    end
  end)
end

function F.notify(msg, skip_chat)
  F.log_line(msg)
  notice = msg
  notice_t = os.clock() + 3.5
  if not skip_chat and cfg.notify == 1 then
    chats[#chats + 1] = msg
  end
  -- With the menu open its own line already shows the message.
  if not show and cfg.toast_sys == 1 and F.toast then
    F.toast('sys', {key = 'sys' .. msg, icon = 'ICON_FA_INFO_CIRCLE', title = 'fHelper', text = msg})
  end
end

function F.load_log()
  local f = io.open(F.log_path(), 'r')
  if not f then return end
  local all = {}
  for line in f:lines() do
    all[#all + 1] = line
  end
  f:close()
  local from = #all - 2999
  if from < 1 then from = 1 end
  logs = {}
  for i = from, #all do
    logs[#logs + 1] = all[i]
  end
end

function F.load_cfg()
  local f = io.open(F.cfg_path(), 'r')
  if not f then return end
  for line in f:lines() do
    local k, v = line:match('^([%w_]+)=(.*)$')
    if k == 'notify' then cfg.notify = tonumber(v) == 1 and 1 or 0
    elseif k == 'opacity' then cfg.opacity = tonumber(v) or 1
    elseif k == 'key' then cfg.key = tonumber(v) or 0
    elseif k == 'open' then cfg.open = tonumber(v) == 1 and 1 or 0
    elseif k == 'x' then cfg.x = tonumber(v) or -1
    elseif k == 'y' then cfg.y = tonumber(v) or -1
    elseif k == 'last' then cfg.last = v or ''
    elseif k == 'lock' then cfg.lock = tonumber(v) == 0 and 0 or 1
    elseif k == 'play_total' then play.total = tonumber(v) or 0
    elseif k == 'play_day' then play.day = tonumber(v) or 0
    elseif k == 'play_day_id' then play.day_id = v or ''
    elseif k == 'play_session' then play.session = tonumber(v) or 0
    elseif k == 'play_server' then play.server = v or ''
    elseif k == 'play_beat' then play.beat = tonumber(v) or 0
    elseif k == 'scale' then cfg.scale = tonumber(v) or 1
    elseif k == 'hidekey' then cfg.hidekey = tonumber(v) or 0
    elseif k == 'bg' then cfg.bg = tonumber(v) == 0 and 0 or 1
    elseif k == 'hud_fps' then cfg.hud_fps = tonumber(v) == 0 and 0 or 1
    elseif k == 'hud_net' then cfg.hud_net = tonumber(v) == 0 and 0 or 1
    elseif k == 'hud_ping' then cfg.hud_ping = tonumber(v) == 0 and 0 or 1
    elseif k == 'hud_place' then cfg.hud_place = tonumber(v) or 1
    elseif k == 'hud_x' then cfg.hud_x = tonumber(v) or 78
    elseif k == 'hud_y' then cfg.hud_y = tonumber(v) or 4
    elseif k == 'hud_scale' then cfg.hud_scale = tonumber(v) or 1
    elseif k == 'draw' then cfg.draw = tonumber(v) or 800
    elseif k == 'draw_on' then cfg.draw_on = tonumber(v) == 1 and 1 or 0
    elseif k == 'fps_free' then cfg.fps_free = tonumber(v) == 1 and 1 or 0
    elseif k == 'accent_on' then cfg.accent_on = tonumber(v) == 0 and 0 or 1
    elseif k == 'accent' then cfg.accent = (v or ''):gsub('[\r\n]', '')
    elseif k == 'net_in' then net.inn = tonumber(v) or 0
    elseif k == 'net_out' then net.outn = tonumber(v) or 0
    elseif k == 'off' then cfg.off = tonumber(v) == 1 and 1 or 0
    elseif k == 'money_real' then cfg.money_real = tonumber(v) or -1
    elseif k == 'bank' then cfg.bank = tonumber(v) or -1
    elseif k == 'depo' then cfg.depo = tonumber(v) or -1
    elseif k == 'seen_ver' then cfg.seen_ver = v or ''
    elseif k == 'calc_win' then cfg.calc_win = tonumber(v) == 1 and 1 or 0
    elseif k == 'calc_mode' then cfg.calc_mode = tonumber(v) == 1 and 1 or 0
    elseif k == 'calc_pad' then cfg.calc_pad = tonumber(v) == 0 and 0 or 1
    elseif k == 'calc_key' then cfg.calc_key = tonumber(v) or 0
    elseif k == 'calc_x' then cfg.calc_x = tonumber(v) or -1
    elseif k == 'calc_y' then cfg.calc_y = tonumber(v) or -1
    elseif k == 'fav_mode' then cfg.fav_mode = tonumber(v) or 0
    elseif k == 'fav_close' then cfg.fav_close = tonumber(v) == 1 and 1 or 0
    elseif k == 'proj' then cfg.proj = F.PROJ[v] and v or 'arz'
    elseif k then
      for i = 1, #CFG_NUM do
        local row = CFG_NUM[i]
        local n = tonumber(v)
        if row[1] == k and n then cfg[k] = math.max(row[2], math.min(row[3], n)) end
      end
    end
  end
  f:close()
  if cfg.fav_mode < 0 or cfg.fav_mode > 2 then cfg.fav_mode = 0 end
  if cfg.calc_key == 0x1B then cfg.calc_key = 0 end
  if cfg.hud_place < 0 or cfg.hud_place > 4 then cfg.hud_place = 1 end
  if cfg.hud_x < 0 then cfg.hud_x = 0 elseif cfg.hud_x > 100 then cfg.hud_x = 100 end
  if cfg.hud_y < 0 then cfg.hud_y = 0 elseif cfg.hud_y > 100 then cfg.hud_y = 100 end
  if net.inn < 0 then net.inn = 0 end
  if net.outn < 0 then net.outn = 0 end
  if cfg.opacity < 0.82 then cfg.opacity = 0.82 end
  if cfg.opacity > 1 then cfg.opacity = 1 end
  if cfg.scale < 0.85 then cfg.scale = 0.85 end
  if cfg.scale > 1.2 then cfg.scale = 1.2 end
  if not cfg.hud_scale or cfg.hud_scale < 0.6 then cfg.hud_scale = 0.6 end
  if cfg.hud_scale > 2 then cfg.hud_scale = 2 end
  if not cfg.draw or cfg.draw < 300 then cfg.draw = 300 end
  if cfg.draw > 1500 then cfg.draw = 1500 end
  if cfg.key == 0x1B then cfg.key = 0 end
  if cfg.hidekey == 0x1B then cfg.hidekey = 0 end
  -- With one key for both, the menu always wins and hiding never fires.
  if cfg.hidekey ~= 0 and cfg.hidekey == cfg.key then cfg.hidekey = 0 end
  cfg.accent = F.accent_clean(cfg.accent)
end

function F.save_cfg()
  F.mkdir(F.cfg_dir())
  local f = io.open(F.cfg_path(), 'w')
  if not f then return end
  f:write('notify=' .. (cfg.notify == 1 and '1' or '0') .. '\n')
  f:write('opacity=' .. string.format('%.3f', cfg.opacity) .. '\n')
  f:write('key=' .. tostring(cfg.key or 0) .. '\n')
  f:write('open=' .. tostring(cfg.open or 0) .. '\n')
  f:write('x=' .. tostring(math.floor(cfg.x or -1)) .. '\n')
  f:write('y=' .. tostring(math.floor(cfg.y or -1)) .. '\n')
  f:write('last=' .. (cfg.last or ''):gsub('[\r\n]', '') .. '\n')
  f:write('lock=' .. (cfg.lock == 1 and '1' or '0') .. '\n')
  f:write('play_total=' .. tostring(math.floor(play.total or 0)) .. '\n')
  f:write('play_day=' .. tostring(math.floor(play.day or 0)) .. '\n')
  f:write('play_day_id=' .. (play.day_id or '') .. '\n')
  f:write('play_session=' .. tostring(math.floor(play.session or 0)) .. '\n')
  f:write('play_server=' .. (play.server or ''):gsub('[\r\n]', '') .. '\n')
  f:write('play_beat=' .. tostring(math.floor(play.beat or 0)) .. '\n')
  f:write('scale=' .. string.format('%.2f', cfg.scale or 1) .. '\n')
  f:write('hidekey=' .. tostring(cfg.hidekey or 0) .. '\n')
  f:write('bg=' .. (cfg.bg == 1 and '1' or '0') .. '\n')
  f:write('hud_fps=' .. (cfg.hud_fps == 1 and '1' or '0') .. '\n')
  f:write('hud_net=' .. (cfg.hud_net == 1 and '1' or '0') .. '\n')
  f:write('hud_ping=' .. (cfg.hud_ping == 1 and '1' or '0') .. '\n')
  f:write('hud_place=' .. tostring(cfg.hud_place or 1) .. '\n')
  f:write('hud_x=' .. string.format('%.1f', cfg.hud_x or 0) .. '\n')
  f:write('hud_y=' .. string.format('%.1f', cfg.hud_y or 0) .. '\n')
  f:write('hud_scale=' .. string.format('%.2f', cfg.hud_scale or 1) .. '\n')
  f:write('draw=' .. tostring(math.floor(cfg.draw or 800)) .. '\n')
  f:write('draw_on=' .. (cfg.draw_on == 1 and '1' or '0') .. '\n')
  f:write('fps_free=' .. (cfg.fps_free == 1 and '1' or '0') .. '\n')
  f:write('accent_on=' .. (cfg.accent_on == 0 and '0' or '1') .. '\n')
  f:write('accent=' .. (cfg.accent or ''):gsub('[\r\n]', '') .. '\n')
  f:write('net_in=' .. tostring(math.floor(net.inn or 0)) .. '\n')
  f:write('net_out=' .. tostring(math.floor(net.outn or 0)) .. '\n')
  f:write('off=' .. (cfg.off == 1 and '1' or '0') .. '\n')
  f:write('money_real=' .. string.format('%.0f', cfg.money_real or -1) .. '\n')
  f:write('bank=' .. string.format('%.0f', cfg.bank or -1) .. '\n')
  f:write('depo=' .. string.format('%.0f', cfg.depo or -1) .. '\n')
  f:write('seen_ver=' .. (cfg.seen_ver or '') .. '\n')
  f:write('calc_win=' .. (cfg.calc_win == 1 and '1' or '0') .. '\n')
  f:write('calc_mode=' .. (cfg.calc_mode == 1 and '1' or '0') .. '\n')
  f:write('calc_pad=' .. (cfg.calc_pad == 0 and '0' or '1') .. '\n')
  f:write('calc_key=' .. tostring(cfg.calc_key or 0) .. '\n')
  f:write('calc_x=' .. tostring(math.floor(cfg.calc_x or -1)) .. '\n')
  f:write('calc_y=' .. tostring(math.floor(cfg.calc_y or -1)) .. '\n')
  f:write('fav_mode=' .. tostring(cfg.fav_mode or 0) .. '\n')
  f:write('fav_close=' .. (cfg.fav_close == 1 and '1' or '0') .. '\n')
  f:write('proj=' .. tostring(cfg.proj or 'arz') .. '\n')
  for i = 1, #CFG_NUM do
    local k = CFG_NUM[i][1]
    f:write(k .. '=' .. string.format('%.2f', cfg[k] or 0):gsub('%.?0+$', '') .. '\n')
  end
  f:close()
  dirty = false
  stat_dirty = false
end

function F.typing()
  if isSampAvailable() then
    if sampIsChatInputActive() or sampIsDialogActive() then return true end
  end
  local ok, pause = pcall(isPauseMenuActive)
  return ok and pause and true or false
end

local shell32

function F.prep_ffi()
  if not ffi_ok then return end
  pcall(ffi.cdef, 'int __stdcall ShellExecuteA(void* hwnd, const char* op, const char* file, const char* params, const char* dir, int show);')
  pcall(ffi.cdef, [[
    int __stdcall OpenClipboard(void* hwnd);
    int __stdcall CloseClipboard(void);
    void* __stdcall GetClipboardData(unsigned int fmt);
    int __stdcall IsClipboardFormatAvailable(unsigned int fmt);
    void* __stdcall GlobalLock(void* mem);
    int __stdcall GlobalUnlock(void* mem);
    int __stdcall WideCharToMultiByte(unsigned int cp, unsigned long flags, const unsigned short* src, int srclen, char* dst, int dstlen, const char* defch, int* used);
  ]])
  pcall(ffi.cdef, 'int __stdcall MultiByteToWideChar(unsigned int cp, unsigned long flags, const char* src, int srclen, wchar_t* dst, int dstlen);')
  pcall(ffi.cdef, [[
    void* __stdcall GlobalAlloc(unsigned int flags, unsigned long bytes);
    void* __stdcall GlobalFree(void* mem);
    int __stdcall EmptyClipboard(void);
    void* __stdcall SetClipboardData(unsigned int fmt, void* mem);
  ]])
  local ok, lib = pcall(ffi.load, 'shell32')
  if ok then shell32 = lib end
  local uok, user32 = pcall(ffi.load, 'user32')
  if uok then F.user32 = user32 end
  local kok, kernel32 = pcall(ffi.load, 'kernel32')
  if kok then F.kernel32 = kernel32 end
end

function F.shell_open(op, path)
  if not shell32 then
    F.notify('Не удалось открыть папку')
    return
  end
  local ok, rc = pcall(function()
    return shell32.ShellExecuteA(ffi.cast('void*', 0), op, path, nil, nil, 1)
  end)
  if not ok or not rc or tonumber(rc) == nil or tonumber(rc) <= 32 then
    F.notify('Не удалось открыть: ' .. path)
  end
end

function F.rel_path(path)
  local root = F.wd()
  local p = path:gsub('/', '\\')
  if p:sub(1, #root):lower() == root:lower() then
    p = p:sub(#root + 1):gsub('^\\', '')
  end
  return p
end

function F.find_loaded(path)
  local want = path:lower():gsub('/', '\\')
  local base = want:match('[^\\]+$') or want
  local loose = nil
  local loose_n = 0
  for _, s in ipairs(script.list()) do
    local sp = s.path and s.path:lower():gsub('/', '\\') or nil
    if sp == want then return s end
    if s.filename and s.filename:lower() == base then
      loose = s
      loose_n = loose_n + 1
    end
  end
  if loose_n == 1 then return loose end
  return nil
end

function F.is_self_path(path)
  local base = (path or ''):lower():match('[^\\]+$') or ''
  return base == 'fhelp.lua'
end

function F.peek_meta(path)
  local f = io.open(path, 'rb')
  if not f then return {ver = '', author = '', desc = ''}, false end
  local data = f:read(6000) or ''
  f:close()
  local function grab(key)
    return data:match(key .. "%s*%(%s*'([^']*)'") or data:match(key .. '%s*%(%s*"([^"]*)"') or ''
  end
  local low = data:lower()
  local warn = low:find('os.execute', 1, true) or low:find('io.popen', 1, true) or low:find('package.loadlib', 1, true)
  return {ver = grab('script_version'), author = grab('script_author'), desc = grab('script_description')}, warn and true or false
end

function F.guess_category(name, desc)
  local s = F.lower_text((name or '') .. ' ' .. (desc or ''))
  if s:find('fhelp', 1, true) then return 'Helper' end
  if s:find('hud', 1, true) or s:find('интерфей', 1, true) then return 'Интерфейс' end
  if s:find('транспорт', 1, true) or s:find('car', 1, true) or s:find('veh', 1, true) then return 'Транспорт' end
  if s:find('квест', 1, true) or s:find('quest', 1, true) then return 'Квесты' end
  if s:find('семь', 1, true) or s:find('family', 1, true) then return 'Семья' end
  return 'Скрипты'
end

local skip_dir = {
  lib = true,
  config = true,
  resource = true,
  fhelp_backup = true,
}

function F.scan_files()
  file_list = {}
  if not lfs_ok then
    -- Without lfs the scan would retry every frame.
    need_scan = false
    F.log_line('Модуль lfs недоступен')
    return
  end
  local root = F.wd()
  local function add_file(dir, name, prefix)
    if name:sub(1, 1) == '.' or name:sub(1, 1) == '#' then return end
    if name:lower() == 'fhelp_boot.lua' then return end
    if not name:lower():match('%.lua$') then return end
    local full = dir .. '\\' .. name
    if lfs.attributes(full, 'mode') ~= 'file' then return end
    if #file_list >= 400 then return end
    local loaded = F.find_loaded(full)
    local meta, warn = F.peek_meta(full)
    local ver = ''
    if loaded and loaded.version and loaded.version ~= '' then
      ver = tostring(loaded.version)
    elseif meta.ver ~= '' then
      ver = meta.ver
    end
    file_list[#file_list + 1] = {
      name = name,
      rel = prefix .. name,
      path = full,
      loaded = loaded ~= nil,
      version = ver,
      self = F.is_self_path(full),
      author = F.game_text(meta.author),
      desc = F.game_text(meta.desc),
      category = F.guess_category(name .. ' ' .. prefix, F.game_text(meta.desc)),
      warn = warn,
    }
  end
  local ok, err = pcall(function()
    for name in lfs.dir(root) do
      if name ~= '.' and name ~= '..' and name:sub(1, 1) ~= '#' and name:sub(1, 1) ~= '.' then
        local full = root .. '\\' .. name
        local mode = lfs.attributes(full, 'mode')
        if mode == 'file' then
          add_file(root, name, '')
        elseif mode == 'directory' and not skip_dir[name:lower()] then
          for sub in lfs.dir(full) do
            add_file(full, sub, name .. '\\')
          end
        end
      end
    end
  end)
  if not ok then
    F.log_line('Список скриптов: ' .. tostring(err))
  end
  table.sort(file_list, function(a, b) return a.rel:lower() < b.rel:lower() end)
  need_scan = false
end

function F.remember(path)
  if F.is_self_path(path) then return end
  cfg.last = F.rel_path(path)
  dirty = true
end

function F.perform(j)
  if j.op == 'reload_self' then
    cfg.open = 1
    F.save_cfg()
    F.log_line('Перезагрузка fhelp')
    thisScript():reload()
    return
  elseif j.op == 'reload_all' then
    local list = script.list()
    for i = 1, #list do
      local s = list[i]
      if s ~= script.this then
        pcall(function() s:reload() end)
      end
    end
    cfg.open = 1
    F.save_cfg()
    thisScript():reload()
    return
  elseif j.op == 'load' then
    local s = script.load(j.path)
    if s then
      F.remember(j.path)
      F.notify('Запущен ' .. F.rel_path(j.path))
      need_scan = true
    else
      F.notify('Не удалось запустить ' .. F.rel_path(j.path))
    end
  elseif j.op == 'reload' then
    local s = F.find_loaded(j.path)
    if not s then
      F.notify('Скрипт не запущен')
      return
    end
    if F.is_self_path(j.path) then
      F.perform({op = 'reload_self'})
      return
    end
    s:reload()
    F.remember(j.path)
    F.notify('Перезагружен ' .. F.rel_path(j.path))
    need_scan = true
  elseif j.op == 'unload' then
    local s = F.find_loaded(j.path)
    if not s then
      F.notify('Скрипт не запущен')
      return
    end
    local self = F.is_self_path(j.path)
    if self then
      -- fhelp_boot reads off=1 and does not start the helper again.
      cfg.open = 0
      cfg.off = 1
      F.save_cfg()
    end
    s:unload()
    if not self then
      F.notify('Выгружен ' .. F.rel_path(j.path))
      need_scan = true
    end
  elseif j.op == 'last' then
    if cfg.last == '' then
      F.notify('Сначала запустите скрипт из списка')
      return
    end
    local path = F.wd() .. '\\' .. cfg.last
    if not doesFileExist(path) then
      F.notify('Файл не найден: ' .. cfg.last)
      return
    end
    if F.is_self_path(path) then
      F.perform({op = 'reload_self'})
      return
    end
    local s = F.find_loaded(path)
    if s then
      s:reload()
      F.notify('Перезагружен ' .. cfg.last)
    else
      if script.load(path) then
        F.notify('Запущен ' .. cfg.last)
      else
        F.notify('Не удалось запустить ' .. cfg.last)
      end
    end
    need_scan = true
  elseif j.op == 'dir' then
    F.shell_open('explore', F.wd())
  elseif j.op == 'log' then
    F.shell_open('open', F.log_path())
  elseif j.op == 'copy' then
    if not j.text or j.text == '' then
      F.notify('Нечего копировать')
    else
      setClipboardText(j.text)
      F.notify('Скопировано')
    end
  elseif j.op == 'clear_log' then
    logs = {}
    F.mkdir(F.cfg_dir())
    local f = io.open(F.log_path(), 'w')
    if f then f:close() end
    F.notify('Журнал очищен')
  elseif j.op == 'fn' then
    if j.fn then j.fn() end
  end
end

function F.queue(op, extra)
  job = extra or {}
  job.op = op
end

function F.ask(text, ok_label, op, extra)
  local item = extra or {}
  item.op = op
  modal = {kind = 'ask', text = text, ok = ok_label, job = item}
end

function F.sync_anim()
  local goal = show and 1 or 0
  if goal ~= anim_goal then
    anim_from = anim
    anim_goal = goal
    anim_t0 = os.clock()
  end
  local t = (os.clock() - anim_t0) / 0.32
  if t < 0 then t = 0 elseif t > 1 then t = 1 end
  local e = 1 - (1 - t) * (1 - t) * (1 - t)
  anim = anim_from + (anim_goal - anim_from) * e
  if anim < 0 then anim = 0 elseif anim > 1 then anim = 1 end
end

function F.anim_slide()
  return (1 - anim) * 36
end

function F.menu_drawn()
  return show or anim > 0.02
end

function F.server_day()
  local stamp = os.time() + 3 * 3600
  local t = os.date('!*t', stamp)
  if t and t.hour < 5 then stamp = stamp - 86400 end
  return os.date('!%Y-%m-%d', stamp)
end

function F.fmt_bytes(n)
  n = tonumber(n) or 0
  if n < 0 then n = 0 end
  local text
  if n < 1024 then
    text = string.format('%d Б', math.floor(n))
  elseif n < 1048576 then
    text = string.format('%.1f КБ', n / 1024)
  elseif n < 1073741824 then
    text = string.format('%.1f МБ', n / 1048576)
  else
    text = string.format('%.2f ГБ', n / 1073741824)
  end
  return (text:gsub('%.', ','))
end

function F.used_bytes(session)
  if session then
    return (net.sin or 0) + (net.sout or 0)
  end
  return (net.inn or 0) + (net.outn or 0)
end

function F.note_bytes(n, incoming)
  n = tonumber(n) or 0
  if n <= 0 or n > 2000000 then return end
  if incoming then
    net.inn = net.inn + n
    net.sin = net.sin + n
  else
    net.outn = net.outn + n
    net.sout = net.sout + n
  end
  local now = os.clock()
  if not net.touch or now - net.touch >= 1 then
    net.touch = now
    stat_dirty = true
  end
end

function F.hud_on()
  if hidden then return false end
  if cfg.hud_fps ~= 1 and cfg.hud_net ~= 1 and cfg.hud_ping ~= 1 then return false end
  local ok, pause = pcall(isPauseMenuActive)
  if ok and pause then return false end
  return true
end

function F.hud_anchor(sw, sh, bw, bh)
  local margin = 18
  local place = cfg.hud_place or 1
  if place == 0 then return margin, margin end
  if place == 2 then return margin, sh - bh - margin end
  if place == 3 then return sw - bw - margin, sh - bh - margin end
  if place == 4 then
    local x = (cfg.hud_x or 0) / 100 * math.max(1, sw - bw)
    local y = (cfg.hud_y or 0) / 100 * math.max(1, sh - bh)
    return x, y
  end
  return sw - bw - margin, margin
end

function F.fmt_span(sec)
  sec = math.floor(sec or 0)
  if sec < 0 then sec = 0 end
  local days = math.floor(sec / 86400)
  sec = sec % 86400
  local h = math.floor(sec / 3600)
  local m = math.floor((sec % 3600) / 60)
  local s = sec % 60
  if days > 0 then
    return string.format('%dд %02d:%02d:%02d', days, h, m, s)
  end
  return string.format('%02d:%02d:%02d', h, m, s)
end

function F.in_game()
  if not isSampAvailable() then return false, '' end
  local connected = true
  local ok, gs = pcall(sampGetGamestate)
  if ok and gs ~= nil and GAMESTATE_CONNECTED ~= nil then
    connected = gs == GAMESTATE_CONNECTED
  end
  if not connected then return false, '' end
  local addr, port = '', 0
  local got = pcall(function()
    addr, port = sampGetCurrentServerAddress()
  end)
  if not got then return false, '' end
  addr = F.plain_samp(addr)
  port = tonumber(port) or 0
  if addr == '' then return false, '' end
  if port > 0 then return true, addr .. ':' .. tostring(port) end
  return true, addr
end

function F.play_restore()
  local now = os.time()
  local today = F.server_day()
  if play.day_id ~= today then
    play.day = 0
    play.day_id = today
    dirty = true
  end
  if play.beat == 0 or now - play.beat > 20 then
    play.session = 0
    play.server = ''
  end
  play.online = false
  play.slice = 0
end

function F.play_commit(now, count)
  if not count then
    play.slice = now
    play.beat = now
    return
  end
  if play.slice == 0 then
    play.slice = now
    play.beat = now
    return
  end
  local dt = now - play.slice
  if dt <= 0 then return end
  if dt > 5 then dt = 5 end
  play.session = play.session + dt
  play.day = play.day + dt
  play.total = play.total + dt
  play.slice = now
  play.beat = now
  stat_dirty = true
end

function F.play_tick()
  local today = F.server_day()
  if play.day_id ~= today then
    play.day = 0
    play.day_id = today
    dirty = true
  end
  local online, server = F.in_game()
  local paused = false
  if online then
    local ok, flag = pcall(isPauseMenuActive)
    paused = ok and flag and true or false
  end
  local now = os.time()
  if online then
    if play.server ~= server then
      if play.server ~= '' then F.play_commit(now, true) end
      play.session = 0
      play.server = server
      play.slice = now
      dirty = true
    end
    play.online = true
    if paused then
      play.slice = now
      if play.beat ~= now then
        play.beat = now
        stat_dirty = true
      end
    else
      F.play_commit(now, true)
    end
  elseif play.online then
    F.play_commit(now, true)
    play.session = 0
    play.online = false
    play.server = ''
    play.slice = 0
    dirty = true
  end
end

function F.play_seconds(kind)
  local extra = 0
  if play.online and play.slice > 0 then
    extra = os.time() - play.slice
    if extra < 0 or extra > 5 then extra = 0 end
  end
  if kind == 'session' then
    if not play.online then return 0 end
    return play.session + extra
  elseif kind == 'day' then
    return play.day + extra
  end
  return play.total + extra
end

function F.chat_brand(text)
  if not isSampAvailable() then return end
  sampAddChatMessage(F.to_cp('{E08A55}[fHelper] {FFFFFF}' .. text), -1)
end

function F.blank_live()
  live.nick, live.nick_raw, live.id, live.ping = '—', '', '—', '—'
  live.server, live.ip, live.players = '—', '—', '—'
  live.money, live.health, live.armour, live.score, live.wanted = '—', '—', '—', '—', '—'
  live.zone, live.pos, live.weapon, live.veh, live.clock, live.interior = '—', '—', '—', '—', '—', '—'
end

-- SAMPFUNCS has no sampGetLocalPlayerId, the id comes from our own ped.
function F.local_id()
  if type(sampGetPlayerIdByCharHandle) == 'function' then
    local ok, res, id = pcall(sampGetPlayerIdByCharHandle, PLAYER_PED)
    id = tonumber(id)
    if ok and res and id then return id end
  end
  if type(sampGetLocalPlayerId) == 'function' then
    local ok, id = pcall(sampGetLocalPlayerId)
    id = ok and tonumber(id) or nil
    if id then return id end
  end
  return nil
end

function F.player_total()
  if type(sampGetPlayerCount) ~= 'function' then return nil end
  local ok, n = pcall(sampGetPlayerCount, false)
  n = ok and tonumber(n) or nil
  if not n then return nil end
  if n < 0 then n = 0 end
  return n
end

function F.refresh_live()
  live.session = F.fmt_span(F.play_seconds('session'))
  live.fps = tostring(math.floor((fps or 0) + 0.5))
  if not isSampAvailable() or not F.in_game() then
    live.miss = (live.miss or 0) + 1
    if live.miss < 4 then return end
    live.online = false
    F.blank_live()
    return
  end
  live.miss = 0
  live.online = true
  pcall(function()
    local id = F.local_id()
    if id and id >= 0 and id < 1000 then
      live.id = tostring(id)
      local nick = F.game_text(sampGetPlayerNickname(id))
      if nick ~= '' then
        live.nick_raw = nick
        live.nick = nick
      end
      local ping = tonumber(sampGetPlayerPing(id))
      if ping then live.ping = tostring(math.floor(ping + 0.5)) end
      local score = tonumber(sampGetPlayerScore(id))
      if score then live.score = tostring(math.floor(score + 0.5)) end
    end
  end)
  pcall(function()
    local name = F.game_text(sampGetCurrentServerName())
    if name ~= '' then live.server = name end
  end)
  pcall(function()
    local addr, port = sampGetCurrentServerAddress()
    addr = F.plain_samp(addr)
    port = tonumber(port) or 0
    if addr ~= '' and port > 0 then
      live.ip = addr .. ':' .. tostring(port)
    elseif addr ~= '' then
      live.ip = addr
    end
  end)
  pcall(function()
    local n = F.player_total()
    if n then live.players = tostring(n) end
  end)
  pcall(function()
    -- GTA keeps money in a capped 32-bit value, the server's CEF event has the real sum.
    local money = tonumber(cfg.money_real) or -1
    if money < 0 then money = tonumber(getPlayerMoney(PLAYER_HANDLE)) end
    if money then live.money = F.fmt_money(money) or live.money end
  end)
  -- For our own player SA-MP pools return 0 health, the ped has the real value.
  pcall(function()
    local hp = tonumber(getCharHealth(PLAYER_PED))
    if hp then live.health = tostring(math.floor(hp + 0.5)) end
    local arm = tonumber(getCharArmour(PLAYER_PED))
    if arm then live.armour = tostring(math.floor(arm + 0.5)) end
  end)
  pcall(function()
    local fn = storeWantedLevel or getPlayerWantedLevel
    if type(fn) ~= 'function' then return end
    -- storeWantedLevel returns (true, level), the old name returns the level.
    local a, b = fn(PLAYER_HANDLE)
    local w = type(a) == 'number' and a or tonumber(b)
    if w then live.wanted = tostring(math.floor(w + 0.5)) end
  end)
  F.live_place()
end

function F.gun_name(id)
  local names = {
    [0] = 'кулаки', [1] = 'кастет', [2] = 'клюшка', [3] = 'дубинка', [4] = 'нож',
    [5] = 'бита', [6] = 'лопата', [7] = 'кий', [8] = 'катана', [9] = 'пила',
    [14] = 'цветы', [15] = 'трость',
    [16] = 'граната', [17] = 'газ', [18] = 'молотов',
    [22] = 'пистолет', [23] = 'пистолет', [24] = 'дигл', [25] = 'дробовик',
    [26] = 'обрез', [27] = 'спаз', [28] = 'узи', [29] = 'мп5', [30] = 'ак',
    [31] = 'м4', [32] = 'тек', [33] = 'винтовка', [34] = 'снайперка', [35] = 'ргп',
    [36] = 'хс', [37] = 'огнемёт', [38] = 'миниган', [39] = 'заряд', [40] = 'детонатор',
    [41] = 'баллон', [42] = 'огнетушитель', [43] = 'камера', [44] = 'пнв',
    [45] = 'тепловизор', [46] = 'парашют',
  }
  id = tonumber(id) or 0
  return names[id] or ('оружие ' .. tostring(id))
end

function F.gxt_name(key)
  if type(getGxtText) ~= 'function' or not key or key == '' then return '' end
  local ok, gxt = pcall(getGxtText, key)
  if not ok or type(gxt) ~= 'string' then return '' end
  local name = F.game_text(gxt)
  if name == '' or name == key then return '' end
  return name
end

function F.zone_map()
  if F._zones then return F._zones end
  F._zones = {
    LA = 'Лос-Сантос', RIH = 'Ричман', MUL = 'Малхолланд', MULINT = 'Перекрёсток Малхолланд',
    SUN = 'Темпл', CHC = 'Лас-Колинас', VIN = 'Вайнвуд', LDT = 'Центр Лос-Сантоса',
    GLN = 'Глен-Парк', LFL = 'Лос-Флорес', MKT = 'Маркет', MARKST = 'Станция Маркет',
    JEF = 'Джефферсон', ROD = 'Родео', MAR = 'Марина', COM = 'Коммерция',
    ELS = 'Восточный Лос-Сантос', EBE = 'Ист-Бич', PER1 = 'Площадь Першинга',
    IWD = 'Айдлвуд', GAN = 'Гэнтон', CONF = 'Конференц-центр', CITYS = 'Мэрия',
    LMEX = 'Маленькая Мексика', UNITY = 'Станция Юнити', SMB = 'Пляж Санта-Мария',
    VERO = 'Пляж Верона', LIND = 'Уиллоуфилд', ELCO = 'Эль-Корона', PLS = 'Плайя-дель-Севиль',
    BLUF = 'Вердант-Блаффс', LAIR = 'Аэропорт Лос-Сантоса', LDOC = 'Оушен-Докс',
    RED = 'Ред-Каунти', MONT = 'Монтгомери', MONINT = 'Перекрёсток Монтгомери',
    HBARNS = 'Амбары Хэмптон', HANKY = 'Хэнкипанки-Пойнт', BLUAC = 'Фермы Блуберри',
    FERN = 'Ферн-Ридж', PANOP = 'Паноптикум', PALO = 'Паломино-Крик', BLUEB = 'Блуберри',
    TOPFA = 'Ферма на холме', NROCK = 'Норт-Рок', DILLI = 'Диллимор',
    SF = 'Сан-Фиерро', BATTP = 'Бэттери-Пойнт', ESPN = 'Эспланада Норт', ESPE = 'Эспланада Ист',
    JUNIHO = 'Джунипер-Холлоу', SFDWT = 'Центр Сан-Фиерро', PARA = 'Парадизо',
    CALT = 'Калтон-Хайтс', FINA = 'Финансовый район', BAYV = 'Палисады',
    JUNIHI = 'Джунипер-Хилл', CHINA = 'Чайнатаун', CIVI = 'Санта-Флора', WESTP = 'Куинс',
    THEA = 'Кингс', EASB = 'Истер-Бейсин', GARC = 'Гарсия', CRANB = 'Станция Крэнберри',
    OCEAF = 'Оушен-Флэтс', HASH = 'Хэшбери', DOH = 'Доэрти', SFAIR = 'Аэропорт Истер-Бэй',
    FLINTC = 'Флинт-Каунти', CUNTC = 'Загородный клуб Ависпа', HAUL = 'Упавшее дерево',
    HILLP = 'Миссионерский холм', EBAY = 'Химзавод Истер-Бэй', ETUNN = 'Тоннель Истер',
    SILLY = 'Фостер-Вэлли', FARM = 'Ферма', BEACO = 'Бикон-Хилл', FLINTI = 'Перекрёсток Флинт',
    FLINTR = 'Полигон Флинт', LEAFY = 'Лифи-Холлоу', BACKO = 'Бэк-о-Бейонд',
    WHET = 'Уэтстоун', MTCHI = 'Гора Чилиад', CREEK = 'Шейди-Крикс', SHACA = 'Шейди-Кэбин',
    ANGPI = 'Энджел-Пайн',
    VE = 'Лас-Вентурас', YBELL = 'Гольф-клуб Йеллоу-Белл', SPIN = 'Спайнибед',
    KACC = 'Военная база КАСС', PRP = 'Прикл-Пайн', YELLOW = 'Станция Йеллоу-Белл',
    JTN = 'Джулиус-Норт', PINT = 'Перекрёсток Пилсон', ISLE = 'Эмералд-Айл',
    ROCE = 'Рока-Эскаланте', WWE = 'Уайтвуд-Эстейтс', OVS = 'Старый Стрип', CREE = 'Крик',
    REDE = 'Редсэндс-Ист', REDW = 'Редсэндс-Уэст', HGP = 'Харри-Голд-Паркуэй', STRIP = 'Стрип',
    JTW = 'Джулиус-Вест', VISA = 'Визаж', STAR = 'Казино Старфиш', RING = 'Карман клоуна',
    SRY = 'Сортировочная Собелл', JTE = 'Джулиус-Ист', BFLD = 'Блэкфилд', CALI = 'Казино Калигула',
    VAIR = 'Аэропорт Лас-Вентураса', PIRA = 'Пираты в мужских штанах', ROY = 'Королевское казино',
    PILL = 'Пилигрим', LST = 'Станция Линден', LINDEN = 'Станция Линден', HIGH = 'Хай-Роллер',
    PINK = 'Пинк-Свон', CAM = 'Кэмелс-Тоу', GGC = 'Колледж Грингласс', LDS = 'Линден-Сайд',
    LVA = 'Грузовое депо', DRAG = 'Казино Четыре дракона', LOT = 'Кам-э-Лот',
    BINT = 'Перекрёсток Блэкфилд', JTS = 'Джулиус-Саут', BFC = 'Часовня Блэкфилд',
    RIE = 'Промзона Рэндольф', LDM = 'Мотель Ласт-Дайм', RSE = 'Рокшор-Ист', RSW = 'Рокшор-Уэст',
    ROBAD = 'Тьерра-Робада', ELQUE = 'Эль-Кебрадос', SUNNN = 'Бэйсайд', BYTUN = 'Тоннель Бэйсайд',
    ALDEA = 'Альдеа-Мальвада', SUNMA = 'Марина Бэйсайд', BARRA = 'Лас-Барранкас',
    ROBINT = 'Перекрёсток Робада',
    BONE = 'Боун-Каунти', PAYAS = 'Лас-Паясадас', VALLE = 'Валье-Окультадо',
    ELCA = 'Эль-Кастильо-дель-Диабло', ARCO = 'Арко-дель-Оэсте', MEAD = 'Вердант-Медоус',
    BRUJA = 'Лас-Брухас', TOM = 'Регуляр Том', REST = 'Закрытая зона', BIGE = 'Большое ухо',
    PALMS = 'Грин-Палмс', OCTAN = 'Октан-Спрингс', PROBE = 'Литл Проуб Инн',
    CARSO = 'Форт-Карсон', QUARY = 'Карьер Хантера',
    LSINL = 'Бухта Лос-Сантоса', FLINW = 'Воды Флинта', FISH = 'Лагуна Фишера',
    SANB = 'Бухта Сан-Фиерро', SHERR = 'Водохранилище Шермана', SASO = 'Пролив Сан-Андреас',
    GANTB = 'Мост Гант', DAM = 'Дамба Шермана', GARV = 'Мост Гарвер', KINC = 'Мост Кинкейд',
    FALLO = 'Мост Фэллоу', MART = 'Мост Мартин', MAKO = 'Мост Мако', FRED = 'Мост Фредерик',
  }
  return F._zones
end

function F.zone_title(code)
  -- The zone id (GAN1) is not the GXT key (GAN). A missing key comes back as ???.
  -- Arizona GXT uses its own font encoding, so the Russian table goes first
  -- and GXT text is trusted only when it is plain ASCII.
  code = F.plain_samp(code)
  if code == '' or F.qmark(code) then return '' end
  local map = F.zone_map()
  local base = code:match('^%A*(%a+)')
  if map[code] then return map[code] end
  if base and map[base] then return map[base] end
  local name = F.gxt_name(code)
  if name ~= '' and not name:find('[\128-\255]') then return name end
  return code
end

function F.read_clock()
  if type(getTimeOfDay) == 'function' then
    local ok, h, m = pcall(getTimeOfDay)
    h = ok and tonumber(h) or nil
    if h and h >= 0 and h < 24 then return h, tonumber(m) or 0 end
  end
  local mem = F.mem()
  if mem and mem.getuint8 then
    local okh, h = pcall(mem.getuint8, 0xB70153)
    local okm, m = pcall(mem.getuint8, 0xB70152)
    h = okh and tonumber(h) or nil
    m = okm and tonumber(m) or nil
    if h and m and h < 24 and m < 60 then return h, m end
  end
end

function F.live_place()
  pcall(function()
    local h, m = F.read_clock()
    if h then live.clock = string.format('%02d:%02d', h, m or 0) end
  end)
  pcall(function()
    if type(getCharCoordinates) ~= 'function' then return end
    local x, y, z = getCharCoordinates(PLAYER_PED)
    if not x then return end
    live.pos = string.format('%.0f, %.0f, %.0f', x, y, z or 0)
    if type(getNameOfZone) ~= 'function' then return end
    local zone = getNameOfZone(x, y, z or 0)
    local title = F.zone_title(zone)
    if title ~= '' then live.zone = title end
  end)
  pcall(function()
    if type(getCurrentCharWeapon) ~= 'function' then return end
    local id = getCurrentCharWeapon(PLAYER_PED)
    if id ~= nil then live.weapon = F.gun_name(id) end
  end)
  pcall(function()
    if type(getActiveInterior) ~= 'function' then return end
    local n = tonumber(getActiveInterior())
    if n == nil then return end
    if n == 0 then live.interior = 'улица'
    else live.interior = tostring(n) end
  end)
  pcall(function()
    if type(isCharInAnyCar) ~= 'function' or not isCharInAnyCar(PLAYER_PED) then
      live.veh = 'пешком'
      return
    end
    local model
    if type(storeCarCharIsInNoSave) == 'function' and type(getCarModel) == 'function' then
      model = getCarModel(storeCarCharIsInNoSave(PLAYER_PED))
    end
    local name = ''
    if model and type(getNameOfVehicleModel) == 'function' then
      local ok, key = pcall(getNameOfVehicleModel, model)
      if ok and type(key) == 'string' then
        name = F.gxt_name(key)
        if name == '' then name = F.game_text(key) end
      end
    end
    -- Arizona's own cars (id above 611) have no GTA name.
    if name ~= '' and not name:find('[\128-\255]') then live.veh = name
    else live.veh = model and ('модель ' .. tostring(model)) or 'в транспорте' end
  end)
end

function F.pay_state()
  if F.pay then return F.pay end
  F.pay = {open = false, buf = {}, at = 0, list = {}, pick = 0}
  return F.pay
end

function F.pay_cash(s)
  local deltas, all = {}, {}
  local function push(list, sign, num)
    local n = tostring(num or ''):gsub('[ %.,]', '')
    n = tonumber(n)
    if not n then return end
    if sign == '-' then n = -n end
    list[#list + 1] = n
  end
  for sign, num in s:gmatch('%(([%+%-]?)%$([%d][%d%., ]*)%)') do
    push(deltas, sign, num)
  end
  for sign, num in s:gmatch('([%+%-]?)%$([%d][%d%., ]*)') do
    push(all, sign, num)
  end
  return deltas, all
end

function F.pay_az(s)
  local out = {}
  for sign, num in s:gmatch('%(([%+%-]?)(%d+)%s*[Aa][Zz]%)') do
    local n = tonumber(num) or 0
    if sign == '-' then n = -n end
    out[#out + 1] = n
  end
  return out
end

function F.pay_reason(s)
  local r = tostring(s or '')
  r = r:gsub('%b()', '')
  r = r:gsub('[%+%-]?%$[%d%., ]*', '')
  r = r:gsub('[%+%-]?[%d%., ]*%s*[Aa][Zz]', '')
  r = r:gsub('_', '')
  r = r:gsub('^[#|%s]+', '')
  r = F.trim(r):gsub('[:%s]+$', ''):gsub('^[:%s]+', '')
  r = r:gsub('|', '/')
  r = r:gsub(',?%s*вы получили%s*дополнительно', ''):gsub(',?%s*на сумму%s*$', '')
  if r == '' or F.qmark(r) then return '' end
  return F.utf_cut(F.trim(r), 150)
end

function F.pay_is_total(reason)
  local s = F.lower_text(reason)
  if s:find('общая заработ', 1, true) then return true end
  if s:find('итого', 1, true) then return true end
  if s:find('к получению', 1, true) then return true end
  if s:find('к выдаче', 1, true) then return true end
  if s == 'зарплата' or s == 'заработная плата' then return true end
  return false
end

function F.pay_is_balance(reason)
  local s = F.lower_text(reason)
  if s:find('текущая сумма', 1, true) then return true end
  if s:find('баланс', 1, true) then return true end
  return false
end

function F.pay_save()
  local st = F.pay_state()
  local lines = {}
  for i = 1, #st.list do
    local rec = st.list[i]
    lines[#lines + 1] = '#' .. (rec.t or '') .. '|' .. tostring(rec.total or 0) .. '|' .. tostring(rec.az or 0)
    local items = rec.items or {}
    for j = 1, #items do
      local it = items[j]
      lines[#lines + 1] = (it.reason or ''):gsub('|', '/') .. '|' .. tostring(it.amount or 0) .. '|' .. (it.kind or '')
    end
  end
  F.write_lines('fhelp_income.txt', lines)
end

function F.pay_load()
  local st = F.pay_state()
  st.list = {}
  local rec
  for _, line in ipairs(F.read_lines('fhelp_income.txt')) do
    if line:sub(1, 1) == '#' then
      local t, total, az = line:match('^#(.-)|([%+%-]?%d+)|([%+%-]?%d+)$')
      if t then
        rec = {t = t, total = tonumber(total) or 0, az = tonumber(az) or 0, items = {}}
        st.list[#st.list + 1] = rec
      else
        rec = nil
      end
    elseif rec then
      local reason, amount, kind = line:match('^(.-)|([%+%-]?%d+)|(.*)$')
      if reason and reason ~= '' then
        rec.items[#rec.items + 1] = {reason = reason, amount = tonumber(amount) or 0, kind = kind or ''}
      end
    end
  end
  while #st.list > F.PAY_MAX do table.remove(st.list, 1) end
  st.pick = #st.list
end

function F.pay_close()
  local st = F.pay_state()
  st.open = false
  if #st.buf == 0 then return end
  local items = {}
  local total, az, az_set = nil, 0, false
  local delta_sum, delta_n = 0, 0
  for i = 1, #st.buf do
    local line = st.buf[i]
    local reason = F.pay_reason(line)
    if reason ~= '' then
      local deltas, all = F.pay_cash(line)
      local azs = F.pay_az(line)
      local amount, kind
      if #deltas > 0 then
        amount = deltas[1]
        kind = 'delta'
        delta_sum = delta_sum + amount
        delta_n = delta_n + 1
      elseif #all > 0 then
        amount = all[1]
        kind = 'line'
      end
      if #azs > 0 then
        az = az + azs[1]
        az_set = true
        if not amount then
          amount = azs[1]
          kind = 'az'
        end
      end
      if amount and kind ~= 'az' and F.pay_is_total(reason) then total = amount end
      if amount then
        items[#items + 1] = {reason = reason, amount = amount, kind = kind or 'line'}
      end
    end
  end
  st.buf = {}
  if #items == 0 then return end
  -- Arizona marks what came in with (+$N) next to the bank and the deposit,
  -- so their sum is the payday. The salary line repeats the bank part.
  if delta_n > 0 then
    total = delta_sum
  elseif total == nil then
    do
      local sum, any = 0, false
      for i = 1, #items do
        if items[i].kind ~= 'az' and not F.pay_is_balance(items[i].reason) then
          sum = sum + items[i].amount
          any = true
        end
      end
      if any then total = sum end
    end
  end
  if total == nil and not az_set then return end
  if total == nil then total = 0 end
  local rec = {t = os.date('%Y-%m-%d %H:%M:%S'), total = total, az = az_set and az or 0, items = items}
  st.list[#st.list + 1] = rec
  while #st.list > F.PAY_MAX do table.remove(st.list, 1) end
  st.pick = #st.list
  st.rev = (st.rev or 0) + 1
  st.last = rec
  st.closed_at = os.clock()
  F.pay_save()
  local shown = F.fmt_money(total) or tostring(total)
  F.log_line('Пейдей: ' .. shown)
  pcall(F.toast_pay, rec)
end

-- Right after the check Arizona sends lines like
-- "Вы получили +$30.000 за Дивидентный договор (...)". They belong to the payday.
function F.pay_extra(raw)
  local st = F.pay_state()
  if not st.last or not st.closed_at or os.clock() - st.closed_at > 3 then return false end
  local sign, num, why = raw:match('[Пп]олучили%s*([%+%-]?)%$([%d][%d%.,]*)%s+за%s+(.+)$')
  if not num then return false end
  local n = tonumber((num:gsub('[%.,]', '')))
  if not n then return false end
  if sign == '-' then n = -n end
  why = F.trim((why:gsub('%b()', ''))):gsub('[%.%s]+$', '')
  if why == '' then why = 'Доход' end
  local rec = st.last
  rec.items[#rec.items + 1] = {reason = F.utf_cut(why, 80), amount = n, kind = 'extra'}
  rec.total = (rec.total or 0) + n
  st.rev = (st.rev or 0) + 1
  F.pay_save()
  F.log_line('Пейдей, доплата: ' .. (F.fmt_money(n) or tostring(n)))
  pcall(F.toast_pay, rec, n, why)
  return true
end

-- Bank and deposit balances come from the check and from "Состояние счета".
function F.track_balance(raw)
  local changed = false
  local function take(key, num)
    local n = tonumber((tostring(num or ''):gsub('[%.,%s]', '')))
    if n and cfg[key] ~= n then
      cfg[key] = n
      changed = true
    end
  end
  take('bank', raw:match('умма в банке:%s*%$([%d%.,]+)'))
  take('depo', raw:match('умма на депозите:%s*%$([%d%.,]+)'))
  take('bank', raw:match('остояние счета:%s*%$([%d%.,]+)'))
  take('depo', raw:match('остояние депозита:%s*%$([%d%.,]+)'))
  if changed then stat_dirty = true end
end

-- Rodina counts in roubles and words the check differently, the parsers know Arizona's form.
function F.proj_text(raw)
  if not F.is_rod() then return raw end
  raw = raw:gsub('(%d[%d%.,]*)%s*рубл[^%s%.,%)]*', '$%1'):gsub('(%d[%d%.,]*)%s*руб%.?', '$%1')
  return (raw:gsub('Депозит в банке:', 'Сумма на депозите:'):gsub('На банковском счету:', 'Сумма в банке:'))
end

function F.pay_feed(text)
  local raw = F.game_text(text)
  if raw == '' then return end
  -- Arizona writes money as :CASH:1.234.567 and adds emoji codes like :u1F4B0:.
  raw = raw:gsub(':CASH:', '$'):gsub(':u%x+:', '')
  raw = F.trim(F.proj_text(raw))
  if raw == '' then return end
  local low = F.lower_text(raw)
  local bare = raw:gsub('%s', '')
  local rule = #bare >= 8 and (bare:match('^_+$') or bare:match('^=+$'))
  local header = low:find('банковский чек', 1, true) ~= nil
  local st = F.pay_state()
  F.pay_took = false
  F.track_balance(raw)
  if header then
    if st.open then F.pay_close() end
    st.open = true
    st.at = os.clock()
    st.buf = {}
    st.rules = 0
    return
  end
  if st.open and rule then
    -- The first line of ===== sits right under the header, the second one ends the check.
    st.rules = (st.rules or 0) + 1
    if #st.buf > 0 or st.rules >= 2 then F.pay_close() end
    return
  end
  if not st.open and F.pay_extra(raw) then F.pay_took = true end
  if st.open then
    st.at = os.clock()
    if #st.buf < 40 then st.buf[#st.buf + 1] = raw end
    F.pay_took = true
    return
  end
  if (low:find('заработн', 1, true) or low:find('зарплат', 1, true)) and raw:find('%$', 1, true) then
    st.open = true
    st.buf = {raw}
    st.at = os.clock()
    F.pay_close()
  end
end

function F.pay_tick()
  local st = F.pay
  if not st or not st.open then return end
  if os.clock() - (st.at or 0) > 4 then F.pay_close() end
end

function F.hook_chat()
  if F.pay_hook then return end
  local ok, ev = pcall(require, 'samp.events')
  if not ok or type(ev) ~= 'table' then
    F.log_line('Чат пейдея недоступен')
    return
  end
  F.pay_hook = true
  ev.onServerMessage = function(color, text)
    if not text then return end
    -- One bad line must not stop the others or the chat itself.
    local ok, err = pcall(F.pay_feed, text)
    if not ok then F.feed_err('пейдей', err) end
    ok, err = pcall(F.led_feed, text)
    if not ok then F.feed_err('доходы', err) end
    ok, err = pcall(F.int_feed, text)
    if not ok then F.feed_err('интеграции', err) end
    ok, err = pcall(F.item_feed, text)
    if not ok then F.feed_err('предметы', err) end
  end
  ev.onSetVehicleNumberPlate = function(id, text)
    F.car_plates[id] = F.game_text(text or '')
  end
  ev.onShowDialog = function(_, _, _, _, _, text)
    local ok, err = pcall(F.time_sync, text)
    if not ok then F.feed_err('время', err) end
  end
end

function F.feed_err(what, err)
  F._feed_err = F._feed_err or {}
  if F._feed_err[what] then return end
  F._feed_err[what] = true
  F.log_line('Ошибка разбора чата (' .. what .. '): ' .. tostring(err))
end

function F.lines_path(name)
  if F.is_rod() and F.PROJ_FILES[name] then name = name:gsub('^fhelp_', 'fhelp_rodina_') end
  return F.cfg_dir() .. '\\' .. name
end

function F.read_lines(name)
  local out = {}
  local f = io.open(F.lines_path(name), 'r')
  if not f then return out end
  for line in f:lines() do
    if line ~= '' then out[#out + 1] = line end
  end
  f:close()
  return out
end

function F.write_lines(name, list)
  F.mkdir(F.cfg_dir())
  local f = io.open(F.lines_path(name), 'w')
  if not f then return end
  for i = 1, #list do
    f:write(tostring(list[i]):gsub('[\r\n]', ' ') .. '\n')
  end
  f:close()
end

function F.load_binds()
  binds = {}
  for _, line in ipairs(F.read_lines('fhelp_binds.txt')) do
    local vk, kind, rest = line:match('^(%d+)|([^|]*)|(.*)$')
    vk = tonumber(vk)
    local arg, mods = rest or '', 0
    local body, m = (rest or ''):match('^(.*)|(%d+)$')
    if body then
      arg = body
      mods = tonumber(m) or 0
    end
    if vk and vk > 0 and (kind == 'page' or kind == 'chat' or kind == 'say' or kind == 'script') then
      if mods < 0 or mods > 31 then mods = 0 end
      binds[#binds + 1] = {vk = vk, kind = kind, arg = arg or '', mods = mods}
    end
  end
end

function F.save_binds()
  local list = {}
  for i = 1, #binds do
    local b = binds[i]
    local mods = tonumber(b.mods) or 0
    list[#list + 1] = tostring(b.vk) .. '|' .. b.kind .. '|' .. (b.arg or ''):gsub('|', '/') .. '|' .. tostring(mods)
  end
  F.write_lines('fhelp_binds.txt', list)
end

-- A favourite is a table now. Old files hold bare commands, one per line.
function F.load_favs()
  favs = {}
  local rows = F.read_lines('fhelp_favs.txt')
  for i = 1, #rows do
    local group, label, text = rows[i]:match('^F|([^|]*)|([^|]*)|(.*)$')
    if text then
      favs[#favs + 1] = {group = F.note_unesc(group), label = F.note_unesc(label), text = F.note_unesc(text)}
    else
      favs[#favs + 1] = {group = '', label = '', text = rows[i]}
    end
  end
  if #favs == 0 and not doesFileExist(F.lines_path('fhelp_favs.txt')) then
    local base = {'/time', '/stats', '/family', '/gps', '/showlic', '/showpass'}
    for i = 1, #base do favs[#favs + 1] = {group = '', label = '', text = base[i]} end
    F.save_favs()
  end
end

function F.note_esc(s)
  s = tostring(s or ''):gsub('\r\n', '\n'):gsub('\r', '\n'):gsub('%z', '')
  local out = {}
  for i = 1, #s do
    local c = s:sub(i, i)
    if c == '\\' then out[#out + 1] = '\\\\'
    elseif c == '\n' then out[#out + 1] = '\\n'
    elseif c == '|' then out[#out + 1] = '\\|'
    else out[#out + 1] = c end
  end
  return table.concat(out)
end

function F.note_unesc(s)
  s = tostring(s or '')
  local out, i = {}, 1
  while i <= #s do
    local c = s:sub(i, i)
    if c == '\\' and i < #s then
      local n = s:sub(i + 1, i + 1)
      if n == 'n' then out[#out + 1] = '\n'
      elseif n == '\\' or n == '|' then out[#out + 1] = n
      else out[#out + 1] = n end
      i = i + 2
    else
      out[#out + 1] = c
      i = i + 1
    end
  end
  return table.concat(out)
end

function F.note_bump(id)
  local n = tonumber(id)
  if n and n > (F.note_seq or 0) then F.note_seq = math.floor(n) end
end

function F.note_id()
  F.note_seq = (tonumber(F.note_seq) or 0) + 1
  return tostring(F.note_seq)
end

function F.note_type(id)
  local list = F.note_types or {}
  for i = 1, #list do
    if list[i].id == id then return list[i] end
  end
  return nil
end

function F.note_body(s)
  s = tostring(s or ''):gsub('\r\n', '\n'):gsub('\r', '\n'):gsub('%z', '')
  s = s:gsub('^%s+', ''):gsub('%s+$', '')
  return F.utf_cut(s, 2000)
end

function F.note_plain(s)
  s = tostring(s or ''):gsub('\r\n', '\n'):gsub('\r', '\n'):gsub('%z', '')
  return F.utf_cut(s, 2000)
end

function F.load_notes()
  F.note_types = {}
  F.note_items = {}
  F.note_seq = 0
  local rows = F.read_lines('fhelp_notes.txt')
  for i = 1, #rows do
    local kind, rest = rows[i]:match('^(.)|(.*)$')
    if kind == 'S' then
      F.note_bump(rest)
    elseif kind == 'T' then
      local id, name = (rest or ''):match('^([^|]*)|(.*)$')
      name = F.trim(F.note_unesc(name or ''))
      if id and id ~= '' and name ~= '' and #F.note_types < 40 then
        F.note_bump(id)
        F.note_types[#F.note_types + 1] = {id = id, name = name}
      end
    end
  end
  for i = 1, #rows do
    local kind, rest = rows[i]:match('^(.)|(.*)$')
    if kind == 'N' then
      local id, tid, text = (rest or ''):match('^([^|]*)|([^|]*)|(.*)$')
      text = F.note_body(F.note_unesc(text or ''))
      if id and id ~= '' and tid and tid ~= '' and text ~= '' and F.note_type(tid) and #F.note_items < 500 then
        F.note_bump(id)
        F.note_items[#F.note_items + 1] = {id = id, type = tid, text = text}
      end
    end
  end
end

function F.save_notes()
  if not F.note_types or not F.note_items then return end
  F.mkdir(F.cfg_dir())
  local f = io.open(F.lines_path('fhelp_notes.txt'), 'w')
  if not f then
    F.notify('Не удалось сохранить заметки', true)
    return
  end
  f:write('S|' .. tostring(F.note_seq or 0) .. '\n')
  for i = 1, #F.note_types do
    local t = F.note_types[i]
    f:write('T|' .. t.id .. '|' .. F.note_esc(t.name) .. '\n')
  end
  for i = 1, #F.note_items do
    local n = F.note_items[i]
    f:write('N|' .. n.id .. '|' .. n.type .. '|' .. F.note_esc(n.text) .. '\n')
  end
  f:close()
end

function F.note_add_type(name)
  if not F.note_types then F.load_notes() end
  name = F.trim(tostring(name or ''):gsub('[\r\n]', ' '))
  if name == '' then
    F.notify('Напиши название папки', true)
    return
  end
  if #name > 78 then
    F.notify('Слишком длинное название', true)
    return
  end
  if #F.note_types >= 40 then
    F.notify('Папок уже много', true)
    return
  end
  for i = 1, #F.note_types do
    if F.note_types[i].name == name then
      F.notify('Такая папка уже есть', true)
      return
    end
  end
  local id = F.note_id()
  F.note_types[#F.note_types + 1] = {id = id, name = name}
  F.note_pick = id
  F.note_edit = nil
  F.buf_set(ui_ntype, '', 80)
  F.buf_set(ui_ntext, '', 2048)
  F.save_notes()
  F.notify('Папка добавлена', true)
end

function F.note_del_type(id)
  if not id or not F.note_types then return end
  local types, items = {}, {}
  for i = 1, #F.note_types do
    if F.note_types[i].id ~= id then types[#types + 1] = F.note_types[i] end
  end
  for i = 1, #F.note_items do
    if F.note_items[i].type ~= id then items[#items + 1] = F.note_items[i] end
  end
  F.note_types = types
  F.note_items = items
  if F.note_pick == id then F.note_pick = nil end
  F.note_edit = nil
  F.buf_set(ui_ntext, '', 2048)
  F.save_notes()
  F.notify('Папка удалена', true)
end

function F.note_del(id)
  if not F.note_items then return end
  local items = {}
  for i = 1, #F.note_items do
    if F.note_items[i].id ~= id then items[#items + 1] = F.note_items[i] end
  end
  F.note_items = items
  if F.note_edit == id then
    F.note_edit = nil
    F.note_base = ''
    F.buf_set(ui_ntext, '', 2048)
  end
  F.save_notes()
  F.notify('Заметка удалена', true)
end

function F.note_find(id)
  for i = 1, #(F.note_items or {}) do
    if F.note_items[i].id == id then return F.note_items[i] end
  end
  return nil
end

-- Saves the open note. It stays open, so the editor does not jump.
function F.note_commit(quiet)
  if not F.note_types then F.load_notes() end
  local text = F.note_body(F.buf_get(ui_ntext))
  if text == '' then
    if not quiet then F.notify('Напиши текст', true) end
    return
  end
  local tid = F.note_tsel
  if not tid or not F.note_type(tid) then
    tid = F.note_pick
    if not tid or not F.note_type(tid) then
      if #F.note_types == 0 then
        local id = F.note_id()
        F.note_types[#F.note_types + 1] = {id = id, name = 'Общее'}
      end
      tid = F.note_types[1].id
    end
  end
  F.note_tsel = tid
  local n = F.note_edit and F.note_find(F.note_edit)
  if n then
    n.text = text
    n.type = tid
    F.note_base = text
    F.save_notes()
    if not quiet then F.notify('Заметка сохранена', true) end
    return
  end
  if #F.note_items >= 500 then
    F.notify('Заметок уже много', true)
    return
  end
  n = {id = F.note_id(), type = tid, text = text}
  F.note_items[#F.note_items + 1] = n
  F.note_edit = n.id
  F.note_base = text
  F.save_notes()
  if not quiet then F.notify('Заметка добавлена', true) end
end

function F.note_dirty()
  local text = F.note_body(F.buf_get(ui_ntext))
  if text ~= (F.note_base or '') then return true end
  local n = F.note_edit and F.note_find(F.note_edit)
  return n ~= nil and n.type ~= F.note_tsel
end

-- Switching notes keeps what was typed.
function F.note_flush()
  if F.note_dirty() then F.note_commit(true) end
end

function F.note_open(id)
  F.note_flush()
  local n = F.note_find(id)
  if not n then return end
  F.note_edit = id
  F.note_base = n.text
  F.note_tsel = n.type
  F.buf_set(ui_ntext, n.text, 2048)
end

function F.note_new()
  F.note_flush()
  F.note_edit = nil
  F.note_base = ''
  F.note_tsel = F.note_pick
  F.buf_set(ui_ntext, '', 2048)
end

function F.note_insert(text)
  if not F.note_types then F.load_notes() end
  local cur = F.buf_get(ui_ntext)
  if cur ~= '' and not cur:find('%s$') then cur = cur .. ' ' end
  F.buf_set(ui_ntext, cur .. text .. ' ', 2048)
end

function F.note_copy(text)
  if not text or text == '' then
    F.notify('Нечего копировать', true)
    return
  end
  if F.clip_set(text) then F.notify('Скопировано', true)
  else F.notify('Не удалось скопировать', true) end
end

function F.paste_note_buf()
  local text = F.note_plain(F.clip_text())
  if text == '' then
    F.notify('Буфер пуст', true)
    return
  end
  F.bind_clip = nil
  F.buf_set(ui_ntext, F.buf_get(ui_ntext) .. text, 2048)
end

function F.load_console()
  -- history stays on screen only, so a saved file cannot keep a password
end

function F.sensitive_cmd(text)
  local low = text:lower()
  return low:find('/login', 1, true) or low:find('password', 1, true) or low:find('парол', 1, true) or low:find('token', 1, true)
end

local console_view = {}
function F.chats_ui_push(text)
  console_view[#console_view + 1] = {t = os.date('%H:%M'), text = text}
  if #console_view > 40 then table.remove(console_view, 1) end
end

-- plain = send the text as it is, as a normal chat message.
function F.send_cmd(text, plain)
  text = F.int_pack(F.trim(text or ''))
  if text == '' then return end
  if not plain and text:sub(1, 1) ~= '/' and not F.int_has(text) then text = '/' .. text end
  local online = F.in_game()
  if not online then
    F.notify('Нет подключения к серверу')
    return
  end
  local ok, err = pcall(sampSendChat, F.to_cp(text))
  if not ok then
    F.notify('Команда не ушла в чат')
    F.log_line('Чат: ' .. tostring(err))
    return
  end
  local shown = F.sensitive_cmd(text) and '/команда скрыта' or text
  F.chats_ui_push(shown)
  F.log_line(F.sensitive_cmd(text) and 'Команда отправлена' or ('Команда отправлена: ' .. shown))
end

-- skip = the bind being edited, it may keep its own keys.
function F.bind_conflict(vk, mods, skip)
  mods = tonumber(mods) or 0
  if vk == 0 then return 'Клавиша не выбрана' end
  if mods == 0 and (vk == cfg.key or vk == cfg.hidekey) then
    return 'Эта клавиша уже открывает или скрывает меню'
  end
  for i = 1, #binds do
    if binds[i] ~= skip and binds[i].vk == vk and (binds[i].mods or 0) == mods then
      return 'Такое сочетание уже есть'
    end
  end
  return nil
end

function F.page_ok(id)
  for i = 1, #NAV do
    if NAV[i][1] == id then return true end
  end
  return false
end

function F.bind_kind_name(kind)
  if kind == 'page' then return 'раздел' end
  if kind == 'chat' then return 'команда' end
  if kind == 'say' then return 'сообщение' end
  return 'скрипт'
end

function F.fire_bind(b)
  if b.kind == 'page' then
    page = F.page_ok(b.arg) and b.arg or 'home'
    show = true
    hidden = false
    placed = false
  elseif b.kind == 'chat' then
    F.send_cmd(b.arg)
  elseif b.kind == 'say' then
    F.send_cmd(b.arg, true)
  elseif b.kind == 'script' then
    local path = F.wd() .. '\\' .. b.arg
    local loaded = F.find_loaded(path)
    if loaded then F.queue('reload', {path = path})
    else F.queue('load', {path = path}) end
  end
end

function F.fire_binds()
  if F.typing() or show or capture or modal or F.calc_focus then return end
  local seen = {}
  for i = 1, #binds do
    local vk = binds[i].vk
    if vk ~= 0 and not seen[vk] then
      seen[vk] = true
      if wasKeyPressed(vk) then
        local held = F.held_mods(vk)
        local exact, plain
        for j = 1, #binds do
          local b = binds[j]
          if b.vk == vk then
            if (b.mods or 0) == held then exact = b
            elseif (b.mods or 0) == 0 then plain = b end
          end
        end
        local pick = exact or (held == 0 and plain or nil)
        if pick then
          F.fire_bind(pick)
          return
        end
      end
    end
  end
end

function F.utf_cut(text, cap)
  text = text or ''
  if cap < 1 then return '' end
  if #text <= cap then return text end
  text = text:sub(1, cap)
  while #text > 0 do
    local b = text:byte(#text)
    if b < 128 then break end
    text = text:sub(1, #text - 1)
    if b >= 192 then break end
  end
  return text
end

function F.buf_set(buf, text, cap)
  if not ffi_ok or not buf then return end
  text = F.utf_cut(text or '', cap - 1)
  ffi.fill(buf, cap, 0)
  ffi.copy(buf, text)
end

function F.clip_text()
  local user32, kernel32 = F.user32, F.kernel32
  if not user32 or not kernel32 then return '' end
  if user32.OpenClipboard(nil) == 0 then return '' end
  local out = ''
  -- Every paste goes through here, so all fields get the same token form.
  local ok = pcall(function()
    if user32.IsClipboardFormatAvailable(13) ~= 0 then
      local h = user32.GetClipboardData(13)
      if h ~= nil then
        local p = kernel32.GlobalLock(h)
        if p ~= nil then
          local ws = ffi.cast('const unsigned short*', p)
          local n = kernel32.WideCharToMultiByte(65001, 0, ws, -1, nil, 0, nil, nil)
          if n > 1 and n < 4096 then
            local buf = ffi.new('char[?]', n)
            kernel32.WideCharToMultiByte(65001, 0, ws, -1, buf, n, nil, nil)
            out = ffi.string(buf)
          end
          kernel32.GlobalUnlock(h)
        end
      end
    elseif user32.IsClipboardFormatAvailable(1) ~= 0 then
      local h = user32.GetClipboardData(1)
      if h ~= nil then
        local p = kernel32.GlobalLock(h)
        if p ~= nil then
          out = ffi.string(ffi.cast('const char*', p))
          if enc_ok then
            local converted = encoding.UTF8:encode(out)
            if converted and converted ~= '' then out = converted end
          end
          kernel32.GlobalUnlock(h)
        end
      end
    end
  end)
  user32.CloseClipboard()
  if not ok then return '' end
  return F.int_unname(out)
end

function F.clip_set(text)
  text = tostring(text or '')
  if text == '' then return false end
  text = F.utf_cut(text, 4000)
  local user32, kernel32 = F.user32, F.kernel32
  if user32 and kernel32 and ffi_ok then
    local opened = false
    local ok = pcall(function()
      if user32.OpenClipboard(nil) == 0 then error('open') end
      opened = true
      local n = tonumber(kernel32.MultiByteToWideChar(65001, 0, text, -1, ffi.cast('wchar_t*', 0), 0)) or 0
      if n < 1 then error('len') end
      local h = kernel32.GlobalAlloc(2, n * 2)
      if h == nil then error('alloc') end
      local p = kernel32.GlobalLock(h)
      if p == nil then
        kernel32.GlobalFree(h)
        error('lock')
      end
      local dst = ffi.cast('wchar_t*', p)
      kernel32.MultiByteToWideChar(65001, 0, text, -1, dst, n)
      kernel32.GlobalUnlock(h)
      if user32.EmptyClipboard() == 0 then
        kernel32.GlobalFree(h)
        error('empty')
      end
      if user32.SetClipboardData(13, h) == nil then
        kernel32.GlobalFree(h)
        error('set')
      end
    end)
    if opened then user32.CloseClipboard() end
    if ok then return true end
  end
  local plain = text
  if enc_ok then
    local converted_ok, converted = pcall(function() return encoding.UTF8:decode(text) end)
    if converted_ok and converted and converted ~= '' then plain = converted end
  end
  return pcall(setClipboardText, plain) and true or false
end

function F.clean_clip(text)
  text = tostring(text or '')
  text = text:gsub('[\r\n\t]', ' ')
  text = text:gsub('%z', '')
  return F.trim(text)
end

function F.paste_bind_buf()
  local text = F.clean_clip(F.clip_text())
  if text == '' then
    F.notify('Буфер пуст')
    return
  end
  local cur = F.buf_get(ui_bind)
  F.buf_set(ui_bind, cur .. text, 240)
end

function F.ensure_paste_cb()
  if F.paste_cb or not ffi_ok or not imgui_ok then return end
  local ok, cb = pcall(ffi.cast, 'ImGuiInputTextCallback', function(data)
    pcall(function()
      local add = F.bind_clip
      if not add or add == '' then return end
      F.bind_clip = nil
      local a, b = data.SelectionStart, data.SelectionEnd
      if a > b then a, b = b, a end
      local room = (data.BufSize or 0) - (data.BufTextLen or 0) - 1
      if a ~= b then room = room + (b - a) end
      if room < 1 then return end
      if #add > room then add = F.utf_cut(add, room) end
      if add == '' then return end
      if a ~= b then
        imgui.lib.ImGuiInputTextCallbackData_DeleteChars(data, a, b - a)
      end
      imgui.lib.ImGuiInputTextCallbackData_InsertChars(data, data.CursorPos, add, nil)
    end)
    return 0
  end)
  if ok then F.paste_cb = cb end
end

function F.text_hot()
  if F.hot_field then return true end
  if page == 'binds' then return F.bind_hot and true or false end
  if page == 'chat' then return F.accent_hot and true or false end
  if page == 'notes' then return F.note_hot and true or false end
  return false
end

function F.suppress_bind_paste()
  if not F.text_hot() or not imgui_ok then return end
  local alt = isKeyDown(0x12) or isKeyDown(0xA4) or isKeyDown(0xA5)
  if alt then return end
  local io = imgui.GetIO()
  local ctrl = isKeyDown(0x11) or isKeyDown(0xA2) or isKeyDown(0xA3)
  if ctrl and isKeyDown(0x56) then
    F._old_ctrl = io.KeyCtrl
    F._old_v = io.KeysDown[0x56]
    io.KeyCtrl = false
    io.KeysDown[0x56] = false
    F._muted = true
  end
  local shift = isKeyDown(0x10) or isKeyDown(0xA0) or isKeyDown(0xA1)
  if shift and isKeyDown(0x2D) then
    F._old_shift = io.KeyShift
    F._old_ins = io.KeysDown[0x2D]
    io.KeyShift = false
    io.KeysDown[0x2D] = false
    F._muted_ins = true
  end
end

function F.restore_bind_paste()
  if not imgui_ok then return end
  local io = imgui.GetIO()
  if F._muted then
    io.KeyCtrl = F._old_ctrl
    io.KeysDown[0x56] = F._old_v
    F._muted = false
  end
  if F._muted_ins then
    io.KeyShift = F._old_shift
    io.KeysDown[0x2D] = F._old_ins
    F._muted_ins = false
  end
end

function F.finish_bind(vk, mods)
  bind_vk = vk
  F.bind_mods = mods or 0
  F.cap_peak, F.cap_last = 0, 0
  capture = false
  capture_what = 'menu'
  dirty = true
  F.notify('Бинд: ' .. F.chord_name(vk, mods), true)
end

function F.read_bind_capture()
  if wasKeyPressed(0x1B) or F.take_esc() then
    bind_vk = 0
    F.bind_mods = 0
    F.cap_peak, F.cap_last = 0, 0
    capture = false
    capture_what = 'menu'
    dirty = true
    F.notify('Клавиша сброшена', true)
    return
  end
  local mask = F.mods_mask()
  F.cap_peak = F.bor(F.cap_peak or 0, mask)
  local mods = {0x10, 0x11, 0x12, 0x5B, 0x5C, 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xFF}
  for i = 1, #mods do
    if wasKeyPressed(mods[i]) then F.cap_last = mods[i] end
  end
  for vk = 8, 254 do
    if vk ~= 0x1B and not F.is_mod_vk(vk) and wasKeyPressed(vk) then
      F.finish_bind(vk, mask)
      return
    end
  end
  if (F.cap_last or 0) ~= 0 and mask == 0 then
    local trig = F.cap_last
    local extra = F.cap_peak or 0
    local own = F.mod_bit(trig)
    if own ~= 0 then extra = F.band(extra, F.bnot(own)) end
    F.finish_bind(trig, extra)
  end
end

function F.take_bind_paste()
  if not show or capture or modal or not F.text_hot() then
    F.bind_clip = nil
    return false
  end
  local alt = isKeyDown(0x12) or isKeyDown(0xA4) or isKeyDown(0xA5)
  if alt then return false end
  local ctrl = isKeyDown(0x11) or isKeyDown(0xA2) or isKeyDown(0xA3)
  local shift = isKeyDown(0x10) or isKeyDown(0xA0) or isKeyDown(0xA1)
  if (ctrl and wasKeyPressed(0x56)) or (shift and not ctrl and wasKeyPressed(0x2D)) then
    local raw = F.clip_text()
    F.int_remember(raw)
    local text = (page == 'notes' and F.note_hot) and F.note_plain(raw) or F.clean_clip(raw)
    if text == '' then
      F.notify('Буфер пуст', true)
      F.bind_clip = nil
    else
      F.bind_clip = text
    end
    return true
  end
  return false
end

function F.buf_get(buf)
  if not ffi_ok or not buf then return '' end
  local ok, s = pcall(ffi.string, buf)
  if ok and s then return s end
  return ''
end

function F.vec4(r, g, b, a)
  return imgui.ImVec4(r / 255, g / 255, b / 255, a or 1)
end

function F.rgba(r, g, b, a)
  return imgui.U32(r / 255, g / 255, b / 255, (a or 255) / 255)
end

function F.fonts_dir()
  local ok, p = pcall(getFolderPath, 0x14)
  if ok and type(p) == 'string' and p ~= '' then return p end
  return 'C:\\Windows\\Fonts'
end

function F.first_font(list)
  for i = 1, #list do
    if doesFileExist(list[i]) then return list[i] end
  end
  return nil
end

function F.add_face(path, size)
  local fonts = imgui.GetIO().Fonts
  local font = fonts:AddFontFromFileTTF(path, size, nil, font_ranges[0].Data)
  local fa_path = F.wd() .. '\\resource\\fonts\\fa-solid-900.ttf'
  if font and doesFileExist(fa_path) and fa_range then
    local cfgf = imgui.ImFontConfig()
    cfgf.MergeMode = true
    cfgf.PixelSnapH = true
    font_keep[#font_keep + 1] = cfgf
    fonts:AddFontFromFileTTF(fa_path, size - 1, cfgf, fa_range)
  end
  return font
end

function F.init_fonts()
  if not imgui_ok then return end
  local ok, err = pcall(function()
    local dir = F.fonts_dir()
    local regular = F.first_font({
      dir .. '\\segoeui.ttf',
      dir .. '\\tahoma.ttf',
      dir .. '\\arial.ttf',
    })
    local bold = F.first_font({
      dir .. '\\segoeuib.ttf',
      dir .. '\\tahomabd.ttf',
      regular,
    })
    if not regular then
      font_warn = 'Нет Segoe UI, кириллица может пропасть'
      return
    end
    font_builder = imgui.ImFontGlyphRangesBuilder()
    font_builder:AddRanges(imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    if font_builder.AddText then font_builder:AddText('—–…«»№') end
    font_ranges = imgui.ImVector_ImWchar()
    font_builder:BuildRanges(font_ranges)
    if fa_ok and fa and fa.min_range and fa.max_range then
      fa_range = imgui.new.ImWchar[3](fa.min_range, fa.max_range, 0)
    end
    font_main = F.add_face(regular, 16)
    font_bold = F.add_face(bold or regular, 18)
    font_title = F.add_face(bold or regular, 22)
    if not doesFileExist(F.wd() .. '\\resource\\fonts\\fa-solid-900.ttf') then
      font_warn = 'Нет файла иконок fa-solid-900.ttf'
    end
  end)
  if not ok then
    font_main, font_bold, font_title = nil, nil, nil
    font_warn = 'Шрифт не загрузился'
    F.log_line('Шрифт: ' .. tostring(err))
  end
end

local COL_N = 0
local VAR_N = 0

-- One palette for the whole menu. These are the original fHelper colours.
local PAL = {
  bg = {16, 33, 28},
  side = {12, 25, 22},
  panel = {23, 48, 42},
  raised = {28, 61, 52},
  hover = {36, 74, 62},
  press = {18, 48, 40},
  text = {246, 241, 230},
  accent = {224, 138, 85},
  accent_hi = {232, 160, 110},
  accent_lo = {196, 107, 58},
  bad = {255, 180, 168},
  ink = {28, 25, 21},
}

function F.col(name, a)
  local c = PAL[name] or PAL.text
  return F.rgba(c[1], c[2], c[3], a)
end

function F.cvec(name, a)
  local c = PAL[name] or PAL.text
  return F.vec4(c[1], c[2], c[3], a)
end

function F.s(v)
  return v * (cfg.scale or 1)
end

function F.utf_first(s)
  return tostring(s or ''):match('^[%z\1-\127\194-\244][\128-\191]*') or ''
end

function F.style_push(alpha)
  local colors = {
    {imgui.Col.Text, F.cvec('text')},
    {imgui.Col.TextDisabled, F.cvec('text', 0.45)},
    {imgui.Col.WindowBg, F.cvec('bg', 0)},
    {imgui.Col.ChildBg, F.cvec('panel', 0)},
    {imgui.Col.PopupBg, F.cvec('panel')},
    {imgui.Col.Border, F.cvec('text', 0.12)},
    {imgui.Col.FrameBg, F.cvec('side')},
    {imgui.Col.FrameBgHovered, F.cvec('press')},
    {imgui.Col.FrameBgActive, F.cvec('side')},
    {imgui.Col.Button, F.cvec('raised')},
    {imgui.Col.ButtonHovered, F.cvec('hover')},
    {imgui.Col.ButtonActive, F.cvec('press')},
    {imgui.Col.Header, F.cvec('accent', 0.22)},
    {imgui.Col.HeaderHovered, F.cvec('accent', 0.32)},
    {imgui.Col.HeaderActive, F.cvec('accent', 0.42)},
    {imgui.Col.Separator, F.cvec('text', 0.12)},
    {imgui.Col.ScrollbarBg, F.cvec('side', 0)},
    {imgui.Col.ScrollbarGrab, F.cvec('text', 0.14)},
    {imgui.Col.ScrollbarGrabHovered, F.cvec('accent', 0.7)},
    {imgui.Col.ScrollbarGrabActive, F.cvec('accent')},
    {imgui.Col.CheckMark, F.cvec('accent')},
    {imgui.Col.SliderGrab, F.cvec('accent')},
    {imgui.Col.SliderGrabActive, F.cvec('accent_hi')},
    {imgui.Col.TextSelectedBg, F.cvec('accent', 0.35)},
  }
  COL_N = #colors
  for i = 1, COL_N do
    imgui.PushStyleColor(colors[i][1], colors[i][2])
  end
  local floats = {
    {imgui.StyleVar.Alpha, alpha or (cfg.opacity * anim)},
    {imgui.StyleVar.WindowRounding, 18},
    {imgui.StyleVar.ChildRounding, 14},
    {imgui.StyleVar.FrameRounding, 8},
    {imgui.StyleVar.PopupRounding, 12},
    {imgui.StyleVar.WindowBorderSize, 0},
    {imgui.StyleVar.ChildBorderSize, 0},
    {imgui.StyleVar.FrameBorderSize, 0},
    {imgui.StyleVar.ScrollbarRounding, 8},
    {imgui.StyleVar.ScrollbarSize, 8},
    {imgui.StyleVar.GrabRounding, 8},
    {imgui.StyleVar.GrabMinSize, 14},
  }
  for i = 1, #floats do
    imgui.PushStyleVarFloat(floats[i][1], floats[i][2])
  end
  imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
  imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(12, 8))
  imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 8))
  VAR_N = #floats + 3
end

function F.style_pop()
  if VAR_N > 0 then imgui.PopStyleVar(VAR_N) end
  if COL_N > 0 then imgui.PopStyleColor(COL_N) end
  VAR_N, COL_N = 0, 0
end

function F.use_font(font)
  if font then imgui.PushFont(font) end
end

function F.done_font(font)
  if font then imgui.PopFont() end
end

function F.hotspot(id, x, y, w, h)
  imgui.SetCursorScreenPos(imgui.ImVec2(x, y))
  imgui.InvisibleButton(id, imgui.ImVec2(math.max(1, w), math.max(1, h)))
  return imgui.IsItemClicked(), imgui.IsItemHovered()
end

-- Custom blocks draw by coordinates, then reserve their place in the layout.
function F.advance(p, w, h)
  imgui.SetCursorScreenPos(p)
  imgui.Dummy(imgui.ImVec2(math.max(1, w), math.max(1, h)))
end

function F.text_at(font, size, x, y, col, str, wrap, scale)
  if not str or str == '' then return end
  local dl = imgui.GetWindowDrawList()
  local px = size * (scale or cfg.scale or 1)
  if font then
    dl:AddTextFontPtr(font, px, imgui.ImVec2(x, y), col, str, nil, wrap or 0, nil)
  else
    dl:AddText(imgui.ImVec2(x, y), col, str)
  end
end

function F.text_w(font, str)
  F.use_font(font)
  local sz = imgui.CalcTextSize(str or '')
  local w = sz.x
  F.done_font(font)
  return w
end

function F.fit_text(font, str, max_w)
  str = tostring(str or '')
  if max_w < 8 then return '' end
  -- Cutting goes char by char through CalcTextSize, so long rows are cached.
  local key = tostring(font) .. '|' .. math.floor(max_w) .. '|' .. tostring(cfg.scale) .. '|' .. str
  local cache = F._fit or {}
  F._fit = cache
  if cache[key] then return cache[key] end
  if F._fit_n and F._fit_n > 600 then
    cache = {}
    F._fit = cache
    F._fit_n = 0
  end
  local out = F.fit_text_raw(font, str, max_w)
  cache[key] = out
  F._fit_n = (F._fit_n or 0) + 1
  return out
end

function F.fit_text_raw(font, str, max_w)
  if F.text_w(font, str) <= max_w then return str end
  local ell = '…'
  local acc = ''
  local i = 1
  while i <= #str do
    local b = str:byte(i)
    local len = 1
    if b >= 240 then len = 4
    elseif b >= 224 then len = 3
    elseif b >= 192 then len = 2
    end
    if i + len - 1 > #str then len = 1 end
    local ch = str:sub(i, i + len - 1)
    if F.text_w(font, acc .. ch .. ell) > max_w then break end
    acc = acc .. ch
    i = i + len
  end
  if acc == '' then return ell end
  return acc .. ell
end

function F.clip_card(x, y, w, h)
  imgui.GetWindowDrawList():PushClipRect(imgui.ImVec2(x, y), imgui.ImVec2(x + w, y + h), true)
end

function F.unclip()
  imgui.GetWindowDrawList():PopClipRect()
end

-- ImGui 1.74 rounds a corner with three segments, which looks jagged on big
-- radii. The outline is built here with enough segments and whole pixels.
function F.round_path(dl, x1, y1, x2, y2, r)
  r = math.min(r or 0, (x2 - x1) / 2, (y2 - y1) / 2)
  if r < 1 then
    dl:PathLineTo(imgui.ImVec2(x1, y1))
    dl:PathLineTo(imgui.ImVec2(x2, y1))
    dl:PathLineTo(imgui.ImVec2(x2, y2))
    dl:PathLineTo(imgui.ImVec2(x1, y2))
    return
  end
  local seg = math.max(4, math.min(16, math.floor(r * 0.7)))
  local pi = math.pi
  dl:PathArcTo(imgui.ImVec2(x1 + r, y1 + r), r, pi, pi * 1.5, seg)
  dl:PathArcTo(imgui.ImVec2(x2 - r, y1 + r), r, pi * 1.5, pi * 2, seg)
  dl:PathArcTo(imgui.ImVec2(x2 - r, y2 - r), r, 0, pi * 0.5, seg)
  dl:PathArcTo(imgui.ImVec2(x1 + r, y2 - r), r, pi * 0.5, pi, seg)
end

function F.round_rect(x, y, w, h, col, border, rad, dl)
  dl = dl or imgui.GetWindowDrawList()
  rad = rad or 12
  local x1, y1 = math.floor(x + 0.5), math.floor(y + 0.5)
  local x2, y2 = math.floor(x + w + 0.5), math.floor(y + h + 0.5)
  if x2 - x1 < 1 or y2 - y1 < 1 then return end
  if col then
    F.round_path(dl, x1, y1, x2, y2, rad)
    dl:PathFillConvex(col)
  end
  if border then
    -- Half a pixel inside, so the line sits on the edge of the fill.
    F.round_path(dl, x1 + 0.5, y1 + 0.5, x2 - 0.5, y2 - 0.5, rad - 0.5)
    dl:PathStroke(border, true, 1)
  end
end

function F.tip(text)
  if not text or text == '' then return end
  imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(10, 6))
  imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 6)
  imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 1)
  imgui.PushStyleColor(imgui.Col.PopupBg, F.cvec('raised'))
  imgui.PushStyleColor(imgui.Col.Border, F.cvec('text', 0.16))
  imgui.SetTooltip('%s', tostring(text))
  imgui.PopStyleColor(2)
  imgui.PopStyleVar(3)
end

-- Hand-drawn button. w and h are design pixels (scaled here), 0 means auto,
-- w = 'square' makes it as wide as it is tall.
function F.button(label, w, h, kind)
  local text = label:gsub('##.*$', '')
  h = (h and h > 0) and F.s(h) or imgui.GetFrameHeight()
  if w == 'square' then w = h
  elseif w and w > 0 then w = F.s(w)
  else w = F.text_w(font_main, text) + F.s(28) end
  local p = imgui.GetCursorScreenPos()
  local clicked = imgui.InvisibleButton(label, imgui.ImVec2(w, h))
  local hovered, held = imgui.IsItemHovered(), imgui.IsItemActive()
  local bg, fg, border
  if kind == 'primary' then
    bg = held and F.col('accent_lo') or (hovered and F.col('accent_hi') or F.col('accent'))
    fg = F.col('ink')
  elseif kind == 'danger' then
    bg = held and F.col('bad', 70) or (hovered and F.col('bad', 52) or F.col('bad', 30))
    fg = F.col('bad')
  else
    bg = held and F.col('press') or (hovered and F.col('hover') or F.col('raised'))
    fg = F.col('text', hovered and 255 or 225)
    border = F.col('text', hovered and 32 or 18)
  end
  F.round_rect(p.x, p.y, w, h, bg, border, math.min(F.s(10), h / 2))
  text = F.fit_text(font_main, text, w - F.s(12))
  local tw = F.text_w(font_main, text)
  F.text_at(font_main, 16, p.x + (w - tw) / 2, p.y + (h - F.s(16)) / 2 - 1, fg, text)
  return clicked
end

function F.window_box()
  local sw = imgui.GetIO().DisplaySize.x
  local sh = imgui.GetIO().DisplaySize.y
  if sw < 100 then sw = 1366 end
  if sh < 100 then sh = 768 end
  if maximized then
    return math.max(800, sw - 16), math.max(520, sh - 16), sw, sh
  end
  local w = math.min(1080, sw - 24)
  local h = math.min(700, sh - 24)
  if w < 860 then w = math.max(760, sw - 12) end
  if h < 540 then h = math.max(500, sh - 12) end
  return w, h, sw, sh
end

-- Inner padding of a card, same on every side.
F.PAD = 18

-- Cards. The body is drawn first on channel 1, the panel goes under it on channel 0
-- once its height is known. Cards must not be nested and must always be closed.
function F.card_begin(title, sub, icon)
  local w = imgui.GetContentRegionAvail().x
  local p = imgui.GetCursorScreenPos()
  local dl = imgui.GetWindowDrawList()
  dl:ChannelsSplit(2)
  dl:ChannelsSetCurrent(1)
  F._card = {x = p.x, y = p.y, w = w, dl = dl}
  imgui.SetCursorScreenPos(imgui.ImVec2(p.x + F.PAD, p.y + F.PAD))
  imgui.BeginGroup()
  if title then
    local tp = imgui.GetCursorScreenPos()
    local tx = tp.x
    local glyph = icon and F.faico(icon) or ''
    if glyph ~= '' then
      F.text_at(font_main, 16, tx, tp.y + F.s(2), F.col('accent'), glyph)
      tx = tx + F.text_w(font_main, glyph) + 10
    end
    F.text_at(font_bold, 18, tx, tp.y, F.col('text'), title)
    F.advance(tp, 1, F.s(20))
    if sub and sub ~= '' then F.hint(sub) end
    imgui.Dummy(imgui.ImVec2(1, 2))
  end
end

function F.card_end()
  local c = F._card
  if not c then return end
  imgui.EndGroup()
  local bottom = imgui.GetItemRectMax().y + F.PAD
  c.dl:ChannelsSetCurrent(0)
  F.round_rect(c.x, c.y, c.w, bottom - c.y, F.col('panel'), F.col('text', 20), 16)
  c.dl:ChannelsMerge()
  F._card = nil
  F.advance(imgui.ImVec2(c.x, c.y), c.w, bottom - c.y)
  imgui.Dummy(imgui.ImVec2(1, 2))
end

function F.inner_w()
  local c = F._card
  if c then
    return math.max(40, c.x + c.w - F.PAD - imgui.GetCursorScreenPos().x)
  end
  return math.max(40, imgui.GetContentRegionAvail().x)
end

function F.wrap_x()
  local c = F._card
  if c then return c.x + c.w - F.PAD - imgui.GetWindowPos().x end
  return 0
end

function F.same_if_fit(w)
  local edge
  local c = F._card
  if c then
    edge = c.x + c.w - F.PAD
  else
    edge = imgui.GetWindowPos().x + imgui.GetWindowContentRegionMax().x
  end
  local prev = imgui.GetItemRectMax().x
  if prev + 8 + w <= edge + 0.5 then
    imgui.SameLine()
  end
end

function F.hint(text, col)
  imgui.PushStyleColor(imgui.Col.Text, col or F.cvec('text', 0.62))
  imgui.PushTextWrapPos(F.wrap_x())
  imgui.TextUnformatted(text)
  imgui.PopTextWrapPos()
  imgui.PopStyleColor()
end

function F.hint_bad(text)
  F.hint(text, F.cvec('bad'))
end

function F.page_head(title, sub)
  local p = imgui.GetCursorScreenPos()
  F.text_at(font_title, 22, p.x, p.y, F.col('text'), title)
  local h = F.s(30)
  if sub and sub ~= '' then
    local w = imgui.GetContentRegionAvail().x
    F.text_at(font_main, 16, p.x, p.y + F.s(32), F.col('text', 140), F.fit_text(font_main, sub, w))
    h = F.s(54)
  end
  F.advance(p, 1, h)
  imgui.Dummy(imgui.ImVec2(1, 2))
end

function F.section_title(title, sub)
  local p = imgui.GetCursorScreenPos()
  imgui.GetWindowDrawList():AddRectFilled(imgui.ImVec2(p.x, p.y + 3), imgui.ImVec2(p.x + 3, p.y + 18), F.col('accent'), 2)
  imgui.SetCursorScreenPos(imgui.ImVec2(p.x + 12, p.y))
  imgui.TextUnformatted(title)
  if sub and sub ~= '' then F.hint(sub) end
  imgui.Spacing()
end

function F.divider()
  local p = imgui.GetCursorScreenPos()
  local w = F.inner_w()
  imgui.GetWindowDrawList():AddLine(imgui.ImVec2(p.x, p.y + 4), imgui.ImVec2(p.x + w, p.y + 4), F.col('text', 18), 1)
  F.advance(p, w, 8)
end

function F.accent_button(label, w, h)
  return F.button(label, w, h, 'primary')
end

function F.icon_btn(icon, id, tip, accent)
  local glyph = F.faico(icon)
  if glyph == '' then glyph = F.utf_first(tip or '?') end
  local hit = F.button(glyph .. '##' .. id, 'square', 0, accent and 'primary' or nil)
  if tip and tip ~= '' and imgui.IsItemHovered() then F.tip(tip) end
  return hit
end

-- Small square icon without a frame, for rows and headers.
function F.ghost_icon(id, x, y, icon, tip, danger)
  local size = F.s(30)
  local clicked, hovered = F.hotspot(id, x, y, size, size)
  if hovered then
    F.round_rect(x, y, size, size, danger and F.col('bad', 36) or F.col('text', 22), nil, 9)
    if tip then F.tip(tip) end
  end
  local glyph = F.faico(icon)
  if glyph == '' then glyph = F.utf_first(tip or '?') end
  local col = hovered and (danger and F.col('bad') or F.col('text')) or F.col('text', 150)
  local gw = F.text_w(font_main, glyph)
  F.text_at(font_main, 16, x + (size - gw) / 2, y + (size - F.s(16)) / 2 - 1, col, glyph)
  return clicked
end

function F.chip_w(text)
  return F.text_w(font_main, text) + F.s(28)
end

function F.chip(x, y, text, tone)
  local fg, bg
  if tone == 'on' then fg, bg = F.col('accent_hi'), F.col('accent', 40)
  elseif tone == 'bad' then fg, bg = F.col('bad'), F.col('bad', 34)
  else fg, bg = F.col('text', 170), F.col('text', 18) end
  local w, h = F.chip_w(text), F.s(24)
  F.round_rect(x, y, w, h, bg, nil, h / 2)
  imgui.GetWindowDrawList():AddCircleFilled(imgui.ImVec2(x + F.s(11), y + h / 2), F.s(3), fg, 12)
  F.text_at(font_main, 16, x + F.s(19), y + (h - F.s(16)) / 2 - 1, fg, text)
  return w
end

function F.keycap_w(text)
  return F.text_w(font_main, text) + F.s(18)
end

function F.keycap(x, y, text, lit)
  local w, h = F.keycap_w(text), F.s(28)
  F.round_rect(x, y + 2, w, h, F.col('side'), nil, 8)
  F.round_rect(x, y, w, h, lit and F.col('accent', 46) or F.col('raised'), lit and F.col('accent', 150) or F.col('text', 34), 8)
  F.text_at(font_main, 16, x + F.s(9), y + (h - F.s(16)) / 2 - 1, lit and F.col('accent_hi') or F.col('text'), text)
  return w
end

function F.chord_parts(vk, mods)
  local parts = {}
  mods = tonumber(mods) or 0
  if F.band(mods, 1) ~= 0 then parts[#parts + 1] = 'Ctrl' end
  if F.band(mods, 2) ~= 0 then parts[#parts + 1] = 'Alt' end
  if F.band(mods, 4) ~= 0 then parts[#parts + 1] = 'Shift' end
  if F.band(mods, 8) ~= 0 then parts[#parts + 1] = 'Win' end
  if F.band(mods, 16) ~= 0 then parts[#parts + 1] = 'Fn' end
  vk = tonumber(vk) or 0
  if vk ~= 0 then parts[#parts + 1] = F.key_name(vk) end
  return parts
end

function F.chord_caps(x, y, vk, mods, lit)
  local parts = F.chord_parts(vk, mods)
  if #parts == 0 then
    local w = F.keycap_w('нет')
    F.round_rect(x, y, w, F.s(28), F.col('text', 10), F.col('text', 30), 8)
    F.text_at(font_main, 16, x + F.s(9), y + (F.s(28) - F.s(16)) / 2 - 1, F.col('text', 120), 'нет')
    return w
  end
  local cx = x
  local plus_w = F.text_w(font_main, '+')
  for i = 1, #parts do
    if i > 1 then
      F.text_at(font_main, 16, cx + F.s(5), y + F.s(5), F.col('text', 110), '+')
      cx = cx + plus_w + F.s(10)
    end
    cx = cx + F.keycap(cx, y, parts[i], lit)
  end
  return cx - x
end

-- Toggle switch knob with a short slide.
function F.knob(id, x, y, on, hovered)
  local sw, sh = F.s(40), F.s(22)
  F._sw = F._sw or {}
  local goal = on and 1 or 0
  local cur = F._sw[id] or goal
  local step = math.min(1, (imgui.GetIO().DeltaTime or 0.016) * 14)
  cur = cur + (goal - cur) * step
  if math.abs(goal - cur) < 0.01 then cur = goal end
  F._sw[id] = cur
  local track
  if on then track = hovered and F.col('accent_hi') or F.col('accent')
  else track = hovered and F.col('hover') or F.col('raised') end
  F.round_rect(x, y, sw, sh, track, on and nil or F.col('text', 30), sh / 2)
  local r = sh / 2 - F.s(3)
  local cx = x + sh / 2 + (sw - sh) * cur
  imgui.GetWindowDrawList():AddCircleFilled(imgui.ImVec2(cx, y + sh / 2), r, on and F.col('ink') or F.col('text', 210), 24)
  return sw, sh
end

function F.switch(id, label, on, sub)
  local p = imgui.GetCursorScreenPos()
  local w = F.inner_w()
  local h = F.s(sub and 46 or 30)
  local clicked, hovered = F.hotspot('##sw' .. id, p.x, p.y, w, h)
  local kx = p.x + w - F.s(40)
  F.knob(id, kx, p.y + (h - F.s(22)) / 2, on, hovered)
  local ty = sub and (p.y + F.s(3)) or (p.y + (h - F.s(16)) / 2 - 1)
  F.text_at(font_main, 16, p.x, ty, F.col('text', hovered and 255 or 230), F.fit_text(font_main, label, w - F.s(56)))
  if sub then
    F.text_at(font_main, 16, p.x, p.y + F.s(24), F.col('text', 130), F.fit_text(font_main, sub, w - F.s(56)))
  end
  F.advance(p, w, h)
  return clicked
end

function F.segment(id, items, cur, w)
  local p = imgui.GetCursorScreenPos()
  w = w or F.inner_w()
  local h = imgui.GetFrameHeight()
  local n = #items
  local cw = (w - 8) / n
  local pick
  F.round_rect(p.x, p.y, w, h, F.col('side'), F.col('text', 16), 10)
  for i = 1, n do
    local x = p.x + 4 + (i - 1) * cw
    local clicked, hovered = F.hotspot('##seg' .. id .. i, x, p.y + 4, cw, h - 8)
    local active = items[i][1] == cur
    if active then
      F.round_rect(x, p.y + 4, cw, h - 8, F.col('accent'), nil, 7)
    elseif hovered then
      F.round_rect(x, p.y + 4, cw, h - 8, F.col('text', 16), nil, 7)
    end
    local label = F.fit_text(font_main, items[i][2], cw - 12)
    local tw = F.text_w(font_main, label)
    local col = active and F.col('ink') or F.col('text', hovered and 255 or 180)
    F.text_at(font_main, 16, x + (cw - tw) / 2, p.y + (h - F.s(16)) / 2 - 1, col, label)
    if clicked then pick = items[i][1] end
  end
  F.advance(p, w, h)
  return pick
end

function F.pill_w(text)
  return F.text_w(font_main, text) + F.s(26)
end

function F.pill(id, text, active)
  local p = imgui.GetCursorScreenPos()
  local w, h = F.pill_w(text), F.s(30)
  local clicked, hovered = F.hotspot(id, p.x, p.y, w, h)
  local bg, fg
  if active then
    bg, fg = F.col('accent'), F.col('ink')
  else
    bg = hovered and F.col('hover') or F.col('raised')
    fg = F.col('text', hovered and 255 or 210)
  end
  F.round_rect(p.x, p.y, w, h, bg, nil, h / 2)
  F.text_at(font_main, 16, p.x + F.s(13), p.y + (h - F.s(16)) / 2 - 1, fg, text)
  F.advance(p, w, h)
  return clicked, hovered
end

function F.pill_row(prefix, list, pick)
  local hit
  for i = 1, #list do
    local item = list[i]
    if i > 1 then F.same_if_fit(F.pill_w(item[2])) end
    if F.pill(prefix .. i, item[2], item[1] == pick) then hit = item[1] end
    if item[3] and imgui.IsItemHovered() then F.tip(item[3]) end
  end
  return hit
end

function F.tile(id, w, icon, label, value, bar)
  local h = F.s(66)
  local p = imgui.GetCursorScreenPos()
  value = tostring(value or '—')
  local can_copy = value ~= '—' and value ~= ''
  local clicked, hovered = F.hotspot('##tile' .. id, p.x, p.y, w, h)
  F.round_rect(p.x, p.y, w, h, hovered and F.col('raised') or F.col('side', 150), F.col('text', hovered and 34 or 14), 14)
  local isz = F.s(38)
  local ix, iy = p.x + F.s(12), p.y + (h - isz) / 2
  F.round_rect(ix, iy, isz, isz, F.col('accent', hovered and 60 or 36), nil, 11)
  local glyph = F.faico(icon)
  if glyph == '' then glyph = F.utf_first(label) end
  local gw = F.text_w(font_main, glyph)
  F.text_at(font_main, 16, ix + (isz - gw) / 2, iy + (isz - F.s(16)) / 2 - 1, F.col('accent_hi'), glyph)
  local tx = ix + isz + F.s(12)
  local tw = p.x + w - tx - F.s(10)
  F.text_at(font_main, 16, tx, p.y + F.s(12), F.col('text', 135), F.fit_text(font_main, label, tw))
  F.text_at(font_bold, 18, tx, p.y + F.s(32), F.col('text'), F.fit_text(font_bold, value, tw))
  if bar then
    if bar < 0 then bar = 0 elseif bar > 1 then bar = 1 end
    local by = p.y + h - F.s(7)
    local bw = p.x + w - F.s(12) - tx
    F.round_rect(tx, by, bw, 3, F.col('text', 18), nil, 2)
    if bar > 0 then F.round_rect(tx, by, math.max(3, bw * bar), 3, F.col('accent'), nil, 2) end
  end
  if hovered and can_copy then F.tip('Нажми, чтобы скопировать') end
  if clicked and can_copy then F.note_copy(value) end
  F.advance(p, w, h)
end

function F.tile_grid(id, list, min_w)
  local w = F.inner_w()
  min_w = F.s(min_w or 190)
  local cols = math.max(1, math.floor((w + 8) / (min_w + 8)))
  local cell = math.floor((w - 8 * (cols - 1)) / cols)
  for i = 1, #list do
    if (i - 1) % cols ~= 0 then imgui.SameLine(0, 8) end
    local t = list[i]
    F.tile(id .. i, cell, t[1], t[2], t[3], t[4])
  end
end

function F.empty(icon, title, sub)
  local w = F.inner_w()
  local p = imgui.GetCursorScreenPos()
  local h = F.s(sub and 116 or 90)
  local cy = p.y + F.s(30)
  imgui.GetWindowDrawList():AddCircleFilled(imgui.ImVec2(p.x + w / 2, cy), F.s(24), F.col('accent', 32), 32)
  local glyph = F.faico(icon)
  if glyph ~= '' then
    local gw = F.text_w(font_main, glyph)
    F.text_at(font_main, 16, p.x + (w - gw) / 2, cy - F.s(9), F.col('accent_hi'), glyph)
  end
  local tw = F.text_w(font_bold, title)
  F.text_at(font_bold, 18, p.x + (w - tw) / 2, p.y + F.s(62), F.col('text', 230), title)
  if sub then
    local s = F.fit_text(font_main, sub, w - 20)
    local sw = F.text_w(font_main, s)
    F.text_at(font_main, 16, p.x + (w - sw) / 2, p.y + F.s(88), F.col('text', 130), s)
  end
  F.advance(p, w, h)
end

function F.slider_row(id, label, ptr, lo, hi, fmt)
  imgui.TextUnformatted(label)
  imgui.PushItemWidth(F.inner_w())
  local changed = imgui.SliderFloat('##' .. id, ptr, lo, hi, fmt)
  imgui.PopItemWidth()
  return changed
end

function F.search_text()
  if not ui_search or not ffi_ok then return '' end
  local ok, s = pcall(ffi.string, ui_search)
  if not ok or not s then return '' end
  return F.lower_text(F.trim(s))
end

function F.script_visible(item)
  if filter_st == 'Включен' and not item.loaded then return false end
  if filter_st == 'Выключен' and item.loaded then return false end
  if filter_st == 'Проверить' and not item.warn then return false end
  if filter_cat ~= 'Все' and (item.category or '') ~= filter_cat then return false end
  local q = F.search_text()
  if q == '' then return true end
  local hay = F.lower_text((item.name or '') .. ' ' .. (item.desc or '') .. ' ' .. (item.author or '') .. ' ' .. (item.rel or '') .. ' ' .. (item.category or ''))
  return hay:find(q, 1, true) ~= nil
end

function F.categories()
  local seen, list = {}, {'Все'}
  for i = 1, #file_list do
    local c = file_list[i].category or 'Скрипты'
    if not seen[c] then
      seen[c] = true
      list[#list + 1] = c
    end
  end
  return list
end

function F.cycle_cat()
  local list = F.categories()
  local at = 1
  for i = 1, #list do
    if list[i] == filter_cat then at = i break end
  end
  filter_cat = list[at % #list + 1]
end

function F.toggle_script(item)
  if item.loaded then
    local text = item.self and 'Выключить fHelper? Меню закроется.' or ('Выключить скрипт ' .. item.name .. '?')
    F.ask(text, 'Выключить', 'unload', {path = item.path})
  else
    F.queue('load', {path = item.path})
  end
end

function F.nav_title(id)
  for i = 1, #NAV do
    if NAV[i][1] == id then return NAV[i][3] end
  end
  return ''
end

-- Header height. Everything in the header is centred on it.
F.HEAD = 56

function F.header_icon(id, x, y, glyph, tip, action)
  local size = 32
  local clicked, hovered = F.hotspot(id, x, y, size, size)
  if hovered then
    F.round_rect(x, y, size, size, action == 'close' and F.col('bad', 40) or F.col('text', 22), nil, 10)
    F.tip(tip)
  end
  local col = hovered and F.col('text') or F.col('text', 150)
  if action == 'close' and hovered then col = F.col('bad') end
  local gw = F.text_w(font_main, glyph)
  F.text_at(font_main, 16, x + (size - gw) / 2, y + (size - F.s(16)) / 2, col, glyph)
  if clicked then
    if action == 'min' then collapsed = not collapsed
    elseif action == 'max' then
      maximized = not maximized
      collapsed = false
    elseif action == 'close' then
      local p = imgui.GetWindowPos()
      cfg.x, cfg.y = p.x, p.y - F.anim_slide()
      F.close_menu()
    elseif action == 'settings' then page = 'settings'
    elseif action == 'reload' then F.queue('reload_self')
    elseif action == 'upd' then F.upd_button()
    elseif action == 'patch' then
      modal = {kind = 'patch', title = 'Что нового'}
      cfg.seen_ver = VER
      dirty = true
    end
  end
  return hovered
end

function F.paint_back(ww, wh, wp)
  local dl = imgui.GetWindowDrawList()
  local x, y = wp.x, wp.y
  local r = 18
  F.round_rect(x, y, ww, wh, F.col('bg'), nil, r)
  if not collapsed and wh >= 80 then
    -- The glow starts past the corner radius, so it never pokes out of the round corner.
    local glow_w = math.min(ww - r, 560)
    local glow_h = math.min(wh - r, 240)
    dl:AddRectFilledMultiColor(
      imgui.ImVec2(math.floor(x + r), math.floor(y + 1)),
      imgui.ImVec2(math.floor(x + glow_w), math.floor(y + glow_h)),
      F.col('accent', 26),
      F.col('accent', 0),
      F.col('bg', 0),
      F.col('accent', 0))
  end
  F.round_rect(x, y, ww, wh, nil, F.col('text', 34), r)
end

function F.paint_top(ww, wp, side_w)
  local dl = imgui.GetWindowDrawList()
  local hh = F.HEAD
  local ls = 32
  local lx, ly = wp.x + 16, wp.y + (hh - ls) / 2
  F.round_rect(lx, ly, ls, ls, F.col('accent'), nil, 10)
  local fw = F.text_w(font_bold, 'f')
  F.text_at(font_bold, 18, lx + (ls - fw) / 2, ly + (ls - F.s(18)) / 2 - 1, F.col('ink'), 'f')
  if side_w >= 120 or collapsed then
    local block = F.s(18) + F.s(16) + 1
    local by = wp.y + (hh - block) / 2 - 1
    F.text_at(font_bold, 18, lx + ls + 10, by, F.col('text'), 'fHelper')
    F.text_at(font_main, 16, lx + ls + 10, by + F.s(18) + 1, F.col('text', 130), F.proj().name)
  end
  dl:AddLine(imgui.ImVec2(wp.x + 1, math.floor(wp.y + hh) + 0.5), imgui.ImVec2(wp.x + ww - 1, math.floor(wp.y + hh) + 0.5), F.col('text', 22), 1)
  local controls = 6 * 34 + 16
  local tx = wp.x + side_w + 22
  if not collapsed then
    local title = F.nav_title(page)
    F.text_at(font_bold, 18, tx, wp.y + (hh - F.s(18)) / 2 - 1, F.col('text'), title)
    tx = tx + F.text_w(font_bold, title) + 18
  end
  local label = live.online and F.fit_text(font_main, live.server, 220) or 'Нет подключения'
  local ph = F.s(28)
  local pw = F.text_w(font_main, label) + F.s(34)
  local px = wp.x + ww - controls - pw - 8
  local py = wp.y + (hh - ph) / 2
  if px > tx then
    F.round_rect(px, py, pw, ph, F.col('side', 200), F.col('text', 24), ph / 2)
    dl:AddCircleFilled(imgui.ImVec2(px + F.s(14), py + ph / 2), F.s(4), live.online and F.col('accent') or F.col('bad'), 16)
    F.text_at(font_main, 16, px + F.s(24), py + (ph - F.s(16)) / 2 - 1, F.col('text', 220), label)
  end
  local function glyph(key, alt)
    local g = F.faico(key)
    if g == '' then return alt end
    return g
  end
  local iy = wp.y + (hh - 32) / 2
  local bx = wp.x + ww - 12 - 32
  F.header_icon('##close', bx, iy, glyph('ICON_FA_TIMES', 'X'), 'Закрыть (Esc)', 'close')
  bx = bx - 34
  F.header_icon('##max', bx, iy, maximized and glyph('ICON_FA_COMPRESS', '-') or glyph('ICON_FA_EXPAND', '+'), maximized and 'Обычный размер' or 'Во весь экран', 'max')
  bx = bx - 34
  F.header_icon('##min', bx, iy, glyph('ICON_FA_WINDOW_MINIMIZE', '_'), collapsed and 'Развернуть' or 'Свернуть', 'min')
  bx = bx - 34
  F.header_icon('##rel', bx, iy, glyph('ICON_FA_SYNC', 'R'), 'Перезагрузить fHelper', 'reload')
  bx = bx - 34
  local u = F.upd_state()
  local busy = u.state == 'checking' or u.state == 'loading'
  F.header_icon('##upd', bx, iy, busy and glyph('ICON_FA_HOURGLASS_HALF', '…') or glyph('ICON_FA_CLOUD_DOWNLOAD_ALT', 'U'), F.upd_tip(), 'upd')
  if u.state == 'new' then
    dl:AddCircleFilled(imgui.ImVec2(bx + 25, iy + 7), 4, F.col('accent'), 12)
  end
  bx = bx - 34
  F.header_icon('##patch', bx, iy, glyph('ICON_FA_BULLHORN', '!'), 'Что нового в версии ' .. VER, 'patch')
  if cfg.seen_ver ~= VER then
    -- A dot until the notes of this version were opened.
    dl:AddCircleFilled(imgui.ImVec2(bx + 25, iy + 7), 4, F.col('accent'), 12)
  end
end

function F.paint_side(h, wide)
  local wp = imgui.GetWindowPos()
  local dl = imgui.GetWindowDrawList()
  local pad = 10
  local bw = imgui.GetWindowWidth() - pad * 2
  -- Rows shrink so the whole list fits, on a small screen and at a big scale too.
  local room = h - 16 - (wide and F.s(62) or 0)
  local ih = math.max(F.s(28), math.min(F.s(40), math.floor(room / #NAV) - 3))
  local y = wp.y + 10
  for i = 1, #NAV do
    local item = NAV[i]
    local x = wp.x + pad
    local clicked, hovered = F.hotspot('##nav' .. item[1], x, y, bw, ih)
    local active = page == item[1]
    if active then
      F.round_rect(x, y, bw, ih, F.col('raised'), F.col('text', 18), 12)
      dl:AddRectFilled(imgui.ImVec2(x, y + ih * 0.25), imgui.ImVec2(x + 3, y + ih * 0.75), F.col('accent'), 2)
    elseif hovered then
      F.round_rect(x, y, bw, ih, F.col('text', 12), nil, 12)
    end
    local glyph = F.faico(item[2])
    if glyph == '' then glyph = F.utf_first(item[3]) end
    local icol = active and F.col('accent') or F.col('text', hovered and 230 or 140)
    local ty = y + (ih - F.s(16)) / 2 - 1
    local gw = F.text_w(font_main, glyph)
    if wide then
      F.text_at(font_main, 16, x + 14 + (F.s(20) - gw) / 2, ty, icol, glyph)
      F.text_at(font_main, 16, x + 22 + F.s(20), ty, active and F.col('text') or F.col('text', hovered and 235 or 170), item[3])
    else
      F.text_at(font_main, 16, x + (bw - gw) / 2, ty, icol, glyph)
      if hovered then F.tip(item[3]) end
    end
    if clicked then
      if page == 'notes' and item[1] ~= 'notes' then F.note_flush() end
      page = item[1]
    end
    y = y + ih + 3
  end
  if wide then
    local ch = F.s(56)
    local by = wp.y + h - ch - 12
    if by > y + 8 then
      local x = wp.x + pad
      F.round_rect(x, by, bw, ch, F.col('panel'), F.col('text', 16), 12)
      dl:AddCircleFilled(imgui.ImVec2(x + 16, by + F.s(19)), 4, live.online and F.col('accent') or F.col('bad'), 12)
      F.text_at(font_main, 16, x + 28, by + F.s(10), F.col('text'), live.online and 'В игре' or 'Не в игре')
      local sub = live.online and ('сессия ' .. F.fmt_span(F.play_seconds('session'))) or 'ждём сервер'
      F.text_at(font_main, 16, x + 14, by + F.s(31), F.col('text', 130), F.fit_text(font_main, sub, bw - 20))
    end
  end
  F.advance(wp, 1, 1)
end

-- Home

function F.home_hero()
  local w = F.inner_w()
  local p = imgui.GetCursorScreenPos()
  local h = F.s(94)
  local dl = imgui.GetWindowDrawList()
  F.round_rect(p.x, p.y, w, h, F.col('panel'), F.col('accent', 80), 18)
  local r = F.s(28)
  local cx, cy = p.x + F.s(18) + r, p.y + h / 2
  dl:AddCircleFilled(imgui.ImVec2(cx, cy), r + 3, F.col('accent', 50), 40)
  dl:AddCircleFilled(imgui.ImVec2(cx, cy), r, F.col('accent'), 40)
  local letter = live.online and F.utf_first(live.nick):upper() or ''
  if letter == '' or letter == '—' then letter = 'f' end
  local lw = F.text_w(font_title, letter)
  F.text_at(font_title, 22, cx - lw / 2, cy - F.s(12), F.col('ink'), letter)
  local tx = cx + r + F.s(18)
  local right_w = math.min(F.s(260), w * 0.38)
  local name_w = p.x + w - right_w - tx - F.s(16)
  local nick = live.online and live.nick or 'Нет подключения'
  F.text_at(font_title, 22, tx, p.y + F.s(20), F.col('text'), F.fit_text(font_title, nick, name_w))
  local sub
  if live.online then
    local ping = live.ping ~= '—' and (live.ping .. ' мс') or '—'
    sub = 'ID ' .. live.id .. '   ·   пинг ' .. ping .. '   ·   уровень ' .. live.score
  else
    sub = 'Зайди на сервер, и данные появятся здесь'
  end
  F.text_at(font_main, 16, tx, p.y + F.s(52), F.col('text', 150), F.fit_text(font_main, sub, name_w))
  local rx = p.x + w - F.s(18)
  local chip = live.online and 'В игре' or 'Не в игре'
  F.chip(rx - F.chip_w(chip), p.y + F.s(16), chip, live.online and 'on' or 'bad')
  if live.online then
    local srv = F.fit_text(font_main, live.server, right_w)
    F.text_at(font_main, 16, rx - F.text_w(font_main, srv), p.y + F.s(48), F.col('text', 210), srv)
    local ses = 'сессия ' .. F.fmt_span(F.play_seconds('session'))
    F.text_at(font_main, 16, rx - F.text_w(font_main, ses), p.y + F.s(68), F.col('text', 120), ses)
  end
  F.advance(p, w, h)
  imgui.Dummy(imgui.ImVec2(1, 2))
end

function F.draw_home()
  F.home_hero()
  local hp, arm = tonumber(live.health), tonumber(live.armour)
  F.card_begin('Персонаж', nil, 'ICON_FA_USER')
  F.tile_grid('pl', {
    {'ICON_FA_WALLET', 'Наличные', live.money},
    {'ICON_FA_UNIVERSITY', 'Банк', F.fmt_saved('bank')},
    {'ICON_FA_PIGGY_BANK', 'Депозит', F.fmt_saved('depo')},
    {'ICON_FA_HEART', 'Здоровье', live.health, hp and hp / 100},
    {'ICON_FA_SHIELD_ALT', 'Броня', live.armour, arm and arm / 100},
    {'ICON_FA_STAR', 'Розыск', live.wanted},
    {'ICON_FA_CROSSHAIRS', 'Оружие', live.weapon},
    {'ICON_FA_CAR', 'Транспорт', live.veh},
  }, 190)
  F.card_end()
  F.card_begin('Местоположение', nil, 'ICON_FA_MAP_MARKER_ALT')
  F.tile_grid('pos', {
    {'ICON_FA_MAP_MARKER_ALT', 'Район', live.zone},
    {'ICON_FA_LOCATION_ARROW', 'Координаты', live.pos},
    {'ICON_FA_DOOR_OPEN', 'Интерьер', live.interior},
    {'ICON_FA_CLOCK', 'Время в игре', live.clock},
  }, 190)
  F.card_end()
  F.card_begin('Время и сеть', nil, 'ICON_FA_SIGNAL')
  F.tile_grid('net', {
    {'ICON_FA_HOURGLASS_HALF', 'Сессия', F.fmt_span(F.play_seconds('session'))},
    {'ICON_FA_CALENDAR_DAY', 'Сегодня', F.fmt_span(F.play_seconds('day'))},
    {'ICON_FA_HISTORY', 'Всего в игре', F.fmt_span(F.play_seconds('total'))},
    {'ICON_FA_USERS', 'Игроки онлайн', live.players},
    {'ICON_FA_SERVER', 'IP сервера', live.ip},
    {'ICON_FA_TACHOMETER_ALT', 'FPS', tostring(math.floor((fps or 0) + 0.5))},
    {'ICON_FA_ARROW_DOWN', 'Получено', F.fmt_bytes(net.inn)},
    {'ICON_FA_ARROW_UP', 'Отправлено', F.fmt_bytes(net.outn)},
  }, 190)
  F.card_end()
end

-- Scripts

function F.script_row(item, w)
  local h = F.s(58)
  local p = imgui.GetCursorScreenPos()
  local dl = imgui.GetWindowDrawList()
  local ib = F.s(30)
  local x_r = p.x + w - F.s(12)
  local info_x = x_r - ib
  local rel_x = info_x - 4 - ib
  local sw_x = rel_x - F.s(12) - F.s(40)
  local _, hovered = F.hotspot('##row' .. item.path, p.x, p.y, math.max(40, sw_x - p.x - 8), h)
  F.round_rect(p.x, p.y, w, h, hovered and F.col('raised') or F.col('panel'), F.col('text', hovered and 34 or 18), 14)
  local stripe = item.warn and F.col('bad') or (item.loaded and F.col('accent') or F.col('text', 46))
  dl:AddRectFilled(imgui.ImVec2(p.x + 10, p.y + F.s(15)), imgui.ImVec2(p.x + 13, p.y + h - F.s(15)), stripe, 2)
  local status = item.warn and 'проверить' or (item.loaded and 'включен' or 'выключен')
  local tone = item.warn and 'bad' or (item.loaded and 'on' or 'muted')
  local text_end = sw_x - F.s(14)
  if w >= F.s(560) then
    local cw = F.chip_w(status)
    F.chip(sw_x - F.s(14) - cw, p.y + (h - F.s(24)) / 2, status, tone)
    text_end = sw_x - F.s(28) - cw
  end
  local tx = p.x + F.s(26)
  local name = F.fit_text(font_bold, item.name, text_end - tx)
  F.text_at(font_bold, 18, tx, p.y + F.s(8), F.col('text'), name)
  if item.version ~= '' then
    local ver = 'v' .. item.version:gsub('^[vV]', '')
    local vx = tx + F.text_w(font_bold, name) + 8
    if vx + F.text_w(font_main, ver) <= text_end then
      F.text_at(font_main, 16, vx, p.y + F.s(10), F.col('text', 100), ver)
    end
  end
  local sub = item.desc ~= '' and item.desc or (item.author ~= '' and ('автор: ' .. item.author) or item.rel)
  F.text_at(font_main, 16, tx, p.y + F.s(32), F.col('text', 135), F.fit_text(font_main, sub, text_end - tx))
  local sw_hit, sw_hover = F.hotspot('##sw' .. item.path, sw_x, p.y + (h - F.s(22)) / 2, F.s(40), F.s(22))
  F.knob('row' .. item.path, sw_x, p.y + (h - F.s(22)) / 2, item.loaded, sw_hover)
  if sw_hover then F.tip(item.loaded and 'Выключить' or 'Включить') end
  if sw_hit then F.toggle_script(item) end
  local iy = p.y + (h - ib) / 2
  if item.loaded and F.ghost_icon('##rl' .. item.path, rel_x, iy, 'ICON_FA_REDO', 'Перезагрузить') then
    F.queue('reload', {path = item.path})
  end
  if F.ghost_icon('##in' .. item.path, info_x, iy, 'ICON_FA_INFO_CIRCLE', 'Подробнее') then
    local lines = {
      item.rel,
      'Версия: ' .. (item.version ~= '' and item.version or '—'),
      'Автор: ' .. (item.author ~= '' and item.author or '—'),
      'Категория: ' .. (item.category or '—'),
      item.warn and 'В файле есть запуск программ или библиотек. Открой его и проверь сам.' or 'Замечаний по запуску программ нет.',
      'Папка: ' .. item.path,
    }
    modal = {kind = 'script', title = item.name, lines = lines, path = item.path}
  end
  F.advance(p, w, h)
end

function F.draw_scripts_page()
  F.page_head('Скрипты', 'Включение, перезагрузка и сведения о скриптах MoonLoader')
  local on, warn = 0, 0
  for i = 1, #file_list do
    if file_list[i].loaded then on = on + 1 end
    if file_list[i].warn then warn = warn + 1 end
  end
  local p = imgui.GetCursorScreenPos()
  local x = p.x
  x = x + F.chip(x, p.y, 'всего ' .. #file_list, 'muted') + 8
  x = x + F.chip(x, p.y, 'включено ' .. on, 'on') + 8
  if warn > 0 then F.chip(x, p.y, 'проверить ' .. warn, 'bad') end
  F.advance(p, 1, F.s(24))
  imgui.Spacing()
  local fh = imgui.GetFrameHeight()
  imgui.PushItemWidth(math.max(80, F.inner_w() - (fh + 8) * 3))
  imgui.InputTextWithHint('##search', 'Поиск по названию, автору, описанию', ui_search, 80)
  imgui.PopItemWidth()
  imgui.SameLine()
  if F.icon_btn('ICON_FA_SYNC', 'scan', 'Обновить список', true) then need_scan = true end
  imgui.SameLine()
  local last = cfg.last ~= '' and cfg.last or 'нет'
  if F.icon_btn('ICON_FA_REDO', 'last', 'Перезапустить последний: ' .. last) then F.queue('last') end
  imgui.SameLine()
  if F.icon_btn('ICON_FA_FOLDER_OPEN', 'dir', 'Папка скриптов') then F.queue('dir') end
  local w = F.inner_w()
  local seg_w = math.max(F.s(200), math.min(F.s(440), w - F.s(180) - 8))
  local st = F.segment('st', {
    {'Все', 'Все'},
    {'Включен', 'Включены'},
    {'Выключен', 'Выключены'},
    {'Проверить', 'Проверить'},
  }, filter_st, seg_w)
  if st then filter_st = st end
  F.same_if_fit(F.s(180))
  local tag = F.faico('ICON_FA_TAG')
  if F.button((tag ~= '' and (tag .. '  ') or '') .. filter_cat .. '##cat', 180, 0) then F.cycle_cat() end
  if imgui.IsItemHovered() then F.tip('Категория. Нажми, чтобы сменить') end
  imgui.Spacing()
  local shown = 0
  for i = 1, #file_list do
    local item = file_list[i]
    if F.script_visible(item) then
      shown = shown + 1
      F.script_row(item, F.inner_w())
    end
  end
  if shown == 0 then
    if #file_list == 0 then F.empty('ICON_FA_CODE', 'Список пуст', 'Нажми «Обновить список»')
    else F.empty('ICON_FA_SEARCH', 'Ничего не найдено', 'Попробуй другой запрос или фильтр') end
  end
end

-- Binds and accent

function F.accent_clean(text)
  local s = F.trim(text or ''):gsub('[\r\n]', '')
  s = s:gsub('%[', ''):gsub('%]', '')
  return F.utf_cut(s, 40)
end

function F.accent_inner()
  return F.accent_clean(cfg.accent)
end

function F.accent_head()
  local inner = F.accent_inner()
  if inner == '' then inner = 'Акцент' end
  return '[' .. inner .. ']: '
end

function F.draw_accent()
  F.card_begin('Акцент', 'Приставка к обычным сообщениям в чате. Команды с / не меняются', 'ICON_FA_COMMENT_DOTS')
  if F.switch('accent', 'Добавлять акцент', cfg.accent_on ~= 0, F.accent_inner() == '' and 'Поле пустое, приставка не добавляется' or nil) then
    cfg.accent_on = cfg.accent_on ~= 0 and 0 or 1
    dirty = true
  end
  imgui.PushItemWidth(F.inner_w())
  F.ensure_paste_cb()
  local cb = F.paste_cb and F.accent_hot
  if cb then F.suppress_bind_paste() end
  local changed
  if cb then
    changed = imgui.InputTextWithHint('##accent', 'Например: Немецкий акцент', ui_fav, 180, imgui.InputTextFlags.CallbackAlways, F.paste_cb, nil)
  else
    changed = imgui.InputTextWithHint('##accent', 'Например: Немецкий акцент', ui_fav, 180)
  end
  if cb then F.restore_bind_paste() end
  F.accent_hot = imgui.IsItemActive()
  imgui.PopItemWidth()
  if changed then
    local raw = F.buf_get(ui_fav)
    local inner = F.accent_clean(raw)
    cfg.accent = inner
    if inner ~= raw then F.buf_set(ui_fav, inner, 180) end
    dirty = true
  end
  local p = imgui.GetCursorScreenPos()
  local head = F.accent_head()
  local live_on = cfg.accent_on ~= 0 and F.accent_inner() ~= ''
  F.text_at(font_main, 16, p.x, p.y, F.col('text', 120), 'В чате:')
  local x = p.x + F.text_w(font_main, 'В чате:') + 10
  F.text_at(font_main, 16, x, p.y, live_on and F.col('accent_hi') or F.col('text', 90), head)
  x = x + F.text_w(font_main, head)
  F.text_at(font_main, 16, x, p.y, F.col('text', 220), 'Привет!')
  F.advance(p, 1, F.s(18))
  F.card_end()
end

function F.bind_clear()
  F.bind_edit = nil
  F.buf_set(ui_bind, '', 240)
  bind_vk = 0
  F.bind_mods = 0
end

-- The form at the top of the page edits the bind in place.
function F.bind_open(b)
  capture = false
  capture_what = 'menu'
  F.bind_edit = b
  bind_vk, bind_kind = b.vk, b.kind
  F.bind_mods = b.mods or 0
  F.buf_set(ui_bind, b.arg, 240)
end

function F.bind_add()
  local editing = F.bind_edit
  local why = F.bind_conflict(bind_vk, F.bind_mods, editing)
  local arg = F.trim(F.buf_get(ui_bind))
  if why then
    F.notify(why)
  elseif arg == '' then
    F.notify('Заполни действие')
  elseif bind_kind == 'page' and not F.page_ok(arg) then
    F.notify('Нет такого раздела: ' .. arg)
  elseif bind_kind == 'script' and not doesFileExist(F.wd() .. '\\' .. arg) then
    F.notify('Файл не найден: ' .. arg)
  else
    local b = editing or {}
    b.vk, b.kind, b.arg, b.mods = bind_vk, bind_kind, arg, F.bind_mods or 0
    if not editing then binds[#binds + 1] = b end
    F.save_binds()
    F.log_line('Бинд ' .. F.chord_name(bind_vk, F.bind_mods) .. ' -> ' .. bind_kind)
    F.notify(editing and 'Бинд изменён' or 'Бинд добавлен', true)
    F.bind_clear()
  end
end

function F.bind_arg_title(b)
  if b.kind == 'page' then
    local t = F.nav_title(b.arg)
    if t ~= '' then return t end
  end
  return b.arg
end

function F.draw_binds()
  F.page_head('Бинды', 'Клавиша или сочетание: открыть раздел, отправить команду или запустить скрипт')
  local editing = F.bind_edit
  F.card_begin(editing and 'Изменить бинд' or 'Новый бинд', nil, editing and 'ICON_FA_PEN' or 'ICON_FA_PLUS_CIRCLE')
  local waiting = capture and capture_what == 'bind'
  local p = imgui.GetCursorScreenPos()
  local fh = imgui.GetFrameHeight()
  local cap_y = p.y + (fh - F.s(28)) / 2
  local cw
  if waiting then
    local held = F.chord_name(0, F.mods_mask())
    cw = F.keycap(p.x, cap_y, held ~= 'нет' and (held .. ' + …') or 'Нажми клавишу…', true)
  else
    cw = F.chord_caps(p.x, cap_y, bind_vk, F.bind_mods, bind_vk ~= 0)
  end
  F.advance(p, cw, fh)
  imgui.SameLine(0, 12)
  if F.button((waiting and 'Отмена' or 'Назначить клавишу') .. '##bcap', 180, 0, waiting and 'primary' or nil) then
    if waiting then
      capture = false
      capture_what = 'menu'
    else
      capture = true
      capture_what = 'bind'
      F.cap_peak, F.cap_last = 0, 0
    end
  end
  if waiting then F.hint('Удерживай Ctrl, Alt, Shift, Win или Fn и нажми клавишу. Esc сбрасывает.') end
  local kind = F.segment('bk', {{'page', 'Раздел'}, {'chat', 'Команда'}, {'say', 'Сообщение'}, {'script', 'Скрипт'}}, bind_kind, math.min(F.s(480), F.inner_w()))
  if kind then bind_kind = kind end
  local hint_arg = bind_kind == 'page' and 'Раздел: выбери ниже' or bind_kind == 'chat' and '/time'
    or bind_kind == 'say' and 'Текст в чат, можно с интеграциями' or 'папка\\скрипт.lua'
  imgui.PushItemWidth(math.max(80, F.inner_w() - fh - F.s(140) - 16 - (editing and (fh + 8) or 0)))
  F.ensure_paste_cb()
  local bind_paste = F.paste_cb and F.bind_hot and not F.accent_hot
  if bind_paste then F.suppress_bind_paste() end
  local enter
  if bind_paste then
    enter = imgui.InputTextWithHint('##bindarg', hint_arg, ui_bind, 240, imgui.InputTextFlags.CallbackAlways + imgui.InputTextFlags.EnterReturnsTrue, F.paste_cb, nil)
  else
    enter = imgui.InputTextWithHint('##bindarg', hint_arg, ui_bind, 240, imgui.InputTextFlags.EnterReturnsTrue)
  end
  if bind_paste then F.restore_bind_paste() end
  F.bind_hot = imgui.IsItemActive()
  imgui.PopItemWidth()
  local bind_form = F.int_form(F.buf_get(ui_bind))
  if bind_form then bind_kind = bind_form == 'cmd' and 'chat' or 'say' end
  imgui.SameLine()
  if F.icon_btn('ICON_FA_PASTE', 'bpaste', 'Вставить из буфера') then F.paste_bind_buf() end
  imgui.SameLine()
  if F.accent_button((editing and 'Сохранить' or 'Добавить') .. '##badd', 140, 0) or enter then F.bind_add() end
  if editing then
    imgui.SameLine()
    if F.icon_btn('ICON_FA_TIMES', 'bcancel', 'Отменить изменения') then F.bind_clear() end
  end
  if bind_kind == 'page' then
    local list = {}
    for i = 1, #NAV do list[#list + 1] = {NAV[i][1], NAV[i][3]} end
    local pick = F.pill_row('##bpg', list, F.trim(F.buf_get(ui_bind)))
    if pick then F.buf_set(ui_bind, pick, 240) end
  elseif bind_kind == 'chat' or bind_kind == 'say' then
    if F.button((F.faico('ICON_FA_LINK') ~= '' and (F.faico('ICON_FA_LINK') .. '  ') or '') .. 'Вставить интеграцию##bint', 230, 0) then
      F.int_pick = 'bind'
      F.chat_tab = 'lib'
      page = 'chat'
    end
    F.int_preview(F.buf_get(ui_bind))
    if #favs > 0 then
      local list = {}
      for i = 1, #favs do
        local t = favs[i].text
        if (bind_kind == 'chat') == (t:sub(1, 1) == '/') then
          list[#list + 1] = {t, F.fit_text(font_main, F.fav_title(favs[i]), F.s(220))}
        end
      end
      local pick = F.pill_row('##bfv', list, F.trim(F.buf_get(ui_bind)))
      if pick then F.buf_set(ui_bind, pick, 240) end
    end
  elseif bind_kind == 'script' then
    F.hint('Путь от папки moonloader. Список файлов есть в разделе «Скрипты».')
  end
  local why = bind_vk ~= 0 and F.bind_conflict(bind_vk, F.bind_mods, F.bind_edit) or nil
  if why then F.hint_bad(why) end
  F.card_end()

  F.card_begin('Мои бинды' .. (#binds > 0 and ('  ·  ' .. #binds) or ''), 'Срабатывают, когда меню закрыто и чат не открыт', 'ICON_FA_BOLT')
  if #binds == 0 then
    F.empty('ICON_FA_KEYBOARD', 'Биндов нет', 'Назначь клавишу и действие выше')
  end
  local del, run, open
  for i = 1, #binds do
    local b = binds[i]
    local rp = imgui.GetCursorScreenPos()
    local w = F.inner_w()
    local h = F.s(46)
    local ib = F.s(30)
    local clicked, hovered = F.hotspot('##brow' .. i, rp.x, rp.y, math.max(1, w - ib * 3 - 24), h)
    if clicked then open = b end
    F.round_rect(rp.x, rp.y, w, h, (hovered or F.bind_edit == b) and F.col('raised') or F.col('side', 140),
      F.bind_edit == b and F.col('accent', 130) or nil, 12)
    local cx = rp.x + F.s(10)
    local kw = F.chord_caps(cx, rp.y + (h - F.s(28)) / 2, b.vk, b.mods)
    local chx = cx + kw + F.s(14)
    local chw = F.chip(chx, rp.y + (h - F.s(24)) / 2, F.bind_kind_name(b.kind), b.kind == 'chat' and 'on' or 'muted')
    local ax = chx + chw + F.s(12)
    local bx = rp.x + w - F.s(8) - ib
    F.text_at(font_main, 16, ax, rp.y + (h - F.s(16)) / 2 - 1, F.col('text', 225), F.fit_text(font_main, F.int_human(F.bind_arg_title(b)), bx - (ib + 4) * 2 - 12 - ax))
    if F.ghost_icon('##bdel' .. i, bx, rp.y + (h - ib) / 2, 'ICON_FA_TRASH', 'Удалить', true) then del = i end
    if F.ghost_icon('##brun' .. i, bx - ib - 4, rp.y + (h - ib) / 2, 'ICON_FA_PLAY', 'Выполнить сейчас') then run = b end
    if F.ghost_icon('##bedit' .. i, bx - (ib + 4) * 2, rp.y + (h - ib) / 2, 'ICON_FA_PEN', 'Изменить') then open = b end
    F.advance(rp, w, h)
  end
  F.card_end()
  if open then
    F.bind_open(open)
    imgui.SetScrollY(0)
  end
  if del then
    if F.bind_edit == binds[del] then F.bind_clear() end
    table.remove(binds, del)
    F.save_binds()
    F.notify('Бинд удалён', true)
  end
  if run then F.fire_bind(run) end
end

-- Hotkeys

function F.key_row(id, title, sub, vk, what)
  local w = F.inner_w()
  local p = imgui.GetCursorScreenPos()
  local h = F.s(52)
  local waiting = capture and capture_what == what
  local bw = F.s(110)
  local bx = p.x + w - bw
  local by = p.y + (h - imgui.GetFrameHeight()) / 2
  imgui.SetCursorScreenPos(imgui.ImVec2(bx, by))
  local clear = F.button('Убрать##' .. id, 110, 0)
  imgui.SetCursorScreenPos(imgui.ImVec2(bx - 8 - bw, by))
  local set
  if waiting then set = F.accent_button('Отмена##set' .. id, 110, 0)
  else set = F.button('Назначить##set' .. id, 110, 0) end
  local label = waiting and 'нажми клавишу' or F.key_name(vk)
  local kw = F.keycap_w(label)
  local kx = bx - 8 - bw - 14 - kw
  F.keycap(kx, p.y + (h - F.s(28)) / 2, label, waiting or vk ~= 0)
  F.text_at(font_main, 16, p.x, p.y + F.s(6), F.col('text'), F.fit_text(font_main, title, kx - p.x - 12))
  F.text_at(font_main, 16, p.x, p.y + F.s(28), F.col('text', 130), F.fit_text(font_main, sub, kx - p.x - 12))
  F.advance(p, w, h)
  return set, clear, waiting
end

function F.draw_hotkeys()
  F.page_head('Клавиши', 'Открытие меню, скрытие интерфейса и управление')
  F.card_begin('Горячие клавиши', nil, 'ICON_FA_KEYBOARD')
  local set, clear, waiting = F.key_row('menu', 'Открыть меню', 'То же, что команда /fhelp', cfg.key, 'menu')
  if set then
    if waiting then capture = false
    else
      capture = true
      capture_what = 'menu'
    end
  end
  if clear then
    cfg.key = 0
    dirty = true
  end
  F.divider()
  set, clear, waiting = F.key_row('hide', 'Скрыть интерфейс', 'Убирает меню и плашку, второе нажатие возвращает', cfg.hidekey, 'hide')
  if set then
    if waiting then capture = false
    else
      capture = true
      capture_what = 'hide'
    end
  end
  if clear then
    cfg.hidekey = 0
    dirty = true
  end
  if cfg.key ~= 0 and cfg.key == cfg.hidekey then
    F.hint_bad('Одна клавиша на меню и скрытие: скрытие не сработает. Назначь другую.')
  end
  F.divider()
  set, clear, waiting = F.key_row('calc', 'Окошко калькулятора', 'Включает мышь и ввод в окошке, Esc выключает', cfg.calc_key, 'calc')
  if set then
    if waiting then capture = false
    else
      capture = true
      capture_what = 'calc'
    end
  end
  if clear then
    cfg.calc_key = 0
    dirty = true
  end
  F.card_end()
  F.card_begin('Управление', nil, 'ICON_FA_GAMEPAD')
  if F.switch('lock', 'Блокировать управление', cfg.lock == 1, 'Персонаж не двигается, пока меню открыто') then
    cfg.lock = cfg.lock == 1 and 0 or 1
    if ui_lock then ui_lock[0] = cfg.lock == 1 end
    dirty = true
  end
  F.card_end()
  F.card_begin('Команды', nil, 'ICON_FA_TERMINAL')
  local rows = {
    {'/fhelp', 'открыть или закрыть меню'},
    {'/fhelpreload', 'перезагрузить fHelper'},
    {'/fcalc', 'включить ввод в окошке калькулятора'},
    {'/fcalc 2кк*3', 'посчитать прямо в чате'},
    {'Esc', 'закрыть меню или окно подтверждения'},
  }
  for i = 1, #rows do
    local p = imgui.GetCursorScreenPos()
    local kw = F.keycap(p.x, p.y, rows[i][1], false)
    F.text_at(font_main, 16, p.x + kw + F.s(14), p.y + (F.s(28) - F.s(16)) / 2 - 1, F.col('text', 170), rows[i][2])
    F.advance(p, 1, F.s(30))
  end
  F.card_end()
end

-- Income

function F.log_split(line)
  local d, t, text = tostring(line or ''):match('^(%d%d%d%d%-%d%d%-%d%d) (%d%d:%d%d:%d%d)%s+(.*)$')
  if d then return d, t, text end
  t, text = tostring(line or ''):match('^(%d%d:%d%d:%d%d)%s+(.*)$')
  if t then return 'без даты', t, text end
  return 'без даты', '', tostring(line or '')
end

function F.short_stamp(t)
  local y, m, d, hm = tostring(t or ''):match('^(%d+)%-(%d+)%-(%d+) (%d+:%d+)')
  if not y then return tostring(t or '') end
  return d .. '.' .. m .. ' ' .. hm
end

function F.income_paydays(from, to)
  local st = F.pay_state()
  if #st.list == 0 then
    F.card_begin()
    F.empty('ICON_FA_COINS', 'Пейдеев пока нет', 'Когда в чате появится банковский чек, он будет здесь')
    F.card_end()
    return
  end
  local idx, sum, az, best = {}, 0, 0, nil
  for i = #st.list, 1, -1 do
    local r = st.list[i]
    local t = r.t or ''
    if t >= from and t <= to then
      idx[#idx + 1] = i
      sum = sum + (r.total or 0)
      az = az + (r.az or 0)
      if not best or (r.total or 0) > (st.list[best].total or 0) then best = i end
    end
  end
  if #idx == 0 then
    F.card_begin()
    F.empty('ICON_FA_COINS', 'За этот период пейдеев нет', 'Последний был ' .. F.short_stamp(st.list[#st.list].t))
    F.card_end()
    return
  end
  local in_range = false
  for i = 1, #idx do
    if idx[i] == st.pick then in_range = true break end
  end
  if not in_range then st.pick = idx[1] end
  local rec = st.list[st.pick]
  local tiles = {
    {'ICON_FA_COINS', 'Пейдеев: ' .. #idx, F.fmt_money(sum) or '—'},
    {'ICON_FA_CHART_LINE', 'В среднем', F.fmt_money(sum / #idx) or '—'},
    {'ICON_FA_TROPHY', 'Лучший, ' .. F.short_stamp(st.list[best].t), F.fmt_money(st.list[best].total) or '—'},
  }
  if az ~= 0 then
    tiles[#tiles + 1] = {'ICON_FA_GEM', 'AZ за период', (az > 0 and '+' or '') .. tostring(az) .. ' AZ'}
  end
  F.tile_grid('inc', tiles, 200)
  imgui.Spacing()
  if #idx > 1 then
    local shown = math.min(#idx, 30)
    F.card_begin('История', #idx > shown and ('Выбери пейдей. Показаны последние ' .. shown .. ' из ' .. #idx)
      or 'Выбери пейдей, чтобы увидеть чек', 'ICON_FA_HISTORY')
    local list = {}
    for k = 1, shown do
      local r = st.list[idx[k]]
      list[#list + 1] = {idx[k], F.short_stamp(r.t) .. '  ·  ' .. (F.fmt_money(r.total) or '')}
    end
    local pick = F.pill_row('##pd', list, st.pick)
    if pick then st.pick = pick end
    F.card_end()
  end
  F.card_begin('Чек от ' .. F.short_stamp(rec.t), nil, 'ICON_FA_RECEIPT')
  if #rec.items == 0 then
    F.hint('В чеке не было строк с суммой.')
  end
  for i = 1, #rec.items do
    local it = rec.items[i]
    local money, col
    if it.kind == 'az' then
      money = (it.amount > 0 and '+' or '') .. tostring(it.amount) .. ' AZ'
      col = F.col('accent_hi')
    else
      money = F.fmt_money(it.amount) or '—'
      if (it.kind == 'delta' or it.kind == 'extra') and it.amount > 0 then money = '+' .. money end
      col = it.amount < 0 and F.col('bad') or F.col('text')
    end
    local p = imgui.GetCursorScreenPos()
    local w = F.inner_w()
    local h = F.s(32)
    if i % 2 == 0 then F.round_rect(p.x - 6, p.y, w + 12, h, F.col('side', 90), nil, 8) end
    local mw = F.text_w(font_main, money)
    F.text_at(font_main, 16, p.x, p.y + (h - F.s(16)) / 2 - 1, F.col('text', 190), F.fit_text(font_main, it.reason, w - mw - 20))
    F.text_at(font_main, 16, p.x + w - mw, p.y + (h - F.s(16)) / 2 - 1, col, money)
    F.advance(p, w, h - 6)
  end
  F.divider()
  local p = imgui.GetCursorScreenPos()
  local w = F.inner_w()
  local total = F.fmt_money(rec.total) or '—'
  F.text_at(font_bold, 18, p.x, p.y, F.col('text'), 'Итого')
  F.text_at(font_bold, 18, p.x + w - F.text_w(font_bold, total), p.y, F.col('accent_hi'), total)
  F.advance(p, w, F.s(22))
  F.card_end()
end

-- Log

function F.draw_logs_page()
  F.page_head('Журнал', 'Что делал fHelper: запуски, команды, пейдеи')
  if F.icon_btn('ICON_FA_TRASH', 'logclr', 'Очистить журнал') then
    F.ask('Очистить журнал полностью?', 'Очистить', 'clear_log')
  end
  imgui.SameLine()
  if F.icon_btn('ICON_FA_FOLDER_OPEN', 'logopen', 'Открыть файл журнала') then F.queue('log') end
  local days, seen = {}, {}
  for i = #logs, 1, -1 do
    local d = F.log_split(logs[i])
    if not seen[d] then
      seen[d] = true
      days[#days + 1] = d
    end
  end
  if F.log_pick and not seen[F.log_pick] then F.log_pick = nil end
  local pick = F.log_pick or days[1]
  if #days > 0 then
    local list = {}
    for i = 1, math.min(#days, 14) do
      local d = days[i]
      local label = d == 'без даты' and 'раньше' or (d:sub(9, 10) .. '.' .. d:sub(6, 7))
      list[#list + 1] = {d, label}
    end
    imgui.SameLine(0, 12)
    local hit = F.pill_row('##day', list, pick)
    if hit then F.log_pick = hit end
  end
  imgui.Spacing()
  local log_h = imgui.GetContentRegionAvail().y
  if log_h < 140 then log_h = 140 end
  local lp = imgui.GetCursorScreenPos()
  F.round_rect(lp.x, lp.y, imgui.GetContentRegionAvail().x, log_h, F.col('panel'), F.col('text', 20), 16)
  imgui.PushStyleColor(imgui.Col.ChildBg, F.cvec('panel', 0))
  imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(18, 14))
  imgui.BeginChild('##log', imgui.ImVec2(0, log_h), false, imgui.WindowFlags.AlwaysUseWindowPadding)
  local any = false
  for i = #logs, 1, -1 do
    local d, t, text = F.log_split(logs[i])
    if d == pick then
      any = true
      if t ~= '' then
        imgui.TextColored(F.cvec('text', 0.4), t:sub(1, 5))
        imgui.SameLine(0, 14)
      end
      imgui.PushTextWrapPos(0)
      imgui.TextUnformatted(text)
      imgui.PopTextWrapPos()
    end
  end
  if #logs == 0 then F.hint('Журнал пуст.')
  elseif not any then F.hint('За этот день пусто.') end
  imgui.EndChild()
  imgui.PopStyleVar()
  imgui.PopStyleColor()
end

-- Screen

function F.mem()
  if F._mem_try then return F._mem end
  F._mem_try = true
  local ok, lib = pcall(require, 'memory')
  if ok and type(lib) == 'table' then F._mem = lib end
  return F._mem
end

function F.write_limiter(v)
  local mem = F.mem()
  if mem then
    if mem.setuint8 then
      pcall(mem.setuint8, 0xBA6794, v)
    elseif mem.write then
      pcall(mem.write, 0xBA6794, v, 1, true)
    end
  end
  F._lim = v
end

function F.apply_limiter(force)
  if cfg.fps_free == 1 then
    if force or F._lim ~= 0 then
      if not F.mem() and not F._mem_told then
        F._mem_told = true
        F.notify('Ограничитель кадров недоступен')
      end
      F.write_limiter(0)
    end
  elseif F._lim == 0 then
    F.write_limiter(1)
  end
end

function F.draw_screen()
  F.page_head('Экран', 'Плашка с FPS и трафиком, время, графика')
  F.card_begin('Плашка', 'Её можно перетащить мышью, пока меню открыто', 'ICON_FA_TACHOMETER_ALT')
  if F.switch('hfps', 'FPS', cfg.hud_fps == 1) then
    cfg.hud_fps = cfg.hud_fps == 1 and 0 or 1
    dirty = true
  end
  if F.switch('hping', 'Пинг', cfg.hud_ping == 1) then
    cfg.hud_ping = cfg.hud_ping == 1 and 0 or 1
    dirty = true
  end
  if F.switch('hnet', 'Трафик', cfg.hud_net == 1) then
    cfg.hud_net = cfg.hud_net == 1 and 0 or 1
    dirty = true
  end
  F.divider()
  if F.slider_row('hudscale', 'Размер', ui_hudscale, 60, 200, '%.0f%%') then
    cfg.hud_scale = ui_hudscale[0] / 100
    if cfg.hud_scale < 0.6 then cfg.hud_scale = 0.6 end
    if cfg.hud_scale > 2 then cfg.hud_scale = 2 end
    dirty = true
  end
  imgui.TextUnformatted('Место на экране')
  local place = F.segment('hplace', {
    {0, 'Слева сверху'},
    {1, 'Справа сверху'},
    {2, 'Слева снизу'},
    {3, 'Справа снизу'},
    {4, 'Своё'},
  }, cfg.hud_place)
  if place then
    cfg.hud_place = place
    net.force = true
    dirty = true
  end
  if cfg.hud_place == 4 then
    if F.slider_row('hudx', 'По горизонтали', ui_hudx, 0, 100, '%.0f%%') then
      cfg.hud_x = ui_hudx[0]
      net.force = true
      dirty = true
    end
    if F.slider_row('hudy', 'По вертикали', ui_hudy, 0, 100, '%.0f%%') then
      cfg.hud_y = ui_hudy[0]
      net.force = true
      dirty = true
    end
  end
  F.card_end()
  F.time_card()
  F.card_begin('Графика', nil, 'ICON_FA_DESKTOP')
  if F.switch('drawon', 'Своя дальность прорисовки', cfg.draw_on == 1) then
    cfg.draw_on = cfg.draw_on == 1 and 0 or 1
    if ui_drawon then ui_drawon[0] = cfg.draw_on == 1 end
    dirty = true
  end
  if cfg.draw_on == 1 then
    if F.slider_row('draw', 'Дальность', ui_draw, 300, 1500, '%.0f') then
      cfg.draw = ui_draw[0]
      if cfg.draw < 300 then cfg.draw = 300 end
      if cfg.draw > 1500 then cfg.draw = 1500 end
      dirty = true
    end
  end
  if F.switch('fpsfree', 'Снять ограничитель кадров', cfg.fps_free == 1, 'Убирает предел FPS из настроек игры') then
    cfg.fps_free = cfg.fps_free == 1 and 0 or 1
    if ui_fpsfree then ui_fpsfree[0] = cfg.fps_free == 1 end
    dirty = true
    F.apply_limiter(true)
  end
  imgui.Spacing()
  local undo = F.faico('ICON_FA_UNDO')
  if F.button((undo ~= '' and (undo .. '  ') or '') .. 'Вернуть как в игре##drawback', 220, 0) then
    cfg.draw_on = 0
    cfg.fps_free = 0
    if ui_drawon then ui_drawon[0] = false end
    if ui_fpsfree then ui_fpsfree[0] = false end
    dirty = true
    F.write_limiter(1)
  end
  F.card_end()
end

-- Server time

F.WDAYS = {'вс', 'пн', 'вт', 'ср', 'чт', 'пт', 'сб'}
F.MONTHS = {
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
}
F.TIME_MSK = 3 * 3600

-- /time shows the server's own clock, it also corrects a wrong clock on the PC.
function F.time_sync(text)
  if not text or text == '' then return end
  local raw = F.game_text(text):gsub('{%x%x%x%x%x%x}', '')
  local h, mi, s = raw:match('екущее время:%s*(%d+):(%d+):(%d+)')
  local d, mo, y = raw:match('егодняшняя дата:%s*(%d+)[:%.](%d+)[:%.](%d+)')
  if not h or not d then return end
  local stamp = os.time({
    year = tonumber(y), month = tonumber(mo), day = tonumber(d),
    hour = tonumber(h), min = tonumber(mi), sec = tonumber(s),
  })
  if stamp then F.time_shift = stamp - os.time() end
end

function F.time_wall(now)
  local mode = cfg.time_mode
  if mode == 1 then return os.date('*t', now) end
  if mode == 2 then return os.date('!*t', now + math.floor(cfg.time_utc) * 3600) end
  if F.time_shift then return os.date('*t', now + F.time_shift) end
  return os.date('!*t', now + F.TIME_MSK)
end

function F.time_label()
  local mode = cfg.time_mode
  if mode == 1 then return 'ПК' end
  if mode == 2 and cfg.time_utc ~= 3 then return string.format('UTC%+d', math.floor(cfg.time_utc)) end
  return 'МСК'
end

function F.time_date_text(t)
  local fmt = cfg.time_fmt
  if fmt == 1 then return string.format('%02d.%02d', t.day, t.month) end
  if fmt == 2 then return t.day .. ' ' .. F.MONTHS[t.month] end
  if fmt == 3 then return string.format('%04d-%02d-%02d', t.year, t.month, t.day) end
  return string.format('%02d.%02d.%04d', t.day, t.month, t.year)
end

function F.time_clock_text(t)
  local hour, tail = t.hour, ''
  if cfg.time_h12 == 1 then
    tail = hour < 12 and ' AM' or ' PM'
    hour = hour % 12
    if hour == 0 then hour = 12 end
  end
  if cfg.time_sec == 1 then return string.format('%02d:%02d:%02d', hour, t.min, t.sec) .. tail end
  return string.format('%02d:%02d', hour, t.min) .. tail
end

function F.time_text()
  local now = os.time()
  if F.time_cache_at == now then return F.time_cache end
  local t = F.time_wall(now)
  local parts = {}
  if cfg.time_date == 1 then parts[#parts + 1] = F.time_date_text(t) end
  if cfg.time_wday == 1 then parts[#parts + 1] = F.WDAYS[t.wday] end
  if cfg.time_clock == 1 then parts[#parts + 1] = F.time_clock_text(t) end
  if cfg.time_zone == 1 and #parts > 0 then parts[#parts + 1] = F.time_label() end
  F.time_cache_at, F.time_cache = now, table.concat(parts, '   ')
  return F.time_cache
end

function F.time_touch()
  F.time_cache_at = nil
  dirty = true
end

function F.time_on()
  if hidden or cfg.time_on ~= 1 then return false end
  if cfg.time_clock ~= 1 and cfg.time_date ~= 1 and cfg.time_wday ~= 1 then return false end
  local ok, pause = pcall(isPauseMenuActive)
  return not (ok and pause)
end

function F.draw_time()
  local io = imgui.GetIO()
  local sw, sh = io.DisplaySize.x, io.DisplaySize.y
  if sw < 100 then sw = 1366 end
  if sh < 100 then sh = 768 end
  local text = F.time_text()
  if text == '' then return end
  local ts = tonumber(cfg.time_scale) or 1
  F.use_font(font_main)
  local w = F.text_w(font_main, text) * ts + 28 * ts
  local h = 32 * ts
  local max_x, max_y = math.max(0, sw - w), math.max(0, sh - h)
  local x, y = max_x / 2, max_y - 10
  if cfg.time_place == 1 then
    x, y = cfg.time_x / 100 * max_x, cfg.time_y / 100 * max_y
  end
  local WF = imgui.WindowFlags
  local flags = WF.NoTitleBar + WF.NoResize + WF.NoScrollbar + WF.NoScrollWithMouse + WF.NoCollapse
    + WF.NoSavedSettings + WF.NoFocusOnAppearing + WF.NoBringToFrontOnFocus + WF.NoNavInputs
    + WF.NoNavFocus + WF.NoMove + (WF.NoBackground or 0)
  if not show then flags = flags + WF.NoMouseInputs end
  imgui.SetNextWindowPos(imgui.ImVec2(x, y), imgui.Cond.Always)
  imgui.SetNextWindowSize(imgui.ImVec2(w, h), imgui.Cond.Always)
  imgui.PushStyleColor(imgui.Col.WindowBg, F.vec4(0, 0, 0, 0))
  imgui.PushStyleColor(imgui.Col.Border, F.vec4(0, 0, 0, 0))
  imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0)
  imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
  imgui.Begin('fhelp-time', nil, flags)
  local rad = math.max(8, 11 * ts)
  F.round_rect(x, y, w, h, F.col('panel', 236), F.col('text', 34), rad)
  F.text_at(font_main, 16, x + 14 * ts, y + 7 * ts, F.col('accent_hi'), text, nil, ts)
  if show then
    imgui.SetCursorScreenPos(imgui.ImVec2(x, y))
    imgui.InvisibleButton('##timedrag', imgui.ImVec2(w, h))
    if imgui.IsItemHovered() then
      F.round_rect(x, y, w, h, F.col('accent', 0), F.col('accent', 160), rad)
      F.tip('Перетащи плашку мышью')
    end
    if imgui.IsItemActive() and imgui.IsMouseDragging(0) then
      local md = imgui.GetIO().MouseDelta
      local nx = math.max(0, math.min(max_x, x + md.x))
      local ny = math.max(0, math.min(max_y, y + md.y))
      cfg.time_place = 1
      cfg.time_x = max_x > 0 and nx / max_x * 100 or 0
      cfg.time_y = max_y > 0 and ny / max_y * 100 or 0
      ui.time_x[0], ui.time_y[0] = cfg.time_x, cfg.time_y
      dirty = true
    end
  end
  imgui.End()
  F.done_font(font_main)
  imgui.PopStyleVar(2)
  imgui.PopStyleColor(2)
end

function F.time_flag(id, label, key, sub)
  if F.switch(id, label, cfg[key] == 1, sub) then
    cfg[key] = cfg[key] == 1 and 0 or 1
    F.time_touch()
  end
end

function F.time_pick(id, label, items, key)
  imgui.TextUnformatted(label)
  local v = F.segment(id, items, cfg[key])
  if v then
    cfg[key] = v
    F.time_touch()
  end
  imgui.Spacing()
end

function F.time_card()
  F.card_begin('Время', 'Плашку можно перетащить мышью, пока меню открыто', 'ICON_FA_CLOCK')
  F.time_flag('timeon', 'Плашка с датой и временем', 'time_on')
  if cfg.time_on ~= 1 then
    F.card_end()
    return
  end
  F.hint('Сейчас: ' .. F.time_text())
  F.divider()
  F.time_pick('tmode', 'Какое время показывать', {{0, 'Серверное'}, {1, 'На моём ПК'}, {2, 'Свой пояс'}}, 'time_mode')
  if cfg.time_mode == 0 then
    F.hint(F.time_shift and 'Сверено с сервером по /time.' or 'По Москве. Открой /time, и fHelper сверит часы с сервером.')
  elseif cfg.time_mode == 2 and F.slider_row('timeutc', 'Пояс UTC', ui.time_utc, -12, 14, '%+.0f') then
    cfg.time_utc = math.floor(ui.time_utc[0] + 0.5)
    F.time_touch()
  end
  F.time_flag('tclock', 'Время', 'time_clock')
  F.time_flag('tsec', 'Секунды', 'time_sec')
  F.time_flag('tdate', 'Дата', 'time_date')
  F.time_flag('twday', 'День недели', 'time_wday')
  F.time_flag('tzone', 'Часовой пояс', 'time_zone', 'МСК, UTC+5 и так далее')
  F.divider()
  F.time_pick('th12', 'Формат времени', {{0, '24 часа'}, {1, '12 часов'}}, 'time_h12')
  F.time_pick('tfmt', 'Формат даты', {{0, '07.11.2026'}, {1, '07.11'}, {2, '7 ноября'}, {3, '2026-11-07'}}, 'time_fmt')
  if F.slider_row('timescale', 'Размер', ui.time_scale, 60, 200, '%.0f%%') then
    cfg.time_scale = math.max(0.6, math.min(2, ui.time_scale[0] / 100))
    dirty = true
  end
  F.time_pick('tplace', 'Место на экране', {{0, 'Стандартное: внизу по центру'}, {1, 'Своё'}}, 'time_place')
  if cfg.time_place == 1 then
    if F.slider_row('timex', 'По горизонтали', ui.time_x, 0, 100, '%.0f%%') then
      cfg.time_x = ui.time_x[0]
      dirty = true
    end
    if F.slider_row('timey', 'По вертикали', ui.time_y, 0, 100, '%.0f%%') then
      cfg.time_y = ui.time_y[0]
      dirty = true
    end
  end
  F.card_end()
end

-- Car scanner

-- Slot blocks of the inventory window, BLOCK_TYPE in frontend.zip.
F.CAR_TRUNK = 8
F.CAR_SECTIONS = {
  {'trunk', 'Багажник', 'ICON_FA_BOX_OPEN', {8}},
  {'tech', 'Технические модификации', 'ICON_FA_WRENCH', {23}},
  {'look', 'Визуальные модификации', 'ICON_FA_PAINT_BRUSH', {12}},
  {'slots', 'Рамка, турбо и номер', 'ICON_FA_ID_CARD', {18, 19, 36}},
}
F.CAR_BLOCK = {[8] = true, [12] = true, [18] = true, [19] = true, [23] = true, [36] = true}
-- Bits of the "buttons" field: tabs the server allows right now.
F.CAR_BIT_CAR, F.CAR_BIT_TRUNK = 2, 16
F.CAR_LOG = 40
F.cars = {}
F.car_plates = {}
F.inv = {blocks = {}, buttons = 0, at = 0}

-- MoonLoader's own JSON is not used: the game's text may be cp1251 and it must not fail on that.
F.JSON_ESC = {b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'}

function F.json_string(s, p)
  if s:sub(p, p) ~= '"' then error('json: нет строки') end
  local out, i = {}, p + 1
  while true do
    local q = s:find('["\\]', i)
    if not q then error('json: строка не закрыта') end
    out[#out + 1] = s:sub(i, q - 1)
    if s:sub(q, q) == '"' then return table.concat(out), q + 1 end
    local e = s:sub(q + 1, q + 1)
    if e == 'u' then
      local cp = tonumber(s:sub(q + 2, q + 5), 16) or 63
      if cp < 128 then out[#out + 1] = string.char(cp)
      elseif cp < 2048 then out[#out + 1] = string.char(192 + math.floor(cp / 64), 128 + cp % 64)
      else
        out[#out + 1] = string.char(224 + math.floor(cp / 4096), 128 + math.floor(cp / 64) % 64, 128 + cp % 64)
      end
      i = q + 6
    else
      out[#out + 1] = F.JSON_ESC[e] or e
      i = q + 2
    end
  end
end

function F.json_list(s, p)
  local out, n = {}, 0
  p = s:find('%S', p)
  if s:sub(p, p) == ']' then return out, p + 1 end
  while true do
    local v
    v, p = F.json_value(s, p)
    n = n + 1
    out[n] = v
    p = s:find('%S', p)
    local c = s:sub(p, p)
    if c == ']' then return out, p + 1 end
    if c ~= ',' then error('json: ошибка в списке') end
    p = p + 1
  end
end

function F.json_object(s, p)
  local out = {}
  p = s:find('%S', p)
  if s:sub(p, p) == '}' then return out, p + 1 end
  while true do
    local k, v
    k, p = F.json_string(s, s:find('%S', p))
    p = s:find('%S', p)
    if s:sub(p, p) ~= ':' then error('json: нет двоеточия') end
    v, p = F.json_value(s, p + 1)
    out[k] = v
    p = s:find('%S', p)
    local c = s:sub(p, p)
    if c == '}' then return out, p + 1 end
    if c ~= ',' then error('json: ошибка в объекте') end
    p = p + 1
  end
end

function F.json_value(s, p)
  p = s:find('%S', p)
  if not p then error('json: конец текста') end
  local c = s:sub(p, p)
  if c == '{' then return F.json_object(s, p + 1) end
  if c == '[' then return F.json_list(s, p + 1) end
  if c == '"' then return F.json_string(s, p) end
  if s:sub(p, p + 3) == 'true' then return true, p + 4 end
  if s:sub(p, p + 3) == 'null' then return nil, p + 4 end
  if s:sub(p, p + 4) == 'false' then return false, p + 5 end
  local num = s:match('^-?[%d%.eE%+%-]+', p)
  if not num then error('json: неизвестное значение') end
  return tonumber(num), p + #num
end

function F.car_new_inv()
  F.inv = {blocks = {}, buttons = 0, at = 0}
end

-- First inventory packets of a session, to see the real format when something does not match.
function F.car_dump(body)
  F._car_dumps = (F._car_dumps or 0) + 1
  if F._car_dumps > 30 then return end
  local f = io.open(F.cfg_dir() .. '\\fhelp_cars_debug.txt', F._car_dumps == 1 and 'w' or 'a')
  if not f then return end
  f:write(body:sub(1, 1500), '\n')
  f:close()
end

function F.car_view(view)
  if view == 'Inventory' then
    F.inv.open = true
  elseif F.inv.open then
    F.car_close()
  end
end

function F.car_close()
  if F.inv.dirty then F.car_follow() end
  F.car_new_inv()
end

function F.car_info(d)
  if d.name == nil or d.oil == nil then return false end
  local skin = type(d.skin) == 'table' and d.skin or {}
  F.inv.info = {
    name = F.game_text(tostring(d.name)), oil = d.oil, health = d.health, model = tonumber(skin.model),
  }
  F.inv.dirty = true
  return true
end

function F.car_merge(id, act, rows)
  local inv, now = F.inv, os.clock()
  local b = inv.blocks[id]
  -- A new list of a block is a new snapshot, its parts come right after each other.
  if act == 0 and (not b or now - b.at > 1) then
    b = {slots = {}, known = {}}
    inv.blocks[id] = b
  elseif not b then
    return
  end
  for _, row in pairs(rows) do
    local slot = type(row) == 'table' and tonumber(row.slot)
    if slot then
      local item = tonumber(row.item)
      if item and item > 0 then
        b.slots[slot] = {
          item = item, amount = tonumber(row.amount) or 1,
          text = row.text ~= nil and F.game_text(tostring(row.text)) or '', time = tonumber(row.time) or 0,
        }
      else
        b.slots[slot] = nil
      end
      if row.available ~= nil then b.known[slot] = row.available ~= 0 and row.available ~= false
      elseif b.known[slot] == nil then b.known[slot] = true end
    end
  end
  b.at, inv.at, inv.dirty = now, now, true
  if id == F.CAR_TRUNK then inv.open = true end
end

function F.car_event(v, body)
  local act, d = v.action, v.data
  if type(d) ~= 'table' then return end
  local used = false
  if act == 0 or act == 1 then used = F.car_info(d) end
  if act == 1 then
    if d.buttons ~= nil then F.inv.buttons, used = tonumber(d.buttons) or 0, true end
  elseif (act == 0 or act == 2) and F.CAR_BLOCK[d.type] and type(d.items) == 'table' then
    F.car_merge(d.type, act, d.items)
    used = true
  end
  if used then F.car_dump(body) end
end

function F.car_packet(text)
  if cfg.car_on ~= 1 then return end
  if text:find('event.setActiveView', 1, true) then
    F.car_view(text:match('`%s*%[%s*"([^"]+)"'))
    return
  end
  for body in text:gmatch("playerInventory['\"]%s*,%s*`(.-)`") do
    local v = F.json_value(body, 1)
    if type(v) == 'table' and v.action == nil then v = v[1] end
    if type(v) == 'string' then v = F.json_value(v, 1) end
    if type(v) == 'table' then F.car_event(v, body) end
  end
end

-- The window can close without a new view, then only its own message tells about it.
function F.car_sent(bs)
  raknetBitStreamIgnoreBits(bs, 8)
  if raknetBitStreamReadInt8(bs) ~= 18 then return end
  local len = tonumber(raknetBitStreamReadInt16(bs)) or 0
  if len <= 0 or len > 4096 then return end
  local text = raknetBitStreamReadString(bs, len)
  if text and text:find('inventoryClose', 1, true) then F.car_close() end
end

-- The same message a click in the window sends.
function F.cef_send(text)
  local bs = raknetNewBitStream()
  raknetBitStreamWriteInt8(bs, 220)
  raknetBitStreamWriteInt8(bs, 18)
  raknetBitStreamWriteInt16(bs, #text)
  raknetBitStreamWriteString(bs, text)
  raknetBitStreamWriteInt32(bs, 0)
  raknetSendBitStream(bs)
  raknetDeleteBitStream(bs)
end

function F.car_name(car)
  if car.alias and car.alias ~= '' then return car.alias end
  if car.name and car.name ~= '' then return car.name end
  return 'Машина ' .. tostring(car.model)
end

function F.car_model_name(model)
  local ok, name = pcall(getNameOfVehicleModel, model)
  if ok and type(name) == 'string' and name ~= '' then return name:sub(1, 1) .. name:sub(2):lower() end
  return 'Машина ' .. tostring(model)
end

function F.car_plate()
  local b = F.inv.blocks[36]
  if b then
    for _, r in pairs(b.slots) do
      if r.text ~= '' then return r.text end
    end
  end
  return ''
end

function F.car_here()
  local info, plate = F.inv.info, F.car_plate()
  local model, car = info and info.model, nil
  local ok, inside = pcall(isCharInAnyCar, PLAYER_PED)
  if ok and inside then
    ok, car = pcall(storeCarCharIsInNoSave, PLAYER_PED)
  else
    ok, car = pcall(storeClosestEntities, PLAYER_PED)
  end
  if ok and car and car ~= -1 then
    if not model then
      local got, m = pcall(getCarModel, car)
      if got then model = tonumber(m) end
    end
    local got, has, id = pcall(sampGetVehicleIdByCarHandle, car)
    if plate == '' and got and has then plate = F.car_plates[id] or '' end
  end
  if not model or model <= 0 then return nil end
  return {model = model, plate = plate}
end

-- Nothing else tells two cars apart: the id of a car changes after every spawn.
function F.car_find(model, plate)
  local same, n = nil, 0
  for i = 1, #F.cars do
    local c = F.cars[i]
    if c.model == model then
      if plate ~= '' and c.plate == plate then return c, 1 end
      if plate == '' or c.plate == '' then same, n = c, n + 1 end
    end
  end
  if n == 1 then return same, 1 end
  return nil, n
end

function F.car_latest(model)
  local best
  for i = 1, #F.cars do
    local c = F.cars[i]
    if c.model == model and (not best or c.scanned > best.scanned) then best = c end
  end
  return best
end

function F.car_make(model, plate)
  local id = 0
  for i = 1, #F.cars do id = math.max(id, F.cars[i].id) end
  local car = {
    id = id + 1, model = model, plate = plate or '', name = F.car_model_name(model), alias = '',
    auto = 0, scanned = 0, oil = '', health = '', blocks = {}, log = {},
  }
  F.cars[#F.cars + 1] = car
  return car
end

function F.car_tally(block)
  local t = {}
  local items = block and block.items or {}
  for i = 1, #items do
    local r = items[i]
    t[r.item] = (t[r.item] or 0) + r.amount
  end
  return t
end

function F.car_diff(car, id, old, new, now)
  if not old then return end
  local a, b = F.car_tally(old), F.car_tally(new)
  for item, n in pairs(b) do
    local d = n - (a[item] or 0)
    if d ~= 0 then car.log[#car.log + 1] = {t = now, block = id, item = item, delta = d} end
  end
  for item, n in pairs(a) do
    if not b[item] then car.log[#car.log + 1] = {t = now, block = id, item = item, delta = -n} end
  end
  while #car.log > F.CAR_LOG do table.remove(car.log, 1) end
end

function F.car_store(car)
  local inv, now, n = F.inv, os.time(), 0
  for id, b in pairs(inv.blocks) do
    local new = {at = now, total = 0, items = {}}
    for _, open in pairs(b.known) do
      if open then new.total = new.total + 1 end
    end
    for slot, r in pairs(b.slots) do
      new.items[#new.items + 1] = {slot = slot, item = r.item, amount = r.amount, text = r.text, time = r.time}
    end
    table.sort(new.items, function(x, y) return x.slot < y.slot end)
    F.car_diff(car, id, car.blocks[id], new, now)
    car.blocks[id] = new
    n = n + 1
  end
  if n == 0 then return 0 end
  local info = inv.info
  if info then
    if info.name ~= '' then car.name = info.name end
    car.oil = info.oil ~= nil and tostring(info.oil) or car.oil
    car.health = info.health ~= nil and tostring(info.health) or car.health
  end
  if car.plate == '' then car.plate = F.car_plate() end
  car.scanned = now
  F.car_save()
  return n
end

function F.car_cell(v)
  return (tostring(v == nil and '' or v):gsub('[\t\r\n]', ' '))
end

function F.car_save()
  local lines = {}
  local function row(...)
    local cells = {...}
    for i = 1, select('#', ...) do cells[i] = F.car_cell(cells[i]) end
    lines[#lines + 1] = table.concat(cells, '\t', 1, select('#', ...))
  end
  for _, c in ipairs(F.cars) do
    row('C', c.id, c.model, c.auto, c.scanned, c.oil, c.health, c.name, c.alias, c.plate)
    for id, b in pairs(c.blocks) do
      row('B', c.id, id, b.at, b.total)
      for _, r in ipairs(b.items) do
        row('I', c.id, id, r.slot, r.item, r.amount, r.time, r.text)
      end
    end
    for _, l in ipairs(c.log) do
      row('L', c.id, l.t, l.block, l.item, l.delta)
    end
  end
  F.write_lines('fhelp_cars.txt', lines)
end

function F.car_load()
  F.cars = {}
  local by = {}
  for _, line in ipairs(F.read_lines('fhelp_cars.txt')) do
    local c = {}
    for cell in (line .. '\t'):gmatch('(.-)\t') do c[#c + 1] = cell end
    local id = tonumber(c[2])
    local car = by[id or -1]
    if c[1] == 'C' and id then
      car = {
        id = id, model = tonumber(c[3]) or 0, auto = tonumber(c[4]) or 0, scanned = tonumber(c[5]) or 0,
        oil = c[6] or '', health = c[7] or '', name = c[8] or '', alias = c[9] or '', plate = c[10] or '',
        blocks = {}, log = {},
      }
      by[id] = car
      F.cars[#F.cars + 1] = car
    elseif car and c[1] == 'B' then
      car.blocks[tonumber(c[3]) or 0] = {at = tonumber(c[4]) or 0, total = tonumber(c[5]) or 0, items = {}}
    elseif car and c[1] == 'I' then
      local b = car.blocks[tonumber(c[3]) or 0]
      local item = tonumber(c[5])
      if b and item then
        b.items[#b.items + 1] = {
          slot = tonumber(c[4]) or 0, item = item, amount = tonumber(c[6]) or 1, time = tonumber(c[7]) or 0, text = c[8] or '',
        }
      end
    elseif car and c[1] == 'L' then
      car.log[#car.log + 1] = {t = tonumber(c[3]) or 0, block = tonumber(c[4]) or 0, item = tonumber(c[5]) or 0, delta = tonumber(c[6]) or 0}
    end
  end
end

-- Keeps a known car up to date without sending anything: only what the window got anyway.
function F.car_follow()
  local inv = F.inv
  inv.dirty = false
  local car = inv.car
  if not car then
    local h = F.car_here()
    if not h then return end
    car = F.car_find(h.model, h.plate)
    if not car or car.auto ~= 1 then return end
    inv.car = car
  end
  F.car_store(car)
end

function F.car_tick()
  local inv = F.inv
  if inv.dirty and not F.car_busy and os.clock() - inv.at > 0.6 then
    local ok, err = pcall(F.car_follow)
    if not ok then F.feed_err('машины', err) end
  end
end

function F.car_wait(blocks, limit)
  local start = os.clock()
  while F.inv.open and os.clock() - start < limit do
    for i = 1, #blocks do
      local b = F.inv.blocks[blocks[i]]
      if b and b.at >= start and os.clock() - F.inv.at > 0.35 then return true end
    end
    wait(50)
  end
  return false
end

function F.car_can(bit)
  return F.inv.buttons == 0 or F.band(F.inv.buttons, bit) ~= 0
end

function F.car_count(car, list)
  local n = 0
  for _, id in ipairs(list) do
    local b = car.blocks[id]
    if b then n = n + #b.items end
  end
  return n
end

function F.car_scan_run()
  local trunk = F.inv.blocks[F.CAR_TRUNK] ~= nil
  if not trunk and F.car_can(F.CAR_BIT_TRUNK) then
    F.cef_send('openWarehouse|{"type":8}')
    trunk = F.car_wait({F.CAR_TRUNK}, 1.5)
    wait(300)
  end
  local tuning = false
  if F.car_can(F.CAR_BIT_CAR) then
    F.cef_send('requestShowingInventory|30')
    tuning = F.car_wait({23, 12, 18, 19, 36}, 1.5)
    if trunk and F.inv.open then
      wait(300)
      F.cef_send('openWarehouse|{"type":8}')
      F.car_wait({F.CAR_TRUNK}, 1)
    end
  end
  if not F.inv.open then
    F.notify('Инвентарь закрылся, скан прерван')
    return
  end
  if not next(F.inv.blocks) then
    F.notify('Сервер не прислал данные. Открой багажник и попробуй ещё раз')
    return
  end
  local h = F.car_here()
  if not h then
    F.notify('Не вижу машину рядом')
    return
  end
  local car, same = F.car_find(h.model, h.plate)
  if not car and same > 0 then car = F.car_latest(h.model) end
  car = car or F.car_make(h.model, h.plate)
  local keep = {blocks = {}, log = {}, scanned = car.scanned}
  for id, b in pairs(car.blocks) do keep.blocks[id] = b end
  for i = 1, #car.log do keep.log[i] = car.log[i] end
  F.car_store(car)
  car.prev = keep.scanned > 0 and keep or nil
  F.inv.car, F.inv.dirty = car, false
  F.car_last, F.car_sel = car, car.id
  local msg = F.car_name(car) .. ': багажник ' .. tostring(F.car_count(car, {8}))
  if tuning then
    msg = msg .. ', тюнинг ' .. tostring(F.car_count(car, {12, 18, 19, 23, 36}))
  else
    msg = msg .. '. Тюнинг не получен: открой вкладку машины в инвентаре, fHelper дочитает'
  end
  F.notify(msg)
  pcall(F.toast, 'car', {key = 'car' .. tostring(car.id), icon = 'ICON_FA_CAR', title = 'Машина отсканирована', text = msg})
end

function F.car_scan()
  if F.car_busy then return end
  if cfg.car_on ~= 1 then
    F.notify('Сканер машин выключен в разделе «Эксперимент»')
    return
  end
  if not F.inv.open then
    F.notify('Сначала открой багажник машины')
    return
  end
  F.car_busy = true
  lua_thread.create(function()
    local ok, err = pcall(F.car_scan_run)
    F.car_busy = false
    if not ok then
      F.notify('Скан не удался')
      F.log_line('Скан машины: ' .. tostring(err))
    end
  end)
end

-- Two cars of one model without a known plate look the same, this undoes such a mix.
function F.car_split(car)
  local prev = car.prev
  if not prev then return end
  local new = F.car_make(car.model, '')
  new.name, new.oil, new.health = car.name, car.oil, car.health
  new.blocks, new.scanned = car.blocks, car.scanned
  car.blocks, car.log, car.scanned, car.prev = prev.blocks, prev.log, prev.scanned, nil
  if F.inv.car == car then F.inv.car = new end
  F.car_last, F.car_sel = new, new.id
  F.car_save()
end

function F.car_drop(car)
  for i = #F.cars, 1, -1 do
    if F.cars[i] == car then table.remove(F.cars, i) end
  end
  if F.inv.car == car then F.inv.car = nil end
  if F.car_last == car then F.car_last = nil end
  F.car_sel = nil
  F.car_save()
end

function F.car_ago(t)
  local d = os.time() - (tonumber(t) or 0)
  if d < 60 then return 'только что' end
  if d < 3600 then return math.floor(d / 60) .. ' мин назад' end
  if d < 86400 then return math.floor(d / 3600) .. ' ч назад' end
  return math.floor(d / 86400) .. ' дн назад'
end

function F.car_left(t)
  local d = t - os.time()
  if d <= 0 then return 'срок истёк' end
  if d < 3600 then return 'осталось ' .. math.ceil(d / 60) .. ' мин' end
  if d < 86400 then return 'осталось ' .. math.floor(d / 3600) .. ' ч' end
  return 'осталось ' .. math.floor(d / 86400) .. ' дн'
end

function F.car_status()
  if F.car_busy then return 'Читаю багажник и тюнинг' end
  local now = os.clock()
  if F._car_st and now - F._car_st_at < 1 then return F._car_st end
  local car = F.inv.car
  if not car then
    local h = F.car_here()
    if h then car = F.car_find(h.model, h.plate) end
  end
  local st = 'Эта машина ещё не сканировалась'
  if car then
    st = F.car_name(car) .. ': скан ' .. F.car_ago(car.scanned)
    if car.auto == 1 then st = st .. ', автоскан' end
  end
  F._car_st, F._car_st_at = st, now
  return st
end

function F.car_bar_on()
  local inv = F.inv
  if hidden or cfg.car_on ~= 1 or cfg.car_bar ~= 1 or not inv.open or inv.bar_off then return false end
  if not inv.blocks[F.CAR_TRUNK] and F.band(inv.buttons, F.CAR_BIT_TRUNK) == 0 then return false end
  local ok, pause = pcall(isPauseMenuActive)
  return not (ok and pause)
end

function F.draw_car_bar()
  local io = imgui.GetIO()
  local sw = io.DisplaySize.x
  if sw < 100 then sw = 1366 end
  local w, h = F.s(380), F.s(62)
  local x, y = (sw - w) / 2, F.s(12)
  local WF = imgui.WindowFlags
  local flags = WF.NoTitleBar + WF.NoResize + WF.NoScrollbar + WF.NoScrollWithMouse + WF.NoCollapse
    + WF.NoSavedSettings + WF.NoFocusOnAppearing + WF.NoNavInputs + WF.NoNavFocus + WF.NoMove + (WF.NoBackground or 0)
  imgui.SetNextWindowPos(imgui.ImVec2(x, y), imgui.Cond.Always)
  imgui.SetNextWindowSize(imgui.ImVec2(w, h), imgui.Cond.Always)
  imgui.PushStyleColor(imgui.Col.WindowBg, F.vec4(0, 0, 0, 0))
  imgui.PushStyleColor(imgui.Col.Border, F.vec4(0, 0, 0, 0))
  imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0)
  imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
  imgui.Begin('fhelp-car', nil, flags)
  F.use_font(font_main)
  F.round_rect(x, y, w, h, F.col('panel', 244), F.col('accent', 120), 12)
  local tw = w - F.s(186)
  F.text_at(font_bold, 16, x + F.s(14), y + F.s(10), F.col('text'), F.fit_text(font_bold, 'Багажник машины', tw))
  F.text_at(font_main, 14, x + F.s(14), y + F.s(33), F.col('text', 150), F.fit_text(font_main, F.car_status(), tw / 0.875))
  imgui.SetCursorScreenPos(imgui.ImVec2(x + w - F.s(168), y + (h - F.s(34)) / 2))
  if F.button(F.car_busy and 'Читаю##carscan' or 'Сканировать##carscan', 126, 34, 'primary') then F.car_scan() end
  if F.ghost_icon('##carbaroff', x + w - F.s(36), y + (h - F.s(30)) / 2, 'ICON_FA_TIMES', 'Скрыть до следующего открытия') then
    F.inv.bar_off = true
  end
  F.done_font(font_main)
  imgui.End()
  imgui.PopStyleVar(2)
  imgui.PopStyleColor(2)
end

function F.car_lib(id)
  local db = F.lib_db()
  local it = db.by_id[id]
  if it then return it end
  db.stub = db.stub or {}
  it = db.stub[id]
  if not it then
    it = {id = id, cat = 'etc', name = 'Предмет ' .. tostring(id), token = ':item' .. tostring(id) .. ':', pic_n = 0, desc_n = 0}
    db.stub[id] = it
  end
  return it
end

-- Equal items from several slots make one card with the total amount.
function F.car_group(car, blocks)
  local out, at = {}, {}
  for _, id in ipairs(blocks) do
    local b = car.blocks[id]
    if b then
      for _, r in ipairs(b.items) do
        local key = r.item .. '|' .. r.text
        local e = at[key]
        if e then
          e.amount = e.amount + r.amount
          if r.time > 0 and (e.time == 0 or r.time < e.time) then e.time = r.time end
        else
          e = {it = F.car_lib(r.item), amount = r.amount, text = r.text, time = r.time}
          at[key] = e
          out[#out + 1] = e
        end
      end
    end
  end
  return out
end

function F.car_item(e, x, y, w, h, hovered)
  local it = e.it
  local expired = e.time > 0 and e.time <= os.time()
  F.round_rect(x, y, w, h, hovered and F.col('raised') or F.col('side', 140),
    expired and F.col('bad', 150) or F.col('text', hovered and 34 or 14), 10)
  local sz = F.s(56)
  F.lib_pic(it, x + (w - sz) / 2, y + F.s(6), sz)
  local one, two = F.lib_lines(it, w - F.s(10))
  local ty = y + F.s(66)
  F.text_at(font_main, 14, x + (w - F.text_w(font_main, one) * 0.875) / 2, ty, F.col('text'), one)
  F.text_at(font_main, 14, x + (w - F.text_w(font_main, two) * 0.875) / 2, ty + F.s(16), F.col('text', 170), two)
  local badge = e.amount > 1 and ('x' .. tostring(e.amount)) or e.text
  if badge ~= '' then
    badge = F.fit_text(font_main, badge, w - F.s(20))
    local bw = F.text_w(font_main, badge) * 0.875 + F.s(12)
    F.round_rect(x + w - bw - F.s(4), y + F.s(4), bw, F.s(20), F.col('accent', 225), nil, 6)
    F.text_at(font_main, 14, x + w - bw + F.s(2), y + F.s(6), F.col('ink'), badge)
  end
  if hovered then
    local tip = it.name
    if e.amount > 1 then tip = tip .. '\nКоличество: ' .. tostring(e.amount) end
    if e.time > 0 then tip = tip .. '\n' .. F.car_left(e.time) end
    F.tip(tip .. '\nНажми, чтобы скопировать код')
  end
end

function F.car_grid(prefix, list)
  local w = F.inner_w()
  local gap = math.floor(F.s(8))
  local cols = math.max(1, math.floor((w + gap) / (F.s(112) + gap)))
  local cw = math.floor((w - gap * (cols - 1)) / cols)
  local ch = math.floor(F.s(106))
  local p = imgui.GetCursorScreenPos()
  local rows = math.ceil(#list / cols)
  for i = 1, #list do
    local x = p.x + (i - 1) % cols * (cw + gap)
    local y = p.y + math.floor((i - 1) / cols) * (ch + gap)
    local clicked, hovered = F.hotspot(prefix .. i, x, y, cw, ch)
    F.car_item(list[i], x, y, cw, ch, hovered)
    if clicked then F.note_copy(list[i].it.token) end
  end
  F.advance(p, w, math.max(1, rows * (ch + gap) - gap))
end

function F.car_sub(sec, car)
  local used, total, at = 0, 0, nil
  for _, id in ipairs(sec[4]) do
    local b = car.blocks[id]
    if b then
      used, total = used + #b.items, total + b.total
      at = math.max(at or 0, b.at)
    end
  end
  if not at then return nil end
  local text = total > used and (used .. ' из ' .. total .. ' слотов') or (used .. ' предм.')
  return text .. ', скан ' .. F.car_ago(at)
end

function F.car_section(car, sec)
  local sub = F.car_sub(sec, car)
  F.card_begin(sec[2], sub or 'Ещё не сканировали', sec[3])
  local list = F.car_group(car, sec[4])
  if #list > 0 then
    F.car_grid('##car' .. sec[1], list)
  elseif sub then
    F.hint('Пусто')
  else
    F.hint('Нажми «Сканировать» в машине или открой эту вкладку в инвентаре.')
  end
  F.card_end()
end

function F.car_section_name(id)
  for _, sec in ipairs(F.CAR_SECTIONS) do
    for _, b in ipairs(sec[4]) do
      if b == id then return sec[2] end
    end
  end
  return tostring(id)
end

function F.car_history(car)
  F.card_begin('История', 'Что изменилось между сканами', 'ICON_FA_HISTORY')
  if #car.log == 0 then F.hint('Изменений пока нет.') end
  for i = #car.log, 1, -1 do
    local l = car.log[i]
    local sign = l.delta > 0 and '+' or ''
    F.hint(os.date('%d.%m %H:%M', l.t) .. '   ' .. sign .. tostring(l.delta) .. '   ' .. F.car_lib(l.item).name
      .. '   (' .. F.car_section_name(l.block) .. ')', l.delta > 0 and F.cvec('accent_hi') or F.cvec('bad'))
  end
  F.card_end()
end

function F.car_text(car)
  local out = {F.car_name(car) .. (car.plate ~= '' and (' [' .. car.plate .. ']') or '')}
  for _, sec in ipairs(F.CAR_SECTIONS) do
    local list = F.car_group(car, sec[4])
    if #list > 0 then
      out[#out + 1] = sec[2] .. ':'
      for _, e in ipairs(list) do
        out[#out + 1] = '  ' .. e.it.name .. (e.amount > 1 and (' x' .. tostring(e.amount)) or '')
      end
    end
  end
  return table.concat(out, '\n')
end

function F.car_actions(car)
  if F.switch('carauto', 'Автоскан', car.auto == 1, 'Обновлять при каждом открытии багажника, без лишних запросов') then
    car.auto = car.auto == 1 and 0 or 1
    F.car_save()
  end
  F.divider()
  if F._car_alias ~= car.id then
    F._car_alias = car.id
    F.buf_set(ui.car_alias, car.alias or '', 60)
  end
  local w = F.inner_w()
  F.field('##caralias', 'Своё название, например «Для перевозки»', ui.car_alias, 60, w - F.s(130), 'car_alias')
  imgui.SameLine(0, 8)
  if F.button('Сохранить##caralias', 120, 0) then
    car.alias = F.trim(F.buf_get(ui.car_alias))
    F.car_save()
  end
  imgui.Spacing()
  if F.button('Скопировать список##carcopy', 180, 0) then F.note_copy(F.car_text(car)) end
  if F.car_last == car and car.prev then
    F.same_if_fit(F.s(170))
    if F.button('Это другая машина##carsplit', 170, 0) then F.car_split(car) end
    if imgui.IsItemHovered() then F.tip('Вернёт прошлый скан этой записи, а новый сохранит отдельной машиной') end
  end
  F.same_if_fit(F.s(170))
  if F.car_ask == car.id then
    if F.button('Да, удалить##cardel', 120, 0, 'danger') then
      F.car_ask = nil
      F.car_drop(car)
    end
  elseif F.button('Удалить##cardel', 100, 0) then
    F.car_ask = car.id
  end
end

function F.car_page(car)
  local parts = {}
  if car.plate ~= '' then parts[#parts + 1] = car.plate end
  parts[#parts + 1] = 'скан ' .. F.car_ago(car.scanned)
  if car.health ~= '' then parts[#parts + 1] = 'состояние ' .. car.health .. '%' end
  if car.oil ~= '' then parts[#parts + 1] = 'топливо ' .. car.oil .. '%' end
  F.card_begin(F.car_name(car), table.concat(parts, '  ·  '), 'ICON_FA_CAR')
  F.car_actions(car)
  if not F.car_sel then
    F.card_end()
    return
  end
  F.card_end()
  local pills = {{'all', 'Все'}}
  for _, sec in ipairs(F.CAR_SECTIONS) do pills[#pills + 1] = {sec[1], sec[2]} end
  pills[#pills + 1] = {'log', 'История'}
  local pick = F.pill_row('##carsec', pills, F.car_tab or 'all')
  if pick then F.car_tab = pick end
  imgui.Spacing()
  if F.car_tab == 'log' then
    F.car_history(car)
    return
  end
  for _, sec in ipairs(F.CAR_SECTIONS) do
    if (F.car_tab or 'all') == 'all' or F.car_tab == sec[1] then F.car_section(car, sec) end
  end
end

-- Where an item lies, over all the saved cars.
function F.car_found(q)
  local low = F.lower_fast(q)
  local id = tonumber((low:match('^:item(%d+):$')) or low)
  local total, cars = 0, 0
  local hits = {}
  for _, car in ipairs(F.cars) do
    for _, sec in ipairs(F.CAR_SECTIONS) do
      local list = {}
      for _, e in ipairs(F.car_group(car, sec[4])) do
        if (id and e.it.id == id) or F.lower_fast(e.it.name):find(low, 1, true) then
          list[#list + 1] = e
          total = total + e.amount
        end
      end
      if #list > 0 then
        if not hits[car] then
          hits[car] = true
          cars = cars + 1
        end
        hits[#hits + 1] = {car = car, sec = sec, list = list}
      end
    end
  end
  if #hits == 0 then
    F.empty('ICON_FA_SEARCH', 'Ничего не нашлось', 'Поиск идёт по последним сканам')
    return
  end
  F.card_begin('Найдено', 'Всего ' .. tostring(total) .. ' шт., машин: ' .. tostring(cars), 'ICON_FA_SEARCH')
  for i, hit in ipairs(hits) do
    F.section_title(F.car_name(hit.car) .. ', ' .. F.lower_fast(hit.sec[2]))
    F.car_grid('##carfind' .. i, hit.list)
    imgui.Spacing()
  end
  F.card_end()
end

function F.draw_cars()
  F.card_begin('Сканер машин', 'Запоминает, что лежит в багажнике и стоит на машине', 'ICON_FA_CAR')
  if F.switch('caron', 'Сканер', cfg.car_on == 1) then
    cfg.car_on = cfg.car_on == 1 and 0 or 1
    dirty = true
  end
  if cfg.car_on == 1 then
    if F.switch('carbar', 'Кнопка над инвентарём', cfg.car_bar == 1, 'Появляется, когда багажник открыт') then
      cfg.car_bar = cfg.car_bar == 1 and 0 or 1
      dirty = true
    end
    F.hint('Сядь в машину, открой багажник и нажми «Сканировать» или введи /fcar.')
    if F.inv.open and F.accent_button(F.car_busy and 'Читаю##carmenu' or 'Сканировать##carmenu', 170, 0) then F.car_scan() end
  end
  F.card_end()
  if #F.cars == 0 then
    F.empty('ICON_FA_CAR', 'Машин пока нет', 'После первого скана машина появится здесь')
    return
  end
  F.field('##carq', 'Поиск предмета по всем машинам: название или ID', ui.car_q, 80, F.inner_w(), 'car_q')
  imgui.Spacing()
  local q = F.trim(F.buf_get(ui.car_q))
  if q ~= '' then
    F.car_found(q)
    return
  end
  local list, car = {}, nil
  for _, c in ipairs(F.cars) do
    list[#list + 1] = {c.id, F.car_name(c)}
    if c.id == F.car_sel then car = c end
  end
  car = car or F.cars[1]
  F.car_sel = car.id
  local pick = F.pill_row('##carlist', list, F.car_sel)
  if pick then
    F.car_sel, F.car_ask = pick, nil
  end
  imgui.Spacing()
  F.car_page(car)
end

-- Stalls: what a stall shows when it is opened. The server sends nothing about stalls nobody opened.
-- Block 13 is what the stall sells, block 28 is what it buys; the price is the slot text with '$'.

F.SHOP_KIND = {[13] = 'sell', [28] = 'buy'}
F.SHOP_MAX = 400
F.SHOP_DAYS = 3
F.shops = {}
F.shop_rev = 0

function F.shop_dump(body)
  F._shop_dumps = (F._shop_dumps or 0) + 1
  if F._shop_dumps > 20 then return end
  pcall(function()
    F.mkdir(F.cfg_dir())
    local f = io.open(F.cfg_dir() .. '\\fhelp_shops_debug.txt', F._shop_dumps == 1 and 'w' or 'a')
    if not f then return end
    f:write(body:sub(1, 3000), '\n')
    f:close()
  end)
end

function F.shop_price(text)
  text = tostring(text or '')
  if not text:find('$', 1, true) then return nil end
  local digits = text:gsub('%D', '')
  if digits == '' or #digits > 15 then return nil end
  return tonumber(digits)
end

function F.shop_packet(text)
  if cfg.shop_on ~= 1 or not text:find('playerInventory', 1, true) then return end
  for body in text:gmatch("playerInventory['\"]%s*,%s*`(.-)`") do
    if body:find('"type"%s*:%s*13%D') or body:find('"type"%s*:%s*28%D') then
      local v = F.json_value(body, 1)
      if type(v) == 'table' and v.action == nil then v = v[1] end
      if type(v) == 'string' then v = F.json_value(v, 1) end
      if type(v) == 'table' and (v.action == 0 or v.action == 2) and type(v.data) == 'table' then
        local kind = F.SHOP_KIND[tonumber(v.data.type)]
        if kind and type(v.data.items) == 'table' then
          F.shop_dump(body)
          F.shop_merge(kind, v.action, v.data.items)
        end
      end
    end
  end
end

-- The stall itself is the nearest label with the word "лавка", else any label right next to the player.
function F.shop_pos()
  local ok, x, y, z = pcall(getCharCoordinates, PLAYER_PED)
  if not ok or not x then return nil end
  local p = {x = x, y = y, z = z}
  local best, bd, near, nd
  pcall(function()
    for id = 0, 2047 do
      if sampIs3dTextDefined(id) then
        local text, _, tx, ty, tz, _, _, pl, veh = sampGet3dTextInfoById(id)
        if text and tx and (pl == nil or pl == -1 or pl == 65535) and (veh == nil or veh == -1 or veh == 65535) then
          local d = math.sqrt((tx - x) ^ 2 + (ty - y) ^ 2 + (tz - z) ^ 2)
          if d < 12 then
            local t = F.trim((F.game_text(text):gsub('[\r\n]+', '  ·  ')))
            if t ~= '' then
              if F.lower_fast(t):find('лавк', 1, true) then
                if not bd or d < bd then best, bd = {t, tx, ty, tz}, d end
              elseif d < 5 and (not nd or d < nd) then
                near, nd = {t, tx, ty, tz}, d
              end
            end
          end
        end
      end
    end
  end)
  local hit = best or near
  if hit then p.label, p.lx, p.ly, p.lz = hit[1], hit[2], hit[3], hit[4] end
  return p
end

function F.shop_merge(kind, act, rows)
  local now = os.clock()
  local cur = F.shop_cur
  -- Both blocks of one stall come right after each other; a later list is another opening.
  if act == 0 and (not cur or now - cur.at > 2) then
    cur = {blocks = {}, at = now, pos = F.shop_pos()}
    F.shop_cur = cur
  elseif not cur then
    return
  end
  local b = cur.blocks[kind]
  if act == 0 and (not b or now - b.at > 1) then
    b = {slots = {}, at = now}
    cur.blocks[kind] = b
  elseif not b then
    return
  end
  for _, row in pairs(rows) do
    local slot = type(row) == 'table' and tonumber(row.slot)
    if slot then
      local id = tonumber(row.item)
      if id and id > 0 then
        b.slots[slot] = {id = id, amount = math.max(1, math.floor(tonumber(row.amount) or 1)), price = F.shop_price(row.text)}
      else
        b.slots[slot] = nil
      end
    end
  end
  b.at, cur.at, cur.dirty = now, now, true
end

function F.shop_tick()
  local cur = F.shop_cur
  if cur and cur.dirty and os.clock() - cur.at > 0.8 then
    cur.dirty = false
    F.shop_commit(cur)
  end
end

function F.shop_commit(cur)
  local p = cur.pos or {}
  local key
  if p.lx then key = string.format('%.0f_%.0f', p.lx, p.ly)
  else key = string.format('p%d_%d', math.floor((p.x or 0) / 4), math.floor((p.y or 0) / 4)) end
  local items = {}
  for _, kind in ipairs({'sell', 'buy'}) do
    local b = cur.blocks[kind]
    if b then
      local slots = {}
      for s in pairs(b.slots) do slots[#slots + 1] = s end
      table.sort(slots)
      for _, s in ipairs(slots) do
        local r = b.slots[s]
        items[#items + 1] = {k = kind, id = r.id, amount = r.amount, price = r.price}
      end
    end
  end
  local title = p.label and F.utf_cut(p.label, 90) or 'Лавка без подписи'
  local shop = {key = key, t = os.date('%Y-%m-%d %H:%M:%S'), x = p.lx or p.x, y = p.ly or p.y, z = p.lz or p.z, title = title, items = items}
  for i = #F.shops, 1, -1 do
    if F.shops[i].key == key then table.remove(F.shops, i) end
  end
  table.insert(F.shops, 1, shop)
  while #F.shops > F.SHOP_MAX do table.remove(F.shops) end
  F.shop_rev = F.shop_rev + 1
  pcall(F.shop_save)
  F.toast('shop', {key = 'shop' .. key, icon = 'ICON_FA_STORE', title = 'Лавка записана', text = title .. '  ·  товаров: ' .. #items, quiet = true})
end

function F.shop_save()
  local out = {}
  for _, s in ipairs(F.shops) do
    out[#out + 1] = table.concat({'S', s.key, s.t, string.format('%.1f', s.x or 0), string.format('%.1f', s.y or 0),
      string.format('%.1f', s.z or 0), (tostring(s.title):gsub('|', '/'))}, '|')
    for _, r in ipairs(s.items) do
      out[#out + 1] = 'I|' .. r.k .. '|' .. r.id .. '|' .. r.amount .. '|' .. (r.price and string.format('%.0f', r.price) or '')
    end
  end
  F.write_lines('fhelp_shops.txt', out)
end

function F.shop_load()
  F.shops = {}
  local cut = os.date('%Y-%m-%d %H:%M:%S', os.time() - F.SHOP_DAYS * 86400)
  local cur
  for _, line in ipairs(F.read_lines('fhelp_shops.txt')) do
    local key, t, x, y, z, title = line:match('^S|(.-)|(.-)|(.-)|(.-)|(.-)|(.*)$')
    if key then
      cur = nil
      if t >= cut and #F.shops < F.SHOP_MAX then
        cur = {key = key, t = t, x = tonumber(x), y = tonumber(y), z = tonumber(z), title = title, items = {}}
        F.shops[#F.shops + 1] = cur
      end
    elseif cur then
      local k, id, am, pr = line:match('^I|(%a+)|(%d+)|(%d+)|(%d*)$')
      if k then cur.items[#cur.items + 1] = {k = k, id = tonumber(id), amount = tonumber(am) or 1, price = tonumber(pr)} end
    end
  end
  F.shop_rev = F.shop_rev + 1
end

function F.shop_clear()
  F.shops, F.shop_sel = {}, nil
  F.shop_rev = F.shop_rev + 1
  pcall(F.shop_save)
  F.notify('Записанные лавки удалены', true)
end

function F.ago(t)
  local at = F.stamp_time(t)
  if not at then return tostring(t or '') end
  local d = math.max(0, os.time() - at)
  if d < 60 then return 'только что' end
  if d < 3600 then return math.floor(d / 60) .. ' мин назад' end
  if d < 86400 then return math.floor(d / 3600) .. ' ч назад' end
  local n = math.floor(d / 86400)
  return n .. ' ' .. F.ru_count(n, 'день', 'дня', 'дней') .. ' назад'
end

function F.shop_dist(s)
  local ok, x, y, z = pcall(getCharCoordinates, PLAYER_PED)
  if not ok or not x or not s.x then return '' end
  local d = math.sqrt((s.x - x) ^ 2 + (s.y - y) ^ 2 + ((s.z or z) - z) ^ 2)
  if d < 1000 then return string.format('%.0f м', d) end
  return string.format('%.1f км', d / 1000)
end

function F.shop_mark(s)
  if not s.x then return end
  local ok = pcall(placeWaypoint, s.x, s.y, s.z or 0)
  F.notify(ok and ('Метка на карте: ' .. s.title) or 'Не получилось поставить метку', true)
end

function F.shop_view(q, kind)
  local key = q .. '|' .. kind .. '|' .. F.shop_rev
  if F._shop_vk == key then return F._shop_v end
  local low = F.lower_fast(q)
  local qid = tonumber(q)
  local rows = {}
  for _, s in ipairs(F.shops) do
    for _, r in ipairs(s.items) do
      if r.k == kind then
        local name = F.item_label(r.id)
        if r.id == qid or F.lower_fast(name):find(low, 1, true) then rows[#rows + 1] = {shop = s, r = r, name = name} end
      end
    end
  end
  table.sort(rows, function(a, b)
    local pa, pb = a.r.price, b.r.price
    if pa and pb and pa ~= pb then
      if kind == 'sell' then return pa < pb end
      return pa > pb
    end
    if (pa == nil) ~= (pb == nil) then return pa ~= nil end
    return a.shop.t > b.shop.t
  end)
  F._shop_vk, F._shop_v = key, rows
  return rows
end

function F.shop_price_text(r)
  if not r.price then return 'цена ?' end
  return '$' .. (F.fmt_money(r.price) or tostring(r.price))
end

function F.shop_items(s, kind, base)
  local n = 0
  for _, r in ipairs(s.items) do
    if r.k == kind then
      n = n + 1
      F.item_row(F.item_label(r.id), r.id, '×' .. r.amount, F.shop_price_text(r), base + n)
    end
  end
  return n
end

function F.draw_shops()
  F.card_begin('Лавки', 'Запоминает товары и цены лавок, которые ты открыл', 'ICON_FA_STORE')
  if F.switch('shopon', 'Записывать лавки', cfg.shop_on == 1) then
    cfg.shop_on = cfg.shop_on == 1 and 0 or 1
    dirty = true
  end
  F.hint('Открывай лавки на рынке как обычно, fHelper сам запишет товары и цены. Сервер присылает только лавки, которые ты открыл.')
  F.hint('Записи старше ' .. F.SHOP_DAYS .. ' дней удаляются. Нажми на найденный товар, чтобы поставить метку на карте.')
  if #F.shops > 0 then
    imgui.Spacing()
    if F.button('Очистить записи##shopclr', 200, 0, 'danger') then
      F.ask('Удалить все записанные лавки?', 'Удалить', 'fn', {fn = F.shop_clear})
    end
  end
  F.card_end()
  if #F.shops == 0 then
    F.empty('ICON_FA_STORE', 'Лавок пока нет', 'Открой любую лавку, и она появится здесь')
    return
  end
  F.field('##shopq', 'Поиск товара по всем лавкам: название или ID', ui.shop_q, 80, F.inner_w(), 'shop_q')
  imgui.Spacing()
  F.shop_kind = F.segment('shopkind', {{'sell', 'Продают'}, {'buy', 'Скупают'}}, F.shop_kind or 'sell') or F.shop_kind or 'sell'
  imgui.Spacing()
  local q = F.trim(F.buf_get(ui.shop_q))
  if q ~= '' then
    local rows = F.shop_view(q, F.shop_kind)
    if #rows == 0 then
      F.empty('ICON_FA_SEARCH', 'Ничего не нашлось', 'Поиск идёт только по лавкам, которые ты открывал')
      return
    end
    F.card_begin('Найдено', F.shop_kind == 'sell' and 'Сначала самые дешёвые' or 'Сначала те, кто платит больше', 'ICON_FA_SEARCH')
    for i = 1, math.min(#rows, 80) do
      local h = rows[i]
      local s = h.shop
      local dist = F.shop_dist(s)
      local sub = '×' .. h.r.amount .. '  ·  ' .. s.title .. '  ·  ' .. F.ago(s.t) .. (dist ~= '' and ('  ·  ' .. dist) or '')
      F.item_row(h.name, h.r.id, sub, F.shop_price_text(h.r), i, 'Нажми, чтобы поставить метку на эту лавку', function() F.shop_mark(s) end)
    end
    if #rows > 80 then F.hint('И ещё: ' .. (#rows - 80)) end
    F.card_end()
    return
  end
  local sel
  for _, s in ipairs(F.shops) do
    if s.key == F.shop_sel then sel = s end
  end
  F.card_begin('Записанные лавки', 'Всего: ' .. #F.shops .. '. Нажми, чтобы открыть товары', 'ICON_FA_STORE')
  for i = 1, math.min(#F.shops, 60) do
    local s = F.shops[i]
    local n = 0
    for _, r in ipairs(s.items) do
      if r.k == F.shop_kind then n = n + 1 end
    end
    local dist = F.shop_dist(s)
    F.item_row(s.title, 0, F.ago(s.t) .. (dist ~= '' and ('  ·  ' .. dist) or ''), tostring(n), 2000 + i,
      'Нажми, чтобы показать товары этой лавки', function() F.shop_sel = s.key end)
  end
  F.card_end()
  if sel then
    F.card_begin(sel.title, (F.shop_kind == 'sell' and 'Продаёт' or 'Скупает') .. '  ·  ' .. F.ago(sel.t), 'ICON_FA_BOXES')
    if F.shop_items(sel, F.shop_kind, 3000) == 0 then F.hint('В этом разделе у лавки ничего нет.') end
    imgui.Spacing()
    if F.button('Метка на карте##shopmark', 200, 0) then F.shop_mark(sel) end
    F.card_end()
  end
end

-- Experimental mode

-- The restart reloads every list, so nothing of the old project stays in memory.
-- What waits for a save goes out first, while the paths still lead to the old project.
function F.proj_set(key)
  if key == cfg.proj or not F.PROJ[key] then return end
  if F.int_dirty then F.int_save() end
  cfg.proj = key
  cfg.money_real, cfg.alt_money_real = cfg.alt_money_real, cfg.money_real
  cfg.bank, cfg.alt_bank = cfg.alt_bank, cfg.bank
  cfg.depo, cfg.alt_depo = cfg.alt_depo, cfg.depo
  if show then cfg.open = 1 end
  F.save_cfg()
  F.log_line('Проект: ' .. F.proj().name)
  lua_thread.create(function()
    wait(100)
    thisScript():reload()
  end)
end

function F.draw_exp_proj()
  F.card_begin('Проект', 'Переключает весь fHelper под другой проект', 'ICON_FA_FLASK')
  local key = F.segment('proj', {{'arz', 'Arizona RP'}, {'rod', 'Rodina RP'}}, cfg.proj)
  if key then F.proj_set(key) end
  imgui.Spacing()
  F.hint('Сейчас выбран ' .. F.proj().name .. '. При переключении fHelper перезапустится.')
  F.divider()
  F.hint('Меняется: предметы, картинки и библиотека, лог чата, валюта, разбор чека и доходов, названия в меню.')
  F.hint('У каждого проекта свои доходы, интеграции, рецепты крафта, машины и суммы банка. Бинды, заметки и избранное общие.')
  F.card_end()
end

function F.draw_exp()
  F.page_head('Экспериментальный режим', 'Функции, которые ещё обкатываются')
  F.exp_tab = F.segment('exptab', {{'proj', 'Проект'}, {'cars', 'Машины'}, {'shops', 'Лавки'}}, F.exp_tab or 'proj') or F.exp_tab or 'proj'
  imgui.Spacing()
  if F.exp_tab == 'cars' then F.draw_cars()
  elseif F.exp_tab == 'shops' then F.draw_shops()
  else F.draw_exp_proj() end
end

function F.draw_hud()
  local io = imgui.GetIO()
  local sw, sh = io.DisplaySize.x, io.DisplaySize.y
  if sw < 100 then sw = 1366 end
  if sh < 100 then sh = 768 end
  local rows = {}
  local hs = tonumber(cfg.hud_scale) or 1
  if hs < 0.6 then hs = 0.6 elseif hs > 2 then hs = 2 end
  if cfg.hud_fps == 1 or cfg.hud_ping == 1 then
    local parts = {}
    if cfg.hud_fps == 1 then
      parts[#parts + 1] = string.format('FPS  %d', math.floor((fps or 0) + 0.5))
    end
    if cfg.hud_ping == 1 then
      local ping = tonumber(live.ping)
      if ping then
        parts[#parts + 1] = string.format('пинг  %d мс', math.floor(ping + 0.5))
      else
        parts[#parts + 1] = 'пинг  —'
      end
    end
    rows[#rows + 1] = {table.concat(parts, '   '), 'fps'}
  end
  if cfg.hud_net == 1 then
    rows[#rows + 1] = {'трафик  ' .. F.fmt_bytes(F.used_bytes(false)), 'used'}
    rows[#rows + 1] = {'вх ' .. F.fmt_bytes(net.inn) .. '   исх ' .. F.fmt_bytes(net.outn), 'sub'}
  end
  if #rows == 0 then return end
  F.use_font(font_main)
  local tw = 48 * hs
  for i = 1, #rows do
    local w = F.text_w(font_main, rows[i][1]) * hs
    if w > tw then tw = w end
  end
  local line_h = 18 * hs
  local pad = 9 * hs
  local box_w = tw + 30 * hs
  local box_h = #rows * line_h + pad * 2
  local menu_open = show
  local pinned = cfg.hud_place ~= 4 or not menu_open or net.force
  local WF = imgui.WindowFlags
  local flags = WF.NoTitleBar + WF.NoResize + WF.NoScrollbar + WF.NoScrollWithMouse
    + WF.NoCollapse + WF.NoSavedSettings + WF.NoFocusOnAppearing
    + WF.NoBringToFrontOnFocus + WF.NoNavInputs + WF.NoNavFocus
    + (WF.NoBackground or 0)
  if pinned or not menu_open then
    local x, y = F.hud_anchor(sw, sh, box_w, box_h)
    imgui.SetNextWindowPos(imgui.ImVec2(x, y), imgui.Cond.Always)
    flags = flags + WF.NoMove
  end
  if not menu_open then flags = flags + WF.NoMouseInputs end
  imgui.SetNextWindowSize(imgui.ImVec2(box_w, box_h), imgui.Cond.Always)
  if imgui.SetNextWindowBgAlpha then imgui.SetNextWindowBgAlpha(0) end
  imgui.PushStyleColor(imgui.Col.WindowBg, F.vec4(0, 0, 0, 0))
  imgui.PushStyleColor(imgui.Col.Border, F.vec4(0, 0, 0, 0))
  imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12)
  imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0)
  imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
  imgui.Begin('fhelp-hud', nil, flags)
  local p = imgui.GetWindowPos()
  local sz = imgui.GetWindowSize()
  if sz and sz.x > 8 then net.bw = sz.x end
  if sz and sz.y > 8 then net.bh = sz.y end
  F.round_rect(p.x, p.y, box_w, box_h, F.col('panel', 236), F.col('text', 34), math.max(10, 14 * hs))
  imgui.GetWindowDrawList():AddRectFilled(imgui.ImVec2(p.x + 7 * hs, p.y + pad), imgui.ImVec2(p.x + 10 * hs, p.y + box_h - pad), F.col('accent'), 2)
  local ty = p.y + pad
  for i = 1, #rows do
    local col = F.col('text')
    if rows[i][2] == 'fps' then col = F.col('accent_hi')
    elseif rows[i][2] == 'sub' then col = F.col('text', 150) end
    F.text_at(font_main, 16, p.x + 18 * hs, ty, col, rows[i][1], nil, hs)
    ty = ty + line_h
  end
  if menu_open then
    imgui.SetCursorScreenPos(p)
    imgui.InvisibleButton('##huddrag', imgui.ImVec2(box_w, box_h))
    if imgui.IsItemHovered() then
      F.round_rect(p.x, p.y, box_w, box_h, F.col('accent', 0), F.col('accent', 160), math.max(10, 14 * hs))
    end
    if imgui.IsItemActive() and imgui.IsMouseDragging(0) then
      local md = imgui.GetIO().MouseDelta
      local nx = p.x + md.x
      local ny = p.y + md.y
      local max_x = math.max(0, sw - box_w)
      local max_y = math.max(0, sh - box_h)
      if nx < 0 then nx = 0 elseif nx > max_x then nx = max_x end
      if ny < 0 then ny = 0 elseif ny > max_y then ny = max_y end
      imgui.SetWindowPosVec2(imgui.ImVec2(nx, ny), imgui.Cond.Always)
      cfg.hud_place = 4
      cfg.hud_x = (max_x > 0) and (nx / max_x * 100) or 0
      cfg.hud_y = (max_y > 0) and (ny / max_y * 100) or 0
      if ui_hudx then ui_hudx[0] = cfg.hud_x end
      if ui_hudy then ui_hudy[0] = cfg.hud_y end
      net.force = false
      dirty = true
    end
  end
  if net.force then net.force = false end
  imgui.End()
  F.done_font(font_main)
  imgui.PopStyleVar(3)
  imgui.PopStyleColor(2)
end

-- Settings

function F.reset_stats()
  play.total, play.day, play.session = 0, 0, 0
  net.inn, net.outn, net.sin, net.sout = 0, 0, 0, 0
  dirty = true
  F.notify('Статистика сброшена', true)
end

function F.draw_settings_page()
  F.page_head('Настройки', 'Вид окна, сообщения и данные fHelper')
  F.card_begin('Окно', nil, 'ICON_FA_WINDOW_MAXIMIZE')
  if F.slider_row('opacity', 'Прозрачность', ui_opacity, 82, 100, '%.0f%%') then
    cfg.opacity = ui_opacity[0] / 100
    if cfg.opacity < 0.82 then cfg.opacity = 0.82 end
    dirty = true
  end
  if F.slider_row('scale', 'Масштаб меню', ui_scale, 85, 120, '%.0f%%') then
    cfg.scale = ui_scale[0] / 100
    if cfg.scale < 0.85 then cfg.scale = 0.85 end
    if cfg.scale > 1.2 then cfg.scale = 1.2 end
    dirty = true
  end
  imgui.Spacing()
  if F.button('Вернуть окно в центр##center', 230, 0) then
    cfg.x, cfg.y = -1, -1
    force_center = true
    maximized = false
    dirty = true
  end
  F.card_end()
  F.card_begin('Поведение', nil, 'ICON_FA_SLIDERS_H')
  if F.switch('notify', 'Сообщения в чат', cfg.notify == 1, 'Короткие ответы fHelper в чате игры') then
    cfg.notify = cfg.notify == 1 and 0 or 1
    if ui_notify then ui_notify[0] = cfg.notify == 1 end
    dirty = true
  end
  if F.switch('bg', 'Фоновый обзор скриптов', cfg.bg == 1, 'Список скриптов обновляется, пока меню открыто') then
    cfg.bg = cfg.bg == 1 and 0 or 1
    dirty = true
  end
  F.card_end()
  F.toast_settings()
  F.upd_card()
  F.card_begin('Данные', 'Всё хранится в moonloader\\config', 'ICON_FA_DATABASE')
  local m = F.mem_st or {}
  if m.free and m.free < F.MEM_WARN then F.hint_bad(F.mem_text() .. '. Перезапусти игру.')
  else F.hint(F.mem_text()) end
  imgui.Spacing()
  if F.button('Папка скриптов##sdir', 180, 0) then F.queue('dir') end
  F.same_if_fit(F.s(180))
  if F.button('Файл журнала##slog', 180, 0) then F.queue('log') end
  F.same_if_fit(F.s(220))
  if F.button('Сбросить статистику##sreset', 220, 0, 'danger') then
    F.ask('Сбросить время в игре и трафик? Пейдеи, бинды и заметки останутся.', 'Сбросить', 'fn', {fn = F.reset_stats})
  end
  F.card_end()
  F.card_begin('О fHelper', nil, 'ICON_FA_INFO_CIRCLE')
  local p = imgui.GetCursorScreenPos()
  local x = p.x
  x = x + F.chip(x, p.y, 'версия ' .. VER, 'on') + 8
  F.chip(x, p.y, F.proj().name, 'muted')
  F.advance(p, 1, F.s(24))
  F.hint('fHelper не включает читы, обход античита, скрытые автоматические действия и эксплуатацию уязвимостей.')
  F.hint('Команды уходят в чат только когда ты сам нажал отправить или свой бинд.')
  F.card_end()
end

-- Update notes. New entries go on top.

F.PATCH = {
  {'1.11.1', '08.11.2026', {
    {'add', 'Кнопка проверки обновления в шапке рядом с «Что нового»'},
    {'add', 'Если вышла новая версия, кнопка сразу предлагает обновиться и показывает, что изменилось'},
    {'add', 'Точка на кнопке, пока есть неустановленное обновление'},
  }},
  {'1.11.0', '08.11.2026', {
    {'add', 'Раздел «Эксперимент» → «Лавки»: fHelper запоминает товары и цены каждой лавки, которую ты открыл'},
    {'add', 'Поиск товара по всем записанным лавкам: самые дешёвые сверху, у скупки сверху те, кто платит больше'},
    {'add', 'Нажатие на найденный товар ставит метку на карте у этой лавки'},
  }},
  {'1.10.0', '07.11.2026', {
    {'add', 'Обновления с GitHub: при входе fHelper подсказывает, что вышла новая версия'},
    {'add', 'Установка по кнопке в настройках или командой /fupdate, файл проверяется перед заменой'},
    {'add', 'Старая версия сохраняется в moonloader\\fhelp_backup, версию можно пропустить'},
  }},
  {'1.9.1', '07.11.2026', {
    {'fix', 'Картинки предметов освобождаются при перезагрузке скрипта и смене проекта'},
    {'add', 'fHelper следит за памятью игры и заранее предупреждает, если её почти не осталось'},
    {'add', 'В настройках видно, сколько памяти занимает fHelper и сколько свободно у игры'},
  }},
  {'1.9.0', '07.11.2026', {
    {'add', 'Доходы: свой период с календарём, днём и временем начала и конца, быстрые недели и месяцы'},
    {'add', 'Период действует на все вкладки доходов, включая пейдеи'},
    {'add', 'График по часам, дням или месяцам и сравнение с прошлым таким же периодом'},
    {'add', 'Вкладка «Предметы»: что пришло в инвентарь и из хранилища, по периоду и с поиском'},
    {'add', 'Уведомления на экране о пейдее, доходах, расходах, предметах и сканере машин'},
    {'add', 'Настройки уведомлений: что показывать, место, размер, время, звук, порог суммы'},
    {'add', 'Кнопка «Скопировать отчёт» за выбранный период'},
  }},
  {'1.8.0', '07.11.2026', {
    {'add', 'Сканер машин в разделе «Эксперимент»: багажник, тюнинг, рамка, турбо и номер запоминаются для каждой машины'},
    {'add', 'Кнопка «Сканировать» над открытым багажником и команда /fcar'},
    {'add', 'Автоскан для отсканированных машин, поиск предмета по всем машинам и история изменений'},
  }},
  {'1.7.0', '07.11.2026', {
    {'add', 'Раздел «Эксперимент»: весь fHelper переключается между Arizona RP и Rodina RP'},
    {'add', 'Плашка с датой и серверным временем внизу по центру'},
    {'add', 'Раздел «Время» на вкладке «Экран»: что показывать, формат, пояс и место плашки'},
  }},
  {'1.6.0', '07.11.2026', {
    {'add', 'Вкладка «Библиотека» в разделе «Чат»: все предметы игры карточками с картинками'},
    {'add', 'Поиск и категории в библиотеке, описание предмета прямо в карточке'},
    {'add', 'У предметов в списке интеграций теперь видно картинку'},
  }},
  {'1.5.1', '07.11.2026', {
    {'add', 'Готовый бинд можно изменить: клавишу, тип и действие'},
  }},
  {'1.5.0', '07.11.2026', {
    {'add', 'Заметку можно закрепить на экране: при открытом меню, при закрытом или всегда'},
    {'add', 'Вкладка «Лог» в разделе «Чат»: весь чат с цветами идёт вживую'},
    {'add', 'Старые логи чата: список сессий и поиск сразу по всем файлам'},
  }},
  {'1.4.2', '06.11.2026', {
    {'fix', 'Плашка предмета из инвентаря больше не пропадает при вставке: она становится кодом :slot1_2:'},
    {'add', 'Интеграции, вставленные через Ctrl+V, сами попадают в список'},
  }},
  {'1.4.1', '06.11.2026', {
    {'fix', 'Интеграция больше не уходит как команда: /:item123: заменён на обычное сообщение'},
    {'fix', 'Вставка сама определяет форму: :item123:, символ из чата или [Название]'},
    {'fix', 'Поля «Чат» и бинды сами переключаются на «Сообщение» или «Команду» по тексту'},
    {'add', 'Поиск интеграций понимает вставленный код вида :item123:'},
  }},
  {'1.4.0', '05.11.2026', {
    {'fix', 'Наличные без лимита: сумма берётся из серверного события, а не из значения GTA с потолком'},
    {'add', 'Банк и депозит на главной, обновляются по чеку пейдея'},
    {'add', 'Доходы по вкладкам: обзор, пейдеи, работа, продажи, покупки, расходы, прочее'},
    {'add', 'История сделок: что, сколько штук, у кого, за сколько. Поиск и периоды'},
    {'add', 'Блок «Откуда деньги» и «Куда ушли» за выбранный период'},
    {'add', 'Вкладка «Чат»: отправка, избранное с папками и подписями, история, настройки'},
    {'add', 'Интеграции: предметы, лавки, телефоны, дома и бизнесы из чата, поиск по всем предметам'},
    {'add', 'Вставка интеграций в заметки, бинды, поле чата и чат игры'},
    {'add', 'Новый тип бинда «Сообщение»: уходит в чат как есть, без /'},
    {'add', 'Вкладка «Калькулятор» с историей и суффиксами к, кк, ккк, млн, млрд, процентами'},
    {'add', 'Отдельное окошко калькулятора: всегда на экране или только вместе с меню'},
    {'add', 'Команда /fcalc: ввод в окошке или расчёт прямо в чате'},
    {'add', 'Вкладка «Крафт»: ресурсы, цены, попытки, шанс, запас, прибыль и сохранённые рецепты'},
    {'add', 'Кнопка «Что нового» в шапке'},
    {'chg', 'Заметки: список слева, редактор справа, папки, поиск, автосохранение при переключении'},
    {'chg', 'Быстрые команды перенесены с главной во вкладку «Чат», акцент тоже там'},
    {'chg', 'История пейдеев хранит до 400 чеков вместо 40'},
    {'del', 'Блок быстрых команд с главной страницы'},
    {'fix', 'Длинные строки чека больше не обрезаются на полуслове'},
  }},
  {'1.3.0', '31.10.2026', {
    {'chg', 'Выровнены кнопки, текст, окна и всплывающие подсказки'},
    {'chg', 'Плавные углы без торчащих пикселей'},
    {'add', 'Меню закрывается по Esc'},
    {'fix', 'Разбор банковского чека: дивиденды, депозит и итог пейдея'},
  }},
  {'1.2.0', '31.10.2026', {
    {'chg', 'Новый дизайн всех разделов в той же палитре'},
    {'add', 'Плитки, переключатели, карточки, кнопка «Во весь экран»'},
    {'fix', 'Пинг, ID, здоровье, броня, розыск и районы показываются правильно'},
  }},
  {'1.1.0', '31.10.2026', {
    {'fix', 'Пустой акцент больше не уходит в чат'},
    {'fix', 'fHelper не поднимается сам после выключения из списка скриптов'},
    {'add', 'Клавиша скрытия убирает меню и плашку'},
  }},
}

F.PATCH_KIND = {
  add = {'Добавлено', 'accent_hi'},
  chg = {'Изменено', 'text'},
  fix = {'Исправлено', 'text'},
  del = {'Убрано', 'bad'},
}

function F.draw_patch_body()
  for i = 1, #F.PATCH do
    local v = F.PATCH[i]
    if i > 1 then imgui.Dummy(imgui.ImVec2(1, 8)) end
    local p = imgui.GetCursorScreenPos()
    local cw = F.chip(p.x, p.y, 'версия ' .. v[1], i == 1 and 'on' or 'muted')
    F.text_at(font_main, 16, p.x + cw + 10, p.y + F.s(3), F.col('text', 120), v[2])
    F.advance(p, 1, F.s(26))
    for j = 1, #v[3] do
      local row = v[3][j]
      local kind = F.PATCH_KIND[row[1]] or F.PATCH_KIND.chg
      imgui.TextColored(F.cvec(kind[2], 0.75), '%s', kind[1])
      imgui.SameLine(F.s(100))
      imgui.PushTextWrapPos(0)
      imgui.TextUnformatted(row[2])
      imgui.PopTextWrapPos()
    end
  end
end

-- Money

-- Until the first money event of a fresh install, ArzMarket's last value is the best guess.
function F.money_seed()
  if (tonumber(cfg.money_real) or -1) >= 0 or F.is_rod() then return end
  local f = io.open(F.cfg_dir() .. '\\ArzMarket\\ArzMarket.ini', 'r')
  if not f then return end
  for line in f:lines() do
    local n = tonumber(line:match('^realMoneyNow=(%d+)'))
    if n then
      cfg.money_real = n
      break
    end
  end
  f:close()
end

function F.fmt_saved(key)
  local n = tonumber(cfg[key]) or -1
  if n < 0 then return '—' end
  return F.fmt_money(n) or '—'
end

function F.cef_text(bs)
  raknetBitStreamIgnoreBits(bs, 8)
  if raknetBitStreamReadInt8(bs) ~= 17 then return nil end
  raknetBitStreamIgnoreBits(bs, 32)
  local len = tonumber(raknetBitStreamReadInt16(bs)) or 0
  local enc = tonumber(raknetBitStreamReadInt8(bs)) or 0
  if len < 0 then len = len + 65536 end
  if enc < 0 then enc = enc + 256 end
  if len <= 0 or len > 65000 then return nil end
  if enc ~= 0 then return raknetBitStreamDecodeString(bs, len + enc) end
  return raknetBitStreamReadString(bs, len)
end

-- The interface gets the real sum as event.player.updateMoney. GTA's own value is capped.
function F.cef_packet(bs)
  local ok, text = pcall(F.cef_text, bs)
  pcall(raknetBitStreamResetReadPointer, bs)
  if not ok or type(text) ~= 'string' then return end
  local fine, err = pcall(F.car_packet, text)
  if not fine then F.feed_err('машины', err) end
  fine, err = pcall(F.shop_packet, text)
  if not fine then F.feed_err('лавки', err) end
  local at = text:find('updateMoney', 1, true)
  if not at then return end
  local n = tonumber(text:match('(%d+)', at))
  if not n then return end
  if not F._money_seen then
    F._money_seen = true
    F.log_line('Наличные с сервера: ' .. (F.fmt_money(n) or tostring(n)))
  end
  if cfg.money_real ~= n then
    cfg.money_real = n
    stat_dirty = true
  end
  live.money = F.fmt_money(n) or live.money
end

-- Integrations

-- Arizona shows an item as the character U+50000 + id, an inventory slot as
-- U+60000 + a * 256 + b, money as U+1FC22. Taken from _chat.asi.
function F.int_pack(s)
  s = tostring(s or '')
  if not s:find('[\240-\244]') then return s end
  return (s:gsub('[\240-\244][\128-\191][\128-\191][\128-\191]', function(c)
    local a, b, d, e = c:byte(1, 4)
    local cp = (a % 8) * 262144 + (b % 64) * 4096 + (d % 64) * 64 + (e % 64)
    if cp >= 0x50000 and cp < 0x60000 then return ':item' .. tostring(cp - 0x50000) .. ':' end
    if cp >= 0x60000 and cp < 0x70000 then
      return string.format(':slot%d_%d:', math.floor((cp - 0x60000) / 256), cp % 256)
    end
    if cp == 0x1FC22 then return ':CASH:' end
    if cp == 0x1FC23 then return ':CASHV:' end
    if cp == 0x1FC1A then return ':buy:' end
    if cp == 0x1FC1B then return ':sell:' end
    return string.format(':u%X:', cp)
  end))
end

function F.int_has(s)
  s = tostring(s or '')
  for kind in s:gmatch(':(%a+)%d[%d_]*:') do
    if F.INT_KIND[kind] then return true end
  end
  return s:find(':CASH:', 1, true) or s:find(':CASHV:', 1, true) or s:find(':buy:', 1, true)
    or s:find(':sell:', 1, true) or s:find(':u%x%x%x%x+:') and true or false
end

-- nil = no integration inside, so the caller keeps the mode it has.
function F.int_form(s)
  s = F.trim(F.int_pack(s))
  if not F.int_has(s) then return nil end
  return s:sub(1, 1) == '/' and 'cmd' or 'say'
end

-- Names repeat in the item list, the one seen in chat is the right one.
function F.item_by_name(name)
  local low = F.lower_fast(F.trim(name))
  local list = F.ints or {}
  for i = #list, 1, -1 do
    local r = list[i]
    if r.kind == 'item' and F.lower_fast(F.item_name(r.id)) == low then return tonumber(r.id) end
  end
  return F.item_db().ids[low]
end

function F.int_token(name)
  name = F.trim(name)
  local n = name:match('^Тел%.%s*(%d+)$')
  if n then return ':call' .. n .. ':' end
  n = name:match('^Лавка №%s*(%d+)$')
  if n then return ':lavka' .. n .. ':' end
  n = name:match('^Бизнес №%s*(%d+)$')
  if n then return ':biz' .. n .. ':' end
  n = name:match('^Дом №%s*(%d+)$')
  if n then return ':house' .. n .. ':' end
  n = name:match('^Слот (%d+_%d+)$')
  if n then return ':slot' .. n .. ':' end
  n = name:match('^Предмет #(%d+)$') or F.item_by_name(name)
  if n then return ':item' .. n .. ':' end
end

-- Pasted text: special characters and [Name] become :item123: and the like.
function F.int_unname(s)
  s = F.int_pack(s)
  if not s:find('[', 1, true) then return s end
  return (s:gsub('%[([^%[%]]+)%]', F.int_token))
end

function F.lower_fast(s)
  s = tostring(s or ''):lower()
  return (s:gsub('\208[\129\144-\175]', RU_LOW))
end

function F.item_db()
  if F._items then return F._items end
  local db = {names = {}, list = {}, ids = {}}
  F._items = db
  if F.is_rod() then return F.item_db_lib(db) end
  local dir = F.wd() .. '\\ArzMarket'
  local best, best_n = nil, -1
  if lfs_ok then
    pcall(function()
      for name in lfs.dir(dir) do
        local n = tonumber(name:match('^items_data(%d+)%.json$'))
        if n and n > best_n then
          best, best_n = dir .. '\\' .. name, n
        end
      end
    end)
  end
  if not best then return db end
  local f = io.open(best, 'rb')
  if not f then return db end
  local data = f:read('*a') or ''
  f:close()
  for id, name in data:gmatch('"(%d+)"%s*:%s*"([^"]*)"') do
    id = tonumber(id)
    if id and name ~= '' and name ~= 'DELETED' then
      db.names[id] = name
      db.list[#db.list + 1] = {id = id, name = name, low = F.lower_fast(name)}
    end
  end
  table.sort(db.list, function(a, b) return a.id < b.id end)
  for i = 1, #db.list do
    local it = db.list[i]
    db.ids[it.low] = db.ids[it.low] or it.id
  end
  return db
end

-- ArzMarket has no Rodina list, the names come from the pack made of the game's own files.
function F.item_db_lib(db)
  local src = F.lib_db().by_id
  for id, it in pairs(src) do
    local low = F.lower_fast(it.name)
    db.names[id] = it.name
    db.list[#db.list + 1] = {id = id, name = it.name, low = low}
  end
  table.sort(db.list, function(a, b) return a.id < b.id end)
  for i = 1, #db.list do
    local it = db.list[i]
    db.ids[it.low] = db.ids[it.low] or it.id
  end
  return db
end

function F.item_name(id)
  id = tonumber(id) or 0
  return F.item_db().names[id] or ('Предмет #' .. tostring(id))
end

function F.item_find(q)
  q = F.lower_fast(F.trim(q or ''))
  local pasted = q:match('^:item(%d+):$')
  if pasted then q = pasted end
  if #q < 2 and not pasted then return {} end
  if F._find_q == q then return F._find_res end
  local out, list = {}, F.item_db().list
  local exact = tonumber(q)
  for i = 1, #list do
    local it = list[i]
    if it.id == exact then table.insert(out, 1, it)
    elseif it.low:find(q, 1, true) then out[#out + 1] = it end
    if #out >= 60 then break end
  end
  F._find_q, F._find_res = q, out
  return out
end

F.INT_KIND = {
  item = 'Предмет', slot = 'Слот', lavka = 'Лавка', biz = 'Бизнес', house = 'Дом', call = 'Телефон',
}

function F.int_title(kind, id)
  if kind == 'item' then return F.item_name(id) end
  if kind == 'lavka' then return 'Лавка №' .. id end
  if kind == 'biz' then return 'Бизнес №' .. id end
  if kind == 'house' then return 'Дом №' .. id end
  if kind == 'call' then return 'Тел. ' .. id end
  if kind == 'slot' then return 'Слот ' .. id end
  return kind .. id
end

function F.int_human(s, bare)
  s = F.int_pack(s)
  if not s:find(':', 1, true) then return s end
  s = s:gsub(':CASHV:', 'VC$'):gsub(':CASH:', '$'):gsub(':u%x%x%x%x+:', '')
  -- :gem: and the like are emoji names, the font here cannot draw them.
  s = s:gsub(':sell:', 'SELL'):gsub(':buy:', 'BUY'):gsub(':%l[%l_]*:', '')
  s = s:gsub(':(%a+)(%d[%d_]*):', function(kind, id)
    if F.INT_KIND[kind] then
      local title = F.int_title(kind, id)
      if bare then return title end
      return '[' .. title .. ']'
    end
  end)
  return s
end

function F.int_preview(text)
  text = F.int_pack(text or '')
  if not F.int_has(text) then return end
  F.hint('В чате будет: ' .. F.int_human(text))
end

function F.int_note(token, from, stamp)
  local kind, id = token:match('^:(%a+)(%d[%d_]*):$')
  if not kind or not F.INT_KIND[kind] then return false end
  F.ints = F.ints or {}
  local list = F.ints
  for i = #list, 1, -1 do
    if list[i].token == token then
      table.remove(list, i)
      break
    end
  end
  list[#list + 1] = {token = token, kind = kind, id = id, t = stamp or os.date('%d.%m %H:%M'), from = from or ''}
  -- Phone numbers come in every ad, they must not push items out.
  local same = 0
  for i = #list, 1, -1 do
    if list[i].kind == kind then
      same = same + 1
      if same > (kind == 'item' and 200 or 60) then table.remove(list, i) end
    end
  end
  F.int_dirty = true
  return true
end

function F.int_feed(text)
  if not text:find(':', 1, true) then return end
  local raw = F.int_pack(F.game_text(text))
  if not raw:find(':%a+%d') then return end
  local line
  for token in raw:gmatch(':%a+%d[%d_]*:') do
    if F.INT_KIND[token:match('^:(%a+)')] then
      line = line or F.utf_cut(F.trim(F.int_human(raw)), 130)
      F.int_note(token, line)
    end
  end
end

function F.int_load()
  F.ints = {}
  for _, row in ipairs(F.read_lines('fhelp_ints.txt')) do
    local token, t, from = row:match('^([^|]*)|([^|]*)|(.*)$')
    if token then F.int_note(token, from, t) end
  end
  F.int_dirty = false
end

function F.int_save()
  local rows = {}
  local list = F.ints or {}
  for i = 1, #list do
    local r = list[i]
    rows[#rows + 1] = r.token .. '|' .. r.t .. '|' .. (r.from:gsub('|', '/'))
  end
  F.write_lines('fhelp_ints.txt', rows)
  F.int_dirty = false
end

function F.buf_add(buf, cap, text)
  local cur = F.buf_get(buf)
  if cur ~= '' and not cur:find('%s$') then cur = cur .. ' ' end
  F.buf_set(buf, cur .. text .. ' ', cap)
end

function F.to_game_chat(text)
  text = F.int_pack(F.trim(tostring(text or ''):match('^[^\n]*') or ''))
  if text == '' or not isSampAvailable() then return end
  F.close_menu()
  pcall(sampSetChatInputEnabled, true)
  pcall(sampSetChatInputText, F.to_cp(text))
end

function F.int_put(where, token)
  if where == 'chat' then
    F.buf_add(ui_cmd, 180, token)
    if F.buf_get(ui_cmd):sub(1, 1) ~= '/' then F.chat_mode = 'say' end
    F.chat_tab = 'send'
    page = 'chat'
  elseif where == 'fav' then
    F.buf_add(ui.fav_text, 240, token)
    F.chat_tab = 'favs'
    page = 'chat'
  elseif where == 'note' then
    F.note_insert(token)
    page = 'notes'
  elseif where == 'bind' then
    F.buf_add(ui_bind, 240, token)
    if bind_kind ~= 'chat' then bind_kind = 'say' end
    page = 'binds'
  elseif where == 'game' then
    F.to_game_chat(token)
  end
  F.int_pick = nil
end

function F.int_remember(raw)
  local n = 0
  for token in raw:gmatch(':%a+%d[%d_]*:') do
    if F.int_note(token, 'Из буфера обмена') then n = n + 1 end
  end
  return n
end

function F.int_from_clip()
  local raw = F.clip_text()
  local n = F.int_remember(raw)
  if n > 0 then F.notify('Найдено интеграций: ' .. n, true)
  elseif raw == '' then F.notify('Буфер пуст', true)
  else
    F.notify('В буфере нет интеграций', true)
    F.log_line('Буфер без интеграций: ' .. F.utf_cut(raw, 60))
  end
end

-- Ledger

F.PAY_MAX = 400
F.LED_MAX = 6000

F.LED_CAT = {
  work = {'Работа', 'ICON_FA_BRIEFCASE'},
  sell = {'Продажи', 'ICON_FA_TAGS'},
  buy = {'Покупки', 'ICON_FA_SHOPPING_CART'},
  spend = {'Расходы', 'ICON_FA_RECEIPT'},
  other = {'Прочее', 'ICON_FA_HAND_HOLDING_USD'},
}

function F.led_num(s)
  return tonumber((tostring(s or ''):gsub('[%.,%s]', '')))
end

function F.led_state()
  if not F.led then F.led = {list = {}, rev = 0} end
  return F.led
end

function F.led_line(r)
  return table.concat({
    r.t, r.cat, string.format('%.0f', r.amount), r.cur or 'sa', tostring(r.qty or 0),
    (tostring(r.who or ''):gsub('|', '/')), (tostring(r.text or ''):gsub('|', '/')),
  }, '|')
end

function F.led_load()
  local st = F.led_state()
  st.list = {}
  local rows = F.read_lines('fhelp_ledger.txt')
  for i = math.max(1, #rows - F.LED_MAX + 1), #rows do
    local t, cat, amount, cur, qty, who, text = rows[i]:match('^(.-)|(%a+)|(%d+)|(%a+)|(%d+)|(.-)|(.*)$')
    if t and F.LED_CAT[cat] then
      st.list[#st.list + 1] = {
        t = t, cat = cat, amount = tonumber(amount) or 0, cur = cur,
        qty = tonumber(qty) or 0, who = who, text = text,
      }
    end
  end
  if #rows > F.LED_MAX + 1000 then
    local out = {}
    for i = 1, #st.list do out[i] = F.led_line(st.list[i]) end
    F.write_lines('fhelp_ledger.txt', out)
  end
  st.rev = st.rev + 1
end

function F.led_add(cat, amount, text, qty, who, cur)
  local st = F.led_state()
  local r = {
    t = os.date('%Y-%m-%d %H:%M:%S'), cat = cat, amount = amount, cur = cur or 'sa',
    qty = tonumber(qty) or 0, who = who or '', text = F.utf_cut(text or '', 150),
  }
  st.list[#st.list + 1] = r
  while #st.list > F.LED_MAX do table.remove(st.list, 1) end
  st.rev = st.rev + 1
  pcall(function()
    F.mkdir(F.cfg_dir())
    local f = io.open(F.lines_path('fhelp_ledger.txt'), 'a')
    if f then
      f:write((F.led_line(r):gsub('[\r\n]', ' ')) .. '\n')
      f:close()
    end
  end)
  pcall(F.toast_led, r)
end

-- Phrases are taken from real Arizona chat logs. Specific rules go first.
function F.led_rules()
  if F._led_rules then return F._led_rules end
  local M = '%$([%d][%d%.,]*)'
  local n = F.led_num
  local r = {}
  local function add(pat, fn) r[#r + 1] = {pat, fn} end
  local function simple(pat, cat, text)
    add(pat, function(a) return cat, n(a), text end)
  end
  -- Trades
  add('(%S+) купил у вас (.-) %((%d+) шт%.?%), вы получили ' .. M, function(who, item, q, a)
    return 'sell', n(a), item, tonumber(q), who
  end)
  add('(%S+) купил у вас (.-), вы получили ' .. M, function(who, item, a)
    return 'sell', n(a), item, 1, who
  end)
  add('Вы успешно продали (.-) %((%d+) шт%.?%) торговцу (%S-), с продажи получили ' .. M, function(item, q, who, a)
    return 'sell', n(a), item, tonumber(q), who
  end)
  add('Вы успешно продали (.-) торговцу (%S-), с продажи получили ' .. M, function(item, who, a)
    return 'sell', n(a), item, 1, who
  end)
  add('Вы успешно купили (.-) %((%d+) шт%.?%) у (%S+) за ' .. M, function(item, q, who, a)
    return 'buy', n(a), item, tonumber(q), who
  end)
  add('Вы успешно купили (.-) у (%S+) за ' .. M, function(item, who, a)
    return 'buy', n(a), item, 1, who
  end)
  add('Вы продали ваше транспортное средство за ' .. M, function(a)
    return 'sell', n(a), 'Транспорт'
  end)
  add('Вы успешно вернули номерной знак (.-) за ' .. M, function(_, a)
    return 'sell', n(a), 'Возврат номерного знака'
  end)
  add('Вы совершили обмен (%S+ %S+) на ' .. M, function(what, a)
    return 'sell', n(a), 'Обмен ' .. what
  end)
  add('За обмен вы получили ' .. M, function(a) return 'sell', n(a), 'Обмен валюты' end)
  add('Вы успешно обменяли ' .. M .. ' на (%d[%d%s]*) AZ', function(a, az)
    return 'buy', n(a), 'AZ Coins: ' .. F.trim(az)
  end)
  add('Вы успешно обменяли %$[%d][%d%.,]* на ' .. M, function(a) return 'sell', n(a), 'Обмен VC$' end)
  add('вы выкупили транспорт \'(.-)\' со ставкой ' .. M, function(item, a) return 'buy', n(a), item end)
  add('Вы выкупили транспорт \'(.-)\' со ставкой ' .. M, function(item, a) return 'buy', n(a), item end)
  add('Вы купили (.-) за ' .. M, function(item, a) return 'buy', n(a), (item:gsub('^ларец ', '')) end)
  add('Вы приобрели (.-) за ' .. M, function(item, a) return 'buy', n(a), item end)
  -- Work
  simple('%[Патрулирование%] Вы заработали %+?' .. M, 'work', 'Патрулирование')
  simple('Начислено ' .. M .. ' за дежурство', 'work', 'Дежурство на посту')
  add('Сэт (.-)! Ваш бонус за (.-) %+%d+ процентов, вы получили ' .. M, function(set, what, a)
    return 'work', n(a), 'Бонус сета ' .. set .. ': ' .. what
  end)
  add('успешно продали бочку с ([%d%.]+) литров нефти и получили ' .. M, function(_, a)
    return 'work', n(a), 'Нефть: продажа бочки'
  end)
  simple('доплату от электрокомпании за бочку в размере ' .. M, 'work', 'Нефть: доплата электрокомпании')
  simple('Ваша зарплата за рейс: ' .. M, 'work', 'Рейс: зарплата')
  add('Премия за работу таксистом: ' .. M .. ' %(%+' .. M, function(a, b)
    return 'work', (n(a) or 0) + (n(b) or 0), 'Такси: премия'
  end)
  simple('Премия за работу таксистом: ' .. M, 'work', 'Такси: премия')
  simple('%[Такси%] Клиент оплатил: ' .. M, 'work', 'Такси: клиент')
  simple('Вы доставили пиццу, заработано %+?' .. M, 'work', 'Доставка пиццы')
  add('Вы получили премию за \'(.-)\' в размере ' .. M, function(what, a)
    return 'work', n(a), 'Премия: ' .. what
  end)
  simple('Вы получили премию от мэра: ' .. M, 'work', 'Премия от мэра')
  simple('успешной поимкой преступника! Вы получили: ' .. M, 'work', 'Поимка преступника')
  add('Вы завершили работу (.-), заработано за смену: ' .. M, function(what, a)
    return 'work', n(a), 'Смена: ' .. what
  end)
  simple('Вы заработали %+?' .. M, 'work', 'Заработок')
  simple('заработано %+?' .. M, 'work', 'Заработок')
  -- Spending
  add('Вы сняли деньги с депозитного счета ' .. M .. '%.? Комиссия: ' .. M, function(_, b)
    return 'spend', n(b), 'Комиссия: снятие с депозита'
  end)
  add('Вы сняли со счета ' .. M .. '%.? Получено на руки: ' .. M, function(a, b)
    return 'spend', (n(a) or 0) - (n(b) or 0), 'Комиссия: снятие со счёта'
  end)
  simple('Вы оплатили налоги на сумму: ' .. M, 'spend', 'Налоги')
  simple('Вы оплатили все налоги на сумму: ' .. M, 'spend', 'Налоги')
  add('Вы оплатили ' .. M .. ' наличными за (.-)%.?$', function(a, what)
    return 'spend', n(a), 'Оплата: ' .. what
  end)
  simple('Стоимость услуги составила ' .. M, 'spend', 'Услуга')
  add('Вы успешно продлили аренду (.-) за ' .. M, function(what, a)
    return 'spend', n(a), 'Аренда ' .. (what:gsub('^своего ', ''))
  end)
  simple('С вас взяли ' .. M, 'spend', 'Штраф')
  add('Вас вылечил медик (%S+) за ' .. M, function(who, a) return 'spend', n(a), 'Лечение', 0, who end)
  simple('Вам начислен штраф на восстановление: ' .. M, 'spend', 'Штраф: восстановление транспорта')
  simple('оплатили штраф ' .. M, 'spend', 'Штраф')
  add('%[Авто%-сервис%] (.-) завершены, потрачено: ' .. M, function(what, a)
    return 'spend', n(a), 'Автосервис: ' .. what
  end)
  simple('Механики взяли за работу: ' .. M, 'spend', 'Ремонт транспорта')
  simple('%[Такси%] Вы оплатили: ' .. M, 'spend', 'Такси: поездка')
  simple('Вы успешно оплатили все долги в размере ' .. M, 'spend', 'Долги')
  simple('Вы пожертвовали ' .. M, 'spend', 'Пожертвование')
  simple('С Вашего банковского счета было снято ' .. M .. ' на улучшение', 'spend', 'Улучшение депозита')
  add('Вы передали ' .. M .. ' (%S+)', function(a, who) return 'spend', n(a), 'Передача денег', 0, who end)
  add('Вы перевели ' .. M .. ' игроку (.-) на счет', function(a, who) return 'spend', n(a), 'Перевод', 0, who end)
  -- Other income
  add('Вам поступил перевод на ваш счет в размере ' .. M .. ' от жителя (%S+)', function(a, who)
    return 'other', n(a), 'Перевод', 0, (who:gsub('%(%d+%)$', ''))
  end)
  simple('Получена разовая семейная премия: ' .. M, 'other', 'Семейная премия')
  simple('Вы открыли пачку с деньгами, там было: ' .. M, 'other', 'Пачка денег')
  simple('в количестве ' .. M, 'other', 'Игровая валюта')
  add('Вы получили %+' .. M .. ' на банковский счет', function(a) return 'other', n(a), 'На банковский счёт' end)
  add('Вы получили %+' .. M .. ' за (.+)$', function(a, why)
    return 'other', n(a), (F.trim((why:gsub('%b()', ''))):gsub('[%.%s]+$', ''))
  end)
  simple('Вы получили %+' .. M, 'other', 'Бонус')
  simple('Вам начислено ' .. M, 'other', 'Начисление')
  F._led_rules = r
  return r
end

-- Player chat, ads and radio hold the same phrases, only system lines count.
function F.led_system(raw)
  if raw:find('%w%[%d+%]') then return false end
  -- Nicks on Rodina are written in Russian letters.
  if F.is_rod() and raw:find('[\128-\255]%[%d+%]') then return false end
  if raw:sub(1, 1) == '|' then return false end
  if raw:find('Тел:', 1, true) or raw:find('MesaBot', 1, true) then return false end
  if raw:find('[Семья', 1, true) or raw:find('[Family', 1, true) then return false end
  if raw:find('[Донат-магазин', 1, true) then return false end
  return true
end

function F.led_parse(raw)
  raw = F.int_human(raw:gsub(':u%x%x%x%x+:', ''), true)
  raw = F.trim(raw:gsub('VC%$', '$'))
  if raw == '' or not F.led_system(raw) then return nil end
  local rules = F.led_rules()
  for i = 1, #rules do
    local a, b, c, d = raw:match(rules[i][1])
    if a then
      local cat, amount, text, qty, who = rules[i][2](a, b, c, d)
      if cat and amount and amount > 0 then return cat, amount, text, qty, who end
      return nil
    end
  end
  return nil
end

function F.led_feed(text)
  if not F.is_rod() and not (text:find(':CASH', 1, true) or text:find('$', 1, true)) then return end
  if F.pay_took or F.pay_state().open then return end
  local raw = F.proj_text(F.game_text(text))
  if raw == '' then return end
  local vc = raw:find(':CASHV:', 1, true) and not raw:find(':CASH:', 1, true)
  local cat, amount, what, qty, who = F.led_parse(raw)
  if cat then F.led_add(cat, amount, what, qty, who, vc and 'vc' or 'sa') end
end

F.PERIODS = {
  {'today', 'Сегодня'}, {'yday', 'Вчера'}, {'week', '7 дней'}, {'month', '30 дней'}, {'all', 'Всё время'},
  {'range', 'Свой период', 'Выбери день и время начала и конца'},
}

-- Periods compare full stamps "YYYY-MM-DD HH:MM:SS", so a range can start mid-day.
function F.period_range(key)
  local now = os.time()
  local today = os.date('%Y-%m-%d', now)
  local function span(a, b) return a .. ' 00:00:00', b .. ' 23:59:59' end
  if key == 'today' then return span(today, today) end
  if key == 'yday' then
    local d = os.date('%Y-%m-%d', now - 86400)
    return span(d, d)
  end
  if key == 'week' then return span(os.date('%Y-%m-%d', now - 6 * 86400), today) end
  if key == 'month' then return span(os.date('%Y-%m-%d', now - 29 * 86400), today) end
  if key == 'range' then
    F.rng_fix()
    return F.rng_text(cfg.inc_from, false), F.rng_text(cfg.inc_to, true)
  end
  return '', '9999'
end

function F.led_stats(from, to)
  local led, pay = F.led_state(), F.pay_state()
  local key = from .. '|' .. to .. '|' .. led.rev .. '|' .. (pay.rev or 0) .. '|' .. #pay.list
  F._stats_c = F._stats_c or {}
  if F._stats_c[key] then return F._stats_c[key] end
  local s = {pay = 0, pay_n = 0, work = 0, sell = 0, buy = 0, spend = 0, other = 0, ops = 0, days = {}, hours = {}}
  local gin, gout = {}, {}
  -- Day and hour sums for the chart.
  local function bucket(t, inc, exp)
    local d, h = t:sub(1, 10), t:sub(1, 13)
    local b = s.days[d] or {inc = 0, exp = 0}
    s.days[d] = b
    b.inc, b.exp = b.inc + inc, b.exp + exp
    local hb = s.hours[h] or {inc = 0, exp = 0}
    s.hours[h] = hb
    hb.inc, hb.exp = hb.inc + inc, hb.exp + exp
  end
  local function add(map, name, sum)
    if not map[name] then map[name] = {name = name, sum = 0, n = 0} end
    map[name].sum = map[name].sum + sum
    map[name].n = map[name].n + 1
  end
  for i = 1, #pay.list do
    local r = pay.list[i]
    local d = r.t or ''
    if d >= from and d <= to then
      s.pay = s.pay + (r.total or 0)
      s.pay_n = s.pay_n + 1
      bucket(d, r.total or 0, 0)
      for j = 1, #(r.items or {}) do
        local it = r.items[j]
        if it.kind == 'delta' or it.kind == 'extra' then
          local low = F.lower_fast(it.reason)
          local name = it.reason
          if low:find('в банке', 1, true) then name = 'Зарплата'
          elseif low:find('на депозите', 1, true) then name = 'Депозит' end
          add(gin, name, it.amount)
        end
      end
    end
  end
  for i = 1, #led.list do
    local r = led.list[i]
    local d = r.t
    if d >= from and d <= to and r.cur == 'sa' then
      s[r.cat] = s[r.cat] + r.amount
      s.ops = s.ops + 1
      if r.cat == 'buy' or r.cat == 'spend' then
        add(gout, r.text, r.amount)
        bucket(d, 0, r.amount)
      else
        add(gin, r.text, r.amount)
        bucket(d, r.amount, 0)
      end
    end
  end
  local function sorted(map)
    local list = {}
    for _, v in pairs(map) do list[#list + 1] = v end
    table.sort(list, function(a, b) return a.sum > b.sum end)
    return list
  end
  s.gin, s.gout = sorted(gin), sorted(gout)
  s.inc = s.pay + s.work + s.sell + s.other
  s.exp = s.buy + s.spend
  -- The current range and the one before it are asked every frame.
  local n = 0
  for _ in pairs(F._stats_c) do n = n + 1 end
  if n > 6 then F._stats_c = {} end
  F._stats_c[key] = s
  return s
end

function F.led_view(cat, from, to, q)
  local led = F.led_state()
  local key = tostring(cat) .. '|' .. from .. '|' .. to .. '|' .. q .. '|' .. led.rev
  if F._view_key == key then return F._view end
  local low = F.lower_fast(q)
  local out = {rows = {}, sum = 0, n = 0}
  for i = #led.list, 1, -1 do
    local r = led.list[i]
    local d = r.t
    if (not cat or r.cat == cat) and d >= from and d <= to then
      if low == '' or F.lower_fast(r.text .. ' ' .. r.who):find(low, 1, true) then
        out.n = out.n + 1
        if r.cur == 'sa' then out.sum = out.sum + r.amount end
        if #out.rows < 200 then out.rows[#out.rows + 1] = r end
      end
    end
  end
  F._view_key, F._view = key, out
  return out
end

function F.share_row(name, sum, share, col)
  local p = imgui.GetCursorScreenPos()
  local w = F.inner_w()
  local h = F.s(36)
  local money = F.fmt_money(sum) or '—'
  local mw = F.text_w(font_main, money)
  F.text_at(font_main, 16, p.x, p.y, F.col('text', 205), F.fit_text(font_main, name, w - mw - 20))
  F.text_at(font_main, 16, p.x + w - mw, p.y, F.col('text'), money)
  local by = p.y + F.s(23)
  F.round_rect(p.x, by, w, 4, F.col('text', 16), nil, 2)
  if share > 0 then F.round_rect(p.x, by, math.max(4, w * math.min(1, share)), 4, col, nil, 2) end
  F.advance(p, w, h)
end

function F.led_row(r, i)
  local p = imgui.GetCursorScreenPos()
  local w = F.inner_w()
  local h = F.s(48)
  if i % 2 == 0 then F.round_rect(p.x - 6, p.y, w + 12, h, F.col('side', 90), nil, 8) end
  local out = r.cat == 'buy' or r.cat == 'spend'
  local money = F.fmt_money(r.amount) or '—'
  if r.cur == 'vc' then money = money:gsub('^%$', 'VC$') end
  money = (out and '-' or '+') .. money
  local mw = F.text_w(font_bold, money)
  local title = r.text
  if (r.qty or 0) > 1 then title = title .. '  ×' .. tostring(r.qty) end
  F.text_at(font_main, 16, p.x + 4, p.y + F.s(5), F.col('text', 230), F.fit_text(font_main, title, w - mw - 24))
  local sub = F.short_stamp(r.t)
  if (r.who or '') ~= '' then sub = sub .. '  ·  ' .. r.who end
  if not F.inc_tab or F.inc_tab == 'over' then sub = sub .. '  ·  ' .. F.LED_CAT[r.cat][1] end
  F.text_at(font_main, 16, p.x + 4, p.y + F.s(26), F.col('text', 120), F.fit_text(font_main, sub, w - mw - 24))
  F.text_at(font_bold, 18, p.x + w - mw - 4, p.y + (h - F.s(18)) / 2 - 1, out and F.col('bad') or F.col('accent_hi'), money)
  F.advance(p, w, h - 4)
end

function F.income_over(from, to)
  local s = F.led_stats(from, to)
  F.card_begin('Счета сейчас', nil, 'ICON_FA_WALLET')
  F.tile_grid('acc', {
    {'ICON_FA_WALLET', 'Наличные', live.money},
    {'ICON_FA_UNIVERSITY', 'Банк', F.fmt_saved('bank')},
    {'ICON_FA_PIGGY_BANK', 'Депозит', F.fmt_saved('depo')},
  }, 200)
  F.card_end()
  F.card_begin('Итоги периода', nil, 'ICON_FA_CHART_LINE')
  F.tile_grid('sum', {
    {'ICON_FA_ARROW_DOWN', 'Пришло', F.fmt_money(s.inc)},
    {'ICON_FA_ARROW_UP', 'Ушло', F.fmt_money(s.exp)},
    {'ICON_FA_EQUALS', 'Чистыми', F.fmt_money(s.inc - s.exp)},
    {'ICON_FA_COINS', 'Пейдеи: ' .. s.pay_n, F.fmt_money(s.pay)},
    {'ICON_FA_BRIEFCASE', 'Работа', F.fmt_money(s.work)},
    {'ICON_FA_TAGS', 'Продажи', F.fmt_money(s.sell)},
    {'ICON_FA_SHOPPING_CART', 'Покупки', F.fmt_money(s.buy)},
    {'ICON_FA_RECEIPT', 'Расходы', F.fmt_money(s.spend)},
    {'ICON_FA_HAND_HOLDING_USD', 'Прочее', F.fmt_money(s.other)},
  }, 190)
  local pf, pt = F.prev_range(from, to)
  if pf then
    local ps = F.led_stats(pf, pt)
    F.hint('Прошлый такой же период: пришло ' .. (F.fmt_money(ps.inc) or '—') .. F.pct_text(s.inc, ps.inc)
      .. ', ушло ' .. (F.fmt_money(ps.exp) or '—') .. F.pct_text(s.exp, ps.exp))
  end
  imgui.Spacing()
  if F.button('Скопировать отчёт##increp', 200, 0) then F.note_copy(F.income_report(s, from, to)) end
  if imgui.IsItemHovered() then F.tip('Итоги, статьи доходов и расходов текстом') end
  F.card_end()
  F.income_chart(s, from, to)
  local function block(title, icon, list, total, col, none)
    F.card_begin(title, nil, icon)
    if #list == 0 then F.hint(none) end
    for i = 1, math.min(#list, 12) do
      F.share_row(list[i].name, list[i].sum, total > 0 and list[i].sum / total or 0, col)
    end
    if #list > 12 then F.hint('И ещё статей: ' .. (#list - 12)) end
    F.card_end()
  end
  block('Откуда деньги', 'ICON_FA_ARROW_DOWN', s.gin, s.inc, F.col('accent'), 'За этот период доходов нет.')
  block('Куда ушли', 'ICON_FA_ARROW_UP', s.gout, s.exp, F.col('bad'), 'За этот период расходов нет.')
  local view = F.led_view(nil, from, to, '')
  F.card_begin('Последние операции', nil, 'ICON_FA_HISTORY')
  if #view.rows == 0 then F.hint('Операции появятся здесь, когда они пройдут в чате.') end
  for i = 1, math.min(#view.rows, 12) do F.led_row(view.rows[i], i) end
  F.card_end()
end

function F.income_list(cat, from, to)
  local info = F.LED_CAT[cat]
  F.field('##ledq', 'Поиск по названию или нику', ui.led_q, 80, F.inner_w(), 'led_q')
  imgui.Spacing()
  local view = F.led_view(cat, from, to, F.trim(F.buf_get(ui.led_q)))
  local label = (cat == 'buy' or cat == 'spend') and 'Всего потрачено' or 'Всего получено'
  F.tile_grid('led', {
    {info[2], label, F.fmt_money(view.sum)},
    {'ICON_FA_HISTORY', 'Записей', tostring(view.n)},
  }, 240)
  imgui.Spacing()
  F.card_begin(info[1], view.n > #view.rows and ('Показаны последние ' .. #view.rows) or nil, info[2])
  if #view.rows == 0 then F.empty(info[2], 'Записей нет', 'Смени период или дождись новых операций') end
  for i = 1, #view.rows do F.led_row(view.rows[i], i) end
  F.card_end()
end

function F.draw_income()
  F.page_head('Доходы', 'Пейдеи, работа, сделки, расходы и предметы: что пришло и куда ушло')
  F.inc_tab = F.inc_tab or 'over'
  if not F.inc_period then
    local row = F.PERIODS[math.floor(cfg.inc_per or 1)] or F.PERIODS[1]
    F.inc_period = row[1]
  end
  local tab = F.segment('inc', {
    {'over', 'Обзор'}, {'pay', 'Пейдеи'}, {'work', 'Работа'}, {'sell', 'Продажи'},
    {'buy', 'Покупки'}, {'spend', 'Расходы'}, {'other', 'Прочее'}, {'items', 'Предметы'},
  }, F.inc_tab)
  if tab then F.inc_tab = tab end
  imgui.Spacing()
  local period = F.pill_row('##per', F.PERIODS, F.inc_period)
  if period then
    F.inc_period = period
    for i = 1, #F.PERIODS do
      if F.PERIODS[i][1] == period then cfg.inc_per = i end
    end
    if period == 'range' and not F.rng_edit then F.rng_open('from') end
    dirty = true
  end
  local from, to = F.period_range(F.inc_period)
  if F.inc_period == 'range' then F.rng_card()
  else F.hint(F.range_label(from, to)) end
  imgui.Spacing()
  if F.inc_tab == 'pay' then F.income_paydays(from, to)
  elseif F.inc_tab == 'items' then F.income_items(from, to)
  elseif F.inc_tab == 'over' then F.income_over(from, to)
  else F.income_list(F.inc_tab, from, to) end
end

-- Own range: numbers YYYYMMDDHHMM in the config.

function F.rng_parts(n)
  n = math.floor(tonumber(n) or 0)
  local mi = n % 100
  n = math.floor(n / 100)
  local h = n % 100
  n = math.floor(n / 100)
  local d = n % 100
  n = math.floor(n / 100)
  return math.floor(n / 100), n % 100, d, h, mi
end

function F.rng_make(y, m, d, h, mi)
  return (((y * 100 + m) * 100 + d) * 100 + h) * 100 + mi
end

function F.month_days(y, m)
  local ny, nm = y, m + 1
  if nm > 12 then ny, nm = y + 1, 1 end
  local t = os.time({year = ny, month = nm, day = 1, hour = 12})
  return tonumber(os.date('%d', t - 86400))
end

function F.rng_valid(n)
  local y, m, d, h, mi = F.rng_parts(n)
  if y < 2000 or y > 2100 or m < 1 or m > 12 or h > 23 or mi > 59 then return false end
  return d >= 1 and d <= F.month_days(y, m)
end

function F.rng_text(n, last)
  local y, m, d, h, mi = F.rng_parts(n)
  return string.format('%04d-%02d-%02d %02d:%02d:%s', y, m, d, h, mi, last and '59' or '00')
end

function F.rng_day(t, h, mi)
  local d = os.date('*t', t)
  return F.rng_make(d.year, d.month, d.day, h, mi)
end

function F.rng_fix()
  if not F.rng_valid(cfg.inc_from) then cfg.inc_from = F.rng_day(os.time(), 0, 0) end
  if not F.rng_valid(cfg.inc_to) then cfg.inc_to = F.rng_day(os.time(), 23, 59) end
end

-- Moving one end past the other pulls the other one to the same day.
function F.rng_set(which, n)
  F.rng_fix()
  local y, m, d = F.rng_parts(n)
  if which == 'from' then
    cfg.inc_from = n
    if cfg.inc_to < n then cfg.inc_to = F.rng_make(y, m, d, 23, 59) end
    if cfg.inc_to < n then cfg.inc_to = n end
  else
    cfg.inc_to = n
    if cfg.inc_from > n then cfg.inc_from = F.rng_make(y, m, d, 0, 0) end
    if cfg.inc_from > n then cfg.inc_from = n end
  end
  dirty = true
end

function F.rng_open(which)
  F.rng_fix()
  F.rng_edit = which
  local y, m, _, h, mi = F.rng_parts(which == 'from' and cfg.inc_from or cfg.inc_to)
  F.rng_view = {y, m}
  if ui.rng_h then ui.rng_h[0], ui.rng_m[0] = h, mi end
end

function F.rng_short(n)
  local y, m, d, h, mi = F.rng_parts(n)
  return string.format('%02d.%02d.%04d  %02d:%02d', d, m, y, h, mi)
end

function F.range_label(from, to)
  if from == '' then return 'За всё время' end
  local function f(s)
    local y, m, d, hm = s:match('^(%d+)%-(%d+)%-(%d+) (%d+:%d+)')
    if not y then return s end
    return d .. '.' .. m .. '.' .. y .. ' ' .. hm
  end
  return f(from) .. '  —  ' .. f(to)
end

-- Quick ranges. A week starts on Monday.
function F.rng_preset(key)
  local now = os.time()
  local t = os.date('*t', now)
  local from, to
  if key == 'h1' or key == 'h3' then
    from, to = now - (key == 'h1' and 3600 or 3 * 3600), now
    local a, b = os.date('*t', from), os.date('*t', to)
    cfg.inc_from = F.rng_make(a.year, a.month, a.day, a.hour, a.min)
    cfg.inc_to = F.rng_make(b.year, b.month, b.day, b.hour, b.min)
  elseif key == 'week' or key == 'pweek' then
    local back = (t.wday + 5) % 7
    local mon = now - back * 86400
    if key == 'pweek' then mon = mon - 7 * 86400 end
    cfg.inc_from = F.rng_day(mon, 0, 0)
    cfg.inc_to = F.rng_day(key == 'pweek' and (mon + 6 * 86400) or now, 23, 59)
  elseif key == 'mon' then
    cfg.inc_from = F.rng_make(t.year, t.month, 1, 0, 0)
    cfg.inc_to = F.rng_make(t.year, t.month, t.day, 23, 59)
  elseif key == 'pmon' then
    local y, m = t.year, t.month - 1
    if m < 1 then y, m = y - 1, 12 end
    cfg.inc_from = F.rng_make(y, m, 1, 0, 0)
    cfg.inc_to = F.rng_make(y, m, F.month_days(y, m), 23, 59)
  end
  F.rng_edit = nil
  dirty = true
end

F.RNG_PRESETS = {
  {'h1', 'Последний час'}, {'h3', '3 часа'}, {'week', 'Эта неделя'}, {'pweek', 'Прошлая неделя'},
  {'mon', 'Этот месяц'}, {'pmon', 'Прошлый месяц'},
}

-- Days that have any money or item record, for dots in the calendar.
function F.inc_days()
  local led, pay, itl = F.led_state(), F.pay_state(), F.itl_state()
  local key = led.rev .. '|' .. (pay.rev or 0) .. '|' .. #pay.list .. '|' .. itl.rev
  if F._days_key == key then return F._days end
  local out = {}
  for i = 1, #led.list do out[led.list[i].t:sub(1, 10)] = true end
  for i = 1, #pay.list do out[(pay.list[i].t or ''):sub(1, 10)] = true end
  for i = 1, #itl.list do out[itl.list[i].t:sub(1, 10)] = true end
  F._days_key, F._days = key, out
  return out
end

function F.rng_card()
  F.rng_fix()
  F.card_begin('Свой период', 'Нажми на начало или конец, чтобы выбрать день и время', 'ICON_FA_CALENDAR_ALT')
  local half = math.floor((F.inner_w() - 8) / 2)
  local function side(which, label, n)
    local p = imgui.GetCursorScreenPos()
    local h = F.s(52)
    local clicked, hovered = F.hotspot('##rng' .. which, p.x, p.y, half, h)
    local on = F.rng_edit == which
    F.round_rect(p.x, p.y, half, h, on and F.col('accent', 40) or (hovered and F.col('raised') or F.col('side', 150)),
      on and F.col('accent', 200) or F.col('text', hovered and 34 or 14), 12)
    F.text_at(font_main, 16, p.x + F.s(14), p.y + F.s(7), F.col('text', 135), label)
    F.text_at(font_bold, 18, p.x + F.s(14), p.y + F.s(26), F.col('text'), F.fit_text(font_bold, F.rng_short(n), half - F.s(28)))
    if clicked then
      if on then F.rng_edit = nil else F.rng_open(which) end
    end
    F.advance(p, half, h)
  end
  side('from', 'С', cfg.inc_from)
  imgui.SameLine(0, 8)
  side('to', 'По', cfg.inc_to)
  imgui.Spacing()
  local hit = F.pill_row('##rngp', F.RNG_PRESETS, nil)
  if hit then F.rng_preset(hit) end
  if F.rng_edit then
    F.divider()
    F.rng_calendar(F.rng_edit)
  end
  F.card_end()
end

function F.rng_calendar(which)
  local cur = which == 'from' and cfg.inc_from or cfg.inc_to
  local cy, cm, cd, ch, cmi = F.rng_parts(cur)
  local view = F.rng_view or {cy, cm}
  F.rng_view = view
  local vy, vm = view[1], view[2]
  local w = math.min(F.inner_w(), F.s(420))
  local p = imgui.GetCursorScreenPos()
  local head = F.s(32)
  if F.ghost_icon('##rngprev', p.x, p.y, 'ICON_FA_CHEVRON_LEFT', 'Прошлый месяц') then
    vm = vm - 1
    if vm < 1 then vy, vm = vy - 1, 12 end
  end
  if F.ghost_icon('##rngnext', p.x + w - F.s(30), p.y, 'ICON_FA_CHEVRON_RIGHT', 'Следующий месяц') then
    vm = vm + 1
    if vm > 12 then vy, vm = vy + 1, 1 end
  end
  view[1], view[2] = vy, vm
  local names = {'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'}
  local title = names[vm] .. ' ' .. vy
  local tw = F.text_w(font_bold, title)
  F.text_at(font_bold, 18, p.x + (w - tw) / 2, p.y + F.s(5), F.col('text'), title)
  local cw = w / 7
  local ch_ = F.s(34)
  local wy = p.y + head + F.s(4)
  local wd = {'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'}
  for i = 1, 7 do
    local lw = F.text_w(font_main, wd[i])
    F.text_at(font_main, 16, p.x + (i - 1) * cw + (cw - lw) / 2, wy, F.col('text', i >= 6 and 110 or 140), wd[i])
  end
  local gy = wy + F.s(24)
  local first = os.date('*t', os.time({year = vy, month = vm, day = 1, hour = 12}))
  local shift = (first.wday + 5) % 7
  local nd = F.month_days(vy, vm)
  local days = F.inc_days()
  local today = os.date('%Y-%m-%d')
  local fy, fm, fd = F.rng_parts(cfg.inc_from)
  local ty, tm, td = F.rng_parts(cfg.inc_to)
  local d_from = string.format('%04d-%02d-%02d', fy, fm, fd)
  local d_to = string.format('%04d-%02d-%02d', ty, tm, td)
  local rows = math.ceil((shift + nd) / 7)
  for d = 1, nd do
    local k = shift + d - 1
    local x = p.x + (k % 7) * cw
    local y = gy + math.floor(k / 7) * ch_
    local key = string.format('%04d-%02d-%02d', vy, vm, d)
    local clicked, hovered = F.hotspot('##rngd' .. d, x + 2, y + 2, cw - 4, ch_ - 4)
    local pick = key == d_from or key == d_to
    local inside = key > d_from and key < d_to
    if pick then
      F.round_rect(x + 2, y + 2, cw - 4, ch_ - 4, F.col('accent'), nil, 9)
    elseif inside then
      F.round_rect(x + 2, y + 2, cw - 4, ch_ - 4, F.col('accent', 46), nil, 9)
    elseif hovered then
      F.round_rect(x + 2, y + 2, cw - 4, ch_ - 4, F.col('text', 20), nil, 9)
    end
    if key == today and not pick then
      F.round_rect(x + 2, y + 2, cw - 4, ch_ - 4, nil, F.col('accent', 170), 9)
    end
    local label = tostring(d)
    local lw = F.text_w(font_main, label)
    local col = pick and F.col('ink') or F.col('text', key > today and 90 or 225)
    F.text_at(font_main, 16, x + (cw - lw) / 2, y + F.s(6), col, label)
    if days[key] then
      imgui.GetWindowDrawList():AddCircleFilled(imgui.ImVec2(x + cw / 2, y + ch_ - F.s(7)), F.s(2), pick and F.col('ink') or F.col('accent_hi'), 8)
    end
    if hovered and days[key] then F.tip('Есть записи за этот день') end
    if clicked then F.rng_set(which, F.rng_make(vy, vm, d, ch, cmi)) end
  end
  F.advance(p, w, head + F.s(28) + rows * ch_)
  imgui.Spacing()
  imgui.PushItemWidth(math.floor((w - 8) / 2))
  local hc = imgui.SliderFloat('##rngh', ui.rng_h, 0, 23, 'Час: %.0f')
  imgui.SameLine(0, 8)
  local mc = imgui.SliderFloat('##rngm', ui.rng_m, 0, 59, 'Минуты: %.0f')
  imgui.PopItemWidth()
  if hc or mc then
    local h = math.max(0, math.min(23, math.floor(ui.rng_h[0] + 0.5)))
    local mi = math.max(0, math.min(59, math.floor(ui.rng_m[0] + 0.5)))
    F.rng_set(which, F.rng_make(cy, cm, cd, h, mi))
  end
  imgui.Spacing()
  local function at(h, mi)
    F.rng_set(which, F.rng_make(cy, cm, cd, h, mi))
    ui.rng_h[0], ui.rng_m[0] = h, mi
  end
  if F.button('Начало дня##rng0', 140, 0) then at(0, 0) end
  imgui.SameLine(0, 8)
  if F.button('Конец дня##rng1', 140, 0) then at(23, 59) end
  imgui.SameLine(0, 8)
  if F.button('Сейчас##rngnow', 120, 0) then
    local t = os.date('*t')
    F.rng_set(which, F.rng_make(t.year, t.month, t.day, t.hour, t.min))
    F.rng_open(which)
  end
  imgui.SameLine(0, 8)
  if F.button('Готово##rngok', 120, 0, 'primary') then F.rng_edit = nil end
end

function F.stamp_time(s)
  local y, m, d, h, mi, sec = tostring(s or ''):match('^(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)')
  if not y then return nil end
  return os.time({year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = tonumber(h), min = tonumber(mi), sec = tonumber(sec)})
end

-- The same length right before the range: yesterday for today, the week before for a week.
function F.prev_range(from, to)
  local a, b = F.stamp_time(from), F.stamp_time(to)
  if not a or not b or b < a then return nil end
  local len = b - a + 1
  return os.date('%Y-%m-%d %H:%M:%S', a - len), os.date('%Y-%m-%d %H:%M:%S', a - 1)
end

function F.pct_text(cur, prev)
  if not prev or prev <= 0 then return '' end
  local p = math.floor((cur - prev) / prev * 100 + 0.5)
  if p == 0 then return ' (столько же)' end
  return string.format(' (%s%d%%)', p > 0 and '+' or '', p)
end

function F.inc_buckets(s, from, to)
  local today = os.date('%Y-%m-%d')
  local d1, d2 = from:sub(1, 10), to:sub(1, 10)
  if from == '' then
    d1 = nil
    for d in pairs(s.days) do
      if not d1 or d < d1 then d1 = d end
    end
    d1 = d1 or today
  end
  if d2 > today then d2 = today end
  if d1 > d2 then d1 = d2 end
  local out = {}
  if d1 == d2 then
    local h1 = from:sub(1, 10) == d1 and tonumber(from:sub(12, 13)) or 0
    local h2 = to:sub(1, 10) == d2 and tonumber(to:sub(12, 13)) or 23
    for h = h1 or 0, h2 or 23 do
      local b = s.hours[d1 .. ' ' .. string.format('%02d', h)] or {inc = 0, exp = 0}
      out[#out + 1] = {label = string.format('%02d:00', h), inc = b.inc, exp = b.exp}
    end
    return out, 'hour'
  end
  local y, m, d = d1:match('^(%d+)%-(%d+)%-(%d+)')
  local t = os.time({year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12})
  local list = {}
  for _ = 1, 4000 do
    local key = os.date('%Y-%m-%d', t)
    if key > d2 then break end
    list[#list + 1] = key
    t = t + 86400
  end
  if #list <= 62 then
    for i = 1, #list do
      local b = s.days[list[i]] or {inc = 0, exp = 0}
      out[#out + 1] = {label = list[i]:sub(9, 10) .. '.' .. list[i]:sub(6, 7), inc = b.inc, exp = b.exp}
    end
    return out, 'day'
  end
  local at = {}
  for i = 1, #list do
    local mk = list[i]:sub(1, 7)
    local b = at[mk]
    if not b then
      b = {label = mk:sub(6, 7) .. '.' .. mk:sub(1, 4), inc = 0, exp = 0}
      at[mk] = b
      out[#out + 1] = b
    end
    local src = s.days[list[i]]
    if src then b.inc, b.exp = b.inc + src.inc, b.exp + src.exp end
  end
  return out, 'month'
end

function F.income_chart(s, from, to)
  local list, mode = F.inc_buckets(s, from, to)
  local top = 0
  for i = 1, #list do top = math.max(top, list[i].inc, list[i].exp) end
  local title = mode == 'hour' and 'По часам' or (mode == 'month' and 'По месяцам' or 'По дням')
  F.card_begin(title, 'Наведи на столбик, чтобы увидеть суммы', 'ICON_FA_CHART_BAR')
  if top <= 0 or #list == 0 then
    F.hint('За этот период движения денег не было.')
    F.card_end()
    return
  end
  local p = imgui.GetCursorScreenPos()
  local w = F.inner_w()
  local h = F.s(120)
  local n = #list
  local bw = w / n
  local gap = math.min(F.s(6), bw * 0.25)
  local base = p.y + h
  local dl = imgui.GetWindowDrawList()
  for i = 1, n do
    local b = list[i]
    local x = p.x + (i - 1) * bw
    local _, hovered = F.hotspot('##incbar' .. i, x, p.y, math.max(1, bw), h)
    if hovered then
      F.round_rect(x, p.y, bw, h, F.col('text', 14), nil, 6)
      F.tip(b.label .. '\nПришло: ' .. (F.fmt_money(b.inc) or '—') .. '\nУшло: ' .. (F.fmt_money(b.exp) or '—')
        .. '\nЧистыми: ' .. (F.fmt_money(b.inc - b.exp) or '—'))
    end
    local half = math.max(1, (bw - gap) / 2)
    local ih = (h - 4) * b.inc / top
    local eh = (h - 4) * b.exp / top
    if ih >= 1 then F.round_rect(x + gap / 2, base - ih, half, ih, F.col('accent', hovered and 255 or 220), nil, math.min(4, half / 2)) end
    if eh >= 1 then F.round_rect(x + gap / 2 + half, base - eh, half, eh, F.col('bad', hovered and 230 or 180), nil, math.min(4, half / 2)) end
  end
  dl:AddLine(imgui.ImVec2(p.x, base), imgui.ImVec2(p.x + w, base), F.col('text', 30), 1)
  local marks = {1, math.floor((n + 1) / 2), n}
  local last_x = -1e9
  for k = 1, 3 do
    local i = marks[k]
    if i >= 1 and i <= n then
      local label = list[i].label
      local lw = F.text_w(font_main, label)
      local x = p.x + (i - 0.5) * bw - lw / 2
      x = math.max(p.x, math.min(p.x + w - lw, x))
      if x > last_x + 8 then
        F.text_at(font_main, 16, x, base + F.s(4), F.col('text', 120), label)
        last_x = x + lw
      end
    end
  end
  F.advance(p, w, h + F.s(26))
  local lp = imgui.GetCursorScreenPos()
  F.round_rect(lp.x, lp.y + F.s(5), F.s(10), F.s(10), F.col('accent'), nil, 3)
  F.text_at(font_main, 16, lp.x + F.s(16), lp.y, F.col('text', 150), 'Пришло')
  local x2 = lp.x + F.s(16) + F.text_w(font_main, 'Пришло') + F.s(20)
  F.round_rect(x2, lp.y + F.s(5), F.s(10), F.s(10), F.col('bad', 200), nil, 3)
  F.text_at(font_main, 16, x2 + F.s(16), lp.y, F.col('text', 150), 'Ушло')
  F.advance(lp, w, F.s(20))
  F.card_end()
end

function F.income_report(s, from, to)
  local m = function(v) return F.fmt_money(v) or '—' end
  local out = {
    'Доходы: ' .. F.range_label(from, to),
    'Пришло: ' .. m(s.inc) .. ' | Ушло: ' .. m(s.exp) .. ' | Чистыми: ' .. m(s.inc - s.exp),
    'Пейдеи (' .. s.pay_n .. '): ' .. m(s.pay) .. ' | Работа: ' .. m(s.work) .. ' | Продажи: ' .. m(s.sell),
    'Покупки: ' .. m(s.buy) .. ' | Расходы: ' .. m(s.spend) .. ' | Прочее: ' .. m(s.other),
  }
  local function top(title, list)
    if #list == 0 then return end
    out[#out + 1] = title
    for i = 1, math.min(#list, 8) do
      local n = list[i].n
      out[#out + 1] = '  ' .. list[i].name .. ': ' .. m(list[i].sum) .. (n > 1 and (' (' .. n .. ' ' .. F.ru_count(n, 'раз', 'раза', 'раз') .. ')') or '')
    end
  end
  top('Откуда деньги:', s.gin)
  top('Куда ушли:', s.gout)
  return table.concat(out, '\n')
end

-- Items that came in: from the chat lines "В инвентарь добавлен предмет" and the like.

F.ITL_MAX = 6000
F.ITL_SRC = {inv = 'В инвентарь', store = 'Из хранилища', prize = 'Награда'}

function F.itl_state()
  if not F.itl then F.itl = {list = {}, rev = 0} end
  return F.itl
end

function F.itl_line(r)
  return table.concat({r.t, tostring(r.id or 0), tostring(r.qty or 1), r.src or 'inv', (tostring(r.name or ''):gsub('|', '/'))}, '|')
end

function F.itl_load()
  local st = F.itl_state()
  st.list = {}
  local rows = F.read_lines('fhelp_items.txt')
  for i = math.max(1, #rows - F.ITL_MAX + 1), #rows do
    local t, id, qty, src, name = rows[i]:match('^(.-)|(%d+)|(%d+)|(%a+)|(.*)$')
    if t and t ~= '' then
      st.list[#st.list + 1] = {t = t, id = tonumber(id) or 0, qty = tonumber(qty) or 1, src = src, name = name}
    end
  end
  if #rows > F.ITL_MAX + 1000 then
    local out = {}
    for i = 1, #st.list do out[i] = F.itl_line(st.list[i]) end
    F.write_lines('fhelp_items.txt', out)
  end
  st.rev = st.rev + 1
end

function F.item_label(id)
  local it = F.lib_db().by_id[id]
  if it and it.name then return it.name end
  return F.item_name(id)
end

function F.lib_by_name(name)
  local db = F.lib_db()
  if not db.by_low then
    db.by_low = {}
    for i = 1, #db.list do
      local it = db.list[i]
      if it.low and not db.by_low[it.low] then db.by_low[it.low] = it.id end
    end
  end
  return db.by_low[F.lower_fast(F.trim(name))]
end

function F.item_got(id, qty, src, name)
  if id and id > 0 then
    name = F.item_label(id)
  else
    name = F.trim(name or '')
    id = (name ~= '' and (F.lib_by_name(name) or F.item_by_name(name))) or 0
  end
  qty = math.max(1, math.floor(tonumber(qty) or 1))
  local r = {t = os.date('%Y-%m-%d %H:%M:%S'), id = id, qty = qty, src = src, name = F.utf_cut(name or '', 120)}
  if r.name == '' then r.name = 'Предмет' end
  local st = F.itl_state()
  st.list[#st.list + 1] = r
  while #st.list > F.ITL_MAX do table.remove(st.list, 1) end
  st.rev = st.rev + 1
  pcall(function()
    F.mkdir(F.cfg_dir())
    local f = io.open(F.lines_path('fhelp_items.txt'), 'a')
    if f then
      f:write((F.itl_line(r):gsub('[\r\n]', ' ')) .. '\n')
      f:close()
    end
  end)
  F.toast('item', {
    key = 'item' .. (id > 0 and tostring(id) or r.name), item = id > 0 and id or nil,
    icon = 'ICON_FA_BOX_OPEN', title = F.ITL_SRC[src] or 'Предмет', text = r.name, qty = qty,
  })
  return r
end

function F.item_feed(text)
  if not (text:find('редмет', 1, true) or text:find('забрали', 1, true)) then return end
  local raw = F.int_pack(F.game_text(text))
  if raw == '' or raw:find('%w%[%d+%]') or raw:find('[\128-\255]%[%d+%]') then return end
  raw = F.trim((raw:gsub(':u%x%x%x%x+:', '')))
  local id = raw:match('^В инвентарь добавлен предмет:%s*:item(%d+):')
  if id then return F.item_got(tonumber(id), 1, 'inv') end
  local name = raw:match("^В инвентарь добавлен предмет:%s*'(.-)'")
  if name then return F.item_got(nil, 1, 'inv', name) end
  local q
  name, q = raw:match("Вы забрали предмет '(.-)%((%d+) шт%.?%)', из хранилища")
  if name then return F.item_got(nil, tonumber(q), 'store', name) end
  name = raw:match("Вы забрали предмет '(.-)', из хранилища")
  if name then return F.item_got(nil, 1, 'store', name) end
  name, q = raw:match("Вы успешно забрали %- '(.-)' в количестве (%d+)")
  if name then return F.item_got(nil, tonumber(q), 'prize', name) end
end

function F.itl_view(from, to, q)
  local st = F.itl_state()
  local key = from .. '|' .. to .. '|' .. q .. '|' .. st.rev
  if F._itl_key == key then return F._itl end
  local low = F.lower_fast(q)
  local out = {groups = {}, rows = {}, qty = 0, n = 0}
  local at = {}
  for i = #st.list, 1, -1 do
    local r = st.list[i]
    if r.t >= from and r.t <= to and (low == '' or F.lower_fast(r.name):find(low, 1, true)) then
      out.n = out.n + 1
      out.qty = out.qty + r.qty
      if #out.rows < 40 then out.rows[#out.rows + 1] = r end
      local gk = r.id > 0 and r.id or r.name
      local g = at[gk]
      if not g then
        g = {id = r.id, name = r.name, qty = 0, n = 0, last = r.t, src = r.src}
        at[gk] = g
        out.groups[#out.groups + 1] = g
      end
      g.qty, g.n = g.qty + r.qty, g.n + 1
    end
  end
  table.sort(out.groups, function(a, b)
    if a.qty ~= b.qty then return a.qty > b.qty end
    return a.last > b.last
  end)
  F._itl_key, F._itl = key, out
  return out
end

function F.item_pic_of(id)
  if id and id > 0 then return F.car_lib(id) end
  return {cat = 'etc', pic_n = 0}
end

function F.item_row(name, id, sub, right, i, tip, fn)
  local p = imgui.GetCursorScreenPos()
  local w = F.inner_w()
  local h = F.s(48)
  local clicked, hovered = F.hotspot('##itr' .. i, p.x - 6, p.y, w + 12, h - 4)
  if hovered then F.round_rect(p.x - 6, p.y, w + 12, h - 4, F.col('text', 16), nil, 8)
  elseif i % 2 == 0 then F.round_rect(p.x - 6, p.y, w + 12, h - 4, F.col('side', 90), nil, 8) end
  local sz = F.s(36)
  F.lib_pic(F.item_pic_of(id), p.x, p.y + (h - 4 - sz) / 2, sz)
  local tx = p.x + sz + F.s(12)
  local rw = F.text_w(font_bold, right)
  local tw = w - (tx - p.x) - rw - F.s(16)
  F.text_at(font_main, 16, tx, p.y + F.s(4), F.col('text', 230), F.fit_text(font_main, name, tw))
  F.text_at(font_main, 16, tx, p.y + F.s(24), F.col('text', 120), F.fit_text(font_main, sub, tw))
  F.text_at(font_bold, 18, p.x + w - rw - 4, p.y + (h - 4 - F.s(18)) / 2 - 1, F.col('accent_hi'), right)
  if hovered then F.tip(tip or (id > 0 and 'Нажми, чтобы скопировать код предмета для чата' or 'Нажми, чтобы скопировать название')) end
  if clicked then
    if fn then fn() else F.note_copy(id > 0 and (':item' .. id .. ':') or name) end
  end
  F.advance(p, w, h)
end

function F.income_items(from, to)
  F.field('##itemq', 'Поиск по названию предмета', ui.item_q, 80, F.inner_w(), 'item_q')
  imgui.Spacing()
  local view = F.itl_view(from, to, F.trim(F.buf_get(ui.item_q)))
  F.tile_grid('itl', {
    {'ICON_FA_BOX_OPEN', 'Получено штук', tostring(view.qty)},
    {'ICON_FA_LAYER_GROUP', 'Разных предметов', tostring(#view.groups)},
    {'ICON_FA_HISTORY', 'Записей', tostring(view.n)},
  }, 200)
  imgui.Spacing()
  F.card_begin('Что пришло', 'Одинаковые предметы сложены, больше всего сверху', 'ICON_FA_LAYER_GROUP')
  if #view.groups == 0 then
    F.empty('ICON_FA_BOX_OPEN', 'Предметов нет', 'Они появятся, когда в чате будет «В инвентарь добавлен предмет»')
  end
  for i = 1, math.min(#view.groups, 60) do
    local g = view.groups[i]
    local sub = 'Последний раз ' .. F.short_stamp(g.last) .. '  ·  ' .. (F.ITL_SRC[g.src] or '')
    if g.n > 1 then sub = sub .. '  ·  ' .. g.n .. ' ' .. F.ru_count(g.n, 'раз', 'раза', 'раз') end
    F.item_row(g.name, g.id, sub, '×' .. g.qty, i)
  end
  if #view.groups > 60 then F.hint('И ещё предметов: ' .. (#view.groups - 60)) end
  F.card_end()
  if #view.rows > 0 then
    F.card_begin('По порядку', view.n > #view.rows and ('Последние ' .. #view.rows .. ' из ' .. view.n) or nil, 'ICON_FA_HISTORY')
    for i = 1, #view.rows do
      local r = view.rows[i]
      F.item_row(r.name, r.id, F.short_stamp(r.t) .. '  ·  ' .. (F.ITL_SRC[r.src] or ''), '×' .. r.qty, 1000 + i)
    end
    F.card_end()
  end
end

-- On-screen notifications

F.toasts = {}
F.toast_log = {}
F.TOAST_TONE = {pay = 'accent', inc = 'accent', exp = 'bad', item = 'accent_hi', car = 'accent', sys = 'text', shop = 'accent'}
F.TOAST_PLACES = {{0, 'Справа'}, {1, 'Справа внизу'}, {2, 'Сверху'}, {3, 'Снизу'}, {4, 'Своё место'}}
F.TOAST_MIN = {{0, 'Любая'}, {10000, 'от 10к'}, {100000, 'от 100к'}, {1000000, 'от 1кк'}}

function F.toast(kind, o)
  if cfg.toast_on ~= 1 then return end
  if not o.force then
    local flag = cfg['toast_' .. kind]
    if flag ~= nil and flag ~= 1 then return end
  end
  local now = os.clock()
  local life = tonumber(cfg.toast_time) or 6
  local list = F.toasts
  if cfg.toast_merge == 1 and o.key then
    for i = 1, #list do
      local t = list[i]
      if t.key == o.key and t.till > now + 0.3 then
        if o.qty then t.qty = (t.qty or 0) + o.qty end
        if o.amount then t.amount = (t.amount or 0) + o.amount end
        if o.text then t.text = o.text end
        t.till, t.life, t.bump = now + life, life, now
        if t.log then t.log.text, t.log.amount, t.log.qty = t.text, t.amount, t.qty end
        return t
      end
    end
  end
  local t = {
    kind = kind, key = o.key, icon = o.icon, title = o.title or '', text = o.text or '',
    amount = o.amount, qty = o.qty, item = o.item, neg = o.neg, vc = o.vc,
    born = now, till = now + life, life = life,
  }
  t.log = {at = os.date('%H:%M:%S'), kind = kind, title = t.title, text = t.text, amount = t.amount, qty = t.qty, neg = t.neg, item = t.item}
  table.insert(F.toast_log, 1, t.log)
  while #F.toast_log > 30 do table.remove(F.toast_log) end
  table.insert(list, 1, t)
  while #list > (cfg.toast_max or 5) do table.remove(list) end
  if cfg.toast_sound == 1 and not o.quiet then
    pcall(function()
      local x, y, z = getCharCoordinates(PLAYER_PED)
      addOneOffSound(x, y, z, 1139)
    end)
  end
  return t
end

function F.ru_count(n, one, few, many)
  local a, b = n % 10, n % 100
  if a == 1 and b ~= 11 then return one end
  if a >= 2 and a <= 4 and (b < 12 or b > 14) then return few end
  return many
end

function F.toast_pay(rec, extra, why)
  local st = F.pay_state()
  local today = os.date('%Y-%m-%d')
  local sum, n = 0, 0
  for i = 1, #st.list do
    local r = st.list[i]
    if (r.t or ''):sub(1, 10) == today then
      sum, n = sum + (r.total or 0), n + 1
    end
  end
  local text = 'Сегодня ' .. n .. ' ' .. F.ru_count(n, 'пейдей', 'пейдея', 'пейдеев') .. ': ' .. (F.fmt_money(sum) or '—')
  if (rec.az or 0) ~= 0 then text = text .. '  ·  ' .. (rec.az > 0 and '+' or '') .. rec.az .. ' AZ' end
  F.toast('pay', {
    key = 'pay' .. tostring(rec.t), icon = 'ICON_FA_COINS', title = extra and ('Пейдей, доплата: ' .. tostring(why or '')) or 'Пейдей',
    text = text, amount = extra or rec.total,
  })
end

function F.toast_led(r)
  local out = r.cat == 'buy' or r.cat == 'spend'
  if (r.amount or 0) < (tonumber(cfg.toast_min) or 0) then return end
  local info = F.LED_CAT[r.cat] or {'Деньги', 'ICON_FA_COINS'}
  local text = r.text or ''
  if (r.qty or 0) > 1 then text = text .. '  ×' .. r.qty end
  if (r.who or '') ~= '' then text = text .. '  ·  ' .. r.who end
  F.toast(out and 'exp' or 'inc', {
    key = 'led' .. r.cat .. '|' .. (r.text or '') .. '|' .. (r.who or ''), icon = info[2], title = info[1],
    text = text, amount = r.amount, neg = out, vc = r.cur == 'vc', qty = 1,
  })
end

function F.toast_demo()
  local item
  local list = F.lib_db().list
  for i = 1, #list do
    if (list[i].pic_n or 0) > 0 then item = list[i] break end
  end
  F.toast_demo_till = os.clock() + (tonumber(cfg.toast_time) or 6) + 1
  F.toast('sys', {force = true, quiet = true, icon = 'ICON_FA_INFO_CIRCLE', title = 'fHelper', text = 'Так выглядят уведомления'})
  F.toast('exp', {force = true, quiet = true, icon = 'ICON_FA_RECEIPT', title = 'Расходы', text = 'Налоги', amount = 25000, neg = true})
  if item then
    F.toast('item', {force = true, quiet = true, icon = 'ICON_FA_BOX_OPEN', title = 'В инвентарь', text = item.name, item = item.id, qty = 3})
  end
  F.toast('inc', {force = true, quiet = true, icon = 'ICON_FA_BRIEFCASE', title = 'Работа', text = 'Такси: клиент', amount = 4500})
  F.toast('pay', {force = true, icon = 'ICON_FA_COINS', title = 'Пейдей', text = 'Сегодня 3 пейдея: $1.250.000', amount = 420000})
end

function F.toast_on()
  if hidden or cfg.toast_on ~= 1 then return false end
  local list = F.toasts
  local now = os.clock()
  for i = #list, 1, -1 do
    if list[i].till <= now then table.remove(list, i) end
  end
  if #list == 0 then return false end
  if show and cfg.toast_menu ~= 1 and not (F.toast_demo_till and F.toast_demo_till > now) then return false end
  local ok, pause = pcall(isPauseMenuActive)
  return not (ok and pause)
end

-- Where the newest notification sits and which way the older ones go.
function F.toast_geo()
  local io = imgui.GetIO()
  local sw, sh = io.DisplaySize.x, io.DisplaySize.y
  if sw < 100 then sw = 1366 end
  if sh < 100 then sh = 768 end
  local ts = tonumber(cfg.toast_scale) or 1
  local w = (tonumber(cfg.toast_w) or 320) * ts
  local h = 58 * ts
  local gap = 8 * ts
  local m = 16
  local place = cfg.toast_place
  local x, y, up
  if place == 1 then x, y, up = sw - w - m, sh - h - sh * 0.1, true
  elseif place == 2 then x, y = (sw - w) / 2, sh * 0.06
  elseif place == 3 then x, y, up = (sw - w) / 2, sh - h - sh * 0.17, true
  elseif place == 4 then
    x = cfg.toast_x / 100 * math.max(0, sw - w)
    y = cfg.toast_y / 100 * math.max(0, sh - h)
    up = cfg.toast_y > 50
  else x, y = sw - w - m, sh * 0.24 end
  return x, y, w, h, gap, up, sw, sh, ts
end

function F.toast_pic(id, x, y, sz, a)
  local it = F.car_lib(id)
  local tex = F.lib_tex(it)
  if tex then
    imgui.GetWindowDrawList():AddImage(tex, imgui.ImVec2(x, y), imgui.ImVec2(x + sz, y + sz),
      imgui.ImVec2(0, 0), imgui.ImVec2(1, 1), F.rgba(255, 255, 255, math.floor(255 * a)))
    return true
  end
  return false
end

function F.toast_card(t, x, y, w, h, a, ts, now)
  local function A(v) return math.max(0, math.min(255, math.floor(v * a))) end
  local tone = t.neg and 'bad' or (F.TOAST_TONE[t.kind] or 'accent')
  local r = math.max(8, 12 * ts)
  F.round_rect(x, y, w, h, F.col('panel', A(250)), F.col('text', A(34)), r)
  F.round_rect(x + 6 * ts, y + 12 * ts, 3 * ts, h - 24 * ts, F.col(tone, A(255)), nil, 2)
  local isz = 38 * ts
  local ix, iy = x + 16 * ts, y + (h - isz) / 2
  F.round_rect(ix, iy, isz, isz, F.col(tone == 'text' and 'accent' or tone, A(40)), nil, math.max(6, 10 * ts))
  local drawn = t.item and F.toast_pic(t.item, ix + 3 * ts, iy + 3 * ts, isz - 6 * ts, a)
  if not drawn then
    local glyph = F.faico(t.icon or 'ICON_FA_BELL')
    if glyph == '' then glyph = F.utf_first(t.title) end
    local gw = F.text_w(font_main, glyph) * ts
    F.text_at(font_main, 16, ix + (isz - gw) / 2, iy + (isz - 16 * ts) / 2 - 1, F.col(tone == 'text' and 'accent_hi' or tone, A(255)), glyph, nil, ts)
  end
  local kb, km = 16 / 18 * ts, 14 / 16 * ts
  local tx = ix + isz + 12 * ts
  local right = x + w - 14 * ts
  local tail = ''
  if t.amount then
    tail = F.fmt_money(t.amount) or ''
    if t.vc then tail = tail:gsub('^%$', 'VC$') end
    tail = (t.neg and '-' or '+') .. tail
  end
  local tw = tail ~= '' and F.text_w(font_bold, tail) * kb or 0
  if tw > 0 then
    F.text_at(font_bold, 16, right - tw, y + 10 * ts, t.neg and F.col('bad', A(255)) or F.col('accent_hi', A(255)), tail, nil, ts)
  end
  local title_w = (right - tx - tw - 8 * ts) / kb
  F.text_at(font_bold, 16, tx, y + 10 * ts, F.col('text', A(255)), F.fit_text(font_bold, t.title, title_w), nil, ts)
  local qtxt = (t.qty or 0) > 1 and ('×' .. t.qty) or ''
  local qw = qtxt ~= '' and F.text_w(font_main, qtxt) * km or 0
  if qw > 0 then F.text_at(font_main, 14, right - qw, y + 33 * ts, F.col('accent_hi', A(255)), qtxt, nil, ts) end
  local text_w = (right - tx - qw - 8 * ts) / km
  F.text_at(font_main, 14, tx, y + 33 * ts, F.col('text', A(170)), F.fit_text(font_main, t.text, text_w), nil, ts)
  if cfg.toast_bar == 1 and t.life and t.life > 0 then
    local frac = math.max(0, math.min(1, (t.till - now) / t.life))
    local bw = (w - 2 * r) * frac
    if bw >= 1 then F.round_rect(x + r, y + h - 4 * ts, bw, math.max(2, 2 * ts), F.col(tone == 'text' and 'accent' or tone, A(130)), nil, 1) end
  end
end

function F.draw_toasts()
  local list = F.toasts
  local n = #list
  if n == 0 then return end
  local ax, ay, w, h, gap, up, sw, sh, ts = F.toast_geo()
  local step = (h + gap) * (up and -1 or 1)
  local top = up and (ay + step * (n - 1)) or ay
  local total = n * h + (n - 1) * gap
  local pad = 30 * ts
  local WF = imgui.WindowFlags
  local flags = WF.NoTitleBar + WF.NoResize + WF.NoScrollbar + WF.NoScrollWithMouse + WF.NoCollapse
    + WF.NoSavedSettings + WF.NoFocusOnAppearing + WF.NoBringToFrontOnFocus + WF.NoNavInputs
    + WF.NoNavFocus + WF.NoMove + (WF.NoBackground or 0)
  if not show then flags = flags + WF.NoMouseInputs end
  imgui.SetNextWindowPos(imgui.ImVec2(ax - pad, top), imgui.Cond.Always)
  imgui.SetNextWindowSize(imgui.ImVec2(w + pad * 2, total), imgui.Cond.Always)
  imgui.PushStyleColor(imgui.Col.WindowBg, F.vec4(0, 0, 0, 0))
  imgui.PushStyleColor(imgui.Col.Border, F.vec4(0, 0, 0, 0))
  imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0)
  imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
  imgui.Begin('fhelp-toast', nil, flags)
  F.use_font(font_main)
  local now = os.clock()
  local alpha = tonumber(cfg.toast_alpha) or 0.94
  local dir = (ax + w / 2 > sw / 2) and 1 or -1
  for i = 1, n do
    local t = list[i]
    local y = ay + step * (i - 1)
    local ain = math.min(1, (now - t.born) / 0.2)
    local aout = math.min(1, math.max(0, (t.till - now) / 0.4))
    local pulse = t.bump and math.max(0, 1 - (now - t.bump) / 0.3) or 0
    local x = ax + (1 - ain) * 24 * ts * dir
    F.toast_card(t, x, y, w, h, math.min(ain, aout) * alpha, ts, now)
    if pulse > 0 then F.round_rect(x, y, w, h, nil, F.col('accent', math.floor(200 * pulse)), math.max(8, 12 * ts)) end
    if show then
      imgui.SetCursorScreenPos(imgui.ImVec2(x, y))
      imgui.InvisibleButton('##toast' .. i, imgui.ImVec2(w, h))
      if imgui.IsItemHovered() then
        t.till = math.max(t.till, now + 0.6)
        F.tip('Перетащи, чтобы сдвинуть. Правый клик закроет')
        if imgui.IsMouseClicked(1) then t.till = now + 0.4 end
      end
      if imgui.IsItemActive() and imgui.IsMouseDragging(0) then
        local md = imgui.GetIO().MouseDelta
        local nx = math.max(0, math.min(sw - w, ax + md.x))
        local ny = math.max(0, math.min(sh - h, ay + md.y))
        cfg.toast_place = 4
        cfg.toast_x = sw - w > 0 and nx / (sw - w) * 100 or 0
        cfg.toast_y = sh - h > 0 and ny / (sh - h) * 100 or 0
        if ui.toast_x then ui.toast_x[0], ui.toast_y[0] = cfg.toast_x, cfg.toast_y end
        dirty = true
      end
    end
  end
  F.done_font(font_main)
  imgui.End()
  imgui.PopStyleVar(2)
  imgui.PopStyleColor(2)
end

function F.toast_flag(id, label, key, sub)
  if F.switch(id, label, cfg[key] == 1, sub) then
    cfg[key] = cfg[key] == 1 and 0 or 1
    dirty = true
  end
end

function F.toast_slider(id, label, key, lo, hi, fmt, mul)
  mul = mul or 1
  if F.slider_row(id, label, ui[key], lo, hi, fmt) then
    local v = ui[key][0] / mul
    if mul == 1 then v = math.floor(v + 0.5) end
    cfg[key] = v
    dirty = true
  end
end

function F.toast_settings()
  F.card_begin('Уведомления на экране', 'Небольшие плашки о пейдее, доходах, расходах и предметах', 'ICON_FA_BELL')
  F.toast_flag('tson', 'Показывать уведомления', 'toast_on')
  if cfg.toast_on ~= 1 then
    F.card_end()
    return
  end
  F.divider()
  imgui.TextUnformatted('О чём сообщать')
  F.toast_flag('tspay', 'Пейдей', 'toast_pay', 'Сумма чека и сколько пейдеев сегодня')
  F.toast_flag('tsinc', 'Доходы', 'toast_inc', 'Работа, продажи, переводы и прочие деньги')
  F.toast_flag('tsexp', 'Расходы', 'toast_exp', 'Покупки, налоги, штрафы, аренда')
  F.toast_flag('tsitem', 'Предметы', 'toast_item', 'Что добавилось в инвентарь или пришло из хранилища')
  F.toast_flag('tscar', 'Сканер машин', 'toast_car', 'Когда машина отсканирована')
  F.toast_flag('tssys', 'Сообщения fHelper', 'toast_sys', 'То, что fHelper пишет в чат, пока меню закрыто')
  imgui.Spacing()
  imgui.TextUnformatted('Сумма, с которой показывать доходы и расходы')
  local v = F.segment('tsmin', F.TOAST_MIN, cfg.toast_min)
  if v then
    cfg.toast_min = v
    dirty = true
  end
  F.divider()
  imgui.TextUnformatted('Где показывать')
  v = F.segment('tsplace', F.TOAST_PLACES, cfg.toast_place)
  if v then
    cfg.toast_place = v
    dirty = true
  end
  if cfg.toast_place == 4 then
    F.toast_slider('tsx', 'По горизонтали', 'toast_x', 0, 100, '%.0f%%')
    F.toast_slider('tsy', 'По вертикали', 'toast_y', 0, 100, '%.0f%%')
    F.hint('Выше середины экрана новые уведомления идут сверху вниз, ниже середины снизу вверх.')
  end
  F.hint('Пока меню открыто, уведомление можно перетащить мышью, правый клик закроет его.')
  F.divider()
  imgui.TextUnformatted('Вид')
  if F.slider_row('tsscale', 'Размер', ui.toast_scale, 60, 200, '%.0f%%') then
    cfg.toast_scale = math.max(0.6, math.min(2, ui.toast_scale[0] / 100))
    dirty = true
  end
  F.toast_slider('tsw', 'Ширина', 'toast_w', 220, 520, '%.0f')
  if F.slider_row('tsalpha', 'Непрозрачность', ui.toast_alpha, 30, 100, '%.0f%%') then
    cfg.toast_alpha = math.max(0.3, math.min(1, ui.toast_alpha[0] / 100))
    dirty = true
  end
  F.toast_slider('tstime', 'Сколько секунд держать', 'toast_time', 2, 30, '%.0f с')
  F.toast_slider('tsmax', 'Сколько сразу на экране', 'toast_max', 1, 10, '%.0f')
  F.toast_flag('tsbar', 'Полоска оставшегося времени', 'toast_bar')
  F.toast_flag('tsmerge', 'Складывать одинаковые', 'toast_merge', 'Пять одинаковых предметов подряд дадут одно уведомление ×5')
  F.toast_flag('tsmenu', 'Показывать при открытом меню', 'toast_menu')
  F.toast_flag('tssound', 'Звук', 'toast_sound', 'Короткий игровой звук при новом уведомлении')
  imgui.Spacing()
  if F.button('Показать пример##tsdemo', 200, 0, 'primary') then F.toast_demo() end
  imgui.SameLine(0, 8)
  if F.button('Убрать с экрана##tsclr', 180, 0) then F.toasts = {} end
  imgui.SameLine(0, 8)
  if F.button('Сбросить вид##tsreset', 160, 0) then
    cfg.toast_place, cfg.toast_x, cfg.toast_y, cfg.toast_scale = 0, 98, 30, 1
    cfg.toast_w, cfg.toast_alpha, cfg.toast_time, cfg.toast_max = 320, 0.94, 6, 5
    F.toast_ui()
    dirty = true
  end
  if #F.toast_log > 0 then
    F.divider()
    imgui.TextUnformatted('Недавние')
    for i = 1, math.min(#F.toast_log, 10) do
      local e = F.toast_log[i]
      local line = e.at .. '   ' .. e.title
      if e.text ~= '' then line = line .. ': ' .. e.text end
      if (e.qty or 0) > 1 then line = line .. '  ×' .. e.qty end
      if e.amount then line = line .. '   ' .. (e.neg and '-' or '+') .. (F.fmt_money(e.amount) or '') end
      F.hint(line)
    end
  end
  F.card_end()
end

function F.toast_ui()
  if not ui.toast_x then return end
  ui.toast_x[0], ui.toast_y[0] = cfg.toast_x, cfg.toast_y
  ui.toast_scale[0] = cfg.toast_scale * 100
  ui.toast_w[0] = cfg.toast_w
  ui.toast_alpha[0] = cfg.toast_alpha * 100
  ui.toast_time[0] = cfg.toast_time
  ui.toast_max[0] = cfg.toast_max
end

-- Text field with the same paste handling as binds.
function F.field(id, hint, buf, cap, w, key, flags)
  imgui.PushItemWidth(w)
  F.ensure_paste_cb()
  local f = flags or 0
  local use_cb = F.paste_cb and F.hot_field == key
  if use_cb then F.suppress_bind_paste() end
  local res
  if use_cb then
    res = imgui.InputTextWithHint(id, hint, buf, cap, f + imgui.InputTextFlags.CallbackAlways, F.paste_cb, nil)
  else
    res = imgui.InputTextWithHint(id, hint, buf, cap, f)
  end
  if use_cb then F.restore_bind_paste() end
  if imgui.IsItemActive() then F.hot_field = key
  elseif F.hot_field == key then F.hot_field = nil end
  imgui.PopItemWidth()
  return res
end

function F.icon_label(icon, text)
  local g = F.faico(icon)
  if g == '' then return text end
  return g .. '  ' .. text
end

-- Chat

function F.fav_title(f)
  if f.label and f.label ~= '' then return f.label end
  return F.int_human(f.text)
end

function F.save_favs()
  local rows = {}
  for i = 1, #favs do
    local f = favs[i]
    rows[#rows + 1] = 'F|' .. F.note_esc((tostring(f.group or ''):gsub('|', '/'))) .. '|'
      .. F.note_esc((tostring(f.label or ''):gsub('|', '/'))) .. '|' .. F.note_esc(f.text)
  end
  F.write_lines('fhelp_favs.txt', rows)
end

function F.fav_add(text, label, group)
  text = F.int_pack(F.trim(text or ''))
  if text == '' then
    F.notify('Напиши текст', true)
    return false
  end
  for i = 1, #favs do
    if favs[i].text == text then
      F.notify('Уже в избранном', true)
      return false
    end
  end
  if #favs >= 200 then
    F.notify('Избранного уже много', true)
    return false
  end
  favs[#favs + 1] = {group = F.trim(group or ''), label = F.trim(label or ''), text = text}
  F.save_favs()
  F.notify('Добавлено в избранное', true)
  return true
end

function F.fav_fire(f)
  if cfg.fav_mode == 1 then
    F.buf_set(ui_cmd, f.text, 180)
    F.chat_mode = f.text:sub(1, 1) == '/' and 'cmd' or 'say'
    F.chat_tab = 'send'
    page = 'chat'
    return
  end
  if cfg.fav_mode == 2 then
    F.to_game_chat(f.text)
    return
  end
  F.send_cmd(f.text, f.text:sub(1, 1) ~= '/')
  if cfg.fav_close == 1 then F.close_menu() end
end

function F.chat_send()
  local text = F.trim(F.buf_get(ui_cmd))
  if text == '' then return end
  F.send_cmd(text, F.chat_mode == 'say' and text:sub(1, 1) ~= '/')
  F.buf_set(ui_cmd, '', 180)
  if cfg.fav_close == 1 then F.close_menu() end
end

function F.chat_tab_send()
  F.chat_mode = F.int_form(F.buf_get(ui_cmd)) or F.chat_mode or 'cmd'
  F.card_begin('Отправить в чат', nil, 'ICON_FA_PAPER_PLANE')
  local mode = F.segment('cmode', {{'cmd', 'Команда'}, {'say', 'Сообщение'}}, F.chat_mode, math.min(F.s(300), F.inner_w()))
  if mode then F.chat_mode = mode end
  local fh = imgui.GetFrameHeight()
  local w = math.max(80, F.inner_w() - F.s(130) - (fh + 8) * 3 - 8)
  local hint = F.chat_mode == 'cmd' and '/команда' or 'Текст сообщения'
  local enter = F.field('##cmd', hint, ui_cmd, 180, w, 'cmd', imgui.InputTextFlags.EnterReturnsTrue)
  imgui.SameLine()
  local hit = F.accent_button('Отправить##cmd', 130, 0)
  imgui.SameLine()
  if F.icon_btn('ICON_FA_LINK', 'cint', 'Вставить интеграцию') then
    F.int_pick = 'chat'
    F.chat_tab = 'lib'
  end
  imgui.SameLine()
  if F.icon_btn('ICON_FA_COMMENT_DOTS', 'cgame', 'Подставить в чат игры, не отправляя') then
    F.to_game_chat(F.buf_get(ui_cmd))
  end
  imgui.SameLine()
  if F.icon_btn('ICON_FA_STAR', 'favadd', 'В избранное') then F.fav_add(F.buf_get(ui_cmd)) end
  if hit or enter then F.chat_send() end
  local cur = F.buf_get(ui_cmd)
  F.int_preview(cur)
  local size = #F.to_cp(cur)
  if size > 0 then F.hint('Длина: ' .. size .. ' из 120', size > 120 and F.cvec('bad') or nil) end
  F.card_end()
  if #favs > 0 then
    F.card_begin('Избранное', 'Нажми, чтобы отправить. Управление во вкладке «Избранное»', 'ICON_FA_STAR')
    for i = 1, #favs do
      local label = F.fit_text(font_main, F.fav_title(favs[i]), F.s(250))
      if i > 1 then F.same_if_fit(F.pill_w(label)) end
      if F.pill('##fav' .. i, label, false) then F.fav_fire(favs[i]) end
      if imgui.IsItemHovered() then F.tip(F.int_human(favs[i].text)) end
    end
    F.card_end()
  end
  F.card_begin('Недавно отправлено', 'История живёт до перезапуска и не пишется на диск', 'ICON_FA_HISTORY')
  if #console_view == 0 then F.hint('Пока ничего не отправлено.') end
  local again
  for i = #console_view, math.max(1, #console_view - 11), -1 do
    local row = console_view[i]
    local p = imgui.GetCursorScreenPos()
    local rw = F.inner_w()
    local h = F.s(32)
    local ib = F.s(30)
    F.text_at(font_main, 16, p.x, p.y + F.s(6), F.col('text', 110), row.t)
    F.text_at(font_main, 16, p.x + F.s(52), p.y + F.s(6), F.col('text', 225),
      F.fit_text(font_main, F.int_human(row.text), rw - F.s(52) - ib * 3 - 14))
    local bx = p.x + rw - ib
    if F.ghost_icon('##hst' .. i, bx, p.y, 'ICON_FA_STAR', 'В избранное') then F.fav_add(row.text) end
    if F.ghost_icon('##hcp' .. i, bx - ib - 2, p.y, 'ICON_FA_COPY', 'Копировать') then F.note_copy(row.text) end
    if F.ghost_icon('##hag' .. i, bx - (ib + 2) * 2, p.y, 'ICON_FA_REDO', 'Отправить ещё раз') then again = row.text end
    F.advance(p, rw, h)
  end
  F.card_end()
  if again then F.send_cmd(again, again:sub(1, 1) ~= '/') end
end

function F.fav_clear_form()
  F.fav_edit = nil
  F.buf_set(ui.fav_text, '', 240)
  F.buf_set(ui.fav_label, '', 80)
  F.buf_set(ui.fav_group, '', 60)
end

function F.fav_groups()
  local seen, list = {}, {{'', 'Все'}}
  for i = 1, #favs do
    local g = favs[i].group or ''
    if g ~= '' and not seen[g] then
      seen[g] = true
      list[#list + 1] = {g, g}
    end
  end
  return list
end

function F.chat_tab_favs()
  local editing = F.fav_edit and favs[F.fav_edit]
  F.card_begin(editing and 'Изменить' or 'Добавить', 'Подпись и папка не обязательны. Команды начинаются с /, остальное уходит как сообщение', editing and 'ICON_FA_PEN' or 'ICON_FA_PLUS')
  local fh = imgui.GetFrameHeight()
  local w = F.inner_w()
  F.field('##ftext', '/команда или текст с интеграциями', ui.fav_text, 240, w - fh - 8, 'fav_text')
  imgui.SameLine()
  if F.icon_btn('ICON_FA_LINK', 'fint', 'Вставить интеграцию') then
    F.int_pick = 'fav'
    F.chat_tab = 'lib'
  end
  F.int_preview(F.buf_get(ui.fav_text))
  local half = math.floor((w - 8) / 2)
  F.field('##flabel', 'Подпись, например «Доклад КПП 1»', ui.fav_label, 80, half, 'fav_label')
  imgui.SameLine()
  F.field('##fgroup', 'Папка, например «Армия»', ui.fav_group, 60, half, 'fav_group')
  if F.accent_button((editing and 'Сохранить' or 'Добавить') .. '##fsave', 140, 0) then
    if editing then
      local text = F.int_pack(F.trim(F.buf_get(ui.fav_text)))
      if text == '' then
        F.notify('Напиши текст', true)
      else
        editing.text = text
        editing.label = F.trim(F.buf_get(ui.fav_label))
        editing.group = F.trim(F.buf_get(ui.fav_group))
        F.save_favs()
        F.fav_clear_form()
        F.notify('Сохранено', true)
      end
    elseif F.fav_add(F.buf_get(ui.fav_text), F.buf_get(ui.fav_label), F.buf_get(ui.fav_group)) then
      F.fav_clear_form()
    end
  end
  if editing then
    imgui.SameLine()
    if F.button('Отмена##fcancel', 110, 0) then F.fav_clear_form() end
  end
  F.card_end()
  F.fav_filter = F.fav_filter or ''
  local groups = F.fav_groups()
  if #groups > 1 then
    local g = F.pill_row('##fg', groups, F.fav_filter)
    if g then F.fav_filter = g end
    imgui.Spacing()
  end
  F.card_begin('Избранное  ·  ' .. #favs, nil, 'ICON_FA_STAR')
  if #favs == 0 then F.empty('ICON_FA_STAR', 'Пусто', 'Добавь первую команду выше') end
  local act, at
  for i = 1, #favs do
    local f = favs[i]
    if F.fav_filter == '' or (f.group or '') == F.fav_filter then
      local p = imgui.GetCursorScreenPos()
      local w2 = F.inner_w()
      local h = F.s(50)
      local ib = F.s(30)
      local bx = p.x + w2 - F.s(6) - ib
      local tw = bx - (ib + 2) * 4 - p.x - F.s(16)
      local _, hovered = F.hotspot('##frow' .. i, p.x, p.y, math.max(1, tw), h)
      F.round_rect(p.x, p.y, w2, h - 4, hovered and F.col('raised') or F.col('side', 140), nil, 12)
      F.text_at(font_main, 16, p.x + F.s(12), p.y + F.s(5), F.col('text', 235), F.fit_text(font_main, F.fav_title(f), tw - F.s(12)))
      local sub = F.int_human(f.text)
      if f.group and f.group ~= '' then sub = f.group .. '  ·  ' .. sub end
      F.text_at(font_main, 16, p.x + F.s(12), p.y + F.s(25), F.col('text', 115), F.fit_text(font_main, sub, tw - F.s(12)))
      local iy = p.y + (h - 4 - ib) / 2
      if F.ghost_icon('##fdel' .. i, bx, iy, 'ICON_FA_TRASH', 'Удалить', true) then act, at = 'del', i end
      if F.ghost_icon('##fed' .. i, bx - ib - 2, iy, 'ICON_FA_PEN', 'Изменить') then act, at = 'edit', i end
      if F.ghost_icon('##fdn' .. i, bx - (ib + 2) * 2, iy, 'ICON_FA_ARROW_DOWN', 'Ниже') then act, at = 'down', i end
      if F.ghost_icon('##fup' .. i, bx - (ib + 2) * 3, iy, 'ICON_FA_ARROW_UP', 'Выше') then act, at = 'up', i end
      if F.ghost_icon('##fgo' .. i, bx - (ib + 2) * 4, iy, 'ICON_FA_PAPER_PLANE', 'Отправить') then act, at = 'go', i end
      F.advance(p, w2, h)
    end
  end
  F.card_end()
  if act == 'go' then F.fav_fire(favs[at])
  elseif act == 'del' then
    table.remove(favs, at)
    F.fav_clear_form()
    F.save_favs()
  elseif act == 'edit' then
    F.fav_edit = at
    F.buf_set(ui.fav_text, favs[at].text, 240)
    F.buf_set(ui.fav_label, favs[at].label or '', 80)
    F.buf_set(ui.fav_group, favs[at].group or '', 60)
  elseif act == 'up' and at > 1 then
    favs[at], favs[at - 1] = favs[at - 1], favs[at]
    F.fav_edit = nil
    F.save_favs()
  elseif act == 'down' and at < #favs then
    favs[at], favs[at + 1] = favs[at + 1], favs[at]
    F.fav_edit = nil
    F.save_favs()
  end
end

function F.int_row(token, title, sub, i)
  local p = imgui.GetCursorScreenPos()
  local w = F.inner_w()
  local h = F.s(50)
  local ib = F.s(30)
  local bx = p.x + w - F.s(6) - ib
  local isz = F.s(36)
  local tx = F.s(14) + isz
  local tw = bx - (ib + 2) * 3 - p.x - F.s(16)
  local clicked, hovered = F.hotspot('##irow' .. i, p.x, p.y, math.max(1, tw), h - 4)
  F.round_rect(p.x, p.y, w, h - 4, hovered and F.col('raised') or F.col('side', 140), nil, 12)
  F.lib_pic(F.lib_of_token(token), p.x + F.s(7), p.y + (h - 4 - isz) / 2, isz)
  F.text_at(font_main, 16, p.x + tx, p.y + F.s(5), F.col('accent_hi'), F.fit_text(font_main, title, tw - tx))
  F.text_at(font_main, 16, p.x + tx, p.y + F.s(25), F.col('text', 115), F.fit_text(font_main, sub, tw - tx))
  if hovered then F.tip(F.int_pick and 'Нажми, чтобы вставить' or ('Нажми, чтобы скопировать ' .. token)) end
  local iy = p.y + (h - 4 - ib) / 2
  if F.ghost_icon('##ibind' .. i, bx, iy, 'ICON_FA_BOLT', 'В бинд') then F.int_put('bind', token) end
  if F.ghost_icon('##inote' .. i, bx - ib - 2, iy, 'ICON_FA_STICKY_NOTE', 'В заметку') then F.int_put('note', token) end
  if F.ghost_icon('##ichat' .. i, bx - (ib + 2) * 2, iy, 'ICON_FA_PAPER_PLANE', 'В поле отправки') then F.int_put('chat', token) end
  if F.ghost_icon('##igame' .. i, bx - (ib + 2) * 3, iy, 'ICON_FA_COMMENT_DOTS', 'В чат игры') then F.int_put('game', token) end
  if clicked then
    if F.int_pick then F.int_put(F.int_pick, token)
    else F.note_copy(token) end
  end
  F.advance(p, w, h)
end

function F.int_pick_bar()
  if not F.int_pick then return end
  local names = {chat = 'поле отправки', note = 'заметку', bind = 'бинд', fav = 'избранное'}
  F.card_begin()
  F.hint('Выбери интеграцию, она вставится в ' .. (names[F.int_pick] or 'поле') .. '.', F.cvec('accent_hi'))
  if F.button('Отмена##ipick', 110, 0) then
    local back = F.int_pick
    F.int_pick = nil
    if back == 'note' then page = 'notes'
    elseif back == 'bind' then page = 'binds'
    elseif back == 'fav' then F.chat_tab = 'favs'
    else F.chat_tab = 'send' end
  end
  F.card_end()
end

function F.chat_tab_ints()
  F.int_pick_bar()
  F.card_begin('Как это работает', nil, 'ICON_FA_LINK')
  F.hint('fHelper запоминает предметы, лавки, телефоны, дома и бизнесы из чата. Нажми на строку, чтобы скопировать код вида :item123:, или на значок, чтобы вставить его сразу. Интеграцию из чата игры можно вставить через Ctrl+V: fHelper сам приведёт её к коду и выберет, команда это или сообщение.')
  if F.button(F.icon_label('ICON_FA_PASTE', 'Разобрать буфер обмена') .. '##iclip', 250, 0) then F.int_from_clip() end
  F.hint('Значки для объявлений:')
  local mark = F.pill_row('##imark', {
    {':buy:', 'BUY'}, {':sell:', 'SELL'}, {':CASH:', '$'}, {':CASHV:', 'VC$'},
  }, nil)
  if mark then
    if F.int_pick then F.int_put(F.int_pick, mark)
    else F.note_copy(mark) end
  end
  F.card_end()
  F.int_tab = F.int_tab or 'all'
  local tab = F.segment('itab', {
    {'all', 'Все'}, {'item', 'Предметы'}, {'lavka', 'Лавки'}, {'call', 'Телефоны'}, {'place', 'Дома и бизнесы'},
  }, F.int_tab)
  if tab then F.int_tab = tab end
  imgui.Spacing()
  F.field('##iq', 'Поиск по всем предметам или из чата', ui.int_q, 80, F.inner_w(), 'int_q')
  imgui.Spacing()
  local q = F.trim(F.buf_get(ui.int_q))
  local low = F.lower_fast(q)
  F.card_begin('Из чата', nil, 'ICON_FA_COMMENTS')
  local list = F.ints or {}
  local shown = 0
  for i = #list, 1, -1 do
    local r = list[i]
    local kind_ok = F.int_tab == 'all' or r.kind == F.int_tab or (F.int_tab == 'place' and (r.kind == 'biz' or r.kind == 'house'))
    if kind_ok and shown < 60 then
      local title = F.int_title(r.kind, r.id)
      if low == '' or q == r.token or F.lower_fast(title .. ' ' .. r.from):find(low, 1, true) then
        shown = shown + 1
        F.int_row(r.token, title, r.t .. '  ·  ' .. r.from, 'c' .. i)
      end
    end
  end
  if shown == 0 then F.hint('Здесь пока пусто. Интеграции появятся, когда пройдут в чате.') end
  F.card_end()
  if #low >= 2 and (F.int_tab == 'all' or F.int_tab == 'item') then
    local found = F.item_find(q)
    F.card_begin('Все предметы', #F.item_db().list == 0 and (F.is_rod() and 'Список предметов не найден' or 'Список предметов не найден, он приходит вместе с ArzMarket') or nil, 'ICON_FA_CUBES')
    if #found == 0 and #F.item_db().list > 0 then F.hint('Ничего не найдено.') end
    for i = 1, #found do
      local token = ':item' .. found[i].id .. ':'
      F.int_row(token, found[i].name, 'ID ' .. found[i].id .. '  ·  ' .. token, 'd' .. i)
    end
    F.card_end()
  end
end

-- Library

-- config\fhelp_lib.* holds every item of the game with its picture as PNG,
-- tools\build_lib.py makes them from arizona\items.zip.

F.LIB_CATS = {
  {'all', 'Все'}, {'chat', 'Из чата'}, {'acs', 'Аксессуары'}, {'skin', 'Одежда'}, {'car', 'Транспорт'},
  {'tune', 'Тюнинг'}, {'gun', 'Оружие'}, {'obj', 'Объекты'}, {'frame', 'Рамки'}, {'box', 'Кейсы'},
  {'etc', 'Разное'}, {'mark', 'Значки'},
}

F.LIB_ICON = {
  acs = 'ICON_FA_GEM', skin = 'ICON_FA_TSHIRT', car = 'ICON_FA_CAR', tune = 'ICON_FA_WRENCH',
  gun = 'ICON_FA_CROSSHAIRS', obj = 'ICON_FA_COUCH', frame = 'ICON_FA_ID_CARD', box = 'ICON_FA_BOX_OPEN',
  lavka = 'ICON_FA_STORE', call = 'ICON_FA_PHONE', biz = 'ICON_FA_BRIEFCASE', house = 'ICON_FA_HOME',
}

F.LIB_MARKS = {
  {token = ':buy:', name = 'Покупка', mark = 'BUY', low = 'покупка buy'},
  {token = ':sell:', name = 'Продажа', mark = 'SELL', low = 'продажа sell'},
  {token = ':CASH:', name = 'Доллары', mark = '$', low = 'доллары cash'},
  {token = ':CASHV:', name = 'Вайс-доллары', mark = 'VC$', low = 'вайс-доллары cash vc'},
}

function F.lib_db()
  if F._lib then return F._lib end
  local db = {list = {}, by_id = {}, cache = {}, cached = 0}
  F._lib = db
  local f = io.open(F.cfg_dir() .. '\\' .. F.proj().pack .. '.idx', 'rb')
  local data = f and f:read('*a') or ''
  if f then f:close() end
  db.stamp = tonumber(data:match('^#(%d+)'))
  for id, cat, io_, il, dat, dl, name in data:gmatch('(%d+)\t(%l+)\t(%d+)\t(%d+)\t(%d+)\t(%d+)\t([^\n]+)') do
    local it = {
      id = tonumber(id), cat = cat, name = name, token = ':item' .. id .. ':',
      pic_at = tonumber(io_), pic_n = tonumber(il), desc_at = tonumber(dat), desc_n = tonumber(dl),
    }
    db.by_id[it.id] = it
    if cat ~= 'twin' then
      it.low = F.lower_fast(name)
      db.list[#db.list + 1] = it
    end
  end
  db.packed = #db.list > 0
  if not db.packed and not F.is_rod() then
    local list = F.item_db().list
    for i = 1, #list do
      local src = list[i]
      local it = {id = src.id, cat = 'etc', name = src.name, low = src.low, token = ':item' .. src.id .. ':', pic_n = 0, desc_n = 0}
      db.by_id[it.id] = it
      db.list[i] = it
    end
  end
  return db
end

function F.lib_read(at, n)
  local db = F.lib_db()
  if db.fh == nil then db.fh = io.open(F.cfg_dir() .. '\\' .. F.proj().pack .. '.bin', 'rb') or false end
  if not db.fh or n <= 0 or not db.fh:seek('set', at) then return nil end
  return db.fh:read(n)
end

-- A texture lives only while its card is near the screen. Those drawn in the last frames
-- stay, their draw commands may still be waiting for the renderer.
function F.lib_trim(frame)
  local db, old = F.lib_db(), {}
  for at, e in pairs(db.cache) do
    if e.used < frame - 2 then old[#old + 1] = {at, e} end
  end
  table.sort(old, function(a, b) return a[2].used < b[2].used end)
  for i = 1, math.min(#old, db.cached - 200) do
    local at, e = old[i][1], old[i][2]
    if e.tex then pcall(imgui.ReleaseTexture, e.tex) end
    db.cache[at] = nil
    db.cached = db.cached - 1
  end
end

-- Every picture goes back to the game, on unload too: a reload must not keep the old ones.
function F.lib_free()
  local db = F._lib
  if not db then return 0 end
  local n = 0
  for at, e in pairs(db.cache) do
    if e.tex then
      pcall(imgui.ReleaseTexture, e.tex)
      n = n + 1
    end
    db.cache[at] = nil
  end
  db.cached = 0
  return n
end

-- GTA is a 32-bit game: at about 4 GB of address space it starts to stall and
-- loses textures, text turns into boxes. fHelper watches that and warns early.
F.MEM_WARN = 450

function F.mem_read()
  if not ffi_ok then return nil end
  if not F._mem_def then
    F._mem_def = pcall(ffi.cdef, [[
      typedef struct { unsigned long len; unsigned long load; unsigned long long tphys; unsigned long long aphys;
        unsigned long long tpage; unsigned long long apage; unsigned long long tvirt; unsigned long long avirt;
        unsigned long long aext; } FH_MEMSTAT;
      int __stdcall GlobalMemoryStatusEx(FH_MEMSTAT* p);
    ]]) or 'fail'
  end
  local ok, st = pcall(function()
    local m = ffi.new('FH_MEMSTAT')
    m.len = ffi.sizeof('FH_MEMSTAT')
    if ffi.C.GlobalMemoryStatusEx(m) == 0 then return nil end
    return {free = tonumber(m.avirt) / 1048576, total = tonumber(m.tvirt) / 1048576}
  end)
  if ok then return st end
  return nil
end

function F.mem_tick(now)
  if F._mem_at and now - F._mem_at < 15 then return end
  F._mem_at = now
  local st = F.mem_read()
  F.mem_st = st or {}
  F.mem_st.lua = collectgarbage('count') / 1024
  F.mem_st.pics = F._lib and F._lib.cached or 0
  if not st then return end
  if not F._mem_logged or now - F._mem_logged > 1800 then
    F._mem_logged = now
    F.log_line(string.format('Память: свободно у игры %.0f из %.0f МБ, fHelper %.0f МБ', st.free, st.total, F.mem_st.lua))
  end
  if st.free < F.MEM_WARN and (not F._mem_warned or now - F._mem_warned > 600) then
    F._mem_warned = now
    -- The pictures are the only big thing fHelper can give back right away.
    F.lib_free()
    collectgarbage('collect')
    local msg = string.format('Игре осталось %.0f МБ памяти. Скоро будут фризы и квадраты вместо текста, перезапусти игру', st.free)
    F.log_line(msg)
    F.chat_brand(msg)
    pcall(F.toast, 'sys', {force = true, key = 'mem', icon = 'ICON_FA_EXCLAMATION_TRIANGLE', title = 'Мало памяти', text = msg})
  end
end

function F.mem_text()
  local m = F.mem_st or {}
  local s = string.format('fHelper: %.0f МБ, картинок в памяти: %d', m.lua or collectgarbage('count') / 1024, m.pics or 0)
  if m.free then s = s .. string.format('. Свободно у игры: %.0f из %.0f МБ', m.free, m.total) end
  return s
end

function F.lib_tex(it)
  if not it.pic_n or it.pic_n <= 0 then return nil end
  local db, frame = F.lib_db(), imgui.GetFrameCount()
  local e = db.cache[it.pic_at]
  if e then
    e.used = frame
    return e.tex
  end
  -- Scrolling through the list must not stall the game.
  if db.frame ~= frame then db.frame, db.budget = frame, 8 end
  if db.budget <= 0 then return nil end
  db.budget = db.budget - 1
  local png = F.lib_read(it.pic_at, it.pic_n)
  local ok, tex = false, nil
  if png then ok, tex = pcall(imgui.CreateTextureFromFileInMemory, png, #png) end
  if not (ok and tex) and not db.pic_failed then
    db.pic_failed = true
    F.log_line('Библиотека: картинка не загрузилась: ' .. tostring(tex))
  end
  if not ok then tex = nil end
  db.cache[it.pic_at] = {tex = tex, used = frame}
  db.cached = db.cached + 1
  if db.cached > 320 then F.lib_trim(frame) end
  return tex
end

function F.lib_of_token(token)
  local id = tonumber(token:match('^:item(%d+):$'))
  if id then return F.lib_db().by_id[id] or {cat = 'etc'} end
  return {cat = token:match('^:(%l+)%d') or 'etc'}
end

function F.lib_pic(it, x, y, sz)
  local src = it.pic or it
  local tex = F.lib_tex(src)
  if tex then
    imgui.GetWindowDrawList():AddImage(tex, imgui.ImVec2(x, y), imgui.ImVec2(x + sz, y + sz))
    return
  end
  F.round_rect(x, y, sz, sz, F.col('accent', 36), nil, math.floor(sz / 4))
  local glyph = it.mark or F.faico(F.LIB_ICON[src.cat] or 'ICON_FA_CUBE')
  local gw = F.text_w(font_main, glyph)
  F.text_at(font_main, 16, x + (sz - gw) / 2, y + (sz - F.s(16)) / 2 - 1, F.col('accent_hi'), glyph)
end

-- The name on a card, in two lines at most.
function F.lib_lines(it, w)
  if it.line_w == w then return it.line1, it.line2 end
  local max_w = w / 0.875
  local one, rest = it.name, ''
  if F.text_w(font_main, one) > max_w then
    one = ''
    local pos = 1
    for word, stop in it.name:gmatch('(%S+)%s*()') do
      local try = one == '' and word or (one .. ' ' .. word)
      if F.text_w(font_main, try) > max_w then break end
      one, pos = try, stop
    end
    if one == '' then one = F.fit_text(font_main, it.name, max_w)
    else rest = F.fit_text(font_main, it.name:sub(pos), max_w) end
  end
  it.line_w, it.line1, it.line2 = w, one, rest
  it.cut = one .. (rest == '' and '' or ' ' .. rest) ~= it.name
  return one, rest
end

function F.lib_chat_cards()
  local list, out = F.ints or {}, {}
  for i = #list, 1, -1 do
    local r = list[i]
    local title = F.int_title(r.kind, r.id)
    local src = F.lib_of_token(r.token)
    out[#out + 1] = {
      token = r.token, name = title, pic = src, sub = r.t .. '  ·  ' .. r.from,
      low = F.lower_fast(title .. ' ' .. r.from),
    }
  end
  return out
end

function F.lib_view(cat, q)
  local ints = F.ints or {}
  local last = ints[#ints]
  local stamp = #ints .. (last and last.token or '')
  local v = F._lib_view
  if v and v.cat == cat and v.q == q and v.stamp == stamp then return v end
  v = {cat = cat, q = q, stamp = stamp, fresh = true}
  F._lib_view = v
  local list = F.lib_db().list
  if cat == 'chat' then list = F.lib_chat_cards()
  elseif cat == 'mark' then list = F.LIB_MARKS end
  local low = F.lower_fast(q)
  low = low:match('^:item(%d+):$') or low
  local id = tonumber(low)
  for i = 1, #list do
    local it = list[i]
    if (cat == 'all' or cat == 'chat' or cat == 'mark' or it.cat == cat)
      and (low == '' or (id and it.id == id) or (it.low or F.lower_fast(it.name)):find(low, 1, true)) then
      if it.id and it.id == id then table.insert(v, 1, it)
      else v[#v + 1] = it end
    end
  end
  return v
end

function F.lib_pick(it)
  if F.int_pick then
    F.int_put(F.int_pick, it.token)
    return
  end
  F.lib_sel = it
  F.note_copy(it.token)
end

function F.lib_card(it, x, y, w, h, hovered)
  local picked = F.lib_sel == it
  F.round_rect(x, y, w, h, (picked or hovered) and F.col('raised') or F.col('side', 140),
    picked and F.col('accent', 150) or F.col('text', hovered and 34 or 14), 10)
  local sz = F.s(56)
  F.lib_pic(it, x + (w - sz) / 2, y + F.s(6), sz)
  local one, two = F.lib_lines(it, w - F.s(10))
  local ty = y + F.s(66)
  F.text_at(font_main, 14, x + (w - F.text_w(font_main, one) * 0.875) / 2, ty, F.col('text'), one)
  F.text_at(font_main, 14, x + (w - F.text_w(font_main, two) * 0.875) / 2, ty + F.s(16), F.col('text', 170), two)
  if hovered then
    if it.cut then F.tip(it.name) end
    if imgui.IsMouseClicked(0) then F.lib_pick(it) end
  end
end

function F.lib_grid(v, w, h)
  local gap = math.floor(F.s(8))
  local inner = w - F.s(14)
  local cols = math.max(1, math.floor((inner + gap) / (F.s(112) + gap)))
  local cw = math.floor((inner - gap * (cols - 1)) / cols)
  local ch = math.floor(F.s(106))
  local rh = ch + gap
  imgui.BeginChild('##libgrid', imgui.ImVec2(w, h), false)
  if v.fresh then
    imgui.SetScrollY(0)
    v.fresh = false
  end
  local sy = imgui.GetScrollY()
  local base = imgui.GetCursorScreenPos()
  local rows = math.ceil(#v / cols)
  imgui.Dummy(imgui.ImVec2(1, math.max(1, rows * rh)))
  local hover_ok = imgui.IsWindowHovered()
  local m = imgui.GetMousePos()
  for r = math.floor(sy / rh), math.min(rows - 1, math.floor((sy + h) / rh)) do
    for c = 0, cols - 1 do
      local it = v[r * cols + c + 1]
      if it then
        local x, y = base.x + c * (cw + gap), base.y + r * rh
        local hovered = hover_ok and m.x >= x and m.x < x + cw and m.y >= y and m.y < y + ch
        F.lib_card(it, x, y, cw, ch, hovered)
      end
    end
  end
  imgui.EndChild()
end

function F.lib_info(w)
  local p = imgui.GetCursorScreenPos()
  local h = F.s(90)
  local it = F.lib_sel
  F.round_rect(p.x, p.y, w, h, F.col('panel'), F.col('text', 20), 14)
  if not it then
    F.text_at(font_main, 16, p.x + F.s(14), p.y + (h - F.s(16)) / 2 - 1, F.col('text', 130),
      F.fit_text(font_main, 'Нажми на карточку: код скопируется, а здесь появится описание.', w - F.s(28)))
    F.advance(p, w, h)
    return
  end
  local sz = F.s(72)
  F.lib_pic(it, p.x + F.s(9), p.y + (h - sz) / 2, sz)
  local ib = F.s(30)
  local tx = p.x + sz + F.s(20)
  local bx = p.x + w - F.s(8) - ib
  local tw = bx - (ib + 2) * 4 - tx
  F.text_at(font_main, 16, tx, p.y + F.s(7), F.col('accent_hi'), F.fit_text(font_main, it.name, tw))
  local src = it.pic or it
  if it.desc == nil then
    it.desc = src.desc_n and src.desc_n > 0 and F.lib_read(src.desc_at, src.desc_n) or ''
  end
  local text = it.desc ~= '' and it.desc or (it.sub or it.token)
  imgui.PushClipRect(imgui.ImVec2(tx, p.y), imgui.ImVec2(p.x + w - F.s(10), p.y + h - F.s(6)), true)
  F.text_at(font_main, 14, tx, p.y + F.s(31), F.col('text', 150), text, p.x + w - F.s(12) - tx)
  imgui.PopClipRect()
  local token = it.token
  local iy = p.y + F.s(2)
  if F.ghost_icon('##lcopy', bx, iy, 'ICON_FA_COPY', 'Копировать ' .. token) then F.note_copy(token) end
  if F.ghost_icon('##lbind', bx - ib - 2, iy, 'ICON_FA_BOLT', 'В бинд') then F.int_put('bind', token) end
  if F.ghost_icon('##lnote', bx - (ib + 2) * 2, iy, 'ICON_FA_STICKY_NOTE', 'В заметку') then F.int_put('note', token) end
  if F.ghost_icon('##lchat', bx - (ib + 2) * 3, iy, 'ICON_FA_PAPER_PLANE', 'В поле отправки') then F.int_put('chat', token) end
  if F.ghost_icon('##lgame', bx - (ib + 2) * 4, iy, 'ICON_FA_COMMENT_DOTS', 'В чат игры') then F.int_put('game', token) end
  F.advance(p, w, h)
end

function F.lib_stale(db)
  if db.stale == nil then
    local path = F.wd() .. '\\..\\' .. F.proj().folder .. '\\items.zip'
    local size = lfs_ok and lfs.attributes(path, 'size')
    db.stale = (size and db.stamp and size ~= db.stamp) or false
  end
  return db.stale
end

function F.chat_tab_lib()
  F.int_pick_bar()
  local db = F.lib_db()
  local w = F.inner_w()
  if not db.packed then
    F.hint('Файлы с картинками не найдены: нужны config\\' .. F.proj().pack .. '.idx и .bin.', F.cvec('accent_hi'))
  elseif F.lib_stale(db) then
    F.hint('Игра обновила предметы: новые могут быть без картинок.')
  end
  F.lib_cat = F.lib_cat or 'all'
  F.field('##libq', 'Поиск по названию или ID', ui.lib_q, 80, w, 'lib_q')
  imgui.Spacing()
  local cats = {}
  for i = 1, #F.LIB_CATS do
    local row = F.LIB_CATS[i]
    if row[1] ~= 'frame' or not F.is_rod() then cats[#cats + 1] = row end
  end
  local cat = F.pill_row('##libc', cats, F.lib_cat)
  if cat then F.lib_cat = cat end
  imgui.Spacing()
  F.lib_info(w)
  imgui.Spacing()
  local v = F.lib_view(F.lib_cat, F.trim(F.buf_get(ui.lib_q)))
  if #v == 0 then
    F.hint(F.lib_cat == 'chat' and v.q == '' and 'Здесь пока пусто. Интеграции появятся, когда пройдут в чате.' or 'Ничего не найдено.')
    return
  end
  local avail = imgui.GetContentRegionAvail()
  F.lib_grid(v, w, math.max(F.s(250), avail.y - 10))
end

function F.chat_tab_opts()
  F.card_begin('Избранное', nil, 'ICON_FA_SLIDERS_H')
  imgui.TextUnformatted('Нажатие на избранное')
  local m = F.segment('favm', {{0, 'Отправляет'}, {1, 'В поле отправки'}, {2, 'В чат игры'}}, cfg.fav_mode)
  if m then
    cfg.fav_mode = m
    dirty = true
  end
  imgui.Spacing()
  if F.switch('favclose', 'Закрывать меню после отправки', cfg.fav_close == 1, 'Удобно для докладов и отыгровок') then
    cfg.fav_close = cfg.fav_close == 1 and 0 or 1
    dirty = true
  end
  F.card_end()
  F.draw_accent()
  F.card_begin('История', nil, 'ICON_FA_HISTORY')
  if F.button('Очистить историю отправки##hclr', 280, 0, 'danger') then
    for i = #console_view, 1, -1 do console_view[i] = nil end
    F.notify('История очищена', true)
  end
  F.same_if_fit(F.s(280))
  if F.button('Очистить интеграции##iclr', 280, 0, 'danger') then
    F.ask('Забыть интеграции из чата?', 'Очистить', 'fn', {fn = function()
      F.ints = {}
      F.int_save()
      F.notify('Интеграции очищены', true)
    end})
  end
  F.card_end()
end

function F.draw_chat()
  F.page_head('Чат', 'Команды и сообщения, избранное, интеграции, библиотека и лог всего чата')
  F.chat_tab = F.chat_tab or 'send'
  local tab = F.segment('chat', {
    {'send', 'Отправка'}, {'favs', 'Избранное'}, {'ints', 'Интеграции'}, {'lib', 'Библиотека'}, {'log', 'Лог'}, {'opts', 'Настройки'},
  }, F.chat_tab)
  if tab then
    F.chat_tab = tab
    F.hot_field = nil
  end
  imgui.Spacing()
  if F.chat_tab == 'favs' then F.chat_tab_favs()
  elseif F.chat_tab == 'ints' then F.chat_tab_ints()
  elseif F.chat_tab == 'lib' then F.chat_tab_lib()
  elseif F.chat_tab == 'log' then F.chat_tab_log()
  elseif F.chat_tab == 'opts' then F.chat_tab_opts()
  else F.chat_tab_send() end
end

-- Chat log

-- Arizona already writes the whole chat to files, so fHelper reads those.
-- That also covers the time before fHelper and lines added by other scripts.
function F.clog_dir()
  local ok, docs = pcall(getFolderPath, 5)
  if not ok or type(docs) ~= 'string' or not lfs_ok then return nil end
  local dir = docs .. '\\GTA San Andreas User Files\\SAMP\\' .. F.proj().folder .. '\\chatlog'
  if lfs.attributes(dir, 'mode') ~= 'directory' then return nil end
  return dir
end

function F.clog_scan()
  local dir = F.clog_dir()
  local list = {}
  if dir then
    pcall(function()
      for name in lfs.dir(dir) do
        local mo, d, h, m = name:match('^%d+%-(%d+)%-(%d+) (%d+)%-(%d+)%-%d+%.txt$')
        if mo then
          list[#list + 1] = {
            name = name, title = d .. '.' .. mo .. '  ' .. h .. ':' .. m,
            size = lfs.attributes(dir .. '\\' .. name, 'size') or 0,
          }
        end
      end
    end)
  end
  table.sort(list, function(a, b) return a.name > b.name end)
  F.clog_files, F.clog_path = list, dir
  F.clog_scan_at = os.clock()
end

function F.clog_open(name, live, jump)
  F.clog = {
    name = name, live = live, jump = jump, follow = live,
    lines = {}, plain = {}, len = {}, view = {}, top = {}, cache = {}, cache_n = 0,
    rows = 0, last_rows = 0, cpr = 0, pos = 0, buf = '', at = 1, q = '', read_at = -9,
  }
  return F.clog
end

function F.clog_read(c)
  c.read_at = os.clock()
  local f = io.open(F.clog_path .. '\\' .. c.name, 'rb')
  if not f then return end
  f:seek('set', c.pos)
  local data = f:read('*a') or ''
  f:close()
  if data == '' then return end
  c.pos = c.pos + #data
  c.buf = c.buf:sub(c.at) .. data
  c.at = 1
end

-- A long line takes a few rows. The room is reserved before the line is drawn,
-- so it has a spare share for rows that end early on a word.
function F.clog_need(len, cpr)
  if len <= cpr then return 1 end
  return math.ceil(len / cpr * 1.12)
end

function F.clog_place(c, i)
  local k = #c.view + 1
  c.view[k] = i
  c.top[k] = c.rows
  c.rows = c.rows + F.clog_need(c.len[i], c.cpr)
end

function F.clog_add(c, raw)
  local line = F.int_pack(raw)
  local human = line
  if line:find(':%a') then human = F.int_human(line) end
  human = human:gsub('{%x%x%x%x%x%x}', '')
  local i = #c.lines + 1
  c.lines[i] = line
  c.plain[i] = human
  c.len[i] = select(2, human:gsub('[^\128-\191]', ''))
  if c.q == '' or F.lower_fast(human):find(c.q, 1, true) then F.clog_place(c, i) end
end

-- A big file is split over several frames, so opening it does not freeze the game.
function F.clog_pump(c)
  local stop = os.clock() + 0.006
  while os.clock() < stop do
    local e = c.buf:find('\n', c.at, true)
    if not e then break end
    F.clog_add(c, (c.buf:sub(c.at, e - 1):gsub('\r', '')))
    c.at = e + 1
  end
  if c.at > #c.buf then c.buf, c.at = '', 1 end
end

function F.clog_refilter(c)
  c.view, c.top, c.rows = {}, {}, 0
  c.cache, c.cache_n = {}, 0
  for i = 1, #c.lines do
    if c.q == '' or F.lower_fast(c.plain[i]):find(c.q, 1, true) then F.clog_place(c, i) end
  end
end

function F.clog_color(hex)
  local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
  -- Black text is fine in the game chat, but the panel here is dark.
  if r + g + b < 170 then return F.col('text', 225) end
  return F.rgba(r, g, b, 240)
end

function F.clog_chars(c, i)
  local human = F.int_human(c.lines[i])
  local ch, tone = {}, {}
  local col = F.col('text', 225)
  local function push(s, tint)
    for u in s:gmatch('[%z\1-\127\192-\247][\128-\191]*') do
      ch[#ch + 1] = u
      tone[#ch] = tint
    end
  end
  local pos = 1
  local stamp = human:match('^%[%d+:%d+:%d+%] ')
  if stamp then
    push(stamp, F.col('text', 105))
    pos = #stamp + 1
  end
  while true do
    local a, b = human:find('{%x%x%x%x%x%x}', pos)
    if not a then break end
    push(human:sub(pos, a - 1), col)
    col = F.clog_color(human:sub(a + 1, b - 1))
    pos = b + 1
  end
  push(human:sub(pos), col)
  return ch, tone
end

-- Rows of one line: every row is a list of {text, colour} runs.
function F.clog_rows(c, i)
  local cached = c.cache[i]
  if cached then return cached end
  local ch, tone = F.clog_chars(c, i)
  local cpr, n = c.cpr, #ch
  local cuts, s = {}, 1
  while n - s + 1 > cpr do
    local e = s + cpr - 1
    local k = e
    while k > s + cpr / 2 and ch[k] ~= ' ' do k = k - 1 end
    if ch[k] == ' ' then e = k end
    cuts[#cuts + 1] = e
    s = e + 1
  end
  if #cuts + 1 > F.clog_need(c.len[i], cpr) then
    cuts = {}
    for e = cpr, n - 1, cpr do cuts[#cuts + 1] = e end
  end
  cuts[#cuts + 1] = n
  local rows, from = {}, 1
  for r = 1, #cuts do
    local runs, a = {}, from
    while a <= cuts[r] do
      local b = a
      while b < cuts[r] and tone[b + 1] == tone[a] do b = b + 1 end
      runs[#runs + 1] = {table.concat(ch, '', a, b), tone[a]}
      a = b + 1
    end
    rows[r] = runs
    from = cuts[r] + 1
  end
  if c.cache_n > 300 then c.cache, c.cache_n = {}, 0 end
  c.cache[i] = rows
  c.cache_n = c.cache_n + 1
  return rows
end

function F.clog_first(c, row)
  local lo, hi = 1, #c.view
  while lo < hi do
    local mid = math.ceil((lo + hi) / 2)
    if c.top[mid] <= row then lo = mid else hi = mid - 1 end
  end
  return lo
end

function F.clog_draw(c, w, h)
  local rh = math.floor(F.s(21))
  imgui.BeginChild('##clogview', imgui.ImVec2(w, h), false)
  local sy = imgui.GetScrollY()
  local base = imgui.GetCursorScreenPos()
  imgui.Dummy(imgui.ImVec2(1, math.max(1, c.rows * rh)))
  if c.last_rows ~= c.rows then
    if c.follow then imgui.SetScrollHereY(1) end
    c.last_rows = c.rows
  elseif c.jump and c.buf == '' then
    local k = #c.view
    for j = 1, #c.view do
      if c.view[j] >= c.jump then
        k = j
        break
      end
    end
    if k > 0 then
      imgui.SetScrollY(math.max(0, c.top[k] * rh - h / 3))
      c.mark = c.view[k]
    end
    c.jump, c.follow = nil, false
  elseif not c.jump then
    c.follow = sy >= imgui.GetScrollMaxY() - rh * 2
  end
  if #c.view > 0 then
    local hover_ok = imgui.IsWindowHovered()
    local my = hover_ok and imgui.GetMousePos().y or -1
    local x = base.x + F.s(4)
    local k = F.clog_first(c, sy / rh)
    while k <= #c.view and c.top[k] * rh <= sy + h do
      local i = c.view[k]
      local y = base.y + c.top[k] * rh
      local rows = F.clog_rows(c, i)
      local lh = rows and #rows * rh or rh
      local hovered = my >= y and my < y + lh
      if c.mark == i then
        F.round_rect(base.x, y, w - F.s(10), lh, F.col('accent', 45), nil, 6)
      elseif hovered then
        F.round_rect(base.x, y, w - F.s(10), lh, F.col('text', 14), nil, 6)
      end
      for r = 1, #rows do
        local tx = x
        local ty = y + (r - 1) * rh + (rh - F.s(16)) / 2 - 1
        local runs = rows[r]
        for j = 1, #runs do
          F.text_at(font_main, 16, tx, ty, runs[j][2], runs[j][1])
          if j < #runs then tx = tx + F.text_w(font_main, runs[j][1]) end
        end
      end
      if hovered and imgui.IsMouseClicked(0) then
        F.note_copy((c.lines[i]:gsub('{%x%x%x%x%x%x}', '')))
      end
      k = k + 1
    end
  end
  imgui.EndChild()
end

function F.clog_grep(file, q, run)
  local f = io.open(F.clog_path .. '\\' .. file.name, 'rb')
  if not f then return end
  local data = f:read('*a') or ''
  f:close()
  local text = F.int_human(data)
  local low = F.lower_fast(text)
  local pos, line, mark = 1, 1, 1
  while #run.hits < 300 do
    local a = low:find(q, pos, true)
    if not a then return end
    while true do
      local e = text:find('\n', mark, true)
      if not e or e >= a then break end
      line = line + 1
      mark = e + 1
    end
    local e = text:find('\n', a, true) or (#text + 1)
    run.hits[#run.hits + 1] = {
      file = file, line = line,
      text = (text:sub(mark, e - 1):gsub('{%x%x%x%x%x%x}', ''):gsub('\r', '')),
    }
    pos = e + 1
  end
end

function F.clog_search(q)
  local run = {q = q, hits = {}, done = 0}
  F.clog_run = run
  local files = F.clog_files
  lua_thread.create(function()
    for i = 1, #files do
      if F.clog_run ~= run or #run.hits >= 300 then break end
      run.done = i
      local ok, err = pcall(F.clog_grep, files[i], q, run)
      if not ok then F.feed_err('поиск по логам', err) end
      wait(0)
    end
    run.finished = true
  end)
end

function F.clog_file_row(f, i, live)
  local p = imgui.GetCursorScreenPos()
  local w = imgui.GetContentRegionAvail().x
  local h = F.s(48)
  local clicked, hovered = F.hotspot('##clf' .. i, p.x, p.y, w, h - 4)
  local c = F.clog
  local active = c and c.name == f.name and (c.live or false) == live
  F.round_rect(p.x, p.y, w, h - 4, active and F.col('raised') or (hovered and F.col('hover', 150) or F.col('side', 130)),
    active and F.col('accent', 130) or nil, 11)
  F.text_at(font_main, 16, p.x + F.s(11), p.y + F.s(5), live and F.col('accent_hi') or F.col('text', 225), live and 'Сейчас' or f.title)
  local sub = math.max(1, math.floor(f.size / 1024 + 0.5)) .. ' КБ'
  F.text_at(font_main, 16, p.x + F.s(11), p.y + F.s(24), F.col('text', 110), live and (f.title .. '  ·  ' .. sub) or sub)
  F.advance(p, w, h)
  if clicked then F.clog_open(f.name, live) end
end

function F.clog_hit_row(hit, i)
  local p = imgui.GetCursorScreenPos()
  local w = imgui.GetContentRegionAvail().x - F.s(10)
  local h = F.s(48)
  local clicked, hovered = F.hotspot('##clh' .. i, p.x, p.y, w, h - 4)
  F.round_rect(p.x, p.y, w, h - 4, hovered and F.col('hover', 150) or F.col('side', 130), nil, 11)
  F.text_at(font_main, 16, p.x + F.s(11), p.y + F.s(5), F.col('text', 110), hit.file.title .. '  ·  строка ' .. hit.line)
  F.text_at(font_main, 16, p.x + F.s(11), p.y + F.s(24), F.col('text', 225), F.fit_text(font_main, hit.text, w - F.s(22)))
  F.advance(p, w, h)
  if clicked then
    F.clog_open(hit.file.name, F.clog_files[1].name == hit.file.name, hit.line)
    F.buf_set(ui.clog_q, '', 80)
    F.clog_scope = 'file'
  end
end

function F.clog_all_hits(q, w, h)
  local run = F.clog_run
  local text
  if #q < 2 then text = 'Напиши хотя бы 2 символа.'
  elseif not run then text = 'Ищу…'
  elseif not run.finished then text = 'Ищу: файл ' .. run.done .. ' из ' .. #F.clog_files .. ', найдено ' .. #run.hits
  elseif #run.hits >= 300 then text = 'Показаны первые 300 совпадений, начиная с новых логов'
  else text = 'Найдено: ' .. #run.hits end
  F.hint(text)
  imgui.BeginChild('##cloghits', imgui.ImVec2(w, math.max(40, h - F.s(26))), false)
  if run then
    for i = 1, #run.hits do F.clog_hit_row(run.hits[i], i) end
  end
  imgui.EndChild()
end

function F.clog_right(w, h)
  local fh = imgui.GetFrameHeight()
  local c = F.clog
  F.clog_scope = F.clog_scope or 'file'
  local sw = math.min(F.s(210), w * 0.45)
  F.field('##clq', 'Поиск по чату', ui.clog_q, 80, w - sw - 8, 'clog_q')
  imgui.SameLine()
  local scope = F.segment('clogs', {{'file', 'Этот лог'}, {'all', 'Все логи'}}, F.clog_scope, sw)
  if scope then
    F.clog_scope = scope
    F.clog_ask = nil
  end
  local q = F.lower_fast(F.trim(F.buf_get(ui.clog_q)))
  local now = os.clock()
  if F.clog_ask ~= q then F.clog_ask, F.clog_ask_at = q, now end
  local settled = now - (F.clog_ask_at or 0) > 0.3
  local body = h - fh - 8
  if F.clog_scope == 'all' then
    if settled and #q >= 2 and (not F.clog_run or F.clog_run.q ~= q) then F.clog_search(q) end
    F.clog_all_hits(q, w, body)
    return
  end
  if settled and c.q ~= q then
    c.q = q
    c.mark = nil
    F.clog_refilter(c)
  end
  local p = imgui.GetCursorScreenPos()
  local head = c.live and 'Идёт запись' or 'Сохранённый лог'
  local info = q ~= '' and (head .. '  ·  найдено ' .. #c.view) or (head .. '  ·  строк ' .. #c.lines)
  if c.buf ~= '' then info = 'Загрузка…  ' .. #c.lines end
  F.text_at(font_main, 16, p.x, p.y + F.s(5), F.col('text', 130), info .. '  ·  нажми на строку, чтобы скопировать')
  local ib = F.s(30)
  if F.ghost_icon('##clend', p.x + w - ib - F.s(8), p.y, 'ICON_FA_ARROW_DOWN', 'В конец') then
    c.follow = true
    c.last_rows = -1
  end
  F.advance(p, 1, ib)
  F.clog_draw(c, w, math.max(40, body - ib - 8))
end

function F.chat_tab_log()
  local now = os.clock()
  if not F.clog_files or now - (F.clog_scan_at or -9) > 3 then F.clog_scan() end
  local files = F.clog_files
  if #files == 0 then
    F.card_begin('Лог чата', nil, 'ICON_FA_FILE_ALT')
    F.hint('Файлы чата не найдены. Игра хранит их в «Документы\\GTA San Andreas User Files\\SAMP\\' .. F.proj().folder .. '\\chatlog».')
    F.card_end()
    return
  end
  local c = F.clog
  if not c or (c.live and c.name ~= files[1].name) then c = F.clog_open(files[1].name, true) end
  if c.read_at < 0 or (c.live and now - c.read_at > 0.5) then F.clog_read(c) end
  local avail = imgui.GetContentRegionAvail()
  local h = math.max(F.s(340), avail.y - 10)
  local gap = 12
  local left_w = math.floor(math.min(F.s(190), avail.x * 0.3))
  local right_w = avail.x - left_w - gap
  local pad = 12
  local inner = right_w - pad * 2
  local char_w = F.text_w(font_main, 'аеноп рст') / 9 * 1.14
  local cpr = math.max(20, math.floor((inner - F.s(24)) / math.max(1, char_w)))
  if cpr ~= c.cpr then
    c.cpr = cpr
    F.clog_refilter(c)
  end
  F.clog_pump(c)
  local p = imgui.GetCursorScreenPos()
  F.round_rect(p.x, p.y, left_w, h, F.col('panel'), F.col('text', 20), 16)
  F.round_rect(p.x + left_w + gap, p.y, right_w, h, F.col('panel'), F.col('text', 20), 16)
  imgui.PushStyleColor(imgui.Col.ChildBg, F.cvec('panel', 0))
  imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(pad, pad))
  imgui.BeginChild('##clogl', imgui.ImVec2(left_w, h), false, imgui.WindowFlags.AlwaysUseWindowPadding)
  F.clog_file_row(files[1], 0, true)
  for i = 2, #files do F.clog_file_row(files[i], i, false) end
  imgui.EndChild()
  imgui.SameLine(0, gap)
  imgui.BeginChild('##clogr', imgui.ImVec2(right_w, h), false, imgui.WindowFlags.AlwaysUseWindowPadding + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse)
  F.clog_right(inner, h - pad * 2)
  imgui.EndChild()
  imgui.PopStyleVar()
  imgui.PopStyleColor()
end

-- Notes

function F.note_first(s)
  local line = tostring(s or ''):match('^%s*([^\n]*)') or ''
  return F.int_human(line)
end

function F.note_row(n, i)
  local p = imgui.GetCursorScreenPos()
  local w = imgui.GetContentRegionAvail().x
  local h = F.s(50)
  local clicked, hovered = F.hotspot('##nrow' .. n.id, p.x, p.y, w, h - 4)
  local active = F.note_edit == n.id
  F.round_rect(p.x, p.y, w, h - 4, active and F.col('raised') or (hovered and F.col('hover', 150) or F.col('side', 130)),
    active and F.col('accent', 130) or nil, 11)
  local t = F.note_type(n.type)
  local pinned = F.pin_find(n.id)
  if pinned then F.text_at(font_main, 16, p.x + w - F.s(24), p.y + F.s(5), F.col('accent'), F.faico('ICON_FA_THUMBTACK')) end
  F.text_at(font_main, 16, p.x + F.s(11), p.y + F.s(5), F.col('text', active and 255 or 225), F.fit_text(font_main, F.note_first(n.text), w - F.s(pinned and 42 or 22)))
  local second = n.text:match('\n%s*([^\n]+)')
  local sub = t and t.name or ''
  if second then sub = sub .. '  ·  ' .. F.int_human(second) end
  F.text_at(font_main, 16, p.x + F.s(11), p.y + F.s(25), F.col('text', 110), F.fit_text(font_main, sub, w - F.s(22)))
  F.advance(p, w, h)
  if clicked then F.note_open(n.id) end
end

function F.notes_left()
  local fh = imgui.GetFrameHeight()
  local w = imgui.GetContentRegionAvail().x
  F.field('##nq', 'Поиск', ui.note_q, 80, w - fh - 8, 'note_q')
  imgui.SameLine()
  if F.icon_btn('ICON_FA_PLUS', 'nnew', 'Новая заметка', true) then F.note_new() end
  local counts = {}
  for i = 1, #F.note_items do
    local t = F.note_items[i].type
    counts[t] = (counts[t] or 0) + 1
  end
  if F.note_pick and not F.note_type(F.note_pick) then F.note_pick = nil end
  local list = {{0, 'Все  ' .. #F.note_items}}
  for i = 1, #F.note_types do
    local t = F.note_types[i]
    list[#list + 1] = {t.id, F.fit_text(font_main, t.name, F.s(130)) .. '  ' .. tostring(counts[t.id] or 0)}
  end
  local pick = F.pill_row('##nt', list, F.note_pick or 0)
  if pick then F.note_pick = pick ~= 0 and pick or nil end
  F.same_if_fit(F.s(30))
  local tp = imgui.GetCursorScreenPos()
  if F.ghost_icon('##ntnew', tp.x, tp.y, 'ICON_FA_FOLDER_PLUS', 'Новая папка') then
    F.note_addtype = not F.note_addtype
  end
  F.advance(tp, F.s(30), F.s(30))
  if F.note_pick then
    F.same_if_fit(F.s(30))
    local dp = imgui.GetCursorScreenPos()
    if F.ghost_icon('##ntdel', dp.x, dp.y, 'ICON_FA_TRASH', 'Удалить папку', true) then
      local id = F.note_pick
      F.ask('Удалить папку и все заметки в ней?', 'Удалить', 'fn', {fn = function()
        F.note_del_type(id)
        F.note_base = ''
      end})
    end
    F.advance(dp, F.s(30), F.s(30))
  end
  if F.note_addtype then
    local enter = imgui.InputTextWithHint('##ntype', 'Название папки', ui_ntype, 80, imgui.InputTextFlags.EnterReturnsTrue)
    if enter then
      F.note_flush()
      F.note_add_type(F.buf_get(ui_ntype))
      F.note_base = ''
      F.note_tsel = F.note_pick
      F.note_addtype = false
    end
  end
  imgui.Spacing()
  imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
  imgui.BeginChild('##nlist', imgui.ImVec2(0, 0), false)
  local q = F.lower_fast(F.trim(F.buf_get(ui.note_q)))
  local any = false
  for i = #F.note_items, 1, -1 do
    local n = F.note_items[i]
    if (not F.note_pick or n.type == F.note_pick) and (q == '' or F.lower_fast(F.int_human(n.text)):find(q, 1, true)) then
      any = true
      F.note_row(n, i)
    end
  end
  if not any then F.hint(q ~= '' and 'Ничего не найдено.' or 'Здесь пока пусто. Нажми +, чтобы создать заметку.') end
  imgui.EndChild()
  imgui.PopStyleVar()
end

function F.notes_right()
  local fh = imgui.GetFrameHeight()
  if not F.note_tsel or not F.note_type(F.note_tsel) then
    F.note_tsel = F.note_pick or (F.note_types[1] and F.note_types[1].id) or nil
  end
  local open = F.note_edit and F.note_find(F.note_edit)
  local p = imgui.GetCursorScreenPos()
  local w = imgui.GetContentRegionAvail().x
  F.text_at(font_bold, 18, p.x, p.y, F.col('text'), open and 'Заметка' or 'Новая заметка')
  if F.note_dirty() then
    local label = 'не сохранено'
    F.chip(p.x + w - F.chip_w(label), p.y - F.s(1), label, 'on')
  end
  F.advance(p, 1, F.s(26))
  if #F.note_types > 0 then
    local list = {}
    for i = 1, #F.note_types do
      list[#list + 1] = {F.note_types[i].id, F.fit_text(font_main, F.note_types[i].name, F.s(150))}
    end
    local pick = F.pill_row('##nsel', list, F.note_tsel)
    if pick then F.note_tsel = pick end
  end
  local text = F.buf_get(ui_ntext)
  local human = F.int_human(text)
  local has_int = human ~= text
  local pin = open and F.pin_find(open.id)
  local room = imgui.GetContentRegionAvail().y - fh - F.s(12) - (has_int and F.s(26) or 0)
    - (open and (fh + 8) or 0) - (pin and (fh + 8 + F.s(24)) or 0)
  F.ensure_paste_cb()
  local size = imgui.ImVec2(w, math.max(F.s(120), room))
  -- Without the callback ImGui must keep its own Ctrl+V, so nothing is muted.
  if F.paste_cb then
    F.suppress_bind_paste()
    imgui.InputTextMultiline('##ntext', ui_ntext, 2048, size, imgui.InputTextFlags.CallbackAlways, F.paste_cb, nil)
    F.restore_bind_paste()
  else
    imgui.InputTextMultiline('##ntext', ui_ntext, 2048, size)
  end
  F.note_hot = imgui.IsItemActive()
  if has_int then
    local pv = imgui.GetCursorScreenPos()
    local line = F.note_first(text)
    F.text_at(font_main, 16, pv.x, pv.y, F.col('accent_hi'), F.fit_text(font_main, 'В чате: ' .. line, w))
    F.advance(pv, w, F.s(20))
  end
  if F.accent_button('Сохранить##nsave', 130, 0) then F.note_commit() end
  imgui.SameLine()
  if F.icon_btn('ICON_FA_COPY', 'ncopy', 'Копировать') then F.note_copy(F.buf_get(ui_ntext)) end
  imgui.SameLine()
  if F.icon_btn('ICON_FA_PASTE', 'npaste', 'Вставить из буфера') then F.paste_note_buf() end
  imgui.SameLine()
  if F.icon_btn('ICON_FA_LINK', 'nint', 'Вставить интеграцию') then
    F.int_pick = 'note'
    F.chat_tab = 'lib'
    page = 'chat'
  end
  imgui.SameLine()
  if F.icon_btn('ICON_FA_COMMENT_DOTS', 'ngame', 'Подставить первую строку в чат игры') then F.to_game_chat(F.buf_get(ui_ntext)) end
  imgui.SameLine()
  if F.icon_btn('ICON_FA_PAPER_PLANE', 'nsend', 'Отправить первую строку') then
    local line = F.trim(F.buf_get(ui_ntext):match('^[^\n]*') or '')
    if line ~= '' then F.send_cmd(line, line:sub(1, 1) ~= '/') end
  end
  if open then
    imgui.SameLine()
    if F.icon_btn('ICON_FA_TRASH', 'ndel', 'Удалить заметку') then
      local id = open.id
      F.ask('Удалить эту заметку?', 'Удалить', 'fn', {fn = function() F.note_del(id) end})
    end
    F.note_pin_row(open, pin, w)
  end
end

function F.note_pin_row(n, pin, w)
  local fh = imgui.GetFrameHeight()
  local lw = F.s(84)
  local p = imgui.GetCursorScreenPos()
  F.text_at(font_main, 16, p.x, p.y + (fh - F.s(16)) / 2 - 1, F.col('text', 150), 'На экране')
  imgui.SetCursorScreenPos(imgui.ImVec2(p.x + lw, p.y))
  local mode = F.segment('npin', F.PIN_MODES, pin and pin.mode or 0, w - lw)
  if mode then
    F.note_flush()
    F.pin_set(n.id, mode)
  end
  if not pin then return end
  p = imgui.GetCursorScreenPos()
  F.text_at(font_main, 16, p.x, p.y + (fh - F.s(16)) / 2 - 1, F.col('text', 150), 'Ширина')
  imgui.SetCursorScreenPos(imgui.ImVec2(p.x + lw, p.y))
  local width = F.segment('npinw', F.PIN_W, pin.w, w - lw)
  if width then
    pin.w = width
    F.pin_save()
  end
  p = imgui.GetCursorScreenPos()
  F.text_at(font_main, 16, p.x, p.y, F.col('text', 115), F.fit_text(font_main, 'Двигай окошко за шапку, пока открыт этот раздел', w))
  F.advance(p, w, F.s(18))
end

function F.draw_notes()
  if not F.note_types then F.load_notes() end
  F.page_head('Заметки', 'Папки и список слева, редактор справа. При переключении заметка сохраняется сама')
  if not ui_ntype or not ui_ntext then
    F.note_hot = false
    F.hint('Поле заметок недоступно.')
    return
  end
  local avail = imgui.GetContentRegionAvail()
  local h = math.max(F.s(340), avail.y - 10)
  local gap = 12
  local left_w = math.floor(math.min(F.s(320), avail.x * 0.42))
  local right_w = avail.x - left_w - gap
  local p = imgui.GetCursorScreenPos()
  F.round_rect(p.x, p.y, left_w, h, F.col('panel'), F.col('text', 20), 16)
  F.round_rect(p.x + left_w + gap, p.y, right_w, h, F.col('panel'), F.col('text', 20), 16)
  imgui.PushStyleColor(imgui.Col.ChildBg, F.cvec('panel', 0))
  imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(12, 12))
  imgui.BeginChild('##nleft', imgui.ImVec2(left_w, h), false, imgui.WindowFlags.AlwaysUseWindowPadding + imgui.WindowFlags.NoScrollbar)
  F.notes_left()
  imgui.EndChild()
  imgui.SameLine(0, gap)
  imgui.BeginChild('##nright', imgui.ImVec2(right_w, h), false, imgui.WindowFlags.AlwaysUseWindowPadding + imgui.WindowFlags.NoScrollbar)
  F.notes_right()
  imgui.EndChild()
  imgui.PopStyleVar()
  imgui.PopStyleColor()
end

-- Pinned notes

F.PIN_MODES = {{0, 'Нет'}, {1, 'С меню'}, {2, 'Без меню'}, {3, 'Всегда'}}
F.PIN_W = {{260, 'Узкая'}, {340, 'Средняя'}, {460, 'Широкая'}}

function F.pin_load()
  F.pins = {}
  for _, row in ipairs(F.read_lines('fhelp_pins.txt')) do
    local id, mode, x, y, w = row:match('^([^|]*)|([123])|(-?%d+)|(-?%d+)|(%d+)$')
    if id then
      F.pins[#F.pins + 1] = {id = id, mode = tonumber(mode), x = tonumber(x), y = tonumber(y), w = tonumber(w)}
    end
  end
end

function F.pin_save()
  local rows = {}
  local list = F.pins or {}
  for i = 1, #list do
    local p = list[i]
    rows[i] = table.concat({p.id, p.mode, math.floor(p.x), math.floor(p.y), p.w}, '|')
  end
  F.write_lines('fhelp_pins.txt', rows)
end

function F.pin_find(id)
  local list = F.pins or {}
  for i = 1, #list do
    if list[i].id == id then return list[i], i end
  end
  return nil
end

function F.pin_set(id, mode)
  F.pins = F.pins or {}
  local p, i = F.pin_find(id)
  if mode == 0 then
    if i then table.remove(F.pins, i) end
  elseif p then
    p.mode = mode
  else
    F.pins[#F.pins + 1] = {id = id, mode = mode, x = -1, y = -1, w = 340}
  end
  F.pin_save()
end

-- The Notes page shows every pin, or a pin set to "without menu" could never be moved.
function F.pin_shown(p)
  if show and page == 'notes' then return true end
  if p.mode == 3 then return true end
  if p.mode == 1 then return show end
  return not show
end

function F.pins_on()
  if hidden or not F.pins or #F.pins == 0 then return false end
  local ok, pause = pcall(isPauseMenuActive)
  if ok and pause then return false end
  for i = 1, #F.pins do
    if F.pin_shown(F.pins[i]) then return true end
  end
  return false
end

function F.draw_pin(p, n, i)
  local io = imgui.GetIO()
  local sw, sh = io.DisplaySize.x, io.DisplaySize.y
  local ww = math.floor(F.s(p.w))
  local head = show and F.s(34) or 0
  local pad = F.s(12)
  local wh = math.min(sh * 0.85, head + (p.text_h or F.s(60)) + pad * 2)
  local x, y = p.x, p.y
  if x < 0 then x = 24 end
  if y < 0 then y = sh * 0.3 + (i - 1) * F.s(30) end
  x = math.max(0, math.min(sw - ww, x))
  y = math.max(0, math.min(sh - wh, y))
  local WF = imgui.WindowFlags
  local flags = WF.NoTitleBar + WF.NoResize + WF.NoScrollbar + WF.NoScrollWithMouse
    + WF.NoCollapse + WF.NoSavedSettings + WF.NoMove + WF.NoFocusOnAppearing
  if not show then flags = flags + WF.NoMouseInputs end
  imgui.SetNextWindowPos(imgui.ImVec2(x, y), imgui.Cond.Always)
  imgui.SetNextWindowSize(imgui.ImVec2(ww, wh), imgui.Cond.Always)
  imgui.Begin('fhelp-pin' .. p.id, nil, flags)
  if imgui.SetWindowFontScale then imgui.SetWindowFontScale(cfg.scale or 1) end
  local wp = imgui.GetWindowPos()
  F.round_rect(wp.x, wp.y, ww, wh, F.col('bg', 225), F.col('text', 34), 14)
  if show then
    imgui.SetCursorPos(imgui.ImVec2(0, 0))
    imgui.InvisibleButton('##pindrag', imgui.ImVec2(math.max(1, ww - F.s(36)), head))
    local active = imgui.IsItemActive()
    if active and imgui.IsMouseDragging(0) then
      p.x = math.max(0, math.min(sw - ww, x + io.MouseDelta.x))
      p.y = math.max(0, math.min(sh - wh, y + io.MouseDelta.y))
      p.moved = true
    elseif p.moved and not active then
      p.moved = nil
      F.pin_save()
    end
    local t = F.note_type(n.type)
    F.text_at(font_main, 16, wp.x + pad, wp.y + (head - F.s(16)) / 2 - 1, F.col('accent'), F.faico('ICON_FA_THUMBTACK'))
    F.text_at(font_main, 16, wp.x + pad + F.s(20), wp.y + (head - F.s(16)) / 2 - 1, F.col('text', 170),
      F.fit_text(font_main, t and t.name or 'Заметка', ww - pad * 2 - F.s(60)))
    if F.ghost_icon('##pinx' .. p.id, wp.x + ww - F.s(34), wp.y + F.s(2), 'ICON_FA_TIMES', 'Открепить') then
      F.pin_set(p.id, 0)
    end
  end
  local text = F.int_human(n.text)
  p.text_h = imgui.CalcTextSize(text, nil, false, ww - pad * 2).y
  imgui.SetCursorPos(imgui.ImVec2(pad, head + pad))
  imgui.PushTextWrapPos(ww - pad)
  imgui.TextUnformatted(text)
  imgui.PopTextWrapPos()
  imgui.End()
end

function F.draw_pins()
  F.style_push(cfg.opacity)
  F.use_font(font_main)
  for i = #F.pins, 1, -1 do
    local p = F.pins[i]
    local n = F.note_find(p.id)
    if not n then
      table.remove(F.pins, i)
      F.pin_save()
    elseif F.pin_shown(p) then
      F.draw_pin(p, n, i)
    end
  end
  F.done_font(font_main)
  F.style_pop()
end

-- Calculator

-- Recursive descent, so no text from the field ever reaches load().
function F.calc_eval(src)
  local s = F.lower_fast(src or '')
  s = s:gsub('%s', ''):gsub('×', '*'):gsub('÷', '/'):gsub('−', '-'):gsub('х', '*')
  if s == '' then return nil, 'Пустое выражение' end
  local pos = 1
  local function fail(msg) error({calc = msg}, 0) end
  local function take(str)
    if s:sub(pos, pos + #str - 1) == str then
      pos = pos + #str
      return true
    end
    return false
  end
  local function suffix(n)
    while true do
      if take('млрд') then n = n * 1e9
      elseif take('млн') then n = n * 1e6
      elseif take('м') or take('m') then n = n * 1e6
      elseif take('b') then n = n * 1e9
      elseif take('к') or take('k') then n = n * 1000
      else return n end
    end
  end
  local function number()
    local a, b = s:find('^%d[%d%.,]*', pos)
    if not a then a, b = s:find('^[%.,]%d+', pos) end
    if not a then return nil end
    local t = s:sub(a, b)
    pos = b + 1
    local _, marks = t:gsub('[%.,]', '')
    -- 1.234.567 is how the game writes sums, one mark is a decimal point.
    if marks > 1 then t = t:gsub('[%.,]', '')
    else t = t:gsub(',', '.') end
    return tonumber(t) or fail('Не понял число ' .. t)
  end
  local expr
  local function primary()
    if take('(') then
      local v = expr()
      if not take(')') then fail('Не хватает скобки') end
      return suffix(v)
    end
    if take('ans') or take('ответ') then
      return tonumber(F.calc_last) or 0
    end
    local n = number()
    if not n then fail('Ошибка в выражении') end
    return suffix(n)
  end
  local function unary()
    if take('-') then
      local v, pct = unary()
      return -v, pct
    end
    if take('+') then return unary() end
    local v = primary()
    if take('%') then return v, true end
    return v, false
  end
  local function power()
    local v, pct = unary()
    if take('^') then
      local e = power()
      return v ^ e, false
    end
    return v, pct
  end
  local function term()
    local v, pct = power()
    while true do
      if take('*') then
        local r, rp = power()
        v = v * (rp and r / 100 or r)
        pct = false
      elseif take('/') or take(':') then
        local r, rp = power()
        if rp then r = r / 100 end
        if r == 0 then fail('На ноль делить нельзя') end
        v = v / r
        pct = false
      else
        return v, pct
      end
    end
  end
  expr = function()
    local v, pct = term()
    if pct then v = v / 100 end
    while true do
      if take('+') then
        local r, rp = term()
        v = v + (rp and v * r / 100 or r)
      elseif take('-') then
        local r, rp = term()
        v = v - (rp and v * r / 100 or r)
      else
        return v
      end
    end
  end
  local ok, res = pcall(expr)
  if not ok then
    if type(res) == 'table' and res.calc then return nil, res.calc end
    return nil, 'Ошибка в выражении'
  end
  if pos <= #s then return nil, 'Лишние символы: ' .. F.utf_cut(s:sub(pos), 16) end
  if res ~= res or res == math.huge or res == -math.huge then return nil, 'Слишком большое число' end
  return res
end

function F.calc_plain(v)
  v = tonumber(v) or 0
  if math.abs(v - math.floor(v + 0.5)) < 1e-9 then return string.format('%.0f', v) end
  local s = string.format('%.4f', v):gsub('0+$', ''):gsub('%.$', '')
  return s
end

function F.calc_fmt(v)
  v = tonumber(v) or 0
  local neg = v < 0
  local body = F.calc_plain(math.abs(v))
  local whole, frac = body:match('^(%d+)(%.?%d*)$')
  if not whole then return body end
  local out = whole:reverse():gsub('(%d%d%d)', '%1 '):reverse():gsub('^ ', '')
  return (neg and '-' or '') .. out .. (frac or '')
end

function F.calc_load()
  F.calc_hist = {}
  for _, row in ipairs(F.read_lines('fhelp_calc.txt')) do
    local expr, val = row:match('^(.*)|([^|]*)$')
    if expr and tonumber(val) then
      F.calc_hist[#F.calc_hist + 1] = {expr = expr, val = tonumber(val)}
    end
  end
  local last = F.calc_hist[#F.calc_hist]
  if last then F.calc_last = last.val end
end

function F.calc_save()
  local rows = {}
  for i = 1, #(F.calc_hist or {}) do
    local r = F.calc_hist[i]
    rows[#rows + 1] = (r.expr:gsub('|', '/')) .. '|' .. F.calc_plain(r.val)
  end
  F.write_lines('fhelp_calc.txt', rows)
end

function F.calc_run(text)
  text = F.trim(text or '')
  if text == '' then return nil end
  local v, err = F.calc_eval(text)
  if not v then
    F.calc_err = err
    return nil
  end
  F.calc_err = nil
  F.calc_last = v
  F.calc_hist = F.calc_hist or {}
  local top = F.calc_hist[#F.calc_hist]
  if not top or top.expr ~= text then
    F.calc_hist[#F.calc_hist + 1] = {expr = text, val = v}
    while #F.calc_hist > 100 do table.remove(F.calc_hist, 1) end
    F.calc_save()
  end
  return v
end

function F.calc_press(key)
  if key == 'C' then
    F.buf_set(ui.calc, '', 160)
    F.calc_err = nil
  elseif key == '<' then
    local s = F.buf_get(ui.calc)
    -- Cyrillic letters take two bytes.
    local last = s:byte(#s)
    F.buf_set(ui.calc, s:sub(1, (last and last >= 128) and -3 or -2), 160)
  elseif key == '=' then
    local v = F.calc_run(F.buf_get(ui.calc))
    if v then F.buf_set(ui.calc, F.calc_plain(v), 160) end
  else
    F.buf_set(ui.calc, F.buf_get(ui.calc) .. key, 160)
  end
end

F.CALC_KEYS = {
  {'C', '(', ')', '/'},
  {'7', '8', '9', '*'},
  {'4', '5', '6', '-'},
  {'1', '2', '3', '+'},
  {'0', '.', 'кк', '%'},
  {'<', 'к', 'ккк', '='},
}

function F.calc_pad(id, w)
  local gap = 6
  local cw = (w - gap * 3) / 4 / (cfg.scale or 1)
  for y = 1, #F.CALC_KEYS do
    local row = F.CALC_KEYS[y]
    for x = 1, 4 do
      if x > 1 then imgui.SameLine(0, gap) end
      local key = row[x]
      local label = key == '<' and (F.faico('ICON_FA_BACKSPACE') ~= '' and F.faico('ICON_FA_BACKSPACE') or '<') or key
      local kind = key == '=' and 'primary' or (key == 'C' and 'danger' or nil)
      if F.button(label .. '##k' .. id .. y .. x, cw, 34, kind) then F.calc_press(key) end
    end
  end
end

function F.calc_screen(id, w)
  local text = F.buf_get(ui.calc)
  local live_v = text ~= '' and F.calc_eval(text) or nil
  local p = imgui.GetCursorScreenPos()
  local h = F.s(66)
  F.round_rect(p.x, p.y, w, h, F.col('side'), F.col('text', 18), 12)
  local shown = live_v or F.calc_last
  local big = shown and F.calc_fmt(shown) or '0'
  big = F.fit_text(font_title, big, w - F.s(24))
  F.text_at(font_title, 22, p.x + w - F.s(12) - F.text_w(font_title, big), p.y + F.s(32), F.col('text'), big)
  local top = F.calc_err or (text ~= '' and text or 'Результат')
  F.text_at(font_main, 16, p.x + F.s(12), p.y + F.s(8), F.calc_err and F.col('bad') or F.col('text', 120), F.fit_text(font_main, top, w - F.s(24)))
  F.advance(p, w, h)
  local fh = imgui.GetFrameHeight()
  imgui.PushItemWidth(w - fh - 8)
  local enter = imgui.InputTextWithHint('##calc' .. id, '2.5кк * 3 + 10%', ui.calc, 160, imgui.InputTextFlags.EnterReturnsTrue)
  imgui.PopItemWidth()
  if enter then imgui.SetKeyboardFocusHere(-1) end
  imgui.SameLine()
  if F.icon_btn('ICON_FA_EQUALS', 'ceq' .. id, 'Посчитать', true) or enter then F.calc_press('=') end
end

function F.calc_rows(id, cap)
  local list = F.calc_hist or {}
  local pick
  local shown = 0
  for i = #list, 1, -1 do
    if shown >= cap then break end
    shown = shown + 1
    local r = list[i]
    local p = imgui.GetCursorScreenPos()
    local w = F.inner_w()
    local h = F.s(28)
    local clicked, hovered = F.hotspot('##ch' .. id .. i, p.x, p.y, w, h)
    if hovered then
      F.round_rect(p.x, p.y, w, h, F.col('text', 14), nil, 8)
      F.tip('Нажми, чтобы подставить. Правая кнопка копирует ответ')
    end
    local res = '= ' .. F.calc_fmt(r.val)
    local rw = F.text_w(font_main, res)
    F.text_at(font_main, 16, p.x + 6, p.y + (h - F.s(16)) / 2 - 1, F.col('text', 150), F.fit_text(font_main, r.expr, w - rw - 24))
    F.text_at(font_main, 16, p.x + w - rw - 6, p.y + (h - F.s(16)) / 2 - 1, F.col('accent_hi'), res)
    if hovered and imgui.IsMouseClicked(1) then F.note_copy(F.calc_plain(r.val)) end
    if clicked then pick = r.expr end
    F.advance(p, w, h)
  end
  if shown == 0 then F.hint('История пуста.') end
  if pick then F.buf_set(ui.calc, pick, 160) end
end

function F.draw_calc()
  F.page_head('Калькулятор', 'Понимает к, кк, ккк, млн, млрд, проценты и скобки. Например: 2.5кк * 3 + 10%')
  F.card_begin('Расчёт', nil, 'ICON_FA_CALCULATOR')
  local w = F.inner_w()
  F.calc_screen('p', w)
  imgui.Spacing()
  F.calc_pad('p', w)
  F.card_end()
  F.card_begin('Окошко на экране', 'Перетаскивается за шапку. Ввод в нём включает /fcalc или клавиша из раздела «Клавиши»', 'ICON_FA_WINDOW_MAXIMIZE')
  if F.switch('calcwin', 'Показывать окошко', cfg.calc_win == 1) then
    cfg.calc_win = cfg.calc_win == 1 and 0 or 1
    dirty = true
  end
  imgui.TextUnformatted('Когда показывать')
  local m = F.segment('calcm', {{0, 'Только когда видно fHelper'}, {1, 'Всегда'}}, cfg.calc_mode)
  if m then
    cfg.calc_mode = m
    dirty = true
  end
  imgui.Spacing()
  if F.switch('calcpad', 'Кнопки в окошке', cfg.calc_pad == 1, 'Без них окошко меньше') then
    cfg.calc_pad = cfg.calc_pad == 1 and 0 or 1
    dirty = true
  end
  if F.button('Вернуть окошко на место##calcpos', 260, 0) then
    cfg.calc_x, cfg.calc_y = -1, -1
    dirty = true
  end
  F.card_end()
  F.card_begin('История', nil, 'ICON_FA_HISTORY')
  F.calc_rows('p', 30)
  if #(F.calc_hist or {}) > 0 then
    imgui.Spacing()
    if F.button('Очистить историю##calcclr', 220, 0, 'danger') then
      F.calc_hist = {}
      F.calc_save()
    end
  end
  F.card_end()
end

function F.calc_win_on()
  if F.calc_frame then
    F.calc_frame.HideCursor = not F.calc_focus
    F.calc_frame.LockPlayer = F.calc_focus and true or false
  end
  if hidden then return false end
  if F.calc_focus then return true end
  if cfg.calc_win ~= 1 then return false end
  local ok, pause = pcall(isPauseMenuActive)
  if ok and pause then return false end
  return cfg.calc_mode == 1 or show
end

function F.draw_calc_win()
  local interactive = show or F.calc_focus
  local io = imgui.GetIO()
  local sw, sh = io.DisplaySize.x, io.DisplaySize.y
  local ww = math.floor(F.s(300))
  local fh = imgui.GetFrameHeight()
  local head = F.s(38)
  local pad_h = cfg.calc_pad == 1 and (#F.CALC_KEYS * (F.s(34) + 8) + 4) or 0
  local rows = math.min(4, #(F.calc_hist or {}))
  local wh = math.floor(head + F.s(66) + 8 + fh + 8 + pad_h + rows * (F.s(28) + 8) + F.s(30))
  local x, y = cfg.calc_x, cfg.calc_y
  if not x or x < 0 then x = math.max(8, sw - ww - 24) end
  if not y or y < 0 then y = math.max(8, (sh - wh) / 2) end
  if x > sw - 60 then x = sw - ww end
  if y > sh - 40 then y = math.max(0, sh - wh) end
  local WF = imgui.WindowFlags
  local flags = WF.NoTitleBar + WF.NoResize + WF.NoScrollbar + WF.NoScrollWithMouse
    + WF.NoCollapse + WF.NoSavedSettings + WF.NoMove + WF.NoFocusOnAppearing
  if not interactive then flags = flags + WF.NoMouseInputs end
  imgui.SetNextWindowPos(imgui.ImVec2(x, y), imgui.Cond.Always)
  imgui.SetNextWindowSize(imgui.ImVec2(ww, wh), imgui.Cond.Always)
  F.style_push(cfg.opacity)
  F.use_font(font_main)
  imgui.Begin('fhelp-calc', nil, flags)
  if imgui.SetWindowFontScale then imgui.SetWindowFontScale(cfg.scale or 1) end
  local wp = imgui.GetWindowPos()
  F.round_rect(wp.x, wp.y, ww, wh, F.col('bg'), F.col('text', 34), 16)
  imgui.SetCursorPos(imgui.ImVec2(0, 0))
  imgui.InvisibleButton('##calcdrag', imgui.ImVec2(math.max(1, ww - F.s(40)), head))
  if imgui.IsItemActive() and imgui.IsMouseDragging(0) then
    local md = io.MouseDelta
    cfg.calc_x = math.max(0, math.min(sw - ww, x + md.x))
    cfg.calc_y = math.max(0, math.min(sh - wh, y + md.y))
    dirty = true
  end
  local glyph = F.faico('ICON_FA_CALCULATOR')
  F.text_at(font_main, 16, wp.x + F.s(14), wp.y + (head - F.s(16)) / 2 - 1, F.col('accent'), glyph)
  F.text_at(font_bold, 18, wp.x + F.s(36), wp.y + (head - F.s(18)) / 2 - 1, F.col('text'), 'Калькулятор')
  local cx = wp.x + ww - F.s(36)
  if interactive and F.ghost_icon('##calcx', cx, wp.y + F.s(4), 'ICON_FA_TIMES', F.calc_focus and 'Выключить ввод' or 'Скрыть окошко') then
    if F.calc_focus then F.calc_focus = false
    else
      cfg.calc_win = 0
      dirty = true
    end
  end
  imgui.SetCursorPos(imgui.ImVec2(0, head))
  imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(F.s(12), 0))
  imgui.PushStyleColor(imgui.Col.ChildBg, F.cvec('bg', 0))
  imgui.BeginChild('##calcbody', imgui.ImVec2(ww, wh - head), false, WF.AlwaysUseWindowPadding + WF.NoScrollbar + WF.NoScrollWithMouse)
  local w = imgui.GetContentRegionAvail().x
  F.calc_screen('w', w)
  if cfg.calc_pad == 1 then
    imgui.Dummy(imgui.ImVec2(1, 1))
    F.calc_pad('w', w)
  end
  if interactive then F.calc_rows('w', rows)
  else
    F.hint('Ввод: /fcalc')
    F.calc_rows('w', rows)
  end
  imgui.EndChild()
  imgui.PopStyleColor()
  imgui.PopStyleVar()
  imgui.End()
  F.done_font(font_main)
  F.style_pop()
end

function F.calc_cmd(arg)
  local text = F.trim(F.game_text(arg or ''))
  if text == '' then
    F.calc_focus = not F.calc_focus
    if F.calc_focus then cfg.calc_win = 1 end
    dirty = true
    return
  end
  local v = F.calc_run(text)
  if v then F.chat_brand(text .. ' = ' .. F.calc_fmt(v))
  else F.chat_brand(F.calc_err or 'Ошибка в выражении') end
end

-- Craft

function F.craft_state()
  if not F.craft then F.craft = {list = {}, rows = {}, cur = nil} end
  return F.craft
end

function F.craft_row(name, price, qty, have)
  local r = {
    name = imgui.new.char[64](), price = imgui.new.char[24](),
    qty = imgui.new.char[24](), have = imgui.new.char[24](),
  }
  F.buf_set(r.name, name or '', 64)
  F.buf_set(r.price, price or '', 24)
  F.buf_set(r.qty, qty or '', 24)
  F.buf_set(r.have, have or '', 24)
  return r
end

function F.craft_blank()
  local st = F.craft_state()
  st.cur = nil
  st.rows = {F.craft_row()}
  F.buf_set(ui.craft_name, '', 120)
  F.buf_set(ui.craft_tries, '1', 24)
  F.buf_set(ui.craft_chance, '100', 24)
  F.buf_set(ui.craft_out, '1', 24)
  F.buf_set(ui.craft_sell, '', 24)
end

function F.craft_open(i)
  local st = F.craft_state()
  local rec = st.list[i]
  if not rec then return end
  st.cur = i
  F.buf_set(ui.craft_name, rec.name, 120)
  F.buf_set(ui.craft_tries, rec.tries, 24)
  F.buf_set(ui.craft_chance, rec.chance, 24)
  F.buf_set(ui.craft_out, rec.out, 24)
  F.buf_set(ui.craft_sell, rec.sell, 24)
  st.rows = {}
  for j = 1, #rec.items do
    local it = rec.items[j]
    st.rows[j] = F.craft_row(it.name, it.price, it.qty, it.have)
  end
  if #st.rows == 0 then st.rows[1] = F.craft_row() end
end

function F.craft_load()
  local st = F.craft_state()
  st.list = {}
  local rec
  for _, row in ipairs(F.read_lines('fhelp_craft.txt')) do
    local kind, rest = row:match('^(.)|(.*)$')
    if kind == 'R' then
      local name, tries, chance, out, sell = rest:match('^([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)$')
      if name then
        rec = {name = name, tries = tries, chance = chance, out = out, sell = sell, items = {}}
        st.list[#st.list + 1] = rec
      end
    elseif kind == 'I' and rec then
      local name, price, qty, have = rest:match('^([^|]*)|([^|]*)|([^|]*)|([^|]*)$')
      if name then rec.items[#rec.items + 1] = {name = name, price = price, qty = qty, have = have} end
    end
  end
end

function F.craft_write()
  local st = F.craft_state()
  local rows = {}
  local function clean(s) return (tostring(s or ''):gsub('|', '/')) end
  for i = 1, #st.list do
    local r = st.list[i]
    rows[#rows + 1] = 'R|' .. clean(r.name) .. '|' .. clean(r.tries) .. '|' .. clean(r.chance) .. '|' .. clean(r.out) .. '|' .. clean(r.sell)
    for j = 1, #r.items do
      local it = r.items[j]
      rows[#rows + 1] = 'I|' .. clean(it.name) .. '|' .. clean(it.price) .. '|' .. clean(it.qty) .. '|' .. clean(it.have)
    end
  end
  F.write_lines('fhelp_craft.txt', rows)
end

function F.craft_save()
  local st = F.craft_state()
  local name = F.trim(F.buf_get(ui.craft_name))
  if name == '' then
    F.notify('Напиши, что крафтишь', true)
    return
  end
  local rec = {
    name = name, tries = F.buf_get(ui.craft_tries), chance = F.buf_get(ui.craft_chance),
    out = F.buf_get(ui.craft_out), sell = F.buf_get(ui.craft_sell), items = {},
  }
  for i = 1, #st.rows do
    local r = st.rows[i]
    local n = F.trim(F.buf_get(r.name))
    if n ~= '' then
      rec.items[#rec.items + 1] = {name = n, price = F.buf_get(r.price), qty = F.buf_get(r.qty), have = F.buf_get(r.have)}
    end
  end
  if st.cur and st.list[st.cur] then
    st.list[st.cur] = rec
  else
    st.list[#st.list + 1] = rec
    st.cur = #st.list
  end
  F.craft_write()
  F.notify('Рецепт сохранён', true)
end

function F.craft_num(buf, default)
  local s = F.trim(F.buf_get(buf))
  if s == '' then return default end
  local v = F.calc_eval(s)
  if not v then return default, true end
  return v
end

-- Everything is counted live from the fields.
function F.craft_calc()
  local st = F.craft_state()
  local tries = math.max(0, F.craft_num(ui.craft_tries, 1) or 1)
  local chance = F.craft_num(ui.craft_chance, 100) or 100
  if chance < 0 then chance = 0 elseif chance > 100 then chance = 100 end
  local out = math.max(0, F.craft_num(ui.craft_out, 1) or 1)
  local sell = F.craft_num(ui.craft_sell, 0) or 0
  local c = {tries = tries, chance = chance, rows = {}, one = 0, total = 0, buy = 0, bad = false}
  for i = 1, #st.rows do
    local r = st.rows[i]
    local name = F.trim(F.buf_get(r.name))
    local price, e1 = F.craft_num(r.price, 0)
    local qty, e2 = F.craft_num(r.qty, 0)
    local have, e3 = F.craft_num(r.have, 0)
    if e1 or e2 or e3 then c.bad = true end
    price, qty, have = price or 0, qty or 0, have or 0
    if name ~= '' or qty > 0 then
      local need = qty * tries
      local lack = math.max(0, need - have)
      c.rows[#c.rows + 1] = {name = name ~= '' and name or ('Ресурс ' .. i), need = need, lack = lack, cost = need * price, buy = lack * price}
      c.one = c.one + qty * price
      c.total = c.total + need * price
      c.buy = c.buy + lack * price
    end
  end
  c.done = tries * chance / 100
  c.made = c.done * out
  c.per_item = c.made > 0 and c.total / c.made or 0
  c.income = c.made * sell
  c.profit = c.income - c.total
  c.sell = sell
  return c
end

function F.craft_text(c)
  local out = {F.trim(F.buf_get(ui.craft_name)) .. ', попыток: ' .. F.calc_fmt(c.tries)}
  for i = 1, #c.rows do
    local r = c.rows[i]
    out[#out + 1] = r.name .. ': нужно ' .. F.calc_fmt(r.need) .. ', докупить ' .. F.calc_fmt(r.lack) .. ', ' .. (F.fmt_money(r.buy) or '$0')
  end
  out[#out + 1] = 'Всего: ' .. (F.fmt_money(c.total) or '$0') .. ', докупить на ' .. (F.fmt_money(c.buy) or '$0')
  return table.concat(out, '\n')
end

function F.labeled(id, label, buf, cap, w, hint)
  imgui.BeginGroup()
  imgui.TextColored(F.cvec('text', 0.55), '%s', label)
  imgui.PushItemWidth(w)
  imgui.InputTextWithHint(id, hint or '', buf, cap)
  imgui.PopItemWidth()
  imgui.EndGroup()
end

function F.draw_craft()
  F.page_head('Крафт', 'Что крафтим, какие ресурсы, почём и сколько попыток. Поля понимают 1.5кк и 2*3')
  local st = F.craft_state()
  if #st.rows == 0 then F.craft_blank() end
  F.card_begin('Рецепты', nil, 'ICON_FA_FOLDER')
  local list = {}
  for i = 1, #st.list do list[i] = {i, F.fit_text(font_main, st.list[i].name, F.s(200))} end
  local pick = F.pill_row('##cr', list, st.cur)
  if pick then F.craft_open(pick) end
  if #list > 0 then F.same_if_fit(F.pill_w('+ Новый')) end
  if F.pill('##crnew', '+ Новый', false) then F.craft_blank() end
  F.card_end()
  F.card_begin('Что крафтим', nil, 'ICON_FA_HAMMER')
  local w = F.inner_w()
  F.labeled('##cname', 'Предмет', ui.craft_name, 120, w, 'Например: Точильный камень')
  local cell = math.floor((w - 24) / 4)
  F.labeled('##ctries', 'Попыток', ui.craft_tries, 24, cell)
  imgui.SameLine()
  F.labeled('##cchance', 'Шанс успеха, %', ui.craft_chance, 24, cell)
  imgui.SameLine()
  F.labeled('##cout', 'Выход за успех', ui.craft_out, 24, cell)
  imgui.SameLine()
  F.labeled('##csell', 'Цена продажи', ui.craft_sell, 24, cell, 'необязательно')
  F.card_end()
  F.card_begin('Ресурсы на одну попытку', nil, 'ICON_FA_CUBES')
  local fh = imgui.GetFrameHeight()
  local tw = F.inner_w()
  local col = math.floor((tw - F.s(30) - 32) / 5)
  local name_w = tw - col * 3 - F.s(30) - 32
  local hp = imgui.GetCursorScreenPos()
  local heads = {{'Ресурс', 0}, {'Цена за штуку', name_w + 8}, {'Количество', name_w + col + 16}, {'Есть на руках', name_w + col * 2 + 24}}
  for i = 1, #heads do
    F.text_at(font_main, 16, hp.x + heads[i][2], hp.y, F.col('text', 130), heads[i][1])
  end
  F.advance(hp, 1, F.s(20))
  local del
  for i = 1, #st.rows do
    local r = st.rows[i]
    imgui.PushItemWidth(name_w)
    imgui.InputTextWithHint('##rn' .. i, 'Название', r.name, 64)
    imgui.PopItemWidth()
    imgui.SameLine()
    imgui.PushItemWidth(col)
    imgui.InputTextWithHint('##rp' .. i, '0', r.price, 24)
    imgui.SameLine()
    imgui.InputTextWithHint('##rq' .. i, '0', r.qty, 24)
    imgui.SameLine()
    imgui.InputTextWithHint('##rh' .. i, '0', r.have, 24)
    imgui.PopItemWidth()
    imgui.SameLine()
    local dp = imgui.GetCursorScreenPos()
    if F.ghost_icon('##rdel' .. i, dp.x, dp.y + (fh - F.s(30)) / 2, 'ICON_FA_TRASH', 'Убрать', true) then del = i end
    F.advance(dp, F.s(30), fh)
  end
  if del then
    table.remove(st.rows, del)
    if #st.rows == 0 then st.rows[1] = F.craft_row() end
  end
  if #st.rows < 16 then
    if F.button(F.icon_label('ICON_FA_PLUS', 'Добавить ресурс') .. '##radd', 200, 0) then
      st.rows[#st.rows + 1] = F.craft_row()
    end
  end
  F.card_end()
  local c = F.craft_calc()
  F.card_begin('Расчёт', c.bad and 'В некоторых полях ошибка, они считаются как 0' or nil, 'ICON_FA_CALCULATOR')
  local tiles = {
    {'ICON_FA_COINS', 'Одна попытка', F.fmt_money(c.one)},
    {'ICON_FA_WALLET', 'Всего за попытки', F.fmt_money(c.total)},
    {'ICON_FA_SHOPPING_CART', 'Докупить на', F.fmt_money(c.buy)},
    {'ICON_FA_CHECK_CIRCLE', 'Получится, штук', F.calc_fmt(c.made)},
    {'ICON_FA_TAGS', 'Себестоимость штуки', F.fmt_money(c.per_item)},
  }
  if c.sell > 0 then
    tiles[#tiles + 1] = {'ICON_FA_CHART_LINE', 'Выручка', F.fmt_money(c.income)}
    tiles[#tiles + 1] = {'ICON_FA_EQUALS', 'Прибыль', F.fmt_money(c.profit)}
  end
  F.tile_grid('crf', tiles, 190)
  if #c.rows > 0 then
    imgui.Spacing()
    for i = 1, #c.rows do
      local r = c.rows[i]
      local p = imgui.GetCursorScreenPos()
      local rw = F.inner_w()
      local h = F.s(46)
      if i % 2 == 0 then F.round_rect(p.x - 6, p.y, rw + 12, h, F.col('side', 90), nil, 8) end
      local money = F.fmt_money(r.buy) or '$0'
      local mw = F.text_w(font_bold, money)
      F.text_at(font_main, 16, p.x + 4, p.y + F.s(4), F.col('text', 230), F.fit_text(font_main, r.name, rw - mw - 24))
      F.text_at(font_main, 16, p.x + 4, p.y + F.s(24), F.col('text', 125), 'нужно ' .. F.calc_fmt(r.need) .. '  ·  докупить ' .. F.calc_fmt(r.lack))
      F.text_at(font_bold, 18, p.x + rw - mw - 4, p.y + (h - F.s(18)) / 2 - 1, F.col('accent_hi'), money)
      F.advance(p, rw, h - 4)
    end
  end
  imgui.Spacing()
  if F.accent_button('Сохранить рецепт##csave', 190, 0) then F.craft_save() end
  imgui.SameLine()
  if F.button('Копировать##ccopy', 130, 0) then F.note_copy(F.craft_text(c)) end
  imgui.SameLine()
  if F.button('В заметку##cnote', 130, 0) then
    F.note_flush()
    F.note_edit = nil
    F.note_base = ''
    F.buf_set(ui_ntext, F.craft_text(c), 2048)
    page = 'notes'
  end
  if st.cur then
    imgui.SameLine()
    if F.button('Удалить##cdel', 110, 0, 'danger') then
      local i = st.cur
      F.ask('Удалить рецепт «' .. st.list[i].name .. '»?', 'Удалить', 'fn', {fn = function()
        table.remove(st.list, i)
        F.craft_write()
        F.craft_blank()
      end})
    end
  end
  F.card_end()
end

-- Window

function F.draw_page(w, h, id, fn)
  imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(22, 18))
  imgui.PushStyleColor(imgui.Col.ChildBg, F.vec4(255, 255, 255, 0))
  imgui.BeginChild(id, imgui.ImVec2(w, h), false, imgui.WindowFlags.AlwaysUseWindowPadding)
  fn()
  if F._card then F.card_end() end
  imgui.Dummy(imgui.ImVec2(1, 6))
  -- The toast lives in the page child, so cards cannot cover it.
  F.draw_notice()
  imgui.EndChild()
  imgui.PopStyleColor()
  imgui.PopStyleVar()
end

function F.draw_overlay(ww, wh, wp)
  if not modal then return end
  -- Buttons may clear modal mid-frame, the rest of the frame uses this copy.
  local m = modal
  local flags = imgui.WindowFlags.NoTitleBar
    + imgui.WindowFlags.NoResize
    + imgui.WindowFlags.NoScrollbar
    + imgui.WindowFlags.NoScrollWithMouse
    + imgui.WindowFlags.NoCollapse
    + imgui.WindowFlags.NoSavedSettings
    + imgui.WindowFlags.NoMove
    + (imgui.WindowFlags.NoBackground or 0)
  imgui.SetNextWindowFocus()
  imgui.SetNextWindowPos(wp, imgui.Cond.Always)
  imgui.SetNextWindowSize(imgui.ImVec2(ww, wh), imgui.Cond.Always)
  if imgui.SetNextWindowBgAlpha then imgui.SetNextWindowBgAlpha(0) end
  imgui.PushStyleColor(imgui.Col.WindowBg, F.vec4(0, 0, 0, 0))
  imgui.Begin('fhelp-modal', nil, flags)
  if imgui.SetWindowFontScale then imgui.SetWindowFontScale(cfg.scale or 1) end
  imgui.SetCursorPos(imgui.ImVec2(0, 0))
  imgui.InvisibleButton('##block', imgui.ImVec2(ww, wh))
  if imgui.SetItemAllowOverlap then imgui.SetItemAllowOverlap() end
  local dl = imgui.GetWindowDrawList()
  F.round_rect(wp.x, wp.y, ww, wh, F.col('side', 170), nil, 18)
  local ask = m.kind == 'ask'
  local patch = m.kind == 'patch'
  local pad = 24
  local mw = math.min(F.s(patch and 700 or 480), ww - 40)
  local inner = mw - pad * 2
  local head_h = F.s(36)
  local btn_h = F.s(38)
  local body_h
  if ask then
    F.use_font(font_main)
    body_h = imgui.CalcTextSize(m.text or '', nil, false, inner).y
    F.done_font(font_main)
  elseif patch then
    body_h = math.max(F.s(200), wh - 80 - pad * 2 - head_h - 36 - btn_h)
  else
    body_h = F.s(150)
  end
  local mh = pad + head_h + 14 + body_h + 22 + btn_h + pad
  local x = math.floor(wp.x + (ww - mw) / 2)
  local y = math.floor(wp.y + (wh - mh) / 2)
  F.round_rect(x, y + 4, mw, mh, F.col('side', 120), nil, 20)
  F.round_rect(x, y, mw, mh, F.col('panel'), F.col('accent', 110), 20)
  local icon = F.faico(ask and 'ICON_FA_QUESTION_CIRCLE' or 'ICON_FA_INFO_CIRCLE')
  local tx = x + pad
  local cy = y + pad + head_h / 2
  if icon ~= '' then
    dl:AddCircleFilled(imgui.ImVec2(x + pad + head_h / 2, cy), head_h / 2, F.col('accent', 40), 32)
    local gw = F.text_w(font_main, icon)
    F.text_at(font_main, 16, x + pad + (head_h - gw) / 2, cy - F.s(16) / 2, F.col('accent_hi'), icon)
    tx = x + pad + head_h + 12
  end
  local title = ask and (m.title or 'Подтверждение') or (m.title or 'Сообщение')
  F.text_at(font_bold, 18, tx, cy - F.s(18) / 2 - 1, F.col('text'), F.fit_text(font_bold, title, x + mw - pad - tx))
  local body_y = y + pad + head_h + 14
  if ask then
    F.text_at(font_main, 16, x + pad, body_y, F.col('text', 195), m.text or '', inner)
  else
    imgui.SetCursorScreenPos(imgui.ImVec2(x + pad, body_y))
    imgui.BeginChild('##report', imgui.ImVec2(inner, body_h), false)
    if patch then
      F.draw_patch_body()
    else
      imgui.PushTextWrapPos(0)
      local lines = m.lines or {}
      for i = 1, #lines do
        if i == 1 then imgui.TextColored(F.cvec('accent_hi'), '%s', lines[i])
        else imgui.TextUnformatted(lines[i]) end
      end
      imgui.PopTextWrapPos()
    end
    imgui.EndChild()
  end
  local by = y + mh - pad - btn_h
  local right = x + mw - pad
  if ask then
    imgui.SetCursorScreenPos(imgui.ImVec2(right - F.s(130) - 8 - F.s(120), by))
    if F.button('Отмена##mno', 120, 38) then modal = nil end
    imgui.SameLine(0, 8)
    if F.accent_button((m.ok or 'Да') .. '##myes', 130, 38) then
      local j = m.job
      modal = nil
      job = j
    end
  else
    if m.path then
      imgui.SetCursorScreenPos(imgui.ImVec2(x + pad, by))
      if F.button('Открыть папку##mdir', 150, 38) then
        local folder = m.path:match('^(.*)\\') or F.wd()
        F.queue('fn', {fn = function() F.shell_open('explore', folder) end})
      end
    end
    imgui.SetCursorScreenPos(imgui.ImVec2(right - F.s(120), by))
    if F.accent_button('Закрыть##mclose', 120, 38) then modal = nil end
  end
  imgui.End()
  imgui.PopStyleColor()
end

function F.draw_notice()
  if notice == '' or os.clock() > notice_t then return end
  local wp = imgui.GetWindowPos()
  local ws = imgui.GetWindowSize()
  local left = notice_t - os.clock()
  local a = math.min(1, left / 0.35)
  local glyph = F.faico('ICON_FA_CHECK_CIRCLE')
  local text = F.fit_text(font_main, notice, ws.x - 140)
  local tw = F.text_w(font_main, text)
  local gw = glyph ~= '' and (F.text_w(font_main, glyph) + 10) or 0
  local bh = F.s(40)
  local bw = tw + gw + 40
  local x = wp.x + (ws.x - bw) / 2
  local y = wp.y + ws.y - bh - 16 + (1 - a) * 10
  F.round_rect(x, y + 3, bw, bh, F.col('side', math.floor(120 * a)), nil, bh / 2)
  F.round_rect(x, y, bw, bh, F.col('raised', math.floor(250 * a)), F.col('accent', math.floor(150 * a)), bh / 2)
  local ty = y + (bh - F.s(16)) / 2 - 1
  if glyph ~= '' then F.text_at(font_main, 16, x + 20, ty, F.col('accent_hi', math.floor(255 * a)), glyph) end
  F.text_at(font_main, 16, x + 20 + gw, ty, F.col('text', math.floor(255 * a)), text)
end

function F.draw_contents(ww, wh)
  local wp = imgui.GetWindowPos()
  F.paint_back(ww, wh, wp)
  local controls = 5 * 34 + 20
  imgui.SetCursorPos(imgui.ImVec2(0, 0))
  imgui.InvisibleButton('##drag', imgui.ImVec2(math.max(1, ww - controls), F.HEAD))
  if imgui.IsItemHovered() and imgui.IsMouseDoubleClicked(0) then
    maximized = not maximized
    collapsed = false
  end
  if not maximized then
    user_drag = imgui.IsItemActive()
    if user_drag and imgui.IsMouseDragging(0) then
      local io = imgui.GetIO()
      local p = imgui.GetWindowPos()
      imgui.SetWindowPosVec2(imgui.ImVec2(p.x + io.MouseDelta.x, p.y + io.MouseDelta.y), imgui.Cond.Always)
    end
  else
    user_drag = false
  end
  local wide_side = ww >= 860
  local side_w = wide_side and 200 or 60
  F.paint_top(ww, wp, side_w)
  if collapsed then return end
  if not F.page_ok(page) then page = 'home' end
  local top, foot = F.HEAD + 1, 34
  local body_h = wh - top - foot
  local main_w = ww - side_w
  local dl = imgui.GetWindowDrawList()
  local x0, y0 = math.floor(wp.x), math.floor(wp.y)
  dl:AddRectFilled(imgui.ImVec2(x0 + 1, y0 + top), imgui.ImVec2(x0 + side_w, y0 + wh - foot), F.col('side', 235), 0)
  -- 1px lines sit on pixel centres, otherwise they blur into two rows.
  dl:AddLine(imgui.ImVec2(x0 + side_w + 0.5, y0 + top), imgui.ImVec2(x0 + side_w + 0.5, y0 + wh - foot), F.col('text', 18), 1)
  dl:AddLine(imgui.ImVec2(x0 + 1, y0 + wh - foot + 0.5), imgui.ImVec2(x0 + ww - 1, y0 + wh - foot + 0.5), F.col('text', 18), 1)
  imgui.PushStyleColor(imgui.Col.ChildBg, F.vec4(255, 255, 255, 0))
  imgui.SetCursorPos(imgui.ImVec2(0, top))
  imgui.BeginChild('##side', imgui.ImVec2(side_w, body_h), false, imgui.WindowFlags.NoScrollbar)
  F.paint_side(body_h, wide_side)
  imgui.EndChild()
  imgui.PopStyleColor()
  imgui.SetCursorPos(imgui.ImVec2(side_w, top))
  if page ~= 'binds' then F.bind_hot = false end
  if page ~= 'chat' then F.accent_hot = false end
  if page ~= 'notes' then F.note_hot = false end
  if F.hot_page ~= page then
    F.hot_page = page
    F.hot_field = nil
  end
  local draw_id, draw_fn = '##home', F.draw_home
  if page == 'income' then draw_id, draw_fn = '##income', F.draw_income
  elseif page == 'chat' then draw_id, draw_fn = '##chat', F.draw_chat
  elseif page == 'scripts' then draw_id, draw_fn = '##scripts', F.draw_scripts_page
  elseif page == 'binds' then draw_id, draw_fn = '##binds', F.draw_binds
  elseif page == 'notes' then draw_id, draw_fn = '##notes', F.draw_notes
  elseif page == 'calc' then draw_id, draw_fn = '##calc', F.draw_calc
  elseif page == 'craft' then draw_id, draw_fn = '##craft', F.draw_craft
  elseif page == 'hotkeys' then draw_id, draw_fn = '##hot', F.draw_hotkeys
  elseif page == 'screen' then draw_id, draw_fn = '##screen', F.draw_screen
  elseif page == 'exp' then draw_id, draw_fn = '##exp', F.draw_exp
  elseif page == 'logs' then draw_id, draw_fn = '##logs', F.draw_logs_page
  elseif page == 'settings' then draw_id, draw_fn = '##setp', F.draw_settings_page
  end
  F.draw_page(main_w, body_h, draw_id, draw_fn)
  local fy = wp.y + wh - foot + (foot - F.s(16)) / 2
  F.text_at(font_main, 16, wp.x + 20, fy, F.col('text', 110), 'fHelper v' .. VER)
  local keys = '/fhelp  ·  Esc закрыть'
  if cfg.key ~= 0 then keys = F.key_name(cfg.key) .. '  ·  ' .. keys end
  F.text_at(font_main, 16, wp.x + ww - 20 - F.text_w(font_main, keys), fy, F.col('text', 110), keys)
  if imgui.IsMouseReleased(0) and not maximized then
    local p = imgui.GetWindowPos()
    local rest_y = p.y - F.anim_slide()
    if math.abs(p.x - (cfg.x or 0)) > 0.5 or math.abs(rest_y - (cfg.y or 0)) > 0.5 then
      cfg.x, cfg.y = p.x, rest_y
      dirty = true
    end
  end
end

function F.draw()
  F.sync_anim()
  local slide = F.anim_slide()
  local ww, wh, sw, sh = F.window_box()
  if collapsed then wh = F.HEAD end
  if maximized and not collapsed then
    imgui.SetNextWindowPos(imgui.ImVec2(8, 8 + slide), imgui.Cond.Always)
  elseif force_center then
    local x = (sw - ww) / 2
    local y = (sh - wh) / 2
    cfg.x, cfg.y = x, y
    force_center = false
    placed = true
    imgui.SetNextWindowPos(imgui.ImVec2(x, y + slide), imgui.Cond.Always)
  elseif not placed then
    local x = cfg.x
    local y = cfg.y
    if not x or x < 0 then x = (sw - ww) / 2 end
    if not y or y < 0 then y = (sh - wh) / 2 end
    if x > sw - 80 then x = math.max(8, sw - ww) end
    if y > sh - 40 then y = 8 end
    cfg.x, cfg.y = x, y
    placed = true
    imgui.SetNextWindowPos(imgui.ImVec2(x, y + slide), imgui.Cond.Always)
  elseif not user_drag then
    imgui.SetNextWindowPos(imgui.ImVec2(cfg.x, cfg.y + slide), imgui.Cond.Always)
  end
  imgui.SetNextWindowSize(imgui.ImVec2(ww, wh), imgui.Cond.Always)
  F.style_push()
  local flags = imgui.WindowFlags.NoTitleBar
    + imgui.WindowFlags.NoResize
    + imgui.WindowFlags.NoScrollbar
    + imgui.WindowFlags.NoScrollWithMouse
    + imgui.WindowFlags.NoCollapse
    + imgui.WindowFlags.NoSavedSettings
    + imgui.WindowFlags.NoMove
  F.use_font(font_main)
  imgui.Begin('fhelp', nil, flags)
  if imgui.SetWindowFontScale then imgui.SetWindowFontScale(cfg.scale or 1) end
  F.draw_contents(ww, wh)
  local overlay_x, overlay_y
  if modal and not collapsed then
    local p = imgui.GetWindowPos()
    overlay_x, overlay_y = p.x, p.y
  end
  imgui.End()
  if overlay_x then F.draw_overlay(ww, wh, imgui.ImVec2(overlay_x, overlay_y)) end
  F.done_font(font_main)
  F.style_pop()
end

if imgui_ok then
  imgui.OnInitialize(F.init_fonts)
  frame = imgui.OnFrame(function() return F.menu_drawn() end, F.draw)
  frame.LockPlayer = false
  frame.HideCursor = false
  hud_frame = imgui.OnFrame(function()
    if hud_frame then
      hud_frame.HideCursor = true
      hud_frame.LockPlayer = false
    end
    return F.hud_on()
  end, F.draw_hud)
  hud_frame.HideCursor = true
  hud_frame.LockPlayer = false
  F.calc_frame = imgui.OnFrame(function() return F.calc_win_on() end, F.draw_calc_win)
  F.calc_frame.HideCursor = true
  F.calc_frame.LockPlayer = false
  F.pin_frame = imgui.OnFrame(function() return F.pins_on() end, F.draw_pins)
  F.pin_frame.HideCursor = true
  F.pin_frame.LockPlayer = false
  F.time_frame = imgui.OnFrame(function() return F.time_on() end, F.draw_time)
  F.time_frame.HideCursor = true
  F.time_frame.LockPlayer = false
  F.car_frame = imgui.OnFrame(function() return F.car_bar_on() end, F.draw_car_bar)
  F.car_frame.HideCursor = true
  F.car_frame.LockPlayer = false
  F.toast_frame = imgui.OnFrame(function() return F.toast_on() end, F.draw_toasts)
  F.toast_frame.HideCursor = true
  F.toast_frame.LockPlayer = false
end

function F.toggle()
  show = not show
  release_back = false
  capture = false
  if show then
    hidden = false
    placed = false
  else
    F.note_flush()
    dirty = true
  end
end

function F.toggle_hidden()
  hidden = not hidden
  capture = false
  if hidden then
    F.hidden_menu = show
    show = false
    dirty = true
  else
    if F.hidden_menu then
      show = true
      placed = false
    end
    F.hidden_menu = false
  end
end

function F.ui_typing()
  -- A letter hotkey must not fire while a fHelper text field has focus.
  if not (show or F.calc_focus) or not imgui_ok then return false end
  local ok, io = pcall(imgui.GetIO)
  return ok and io and io.WantTextInput and true or false
end

function F.close_menu()
  F.note_flush()
  show = false
  capture = false
  dirty = true
end

-- Esc reaches us through onWindowMessage, the game never sees it while the menu is open.
function F.take_esc()
  local hit = F.esc_hit
  F.esc_hit = false
  return hit
end

function F.read_hotkey()
  if capture then
    if capture_what == 'bind' then
      F.read_bind_capture()
      return
    end
    if F.take_esc() then
      if capture_what == 'hide' then cfg.hidekey = 0
      elseif capture_what == 'calc' then cfg.calc_key = 0
      else cfg.key = 0 end
      F.notify('Клавиша сброшена', true)
      capture = false
      capture_what = 'menu'
      dirty = true
      return
    end
    for vk = 8, 254 do
      if vk ~= 1 and vk ~= 2 and vk ~= 4 and vk ~= 5 and vk ~= 6 then
        if wasKeyPressed(vk) then
          if vk == 0x1B then
            if capture_what == 'hide' then cfg.hidekey = 0
            elseif capture_what == 'bind' then bind_vk = 0
            elseif capture_what == 'calc' then cfg.calc_key = 0
            else cfg.key = 0 end
            F.notify('Клавиша сброшена', true)
          elseif capture_what == 'calc' then
            if vk == cfg.key or vk == cfg.hidekey then
              F.notify('Эта клавиша уже занята', true)
            else
              cfg.calc_key = vk
              F.notify('Окошко калькулятора: ' .. F.key_name(vk), true)
            end
          elseif capture_what == 'hide' then
            if vk == cfg.key then
              F.notify('Эта клавиша уже открывает меню', true)
            else
              cfg.hidekey = vk
              F.notify('Скрытие интерфейса: ' .. F.key_name(vk), true)
            end
          elseif capture_what == 'bind' then
            F.finish_bind(vk, 0)
          else
            if vk == cfg.hidekey then
              F.notify('Эта клавиша уже скрывает интерфейс', true)
            else
              cfg.key = vk
              F.notify('Клавиша меню: ' .. F.key_name(vk), true)
            end
          end
          capture = false
          capture_what = 'menu'
          dirty = true
          return
        end
      end
    end
    return
  end
  if F.take_bind_paste() then return end
  if cfg.key ~= 0 and wasKeyPressed(cfg.key) and not F.typing() and not F.ui_typing() then
    F.toggle()
    return
  end
  if cfg.hidekey ~= 0 and wasKeyPressed(cfg.hidekey) and not F.typing() and not F.ui_typing() then
    F.toggle_hidden()
    return
  end
  if cfg.calc_key ~= 0 and wasKeyPressed(cfg.calc_key) and not F.typing() and not F.ui_typing() then
    F.calc_cmd('')
    return
  end
  F.fire_binds()
end

-- Updates

-- The files live in a public GitHub repository: version.json and fhelp.lua.
-- Raw links work as a free file server, nothing else is needed.
F.UPD = {user = 'fhyart', repo = 'fhelper', branch = 'main'}
F.BUILD = 17

function F.upd_base()
  if F.UPD.user == '' then return nil end
  return 'https://raw.githubusercontent.com/' .. F.UPD.user .. '/' .. F.UPD.repo .. '/' .. F.UPD.branch .. '/'
end

function F.upd_state()
  F.upd = F.upd or {state = 'idle'}
  return F.upd
end

function F.upd_read(path)
  local f = io.open(path, 'rb')
  if not f then return nil end
  local data = f:read('*a')
  f:close()
  return data
end

-- downloadUrlToFile reports many steps; the last one says the file is complete.
-- A dead connection never reports, so there is a timeout as well.
function F.fetch(url, path, done)
  local okm, ml = pcall(require, 'moonloader')
  local st = okm and type(ml) == 'table' and ml.download_status or {}
  os.remove(path)
  local fin = false
  local function finish(ok)
    if fin then return end
    fin = true
    local ok2, err = pcall(done, ok)
    if not ok2 then F.log_line('Обновление: ' .. tostring(err)) end
  end
  local ok = pcall(downloadUrlToFile, url, path, function(_, status)
    if status == st.STATUSEX_ENDDOWNLOAD then finish(doesFileExist(path)) end
  end)
  if not ok then
    finish(false)
    return
  end
  lua_thread.create(function()
    local t0 = os.clock()
    while not fin and os.clock() - t0 < 25 do wait(250) end
    finish(false)
  end)
end

function F.upd_parse(s)
  if not s or s == '' then return nil end
  local ok, v = pcall(F.json_value, s, 1)
  if not ok or type(v) ~= 'table' then return nil end
  local build = tonumber(v.build)
  if not build or type(v.version) ~= 'string' then return nil end
  local notes = {}
  if type(v.notes) == 'table' then
    for i = 1, math.min(#v.notes, 30) do
      if type(v.notes[i]) == 'string' then notes[#notes + 1] = F.utf_cut(v.notes[i], 200) end
    end
  end
  local file = type(v.file) == 'string' and v.file:match('^[%w_%-%.]+%.lua$') or 'fhelp.lua'
  return {build = build, version = F.utf_cut(v.version, 20), notes = notes, size = tonumber(v.size), file = file}
end

function F.upd_check(manual)
  local u = F.upd_state()
  if u.state == 'checking' or u.state == 'loading' or u.state == 'done' then return end
  u.at = os.time()
  local base = F.upd_base()
  if not base then
    u.state = 'off'
    if manual then F.notify('Адрес обновлений ещё не настроен') end
    return
  end
  u.state = 'checking'
  F.mkdir(F.cfg_dir())
  local path = F.cfg_dir() .. '\\fhelp_upd.json'
  F.fetch(base .. 'version.json?t=' .. os.time(), path, function(ok)
    local info = ok and F.upd_parse(F.upd_read(path))
    os.remove(path)
    local want = u.want
    u.want = nil
    if not info then
      u.state = 'fail'
      if manual then F.notify('Не удалось проверить обновление, нет связи с GitHub') end
      return
    end
    u.info = info
    if info.build <= F.BUILD then
      u.state = 'none'
      if manual then F.notify('У тебя последняя версия: ' .. VER) end
      return
    end
    u.state = 'new'
    if want then F.upd_offer()
    elseif manual or cfg.upd_skip ~= info.build then F.upd_announce(info) end
  end)
end

function F.upd_announce(info)
  local msg = 'Вышла версия ' .. info.version .. '. Обновить: /fupdate или меню → Настройки → Обновление'
  F.log_line('Найдено обновление ' .. info.version)
  F.chat_brand(msg)
  pcall(F.toast, 'sys', {
    force = true, key = 'upd', icon = 'ICON_FA_DOWNLOAD', title = 'Вышла версия ' .. info.version,
    text = info.notes[1] or 'Обновить можно в настройках или командой /fupdate',
  })
end

-- The new file must be whole, be fHelper of the announced build and compile.
function F.upd_verify(data, info)
  if not data or #data < 20000 then return 'файл скачался не целиком' end
  if info.size and #data ~= info.size then return 'размер файла не совпал' end
  if not data:find("script_name('fHelper')", 1, true) then return 'это не файл fHelper' end
  if tonumber(data:match('script_version_number%((%d+)%)')) ~= info.build then return 'номер версии в файле не совпал' end
  if not loadstring(data, 'fhelp') then return 'в файле ошибка' end
  return nil
end

function F.upd_apply(data)
  local self = F.self_path()
  local cur = F.upd_read(self)
  if cur then
    F.mkdir(F.wd() .. '\\fhelp_backup')
    local dir = F.wd() .. '\\fhelp_backup\\' .. VER .. '_' .. os.date('%Y%m%d_%H%M%S')
    F.mkdir(dir)
    local f = io.open(dir .. '\\fhelp.lua', 'wb')
    if not f then return false, 'не удалось сохранить старую версию' end
    f:write(cur)
    f:close()
  end
  local f = io.open(self, 'wb')
  if not f then return false, 'нет доступа к файлу скрипта' end
  f:write(data)
  f:close()
  if F.upd_read(self) ~= data then
    if cur then
      local back = io.open(self, 'wb')
      if back then
        back:write(cur)
        back:close()
      end
    end
    return false, 'файл не записался'
  end
  return true
end

function F.upd_install()
  local u = F.upd_state()
  if u.state ~= 'new' or not u.info then
    F.upd_check(true)
    return
  end
  local base = F.upd_base()
  if not base then return end
  u.state, u.err = 'loading', nil
  local info = u.info
  local tmp = F.cfg_dir() .. '\\fhelp_upd.lua'
  F.notify('Скачиваю версию ' .. info.version)
  F.fetch(base .. info.file .. '?t=' .. os.time(), tmp, function(ok)
    local data = ok and F.upd_read(tmp)
    os.remove(tmp)
    local why = F.upd_verify(data, info)
    local done
    if not why then done, why = F.upd_apply(data) end
    if not done then
      u.state, u.err = 'new', why
      F.notify('Обновление не установлено: ' .. tostring(why))
      return
    end
    u.state = 'done'
    F.log_line('Обновлено до ' .. info.version)
    F.notify('fHelper обновлён до ' .. info.version .. ', перезапускаю')
    if show then cfg.open = 1 end
    F.save_cfg()
    lua_thread.create(function()
      wait(400)
      thisScript():reload()
    end)
  end)
end

-- The button in the window head: checks right away and offers to install what it found.
function F.upd_offer()
  local u = F.upd_state()
  local info = u.info
  if not info then return end
  local lines = {'Вышла версия ' .. info.version .. ', у тебя ' .. VER .. '.'}
  for i = 1, math.min(#info.notes, 6) do lines[#lines + 1] = '•  ' .. info.notes[i] end
  if #info.notes > 6 then lines[#lines + 1] = '…и ещё ' .. (#info.notes - 6) end
  if u.err then lines[#lines + 1] = 'Прошлая попытка: ' .. u.err end
  lines[#lines + 1] = ''
  lines[#lines + 1] = 'Обновить сейчас? fHelper сам перезапустится, старая версия останется в fhelp_backup.'
  modal = {kind = 'ask', title = 'Доступно обновление', text = table.concat(lines, '\n'), ok = 'Обновить', job = {op = 'fn', fn = F.upd_install}}
end

function F.upd_button()
  local u = F.upd_state()
  if not F.upd_base() then
    F.notify('Адрес обновлений ещё не настроен', true)
    return
  end
  if u.state == 'new' and u.info then
    F.upd_offer()
    return
  end
  if u.state == 'checking' or u.state == 'loading' or u.state == 'done' then
    if u.state == 'checking' then u.want = true end
    F.notify(F.UPD_TEXT[u.state], true)
    return
  end
  u.want = true
  F.upd_check(true)
end

function F.upd_tip()
  local u = F.upd_state()
  if u.state == 'new' and u.info then return 'Вышла версия ' .. u.info.version .. ', нажми, чтобы обновить' end
  if u.state == 'checking' then return 'Проверяю обновление…' end
  if u.state == 'loading' then return 'Скачиваю обновление…' end
  return 'Проверить обновление'
end

function F.upd_cmd()
  local u = F.upd_state()
  if u.state == 'new' then F.upd_install() else F.upd_check(true) end
end

-- First check a little after the start, then every three hours.
function F.upd_tick(now)
  if cfg.upd_on ~= 1 or not F.upd_base() then return end
  F._upd_t0 = F._upd_t0 or now
  if now - F._upd_t0 < 10 then return end
  local u = F.upd_state()
  if u.at and os.time() - u.at < 3 * 3600 then return end
  F.upd_check(false)
end

F.UPD_TEXT = {
  idle = 'Ещё не проверялось', checking = 'Проверяю…', none = 'У тебя последняя версия',
  fail = 'Не удалось связаться с GitHub', loading = 'Скачиваю и проверяю файл…', done = 'Установлено, перезапуск',
  off = 'Адрес обновлений ещё не настроен',
}

function F.upd_card()
  local u = F.upd_state()
  if not F.upd_base() then u.state = 'off' end
  F.card_begin('Обновление', 'Новые версии fHelper скачиваются с GitHub', 'ICON_FA_DOWNLOAD')
  if F.switch('updon', 'Проверять при входе в игру', cfg.upd_on == 1, 'Только подсказка: установка всегда по твоей кнопке') then
    cfg.upd_on = cfg.upd_on == 1 and 0 or 1
    dirty = true
  end
  F.divider()
  local p = imgui.GetCursorScreenPos()
  local x = p.x
  x = x + F.chip(x, p.y, 'у тебя ' .. VER, 'muted') + 8
  if u.info and u.state ~= 'none' then F.chip(x, p.y, 'на GitHub ' .. u.info.version, u.state == 'new' and 'on' or 'muted') end
  F.advance(p, 1, F.s(24))
  if u.state == 'new' and u.info then
    F.hint('Вышла версия ' .. u.info.version .. '. Что нового:', F.cvec('accent_hi'))
    for i = 1, math.min(#u.info.notes, 12) do F.hint('•  ' .. u.info.notes[i]) end
    if u.err then F.hint_bad('Прошлая попытка: ' .. u.err) end
    imgui.Spacing()
    if F.button('Обновить##updgo', 160, 0, 'primary') then F.upd_install() end
    imgui.SameLine(0, 8)
    local skipped = cfg.upd_skip == u.info.build
    if F.button((skipped and 'Пропущена' or 'Пропустить эту версию') .. '##updskip', 220, 0) then
      cfg.upd_skip = skipped and 0 or u.info.build
      dirty = true
    end
    if imgui.IsItemHovered() then F.tip('Не напоминать о ней при входе. Обновить можно в любой момент здесь') end
  else
    F.hint(F.UPD_TEXT[u.state] or '')
    imgui.Spacing()
    if u.state ~= 'off' and F.button('Проверить сейчас##updchk', 190, 0) then F.upd_check(true) end
  end
  F.hint('Перед заменой файл проверяется целиком, старая версия остаётся в moonloader\\fhelp_backup.')
  F.card_end()
end

function F.file_mtime(path)
  if not lfs_ok or not lfs or not path or path == '' then return 0 end
  local ok, t = pcall(lfs.attributes, path, 'modification')
  if ok and t then return tonumber(t) or 0 end
  return 0
end

function F.self_path()
  local ok, s = pcall(thisScript)
  if ok and s and s.path and s.path ~= '' then return s.path end
  return F.wd() .. '\\fhelp.lua'
end

function F.watch_self()
  local stamp = F.file_mtime(F.self_path())
  if stamp <= 0 then return end
  if not disk_stamp then
    disk_stamp = stamp
    return
  end
  if stamp == disk_stamp then
    disk_wait = nil
    return
  end
  if not disk_wait then
    disk_wait = os.clock()
    if show then cfg.open = 1 end
    F.save_cfg()
    F.log_line('Файл обновился')
    return
  end
  if os.clock() - disk_wait < 2 then return end
  disk_stamp = stamp
  thisScript():reload()
end

function F.ensure_boot()
  local path = F.wd() .. '\\fhelp_boot.lua'
  if not doesFileExist(path) then return end
  local ok, list = pcall(script.list)
  if not ok or not list then return end
  for i = 1, #list do
    local s = list[i]
    local p = s and s.path and s.path:lower() or ''
    if s and (s.name == 'fhelp boot' or p:match('fhelp_boot%.lua$')) then return end
  end
  local now = os.clock()
  if now - boot_try < 5 then return end
  boot_try = now
  pcall(script.load, path)
end

function main()
  booted = os.clock()
  while not isSampAvailable() do wait(100) end
  if not imgui_ok then
    F.chat_brand('Нет библиотеки mimgui. Меню не открылось.')
    return
  end
  F.prep_ffi()
  F.load_cfg()
  pcall(F.money_seed)
  F.play_restore()
  F.load_log()
  F.load_binds()
  F.load_favs()
  F.load_notes()
  F.pay_load()
  -- A broken data file must not stop the whole menu from starting.
  for _, fn in ipairs({F.led_load, F.int_load, F.calc_load, F.craft_load, F.pin_load, F.car_load, F.itl_load, F.shop_load}) do
    local ok, err = pcall(fn)
    if not ok then F.log_line('Загрузка данных: ' .. tostring(err)) end
  end
  if ui_opacity then
    ui_opacity[0] = cfg.opacity * 100
    ui_notify[0] = cfg.notify == 1
    ui_lock[0] = cfg.lock == 1
    if ui_scale then ui_scale[0] = (cfg.scale or 1) * 100 end
    if ui_hfps then
      ui_hfps[0] = cfg.hud_fps == 1
      ui_hnet[0] = cfg.hud_net == 1
      ui_hudx[0] = cfg.hud_x or 78
      ui_hudy[0] = cfg.hud_y or 4
    end
    if ui_hudscale then ui_hudscale[0] = (cfg.hud_scale or 1) * 100 end
    if ui_hping then ui_hping[0] = cfg.hud_ping ~= 0 end
    if ui_draw then ui_draw[0] = cfg.draw or 800 end
    if ui_drawon then ui_drawon[0] = cfg.draw_on == 1 end
    if ui_fpsfree then ui_fpsfree[0] = cfg.fps_free == 1 end
    if ui_fav then F.buf_set(ui_fav, cfg.accent or '', 180) end
    ui.time_utc[0] = cfg.time_utc
    ui.time_x[0] = cfg.time_x
    ui.time_y[0] = cfg.time_y
    ui.time_scale[0] = cfg.time_scale * 100
    F.toast_ui()
  end
  if cfg.off == 1 then
    cfg.off = 0
    F.save_cfg()
  end
  local reopened = cfg.open == 1
  if reopened then
    cfg.open = 0
    F.save_cfg()
    show = true
    notice = 'Скрипт перезагружен'
    notice_t = os.clock() + 3.5
    F.log_line('Скрипт перезагружен')
  else
    F.log_line('Скрипт загружен')
  end
  F.chat_brand('Скрипт загружен')
  F.hook_chat()
  if frame then
    frame.LockPlayer = show and cfg.lock == 1
    frame.HideCursor = false
  end
  sampRegisterChatCommand('fhelp', F.toggle)
  sampRegisterChatCommand('fhelpreload', function()
    F.queue('reload_self')
  end)
  sampRegisterChatCommand('fcalc', F.calc_cmd)
  sampRegisterChatCommand('fcar', F.car_scan)
  sampRegisterChatCommand('fupdate', F.upd_cmd)
  local int_mark = 0
  local frames = 0
  local fps_mark = os.clock()
  local up_mark = 0
  local scan_mark = 0
  while true do
    wait(0)
    frames = frames + 1
    local now = os.clock()
    if now - fps_mark >= 0.5 then
      fps = frames / (now - fps_mark)
      frames = 0
      fps_mark = now
      F.refresh_live()
    end
    if now - up_mark >= 1 then
      F.ensure_boot()
      F.apply_limiter(true)
      up_mark = now
    end
    if F.int_dirty and now - int_mark >= 20 then
      int_mark = now
      pcall(F.int_save)
    end
    F.play_tick()
    F.pay_tick()
    F.car_tick()
    pcall(F.mem_tick, now)
    pcall(F.upd_tick, now)
    pcall(F.shop_tick)
    F.watch_self()
    if frame then
      frame.LockPlayer = (show or anim > 0.45) and not hidden and cfg.lock == 1
      frame.HideCursor = false
    end
    if need_scan and show and (cfg.bg == 1 or page == 'scripts') then
      F.scan_files()
      scan_mark = now
    end
    F.read_hotkey()
    if release_back and now >= release_until then
      release_back = false
      show = true
    end
    while chats[1] do
      local msg = table.remove(chats, 1)
      if cfg.notify == 1 and isSampAvailable() then
        sampAddChatMessage(F.to_cp('{E08A55}[fHelper] {FFFFFF}' .. msg:gsub('{', '(')), -1)
      end
    end
    if job then
      local current = job
      job = nil
      local ok, err = pcall(F.perform, current)
      if not ok then
        F.notify('Ошибка: ' .. tostring(err))
      end
    end
    if dirty and now >= save_at then
      F.save_cfg()
      save_at = now + 0.4
    elseif stat_dirty and now >= stat_at then
      F.save_cfg()
      stat_at = now + 15
    end
  end
end

addEventHandler('onScriptTerminate', function(scr)
  if scr ~= script.this then return end
  pcall(function()
    if play.online then F.play_commit(os.time(), true) end
    if F._lim == 0 then F.write_limiter(1) end
    F.note_flush()
    if F.int_dirty then F.int_save() end
    F.save_cfg()
  end)
  pcall(F.lib_free)
end)

addEventHandler('onWindowMessage', function(msg, wparam, lparam)
  if wparam ~= 0x1B or (msg ~= 0x100 and msg ~= 0x101) then return end
  if not show and not modal and not capture and not F.calc_focus then return end
  -- Chat and server dialogs close on Esc by themselves.
  if F.typing() then return end
  consumeWindowMessage(true, false)
  if msg ~= 0x100 then return end
  if capture then F.esc_hit = true
  elseif modal then modal = nil
  elseif F.calc_focus and not show then F.calc_focus = false
  else F.close_menu() end
end)

function onD3DPresent()
  if cfg.draw_on ~= 1 then return end
  local paused, pause = pcall(isPauseMenuActive)
  if paused and pause then return end
  local d = tonumber(cfg.draw) or 0
  if d >= 300 then pcall(setFarClipDistance, d) end
end

function onReceivePacket(id, bs)
  local ok, n = pcall(raknetBitStreamGetNumberOfBytesUsed, bs)
  if ok then F.note_bytes(n, true) end
  if id == 220 then F.cef_packet(bs) end
end

function onSendPacket(id, bs)
  local ok, n = pcall(raknetBitStreamGetNumberOfBytesUsed, bs)
  if ok then F.note_bytes(n, false) end
  if id == 220 then
    pcall(F.car_sent, bs)
    pcall(raknetBitStreamResetReadPointer, bs)
  end
end

function F.accent_apply(bs)
  if cfg.accent_on == 0 or not bs then return end
  -- An empty field would send the placeholder [Акцент] to the chat.
  if F.accent_inner() == '' then return end
  local prefix = F.to_cp(F.accent_head())
  if not prefix or prefix == '' then return end
  local ok, message = pcall(function()
    raknetBitStreamSetReadOffset(bs, 0)
    local len = tonumber(raknetBitStreamReadInt8(bs)) or 0
    if len < 0 then len = len + 256 end
    if len <= 0 then return '' end
    return raknetBitStreamReadString(bs, len) or ''
  end)
  pcall(raknetBitStreamSetReadOffset, bs, 0)
  if not ok or type(message) ~= 'string' or message == '' or message:byte(1) == 47 then return end
  if message:sub(1, #prefix) == prefix then return end
  local room = 120 - #prefix
  if room < 1 then return end
  if #message > room then message = message:sub(1, room) end
  local out = prefix .. message
  if #out > 127 then return end
  pcall(function()
    raknetBitStreamSetWriteOffset(bs, 0)
    raknetBitStreamWriteInt8(bs, #out)
    raknetBitStreamWriteString(bs, out)
    raknetBitStreamSetReadOffset(bs, 0)
  end)
end

function onSendRpc(id, bs)
  if id == 101 then F.accent_apply(bs) end
end
