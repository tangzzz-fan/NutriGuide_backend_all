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
  --pdf-parser  同时停止 PDF Parser 服务
  --only-pdf-parser 仅停止 PDF Parser 服务
  --help        显示此帮助信息

示例:
  $0 dev                     # 停止开发环境
  $0 dev --pdf-parser        # 停止开发环境并停止PDF Parser
  $0 --only-pdf-parser       # 仅停止PDF Parser服务
  $0 prod --force            # 强制停止生产环境
  $0 all --clean             # 停止所有环境并清理
  $0 qa --volumes --images   # 停止QA环境并删除数据和镜像

EOF
}

# ==================== PDF Parser 相关函数 ==================== #

stop_pdf_parser() {
    log_step "停止 PDF Parser 服务..."
    
    local pdf_parser_dir="$BACKEND_DIR/pdf_parser"
    
    if [ ! -d "$pdf_parser_dir" ]; then
        log_warn "PDF Parser 目录不存在: $pdf_parser_dir"
        return
    fi
    
    cd "$pdf_parser_dir"
    
    # 检查是否有停止脚本
    if [ -f "stop.sh" ]; then
        log_info "使用 PDF Parser 停止脚本..."
        chmod +x stop.sh
        if [ "$FORCE_STOP" = true ]; then
            ./stop.sh --force
        else
            ./stop.sh
        fi
    else
        # 手动停止 PDF Parser 进程
        log_info "手动停止 PDF Parser 进程..."
        
        # 停止API服务
        if [ -f "logs/api.pid" ]; then
            local api_pid=$(cat logs/api.pid)
            if ps -p $api_pid > /dev/null 2>&1; then
                log_info "停止 PDF Parser API (PID: $api_pid)..."
                if [ "$FORCE_STOP" = true ]; then
                    kill -9 $api_pid 2>/dev/null || true
                else
                    kill $api_pid 2>/dev/null || true
                fi
            fi
            rm -f logs/api.pid
        fi
        
        # 停止Celery Worker
        if [ -f "logs/worker.pid" ]; then
            local worker_pid=$(cat logs/worker.pid)
            if ps -p $worker_pid > /dev/null 2>&1; then
                log_info "停止 Celery Worker (PID: $worker_pid)..."
                if [ "$FORCE_STOP" = true ]; then
                    kill -9 $worker_pid 2>/dev/null || true
                else
                    kill $worker_pid 2>/dev/null || true
                fi
            fi
            rm -f logs/worker.pid
        fi
        
        # 停止Celery Beat
        if [ -f "logs/beat.pid" ]; then
            local beat_pid=$(cat logs/beat.pid)
            if ps -p $beat_pid > /dev/null 2>&1; then
                log_info "停止 Celery Beat (PID: $beat_pid)..."
                if [ "$FORCE_STOP" = true ]; then
                    kill -9 $beat_pid 2>/dev/null || true
                else
                    kill $beat_pid 2>/dev/null || true
                fi
            fi
            rm -f logs/beat.pid
        fi
        
        # 检查端口并停止相关进程
        local ports=("7800" "7801" "7802")
        for port in "${ports[@]}"; do
            if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
                local pids=$(lsof -t -i:$port)
                for pid in $pids; do
                    local cmd=$(ps -p $pid -o comm= 2>/dev/null || echo "")
                    if [[ "$cmd" == "python"* ]] || [[ "$cmd" == "uvicorn"* ]] || [[ "$cmd" == "celery"* ]]; then
                        log_info "停止端口 $port 上的进程 (PID: $pid)..."
                        if [ "$FORCE_STOP" = true ]; then
                            kill -9 $pid 2>/dev/null || true
                        else
                            kill $pid 2>/dev/null || true
                        fi
                    fi
                done
            fi
        done
    fi
    
    # 等待进程停止
    sleep 2
    
    # 验证停止状态
    local pdf_stopped=true
    local ports=("7800" "7801" "7802")
    for port in "${ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            local pids=$(lsof -t -i:$port)
            for pid in $pids; do
                local cmd=$(ps -p $pid -o comm= 2>/dev/null || echo "")
                if [[ "$cmd" == "python"* ]] || [[ "$cmd" == "uvicorn"* ]] || [[ "$cmd" == "celery"* ]]; then
                    pdf_stopped=false
                    break 2
                fi
            done
        fi
    done
    
    if [ "$pdf_stopped" = true ]; then
        log_info "✓ PDF Parser 服务已停止"
    else
        log_warn "PDF Parser 部分服务可能仍在运行"
    fi
    
    cd "$BACKEND_DIR"
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
    
    # PDF Parser 服务状态
    echo ""
    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}  PDF Parser 服务状态${NC}"
    echo -e "${CYAN}======================================${NC}"
    
    local pdf_running=false
    local ports=("7800" "7801" "7802")
    for port in "${ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            local pids=$(lsof -t -i:$port)
            for pid in $pids; do
                local cmd=$(ps -p $pid -o comm= 2>/dev/null || echo "")
                if [[ "$cmd" == "python"* ]] || [[ "$cmd" == "uvicorn"* ]] || [[ "$cmd" == "celery"* ]]; then
                    echo -e "${RED}✗ 端口 $port: PDF Parser 服务仍在运行 (PID: $pid)${NC}"
                    pdf_running=true
                fi
            done
        fi
    done
    
    if [ "$pdf_running" = false ]; then
        echo -e "${GREEN}✓ PDF Parser 服务已完全停止${NC}"
    fi
    
    echo ""
}

# ==================== 参数解析 ==================== #

ENVIRONMENT="dev"
REMOVE_VOLUMES=false
REMOVE_IMAGES=false
FORCE_STOP=false
CLEAN_SYSTEM=false
STOP_PDF_PARSER=false
ONLY_PDF_PARSER=false

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
        --pdf-parser)
            STOP_PDF_PARSER=true
            shift
            ;;
        --only-pdf-parser)
            ONLY_PDF_PARSER=true
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
    
    # 检查依赖 (仅在非 PDF Parser only 模式下)
    if [ "$ONLY_PDF_PARSER" = false ]; then
        check_dependencies
    fi
    
    # 切换到后端目录
    cd "$BACKEND_DIR"
    
    # 仅停止 PDF Parser
    if [ "$ONLY_PDF_PARSER" = true ]; then
        stop_pdf_parser
        show_remaining_resources
        return
    fi
    
    # 停止主要服务
    case $ENVIRONMENT in
        "all")
            stop_all_environments
            ;;
        *)
            stop_environment "$ENVIRONMENT"
            ;;
    esac
    
    # 停止 PDF Parser (如果指定)
    if [ "$STOP_PDF_PARSER" = true ]; then
        stop_pdf_parser
    fi
    
    # 删除镜像
    if [ "$REMOVE_IMAGES" = true ]; then
        remove_images
    fi
    
    # 清理系统
    if [ "$CLEAN_SYSTEM" = true ]; then
        clean_system
    fi
    
    # 显示剩余资源
    show_remaining_resources
    
    log_info "停止操作完成"
}

# 执行主函数
main "$@" 