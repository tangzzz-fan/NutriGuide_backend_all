# Frontend 子模块设置完成

## 🎯 设置概述

Frontend 已成功设置为主仓库的子模块，与 backend_node 平级。

### 仓库结构
```
NutriGuide/backend/
├── backend_node/          # 后端 Node.js 服务 (子模块)
├── frontend/              # 前端 React 应用 (子模块)
├── .gitmodules           # 子模块配置文件
└── ...
```

### 子模块配置
```ini
[submodule "frontend"]
    path = frontend
    url = git@github.com:tangzzz-fan/NutriGuide_frontend.git
```

## 🚀 使用方法

### 初次克隆仓库
```bash
# 克隆主仓库并初始化所有子模块
git clone --recursive git@github.com:your-repo/NutriGuide_backend.git

# 或者分步执行
git clone git@github.com:your-repo/NutriGuide_backend.git
cd NutriGuide_backend
git submodule update --init --recursive
```

### 更新子模块
```bash
# 更新所有子模块到最新版本
git submodule update --remote

# 更新特定子模块
git submodule update --remote frontend
```

### 在子模块中工作
```bash
# 进入 frontend 子模块
cd frontend

# 切换到开发分支
git checkout main

# 进行修改并提交
git add .
git commit -m "Your changes"
git push origin main

# 回到主仓库并更新子模块引用
cd ..
git add frontend
git commit -m "Update frontend submodule"
git push
```

## 🛠️ 开发工作流

### Frontend 开发
```bash
# 进入 frontend 目录
cd frontend

# 安装依赖
npm install

# 启动开发服务器
npm run dev
# 或使用
npx vite --port 4000
```

### 同时开发 Frontend 和 Backend
```bash
# 终端 1: 启动后端
cd backend_node
npm run start:dev

# 终端 2: 启动前端
cd frontend
npm run dev
```

## 📁 Frontend 功能特性

### 已实现功能
- ✅ 无限制登录 (任意手机号+验证码)
- ✅ 强制 Onboarding 流程
- ✅ 智能路由保护
- ✅ 用户状态管理
- ✅ 现代化 UI 界面

### 路由配置
- `/auth` - 登录页面
- `/onboarding` - 用户引导页面
- `/` - 主应用页面
- `/nutrition` - 营养分析
- `/recipes` - 食谱推荐
- `/profile` - 个人中心

### 测试流程
1. 访问 http://localhost:4000 (或 4001)
2. 输入任意手机号和验证码登录
3. 完成 Onboarding 设置
4. 进入主应用

## 🔧 子模块管理命令

### 查看子模块状态
```bash
git submodule status
```

### 添加新子模块
```bash
git submodule add <repository-url> <path>
```

### 移除子模块
```bash
git submodule deinit <path>
git rm <path>
git commit -m "Remove submodule"
```

### 子模块分支管理
```bash
# 在子模块中切换分支
cd frontend
git checkout -b feature/new-feature

# 推送子模块更改
git push origin feature/new-feature

# 在主仓库中更新子模块引用
cd ..
git add frontend
git commit -m "Update frontend to feature branch"
```

## 🚨 注意事项

### 子模块工作原则
1. **独立开发**: 每个子模块都是独立的 git 仓库
2. **版本锁定**: 主仓库记录特定的子模块提交 hash
3. **手动更新**: 子模块更新需要在主仓库中手动提交
4. **分支管理**: 子模块可以有自己的分支策略

### 常见问题解决
```bash
# 子模块目录为空
git submodule update --init

# 子模块有未提交更改
cd frontend
git stash
git pull origin main
git stash pop

# 重置子模块到主仓库记录的版本
git submodule update --force
```

## 📊 当前状态

### Frontend 子模块
- **仓库**: git@github.com:tangzzz-fan/NutriGuide_frontend.git
- **分支**: main
- **状态**: ✅ 正常运行
- **端口**: 4000/4001

### 集成状态
- **主仓库**: ✅ 子模块已添加
- **依赖安装**: ✅ 完成
- **开发服务器**: ✅ 运行中
- **功能测试**: ✅ 通过

## 🎉 总结

Frontend 已成功设置为子模块，现在可以：
- 独立管理 Frontend 代码仓库
- 保持与 Backend 的版本同步
- 支持并行开发和部署
- 维护清晰的项目结构

开发者可以在各自的子模块中独立工作，通过主仓库协调整体项目版本。
