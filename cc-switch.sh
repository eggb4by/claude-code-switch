#!/bin/bash

# Claude Code配置切换脚本 (macOS/Linux)
# 使用方法: ./cc-switch.sh [选项]
# 选项:
#   -v, --view    查看当前Claude Code配置文件
#   -a, --add     添加新的渠道配置
#   -h, --help    显示帮助信息

set -e

# 配置文件路径
CONFIG_FILE="channels.json"
CLAUDE_CODE_SETTINGS_FILE="$HOME/.claude/settings.json"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查必要工具
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}错误: 需要安装 jq 工具来处理JSON文件${NC}"
        echo "安装方法:"
        echo "  macOS: brew install jq"
        echo "  Ubuntu/Debian: sudo apt-get install jq"
        echo "  CentOS/RHEL: sudo yum install jq"
        exit 1
    fi
}

# 检查配置文件是否存在
check_config_file() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}错误: 配置文件 $CONFIG_FILE 不存在${NC}"
        exit 1
    fi
}

# 确保Claude Code设置目录存在
ensure_claude_code_dir() {
    if [ ! -d "$HOME/.claude" ]; then
        mkdir -p "$HOME/.claude"
        echo -e "${GREEN}已创建Claude Code配置目录: $HOME/.claude${NC}"
    fi
}

# 获取当前渠道
get_current_channel() {
    if [ ! -f "$CLAUDE_CODE_SETTINGS_FILE" ]; then
        echo "none"
        return
    fi
    
    # 读取Claude Code当前配置
    local current_env=$(jq -r '.env // {}' "$CLAUDE_CODE_SETTINGS_FILE" 2>/dev/null)
    if [ "$current_env" = "null" ] || [ "$current_env" = "{}" ]; then
        echo "none"
        return
    fi
    
    # 与channels配置进行匹配
    local channels=$(jq -r '.channels | keys[]' "$CONFIG_FILE" 2>/dev/null)
    while IFS= read -r channel_id; do
        local channel_env=$(jq -r '.channels["'${channel_id}'"].config.env // {}' "$CONFIG_FILE" 2>/dev/null)
        
        # 比较关键配置字段
        local current_token=$(echo "$current_env" | jq -r '.ANTHROPIC_AUTH_TOKEN // ""')
        local current_base_url=$(echo "$current_env" | jq -r '.ANTHROPIC_BASE_URL // ""')
        
        local channel_token=$(echo "$channel_env" | jq -r '.ANTHROPIC_AUTH_TOKEN // ""')
        local channel_base_url=$(echo "$channel_env" | jq -r '.ANTHROPIC_BASE_URL // ""')
        
        # 匹配条件：认证令牌相同且基础URL相同（或都为空）
        if [ "$current_token" = "$channel_token" ] && [ "$current_base_url" = "$channel_base_url" ]; then
            echo "$channel_id"
            return
        fi
    done <<< "$channels"
    
    echo "unknown"
}

# 显示当前配置状态
show_current_status() {
    local current_channel=$(get_current_channel)
    local channel_name=""
    local channel_desc=""
    
    case "$current_channel" in
        "none")
            channel_name="无配置"
            channel_desc="Claude Code尚未配置"
            ;;
        "unknown")
            channel_name="未识别"
            channel_desc="当前配置不匹配任何已知渠道"
            ;;
        *)
            channel_name="$current_channel"
            channel_desc="$current_channel 渠道"
            ;;
    esac
    
    echo -e "${BLUE}===============================================${NC}"
    echo -e "${BLUE}     Claude Code 配置切换工具${NC}"
    echo -e "${BLUE}===============================================${NC}"
    echo ""
    if [ "$current_channel" = "none" ] || [ "$current_channel" = "unknown" ]; then
        echo -e "${YELLOW}当前渠道:${NC} $channel_name"
        echo -e "${YELLOW}描述:${NC} $channel_desc"
    else
        echo -e "${GREEN}当前渠道:${NC} $channel_name ($current_channel)"
        echo -e "${GREEN}描述:${NC} $channel_desc"
    fi
    echo ""
}

