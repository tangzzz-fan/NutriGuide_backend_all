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
  --pdf-parser    启用 PDF Parser 服务
  --no-pdf-parser 禁用 PDF Parser 服务
  --help    显示此帮助信息

示例:
  $0 dev                    # 启动开发环境 (默认不启动PDF Parser)
  $0 dev --pdf-parser       # 启动开发环境并启用PDF Parser
  $0 qa --build --pdf-parser # 重新构建并启动QA环境(含PDF Parser)
  $0 prod --pull --logs     # 拉取镜像启动生产环境并显示日志
  $0 --clean                # 清理系统资源

PDF Parser 相关:
  PDF Parser 是可选的微服务组件，用于处理PDF文档解析
  默认情况下不启动，可通过 --pdf-parser 选项启用

EOF
}

# ==================== PDF Parser 相关函数 ==================== #

check_pdf_parser_setup() {
    log_step "检查 PDF Parser 服务设置..."
    
    if [ ! -d "$BACKEND_DIR/pdf_parser" ]; then
        log_error "PDF Parser 目录不存在: $BACKEND_DIR/pdf_parser"
        return 1
    fi
    
    if [ ! -f "$BACKEND_DIR/pdf_parser/requirements.txt" ]; then
        log_error "PDF Parser 未完成设置，缺少 requirements.txt"
        return 1
    fi
    
    log_info "✓ PDF Parser 设置检查通过"
    return 0
}

setup_pdf_parser_env() {
    log_step "设置 PDF Parser 环境..."
    
    cd "$BACKEND_DIR/pdf_parser"
    
    # 检查虚拟环境
    if [ ! -d "venv" ]; then
        log_info "创建 PDF Parser 虚拟环境..."
        python3 -m venv venv
    fi
    
    # 激活虚拟环境并安装依赖
    log_info "安装 PDF Parser 依赖..."
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    deactivate
    
    # 创建必要的目录
    mkdir -p logs uploads temp static templates
    
    # 复制环境配置文件
    if [ ! -f ".env" ]; then
        log_info "创建 PDF Parser 环境配置..."
        cat > .env << EOF
# PDF Parser 环境配置
ENVIRONMENT=$ENVIRONMENT
DEBUG=$([ "$ENVIRONMENT" = "dev" ] && echo "true" || echo "false")
HOST=0.0.0.0
PORT=7800

# 数据库配置 - 与主服务共享
MONGODB_URL=mongodb://localhost:27017
MONGODB_DATABASE=nutriguide_pdf

# Redis 配置 - 与主服务共享
REDIS_URL=redis://localhost:6379/0
CELERY_BROKER_URL=redis://localhost:6379/1
CELERY_RESULT_BACKEND=redis://localhost:6379/2

# 文件处理配置
MAX_FILE_SIZE=52428800
MAX_FILE_SIZE_SYNC=5242880
ALLOWED_EXTENSIONS=pdf

# 安全配置
SECRET_KEY=$(openssl rand -hex 32)
CORS_ORIGINS=*

# 功能开关
OCR_ENABLED=true
RATE_LIMIT_ENABLED=true
METRICS_ENABLED=true
EOF
    fi
    
    log_info "✓ PDF Parser 环境设置完成"
}

