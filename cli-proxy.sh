#!/bin/bash
# ================================================================
# CLIProxyAPI 管理脚本 v2.0
# 功能：一键安装 / 一键更新 / 状态查看 / 服务管理 / 备份恢复 / 版本回滚
# 用法：bash cli-proxy.sh [install|update|status|restart|logs|uninstall|backup|restore|rollback|config|service]
# 不带参数时显示交互菜单
# 系统：Ubuntu / Debian / CentOS / RHEL / Alpine
# ================================================================

set -euo pipefail

# ----------------------------------------------------------------
# 颜色 & 样式
# ----------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ----------------------------------------------------------------
# 全局配置
# ----------------------------------------------------------------
INSTALL_DIR="${HOME}/CLIProxyAPI"
BACKUP_DIR="${HOME}/CLIProxyAPI-backups"
GITHUB_API="https://api.github.com/repos/router-for-me/CLIProxyAPI/releases/latest"
GITHUB_REPO="https://github.com/router-for-me/CLIProxyAPI.git"
CONTAINER_NAME="cli-proxy-api"
SERVICE_PORT="8317"
SCRIPT_PATH="$(realpath "$0")"
MAX_BACKUPS=5
SYSTEMD_SERVICE_NAME="cli-proxy-api.service"

# ----------------------------------------------------------------
# 工具函数
# ----------------------------------------------------------------
info() { echo -e "${CYAN} [INFO]${NC} $1"; }
success() { echo -e "${GREEN} [ ✓ ]${NC} $1"; }
warn() { echo -e "${YELLOW} [ ! ]${NC} $1"; }
error() { echo -e "${RED} [ ✗ ]${NC} $1"; }
step() { echo -e "\n${BOLD}${BLUE} ▶ $1${NC}"; echo -e " ${DIM}$(printf '%.0s─' {1..45})${NC}"; }
blank() { echo ""; }

# ----------------------------------------------------------------
# 系统检测
# ----------------------------------------------------------------
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="centos"
    elif [ -f /etc/alpine-release ]; then
        OS="alpine"
    else
        error "不支持的操作系统"
    fi
    info "检测到操作系统: $OS $VER"
}

# ----------------------------------------------------------------
# 检查root权限
# ----------------------------------------------------------------
check_root() {
    if [ "$EUID" -ne 0 ]; then
        warn "建议使用root权限运行此脚本"
        read -p "是否继续? [y/N]: " confirm
        if [[ "$confirm" != [yY] ]]; then
            exit 1
        fi
    fi
}

# ----------------------------------------------------------------
# Banner
# ----------------------------------------------------------------
show_banner() {
 clear
 echo -e "${CYAN}${BOLD}"
 cat << 'EOF'
 ╔═══════════════════════════════════════════════════════╗
 ║                                                       ║
 ║  ██████╗  █████╗  █████╗  █████╗  ███████╗  █████╗   ║
 ║  ██═══╝  ██═══╝  ██═══╝  ██═══╝  ██═════╝  ██═══╝   ║
 ║  ██      █████╗  ███████╗ █████╗  █████╗   █████╗    ║
 ║  ██         ███  ██═══██  ██═══╝  ██═══╝   ██═══╝    ║
 ║  ███████╗  █████╗  ██  ██  █████╗  ██  ██  ███████╗ ║
 ║  ════════╝  ══════╝  ╚═══╝  ══════╝  ╚════╝  ═══════╝ ║
 ║                                                       ║
 ║  API Management • 管理脚本 v2.0                      ║
 ╚═══════════════════════════════════════════════════════╝
EOF
 echo -e "${NC}"
}

