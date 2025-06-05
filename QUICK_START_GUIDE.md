# 🚀 PDF Parser 快速启动指南

## 📋 概述

现在 PDF Parser 服务已完全集成到主项目的启动管理系统中，您可以通过简单的命令行选项来控制服务的启用/禁用。

**🔧 端口配置更新**: PDF Parser 现在使用 7800-7802 端口范围，避免与常见服务端口冲突。

## 🎯 主要特性

- ✅ **可选启动**: 默认不启动 PDF Parser，按需启用
- ✅ **环境隔离**: 支持 dev/qa/prod 三个环境
- ✅ **统一管理**: 与主项目服务统一启停管理
- ✅ **自动配置**: 自动设置环境和依赖
- ✅ **健康检查**: 内置服务健康监控
- ✅ **端口优化**: 使用 7800-7802 端口，避免常见冲突

## 🚀 快速开始

### 1. 启动主项目 (不含 PDF Parser)

```bash
# 在 /backend 目录下
./start.sh dev
```

### 2. 启动主项目 + PDF Parser

```bash
# 在 /backend 目录下
./start.sh dev --pdf-parser
```

### 3. 不同环境启动

```bash
# 开发环境 (端口 7800) - 避免与常见开发服务冲突
./start.sh dev --pdf-parser

# 测试环境 (端口 7801) 
./start.sh qa --pdf-parser

# 生产环境 (端口 7802)
./start.sh prod --pdf-parser
```

## 🔌 端口分配

| 环境 | PDF Parser | 主 API | 说明 |
|------|------------|--------|------|
| dev  | **7800**   | 3000   | 开发环境，避免与常见8000端口冲突 |
| qa   | **7801**   | 3001   | 测试环境 |
| prod | **7802**   | 3002   | 生产环境 |

**注意**: 新的端口配置 (7800-7802) 专门选择来避免与以下常见服务的端口冲突:
- 8000: Django 开发服务器
- 8001: 其他常见开发服务
- 8002: 代理服务器
- 8080: Tomcat/Jenkins 等

## 🛑 停止服务

### 停止所有服务 (包括 PDF Parser)

```bash
./stop.sh dev --pdf-parser
```

### 仅停止 PDF Parser

```bash
./stop.sh --only-pdf-parser
```

### 强制停止

```bash
./stop.sh dev --pdf-parser --force
```

## 🔧 PDF Parser 独立管理

### 进入 PDF Parser 目录

```bash
cd pdf_parser
```

### 独立启动 PDF Parser

```bash
# 基础启动
./start.sh

# 指定环境和端口
./start.sh --env dev --port 7800

# 初始化环境并启动
./start.sh --setup

# 前台运行 (调试)
./start.sh --foreground

# 启动并查看日志
./start.sh --logs
```

### 独立停止 PDF Parser

```bash
# 正常停止
./stop.sh

# 强制停止
./stop.sh --force

# 停止并清理
./stop.sh --clean
```

## 📊 服务监控

### 健康检查

```bash
# 基础健康检查
curl http://localhost:7800/health

# 详细健康检查
curl http://localhost:7800/admin/health/detailed
```

### 服务状态

```bash
# 查看运行状态
./stop.sh --only-pdf-parser  # 会显示状态然后停止

# 或查看进程
ps aux | grep -E "(uvicorn|celery)"
```

### 访问服务

| 环境 | API 端口 | 文档地址 | 管理界面 |
|------|----------|----------|----------|
| dev  | 7800     | http://localhost:7800/docs | http://localhost:7800/admin/metrics |
| qa   | 7801     | http://localhost:7801/docs | http://localhost:7801/admin/metrics |
| prod | 7802     | http://localhost:7802/docs | http://localhost:7802/admin/metrics |

## 📁 目录结构

```
backend/
├── start.sh                    # 主启动脚本
├── stop.sh                     # 主停止脚本
├── scripts/
│   ├── start.sh               # 详细启动脚本 (支持 --pdf-parser)
│   └── stop.sh                # 详细停止脚本 (支持 --pdf-parser)
└── pdf_parser/
    ├── start.sh               # PDF Parser 独立启动
    ├── stop.sh                # PDF Parser 独立停止
    ├── main.py                # FastAPI 应用
    ├── celery_app.py          # Celery 任务
    └── logs/                  # 日志文件
        ├── api.log           # API 服务日志
        ├── worker.log        # Worker 日志
        ├── api.pid           # API 进程 PID
        └── worker.pid        # Worker 进程 PID
```

## ⚙️ 配置说明

### 环境变量 (.env)

PDF Parser 会自动创建 `.env` 配置文件，主要配置项：

```bash
# 环境配置
ENVIRONMENT=dev
DEBUG=true
HOST=0.0.0.0
PORT=7800

# 数据库配置 (与主服务共享)
MONGODB_URL=mongodb://localhost:27017
MONGODB_DATABASE=nutriguide_pdf

# Redis 配置 (与主服务共享)
REDIS_URL=redis://localhost:6379/0
CELERY_BROKER_URL=redis://localhost:6379/1
CELERY_RESULT_BACKEND=redis://localhost:6379/2

# 功能开关
OCR_ENABLED=true
RATE_LIMIT_ENABLED=true
METRICS_ENABLED=true
```

### 端口分配

| 环境 | PDF Parser | 主 API | MongoDB | Redis | Admin UI |
|------|------------|--------|---------|-------|----------|
| dev  | 7800       | 3000   | 27017   | 6379  | 8081     |
| qa   | 7801       | 3001   | 27018   | 6380  | 8083     |
| prod | 7802       | 3002   | 27019   | 6381  | 5555     |

## 🔍 故障排除

### 1. 端口占用

```bash
# 查看端口占用
lsof -i :7800

# 强制停止占用进程
./stop.sh --only-pdf-parser --force
```

### 2. 依赖问题

```bash
# 重新安装依赖
cd pdf_parser
./start.sh --setup
```

### 3. 服务无法启动

```bash
# 查看日志
cd pdf_parser
tail -f logs/api.log
tail -f logs/worker.log

# 检查外部服务
nc -z localhost 27017  # MongoDB
nc -z localhost 6379   # Redis
```

### 4. 权限问题

```bash
# 确保脚本有执行权限
chmod +x start.sh stop.sh
chmod +x scripts/start.sh scripts/stop.sh
chmod +x pdf_parser/start.sh pdf_parser/stop.sh
```

## 🎉 使用示例

### 完整开发流程

```bash
# 1. 启动完整开发环境
./start.sh dev --pdf-parser

# 2. 测试 PDF 解析
curl -X POST "http://localhost:7800/parse/sync" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test.pdf"

# 3. 查看服务状态
curl http://localhost:7800/health

# 4. 停止服务
./stop.sh dev --pdf-parser
```

### 生产部署

```bash
# 1. 启动生产环境
./start.sh prod --pdf-parser --build

# 2. 检查服务状态
curl http://localhost:7802/admin/health/detailed

# 3. 查看指标
curl http://localhost:7802/admin/metrics
```

## 📞 支持

如遇问题：
1. 查看服务日志：`cd pdf_parser && tail -f logs/*.log`
2. 检查进程状态：`ps aux | grep -E "(uvicorn|celery)"`
3. 验证网络连接：`nc -z localhost 27017 && nc -z localhost 6379`
4. 重新初始化：`cd pdf_parser && ./start.sh --setup`

---

**更新时间**: 2025-06-05  
**版本**: 2.0.0 