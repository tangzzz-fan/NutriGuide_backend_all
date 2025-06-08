# 🏗️ NutriGuide Backend Services

> NutriGuide 后端服务集合 - 基于微服务架构的智能营养平台后端

## 📖 项目简介

NutriGuide Backend 是智能营养指导平台的后端服务集合，采用微服务架构设计，通过 Git 子模块管理多个独立的微服务。

## 🏛️ 微服务架构

```
backend/                        # 后端服务主仓库
├── backend_node/              # Git 子模块：NestJS API 服务
├── docker-compose.*.yml       # 多环境容器编排
├── scripts/                   # 运维和管理脚本
│   ├── start.sh              # 服务启动脚本
│   ├── stop.sh               # 服务停止脚本
│   ├── init-submodules.sh    # Git 子模块管理
│   └── mongo-init.js         # MongoDB 初始化
└── .gitmodules               # Git 子模块配置
```

## 🚀 快速开始

### 环境要求

- **Docker**: 20.0+
- **Docker Compose**: 2.0+
- **Git**: 2.30+
- **Node.js**: 18+ (本地开发)

### 一键部署

```bash
# 1. 克隆后端仓库
git clone <backend-repository-url>
cd backend

# 2. 初始化 Git 子模块
./scripts/init-submodules.sh --init

# 3. 启动开发环境
./scripts/start.sh dev

# 4. 启动QA环境
./scripts/start.sh qa

# 5. 启动生产环境
./scripts/start.sh prod
```

## 🔧 Git 子模块管理

### 子模块操作

```bash
# 初始化子模块
./scripts/init-submodules.sh --init

# 更新子模块到最新版本
./scripts/init-submodules.sh --update

# 查看子模块状态
./scripts/init-submodules.sh --status

# 清理并重新初始化子模块
./scripts/init-submodules.sh --clean
```

### 手动子模块操作

```bash
# 添加新的微服务子模块
git submodule add <repository-url> service_name

# 克隆时包含子模块
git clone --recursive <repository-url>

# 更新特定子模块
git submodule update --remote backend_node

# 进入子模块开发
cd backend_node
git checkout -b feature/new-feature
# ... 开发工作 ...
git commit -m "feat: add new feature"
git push origin feature/new-feature
```

## 📊 微服务详情

### 🔹 Backend Node (NestJS API)
- **路径**: `backend_node/`
- **技术栈**: NestJS + TypeScript + MongoDB
- **功能**: 用户管理、认证、食品数据、膳食计划
- **端口**: 3000/3001/3002 (dev/qa/prod)
- **仓库**: 独立 Git 仓库作为子模块

## 🌐 服务端点

### 开发环境 (dev)

| 服务 | 地址 | 说明 |
|------|------|------|
| 🌐 Backend API | http://localhost:3000 | NestJS 后端API |
| 🗄️ MongoDB Admin | http://localhost:8081 | 数据库管理界面 |
| 🔴 Redis Commander | http://localhost:8082 | Redis 管理界面 |
| 📚 API 文档 | http://localhost:3000/api/docs | Swagger API 文档 |

### QA环境 (qa)

| 服务 | 地址 | 说明 |
|------|------|------|
| 🌐 Backend API | http://localhost:3001 | QA环境后端API |
| 🗄️ MongoDB Admin | http://localhost:8083 | QA环境数据库管理 |

### 生产环境 (prod)

| 服务 | 地址 | 说明 |
|------|------|------|
| 🌐 Backend API | http://localhost:3002 | 生产环境后端API |

## 🐳 Docker 容器编排

### 多环境配置

- **docker-compose.dev.yml**: 开发环境配置
- **docker-compose.qa.yml**: QA测试环境配置  
- **docker-compose.prod.yml**: 生产环境配置

### 容器服务

- **MongoDB**: 数据库服务 (27017/27018/27019)
- **Redis**: 缓存和消息队列 (6379/6380/6381)
- **Backend API**: NestJS 服务容器
- **Monitoring**: 数据库和队列监控工具

## 🔧 本地开发

### 微服务独立开发

```bash
# Backend Node 服务
cd backend_node
npm install
npm run start:dev
```

### 完整服务栈开发(可以开启命令行代理)

```bash
# 启动完整开发环境
./scripts/start.sh dev --build

# 实时查看日志
./scripts/start.sh dev --logs

# 停止开发环境
./scripts/stop.sh dev
```

## 🧪 测试

### 服务健康检查

```bash
# 检查所有服务状态
docker-compose -f docker-compose.dev.yml ps

# API 健康检查
curl http://localhost:3000/health
```

## 📊 监控与日志

### 服务日志

```bash
# 查看所有服务日志
docker-compose -f docker-compose.dev.yml logs -f

# 查看特定服务日志
docker-compose -f docker-compose.dev.yml logs -f backend-api-dev
```

### 性能监控

- **MongoDB**: Mongo Express (8081/8083)
- **Redis**: Redis Commander (8082)
- **Application Logs**: 容器日志聚合

## 🚀 部署

### 环境变量配置

```bash
# 开发环境
export NODE_ENV=development
export MONGODB_URI=mongodb://localhost:27017/nutriguide_dev
export REDIS_URL=redis://localhost:6379

# 生产环境
export NODE_ENV=production
export MONGODB_ADMIN_PASSWORD="secure-password"
export JWT_SECRET="super-secure-jwt-secret"
export CORS_ORIGIN="https://nutriguide.com"
```

### 部署命令

```bash
# 开发环境部署
./scripts/start.sh dev --build

# 生产环境部署 (拉取最新镜像)
./scripts/start.sh prod --pull

# 热更新部署 (重新构建)
./scripts/start.sh prod --build
```

## 🔒 安全配置

### 认证与授权
- JWT Token 认证机制
- API 访问速率限制
- CORS 跨域配置
- 数据库访问控制

### 数据保护
- 密码加密存储
- 敏感数据环境变量管理
- 网络隔离配置
- 容器安全基线

## 🤝 开发指南

### 微服务开发流程

1. **选择微服务**: 进入对应的子模块目录
2. **创建分支**: `git checkout -b feature/new-feature`
3. **开发功能**: 在子模块中进行开发
4. **测试验证**: 使用 Docker 环境测试
5. **提交更改**: 在子模块中提交并推送
6. **更新引用**: 在主仓库中更新子模块引用

### 代码规范

- **Backend Node**: ESLint + Prettier + TypeScript
- **Docker**: Multi-stage builds, 安全基线
- **Git**: Conventional Commits 规范

## 🛠️ 故障排除

### 常见问题

#### 1. 子模块同步问题
```bash
# 重新同步子模块
git submodule sync --recursive
git submodule update --init --recursive
```

#### 2. 容器启动失败
```bash
# 检查端口占用
lsof -i :3000
# 清理 Docker 资源
./scripts/start.sh --clean
```

#### 3. 数据库连接问题
```bash
# 检查 MongoDB 容器
docker-compose -f docker-compose.dev.yml logs mongodb-dev
# 重新初始化数据库
docker-compose -f docker-compose.dev.yml down -v
```

## 📞 支持与联系

- **技术支持**: backend-team@nutriguide.com
- **问题反馈**: 通过各微服务的 GitHub Issues
- **文档更新**: 欢迎提交 PR 改进文档

---

**NutriGuide Backend Team** © 2024 