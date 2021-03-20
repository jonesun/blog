---
title: nacos
tags:
---

下载地址：https://github.com/alibaba/nacos/releases
本文版本：1.0.0

下载完成之后，解压。根据不同平台，执行不同命令，启动单机版Nacos服务：

Linux/Unix/Mac：
```shell
sh startup.sh -m standalone
```
Windows：

```shell
cmd startup.cmd -m standalone
```

启动完成之后，访问：http://127.0.0.1:8848/nacos/，可以进入Nacos的服务管理页面, 默认用户名密码为：nacos