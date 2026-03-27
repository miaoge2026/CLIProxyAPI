# 🔒 安全政策

## 📋 支持的版本

请使用以下表格查看当前支持的安全更新版本：

| 版本 | 支持状态 | 支持结束日期 |
|------|----------|-------------|
| 2.0.x | ✅ 完全支持 | 待定 |
| 1.0.x | ⚠️ 有限支持 | 2026-06-30 |
| < 1.0 | ❌ 不再支持 | 2026-03-31 |

## 🔍 报告安全漏洞

### 如何报告

**请通过以下方式报告安全漏洞：**

1. **发送电子邮件至：** security@cli-proxy-api.com
2. **GitHub 安全公告：** https://github.com/router-for-me/CLIProxyAPI/security/advisories

**不要**在公共 GitHub Issues 中报告安全漏洞。

### 报告内容

请包含以下信息，以便我们更好地理解和处理您的报告：

- 漏洞的详细描述
- 受影响版本
- 复现步骤
- 潜在影响
- 建议的修复方案（如果有的话）

### 报告模板

```
主题: [SECURITY] 漏洞报告 - [漏洞类型]

漏洞描述:
[详细描述漏洞]

受影响版本:
[例如: v1.0.0 - v2.0.0]

复现步骤:
1. [第一步]
2. [第二步]
3. [第三步]

潜在影响:
[描述可能的危害]

建议修复:
[可选: 您认为的修复方案]
```

## ⏰ 响应时间

我们将按照以下时间线处理安全漏洞报告：

| 严重程度 | 响应时间 | 修复时间 | 披露时间 |
|----------|----------|----------|----------|
| 严重 | 24 小时内 | 7 天内 | 修复后立即 |
| 高 | 48 小时内 | 14 天内 | 修复后立即 |
| 中 | 72 小时内 | 30 天内 | 修复后 |
| 低 | 1 周内 | 90 天内 | 修复后 |

## 🛡️ 安全最佳实践

### 安装和配置

1. **使用最新版本：**
   ```bash
   # 定期检查更新
   ./cli-proxy.sh update
   ```

2. **安全配置：**
   ```yaml
   # 在 config.yaml 中启用安全功能
   security:
     cors:
       enabled: true
       allowed_origins: ["https://your-domain.com"]
     ip_whitelist:
       enabled: true
       allowed_ips: ["127.0.0.1"]
   ```

3. **使用强密码：**
   ```yaml
   auth:
     keys:
       - "complex-secret-key-minimum-32-characters"
   ```

### API Key 管理

1. **保护 API Key：**
   ```bash
   # 设置严格的文件权限
   chmod 600 ~/CLIProxyAPI/config.yaml
   chown root:root ~/CLIProxyAPI/config.yaml
   ```

2. **定期轮换密钥：**
   ```bash
   # 创建备份
   ./cli-proxy.sh backup
   
   # 更新 API Key
   ./cli-proxy.sh config
   
   # 重启服务
   ./cli-proxy.sh restart
   ```

3. **不要提交 API Key 到版本控制：**
   ```bash
   # .gitignore 应该包含
   config.yaml
   auths/
   *.key
   *.pem
   ```

### 网络安全

1. **配置防火墙：**
   ```bash
   # 仅允许特定 IP 访问
   ufw allow from 192.168.1.0/24 to any port 8317
   ```

2. **使用 SSL/TLS：**
   ```yaml
   server:
     ssl:
       enabled: true
       cert_path: "/app/cert.pem"
       key_path: "/app/key.pem"
   ```

3. **限制访问频率：**
   ```yaml
   features:
     rate_limit:
       enabled: true
       requests_per_minute: 60
   ```

### 监控和审计

1. **启用监控：**
   ```bash
   # 启动监控组件
   docker-compose --profile monitoring up -d
   ```

2. **定期检查日志：**
   ```bash
   # 查看错误日志
   ./cli-proxy.sh logs
   
   # 查看访问日志
   tail -f ~/CLIProxyAPI/logs/access.log
   ```

3. **设置告警：**
   ```yaml
   monitoring:
     enabled: true
     metrics:
       enabled: true
   ```

## 🔄 安全更新

### 更新策略

- **安全补丁：** 将在确认漏洞后 24-72 小时内发布
- **安全公告：** 将在 GitHub Security Advisories 和邮件列表中发布
- **版本支持：** 每个主要版本支持 12 个月

### 更新通知

订阅安全更新通知：

- GitHub Watch: [https://github.com/router-for-me/CLIProxyAPI/watchers](https://github.com/router-for-me/CLIProxyAPI/watchers)
- 邮件列表: security-announce@cli-proxy-api.com
- RSS Feed: [https://github.com/router-for-me/CLIProxyAPI/security/advisories.atom](https://github.com/router-for-me/CLIProxyAPI/security/advisories.atom)

## 🔒 安全功能

### 内置安全功能

1. **认证和授权**
   - API Key 认证
   - 客户端密钥验证
   - 权限控制

2. **速率限制**
   - 请求频率限制
   - IP 限制
   - API Key 限制

3. **输入验证**
   - 配置验证
   - 请求验证
   - 响应验证

4. **日志和审计**
   - 访问日志
   - 错误日志
   - 安全日志

5. **监控和告警**
   - 异常检测
   - 性能监控
   - 安全告警

### 推荐的安全配置

```yaml
# 安全配置示例
security:
  cors:
    enabled: true
    allowed_origins: ["https://your-domain.com"]
  
  ip_whitelist:
    enabled: true
    allowed_ips: ["127.0.0.1", "192.168.1.0/24"]
  
  rate_limit:
    enabled: true
    requests_per_minute: 60
    burst_size: 10

monitoring:
  enabled: true
  metrics:
    enabled: true
  health_check:
    enabled: true

logging:
  enabled: true
  level: "info"
  filter_sensitive: true
```

## 📞 联系信息

### 安全团队

- **安全邮箱：** security@cli-proxy-api.com
- **PGP 密钥：** [下载 PGP 密钥](https://cli-proxy-api.com/pgp-key.asc)
- **GitHub：** [https://github.com/security](https://github.com/security)

### 紧急联系

如需紧急安全协助，请发送邮件到 security@cli-proxy-api.com，并在主题中标注 [URGENT]。

## 📝 漏洞披露政策

### 私有披露流程

1. **发现漏洞：** 研究人员发现安全漏洞
2. **私下报告：** 通过安全渠道报告漏洞
3. **确认收到：** 维护者确认收到报告
4. **调查评估：** 维护者调查漏洞并评估影响
5. **开发修复：** 开发安全修复补丁
6. **测试验证：** 测试修复方案
7. **发布更新：** 发布安全更新
8. **公开披露：** 在安全公告中公开漏洞详情

### 公开披露流程

如果漏洞被公开披露，我们将：

1. 在 24 小时内确认漏洞
2. 评估漏洞影响
3. 开发并发布修复
4. 发布安全公告
5. 提供迁移指南

## 🎯 致谢

我们感谢所有负责任地披露安全漏洞的安全研究人员和用户。您的贡献帮助我们保持项目的安全。

### 安全研究人员

- [安全研究人员列表](https://github.com/router-for-me/CLIProxyAPI/security)
- [荣誉墙](https://cli-proxy-api.com/hall-of-fame)

---

**最后更新：** 2026-03-27
**版本：** 2.0