start_pdf_parser() {
    if [ "$ENABLE_PDF_PARSER" = false ]; then
        return 0
    fi
    
    log_step "启动 PDF Parser 服务..."
    
    cd "$BACKEND_DIR/pdf_parser"
    
    # 检查设置
    if ! check_pdf_parser_setup; then
        setup_pdf_parser_env
    fi
    
    # 激活虚拟环境
    source venv/bin/activate
    
    # 获取端口配置
    case $ENVIRONMENT in
        "dev")
            PDF_PORT=7800
            ;;
        "qa")
            PDF_PORT=7801
            ;;
        "prod")
            PDF_PORT=7802
            ;;
    esac
    
    # 检查端口
    if lsof -Pi :$PDF_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_warn "PDF Parser 端口 $PDF_PORT 已被占用，停止现有服务..."
        kill -9 $(lsof -t -i:$PDF_PORT) 2>/dev/null || true
        sleep 2
    fi
    
    # 启动主应用
    log_info "启动 PDF Parser API 服务 (端口: $PDF_PORT)..."
    if [ "$DETACH" = true ]; then
        nohup uvicorn main:app --host 0.0.0.0 --port $PDF_PORT --reload > logs/api.log 2>&1 &
        API_PID=$!
        echo $API_PID > logs/api.pid
        log_info "✓ PDF Parser API 已启动 (PID: $API_PID)"
    else
        uvicorn main:app --host 0.0.0.0 --port $PDF_PORT --reload &
        API_PID=$!
        echo $API_PID > logs/api.pid
    fi
    
    # 启动 Celery Worker
    log_info "启动 Celery Worker..."
    if [ "$DETACH" = true ]; then
        nohup celery -A celery_app worker --loglevel=info > logs/worker.log 2>&1 &
        WORKER_PID=$!
        echo $WORKER_PID > logs/worker.pid
        log_info "✓ Celery Worker 已启动 (PID: $WORKER_PID)"
    else
        celery -A celery_app worker --loglevel=info &
        WORKER_PID=$!
        echo $WORKER_PID > logs/worker.pid
    fi
    
    # 启动 Celery Beat (定时任务)
    if [ "$ENVIRONMENT" = "prod" ]; then
        log_info "启动 Celery Beat..."
        if [ "$DETACH" = true ]; then
            nohup celery -A celery_app beat --loglevel=info > logs/beat.log 2>&1 &
            BEAT_PID=$!
            echo $BEAT_PID > logs/beat.pid
            log_info "✓ Celery Beat 已启动 (PID: $BEAT_PID)"
        else
            celery -A celery_app beat --loglevel=info &
            BEAT_PID=$!
            echo $BEAT_PID > logs/beat.pid
        fi
    fi
    
    deactivate
    cd "$BACKEND_DIR"
    
    # 等待服务启动
    sleep 3
    
    # 健康检查
    if curl -s "http://localhost:$PDF_PORT/health" > /dev/null; then
        log_info "✓ PDF Parser 服务健康检查通过"
    else
        log_warn "PDF Parser 服务可能未正常启动，请检查日志"
    fi
}

stop_pdf_parser() {
    log_step "停止 PDF Parser 服务..."
    
    cd "$BACKEND_DIR/pdf_parser"
    
    # 停止各个进程
    if [ -f "logs/api.pid" ]; then
        API_PID=$(cat logs/api.pid)
        if ps -p $API_PID > /dev/null; then
            kill $API_PID
            log_info "✓ PDF Parser API 已停止"
        fi
        rm -f logs/api.pid
    fi
    
    if [ -f "logs/worker.pid" ]; then
        WORKER_PID=$(cat logs/worker.pid)
        if ps -p $WORKER_PID > /dev/null; then
            kill $WORKER_PID
            log_info "✓ Celery Worker 已停止"
        fi
        rm -f logs/worker.pid
    fi
    
    if [ -f "logs/beat.pid" ]; then
        BEAT_PID=$(cat logs/beat.pid)
        if ps -p $BEAT_PID > /dev/null; then
            kill $BEAT_PID
            log_info "✓ Celery Beat 已停止"
        fi
        rm -f logs/beat.pid
    fi
    
    cd "$BACKEND_DIR"
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
    
    # PDF Parser 相关依赖检查
    if [ "$ENABLE_PDF_PARSER" = true ]; then
        if ! command -v python3 &> /dev/null; then
            log_error "Python3 未安装，PDF Parser 需要 Python3"
            exit 1
        fi
        
        if ! command -v pip &> /dev/null && ! command -v pip3 &> /dev/null; then
            log_error "pip 未安装，PDF Parser 需要 pip"
            exit 1
        fi
    fi
    
    log_info "✓ 系统依赖检查通过"
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
    
    # 启动主要的 Docker 服务
    if [ "$DETACH" = true ]; then
        docker-compose -f "docker-compose.$ENVIRONMENT.yml" up -d
    else
        docker-compose -f "docker-compose.$ENVIRONMENT.yml" up &
    fi
    
    log_info "✓ 主要服务启动完成"
    
    # 启动 PDF Parser (如果启用)
    if [ "$ENABLE_PDF_PARSER" = true ]; then
        sleep 5  # 等待基础服务启动
        start_pdf_parser
    fi
}

