#!/bin/bash

# 🚀 NutriGuide Backend Services Startup Script
# 支持多环境的微服务启动管理

set -e

# ==================== 配置变量 ==================== #

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$BACKEND_DIR")"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ==================== 帮助函数 ==================== #

print_header() {
    echo -e "${PURPLE}"
    echo "██████╗ ██╗   ██╗████████╗██████╗ ██╗ ██████╗ ██╗   ██╗██╗██████╗ ███████╗"
    echo "██╔══██╗██║   ██║╚══██╔══╝██╔══██╗██║██╔════╝ ██║   ██║██║██╔══██╗██╔════╝"
    echo "██████╔╝██║   ██║   ██║   ██████╔╝██║██║  ███╗██║   ██║██║██║  ██║█████╗  "
    echo "██╔══██╗██║   ██║   ██║   ██╔══██╗██║██║   ██║██║   ██║██║██║  ██║██╔══╝  "
    echo "██║  ██║╚██████╔╝   ██║   ██║  ██║██║╚██████╔╝╚██████╔╝██║██████╔╝███████╗"
    echo "╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚═╝ ╚═════╝  ╚═════╝ ╚═╝╚═════╝ ╚══════╝"
    echo -e "${NC}"
    echo -e "${CYAN}🥗 NutriGuide Backend Services Management${NC}"
    echo ""
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

show_usage() {
    cat << EOF
使用方法: $0 [环境] [选项]

环境:
  dev       启动开发环境 (默认)
  qa        启动QA测试环境  
  prod      启动生产环境

选项:
  --pull    启动前先拉取最新镜像
  --build   强制重新构建镜像
  --clean   清理未使用的数据卷和镜像
  --logs    启动后显示服务日志
  --detach  后台运行 (默认)
  --help    显示此帮助信息

示例:
  $0 dev                    # 启动开发环境
  $0 qa --build             # 重新构建并启动QA环境
  $0 prod --pull --logs     # 拉取镜像启动生产环境并显示日志
  $0 --clean                # 清理系统资源

EOF
}

# ==================== 主要函数 ==================== #

check_dependencies() {
    log_step "检查系统依赖..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "无法连接到 Docker daemon，请检查 Docker 服务是否运行"
        exit 1
    fi
    
    log_info "✓ Docker 环境检查通过"
}

check_git_submodules() {
    log_step "检查 Git 子模块状态..."
    
    cd "$BACKEND_DIR"
    
    if [ ! -d "backend_node/.git" ]; then
        log_warn "backend_node 子模块未初始化，正在初始化..."
        git submodule update --init backend_node
    fi
    
    if [ ! -d "pdf_parser/.git" ]; then
        log_warn "pdf_parser 子模块未初始化，正在初始化..."
        git submodule update --init pdf_parser
    fi
    
    log_info "✓ Git 子模块检查完成"
}

pull_images() {
    log_step "拉取最新 Docker 镜像..."
    docker-compose -f "docker-compose.$ENVIRONMENT.yml" pull
    log_info "✓ 镜像拉取完成"
}

build_images() {
    log_step "构建 Docker 镜像..."
    docker-compose -f "docker-compose.$ENVIRONMENT.yml" build --parallel
    log_info "✓ 镜像构建完成"
}

start_services() {
    log_step "启动 $ENVIRONMENT 环境服务..."
    
    # 检查端口占用
    check_ports
    
    # 启动服务
    if [ "$DETACH" = true ]; then
        docker-compose -f "docker-compose.$ENVIRONMENT.yml" up -d
    else
        docker-compose -f "docker-compose.$ENVIRONMENT.yml" up
    fi
    
    log_info "✓ 服务启动完成"
}

check_ports() {
    log_step "检查端口占用..."
    
    case $ENVIRONMENT in
        "dev")
            PORTS=("3000" "8000" "27017" "6379" "8081" "8082")
            ;;
        "qa")
            PORTS=("3001" "8001" "27018" "6380" "8083")
            ;;
        "prod")
            PORTS=("3002" "8002" "27019" "6381" "5555")
            ;;
    esac
    
    for port in "${PORTS[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            log_warn "端口 $port 已被占用"
        fi
    done
}