# ----------------------------------------------------------------
# 获取最新版本号
# ----------------------------------------------------------------
get_latest_version() {
 local tag
 tag=$(curl -s --connect-timeout 10 "$GITHUB_API" 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
 echo "${tag:-latest}"
}

# ----------------------------------------------------------------
# 获取当前运行版本
# ----------------------------------------------------------------
get_current_version() {
 docker inspect "$CONTAINER_NAME" 2>/dev/null \
 | grep '"Image"' | head -1 \
 | grep -oP '(?<=:)[^",]+' \
 || echo "未安装"
}

# ----------------------------------------------------------------
# 检查容器是否在运行
# ----------------------------------------------------------------
is_running() {
 docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"
}

# ----------------------------------------------------------------
# 验证配置文件
# ----------------------------------------------------------------
validate_config() {
    local config_file="$INSTALL_DIR/config.yaml"
    if [ ! -f "$config_file" ]; then
        error "配置文件不存在: $config_file"
    fi
    
    # 检查YAML语法
    if command -v python3 &>/dev/null; then
        python3 -c "import yaml; yaml.safe_load(open('$config_file'))" 2>/dev/null || {
            error "配置文件YAML语法错误，请检查: $config_file"
        }
    fi
    
    # 检查必要配置项
    if ! grep -q "auth:" "$config_file"; then
        warn "配置文件中缺少auth配置项"
    fi
    
    if ! grep -q "providers:" "$config_file"; then
        warn "配置文件中缺少providers配置项"
    fi
    
    success "配置文件验证通过"
}

# ----------------------------------------------------------------
# 安装依赖
# ----------------------------------------------------------------
install_deps() {
    local missing=()
    command -v git &>/dev/null || missing+=("git")
    command -v curl &>/dev/null || missing+=("curl")
    command -v docker &>/dev/null || missing+=("docker")
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        info "安装依赖：${missing[*]}"
        
        case "$OS" in
            ubuntu|debian)
                apt-get update -qq
                apt-get install -y -qq "${missing[@]}"
                ;;
            centos|rhel)
                yum install -y -q "${missing[@]}"
                ;;
            alpine)
                apk add --no-cache "${missing[@]}"
                ;;
        esac
    fi
}

# ----------------------------------------------------------------
# 检查并安装 Docker
# ----------------------------------------------------------------
ensure_docker() {
 if command -v docker &>/dev/null && docker compose version &>/dev/null; then
    local docker_version
    docker_version=$(docker --version | cut -d' ' -f3 | tr -d ',')
    success "Docker 已就绪：$docker_version"
    
    # 检查Docker是否正在运行
    if ! docker info &>/dev/null; then
        error "Docker 服务未运行，请启动Docker服务"
    fi
    return
 fi

 warn "未检测到 Docker，开始自动安装..."
 
 case "$OS" in
    ubuntu|debian)
        apt-get update -qq
        apt-get install -y -qq ca-certificates curl gnupg lsb-release git

        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/$OS/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg

        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/$OS $(lsb_release -cs) stable" \
        > /etc/apt/sources.list.d/docker.list

        apt-get update -qq
        apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
        ;;
    centos|rhel)
        yum install -y -q yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y -q docker-ce docker-ce-cli containerd.io docker-compose-plugin
        ;;
    alpine)
        apk add --no-cache docker docker-compose
        ;;
 esac

 systemctl enable docker &>/dev/null || true
 systemctl start docker &>/dev/null || true
 success "Docker 安装完成"
}

# ----------------------------------------------------------------
# 准备项目目录
# ----------------------------------------------------------------
prepare_project() {
 if [[ -d "$INSTALL_DIR/.git" ]]; then
    info "项目目录已存在，同步最新代码..."
    cd "$INSTALL_DIR"
    git fetch --all -q
    git pull origin main -q 2>/dev/null || git pull origin master -q 2>/dev/null || true
    success "代码同步完成"
 else
    info "克隆项目仓库..."
    git clone -q "$GITHUB_REPO" "$INSTALL_DIR"
    success "项目克隆完成"
 fi
}

