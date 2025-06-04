# Git 子模块设置说明

## 当前状态

- ✅ `pdf_parser` 子模块已正确配置并可使用
- ⏳ `backend_node` 子模块暂时禁用，因为目标仓库 `git@github.com:tangzzz-fan/NutriGuide_backend_all.git` 当前为空

## 启用 backend_node 子模块

当 `NutriGuide_backend_all.git` 仓库有内容后，请执行以下步骤：

### 1. 更新 .gitmodules 文件

取消注释 `.gitmodules` 文件中的 backend_node 配置：

```
[submodule "backend_node"]
	path = backend_node
	url = git@github.com:tangzzz-fan/NutriGuide_backend_all.git
	branch = main
```

### 2. 添加子模块

```bash
git submodule add git@github.com:tangzzz-fan/NutriGuide_backend_all.git backend_node
```

### 3. 初始化并更新子模块

```bash
git submodule update --init --recursive
```

## 常用子模块命令

```bash
# 初始化所有子模块
git submodule update --init --recursive

# 更新所有子模块到最新提交
git submodule update --remote

# 拉取子模块的最新更改
git submodule foreach git pull origin main
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