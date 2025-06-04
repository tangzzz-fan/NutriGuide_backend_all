# Git 子模块设置说明

## 仓库结构

- 🏠 **主仓库**: `git@github.com:tangzzz-fan/NutriGuide_backend_all.git` (当前仓库)
- 📦 **子仓库**: 
  - `git@github.com:tangzzz-fan/NutriGuide_backend.git` → `backend_node/`
  - `git@github.com:tangzzz-fan/NutriGuide_pdf_parser.git` → `pdf_parser/`

## 当前状态

- ✅ `backend_node` 子模块已正确配置并可使用
- ✅ `pdf_parser` 子模块已正确配置并可使用

## 子模块管理

### 初始化所有子模块
```bash
git submodule update --init --recursive
```

### 更新所有子模块到最新提交
```bash
git submodule update --remote
```

### 拉取子模块的最新更改
```bash
git submodule foreach git pull origin main
```

### 克隆包含子模块的仓库
```bash
git clone --recursive git@github.com:tangzzz-fan/NutriGuide_backend_all.git
```

## 开发工作流

### 在子模块中进行开发
```bash
# 进入子模块目录
cd backend_node  # 或 cd pdf_parser

# 创建新分支进行开发
git checkout -b feature/new-feature

# 进行开发并提交
git add .
git commit -m "Add new feature"
git push origin feature/new-feature

# 返回主仓库
cd ..

# 更新主仓库中的子模块引用
git add backend_node  # 或 pdf_parser
git commit -m "Update backend_node submodule"
git push origin main
```

### 同步子模块更改
```bash
# 拉取子模块的最新更改
git submodule update --remote --merge

# 提交子模块更新到主仓库
git add .
git commit -m "Update submodules to latest versions"
git push origin main
```

## 问题排查

如果遇到子模块问题，可以使用以下命令清理和重新设置：

```bash
# 移除问题子模块
git submodule deinit -f <submodule_name>
rm -rf .git/modules/<submodule_name>
git rm -f <submodule_name>

# 重新添加子模块
git submodule add <repository_url> <submodule_path>
```

## 注意事项

1. **子模块指向特定提交**: 子模块总是指向特定的提交，而不是分支
2. **同步更新**: 在子模块中进行更改后，需要在主仓库中提交子模块引用的更新
3. **团队协作**: 团队成员需要运行 `git submodule update` 来同步子模块更改 