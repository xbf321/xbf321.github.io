---
layout: post
title:  树莓派安装 Samba
date:   2017-07-21
excerpt_separator: <!--more-->
---

介绍如何在树莓派中安装 Samba 服务。
<!--more-->

## 安装 samba

```shell
sudo apt-get install samba samba-common-bin
```

## 配置 samba

先备份 smb.conf

```shell
sudo cp smb.conf smb.conf.bak
```

然后编辑 smb.conf，在文件的最后，添加以下内容

```shell
[nas]
   comment = NAS Storage
   path = /home/q/nas
   browseable = yes
   writable = yes
   create mask = 0664
   directory mask = 0775
```

设置文件夹权限

```shell
sudo chmod 777 /home/q/nas
```

## 添加访问用户和密码

```shell
sudo useradd raspsmb
sudo smbpasswd -a raspsmb
```

## 启动服务

```shell
sudo /etc/init.d/samba restart
```
