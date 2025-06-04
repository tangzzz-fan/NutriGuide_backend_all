#!/bin/bash

# 🛑 NutriGuide Backend Services Stop Script
# 支持多环境的微服务停止管理

set -e

# ==================== 配置变量 ==================== #

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")"

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
    echo -e "${RED}"
    echo "███████╗████████╗ ██████╗ ██████╗ "
    echo "██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗"
    echo "███████╗   ██║   ██║   ██║██████╔╝"
    echo "╚════██║   ██║   ██║   ██║██╔═══╝ "
    echo "███████║   ██║   ╚██████╔╝██║     "
    echo "╚══════╝   ╚═╝    ╚═════╝ ╚═╝     "
    echo -e "${NC}"
    echo -e "${CYAN}🛑 NutriGuide Backend Services Stop${NC}"
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
  dev       停止开发环境 (默认)
  qa        停止QA测试环境
  prod      停止生产环境
  all       停止所有环境

选项:
  --volumes     同时删除数据卷 (谨慎使用)
  --images      同时删除相关镜像
  --force       强制停止，不等待优雅关闭
  --clean       停止后进行系统清理
  --help        显示此帮助信息

示例:
  $0 dev                     # 停止开发环境
  $0 prod --force            # 强制停止生产环境
  $0 all --clean             # 停止所有环境并清理
  $0 qa --volumes --images   # 停止QA环境并删除数据和镜像

EOF
}

# ==================== 主要函数 ==================== #

check_dependencies() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装"
        exit 1
    fi
}

stop_environment() {
    local env=$1
    local compose_file="docker-compose.$env.yml"
    
    if [ ! -f "$compose_file" ]; then
        log_warn "未找到 $compose_file，跳过 $env 环境"
        return
    fi
    
    log_step "停止 $env 环境服务..."
    
    if [ "$FORCE_STOP" = true ]; then
        docker-compose -f "$compose_file" kill
        docker-compose -f "$compose_file" down --remove-orphans
    else
        docker-compose -f "$compose_file" down --remove-orphans
    fi
    
    # 删除数据卷
    if [ "$REMOVE_VOLUMES" = true ]; then
        log_warn "删除 $env 环境数据卷..."
        docker-compose -f "$compose_file" down -v
    fi
    
    log_info "✓ $env 环境已停止"
}

stop_all_environments() {
    log_step "停止所有环境..."
    
    for env in dev qa prod; do
        stop_environment "$env"
    done
    
    log_info "✓ 所有环境已停止"
}

remove_images() {
    log_step "删除相关 Docker 镜像..."
    
    # 删除 NutriGuide 相关镜像
    docker images | grep -E "(nutriguide|nutriguide)" | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true
    
    # 删除 dangling 镜像
    docker image prune -f
    
    log_info "✓ 镜像清理完成"
}

clean_system() {
    log_step "清理系统资源..."
    
    # 清理未使用的网络
    docker network prune -f
    
    # 清理未使用的镜像
    docker image prune -f
    
    # 清理构建缓存
    docker builder prune -f
    
    log_info "✓ 系统清理完成"
}

show_remaining_resources() {
    log_step "检查剩余资源..."
    
    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}  剩余容器${NC}"
    echo -e "${CYAN}======================================${NC}"
    
    local containers=$(docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -E "(nutriguide|nutriguide)" || echo "无相关容器")
    echo "$containers"
    
    echo ""
    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}  剩余镜像${NC}"
    echo -e "${CYAN}======================================${NC}"
    
    local images=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(nutriguide|nutriguide)" || echo "无相关镜像")
    echo "$images"
    
    echo ""
    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}  剩余数据卷${NC}"
    echo -e "${CYAN}======================================${NC}"
    
    local volumes=$(docker volume ls --format "table {{.Name}}" | grep -E "(nutriguide|nutriguide)" || echo "无相关数据卷")
    echo "$volumes"
    
    echo ""
}

# ==================== 参数解析 ==================== #

ENVIRONMENT="dev"
REMOVE_VOLUMES=false
REMOVE_IMAGES=false
FORCE_STOP=false
CLEAN_SYSTEM=false

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        dev|qa|prod|all)
            ENVIRONMENT="$1"
            shift
            ;;
        --volumes)
            REMOVE_VOLUMES=true
            shift
            ;;
        --images)
            REMOVE_IMAGES=true
            shift
            ;;
        --force)
            FORCE_STOP=true
            shift
            ;;
        --clean)
            CLEAN_SYSTEM=true
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
    
    # 切换到后端目录
    cd "$BACKEND_DIR"
    
    # 检查依赖
    check_dependencies
    
    # 警告信息
    if [ "$REMOVE_VOLUMES" = true ]; then
        echo -e "${RED}⚠️  警告: 即将删除数据卷，这将导致数据丢失！${NC}"
        read -p "确认继续？(y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            log_info "操作已取消"
            exit 0
        fi
    fi
    
    # 停止服务
    if [ "$ENVIRONMENT" = "all" ]; then
        stop_all_environments
    else
        stop_environment "$ENVIRONMENT"
    fi
    
    # 删除镜像
    if [ "$REMOVE_IMAGES" = true ]; then
        remove_images
    fi
    
    # 系统清理
    if [ "$CLEAN_SYSTEM" = true ]; then
        clean_system
    fi
    
    # 显示剩余资源
    show_remaining_resources
    
    log_info "🎉 停止操作完成！"
    
    # 提示信息
    echo ""
    echo -e "${YELLOW}💡 小贴士:${NC}"
    echo "  - 重新启动: ./scripts/start.sh $ENVIRONMENT"
    echo "  - 查看日志: docker-compose -f docker-compose.$ENVIRONMENT.yml logs"
    echo "  - 完全清理: $0 all --volumes --images --clean"
}

# 执行主函数
main "$@" 