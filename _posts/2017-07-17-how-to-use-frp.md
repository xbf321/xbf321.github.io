---
layout: post
title:  frp 配置和使用
date:   2017-07-17
excerpt_separator: <!--more-->
---
## frp 作用

* 利用处于内网或防火墙后的机器，对外网环境提供 http 或 https 服务。
* 对于 http, https 服务支持基于域名的虚拟主机，支持自定义域名绑定，使多个域名可以共用一个80端口。
* 利用处于内网或防火墙后的机器，对外网环境提供 tcp 和 udp 服务，例如在家里通过 ssh 访问处于公司内网环境内的主机。

<!--more-->

详细参见[官网](https://github.com/fatedier/frp/blob/master/README_zh.md)

## 服务端配置（公网）

### 下载

使用 **wget** 指令下载到我们制定的目录中，如：*/home/tools/frp*

```shell
sudo wget https://github.com/fatedier/frp/releases/download/v0.13.0/frp_0.13.0_linux_amd64.tar.gz
```

### 解压

```shell
sudo tar -zxvf frp_0.13.0_linux_amd64.tar.gz
```

因为作为服务端，可以把客户端文件删掉，使用 *rm* 指令。

```shell
sudo rm -f frpc
sudo rm -f frpc.ini
```

### 编辑 *frps.ini* 配置文件

可以参考官网范例。
我这删掉了一些不用的内容，是个简化版的配置文件。

```shell
[common]
bind_port = 7000
vhost_http_port = 80
dashboard_port = 7500
dashboard_user = xxx
dashboard_pwd = xxx
log_file = /home/tools/frp/frps.log
subdomain_host = xxx.me

[ssh]
listen_port = 422
auth_token = xxx

[nas]
type = http
auth_token = xxx

[nas-rpc]
type = http
auth_token = xxx
```

### 启动服务

```shell
./frps -c ./frps.ini
```

### Systemd 管理

因为我的公网机器是 Centos ，所以用的是 Systemd 管理。

编写 *frp service* 文件

```shell
sudo vim /usr/lib/systemd/system/frps.service
```

内容如下：

```shell
[Unit]
Description=frps
After=network.target

[Service]
TimeoutStartSec=30
ExecStart=/home/tools/frp/frps -c /home/tools/frp/frps.ini
ExecStop=/bin/kill $MAINPID

[Install]
WantedBy=multi-user.target
```

开机启动和查看状态

```shell
systemctl enable frps
systemctl start frps
systemctl status frps

```

## 客户端配置（内网）

因为 frp 下载自带客户端和服务端，所以这里，可以参考上面的。

下载之后，同样删掉 **服务端** 文件。

### 编辑 *fprc.ini* 配置文件

```shell
[common]
server_addr = 1.1.1.1
server_port = 7000
log_file = /home/q/tools/frp/frpc.log
auth_token = xxx

[ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = 422

[nas]
type = http
local_ip = 127.0.0.1
local_port = 8888
subdomain = nas

[nas-rpc]
type = http
local_ip = 127.0.0.1
local_port = 6800
subdomain = rpc
```

> 客户端和服务器端要一一对应，比如 [xxx]

### 启动服务

```shell
./frpc -c ./frpc.ini
```

### 后台运行

服务端虽然启动了，但是不能就这么算了。这个进程最好可以向Windows服务那样拥有一个状态，可以开机自启。我们使用Linux下常用的进程管理器supervisor来管理该服务。

首先需要安装supervisor。

```shell
sudo apt-get install supervisor
```

然后在/etc/supervisor/conf.d下新建一个配置文件frp.conf，输入以下内容。command应该是你放置frp软件的位置。

```shell
[program:frp]
command = /home/q/tools/frp/frpc -c /home/q/tools/frp/frpc.ini
autostart = true
```

然后启动supervisor，如果事先已经安装好了supervisor那么就重新启动。之后查看一下supervisor的运行状态，看看frp是否已在运行。

```shell
# 重启supervisor
sudo systemctl restart supervisor
# 查看supervisor运行状态
sudo supervisorctl status
```
