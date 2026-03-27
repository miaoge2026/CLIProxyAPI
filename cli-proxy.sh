#!/bin/bash
# ================================================================
# CLIProxyAPI 管理脚本 v1.0
# 功能：一键安装 / 一键更新 / 状态查看 / 服务管理
# 用法：bash cli-proxy.sh [install|update|status|restart|logs|uninstall]
# 不带参数时显示交互菜单
# 系统：Ubuntu / Debian
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
GITHUB_API="https://api.github.com/repos/router-for-me/CLIProxyAPI/releases/latest"
GITHUB_REPO="https://github.com/router-for-me/CLIProxyAPI.git"
CONTAINER_NAME="cli-proxy-api"
SERVICE_PORT="8317"
SCRIPT_PATH="$(realpath "$0")"

# ----------------------------------------------------------------
# 工具函数
# ----------------------------------------------------------------
info() { echo -e "${CYAN} [INFO]${NC} $1"; }
success() { echo -e "${GREEN} [ ✓ ]${NC} $1"; }
warn() { echo -e "${YELLOW} [ ! ]${NC} $1"; }
error() { echo -e "${RED} [ ✗ ]${NC} $1"; exit 1; }
step() { echo -e "\n${BOLD}${BLUE} ▶ $1${NC}"; echo -e " ${DIM}$(printf '%.0s─' {1..45})${NC}"; }
blank() { echo ""; }

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
 ║  API Management • 管理脚本 v1.0                      ║
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
# 检查并安装 Docker
# ----------------------------------------------------------------
ensure_docker() {
 if command -v docker &>/dev/null && docker compose version &>/dev/null; then
 success "Docker 已就绪：$(docker --version | cut -d' ' -f3 | tr -d ',')"
 return
 fi

 warn "未检测到 Docker，开始自动安装..."
 apt-get update -qq
 apt-get install -y -qq ca-certificates curl gnupg lsb-release git

 install -m 0755 -d /etc/apt/keyrings
 curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
 | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
 chmod a+r /etc/apt/keyrings/docker.gpg

 echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
 > /etc/apt/sources.list.d/docker.list

 apt-get update -qq
 apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin

 systemctl enable docker &>/dev/null
 systemctl start docker
 success "Docker 安装完成"
}

# ----------------------------------------------------------------
# 检查并安装 Git / curl
# ----------------------------------------------------------------
ensure_deps() {
 local missing=()
 command -v git &>/dev/null || missing+=("git")
 command -v curl &>/dev/null || missing+=("curl")
 if [[ ${#missing[@]} -gt 0 ]]; then
 info "安装依赖：${missing[*]}"
 apt-get install -y -qq "${missing[@]}"
 fi
}

# ----------------------------------------------------------------
# 准备项目目录
# ----------------------------------------------------------------
prepare_project() {
 if [[ -d "$INSTALL_DIR/.git" ]]; then
 info "项目目录已存在，同步最新代码..."
 cd "$INSTALL_DIR"
 git pull origin main -q 2>/dev/null || git pull origin master -q 2>/dev/null || true
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

auth:
 # 客户端连接本代理时使用的密钥（自定义）
 keys: []
 # 示例：
 # keys:
 # - "my-secret-key-123"

# 在此添加你的 AI 服务 API Key
providers: []
YAML
 warn "已创建基础 config.yaml"
 fi

 echo ""
 warn "⚠ 请编辑配置文件填写你的 API Key："
 warn " ${BOLD}nano $INSTALL_DIR/config.yaml${NC}"
}

# ----------------------------------------------------------------
# 启动服务
# ----------------------------------------------------------------
start_service() {
 local version="$1"
 cd "$INSTALL_DIR"
 info "使用镜像版本：$version"
 CLI_PROXY_IMAGE="eceasy/cli-proxy-api:${version}" \
 docker compose up -d --no-build --pull always
 success "容器启动完成"
}

# ----------------------------------------------------------------
# 验证服务健康
# ----------------------------------------------------------------
verify_service() {
 info "等待服务就绪..."
 local retries=8
 for ((i=1; i<=retries; i++)); do
 sleep 2
 local code
 code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${SERVICE_PORT}/health" 2>/dev/null)
 if [[ "$code" == "200" ]]; then
 success "服务健康检查通过"
 return
 fi
 done
 warn "服务启动可能较慢，请稍后手动检查状态"
}

# ----------------------------------------------------------------
# 安装服务
# ----------------------------------------------------------------
install_service() {
 show_banner
 step "开始安装 CLIProxyAPI"

 ensure_docker
 ensure_deps
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
 info "访问地址：http://localhost:${SERVICE_PORT}"
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

 info "开始更新..."
 cd "$INSTALL_DIR"
 docker compose pull
 docker compose up -d --no-build
 success "更新完成"

 verify_service
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
 netstat -tlnp | grep ":${SERVICE_PORT}" || echo "端口未监听"
 else
 warn "服务未运行"
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
 docker logs -f "$CONTAINER_NAME"
 else
 warn "服务未运行，请先安装"
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

 read -p "是否删除项目目录 (${INSTALL_DIR})？[y/N]: " confirm
 if [[ "$confirm" == [yY] ]]; then
 rm -rf "$INSTALL_DIR"
 success "项目目录已删除"
 else
 info "保留项目目录：${INSTALL_DIR}"
 fi
}

# ----------------------------------------------------------------
# 显示菜单
# ----------------------------------------------------------------
show_menu() {
 blank
 echo -e "${BOLD}请选择操作：${NC}"
 echo -e " ${GREEN}1)${NC} 安装服务"
 echo -e " ${GREEN}2)${NC} 更新服务"
 echo -e " ${GREEN}3)${NC} 查看状态"
 echo -e " ${GREEN}4)${NC} 重启服务"
 echo -e " ${GREEN}5)${NC} 查看日志"
 echo -e " ${GREEN}6)${NC} 卸载服务"
 echo -e " ${RED}0)${NC} 退出"
 blank
}

# ----------------------------------------------------------------
# 主函数
# ----------------------------------------------------------------
main() {
 local cmd="${1:-menu}"

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
 "uninstall")
 uninstall_service
 ;;
 "menu")
 show_banner
 while true; do
 show_menu
 read -p "请输入选项 [0-6]: " choice
 case "$choice" in
 1) install_service ;;
 2) update_service ;;
 3) service_status ;;
 4) restart_service ;;
 5) show_logs ;;
 6) uninstall_service ;;
 0) echo -e "${GREEN}再见！${NC}"; exit 0 ;;
 *)
 echo -e "${RED}无效选项，请重新选择${NC}"
 sleep 1
 ;;
 esac
 done
 ;;
 *)
 echo "使用方法: $0 [install|update|status|restart|logs|uninstall|menu]"
 exit 1
 ;;
 esac
}

# 运行主函数
main "$@"