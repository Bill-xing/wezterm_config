local wezterm = require("wezterm")
local config = wezterm.config_builder()

local target = wezterm.target_triple or ""
local is_macos = target:find("darwin") ~= nil
local is_windows = target:find("windows") ~= nil
local path_sep = is_windows and "\\" or "/"

local function file_exists(path)
  local handle = io.open(path, "r")
  if handle then
    handle:close()
    return true
  end
  return false
end

local function normalize_path(path)
  if not path or path == "" then
    return ""
  end

  local normalized = tostring(path)
  if normalized:match("^file://") then
    normalized = normalized:gsub("^file://[^/]*", "")
  end

  if is_windows then
    normalized = normalized:gsub("^/([A-Za-z]:)", "%1")
    normalized = normalized:gsub("/", "\\")
  end

  return normalized
end

local function basename(path)
  local normalized = normalize_path(path)
  if normalized == "" then
    return ""
  end

  normalized = normalized:gsub("[/\\]+$", "")
  return normalized:match("([^/\\]+)$") or normalized
end

local function process_name(process)
  local name = basename(process)
  if name == "" then
    return "shell"
  end
  return name
end

local function shorten_path(path, max_parts)
  local normalized = normalize_path(path)
  if normalized == "" then
    return ""
  end

  local parts = {}
  for part in normalized:gmatch("[^/\\]+") do
    table.insert(parts, part)
  end

  if #parts == 0 then
    return normalized
  end

  local from = math.max(1, #parts - max_parts + 1)
  return table.concat(parts, path_sep, from, #parts)
end

local function cwd_name(pane)
  local cwd = pane and pane.current_working_dir
  if not cwd then
    return ""
  end

  local path = cwd.file_path or tostring(cwd)
  path = normalize_path(path)

  local home = normalize_path(wezterm.home_dir)
  if home ~= "" and path:sub(1, #home) == home then
    path = "~" .. path:sub(#home + 1)
  end

  if path == "~" then
    return "~"
  end

  if path:sub(1, 2) == "~/" or path:sub(1, 2) == "~\\" then
    local tail = shorten_path(path:sub(3), 3)
    if tail == "" then
      return "~"
    end
    return "~" .. path_sep .. tail
  end

  return shorten_path(path, 3)
end

local shells = {
  bash = true,
  fish = true,
  nu = true,
  pwsh = true,
  sh = true,
  tmux = true,
  zsh = true,
}

local function tab_label(tab)
  if tab.tab_title and tab.tab_title ~= "" then
    return tab.tab_title
  end

  local pane = tab.active_pane
  local proc = process_name(pane and pane.foreground_process_name)
  local cwd = cwd_name(pane)

  if shells[proc] and cwd ~= "" then
    return cwd
  end

  if cwd ~= "" and cwd ~= proc then
    return proc .. " @ " .. cwd
  end

  return proc
end

local function right_click_action(window, pane)
  local selection = window:get_selection_text_for_pane(pane)
  if selection and selection ~= "" then
    window:copy_to_clipboard(selection, "Clipboard")
    window:perform_action(wezterm.action.ClearSelection, pane)
  end
end

wezterm.on("format-tab-title", function(tab, _, _, _, hover, max_width)
  local bg = "#1e1e2e"
  local fg = "#cba6f7"
  local edge = "#11111b"

  if tab.is_active then
    bg = "#cba6f7"
    fg = "#11111b"
  elseif hover then
    bg = "#313244"
    fg = "#cba6f7"
  end

  local title = string.format(" %d %s ", tab.tab_index + 1, tab_label(tab))
  title = wezterm.truncate_right(title, math.max(10, max_width - 1))

  return {
    { Background = { Color = edge } },
    { Foreground = { Color = bg } },
    { Text = " " },
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Attribute = { Intensity = tab.is_active and "Bold" or "Normal" } },
    { Text = title },
    { Background = { Color = edge } },
    { Foreground = { Color = bg } },
    { Text = " " },
  }
end)

local fonts = {
  "JetBrains Mono",
  "JetBrainsMono Nerd Font",
  "Symbols Nerd Font Mono",
}

if is_macos then
  table.insert(fonts, 3, "Heiti SC")
elseif is_windows then
  table.insert(fonts, 3, "Microsoft YaHei UI")
else
  table.insert(fonts, 3, "Noto Sans CJK SC")
end

local primary_mod = is_macos and "CMD" or "CTRL|SHIFT"
local link_mod = is_macos and "CMD" or "CTRL"

config.term = "wezterm"
config.check_for_updates = false
config.front_end = "WebGpu"
config.max_fps = 120
config.animation_fps = 120

config.font = wezterm.font_with_fallback(fonts)
config.font_size = is_windows and 12.5 or 14.0
config.line_height = 1.1
config.cell_width = 1.0

config.color_scheme = "Catppuccin Mocha"
config.set_environment_variables = {
  BAT_THEME = "Catppuccin-mocha",
  COLORTERM = "truecolor",
}
config.colors = {
  tab_bar = {
    background = "#11111b",
    new_tab = {
      bg_color = "#1e1e2e",
      fg_color = "#8087a2",
    },
    new_tab_hover = {
      bg_color = "#313244",
      fg_color = "#cdd6f4",
      intensity = "Bold",
    },
  },
}
config.window_background_opacity = is_windows and 0.92 or 0.86
config.text_background_opacity = 1.0
if is_macos then
  config.macos_window_background_blur = 32
end

config.window_padding = {
  left = 15,
  right = 15,
  top = 15,
  bottom = 15,
}

config.window_frame = {
  font = wezterm.font_with_fallback(fonts),
  font_size = 12.5,
  active_titlebar_bg = "#11111b",
  inactive_titlebar_bg = "#11111b",
}

config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.bypass_mouse_reporting_modifiers = "SHIFT"
config.mouse_bindings = {
  {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = wezterm.action.Nop,
  },
  {
    event = { Up = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = wezterm.action_callback(right_click_action),
  },
  {
    event = { Down = { streak = 1, button = "Left" } },
    mods = link_mod,
    action = wezterm.action.Nop,
  },
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = link_mod,
    action = wezterm.action.OpenLinkAtMouseCursor,
  },
}
config.hide_tab_bar_if_only_one_tab = false
config.show_tab_index_in_tab_bar = false
config.tab_max_width = 42
config.show_new_tab_button_in_tab_bar = true
config.tab_bar_at_bottom = false

config.enable_scroll_bar = false
config.scrollback_lines = 10000
config.adjust_window_size_when_changing_font_size = false
config.window_decorations = is_macos and "RESIZE | TITLE | MACOS_FORCE_ENABLE_SHADOW" or "RESIZE"
config.audible_bell = "Disabled"
config.visual_bell = {
  fade_in_function = "EaseIn",
  fade_in_duration_ms = 80,
  fade_out_function = "EaseOut",
  fade_out_duration_ms = 120,
}

config.cursor_blink_rate = 500
config.default_cursor_style = "BlinkingBar"
config.window_close_confirmation = "NeverPrompt"
if is_macos then
  config.native_macos_fullscreen_mode = true
end
config.switch_to_last_active_tab_when_closing_tab = true

if is_windows then
  if file_exists("C:/msys64/usr/bin/zsh.exe") then
    config.default_prog = { "C:/msys64/usr/bin/zsh.exe", "-l" }
  elseif file_exists("C:/Program Files/Git/bin/bash.exe") then
    config.default_prog = { "C:/Program Files/Git/bin/bash.exe", "-l" }
  end
elseif not is_macos then
  config.default_prog = { "zsh", "-l" }
end

config.keys = {
  { key = "Enter", mods = primary_mod, action = wezterm.action.ToggleFullScreen },
  { key = "d", mods = primary_mod, action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "d", mods = primary_mod .. "|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "w", mods = primary_mod, action = wezterm.action.CloseCurrentPane({ confirm = false }) },
}

return config