# 显示所有可用渠道
show_available_channels() {
    echo -e "${YELLOW}可用渠道:${NC}"
    echo ""
    
    local channels=$(jq -r '.channels | keys[]' "$CONFIG_FILE")
    local index=1
    
    while IFS= read -r channel_id; do
        local current_channel=$(get_current_channel)
        
        if [ "$channel_id" = "$current_channel" ]; then
            echo -e "  ${GREEN}[$index]${NC} $channel_id ${GREEN}[当前]${NC}"
        else
            echo -e "  [$index] $channel_id"
        fi
        echo ""
        
        index=$((index + 1))
    done <<< "$channels"
}

# 应用配置到Claude设置文件
apply_config() {
    local channel_id=$1
    local channel_config=$(jq '.channels["'${channel_id}'"].config' "$CONFIG_FILE")
    
    if [ "$channel_config" = "null" ]; then
        echo -e "${RED}错误: 渠道 $channel_id 配置不存在${NC}"
        return 1
    fi
    
    # 读取现有设置或创建空设置
    local existing_settings="{}"
    if [ -f "$CLAUDE_CODE_SETTINGS_FILE" ]; then
        existing_settings=$(cat "$CLAUDE_CODE_SETTINGS_FILE")
    fi
    
    # 合并配置
    local new_settings=$(echo "$existing_settings" | jq ". + $channel_config")
    
    # 写入新配置
    echo "$new_settings" | jq '.' > "$CLAUDE_CODE_SETTINGS_FILE"
    
    echo -e "${GREEN}✓ 已切换到渠道: $channel_id${NC}"
    echo -e "${GREEN}✓ 配置已保存到: $CLAUDE_CODE_SETTINGS_FILE${NC}"
}

# 选择渠道
select_channel() {
    local channels=($(jq -r '.channels | keys[]' "$CONFIG_FILE"))
    local total_channels=${#channels[@]}
    
    echo -e "${YELLOW}请选择要切换的渠道 (输入序号):${NC}"
    read -p "选择 [1-$total_channels] (或 q 退出): " choice
    
    if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
        echo "取消操作"
        exit 0
    fi
    
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}错误: 请输入有效的数字${NC}"
        return 1
    fi
    
    if [ "$choice" -lt 1 ] || [ "$choice" -gt "$total_channels" ]; then
        echo -e "${RED}错误: 选择超出范围 (1-$total_channels)${NC}"
        return 1
    fi
    
    local selected_channel=${channels[$((choice - 1))]}
    local current_channel=$(get_current_channel)
    
    if [ "$selected_channel" = "$current_channel" ]; then
        echo -e "${YELLOW}当前已经是所选渠道，无需切换${NC}"
        return 0
    fi
    
    echo ""
    echo -e "${YELLOW}确认切换到渠道: $selected_channel? [y/N]${NC}"
    read -p "确认: " confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        apply_config "$selected_channel"
        echo ""
        echo -e "${GREEN}切换完成！重启Claude Code以使配置生效。${NC}"
    else
        echo "取消切换"
    fi
}

