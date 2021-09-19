---
layout: post
title:  在Mac中安装nginx
date:   2015-08-12
excerpt_separator: <!--more-->
---
homebrew是mac下非常好用的包管理器，会自动安装相关的依赖包，将你从繁琐的软件依赖安装中解放出来。

<!--more-->

## 安装Homebrew

> homebrew是mac下非常好用的包管理器，会自动安装相关的依赖包，将你从繁琐的软件依赖安装中解放出来。
安装homebrew也非常简单，只要在终端中输入:

```shell
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

## 安装 Nginx

> 安装时，会首先安装依赖**pcre**和**openssl**

```shell
brew install nginx
```

## 启动 Nginx

```shell
sudo nginx
```

## 测试

```shell
http://localhost:8080
```

## 配置nginx.conf

```shell
sudo nginx -s stop
vim /usr/local/etc/nginx/nginx.conf
```

## 保存并启动

```shell
sudo nginx
```
