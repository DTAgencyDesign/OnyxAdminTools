-- OnyxAdminTools.lua
-- MoonLoader script for GTA SA-MP 0.3.7
-- Author: Дмитрий Цыганов 

script_name('OnyxAdminTools')
script_author('Dmitriy Tsyganov')
script_version('1.4.2')

local inicfg = require 'inicfg'
local sampev = require 'lib.samp.events'

local CONFIG_NAME = 'OnyxAdminTools'
local CONFIG_DIR = 'moonloader/config'
local DIALOG_ID = 11220

local COL = {
  BLUE = '{1E90FF}', ORANGE = '{FF8C00}', RED = '{FF0000}',
  GREEN = '{00FF00}', WHITE = '{FFFFFF}', GRAY = '{A9A9A9}',
  PINK = '{FF69B4}',
}

local default_cfg = {
  main = {
    prefix_tag = '[ONYX AdminTools]',
    show_connect_msg = true,
    vk_group = 'vk.com/onx_rp',
    delay_ms = 2000,
  },
  texts = {
    author_name = 'Дмитрий Цыганов',
    lid_line1 = 'Заявку на Лидерку можете подать в нашей группе ВК: %VK%',
    lid_line2 = 'С уважением, администрация проекта ONYX Role Play',
    admin_line1 = 'Заявку на пост Администратора можете подать в нашей группе ВК: %VK%',
    admin_line2 = 'С уважением, администрация проекта ONYX Role Play',
    helper_line1 = 'Заявку на пост Помощника можете подать в нашей группе ВК: %VK%',
    helper_line2 = 'С уважением, администрация проекта ONYX Role Play',
    spt_line1 = 'Администратор летит к вам на помощь!',
    spt_line2 = 'С уважением, администрация проекта ONYX Role Play',

    dm_reason = 'ДМ / Death Match',
    dmzz_reason = 'ДМ в ЗЗ / Death Match in Green Zone',
    mdm_reason = 'Масс. ДМ / Mass Death Match',
    db_reason = 'ДБ / Drive By',
    mdb_reason = 'Масс. ДБ / Mass Drive By',
    tk_reason = 'ТК / Team Kill',
    sk_reason = 'СК / Spawn Kill',
    rk_reason = 'РК / Revenge Kill',
    sanim_reason = 'Сбив Анимации',
    nrd_reason = 'НРД / Non Rp Drive',
    sriv_reason = 'Срыв Набора',

    caps_reason = 'Капс / CapsLock',
    flood_reason = 'Флуд / Flood',
    mg_reason = 'МГ / Metagaming',
    adeq_reason = 'Неадекватность',
    oskp_reason = 'Оск. игрока/ов',
    oska_reason = 'Оск. администрации',
    oskf_reason = 'Оск. родных',

    offtop1_line = 'offtop 1/2',
    offtop2_line = 'offtop 2/2 + /offreport',
  },
  descriptions = {
    athelp = 'список всех команд скрипта',
    atrel = 'перезагрузка конфигурации и скрипта',
    lid = 'автоответ по Лидерке',
    admin = 'автоответ по Админке',
    helper = 'автоответ по Помощнику',
    spt = 'телепорт игрока на спавн',
    dm = 'ДМ (40 мин)', 
	dmzz = 'ДМ в ЗЗ (60 мин)', 
	mdm = 'Масс. ДМ (60 мин)',
    db = 'ДБ (40 мин)', 
	mdb = 'Масс. ДБ (60 мин)', 
	tk = 'ТК (30 мин)',
    sk = 'СК (50 мин)', 
	rk = 'РК (30 мин)', 
	sanim = 'Сбив Анимации (20 мин)',
    nrd = 'НРД (40 мин)', 
	sriv = 'Срыв Набора (50 мин)',
    caps = 'Капс (20 мин)', 
	flood = 'Флуд (20 мин)', 
	mg = 'МГ (10 мин)',
    adeq = 'Неадекватность (40 мин)', 
	oskp = 'Оск. игрока (40 мин)',
    oska = 'Оск. администрации (70 мин)', 
	oskf = 'Оск. родных (120 мин)',
    offtop1 = 'оффтоп 1/2', 
	offtop2 = 'оффтоп 2/2 + /offreport'
  }
}

local cfg_path = string.format('%s/%s.ini', CONFIG_DIR, CONFIG_NAME)
local cfg = {}
local banner_shown = false

local function chat(msg) sampAddChatMessage(msg, -1) end
local function vk() return cfg.main.vk_group or default_cfg.main.vk_group end
local function replace_tokens(s) return s:gsub('%%VK%%', vk()) end
local function send_cmd(cmd) sampSendChat(cmd) end
local function wait_ms(ms) wait(ms) end
local function parse_id(arg) return tonumber(arg) end
local function ensure_config_dir() os.execute(string.format('mkdir "%s" 2>nul', CONFIG_DIR)) end
local function get_reason(key, fallback) return (cfg.texts and cfg.texts[key]) or fallback end

local function load_config()
  ensure_config_dir()
  local data = inicfg.load(default_cfg, cfg_path)
  if not data then return false end
  cfg = data
  for section, tbl in pairs(default_cfg) do
    cfg[section] = cfg[section] or {}
    for k, v in pairs(tbl) do
      if cfg[section][k] == nil then cfg[section][k] = v end
    end
  end
  return true
