@echo off
setlocal enabledelayedexpansion

REM Claude Code配置切换脚本 (Windows)
REM 使用方法: cc-switch.bat [选项]
REM 选项:
REM   -v, --view    查看当前Claude Code配置文件
REM   -a, --add     添加新的渠道配置
REM   -h, --help    显示帮助信息

REM 配置文件路径
set CONFIG_FILE=channels.json
set CLAUDE_CODE_SETTINGS_FILE=%USERPROFILE%\.claude\settings.json

REM 解析命令行参数
call :parse_arguments %1

REM 如果没有退出，说明是交互模式
call :check_dependencies
if errorlevel 1 exit /b 1

call :check_config_file
if errorlevel 1 exit /b 1

call :ensure_claude_code_dir

call :interactive_mode

goto :eof

REM ========== 函数定义 ==========

:parse_arguments
    if "%1"=="" goto :eof
    if "%1"=="-h" call :show_help && exit /b 0
    if "%1"=="--help" call :show_help && exit /b 0
    if "%1"=="-v" call :view_config && exit /b 0
    if "%1"=="--view" call :view_config && exit /b 0
    if "%1"=="-a" call :add_channel && exit /b 0
    if "%1"=="--add" call :add_channel && exit /b 0
    
    echo [错误] 未知选项 '%1'
    echo.
    call :show_help
    exit /b 1
goto :eof

:show_help
    echo Claude Code 配置切换工具
    echo.
    echo 使用方法: %~nx0 [选项]
    echo.
    echo 选项:
    echo   -v, --view     查看当前Claude Code配置
    echo   -a, --add      添加新的渠道配置
    echo   -h, --help     显示此帮助信息
    echo.
    echo 不带参数运行时进入交互式配置切换模式
    echo.
    echo 示例:
    echo   %~nx0              # 进入交互式模式
    echo   %~nx0 -v           # 查看Claude Code配置
    echo   %~nx0 --view       # 查看Claude Code配置
    echo   %~nx0 -a           # 添加新渠道
    echo   %~nx0 --add        # 添加新渠道
    echo   %~nx0 --help       # 显示帮助
goto :eof

:view_config
    echo ===============================================
    echo      当前Claude Code配置查看
    echo ===============================================
    echo.
    
    echo Claude Code设置文件: %CLAUDE_CODE_SETTINGS_FILE%
    echo.
    
    echo === 当前Claude Code设置文件内容 ===
    if exist "%CLAUDE_CODE_SETTINGS_FILE%" (
        where jq >nul 2>&1
        if errorlevel 1 (
            type "%CLAUDE_CODE_SETTINGS_FILE%"
        ) else (
            jq "." "%CLAUDE_CODE_SETTINGS_FILE%"
        )
    ) else (
        echo Claude Code设置文件不存在
    )
goto :eof