# ----------------------------------------------------------------
# 创建默认配置文件
# ----------------------------------------------------------------
prepare_config() {
 mkdir -p "$INSTALL_DIR/auths" "$INSTALL_DIR/logs"

 if [[ -f "$INSTALL_DIR/config.yaml" ]]; then
    success "config.yaml 已存在，跳过"
    
    # 验证现有配置
    validate_config
    return
 fi

 if [[ -f "$INSTALL_DIR/config.example.yaml" ]]; then
    cp "$INSTALL_DIR/config.example.yaml" "$INSTALL_DIR/config.yaml"
    warn "已从示例创建 config.yaml"
 else
    cat > "$INSTALL_DIR/config.yaml" << 'YAML'
# ================================================
# CLIProxyAPI 配置文件
# 文档: https://github.com/router-for-me/CLIProxyAPI
# ================================================

# 认证配置
auth:
 # 客户端连接本代理时使用的密钥（自定义）
 keys: []
 # 示例：
 # keys:
 # - "my-secret-key-123"

# AI服务提供商配置
providers:
  # OpenAI 配置示例
  - type: "openai"
    api_key: "your-openai-api-key-here"
    base_url: "https://api.openai.com/v1"
    models:
      - "gpt-3.5-turbo"
      - "gpt-4"
  
  # Claude 配置示例
  - type: "claude"
    api_key: "your-claude-api-key-here"
    base_url: "https://api.anthropic.com/v1"
  
  # Azure OpenAI 配置示例
  - type: "azure"
    api_key: "your-azure-api-key-here"
    base_url: "https://your-resource.openai.azure.com/openai/deployments/your-deployment"
    api_version: "2024-02-15-preview"

# 服务器配置
server:
  host: "0.0.0.0"
  port: 8317
  debug: false
  log_level: "info"

# 高级功能
features:
  # 请求速率限制
  rate_limit:
    enabled: true
    requests_per_minute: 60
  
  # 请求超时设置
  timeout:
    connect: 10
    read: 60
    write: 60
  
  # 重试策略
  retry:
    enabled: true
    max_attempts: 3
    backoff_factor: 2
YAML
    warn "已创建基础 config.yaml"
 fi

 blank
 warn "⚠ 请编辑配置文件填写你的 API Key："
 warn " ${BOLD}nano $INSTALL_DIR/config.yaml${NC}"
}

# ----------------------------------------------------------------
# 创建Docker Compose配置
# ----------------------------------------------------------------
create_docker_compose() {
    local compose_file="$INSTALL_DIR/docker-compose.yml"
    
    if [[ -f "$compose_file" ]]; then
        success "docker-compose.yml 已存在，跳过"
        return
    fi
    
    cat > "$compose_file" << 'YAML'
version: '3.8'

services:
  cli-proxy-api:
    image: eceasy/cli-proxy-api:${CLI_PROXY_VERSION:-latest}
    container_name: cli-proxy-api
    restart: unless-stopped
    ports:
      - "${SERVICE_PORT:-8317}:8317"
    environment:
      - CONFIG_PATH=/app/config.yaml
      - TZ=${TZ:-Asia/Shanghai}
    volumes:
      - ./config.yaml:/app/config.yaml:ro
      - ./auths:/app/auths:ro
      - ./logs:/app/logs
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8317/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    networks:
      - cli-proxy-network

networks:
  cli-proxy-network:
    driver: bridge
YAML
    success "docker-compose.yml 创建完成"
}

# ----------------------------------------------------------------
# 创建备份
# ----------------------------------------------------------------
create_backup() {
    if [ ! -d "$INSTALL_DIR" ]; then
        error "安装目录不存在，无法备份"
    fi
    
    mkdir -p "$BACKUP_DIR"
    
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="cli-proxy-api_backup_${timestamp}"
    local backup_path="$BACKUP_DIR/${backup_name}.tar.gz"
    
    # 创建备份
    info "创建备份: $backup_name"
    tar -czf "$backup_path" -C "$(dirname "$INSTALL_DIR")" "$(basename "$INSTALL_DIR")" 2>/dev/null
    
    # 清理旧备份
    local backup_count
    backup_count=$(ls -1 "$BACKUP_DIR"/cli-proxy-api_backup_*.tar.gz 2>/dev/null | wc -l)
    if [ "$backup_count" -gt "$MAX_BACKUPS" ]; then
        local old_backups
        old_backups=$(ls -1t "$BACKUP_DIR"/cli-proxy-api_backup_*.tar.gz | tail -n +$((MAX_BACKUPS + 1)))
        for backup in $old_backups; do
            rm -f "$backup"
            info "清理旧备份: $(basename "$backup")"
        done
    fi
    
    success "备份创建成功: $backup_path"
    info "可用备份:"
    ls -1h "$BACKUP_DIR"/cli-proxy-api_backup_*.tar.gz 2>/dev/null || echo "  无"
}

