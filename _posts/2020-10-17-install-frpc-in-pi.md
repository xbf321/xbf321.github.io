---
layout: post
title:  树莓派安装 frpc 客户端
date:   2020-10-17
excerpt_separator: <!--more-->
---

## 目的

* 实现内网穿透，外网可以访问家里设备。比如访问路由器、树莓派。
* 访问家里打印机，便于在外网打印文件。

## 下载 frp

前往[releases](https://github.com/fatedier/frp/releases)页面下载相应架构的应用包，这里是在树莓派中使用，所以需要下载 ARM 包。

```shell
# 进入 /home/pi/Downloads
wget https://github.com/fatedier/frp/releases/download/v0.37.1/frp_0.37.1_linux_arm.tar.gz
```

## 解压

```shell
tar -zxvf frp_0.37.1_linux_arm.tar.gz
```

## 配置 frpc

下载包中，包含服务端和客户端，这里我们只需要配置客户端，也就是 **frpc.ini**

```shell
[common]
server_addr = domain
server_port = port
token = da013ce4-2a80-4858-aacd-3af80d6cae46

[ssh-pi]
type = tcp
local_ip = 0.0.0.0
local_port = 22
remote_port = 19042

[printer]
type = tcp
local_ip = 192.168.31.10
local_port = 9100
remote_port = 19100
```

## 创建服务

进入 **/lib/systemd/system** 目录，新建 **frpc.service**，内容如下：

```shell
[Unit]
Description=Frp Client Service
After=network.target

[Service]
Type=simple
User=nobody
Restart=on-failure
RestartSec=5s
ExecStart=/home/pi/Downloads/frp/frpc -c /home/pi/Downloads/frp/frpc.ini
ExecReload=/home/pi/Downloads/frp/frpc reload -c /home/pi/Downloads/frp/frpc.ini
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
```

## 设置开机启动

```shell
# 启动服务
sudo systemctl start frpc.service
# 停止服务
sudo systemctl stop frpc.service
# 重启
sudo systemctl restart frpc.service
# 查看服务状态
sudo systemctl status frpc.service
# 开启启动
sudo systemctl enable frpc.service
```