show_logs() {
    log_step "显示服务日志..."
    docker-compose -f "docker-compose.$ENVIRONMENT.yml" logs -f
}

show_status() {
    log_step "服务状态概览..."
    
    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}  NutriGuide $ENVIRONMENT 环境状态${NC}"
    echo -e "${CYAN}======================================${NC}"
    
    docker-compose -f "docker-compose.$ENVIRONMENT.yml" ps
    
    echo ""
    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}  访问地址${NC}"
    echo -e "${CYAN}======================================${NC}"
    
    case $ENVIRONMENT in
        "dev")
            echo -e "${GREEN}🌐 Backend API:${NC}      http://localhost:3000"
            echo -e "${GREEN}📄 PDF Parser:${NC}       http://localhost:8000"
            echo -e "${GREEN}🗄️  MongoDB Admin:${NC}    http://localhost:8081"
            echo -e "${GREEN}🔴 Redis Commander:${NC}   http://localhost:8082"
            echo -e "${GREEN}📚 API 文档:${NC}          http://localhost:3000/api/docs"
            ;;
        "qa")
            echo -e "${GREEN}🌐 Backend API:${NC}      http://localhost:3001"
            echo -e "${GREEN}📄 PDF Parser:${NC}       http://localhost:8001"
            echo -e "${GREEN}🗄️  MongoDB Admin:${NC}    http://localhost:8083"
            echo -e "${GREEN}📚 API 文档:${NC}          http://localhost:3001/api/docs"
            ;;
        "prod")
            echo -e "${GREEN}🌐 Backend API:${NC}      http://localhost:3002"
            echo -e "${GREEN}📄 PDF Parser:${NC}       http://localhost:8002"
            echo -e "${GREEN}🌸 Celery Monitor:${NC}   http://localhost:5555"
            echo -e "${GREEN}📚 API 文档:${NC}          生产环境中已禁用"
            ;;
    esac
    
    echo ""
}

cleanup_system() {
    log_step "清理系统资源..."
    
    # 停止所有容器
    docker-compose -f docker-compose.dev.yml down 2>/dev/null || true
    docker-compose -f docker-compose.qa.yml down 2>/dev/null || true
    docker-compose -f docker-compose.prod.yml down 2>/dev/null || true
    
    # 清理未使用的镜像
    docker image prune -f
    
    # 清理未使用的网络
    docker network prune -f
    
    # 清理未使用的数据卷 (谨慎操作)
    read -p "是否清理未使用的数据卷？这将删除所有未挂载的数据 (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        docker volume prune -f
        log_info "✓ 数据卷已清理"
    else
        log_info "跳过数据卷清理"
    fi
    
    log_info "✓ 系统清理完成"
}

# ==================== 参数解析 ==================== #

ENVIRONMENT="dev"
PULL_IMAGES=false
BUILD_IMAGES=false
SHOW_LOGS=false
CLEAN_SYSTEM=false
DETACH=true

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        dev|qa|prod)
            ENVIRONMENT="$1"
            shift
            ;;
        --pull)
            PULL_IMAGES=true
            shift
            ;;
        --build)
            BUILD_IMAGES=true
            shift
            ;;
        --logs)
            SHOW_LOGS=true
            DETACH=false
            shift
            ;;
        --clean)
            CLEAN_SYSTEM=true
            shift
            ;;
        --detach)
            DETACH=true
            shift
            ;;
        --help)
            print_header
            show_usage
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            show_usage
            exit 1
            ;;
    esac
done

# ==================== 主执行流程 ==================== #

main() {
    print_header
    
    # 清理系统资源
    if [ "$CLEAN_SYSTEM" = true ]; then
        cleanup_system
        exit 0
    fi
    
    # 切换到后端目录
    cd "$BACKEND_DIR"
    
    # 检查依赖
    check_dependencies
    check_git_submodules
    
    # 拉取镜像
    if [ "$PULL_IMAGES" = true ]; then
        pull_images
    fi
    
    # 构建镜像
    if [ "$BUILD_IMAGES" = true ]; then
        build_images
    fi
    
    # 启动服务
    start_services
    
    # 显示状态
    show_status
    
    # 显示日志
    if [ "$SHOW_LOGS" = true ]; then
        show_logs
    fi
}

# 执行主函数
main "$@" 