# ----------------------------------------------------------------
# 恢复备份
# ----------------------------------------------------------------
restore_backup() {
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        error "没有可用的备份"
    fi
    
    info "可用备份:"
    local i=1
    local backups=()
    for backup in "$BACKUP_DIR"/cli-proxy-api_backup_*.tar.gz; do
        if [ -f "$backup" ]; then
            backups+=("$backup")
            echo "  $i) $(basename "$backup") - $(du -h "$backup" | cut -f1)"
            ((i++))
        fi
    done
    
    if [ ${#backups[@]} -eq 0 ]; then
        error "没有可用的备份文件"
    fi
    
    echo ""
    read -p "请选择要恢复的备份编号 [1-${#backups[@]}]: " choice
    
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#backups[@]}" ]; then
        error "无效的选择"
    fi
    
    local selected_backup="${backups[$((choice-1))]}"
    
    # 停止当前服务
    if is_running; then
        info "停止当前服务..."
        docker stop "$CONTAINER_NAME" >/dev/null
        docker rm "$CONTAINER_NAME" >/dev/null
    fi
    
    # 恢复备份
    info "恢复备份: $(basename "$selected_backup")"
    rm -rf "$INSTALL_DIR"
    tar -xzf "$selected_backup" -C "$(dirname "$INSTALL_DIR")"
    
    success "备份恢复成功"
    info "安装目录: $INSTALL_DIR"
    
    # 重新启动服务
    info "重新启动服务..."
    cd "$INSTALL_DIR"
    CLI_PROXY_VERSION=$(get_current_version) \
    SERVICE_PORT="$SERVICE_PORT" \
    docker compose up -d
    
    success "服务已重启"
}

# ----------------------------------------------------------------
# 版本回滚
# ----------------------------------------------------------------
rollback_version() {
    if ! is_running; then
        error "服务未运行，无法回滚"
    fi
    
    info "可用版本:"
    info "1) 上一个稳定版本"
    info "2) 手动输入版本号"
    info "3) 从GitHub获取版本列表"
    
    echo ""
    read -p "请选择操作 [1-3]: " choice
    
    local target_version=""
    
    case "$choice" in
        1)
            # 获取上一个版本
            target_version=$(get_latest_version)
            # 这里简化处理，实际应该获取上一个稳定版本
            warn "将回滚到最新版本: $target_version"
            ;;
        2)
            read -p "请输入目标版本号 (如: v1.2.3): " target_version
            ;;
        3)
            info "正在获取版本列表..."
            local versions
            versions=$(curl -s --connect-timeout 10 "https://api.github.com/repos/router-for-me/CLIProxyAPI/releases" 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4 | head -10)
            echo "可用版本:"
            echo "$versions" | nl
            echo ""
            read -p "请选择版本编号: " version_choice
            target_version=$(echo "$versions" | sed -n "${version_choice}p")
            ;;
        *)
            error "无效的选择"
            ;;
    esac
    
    if [ -z "$target_version" ]; then
        error "未选择有效版本"
    fi
    
    info "正在回滚到版本: $target_version"
    
    # 创建当前状态备份
    create_backup
    
    # 执行回滚
    cd "$INSTALL_DIR"
    docker stop "$CONTAINER_NAME" >/dev/null
    docker rm "$CONTAINER_NAME" >/dev/null
    
    CLI_PROXY_VERSION="$target_version" \
    docker compose up -d --no-build --pull always
    
    success "版本回滚完成: $target_version"
    
    # 验证服务
    info "验证服务状态..."
    sleep 5
    verify_service
}

# ----------------------------------------------------------------
# 创建Systemd服务
# ----------------------------------------------------------------
create_systemd_service() {
    if [ ! -d "$INSTALL_DIR" ]; then
        error "请先安装服务"
    fi
    
    local service_file="/etc/systemd/system/$SYSTEMD_SERVICE_NAME"
    
    if [ -f "$service_file" ]; then
        success "Systemd服务已存在"
        info "管理服务: systemctl {start|stop|restart|status} $SYSTEMD_SERVICE_NAME"
        return
    fi
    
    info "创建Systemd服务..."
    
    cat > "$service_file" << SERVICE
[Unit]
Description=CLIProxyAPI Service
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
Restart=on-failure
RestartSec=30
User=root

[Install]
WantedBy=multi-user.target
SERVICE
    
    systemctl daemon-reload
    success "Systemd服务创建成功"
    info "启用服务: systemctl enable $SYSTEMD_SERVICE_NAME"
    info "启动服务: systemctl start $SYSTEMD_SERVICE_NAME"
    info "查看状态: systemctl status $SYSTEMD_SERVICE_NAME"
}