# 添加新渠道
add_channel() {
    check_config_file
    
    echo -e "${BLUE}===============================================${NC}"
    echo -e "${BLUE}     添加新的渠道配置${NC}"
    echo -e "${BLUE}===============================================${NC}"
    echo ""
    
    # 获取渠道ID
    while true; do
        echo -e "${YELLOW}请输入渠道ID (用于内部标识，如: my-api):${NC}"
        read -p "渠道ID: " channel_id
        
        if [ -z "$channel_id" ]; then
            echo -e "${RED}错误: 渠道ID不能为空${NC}"
            continue
        fi
        
        # 检查ID是否已存在
        if jq -e ".channels[\"$channel_id\"]" "$CONFIG_FILE" >/dev/null 2>&1; then
            echo -e "${RED}错误: 渠道ID '$channel_id' 已存在${NC}"
            continue
        fi
        
        # 检查ID格式（只允许字母、数字、连字符、下划线）
        if [[ ! "$channel_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            echo -e "${RED}错误: 渠道ID只能包含字母、数字、连字符和下划线${NC}"
            continue
        fi
        
        break
    done
    

    
    # 获取基础URL
    echo -e "${YELLOW}请输入API基础URL (可选，如: https://api.example.com):${NC}"
    read -p "基础URL: " base_url
    
    # 获取认证令牌
    while true; do
        echo -e "${YELLOW}请输入API认证令牌:${NC}"
        read -p "认证令牌: " auth_token
        
        if [ -z "$auth_token" ]; then
            echo -e "${RED}错误: 认证令牌不能为空${NC}"
            continue
        fi
        
        break
    done
    
    # 获取模型名称
    echo -e "${YELLOW}请输入模型名称 (可选，如: claude-3-5-sonnet-20241022):${NC}"
    read -p "模型名称: " model_name
    
    # 构建配置JSON
    local config="{}"
    config=$(echo "$config" | jq ".env = {}")
    
    if [ ! -z "$base_url" ]; then
        config=$(echo "$config" | jq ".env.ANTHROPIC_BASE_URL = \"$base_url\"")
    fi
    
    config=$(echo "$config" | jq ".env.ANTHROPIC_AUTH_TOKEN = \"$auth_token\"")
    
    if [ ! -z "$model_name" ]; then
        config=$(echo "$config" | jq ".env.ANTHROPIC_MODEL = \"$model_name\"")
    fi
    
    # 显示配置预览
    echo ""
    echo -e "${GREEN}=== 配置预览 ===${NC}"
    echo -e "${YELLOW}渠道ID:${NC} $channel_id"
    if [ ! -z "$base_url" ]; then
        echo -e "${YELLOW}基础URL:${NC} $base_url"
    fi
    echo -e "${YELLOW}认证令牌:${NC} ${auth_token:0:10}..."
    if [ ! -z "$model_name" ]; then
        echo -e "${YELLOW}模型名称:${NC} $model_name"
    fi
    echo ""
    
    # 确认添加
    echo -e "${YELLOW}确认添加此渠道配置? [y/N]${NC}"
    read -p "确认: " confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "取消添加"
        return 0
    fi
    
    # 添加到配置文件
    local new_channel="{
        \"config\": $config
    }"
    
    local updated_config=$(jq ".channels[\"$channel_id\"] = $new_channel" "$CONFIG_FILE")
    echo "$updated_config" > "$CONFIG_FILE"
    
    echo ""
    echo -e "${GREEN}✓ 渠道 '$channel_id' 添加成功！${NC}"
    echo -e "${GREEN}✓ 现在可以使用 './cc-switch.sh' 切换到此渠道${NC}"
}

# 显示帮助信息
show_help() {
    echo -e "${BLUE}Claude Code 配置切换工具${NC}"
    echo ""
    echo "使用方法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -v, --view     查看当前Claude Code配置"
    echo "  -a, --add      添加新的渠道配置"
    echo "  -h, --help     显示此帮助信息"
    echo ""
    echo "不带参数运行时进入交互式配置切换模式"
    echo ""
    echo "示例:"
    echo "  $0              # 进入交互式模式"
    echo "  $0 -v           # 查看Claude Code配置"
    echo "  $0 --view       # 查看Claude Code配置"
    echo "  $0 -a           # 添加新渠道"
    echo "  $0 --add        # 添加新渠道"
    echo "  $0 --help       # 显示帮助"
}

# 查看配置文件
view_config() {
    echo -e "${BLUE}===============================================${NC}"
    echo -e "${BLUE}     当前Claude Code配置查看${NC}"
    echo -e "${BLUE}===============================================${NC}"
    echo ""
    
    echo -e "${YELLOW}Claude Code设置文件:${NC} $CLAUDE_CODE_SETTINGS_FILE"
    echo ""
    
    echo -e "${GREEN}=== 当前Claude Code设置文件内容 ===${NC}"
    if [ -f "$CLAUDE_CODE_SETTINGS_FILE" ]; then
        if command -v jq &> /dev/null; then
            jq '.' "$CLAUDE_CODE_SETTINGS_FILE"
        else
            cat "$CLAUDE_CODE_SETTINGS_FILE"
        fi
    else
        echo -e "${YELLOW}Claude Code设置文件不存在${NC}"
    fi
}

# 解析命令行参数
parse_arguments() {
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--view)
            view_config
            exit 0
            ;;
        -a|--add)
            add_channel
            exit 0
            ;;
        "")
            # 没有参数，进入交互模式
            return 0
            ;;
        *)
            echo -e "${RED}错误: 未知选项 '$1'${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 交互式模式
interactive_mode() {
    show_current_status
    show_available_channels
    
    while true; do
        select_channel
        break
    done
}

# 主函数
main() {
    # 先解析命令行参数
    parse_arguments "$@"
    
    # 如果没有退出，说明是交互模式
    check_dependencies
    check_config_file
    ensure_claude_code_dir
    
    interactive_mode
}

# 运行主函数，传递所有参数
main "$@" 