end

local function show_connect_banner_once()
  if banner_shown then return end
  banner_shown = true
  if not (cfg.main and cfg.main.show_connect_msg) then return end

  chat(string.format('%s%s %s%s', COL.ORANGE, cfg.main.prefix_tag, COL.WHITE, 'Успешно подключён!'))
  chat(string.format('%s%s %s%s %s%s', COL.ORANGE, cfg.main.prefix_tag, COL.WHITE, 'Скрипт был разработан: ', COL.ORANGE, cfg.texts.author_name))
  chat(string.format('%s%s %s%s %s%s', COL.ORANGE, cfg.main.prefix_tag, COL.WHITE, 'Для просмотра всех команд пропишите -> ', COL.ORANGE, '/athelp'))
end

local function sequence_for(id, steps)
  local delay = tonumber(cfg.main.delay_ms or 2000)
  lua_thread.create(function()
    for _, cmd in ipairs(steps) do send_cmd(cmd) wait_ms(delay) end
  end)
end

function handle_command(name, arg)
  local id = parse_id(arg)

  if name == 'athelp' then
    local title = string.format('%s[ONYX AdminTools]', COL.ORANGE)
    local sub = string.format(
      '%sНиже перечислены все команды скрипта\n%sАвтор: %s%s\n\nСделано с любовью для %sONYX Role Play 0.3.7\n\n',
      COL.WHITE, COL.WHITE, COL.WHITE, cfg.texts.author_name, COL.ORANGE
    )

    local auto = ''
    local jail = ''
    local mute = ''

    for cmd, desc in pairs(cfg.descriptions) do
      if cmd == 'lid' or cmd == 'admin' or cmd == 'helper' or cmd == 'spt' or cmd:find('offtop') then
        auto = auto .. string.format('%sКоманда %s/%s %s- %s\n', COL.WHITE, COL.GRAY, cmd, COL.WHITE, desc)
      elseif cmd == 'caps' or cmd == 'flood' or cmd == 'mg' or cmd == 'adeq'
          or cmd == 'oskp' or cmd == 'oska' or cmd == 'oskf' then
        mute = mute .. string.format('%sКоманда %s/%s %s- %s\n', COL.WHITE, COL.GRAY, cmd, COL.WHITE, desc)
      elseif cmd ~= 'athelp' and cmd ~= 'atrel' then
        jail = jail .. string.format('%sКоманда %s/%s %s- %s\n', COL.WHITE, COL.GRAY, cmd, COL.WHITE, desc)
      end
    end

    local body = ''
    body = body .. COL.ORANGE .. 'Автоответы по репортам:\n' .. auto .. '\n'
    body = body .. COL.ORANGE .. 'Тюремные наказания:\n' .. jail .. '\n'
    body = body .. COL.ORANGE .. 'Наказания лишающие права писать в чат:\n' .. mute .. '\n'

    sampShowDialog(DIALOG_ID, title, sub .. body, 'ОК', '')
    return
  end
  if name == 'atrel' then
    if load_config() then
      chat(COL.GREEN .. 'Конфиг успешно перезагружен.')
    else
      chat(COL.RED .. 'Ошибка перезагрузки конфига.')
    end
    return
  end
  if not id then chat(COL.RED .. 'Использование: /' .. name .. ' [id]') return end
  if name == 'lid' or name == 'admin' or name == 'helper' then
    sequence_for(id, {
      string.format('/gj %d', id),
      string.format('/pm %d %s', id, replace_tokens(get_reason(name .. '_line1', '...'))),
      string.format('/pm %d %s', id, get_reason(name .. '_line2', '...')),
      string.format('/gg %d', id),
    })
  elseif name == 'spt' then
    sequence_for(id, {
      string.format('/gj %d', id),
	  string.format('/pm %d %s', id, get_reason('spt_line1')),
      string.format('/sp %d', id),
      string.format('/pm %d %s', id, get_reason('spt_line2')),
      string.format('/gg %d', id),
    })
  elseif name:find('offtop') then
    sequence_for(id, { string.format('/pm %d %s', id, get_reason(name .. '_line', '...')) })
  elseif name == 'caps' or name == 'flood' or name == 'mg' or name == 'adeq' or name:match('osk') then
    sequence_for(id, {
      string.format('/mute %d 20 %s', id, get_reason(name .. '_reason', '...')),
      string.format('/gg %d', id),
    })
  else
    sequence_for(id, {
      string.format('/jail %d 40 %s', id, get_reason(name .. '_reason', '...')),
      string.format('/gg %d', id),
    })
  end
end

function main()
  while not isSampAvailable() do wait(250) end
  if not load_config() then
    chat(COL.RED .. 'Ошибка загрузки конфигурации!')
    return
  end
  show_connect_banner_once()

  local commands = {
    'athelp','atrel','lid','admin','helper','spt','dm','dmzz','mdm','db','mdb','tk','sk','rk','sanim','nrd','sriv',
    'caps','flood','mg','adeq','oskp','oska','oskf','offtop1','offtop2'
  }
  for _, cmd in ipairs(commands) do
    sampRegisterChatCommand(cmd, function(arg) handle_command(cmd, arg) end)
  end
end