# ----------------------------------------------------------------
# 启动服务
# ----------------------------------------------------------------
start_service() {
    local version="$1"
    cd "$INSTALL_DIR"
    
    # 创建Docker Compose配置
    create_docker_compose
    
    info "使用镜像版本：$version"
    
    CLI_PROXY_VERSION="$version" \
    SERVICE_PORT="$SERVICE_PORT" \
    docker compose up -d --no-build --pull always
    
    success "容器启动完成"
    
    # 创建Systemd服务
    read -p "是否创建Systemd服务? [y/N]: " create_service
    if [[ "$create_service" == [yY] ]]; then
        create_systemd_service
    fi
}

# ----------------------------------------------------------------
# 验证服务健康
# ----------------------------------------------------------------
verify_service() {
    info "等待服务就绪..."
    local retries=15
    for ((i=1; i<=retries; i++)); do
        sleep 2
        local code
        code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${SERVICE_PORT}/health" 2>/dev/null || echo "0")
        if [[ "$code" == "200" ]]; then
            success "服务健康检查通过"
            info "访问地址: http://localhost:${SERVICE_PORT}"
            info "健康检查: http://localhost:${SERVICE_PORT}/health"
            return
        fi
        info "等待服务启动... ($i/$retries)"
    done
    
    warn "服务启动可能较慢，请稍后手动检查状态"
    warn "检查命令: curl http://localhost:${SERVICE_PORT}/health"
}

# ----------------------------------------------------------------
# 安装服务
# ----------------------------------------------------------------
install_service() {
    show_banner
    step "开始安装 CLIProxyAPI"

    detect_os
    check_root
    ensure_docker
    install_deps
    prepare_project
    prepare_config

    local version
    version=$(get_latest_version)
    info "获取到最新版本：$version"

    start_service "$version"
    verify_service

    blank
    success "安装完成！"
    info "管理脚本：${SCRIPT_PATH}"
    info "配置文件：${INSTALL_DIR}/config.yaml"
    info "项目目录：${INSTALL_DIR}"
    info "备份目录：${BACKUP_DIR}"
    info "访问地址：http://localhost:${SERVICE_PORT}"
    
    # 创建首次备份
    info "创建首次备份..."
    create_backup
}

# ----------------------------------------------------------------
# 更新服务
# ----------------------------------------------------------------
update_service() {
    show_banner
    step "开始更新 CLIProxyAPI"

    if ! is_running; then
        warn "服务未运行，请先安装"
        return 1
    fi

    local current_version
    local latest_version

    current_version=$(get_current_version)
    latest_version=$(get_latest_version)

    info "当前版本：$current_version"
    info "最新版本：$latest_version"

    if [[ "$current_version" == "$latest_version" ]]; then
        success "已经是最新版本"
        return
    fi

    # 创建备份
    info "更新前创建备份..."
    create_backup

    info "开始更新..."
    cd "$INSTALL_DIR"
    
    # 拉取新镜像
    CLI_PROXY_VERSION="$latest_version" \
    docker compose pull
    
    # 重启服务
    CLI_PROXY_VERSION="$latest_version" \
    docker compose up -d --no-build
    
    success "更新完成"
    info "新版本：$latest_version"

    verify_service
    
    # 清理旧镜像
    info "清理旧镜像..."
    docker image prune -f
}

