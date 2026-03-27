---
name: 🐛 Bug 报告
about: 创建一个 bug 报告来帮助我们改进
title: '[BUG] '
labels: ['bug', 'triage']
assignees: ''

---

## 🐛 Bug 描述

请在此处提供详细的 bug 描述。

**清晰简洁地描述问题：**
- 发生了什么？
- 期望的行为是什么？
- 实际的行为是什么？

## 🔍 复现步骤

请提供复现问题的详细步骤：

1. 第一步
2. 第二步
3. 第三步
4. ...

**示例：**
1. 运行命令 `./cli-proxy.sh install`
2. 编辑配置文件 `~/CLIProxyAPI/config.yaml`
3. 重启服务 `./cli-proxy.sh restart`
4. 查看日志发现错误

## 📋 预期行为

请描述您期望发生的行为。

## 🚫 实际行为

请描述实际发生的行为，包括任何错误信息。

## 🖥️ 环境信息

请提供您的环境信息：

- **操作系统**: [例如: Ubuntu 22.04, CentOS 8, Alpine 3.18]
- **架构**: [例如: amd64, arm64]
- **Docker 版本**: [例如: Docker 24.0.5, Docker Compose 2.20.3]
- **脚本版本**: [例如: v2.0, commit hash]
- **Shell**: [例如: bash 5.1, zsh 5.8]

**获取环境信息命令：**
```bash
# 操作系统信息
cat /etc/os-release

# Docker 信息
docker --version
docker compose version

# 脚本版本
./cli-proxy.sh --version 2>/dev/null || echo "版本信息不可用"

# 系统资源
free -h
df -h
```

## 📝 相关日志

请提供相关的日志信息：

```bash
# 查看服务日志
./cli-proxy.sh logs

# 查看容器状态
docker ps -a
docker inspect cli-proxy-api

# 查看系统日志
journalctl -u cli-proxy-api.service -n 50
```

## 🔧 可能的解决方案

如果您知道如何修复这个问题，请在此处描述。

## 📸 截图

如果适用，请添加截图来帮助解释您的问题。

## 🔍 其他信息

请添加任何其他关于这个问题的信息。

---