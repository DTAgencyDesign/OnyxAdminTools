-- OnyxAdminTools.lua
-- MoonLoader script for GTA SA-MP 0.3.7
-- Author: Дмитрий Цыганов 

script_name('OnyxAdminTools')
script_author('Dmitriy Tsyganov')
script_version('1.4.9')

local inicfg = require 'inicfg'
local sampev = require 'lib.samp.events'
local hasSamp, samp = pcall(require, 'lib.samp')
if not hasSamp then samp = nil end
local sampfuncs = require 'sampfuncs'

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
    delay_ms = 1500,
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
    ah = '[id] [1 или 2] 1 - история ников 2 - список наказаний',
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

local function sequence_for(id, steps)
  local delay = tonumber(cfg.main.delay_ms or 1500)
  lua_thread.create(function()
    for _, cmd in ipairs(steps) do send_cmd(cmd) wait_ms(delay) end
  end)
end

function handle_command(name, arg)
  local id = parse_id(arg)

  if name == 'ah' then
    local args = {}
    for word in arg:gmatch('%S+') do table.insert(args, word) end

    local id = tonumber(args[1])
    local page = tonumber(args[2]) or 2

    if not id then
      chat(COL.RED .. 'Использование: /ah [id] [1 - ники | 2 - наказания]')
      return
    end
    if not sampIsPlayerConnected(id) then
      chat(COL.RED .. 'Игрок с таким ID не найден или оффлайн.')
      return
    end

    local nickname = sampGetPlayerNickname(id)
    if not nickname then
      chat(COL.RED .. 'Не удалось получить никнейм игрока.')
      return
    end

    send_cmd(string.format('/ahistory %s %d', nickname, page))
    return
  end

  if name == 'athelp' then
    local title = string.format('%s[ONYX AdminTools]', COL.ORANGE)
    local sub = string.format('%sНиже перечислены все команды скрипта\n%sАвтор: %s%s\n\nСделано с любовью для %sONYX Role Play 0.3.7\n\n',
      COL.WHITE, COL.WHITE, COL.WHITE, cfg.texts.author_name, COL.ORANGE)

    local auto, jail, mute, info = '', '', '', ''
    for cmd, desc in pairs(cfg.descriptions) do
      local line = string.format('%sКоманда %s/%s %s- %s\n', COL.WHITE, COL.GRAY, cmd, COL.WHITE, desc)
      if cmd == 'lid' or cmd == 'admin' or cmd == 'helper' or cmd == 'spt' or cmd:find('offtop') then
        auto = auto .. line
      elseif cmd == 'caps' or cmd == 'flood' or cmd == 'mg' or cmd == 'adeq' or cmd:match('osk') then
        mute = mute .. line
      elseif cmd == 'ah' then
        info = info .. line
      elseif cmd ~= 'athelp' and cmd ~= 'atrel' then
        jail = jail .. line
      end
    end

    local body = COL.ORANGE .. 'Автоответы по репортам:\n' .. auto .. '\n'
               .. COL.ORANGE .. 'Тюремные наказания:\n' .. jail .. '\n'
               .. COL.ORANGE .. 'Наказания лишающие права писать в чат:\n' .. mute .. '\n'
               .. COL.ORANGE .. 'Информация об игроке:\n' .. info .. '\n'

    sampShowDialog(DIALOG_ID, title, sub .. body, 'ОК', '')
    return
  end

  if name == 'atrel' then
    chat(load_config() and COL.GREEN .. 'Конфиг успешно перезагружен.' or COL.RED .. 'Ошибка перезагрузки конфига.')
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
    local desc = cfg.descriptions[name] or default_cfg.descriptions[name] or ''
    local duration = tonumber(desc:match('(%d+)%s*мин')) or 20
    sequence_for(id, {
      string.format('/mute %d %d %s', id, duration, get_reason(name .. '_reason', '...')),
      string.format('/gg %d', id),
    })
  else
    local desc = cfg.descriptions[name] or default_cfg.descriptions[name] or ''
    local duration = tonumber(desc:match('(%d+)%s*мин')) or 40
    sequence_for(id, {
      string.format('/jail %d %d %s', id, duration, get_reason(name .. '_reason', '...')),
      string.format('/gg %d', id),
    })
  end
end

function main()
  while not isSampAvailable() do wait(250) end
  if not load_config() then chat(COL.RED .. 'Ошибка загрузки конфигурации!') return end
  if not banner_shown and cfg.main.show_connect_msg then
    chat(string.format('%s%s %s%s', COL.ORANGE, cfg.main.prefix_tag, COL.WHITE, 'Успешно подключён!'))
    chat(string.format('%s%s %s%s %s%s', COL.ORANGE, cfg.main.prefix_tag, COL.WHITE, 'Скрипт был разработан: ', COL.ORANGE, cfg.texts.author_name))
    chat(string.format('%s%s %s%s %s%s', COL.ORANGE, cfg.main.prefix_tag, COL.WHITE, 'Для просмотра всех команд пропишите -> ', COL.ORANGE, '/athelp'))
    banner_shown = true
  end
  local commands = {
    'athelp','atrel','lid','admin','helper','spt','ah',
    'dm','dmzz','mdm','db','mdb','tk','sk','rk','sanim','nrd','sriv',
    'caps','flood','mg','adeq','oskp','oska','oskf',
    'offtop1','offtop2'
  }
  for _, cmd in ipairs(commands) do
    sampRegisterChatCommand(cmd, function(arg) handle_command(cmd, arg) end)
  end
end