check_ports() {
    log_step "检查端口占用..."
    
    case $ENVIRONMENT in
        "dev")
            PORTS=("3000" "27017" "6379" "8081" "8082")
            if [ "$ENABLE_PDF_PARSER" = true ]; then
                PORTS+=("7800")
            fi
            ;;
        "qa")
            PORTS=("3001" "27018" "6380" "8083")
            if [ "$ENABLE_PDF_PARSER" = true ]; then
                PORTS+=("7801")
            fi
            ;;
        "prod")
            PORTS=("3002" "27019" "6381" "5555")
            if [ "$ENABLE_PDF_PARSER" = true ]; then
                PORTS+=("7802")
            fi
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
    
    # PDF Parser 状态
    if [ "$ENABLE_PDF_PARSER" = true ]; then
        echo ""
        echo -e "${CYAN}PDF Parser 服务状态:${NC}"
        
        case $ENVIRONMENT in
            "dev") PDF_PORT=7800 ;;
            "qa") PDF_PORT=7801 ;;
            "prod") PDF_PORT=7802 ;;
        esac
        
        if curl -s "http://localhost:$PDF_PORT/health" > /dev/null; then
            echo -e "${GREEN}✓ PDF Parser API: 运行中${NC}"
        else
            echo -e "${RED}✗ PDF Parser API: 未运行${NC}"
        fi
        
        if [ -f "$BACKEND_DIR/pdf_parser/logs/worker.pid" ]; then
            WORKER_PID=$(cat "$BACKEND_DIR/pdf_parser/logs/worker.pid")
            if ps -p $WORKER_PID > /dev/null; then
                echo -e "${GREEN}✓ Celery Worker: 运行中${NC}"
            else
                echo -e "${RED}✗ Celery Worker: 未运行${NC}"
            fi
        fi
    fi
    
    echo ""
    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}  访问地址${NC}"
    echo -e "${CYAN}======================================${NC}"
    
    case $ENVIRONMENT in
        "dev")
            echo -e "${GREEN}🌐 Backend API:${NC}      http://localhost:3000"
            if [ "$ENABLE_PDF_PARSER" = true ]; then
                echo -e "${GREEN}📄 PDF Parser:${NC}       http://localhost:7800"
                echo -e "${GREEN}📚 PDF Parser 文档:${NC}  http://localhost:7800/docs"
                echo -e "${GREEN}⚡ PDF Parser 管理:${NC}  http://localhost:7800/admin/metrics"
            fi
            echo -e "${GREEN}🗄️  MongoDB Admin:${NC}    http://localhost:8081"
            echo -e "${GREEN}🔴 Redis Commander:${NC}   http://localhost:8082"
            echo -e "${GREEN}📚 API 文档:${NC}          http://localhost:3000/api/docs"
            ;;
        "qa")
            echo -e "${GREEN}🌐 Backend API:${NC}      http://localhost:3001"
            if [ "$ENABLE_PDF_PARSER" = true ]; then
                echo -e "${GREEN}📄 PDF Parser:${NC}       http://localhost:7801"
                echo -e "${GREEN}📚 PDF Parser 文档:${NC}  http://localhost:7801/docs"
            fi
            echo -e "${GREEN}🗄️  MongoDB Admin:${NC}    http://localhost:8083"
            echo -e "${GREEN}📚 API 文档:${NC}          http://localhost:3001/api/docs"
            ;;
        "prod")
            echo -e "${GREEN}🌐 Backend API:${NC}      http://localhost:3002"
            if [ "$ENABLE_PDF_PARSER" = true ]; then
                echo -e "${GREEN}📄 PDF Parser:${NC}       http://localhost:7802"
                echo -e "${GREEN}⚡ PDF Parser 管理:${NC}  http://localhost:7802/admin/metrics"
            fi
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
    
    # 停止 PDF Parser 服务
    if [ -d "$BACKEND_DIR/pdf_parser" ]; then
        log_info "清理 PDF Parser 服务..."
        cd "$BACKEND_DIR/pdf_parser"
        
        # 停止所有 PDF Parser 进程
        pkill -f "uvicorn main:app" 2>/dev/null || true
        pkill -f "celery.*worker" 2>/dev/null || true
        pkill -f "celery.*beat" 2>/dev/null || true
        
        # 清理PID文件
        rm -f logs/*.pid 2>/dev/null || true
        
        cd "$BACKEND_DIR"
    fi
    
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
ENABLE_PDF_PARSER=false  # 默认不启用 PDF Parser

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
        --pdf-parser)
            ENABLE_PDF_PARSER=true
            shift
            ;;
        --no-pdf-parser)
            ENABLE_PDF_PARSER=false
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
    
    # 如果启用了 PDF Parser，提供管理提示
    if [ "$ENABLE_PDF_PARSER" = true ]; then
        echo ""
        echo -e "${CYAN}📋 PDF Parser 管理命令:${NC}"
        echo -e "${GREEN}  停止服务:${NC} ./stop.sh --only-pdf-parser"
        echo -e "${GREEN}  重启服务:${NC} cd pdf_parser && ./stop.sh && ./start.sh --env $ENVIRONMENT"
        echo -e "${GREEN}  查看日志:${NC} cd pdf_parser && tail -f logs/api.log"
        echo -e "${GREEN}  服务状态:${NC} curl http://localhost:$(case $ENVIRONMENT in dev) echo 7800;; qa) echo 7801;; prod) echo 7802;; esac)/health"
    fi
}

# 执行主函数
main "$@" 