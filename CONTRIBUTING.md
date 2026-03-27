# 🤝 贡献指南

欢迎来到 CLIProxyAPI 项目！我们非常高兴您有兴趣为这个项目做出贡献。无论您是修复 bug、添加新功能、改进文档，还是帮助其他用户，您的贡献都非常宝贵。

## 📋 目录

- [开始之前](#-开始之前)
- [贡献方式](#-贡献方式)
- [开发环境](#-开发环境)
- [代码规范](#-代码规范)
- [提交规范](#-提交规范)
- [Pull Request 流程](#-pull-request-流程)
- [测试指南](#-测试指南)
- [文档贡献](#-文档贡献)
- [社区](#-社区)
- [致谢](#-致谢)

## 🎯 开始之前

### 阅读文档

在开始贡献之前，请确保您已经阅读了以下文档：

- [README.md](README.md) - 项目概述和安装指南
- [用户指南](https://github.com/router-for-me/CLIProxyAPI/wiki/User-Guide) - 详细使用指南
- [API 文档](https://github.com/router-for-me/CLIProxyAPI/wiki/API-Documentation) - API 参考文档
- [开发文档](https://github.com/router-for-me/CLIProxyAPI/wiki/Development-Guide) - 开发指南

### 了解项目

在开始之前，请了解项目的：

- **目标用户：** 开发者和系统管理员
- **核心价值：** 简化 AI API 代理管理
- **技术栈：** Bash、Docker、Python、YAML
- **架构：** 微服务架构

### 行为准则

请阅读并遵守我们的 [行为准则](.github/CODE_OF_CONDUCT.md)。我们致力于为所有贡献者提供一个友好、包容的环境。

## 🌟 贡献方式

### 🐛 报告 Bug

如果您发现 bug，请：

1. **检查现有 Issues：** 确保 bug 尚未被报告
2. **创建新 Issue：** 使用 [Bug 报告模板](.github/ISSUE_TEMPLATE/bug_report.md)
3. **提供详细信息：** 包括复现步骤、环境信息、日志等

### ✨ 建议功能

如果您有新想法，请：

1. **检查现有建议：** 确保功能尚未被建议
2. **创建新 Issue：** 使用 [功能请求模板](.github/ISSUE_TEMPLATE/feature_request.md)
3. **详细描述：** 包括使用场景、解决方案、预期效果

### 📚 改进文档

文档贡献包括：

- 修复拼写错误
- 改进示例
- 添加新章节
- 翻译文档
- 更新截图

### 💻 提交代码

代码贡献包括：

- Bug 修复
- 新功能实现
- 性能优化
- 测试改进
- 代码重构

### 🌐 帮助社区

其他贡献方式：

- 回答问题
- 参与讨论
- 分享使用经验
- 推广项目
- 报告安全问题

## 🛠️ 开发环境

### 系统要求

- **操作系统：** Ubuntu 20.04+ / Debian 10+ / CentOS 7+ / Alpine 3.14+
- **内存：** 2GB+
- **存储：** 20GB+
- **网络：** 稳定的网络连接

### 安装依赖

```bash
# 安装基本工具
sudo apt update
sudo apt install -y git curl wget vim

# 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 安装 Python
sudo apt install -y python3 python3-pip

# 安装开发工具
pip3 install pre-commit shellcheck pyyaml

# 配置 Git
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### 设置开发环境

```bash
# Fork 项目
# 1. 访问 https://github.com/router-for-me/CLIProxyAPI
# 2. 点击 "Fork" 按钮

# 克隆您的 Fork
git clone https://github.com/your-username/CLIProxyAPI.git
cd CLIProxyAPI

# 添加上游仓库
git remote add upstream https://github.com/router-for-me/CLIProxyAPI.git

# 创建开发分支
git checkout -b develop

# 安装 pre-commit hooks
pre-commit install

# 运行初始测试
./test-script.sh
```

## 📝 代码规范

### Shell 脚本规范

#### 基础规范

1. **Shebang：**
   ```bash
   #!/bin/bash
   set -euo pipefail
   ```

2. **注释：**
   ```bash
   # 好的注释示例
   # - 解释为什么这样做
   # - 说明复杂的逻辑
   # - 标记 TODO 和 FIXME
   
   # 避免
   # - 重复代码功能的注释
   # - 过时的注释
   ```

3. **变量命名：**
   ```bash
   # 使用小写下划线命名
   local_variable="value"
   global_variable="value"
   
   # 环境变量使用大写
   export PATH="/usr/local/bin:$PATH"
   ```

4. **函数命名：**
   ```bash
   # 使用动词+名词形式
   create_backup() {
       # ...
   }
   
   validate_config() {
       # ...
   }
   ```

#### 代码结构

1. **函数组织：**
   ```bash
   # 按照依赖关系组织
   helper_function() {
       # ...
   }
   
   main_function() {
       helper_function
       # ...
   }
   ```

2. **错误处理：**
   ```bash
   # 检查命令返回值
   if ! command -v docker &>/dev/null; then
       error "Docker 未安装"
   fi
   
   # 使用 trap 清理资源
   trap 'cleanup' EXIT
   ```

3. **输入验证：**
   ```bash
   # 验证参数
   if [ $# -eq 0 ]; then
       usage
       exit 1
   fi
   
   # 验证文件存在
   if [ ! -f "$config_file" ]; then
       error "配置文件不存在: $config_file"
   fi
   ```

### YAML 规范

#### 配置文件格式

1. **缩进：**
   ```yaml
   # 使用 2 空格缩进
   server:
     host: "0.0.0.0"
     port: 8317
   ```

2. **命名规范：**
   ```yaml
   # 使用小写下划线
   rate_limit:
     enabled: true
     requests_per_minute: 60
   ```

3. **注释：**
   ```yaml
   # 在配置项上方添加注释
   # 说明配置项的用途和取值范围
   features:
     # 是否启用速率限制
     # 取值: true/false
     rate_limit:
       enabled: true
   ```

### Markdown 规范

1. **标题层次：**
   ```markdown
   # 一级标题
   
   ## 二级标题
   
   ### 三级标题
   
   #### 四级标题
   ```

2. **代码块：**
   ```markdown
   ```bash
   # 使用语言标识符
   command --option
   ```
   ```

3. **链接：**
   ```markdown
   # 使用相对链接
   [README](README.md)
   [配置文件](config.example.yaml)
   ```

## 🔄 提交规范

### 提交消息格式

使用 Angular Commit Message Conventions：

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

### Type

必须使用以下类型之一：

- **feat**: 新功能
- **fix**: Bug 修复
- **docs**: 文档更新
- **style**: 代码格式（不影响代码含义）
- **refactor**: 代码重构（既不是修复 bug 也不是添加新功能）
- **test**: 添加或修改测试
- **chore**: 构建过程或辅助工具的变动

### Scope

可选，表示修改的范围：

- **cli**: 管理脚本相关
- **config**: 配置文件相关
- **docker**: Docker 配置相关
- **docs**: 文档相关
- **test**: 测试相关
- **ci**: CI/CD 相关

### Subject

- 使用祈使语气
- 首字母小写
- 不要超过 50 个字符
- 不要添加句号

### Body

- 解释为什么修改
- 解释如何修改
- 对比修改前后的差异

### Footer

- **Breaking Changes**: 描述任何破坏性变更
- **Closes**: 关联的 Issue 编号

### 示例

```
feat(cli): add backup and restore functionality

- Add backup command to create full system backup
- Add restore command to recover from backup
- Add automatic backup before update

Closes #123
```

```
fix(config): validate yaml syntax before applying

- Use python3 yaml module to validate config syntax
- Show clear error message for invalid yaml
- Prevent service crash due to bad config

Fixes #456
```

```
docs(readme): update installation instructions

- Add detailed steps for different OS
- Add troubleshooting section
- Update screenshots

See #789
```

### 提交频率

- 频繁提交，每次提交应该是一个完整的、可测试的变更
- 避免提交大量不相关的变更
- 使用 `git add -p` 选择性地添加变更

## 🚀 Pull Request 流程

### 1. 创建分支

```bash
# 从最新的 develop 分支创建
git checkout develop
git pull upstream develop
git checkout -b feature/your-feature-name
```

### 2. 开发

```bash
# 进行修改
# 添加测试
# 更新文档
```

### 3. 提交

```bash
# 添加变更
git add .

# 提交
git commit -m "feat(feature): add your feature"

# 或者使用 git commit 打开编辑器
git commit
```

### 4. 同步上游

```bash
# 获取上游最新变更
git fetch upstream

# 变基到上游
git rebase upstream/develop

# 解决冲突
# 继续变基
git rebase --continue
```

### 5. 推送

```bash
# 推送到您的 Fork
git push origin feature/your-feature-name

# 如果推送失败，可能需要强制推送
git push -f origin feature/your-feature-name
```

### 6. 创建 Pull Request

1. 访问您的 GitHub Fork
2. 点击 "Compare & pull request"
3. 填写 PR 模板
4. 等待 CI 检查通过
5. 回应审查意见

### 7. 代码审查

审查者可能会要求您：

- 修复代码风格问题
- 添加或更新测试
- 更新文档
- 修复 bug
- 优化性能

### 8. 合并

一旦 PR 通过审查，维护者将合并您的 PR。

## 🧪 测试指南

### 测试类型

1. **单元测试：** 测试单个函数或模块
2. **集成测试：** 测试多个模块的交互
3. **功能测试：** 测试完整的功能流程
4. **性能测试：** 测试性能指标
5. **兼容性测试：** 测试不同环境

### 运行测试

```bash
# 运行所有测试
./test-script.sh

# 运行特定测试
./test-script.sh --test backup-test

# 运行性能测试
./test-script.sh --performance
```

### 编写测试

```bash
# 测试函数示例
test_backup_creation() {
    local test_dir="/tmp/test-backup"
    mkdir -p "$test_dir"
    
    # 创建测试文件
    echo "test" > "$test_dir/test.txt"
    
    # 运行备份
    ./cli-proxy.sh backup
    
    # 验证备份
    if [ -f "$BACKUP_DIR/backup_*.tar.gz" ]; then
        echo "✅ 备份创建成功"
    else
        echo "❌ 备份创建失败"
        exit 1
    fi
}
```

## 📚 文档贡献

### 文档结构

```
docs/
├── README.md              # 项目概述
├── INSTALL.md            # 安装指南
├── USER_GUIDE.md         # 用户指南
├── API.md                # API 文档
├── CONFIGURATION.md      # 配置说明
├── TROUBLESHOOTING.md    # 故障排除
├── FAQ.md                # 常见问题
├── CHANGELOG.md          # 更新日志
└── IMAGES/               # 图片资源
```

### 文档编写规范

1. **清晰简洁：** 使用简单明了的语言
2. **结构清晰：** 使用标题、列表、表格等
3. **代码示例：** 提供完整可运行的代码示例
4. **截图：** 必要时添加截图说明
5. **链接：** 正确链接到相关文档

## 💬 社区

### 讨论渠道

- **GitHub Discussions:** [https://github.com/router-for-me/CLIProxyAPI/discussions](https://github.com/router-for-me/CLIProxyAPI/discussions)
- **GitHub Issues:** [https://github.com/router-for-me/CLIProxyAPI/issues](https://github.com/router-for-me/CLIProxyAPI/issues)
- **Stack Overflow:** 使用 `cli-proxy-api` 标签
- **Twitter:** [@CLIProxyAPI](https://twitter.com/CLIProxyAPI)

### 帮助其他用户

1. **回答问题：** 在 Discussions 和 Stack Overflow 中回答问题
2. **分享经验：** 分享使用经验和最佳实践
3. **报告问题：** 及时报告发现的问题
4. **提供反馈：** 提供建设性的反馈

## 🎉 致谢

### 如何致谢

我们会在以下地方致谢您的贡献：

- **贡献者列表：** [CONTRIBUTORS.md](CONTRIBUTORS.md)
- **发布说明：** 每次发布都会感谢贡献者
- **项目主页：** 在项目主页显示贡献者头像
- **社交媒体：** 在社交媒体上提及贡献者

### 贡献者荣誉

我们设立了以下荣誉：

- **年度贡献者：** 每年贡献最多的前 10 名
- **新星贡献者：** 首次贡献即获得高评价的贡献者
- **文档贡献者：** 对文档做出重大贡献的贡献者
- **社区贡献者：** 在社区中表现突出的贡献者

## 📞 联系方式

如果您需要帮助或有疑问，请联系：

- **GitHub:** [https://github.com/router-for-me/CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI)
- **邮箱:** contribute@cli-proxy-api.com
- **Discord:** [加入 Discord 服务器](https://discord.gg/cli-proxy-api)
- **论坛:** [https://forum.cli-proxy-api.com](https://forum.cli-proxy-api.com)

## 🎯 结语

感谢您阅读这份贡献指南！我们非常高兴您能成为 CLIProxyAPI 社区的一员。无论您的贡献是大是小，都对项目有着重要的价值。

**让我们开始贡献吧！** 🚀

---

**最后更新：** 2026-03-27
**贡献者：** [CLIProxyAPI 团队](https://github.com/router-for-me/CLIProxyAPI/graphs/contributors)