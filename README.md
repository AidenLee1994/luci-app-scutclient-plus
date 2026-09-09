# luci-app-scutclient-plus

> LuCI web UI for [scutclient](https://github.com/scutclient/scutclient) — OpenWrt campus-network authentication plugin for South China University of Technology (SCUT / 华南理工大学) DRCOM broadband.

![OpenWrt](https://img.shields.io/badge/OpenWrt-21.xx%20~%2025.xx-blue)
![License](https://img.shields.io/badge/license-Apache--3.0-green)
![LuCI](https://img.shields.io/badge/LuCI-compatible-brightgreen)

**关键词 / Keywords:** OpenWrt · LuCI · scutclient · drcom · SCUT · 华南理工大学 · 校园网 · 宽带认证 · campus network · broadband authentication · 802.1x · OpenWrt plugin · router authentication

---

## 项目简介 / About

`luci-app-scutclient-plus` 是 [scutclient](https://github.com/scutclient/scutclient) 的 LuCI 图形化管理界面，专为华南理工大学校园网 DRCOM 认证场景设计。安装后可在 OpenWrt 路由器的 Web 管理页面中完成认证配置、服务启停、实时日志查看及网络状态检测，无需登录 SSH。

This package provides a LuCI graphical front-end for `scutclient`, a DRCOM protocol client used on the SCUT campus network. After installation you can manage all authentication settings, start/stop the service, view live logs, and check internet connectivity directly from the OpenWrt web interface — no SSH required.

---

## 兼容性 / Compatibility

| OpenWrt 版本 | 支持状态 |
|---|---|
| 21.02.x | ✅ 支持 |
| 22.03.x | ✅ 支持 |
| 23.05.x | ✅ 支持 |
| 24.10.x | ✅ 支持 |
| 25.x (snapshot) | ✅ 支持 |

OpenWrt 22.03 引入了 `luci-lua-runtime` 包；本插件使用条件依赖写法，在 21.02 上自动跳过该依赖，由已有的 `luci-compat` 提供 Lua 运行时，无需手动调整。

---

## 功能列表 / Features

- 状态页：一键查看认证状态、当前公网 IP，支持重拨和下线操作
- 配置页：用户名/密码、Drcom 版本、认证服务器 IP、主机名、允许上网时间等全部通过 Web 界面设置
- 日志页：实时滚动显示 `/tmp/scutclient.log` 末尾 75 行，无需 SSH
- 调试包下载：一键打包网络配置、DHCP 租约、scutclient 日志为 `.tar` 文件，方便反馈问题
- 主机名自动生成：默认生成随机 `DESKTOP-XXXXXXX` 格式主机名，也可从 DHCP 租约中选取
- 开机自启：安装后自动 `enable` 服务，路由重启后无需手动操作
- 菜单位置可调：支持将菜单项移动到侧栏靠后位置，避免遮挡其他服务

---

## 依赖 / Dependencies

| 包名 | 说明 |
|---|---|
| `scutclient` | 核心认证客户端（需单独编译或安装） |
| `luci-compat` | LuCI 兼容层，21.xx–25.xx 均需 |
| `luci-lib-nixio` | Lua nixio 文件系统库 |
| `luci-lua-runtime` | 仅 22.03+ 需要，21.xx 上自动跳过 |

---

## 编译安装 / Build & Install

### 从源码编译（推荐）

注意：/path/to/openwrt 指的是你 openwrt源码存放的路径。

可以使用 L 大佬维护的 Lede项目：https://github.com/coolsnowwolf/lede
也可以使用 天灵大佬的项目：https://github.com/immortalwrt/immortalwrt

```bash
# 1. 将本仓库放入 feeds
cp -r luci-app-scutclient-plus /path/to/openwrt/feeds/luci/applications/

# 2. 更新并安装 feeds
cd /path/to/openwrt
./scripts/feeds update luci
./scripts/feeds install -a -p luci

# 3. 进入 menuconfig 勾选
make menuconfig
# 路径: LuCI → Applications → luci-app-scutclient-plus

# 4. 编译
make package/luci-app-scutclient-plus/compile V=s
```

编译产物为 `bin/packages/<arch>/luci/luci-app-scutclient-plus_*.ipk`，可通过 LuCI 软件包页面或 `opkg install` 安装到路由器。

### 直接安装 ipk

```bash
opkg install luci-app-scutclient-plus_*.ipk
```

安装完成后刷新浏览器，在 LuCI 顶栏 **服务 → 华南理工大学客户端** 中访问。

---

## 配置说明 / Configuration

首次配置建议按页面提示依次完成三步：

1. **设置 Wi-Fi**：配置接入校园网的无线网卡（仅无线接入场景需要）
2. **设置 IP**：在网络→接口中配置 WAN 口 IP，有线接入同理
3. **修改管理密码**：强烈建议修改路由器默认密码后再接入校园网

核心认证参数：

| 参数 | 说明 |
|---|---|
| 拨号用户名 | 学号或学校分配的宽带账号 |
| 拨号密码 | 宽带认证密码（页面中以掩码显示） |
| Drcom 版本 | 根据所在校区和接入点选择，默认值适用于大多数场景 |
| DrAuthSvr.dll 版本哈希 | 与 Drcom 版本对应，默认值适用于大多数场景 |
| 服务器 IP | 认证服务器地址，默认 `202.38.210.131` |
| 允许上网时间 | 断网后等待重连的起始时间，格式 `H:MM`，如 `6:15` |
| 主机名 | 向认证服务器上报的设备名，默认随机生成 |

---

## 网络状态检测 / Connectivity Check

状态页通过访问 `http://whatismyip.akamai.com` 来判断联网状态：

- **已联网**：返回公网 IPv4 地址
- **未登录**：能访问但返回内容不是 IP（通常是重定向到认证页）
- **无网络**：请求超时或无响应

---

## 安全声明 / Security Notice

**本插件为华南理工大学校园网合法用户设计，仅供授权使用。**

- 本插件通过 LuCI Web 界面与 `scutclient` 交互，不绕过、不破解校园网认证系统，认证凭据通过标准 UCI 机制存储于路由器本地。
- 调试包（`scutclient-log.tar`）包含网络配置、DHCP 租约等信息，**请勿将调试包发布到公开渠道**，仅提供给可信任的维护人员用于排查问题。
- 密码字段在页面中以掩码显示，但以明文存储于路由器 `/etc/config/scutclient`。建议限制路由器管理界面的访问来源，并定期修改管理密码。
- **禁止将本插件用于任何违反华南理工大学网络使用规定或中华人民共和国相关法律法规的用途。**
- 本项目的网络状态检测功能会向 `whatismyip.akamai.com` 发出 HTTP 请求以获取公网 IP，该请求不携带任何认证凭据。

---

## 故障排查 / Troubleshooting

认证失败时，优先检查以下几点：

1. Drcom 版本和哈希值是否与所在校区一致——不同接入区域可能使用不同版本
2. 主机名是否符合学校要求（部分接入点会校验主机名格式）
3. 服务器 IP 是否可达：`ping 202.38.210.131`
4. 在日志页查看实时日志，或下载调试包后检查 `scutclient.log`

---

## 许可证 / License

[Apache License 3.0](LICENSE)

---

## 致谢 / Acknowledgements

- [scutclient](https://github.com/scutclient/scutclient) — 核心 DRCOM 认证客户端
- OpenWrt LuCI 框架
- 华南理工大学计算机科学与工程学院

---

*维护者：一名在华工待了八年的科研狗，我会一直维护到我离开华工*

