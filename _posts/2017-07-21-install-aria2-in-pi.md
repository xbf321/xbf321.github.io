---
layout: post
title:  树莓派安装 Aria2
date:   2017-07-21
excerpt_separator: <!--more-->
---

目前迅雷已经关闭第三方的远程下载功能，在这使用 Aria2 代替。

<!--more-->

## 1. 安装并配置 aria2

### 安装

```shell
sudo apt-get install aria2
```

### 创建配置文件夹

```shell
sudo mkdir /etc/aria2
```

### 创建 session 和配置文件

```shell
sudo touch /etc/aria2/aria2.session
sudo touch /etc/aria2/aria2.conf
```

编辑 */etc/aria2/aria2.conf*

```shell
## 文件保存相关 ##

# 文件保存目录
dir=/home/q/download
# 启用磁盘缓存, 0为禁用缓存, 需1.16以上版本, 默认:16M
disk-cache=32M
# 断点续传
continue=true

# 文件预分配方式, 能有效降低磁盘碎片, 默认:prealloc
# 预分配所需时间: none < falloc ? trunc < prealloc
# falloc和trunc则需要文件系统和内核支持
# NTFS建议使用falloc, EXT3/4建议trunc, MAC 下需要注释此项
#file-allocation=falloc

## 下载连接相关 ##

# 最大同时下载任务数, 运行时可修改, 默认:5
#max-concurrent-downloads=5
# 同一服务器连接数, 添加时可指定, 默认:1
max-connection-per-server=15
# 整体下载速度限制, 运行时可修改, 默认:0（不限制）
#max-overall-download-limit=0
# 单个任务下载速度限制, 默认:0（不限制）
#max-download-limit=0
# 整体上传速度限制, 运行时可修改, 默认:0（不限制）
#max-overall-upload-limit=0
# 单个任务上传速度限制, 默认:0（不限制）
#max-upload-limit=0
# 禁用IPv6, 默认:false
disable-ipv6=true

# 最小文件分片大小, 添加时可指定, 取值范围1M -1024M, 默认:20M
# 假定size=10M, 文件为20MiB 则使用两个来源下载; 文件为15MiB 则使用一个来源下载
min-split-size=10M
# 单个任务最大线程数, 添加时可指定, 默认:5
split=10

## 进度保存相关 ##

# 从会话文件中读取下载任务
input-file=/etc/aria2/aria2.session
# 在Aria2退出时保存错误的、未完成的下载任务到会话文件
save-session=/etc/aria2/aria2.session
# 定时保存会话, 0为退出时才保存, 需1.16.1以上版本, 默认:0
save-session-interval=60

## RPC相关设置 ##

# 启用RPC, 默认:false
enable-rpc=true
# 允许所有来源, 默认:false
rpc-allow-origin-all=true
# 允许外部访问, 默认:false
rpc-listen-all=true
# RPC端口, 仅当默认端口被占用时修改
# rpc-listen-port=6800
# 设置的RPC授权令牌, v1.18.4新增功能, 取代 --rpc-user 和 --rpc-passwd 选项
#rpc-secret=<TOKEN>

## BT/PT下载相关 ##

# 当下载的是一个种子(以.torrent结尾)时, 自动开始BT任务, 默认:true
#follow-torrent=true
# 客户端伪装, PT需要
peer-id-prefix=-TR2770-
user-agent=Transmission/2.77
# 强制保存会话, 即使任务已经完成, 默认:false
# 较新的版本开启后会在任务完成后依然保留.aria2文件
#force-save=false
# 继续之前的BT任务时, 无需再次校验, 默认:false
bt-seed-unverified=true
# 保存磁力链接元数据为种子文件(.torrent文件), 默认:false
bt-save-metadata=true
```

## 启动

```shell
aria2c --enable-rpc --rpc-listen-all=true --rpc-allow-origin-all
```

## 2. 界面操作

### YAAW

这里使用 [YAAW](https://github.com/binux/yaaw) 界面管理远程下载，因为它支持 Chrome 插件，这样，只有服务器开通一个 rpc 的服务，就可以在任意地方下载文件了，不需要在重新部署一个 server 站点。

### webui-aria2

* 解压到  */home/q/www/webui-aria2* 目录

```shell
git clone https://github.com/ziahamza/webui-aria2.git -d /home/q/www/webui-aria2
```

* 配置 *configuration.js*

因为我专门提供了一个对外的 **RPC** 服务，所以在这要修改成自己的 **RPC** 服务。

* 本地运行

```shell
node node-server.js
```

* 后台运行，同样使用 **supervisor** 管理

在 */etc/supervisor/conf.d/* 目录下新建 webui-aria2.conf 文件，填入一下内容：

```shell
[program:webui-aria2]
directory = /home/q/www/webui-aria2
command = node node-server.js
autostart = true
```

重启 **supervisor**

```shell
sudo systemctl restart supervisor
```
