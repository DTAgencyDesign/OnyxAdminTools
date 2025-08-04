-- OnyxAdminTools v2.14 — /ah ïğåîáğàçóåò ID â íèê è âûçûâàåò /ahistory
script_name('OnyxAdminTools')
script_author('Dmitriy Tsyganov')
script_version('2.14')

local imgui = require 'imgui'
local inicfg = require 'inicfg'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local sampev = require 'lib.samp.events'
local hasSamp, samp = pcall(require, 'lib.samp')
if not hasSamp then samp = nil end
local sampfuncs = require 'sampfuncs'
local bit = require 'bit'
local VK_F5 = 0x74

function isConsoleActive() return sampfuncsConsoleIsActive ~= nil and sampfuncsConsoleIsActive() end
function isChatInputActive() return sampIsChatInputActive() end

local CONFIG_NAME = 'OnyxAdminTools'
local CONFIG_DIR = 'moonloader/config'
local cfg_path = string.format('%s/%s.ini', CONFIG_DIR, CONFIG_NAME)
local cfg = {}
local default_cfg = {
  main = {
    prefix_tag = '[ONYX AdminTools]',
    show_connect_msg = true,
    vk_group = 'vk.com/onx_rp',
    delay_ms = 1500,
  },
  texts = {},
  descriptions = {}
}

local showMainWindow = imgui.ImBool(false)
local showHelpWindow = imgui.ImBool(false)
local inputId = imgui.ImInt(-1)
local ahChoice = imgui.ImInt(1)
local popupMessage = nil
local popupTimer = 0

local showCategories = {
  ['Àâòîîòâåòû'] = imgui.ImBool(false),
  ['Òşğåìíûå'] = imgui.ImBool(false),
  ['Ìóòû'] = imgui.ImBool(false),
  ['Ñèñòåìíûå'] = imgui.ImBool(false),
}

local categories = {
  ['Àâòîîòâåòû'] = {'lid','admin','helper','spt','offtop1','offtop2'},
  ['Òşğåìíûå'] = {'dm','dmzz','mdm','db','mdb','tk','sk','rk','sanim','nrd','sriv'},
  ['Ìóòû'] = {'caps','flood','mg','adeq','oskp','oska','oskf'},
  ['Ñèñòåìíûå'] = {'athelp','atrel'}
}

local noIdRequired = { athelp=true, atrel=true }

local COL = {
  RED = '{FF0000}', ORANGE = '{FFA500}', WHITE = '{FFFFFF}', GREEN = '{00FF00}'
}
local function chat(msg) sampAddChatMessage(msg, -1) end
local function wait_ms(ms) wait(ms) end
local function send_cmd(cmd) sampSendChat(cmd) end
local function vk() return cfg.main.vk_group or default_cfg.main.vk_group end
local function replace_tokens(s) return s:gsub('%%VK%%', vk()) end
local function show_popup(text) popupMessage = text popupTimer = os.clock() + 2.0 end
local function is_valid_player(id) return id and id >= 0 and id <= 1000 end

function load_config()
  local ini = inicfg.load(default_cfg, cfg_path)
  cfg = ini or default_cfg
end

function sequence_for(id, steps)
  local delay = tonumber(cfg.main.delay_ms or 1500)
  lua_thread.create(function()
    for _, cmd in ipairs(steps) do send_cmd(cmd) wait_ms(delay) end
  end)
end

