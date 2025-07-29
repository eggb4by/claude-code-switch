# Claude Code 配置切换工具

一个用于快速切换Claude Code不同API配置的工具，支持多个渠道和自定义配置。

## 功能特性

- 🚀 支持多个API渠道快速切换
- 🎨 交互式界面，清晰显示当前配置状态
- 🔧 自动备份和合并现有配置
- 💻 跨平台支持 (macOS/Linux/Windows)
- 📝 JSON配置文件，易于扩展和维护

## 系统要求

### Unix系统 (macOS/Linux)
- Bash shell
- [jq](https://jqlang.github.io/jq/) 工具

### Windows系统
- Windows 10或更高版本
- [jq](https://jqlang.github.io/jq/) 工具

## 安装

### 1. 下载和配置文件
将以下文件下载到同一个目录：
- `cc-switch.sh` - Unix系统脚本
- `cc-switch.bat` - Windows系统脚本
- `channels.json.example` - 配置文件模板

然后复制并配置：
```bash
# 复制模板文件
cp channels.json.example channels.json

# 编辑配置文件，填入你的真实API密钥
vim channels.json  # 或使用其他编辑器
```

### 2. 安装依赖

#### macOS
```bash
brew install jq
```

#### Ubuntu/Debian
```bash
sudo apt-get install jq
```

#### CentOS/RHEL
```bash
sudo yum install jq
```

#### Windows
- 访问 [jq官网](https://jqlang.github.io/jq/download/)
- 下载Windows版本的jq.exe
- 将jq.exe放入PATH环境变量包含的目录中

或使用包管理器：
```bash
# 使用Scoop
scoop install jq

# 使用Chocolatey
choco install jq
```

### 3. 设置权限 (Unix系统)
```bash
chmod +x cc-switch.sh
```

## 使用方法

### Unix系统 (macOS/Linux)
```bash
# 进入交互式模式
./cc-switch.sh

# 查看Claude Code配置
./cc-switch.sh -v
./cc-switch.sh --view

# 添加新的渠道配置
./cc-switch.sh -a
./cc-switch.sh --add

# 显示帮助信息
./cc-switch.sh -h
./cc-switch.sh --help
```

### Windows系统
```cmd
REM 进入交互式模式
cc-switch.bat

REM 查看Claude Code配置
cc-switch.bat -v
cc-switch.bat --view

REM 添加新的渠道配置
cc-switch.bat -a
cc-switch.bat --add

REM 显示帮助信息
cc-switch.bat -h
cc-switch.bat --help
```

### 命令行选项

| 选项 | 长选项 | 说明 |
|------|--------|------|
| `-v` | `--view` | 查看当前Claude Code配置内容 |
| `-a` | `--add` | 添加新的渠道配置 |
| `-h` | `--help` | 显示帮助信息 |
| 无参数 | - | 进入交互式配置切换模式 |

## 配置说明

### 配置文件结构

`channels.json` 文件包含所有渠道的配置信息：

```json
{
  "channels": {
    "渠道ID": {
      "config": {
        "env": {
          "ANTHROPIC_BASE_URL": "API基础URL",
          "ANTHROPIC_AUTH_TOKEN": "认证令牌",
          "ANTHROPIC_MODEL": "模型名称"
        }
      }
    }
  }
}
```

**注意**: 
- 渠道直接使用ID作为显示名称，无需额外的name和description字段
- 当前使用的渠道通过读取Claude Code的实际配置文件自动识别
- 脚本会将Claude Code当前配置与各渠道配置进行匹配来确定当前渠道

### 预置渠道

工具预置了以下渠道配置：

1. **302ai** - 302.AI API服务
2. **official** - Anthropic官方Claude API
3. **openrouter** - OpenRouter API服务
4. **zhipu** - 智谱AI API服务
5. **moonshot** - 月之暗面API服务
6. **custom** - 自定义API服务配置

### 添加新渠道

编辑 `channels.json` 文件，在 `channels` 对象中添加新的渠道配置：

```json
{
  "channels": {
    "your-channel": {
      "config": {
        "env": {
          "ANTHROPIC_BASE_URL": "https://your-api-endpoint.com",
          "ANTHROPIC_AUTH_TOKEN": "your-auth-token",
          "ANTHROPIC_MODEL": "your-model-name"
        }
      }
    }
  }
}
```

### 配置字段说明

- `ANTHROPIC_BASE_URL`: API服务的基础URL（可选，官方API可不设置）
- `ANTHROPIC_AUTH_TOKEN`: API认证令牌
- `ANTHROPIC_MODEL`: 要使用的模型名称

## 使用示例

### 交互式切换配置
```bash
$ ./cc-switch.sh

===============================================
     Claude Code 配置切换工具
===============================================

当前渠道: moonshot (moonshot)
描述: moonshot 渠道

可用渠道:

  [1] moonshot [当前]

  [2] zhipu

请选择要切换的渠道 (输入序号):
选择 [1-2] (或 q 退出): 2

确认切换到渠道: zhipu? [y/N]
确认: y

✓ 已切换到渠道: zhipu
✓ 配置已保存到: /Users/username/.claude/settings.json

切换完成！重启Claude Code以使配置生效。
```

### 查看Claude Code配置
```bash
$ ./cc-switch.sh --view

===============================================
     当前Claude Code配置查看
===============================================

Claude Code设置文件: /Users/username/.claude/settings.json

=== 当前Claude Code设置文件内容 ===
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.moonshot.cn/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "sk-xxxxxxxxxxxx"
  }
}
```

### 添加新渠道
```bash
$ ./cc-switch.sh --add

===============================================
     添加新的渠道配置
===============================================

请输入渠道ID (用于内部标识，如: my-api):
渠道ID: my-custom-api

请输入API基础URL (可选，如: https://api.example.com):
基础URL: https://my-api.example.com

请输入API认证令牌:
认证令牌: sk-my-secret-token-123456

请输入模型名称 (可选，如: claude-3-5-sonnet-20241022):
模型名称: claude-3-5-sonnet-20241022

=== 配置预览 ===
渠道ID: my-custom-api
基础URL: https://my-api.example.com
认证令牌: sk-my-secr...
模型名称: claude-3-5-sonnet-20241022

确认添加此渠道配置? [y/N]
确认: y

✓ 渠道 'my-custom-api' 添加成功！
✓ 现在可以使用 './cc-switch.sh' 切换到此渠道
```

### 显示帮助信息
```bash
$ ./cc-switch.sh --help

Claude Code 配置切换工具

使用方法: ./cc-switch.sh [选项]

选项:
  -v, --view     查看当前Claude Code配置
  -a, --add      添加新的渠道配置
  -h, --help     显示此帮助信息

不带参数运行时进入交互式配置切换模式

示例:
  ./cc-switch.sh              # 进入交互式模式
  ./cc-switch.sh -v           # 查看Claude Code配置
  ./cc-switch.sh --view       # 查看Claude Code配置
  ./cc-switch.sh -a           # 添加新渠道
  ./cc-switch.sh --add        # 添加新渠道
  ./cc-switch.sh --help       # 显示帮助
```

## 注意事项

1. **配置文件安全**: 
   - `channels.json` 包含敏感的API密钥，已被 `.gitignore` 忽略
   - 使用 `channels.json.example` 作为模板，复制后填入真实密钥
   - 不要将包含真实密钥的 `channels.json` 提交到版本控制
2. **备份配置**: 脚本会自动合并现有的Claude Code配置，不会覆盖其他设置
3. **重启生效**: 切换配置后需要重启Claude Code才能生效
4. **Token安全**: 请妥善保管您的API令牌，不要分享给他人

## 故障排除

### 常见问题

#### Q: 提示 "jq: command not found"
A: 需要安装jq工具，请参考上面的安装说明。

#### Q: 权限被拒绝 (Unix系统)
A: 使用 `chmod +x cc-switch.sh` 设置执行权限。

#### Q: 配置切换后不生效
A: 确保重启了Claude Code应用程序。

#### Q: JSON配置文件格式错误
A: 使用JSON验证工具检查配置文件格式是否正确。

### 调试模式

如需查看详细的执行信息，可以：

**Unix系统:**
```bash
bash -x cc-switch.sh
```

**Windows系统:**
```cmd
echo on
cc-switch.bat
```

## 许可证

本项目采用 MIT 许可证。

## 贡献

欢迎提交Issue和Pull Request！

---

**提示**: 使用前请确保已正确配置相应的API密钥和权限。 