:add_channel
    call :check_config_file
    if errorlevel 1 exit /b 1
    
    echo ===============================================
    echo      添加新的渠道配置
    echo ===============================================
    echo.
    
    REM 获取渠道ID
    :get_channel_id
    echo 请输入渠道ID (用于内部标识，如: my-api):
    set /p channel_id="渠道ID: "
    
    if "%channel_id%"=="" (
        echo [错误] 渠道ID不能为空
        goto :get_channel_id
    )
    
    REM 检查ID是否已存在
    jq -e ".channels[\"%channel_id%\"]" "%CONFIG_FILE%" >nul 2>&1
    if not errorlevel 1 (
        echo [错误] 渠道ID '%channel_id%' 已存在
        goto :get_channel_id
    )
    

    
    REM 获取基础URL
    echo 请输入API基础URL (可选，如: https://api.example.com):
    set /p base_url="基础URL: "
    
    REM 获取认证令牌
    :get_auth_token
    echo 请输入API认证令牌:
    set /p auth_token="认证令牌: "
    
    if "%auth_token%"=="" (
        echo [错误] 认证令牌不能为空
        goto :get_auth_token
    )
    
    REM 获取模型名称
    echo 请输入模型名称 (可选，如: claude-3-5-sonnet-20241022):
    set /p model_name="模型名称: "
    
    REM 显示配置预览
    echo.
    echo === 配置预览 ===
    echo 渠道ID: %channel_id%
    if not "%base_url%"=="" echo 基础URL: %base_url%
    echo 认证令牌: %auth_token:~0,10%...
    if not "%model_name%"=="" echo 模型名称: %model_name%
    echo.
    
    REM 确认添加
    echo 确认添加此渠道配置? [y/N]
    set /p confirm="确认: "
    
    if not "%confirm%"=="y" if not "%confirm%"=="Y" (
        echo 取消添加
        goto :eof
    )
    
    REM 构建JSON配置
    echo {"env":{}}>temp_new_channel.json
    
    if not "%base_url%"=="" (
        jq ".env.ANTHROPIC_BASE_URL = \"%base_url%\"" temp_new_channel.json > temp_config1.json
        move temp_config1.json temp_new_channel.json >nul
    )
    
    jq ".env.ANTHROPIC_AUTH_TOKEN = \"%auth_token%\"" temp_new_channel.json > temp_config2.json
    move temp_config2.json temp_new_channel.json >nul
    
    if not "%model_name%"=="" (
        jq ".env.ANTHROPIC_MODEL = \"%model_name%\"" temp_new_channel.json > temp_config3.json
        move temp_config3.json temp_new_channel.json >nul
    )
    
    REM 添加到配置文件
    for /f "tokens=*" %%i in ('type temp_new_channel.json') do set new_config=%%i
    
    echo {"config":%new_config%}>temp_channel.json
    for /f "tokens=*" %%i in ('type temp_channel.json') do set new_channel=%%i
    
    jq ".channels[\"%channel_id%\"] = %new_channel%" "%CONFIG_FILE%" > temp_updated_config.json
    move temp_updated_config.json "%CONFIG_FILE%" >nul
    
    REM 清理临时文件
    del temp_new_channel.json temp_channel.json >nul 2>&1
    
    echo.
    echo [成功] 渠道 '%channel_id%' 添加成功！
    echo [成功] 现在可以使用 '%~nx0' 切换到此渠道
goto :eof

:interactive_mode
    call :show_current_status
    call :show_available_channels
    call :select_channel
goto :eof

:check_dependencies
    where jq >nul 2>&1
    if errorlevel 1 (
        echo [错误] 需要安装 jq 工具来处理JSON文件
        echo.
        echo 安装方法:
        echo   1. 访问 https://jqlang.github.io/jq/download/
        echo   2. 下载适用于Windows的jq.exe
        echo   3. 将jq.exe放入PATH环境变量包含的目录中
        echo   4. 或者使用包管理器: scoop install jq 或 choco install jq
        exit /b 1
    )
goto :eof

:check_config_file
    if not exist "%CONFIG_FILE%" (
        echo [错误] 配置文件 %CONFIG_FILE% 不存在
        exit /b 1
    )
goto :eof

:ensure_claude_code_dir
    if not exist "%USERPROFILE%\.claude" (
        mkdir "%USERPROFILE%\.claude"
        echo [信息] 已创建Claude Code配置目录: %USERPROFILE%\.claude
    )
goto :eof

:get_current_channel
    if not exist "%CLAUDE_CODE_SETTINGS_FILE%" (
        set current_channel=none
        goto :eof
    )
    
    REM 读取Claude Code当前配置
    jq -r ".env // {}" "%CLAUDE_CODE_SETTINGS_FILE%" >temp_current_env.json 2>nul
    for /f "tokens=*" %%i in ('type temp_current_env.json') do set current_env=%%i
    
    if "%current_env%"=="null" (
        set current_channel=none
        del temp_current_env.json >nul 2>&1
        goto :eof
    )
    if "%current_env%"=="{}" (
        set current_channel=none
        del temp_current_env.json >nul 2>&1
        goto :eof
    )
    
    REM 与channels配置进行匹配
    for /f "tokens=*" %%i in ('jq -r ".channels | keys[]" "%CONFIG_FILE%"') do (
        set channel_id=%%i
        
        REM 获取当前配置的认证令牌和基础URL
        for /f "tokens=*" %%j in ('jq -r ".env.ANTHROPIC_AUTH_TOKEN // \"\"" temp_current_env.json') do set current_token=%%j
        for /f "tokens=*" %%k in ('jq -r ".env.ANTHROPIC_BASE_URL // \"\"" temp_current_env.json') do set current_base_url=%%k
        
        REM 获取渠道配置的认证令牌和基础URL
        for /f "tokens=*" %%l in ('jq -r ".channels[\"%%i\"].config.env.ANTHROPIC_AUTH_TOKEN // \"\"" "%CONFIG_FILE%"') do set channel_token=%%l
        for /f "tokens=*" %%m in ('jq -r ".channels[\"%%i\"].config.env.ANTHROPIC_BASE_URL // \"\"" "%CONFIG_FILE%"') do set channel_base_url=%%m
        
        REM 匹配条件：认证令牌相同且基础URL相同
        if "!current_token!"=="!channel_token!" if "!current_base_url!"=="!channel_base_url!" (
            set current_channel=%%i
            del temp_current_env.json >nul 2>&1
            goto :eof
        )
    )
    
    set current_channel=unknown
    del temp_current_env.json >nul 2>&1
goto :eof

:show_current_status
    call :get_current_channel
    
    set channel_name=
    set channel_desc=
    
    if "%current_channel%"=="none" (
        set channel_name=无配置
        set channel_desc=Claude Code尚未配置
    ) else if "%current_channel%"=="unknown" (
        set channel_name=未识别
        set channel_desc=当前配置不匹配任何已知渠道
    ) else (
        set channel_name=%current_channel%
        set channel_desc=%current_channel% 渠道
    )
    
    echo ===============================================
    echo      Claude Code 配置切换工具
    echo ===============================================
    echo.
    if "%current_channel%"=="none" (
        echo 当前渠道: !channel_name!
        echo 描述: !channel_desc!
    ) else if "%current_channel%"=="unknown" (
        echo 当前渠道: !channel_name!
        echo 描述: !channel_desc!
    ) else (
        echo 当前渠道: !channel_name! (!current_channel!)
        echo 描述: !channel_desc!
    )
    echo.
goto :eof

:show_available_channels
    echo 可用渠道:
    echo.
    
    set index=1
    call :get_current_channel
    
    for /f "tokens=*" %%i in ('jq -r ".channels | keys[]" "%CONFIG_FILE%"') do (
        set channel_id=%%i
        
        if "%%i"=="!current_channel!" (
            echo   [!index!] %%i [当前]
        ) else (
            echo   [!index!] %%i
        )
        echo.
        
        set /a index+=1
    )
goto :eof

:select_channel
    REM 获取渠道数量
    set channel_count=0
    for /f "tokens=*" %%i in ('jq -r ".channels | keys[]" "%CONFIG_FILE%"') do (
        set /a channel_count+=1
        set channel!channel_count!=%%i
    )
    
    echo 请选择要切换的渠道 (输入序号):
    set /p choice="选择 [1-!channel_count!] (或 q 退出): "
    
    if "!choice!"=="q" goto :cancel_operation
    if "!choice!"=="Q" goto :cancel_operation
    
    REM 验证输入是否为数字
    echo !choice!| findstr /r "^[1-9][0-9]*$" >nul
    if errorlevel 1 (
        echo [错误] 请输入有效的数字
        goto :select_channel
    )
    
    if !choice! lss 1 (
        echo [错误] 选择超出范围 (1-!channel_count!)
        goto :select_channel
    )
    if !choice! gtr !channel_count! (
        echo [错误] 选择超出范围 (1-!channel_count!)
        goto :select_channel
    )
    
    set selected_channel=!channel%choice%!
    call :get_current_channel
    
    if "!selected_channel!"=="!current_channel!" (
        echo [信息] 当前已经是所选渠道，无需切换
        goto :eof
    )
    
    echo.
    echo 确认切换到渠道: !selected_channel!? [y/N]
    set /p confirm="确认: "
    
    if "!confirm!"=="y" call :apply_config !selected_channel!
    if "!confirm!"=="Y" call :apply_config !selected_channel!
    if not "!confirm!"=="y" if not "!confirm!"=="Y" echo 取消切换
    
goto :eof

:apply_config
    set channel_id=%1
    
    REM 检查渠道配置是否存在
    for /f "tokens=*" %%i in ('jq ".channels.%channel_id%.config" "%CONFIG_FILE%"') do set channel_config=%%i
    if "!channel_config!"=="null" (
        echo [错误] 渠道 %channel_id% 配置不存在
        exit /b 1
    )
    
    REM 读取现有设置或创建空设置
    set existing_settings={}
    if exist "%CLAUDE_CODE_SETTINGS_FILE%" (
        for /f "tokens=*" %%i in ('type "%CLAUDE_CODE_SETTINGS_FILE%"') do set existing_settings=%%i
    )
    
    REM 创建临时文件来处理JSON合并
    echo !existing_settings! > temp_settings.json
    jq ". + %channel_config%" temp_settings.json > "%CLAUDE_CODE_SETTINGS_FILE%"
    del temp_settings.json
    
    echo.
    echo [成功] 已切换到渠道: %channel_id%
    echo [成功] 配置已保存到: %CLAUDE_CODE_SETTINGS_FILE%
    echo.
    echo 切换完成！重启Claude Code以使配置生效。
    
goto :eof

:cancel_operation
    echo 取消操作
    exit /b 0
goto :eof 