function do_action(cmd_name, id)
  if not noIdRequired[cmd_name] and not is_valid_player(id) then
    show_popup("Íåêîğğåêòíûé ID: " .. tostring(id)) return
  end
  local desc = cfg.descriptions[cmd_name] or ''
  local duration = tonumber(desc:match('(%d+)%s*ìèí')) or 40
  local reason = cfg.texts[cmd_name .. '_reason'] or '...'

  if cmd_name == 'lid' or cmd_name == 'admin' or cmd_name == 'helper' then
    sequence_for(id, { '/gj '..id, '/pm '..id..' '..(replace_tokens(cfg.texts[cmd_name..'_line1'] or '...')), '/pm '..id..' '..(cfg.texts[cmd_name..'_line2'] or '...'), '/gg '..id })
  elseif cmd_name == 'spt' then
    sequence_for(id, { '/gj '..id, '/pm '..id..' '..(cfg.texts.spt_line1 or '...'), '/sp '..id, '/pm '..id..' '..(cfg.texts.spt_line2 or '...'), '/gg '..id })
  elseif cmd_name:find('offtop') then
    sequence_for(id, { '/pm '..id..' '..(cfg.texts[cmd_name..'_line'] or '...') })
  elseif cmd_name == 'caps' or cmd_name == 'flood' or cmd_name == 'mg' or cmd_name == 'adeq' or cmd_name:match('osk') then
    sequence_for(id, { string.format('/mute %d %d %s', id, duration, reason), '/gg '..id })
  elseif cmd_name == 'athelp' then
    showHelpWindow.v = true
  elseif cmd_name == 'atrel' then
    load_config()
    chat(COL.GREEN .. 'Êîíôèãóğàöèÿ óñïåøíî ïåğåçàãğóæåíà.')
  else
    sequence_for(id, { string.format('/jail %d %d %s', id, duration, reason), '/gg '..id })
  end
  show_popup("Êîìàíäà /" .. cmd_name .. (id and (' '..id) or ''))
end

function get_nickname_by_id(id)
  if sampIsPlayerConnected(id) then
    return sampGetPlayerNickname(id)
  end
  return nil
end

local fontBold = nil
local fontBoldItalic = nil
function imgui.OnInitialize()
  local io = imgui.GetIO()
  fontBold = io.Fonts:AddFontFromFileTTF('resource/fonts/ProximaNova-Bold.ttf', 16.0, nil, io.Fonts:GetGlyphRangesCyrillic())
  fontBoldItalic = io.Fonts:AddFontFromFileTTF('resource/fonts/ProximaNova-BoldItalic.ttf', 18.0, nil, io.Fonts:GetGlyphRangesCyrillic())
end

function imgui.OnDrawFrame()
  if showMainWindow.v then
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.1, 0.1, 0.1, 0.85))
    imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 8)
    imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 5)
    imgui.SetNextWindowSize(imgui.ImVec2(520, 450), imgui.Cond.FirstUseEver)

    if imgui.Begin(u8'ONYX Admin Tools îò Äìèòğèÿ Öûãàíîâ', showMainWindow,
      bit.bor(imgui.WindowFlags.NoCollapse, imgui.WindowFlags.AlwaysAutoResize)) then

      imgui.PushFont(fontBoldItalic)
      imgui.Text(u8'ONYX Admin Tools îò Äìèòğèÿ Öûãàíîâ')
      imgui.PopFont()

      imgui.PushFont(fontBold)
      imgui.TextColored(imgui.ImVec4(1.0, 0.7, 0.0, 1.0), u8'Îñíîâíîå ìåíş:')
      imgui.InputInt(u8'ID èãğîêà', inputId)
      imgui.Separator()

      local labels = {
        ['Àâòîîòâåòû'] = u8'Îáğàáîòêà ğåïîğòîâ',
        ['Òşğåìíûå'] = u8'Òşğåìíûå íàêàçàíèÿ',
        ['Ìóòû'] = u8'Íàêàçàíèÿ ÷àòà',
        ['Ñèñòåìíûå'] = u8'Ñèñòåìíûå'
      }

      for section, commands in pairs(categories) do
        if imgui.Checkbox(labels[section] or section, showCategories[section]) then end
        if showCategories[section].v then
          for _, cmd in ipairs(commands) do
            local desc = cfg.descriptions[cmd] or 'Îïèñàíèå îòñóòñòâóåò'
            if imgui.Button(u8(desc), imgui.ImVec2(400, 0)) then
              if noIdRequired[cmd] then do_action(cmd, nil)
              elseif is_valid_player(inputId.v) then do_action(cmd, inputId.v)
              else show_popup("Ââåäèòå êîğğåêòíûé ID") end
            end
          end
          imgui.Separator()
        end
      end

      imgui.InputInt(u8'AH: ID èãğîêà', inputId)
      imgui.RadioButton(u8'1. Ñïèñîê íèêîâ', ahChoice, 1)
      imgui.RadioButton(u8'2. Ñïèñîê íàêàçàíèé', ahChoice, 2)
      if imgui.Button(u8'AH: Ïîêàçàòü èíôîğìàöèş') then
        if is_valid_player(inputId.v) then
          local nickname = get_nickname_by_id(inputId.v)
          if nickname then
            local cmd = string.format("/ahistory %s %d", nickname, ahChoice.v)
            send_cmd(cmd)
            show_popup("Âûïîëíåíî: " .. cmd)
          else
            show_popup("Îøèáêà: íèêíåéì íå íàéäåí")
          end
        else
          show_popup("Ââåäèòå êîğğåêòíûé ID")
        end
      end
      imgui.PopFont()
    end
    imgui.End()
    imgui.PopStyleVar(2)
    imgui.PopStyleColor()
  end

  if showHelpWindow.v then
    imgui.SetNextWindowSize(imgui.ImVec2(600, 500), imgui.Cond.FirstUseEver)
    if imgui.Begin(u8'Ñïğàâêà — Êîìàíäû', showHelpWindow) then
      for category, cmds in pairs(categories) do
        imgui.Text(u8(category .. ':'))
        for _, cmd in ipairs(cmds) do
          local desc = cfg.descriptions[cmd] or 'Íåò îïèñàíèÿ'
          imgui.BulletText(u8('/'..cmd .. ' — ' .. desc))
        end
        imgui.Separator()
      end
      if imgui.Button(u8'Çàêğûòü') then showHelpWindow.v = false end
    end
    imgui.End()
  end

  if popupMessage and os.clock() < popupTimer then
    imgui.SetNextWindowPos(imgui.ImVec2(10, 10), imgui.Cond.Always)
    if imgui.Begin(u8'Óâåäîìëåíèå', nil,
      bit.bor(imgui.WindowFlags.AlwaysAutoResize, imgui.WindowFlags.NoTitleBar,
              imgui.WindowFlags.NoResize, imgui.WindowFlags.NoMove)) then
      imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), u8(popupMessage))
    end
    imgui.End()
  end
