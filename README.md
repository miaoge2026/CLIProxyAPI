# CLIProxyAPI 管理脚本

一个用于简化 CLIProxyAPI Docker 容器管理的 Bash 脚本，支持一键安装、更新、配置和服务管理。

## 功能特性

- 🚀 **一键安装**：自动检测并安装 Docker、Git、Curl 等依赖
- 🔄 **版本管理**：自动获取最新版本，支持指定版本安装
- 📝 **配置生成**：自动生成配置文件模板，支持自定义配置
- 🖥️ **服务管理**：启动、停止、重启、查看状态
- 📊 **健康检查**：自动验证服务运行状态
- 📋 **日志查看**：实时查看容器日志
- 🔧 **系统支持**：专为 Ubuntu/Debian 系统设计

## 系统要求

- **操作系统**：Ubuntu 20.04+ 或 Debian 10+
- **架构**：amd64/arm64
- **权限**：需要 sudo 权限（用于安装软件包）
- **网络**：需要访问 GitHub 和 Docker Hub

## 快速开始

### 1. 下载脚本

```bash
wget https://raw.githubusercontent.com/miaoge2026/CLIProxyAPI/main/cli-proxy.sh
# 或
curl -O https://raw.githubusercontent.com/miaoge2026/CLIProxyAPI/main/cli-proxy.sh
```

### 2. 赋予执行权限

```bash
chmod +x cli-proxy.sh
```

### 3. 运行脚本

**交互模式**（显示菜单）：
```bash
./cli-proxy.sh
```

**命令模式**：
```bash
./cli-proxy.sh install    # 一键安装
./cli-proxy.sh update     # 更新服务
./cli-proxy.sh status     # 查看状态
./cli-proxy.sh restart    # 重启服务
./cli-proxy.sh logs       # 查看日志
./cli-proxy.sh uninstall  # 卸载服务
```

## 详细使用说明

### 安装服务

```bash
./cli-proxy.sh install
```

执行后脚本将：
1. 自动安装 Docker 和 Docker Compose（如未安装）
2. 安装 Git 和 Curl 依赖
3. 克隆 CLIProxyAPI 项目仓库
4. 创建默认配置文件
5. 拉取并启动 Docker 容器

### 配置 API Key

安装完成后，请编辑配置文件：

```bash
nano ~/CLIProxyAPI/config.yaml
```

添加你的 AI 服务 API Key：

```yaml
auth:
  keys:
    - "your-secret-key-here"

providers:
  - type: "openai"
    api_key: "your-openai-api-key"
    base_url: "https://api.openai.com/v1"
  - type: "claude"
    api_key: "your-claude-api-key"
```

### 服务管理命令

**查看服务状态**：
```bash
./cli-proxy.sh status
```

**重启服务**：
```bash
./cli-proxy.sh restart
```

**查看实时日志**：
```bash
./cli-proxy.sh logs
```

**更新到最新版本**：
```bash
./cli-proxy.sh update
```

### 卸载服务

```bash
./cli-proxy.sh uninstall
```

将停止并删除容器，保留配置文件和项目目录。

## 配置文件说明

配置文件位于 `~/CLIProxyAPI/config.yaml`：

### 认证配置

```yaml
auth:
  keys:
    - "client-secret-key-1"
    - "client-secret-key-2"
```

### 提供商配置

```yaml
providers:
  - type: "openai"
    api_key: "sk-xxxxxxxxxxxxxxxx"
    base_url: "https://api.openai.com/v1"
    models:
      - "gpt-3.5-turbo"
      - "gpt-4"
  - type: "azure"
    api_key: "your-azure-key"
    base_url: "https://your-resource.openai.azure.com/"
```

## 目录结构

```
CLIProxyAPI/
├── config.yaml           # 主配置文件
├── config.example.yaml   # 配置示例
├── docker-compose.yml    # Docker 编排文件
├── auths/                # 认证相关文件
├── logs/                 # 日志目录
└── cli-proxy.sh         # 管理脚本
```

## 常见问题

### Q: 安装时提示权限不足？
A: 确保使用 sudo 或以 root 用户运行：
```bash
sudo ./cli-proxy.sh install
```

### Q: 如何修改服务端口？
A: 编辑 `~/CLIProxyAPI/docker-compose.yml` 文件，修改端口映射。

### Q: 服务无法启动怎么办？
A: 查看日志诊断问题：
```bash
./cli-proxy.sh logs
```

### Q: 如何备份配置？
A: 备份配置文件和项目目录：
```bash
cp -r ~/CLIProxyAPI ~/CLIProxyAPI-backup
```

## 故障排除

### Docker 安装失败
- 确保系统已更新：`sudo apt update && sudo apt upgrade -y`
- 检查网络连接
- 手动安装 Docker：https://docs.docker.com/engine/install/

### 容器无法启动
- 检查端口是否被占用：`netstat -tlnp | grep 8317`
- 查看容器日志：`docker logs cli-proxy-api`
- 验证配置文件语法

## 安全建议

1. **保护 API Key**：不要将配置文件提交到公共仓库
2. **使用强密码**：设置复杂的认证密钥
3. **定期更新**：及时更新到最新版本获取安全补丁
4. **限制访问**：配置防火墙限制访问来源

## 开发贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支
3. 提交更改
4. 创建 Pull Request

## 许可证

MIT License

## 链接

- [项目主页](https://github.com/miaoge2026/CLIProxyAPI)
- [Docker Hub](https://hub.docker.com/r/eceasy/cli-proxy-api)
- [问题反馈](https://github.com/miaoge2026/CLIProxyAPI/issues)

## 更新日志

### v1.0 (2026-03-27)
- 初始版本发布
- 支持一键安装和管理
- 自动 Docker 环境检测
- 交互式菜单支持