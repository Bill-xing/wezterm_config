# Ubuntu 使用注意事项

这份文档专门记录这套 dotfiles 在 `Ubuntu` 下使用时，最容易忽略、但又最影响体验的注意事项。

适用对象：

- 使用 `./install/ubuntu.sh` 安装这套配置
- 终端主程序使用 `WezTerm`
- shell 使用 `zsh + oh-my-zsh + powerlevel10k`

## 安装后建议立即做的事情

执行完安装脚本后，建议至少完成下面几步：

```bash
chsh -s "$(command -v zsh)"
exec zsh
```

然后：

- 彻底关闭一次 `WezTerm`，再重新打开
- 首次启动 `nvim` 时允许它联网拉取 `LazyVim` 依赖
- 确认 `~/.local/bin` 已在 `PATH` 中

推荐顺手检查：

```bash
echo "$SHELL"
echo "$TERM"
command -v zsh tmux nvim yazi lazygit wezterm
```

## 最重要的一条：安装 `wezterm` 的 terminfo

如果系统里没有 `wezterm` 对应的 `terminfo`，但终端又把 `TERM` 声明成 `wezterm`，就很容易出现输入显示错乱、命令行重绘异常等问题。

典型表现包括：

- 你实际输入的是 `pwd`，屏幕上却显示成 `ppwpwd`
- 命令本身执行是对的，但命令行显示是错的
- 光标移动、删除、补全、整行刷新看起来“叠字”或“残影”

这类问题的根因通常不是 `zsh`、不是 `powerlevel10k`，而是 **`TERM=wezterm` 与系统缺少 `wezterm terminfo` 不匹配**。

### 检查系统是否已经安装了 `wezterm` terminfo

```bash
infocmp wezterm | head
```

如果这条命令报错，说明当前系统还没有安装。

### 安装方法

如果本机没有 `tic`，先安装：

```bash
sudo apt-get update
sudo apt-get install -y ncurses-bin
```

然后安装官方 `wezterm.terminfo` 到用户目录：

```bash
curl -fsSL \
  https://raw.githubusercontent.com/wezterm/wezterm/main/termwiz/data/wezterm.terminfo \
  -o /tmp/wezterm.terminfo

mkdir -p ~/.terminfo
tic -x -o ~/.terminfo /tmp/wezterm.terminfo
infocmp wezterm | head
```

如果你当前需要代理，可以先设置：

```bash
export http_proxy=http://127.0.0.1:10808
export https_proxy=http://127.0.0.1:10808
export all_proxy=socks5://127.0.0.1:10808
```

安装完成后：

- 彻底关闭所有 `WezTerm` 窗口
- 重新打开 `WezTerm`
- 再执行 `echo $TERM`

正常情况下应该看到：

```bash
wezterm
```

## `WezTerm` 改配置后，尽量整程序重启

很多人会在 shell 里直接 `exec zsh` 验证配置，但这只会重启 shell，不会重建终端进程本身。

有些问题必须 **完全退出 `WezTerm` 再打开** 才能看出变化，例如：

- `TERM` 值
- terminfo 匹配结果
- 输入法与终端的交互
- 字体回退与渲染问题

因此建议：

- 改 `config/zsh/.zshrc`、`config/zsh/.p10k.zsh` 后：可以先 `exec zsh`
- 改 `config/wezterm/wezterm.lua` 后：最好彻底关闭 `WezTerm` 再打开

## `powerlevel10k` 与 `zsh-autosuggestions` 是“显示层”

这套配置默认启用了：

- `powerlevel10k`
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`

它们会影响命令行的“显示效果”，但不一定会改变真实执行内容。

常见现象：

- 输入 `p`，右侧或后方出现补全建议：这是 `zsh-autosuggestions`
- 命令成功是绿色、失败是红色：这是 `powerlevel10k`
- 命令不同部分出现不同颜色：这是 `zsh-syntax-highlighting`

所以遇到问题时，建议先区分：

- **显示错了**：多半是终端重绘、`terminfo`、提示符或高亮插件
- **执行错了**：才更可能是 shell 绑定、alias、函数或程序本身

## Ubuntu 下字体要单独确认

这套配置会优先使用：

- `JetBrains Mono`
- `JetBrainsMono Nerd Font`
- `Symbols Nerd Font Mono`
- `Noto Sans CJK SC`

如果字体没装齐，常见现象包括：

- 图标显示成方块
- prompt 符号间距不对
- 中英文宽度看起来不协调

建议至少安装一种 Nerd Font。否则配置仍然能用，但显示效果会打折扣。

## `LazyVim` 首次启动需要联网

`config/nvim` 使用的是 `LazyVim` 方案，首次启动 `nvim` 时会自动下载插件管理器和插件。

因此首次启动前请确认：

- 网络可访问 GitHub
- 或者代理已开启

如果你用的是这套 zsh 配置中的别名，也可以直接：

```bash
proxyon
nvim
```

完成首次安装后再执行：

```bash
proxyoff
```

## `~/.local/bin` 下的工具依赖当前 shell 环境

Ubuntu 安装流程里，部分程序会安装到：

- `~/.local/bin`
- `~/.local/opt`

例如：

- `nvim`
- `yazi`
- `ya`
- `lazygit`

这套 `zsh` 配置会自动把 `~/.local/bin` 放进 `PATH`，但如果你：

- 还没有切换到 `zsh`
- 或者在其他 shell / GUI 启动器里直接运行程序

就可能出现“明明安装了但找不到命令”的现象。

这时优先检查：

```bash
echo "$PATH"
command -v nvim
command -v yazi
command -v lazygit
```

## 建议的 Ubuntu 自检命令

下面这组命令适合在安装完成后跑一遍：

```bash
echo "SHELL=$SHELL"
echo "TERM=$TERM"
echo "ZDOTDIR=${ZDOTDIR:-<empty>}"
command -v zsh tmux nvim yazi lazygit wezterm
infocmp "$TERM" | head
tmux source-file ~/.tmux.conf
nvim --version | head -n 1
yazi --version
lazygit --version
wezterm -V
```

如果你怀疑是 `wezterm terminfo` 问题，再补一条：

```bash
infocmp wezterm | head
```

## 常见故障优先排查顺序

遇到 Ubuntu 下的终端显示或交互异常时，建议按这个顺序检查：

1. `echo $TERM`
2. `infocmp $TERM | head`
3. `infocmp wezterm | head`
4. 是否完整重启过 `WezTerm`
5. 是否刚改过 `zsh-autosuggestions` / `powerlevel10k`
6. 是否缺少 Nerd Font
7. 是否首次启动 `nvim` 还没把插件拉完

其中，**如果现象是“输入对了、执行对了、但显示错了”**，优先怀疑 `terminfo`。

## 建议保留的认知

在 Ubuntu 上使用这套配置时，可以优先记住下面三点：

- `WezTerm` 的显示问题，先查 `TERM` 和 `terminfo`
- shell 外观问题，先区分是 `powerlevel10k`、自动建议还是语法高亮
- 改完终端配置后，尽量整程序重启，不要只重开 shell
