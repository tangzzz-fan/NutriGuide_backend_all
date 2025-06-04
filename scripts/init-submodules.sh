#!/bin/bash

# 🔧 NutriGuide Backend Git 子模块初始化脚本
# 用于初始化和管理后端微服务子模块

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}"
    echo "   _____ _ _     ____        _                        _       _           "
    echo "  / ____(_) |   / __ \      | |                      | |     | |          "
    echo " | |  __ _| |_ | |  | |_   _| |__  _ __ ___   ___   __| |_   _| | ___  ___ "
    echo " | | |_ | | __|| |  | | | | | '_ \| '_ \` _ \ / _ \ / _\` | | | | |/ _ \/ __|"
    echo " | |__| | | |_ | |__| | |_| | |_) | | | | | | (_) | (_| | |_| | |  __/\__ |"
    echo "  \_____|_|\__| \____/ \__,_|_.__/|_| |_| |_|\___/ \__,_|\__,_|_|\___||___/"
    echo -e "${NC}"
    echo -e "${CYAN}🔧 NutriGuide Backend Git 子模块管理${NC}"
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
用法: $0 [选项]

选项:
  --init        初始化所有子模块
  --update      更新所有子模块到最新版本
  --status      显示子模块状态
  --clean       清理子模块并重新初始化
  --help        显示此帮助信息

示例:
  $0 --init         # 初始化子模块
  $0 --update       # 更新子模块
  $0 --status       # 查看状态
  $0 --clean        # 清理并重新初始化

EOF
}

check_git() {
    if ! command -v git &> /dev/null; then
        log_error "Git 未安装，请先安装 Git"
        exit 1
    fi
    
    if [ ! -d ".git" ]; then
        log_error "当前目录不是 Git 仓库"
        exit 1
    fi
    
    log_info "✓ Git 环境检查通过"
}

init_submodules() {
    log_step "初始化 Git 子模块..."
    
    # 初始化子模块
    git submodule update --init --recursive
    
    log_info "✓ 子模块初始化完成"
    
    # 检查子模块状态
    show_submodule_status
}

update_submodules() {
    log_step "更新 Git 子模块..."
    
    # 更新所有子模块到最新版本
    git submodule update --remote --recursive
    
    log_info "✓ 子模块更新完成"
    
    # 检查子模块状态
    show_submodule_status
}

show_submodule_status() {
    log_step "Git 子模块状态："
    
    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}  子模块状态概览${NC}"
    echo -e "${CYAN}======================================${NC}"
    
    if [ -f ".gitmodules" ]; then
        git submodule status --recursive
        
        echo ""
        echo -e "${CYAN}======================================${NC}"
        echo -e "${CYAN}  子模块详细信息${NC}"
        echo -e "${CYAN}======================================${NC}"
        
        # 显示每个子模块的详细信息
        git submodule foreach --recursive 'echo "📁 $(basename $(pwd)): $(git branch --show-current) ($(git describe --always))"'
    else
        log_warn "未找到 .gitmodules 文件"
    fi
    
    echo ""
}

clean_submodules() {
    log_step "清理 Git 子模块..."
    
    # 警告用户
    echo -e "${RED}⚠️  警告: 这将删除所有子模块目录并重新初始化！${NC}"
    read -p "确认继续？(y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log_info "操作已取消"
        exit 0
    fi
    
    # 反初始化子模块
    git submodule deinit --all -f
    
    # 删除子模块目录
    rm -rf backend_node pdf_parser
    
    # 清理 .git/modules
    rm -rf .git/modules/backend_node .git/modules/pdf_parser
    
    # 重新初始化
    init_submodules
    
    log_info "✓ 子模块清理完成"
}

# 主函数
main() {
    print_header
    
    # 检查参数
    if [ $# -eq 0 ]; then
        show_usage
        exit 1
    fi
    
    # 检查 Git 环境
    check_git
    
    # 处理参数
    case $1 in
        --init)
            init_submodules
            ;;
        --update)
            update_submodules
            ;;
        --status)
            show_submodule_status
            ;;
        --clean)
            clean_submodules
            ;;
        --help)
            show_usage
            ;;
        *)
            log_error "未知选项: $1"
            show_usage
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@" 