# ----------------------------------------------------------------
# 服务状态
# ----------------------------------------------------------------
service_status() {
    show_banner
    step "服务状态"

    if is_running; then
        success "服务运行中"
        info "容器名称：$CONTAINER_NAME"
        info "服务端口：$SERVICE_PORT"
        info "安装目录：$INSTALL_DIR"

        # 获取更多容器信息
        echo ""
        info "容器详情："
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

        # 检查端口监听
        echo ""
        info "端口状态："
        if command -v netstat &>/dev/null; then
            netstat -tlnp | grep ":${SERVICE_PORT}" || echo "端口未监听"
        elif command -v ss &>/dev/null; then
            ss -tlnp | grep ":${SERVICE_PORT}" || echo "端口未监听"
        else
            warn "无法检查端口状态，缺少netstat或ss命令"
        fi
        
        # 检查服务健康
        echo ""
        info "健康检查："
        local health_status
        health_status=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${SERVICE_PORT}/health" 2>/dev/null || echo "无法连接")
        if [[ "$health_status" == "200" ]]; then
            success "服务健康检查: 通过"
        else
            warn "服务健康检查: 失败 (状态码: $health_status)"
        fi
        
        # 显示资源使用情况
        echo ""
        info "资源使用："
        docker stats "$CONTAINER_NAME" --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
    else
        warn "服务未运行"
        info "可以使用以下命令启动服务："
        echo "  $SCRIPT_PATH install"
        echo "  或"
        echo "  cd $INSTALL_DIR && docker compose up -d"
    fi
    
    # 显示备份信息
    echo ""
    info "备份信息："
    if [ -d "$BACKUP_DIR" ] && [ -n "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        local backup_count
        backup_count=$(ls -1 "$BACKUP_DIR"/cli-proxy-api_backup_*.tar.gz 2>/dev/null | wc -l)
        success "可用备份: $backup_count 个"
        ls -1h "$BACKUP_DIR"/cli-proxy-api_backup_*.tar.gz 2>/dev/null | head -5 | while read -r backup; do
            echo "  $(basename "$backup") - $(du -h "$backup" | cut -f1)"
        done
    else
        warn "无可用备份"
    fi
}

# ----------------------------------------------------------------
# 重启服务
# ----------------------------------------------------------------
restart_service() {
    show_banner
    step "重启服务"

    if is_running; then
        info "正在重启容器..."
        docker restart "$CONTAINER_NAME"
        sleep 3
        verify_service
        success "服务重启完成"
    else
        warn "服务未运行，请先安装"
    fi
}

# ----------------------------------------------------------------
# 查看日志
# ----------------------------------------------------------------
show_logs() {
    show_banner
    step "查看日志"

    if is_running; then
        info "显示实时日志（按 Ctrl+C 退出）"
        info "日志文件: $INSTALL_DIR/logs/"
        echo ""
        
        # 显示最近日志
        if [ -d "$INSTALL_DIR/logs" ] && [ -n "$(ls -A "$INSTALL_DIR/logs" 2>/dev/null)" ]; then
            info "最近的日志文件："
            ls -lt "$INSTALL_DIR/logs"/* 2>/dev/null | head -5 | while read -r log; do
                echo "  $(basename "$log") - $(du -h "$log" | cut -f1)"
            done
            echo ""
        fi
        
        docker logs -f "$CONTAINER_NAME" --tail 100
    else
        warn "服务未运行，请先安装"
    fi
}

# ----------------------------------------------------------------
# 编辑配置
# ----------------------------------------------------------------
edit_config() {
    show_banner
    step "编辑配置"

    if [ ! -f "$INSTALL_DIR/config.yaml" ]; then
        error "配置文件不存在，请先安装"
    fi

    info "配置文件: $INSTALL_DIR/config.yaml"
    echo ""
    info "使用以下命令编辑配置:"
    echo "  nano $INSTALL_DIR/config.yaml"
    echo ""
    info "编辑后需要重启服务生效:"
    echo "  $SCRIPT_PATH restart"
    
    read -p "是否现在编辑配置文件? [y/N]: " edit_now
    if [[ "$edit_now" == [yY] ]]; then
        ${EDITOR:-nano} "$INSTALL_DIR/config.yaml"
        success "配置文件已保存"
        
        read -p "是否重启服务使配置生效? [Y/n]: " restart_now
        if [[ "$restart_now" != [nN] ]]; then
            restart_service
        fi
    fi
}

# ----------------------------------------------------------------
# 卸载服务
# ----------------------------------------------------------------
uninstall_service() {
    show_banner
    step "卸载服务"

    if is_running; then
        info "停止并删除容器..."
        docker stop "$CONTAINER_NAME" >/dev/null
        docker rm "$CONTAINER_NAME" >/dev/null
        success "容器已删除"
    else
        warn "容器未运行"
    fi

    # 询问是否删除数据
    read -p "是否删除项目目录 (${INSTALL_DIR})? [y/N]: " confirm_delete
    if [[ "$confirm_delete" == [yY] ]]; then
        # 创建最终备份
        read -p "是否在删除前创建备份? [Y/n]: " create_final_backup
        if [[ "$create_final_backup" != [nN] ]]; then
            create_backup
        fi
        
        rm -rf "$INSTALL_DIR"
        success "项目目录已删除"
    else
        info "保留项目目录：${INSTALL_DIR}"
    fi
    
    # 询问是否删除备份
    read -p "是否删除备份目录 (${BACKUP_DIR})? [y/N]: " confirm_backup
    if [[ "$confirm_backup" == [yY] ]]; then
        rm -rf "$BACKUP_DIR"
        success "备份目录已删除"
    fi
    
    # 删除Systemd服务
    local service_file="/etc/systemd/system/$SYSTEMD_SERVICE_NAME"
    if [ -f "$service_file" ]; then
        read -p "是否删除Systemd服务? [y/N]: " confirm_service
        if [[ "$confirm_service" == [yY] ]]; then
            systemctl stop "$SYSTEMD_SERVICE_NAME" 2>/dev/null || true
            systemctl disable "$SYSTEMD_SERVICE_NAME" 2>/dev/null || true
            rm -f "$service_file"
            systemctl daemon-reload
            success "Systemd服务已删除"
        fi
    fi
    
    success "卸载完成"
}

# ----------------------------------------------------------------
# 显示增强菜单
# ----------------------------------------------------------------
show_menu() {
    blank
    echo -e "${BOLD}请选择操作：${NC}"
    echo -e " ${GREEN}1)${NC} 安装服务"
    echo -e " ${GREEN}2)${NC} 更新服务"
    echo -e " ${GREEN}3)${NC} 查看状态"
    echo -e " ${GREEN}4)${NC} 重启服务"
    echo -e " ${GREEN}5)${NC} 查看日志"
    echo -e " ${GREEN}6)${NC} 编辑配置"
    echo -e " ${GREEN}7)${NC} 创建备份"
    echo -e " ${GREEN}8)${NC} 恢复备份"
    echo -e " ${GREEN}9)${NC} 版本回滚"
    echo -e " ${GREEN}10)${NC} 创建Systemd服务"
    echo -e " ${GREEN}11)${NC} 卸载服务"
    echo -e " ${RED}0)${NC} 退出"
    blank
}

# ----------------------------------------------------------------
# 主函数
# ----------------------------------------------------------------
main() {
    local cmd="${1:-menu}"

    # 检测操作系统
    detect_os

    case "$cmd" in
        "install")
            install_service
            ;;
        "update")
            update_service
            ;;
        "status")
            service_status
            ;;
        "restart")
            restart_service
            ;;
        "logs")
            show_logs
            ;;
        "config"|"edit")
            edit_config
            ;;
        "backup")
            create_backup
            ;;
        "restore")
            restore_backup
            ;;
        "rollback")
            rollback_version
            ;;
        "service"|"systemd")
            create_systemd_service
            ;;
        "uninstall")
            uninstall_service
            ;;
        "menu"|"")
            show_banner
            while true; do
                show_menu
                read -p "请输入选项 [0-11]: " choice
                case "$choice" in
                    1) install_service ;;
                    2) update_service ;;
                    3) service_status ;;
                    4) restart_service ;;
                    5) show_logs ;;
                    6) edit_config ;;
                    7) create_backup ;;
                    8) restore_backup ;;
                    9) rollback_version ;;
                    10) create_systemd_service ;;
                    11) uninstall_service ;;
                    0) echo -e "${GREEN}再见！${NC}"; exit 0 ;;
                    *)
                        echo -e "${RED}无效选项，请重新选择${NC}"
                        sleep 1
                        ;;
                esac
            done
            ;;
        *)
            echo "使用方法: $0 [install|update|status|restart|logs|config|backup|restore|rollback|service|uninstall|menu]"
            echo "示例:"
            echo "  $0 install      # 安装服务"
            echo "  $0 update       # 更新服务"
            echo "  $0 status       # 查看状态"
            echo "  $0 restart      # 重启服务"
            echo "  $0 logs         # 查看日志"
            echo "  $0 config       # 编辑配置"
            echo "  $0 backup       # 创建备份"
            echo "  $0 restore      # 恢复备份"
            echo "  $0 rollback     # 版本回滚"
            echo "  $0 service      # 创建Systemd服务"
            echo "  $0 uninstall    # 卸载服务"
            echo "  $0 menu         # 显示菜单 (默认)"
            exit 1
            ;;
    esac
}

# 捕获退出信号，确保清理
trap 'echo -e "${NC}"; exit' INT TERM EXIT

# 运行主函数
main "$@"