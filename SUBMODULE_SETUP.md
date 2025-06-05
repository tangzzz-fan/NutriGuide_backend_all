# 🔗 Git 子模块配置状态

## ✅ 已配置的子模块

- `git@github.com:tangzzz-fan/NutriGuide_backend.git` → `backend_node/`

## 📋 子模块状态检查

- ✅ `backend_node` 子模块已正确配置并可使用

## 🚀 快速操作指南

### 初始化所有子模块
```bash
git submodule update --init --recursive
```

### 更新子模块到最新版本
```bash
git submodule update --remote --merge
```

### 查看子模块状态
```bash
git submodule status
```

### 进入子模块进行开发
```bash
cd backend_node
git checkout main
git pull origin main
```

## 🔧 开发工作流

### 1. 在子模块中开发
```bash
cd backend_node
git checkout -b feature/new-feature
# 进行开发工作...
git add .
git commit -m "feat: add new feature"
git push origin feature/new-feature
```

### 2. 更新主仓库中的子模块引用
```bash
# 回到主仓库根目录
cd ..
git add backend_node
git commit -m "update: backend_node submodule reference"
git push origin main
```

## 📚 注意事项

1. **子模块独立性**: 每个子模块都是独立的 Git 仓库
2. **版本控制**: 主仓库只记录子模块的特定提交哈希
3. **同步更新**: 子模块更新后需要在主仓库中提交引用更新
4. **权限管理**: 确保对子模块仓库有相应的访问权限

## 🛠️ 故障排除

### 子模块初始化失败
```bash
# 清理并重新初始化
git submodule deinit --all
git submodule update --init --recursive
```

### 子模块状态异常
```bash
# 重置子模块状态
git submodule foreach --recursive git reset --hard
git submodule update --recursive
``` 