end

function main()
  while not isSampAvailable() do wait(250) end
  load_config()
  sampRegisterChatCommand('atmenu', function() showMainWindow.v = not showMainWindow.v end)
  sampRegisterChatCommand('ah', function(arg)
    local id, opt = arg:match('^(%d+)%s+(%d+)$')
    id, opt = tonumber(id), tonumber(opt)
    if id and opt and sampIsPlayerConnected(id) then
      local nick = get_nickname_by_id(id)
      if nick then
        local cmd = string.format('/ahistory %s %d', nick, opt)
        send_cmd(cmd)
        show_popup('Âûïîëíåíî: ' .. cmd)
      else
        show_popup('Íèêíåéì íå íàéäåí')
      end
    else
      show_popup('Èñïîëüçóéòå: /ah [id] [1 èëè 2]')
    end
  end)
  local commands = {
    'athelp','atrel','lid','admin','helper','spt','dm','dmzz','mdm','db','mdb','tk','sk','rk','sanim','nrd','sriv',
    'caps','flood','mg','adeq','oskp','oska','oskf','offtop1','offtop2'
  }
  for _, cmd in ipairs(commands) do
    if noIdRequired[cmd] then
      sampRegisterChatCommand(cmd, function() do_action(cmd, nil) end)
    else
      sampRegisterChatCommand(cmd, function(arg) do_action(cmd, tonumber(arg)) end)
    end
  end
  imgui.Process = true
  if cfg.main.show_connect_msg then
    chat(COL.ORANGE .. cfg.main.prefix_tag .. COL.WHITE .. ' Ââåäèòå /atmenu èëè íàæìèòå F5')
  end
  while true do
    wait(0)
    imgui.Process = showMainWindow.v or showHelpWindow.v
    imgui.Blocking = showMainWindow.v or showHelpWindow.v
    if wasKeyPressed(VK_F5) and not isConsoleActive() and not isChatInputActive() then
      showMainWindow.v = not showMainWindow.v
    end
  end
end
