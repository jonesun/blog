---
title: windows上使用jenkins构建并部署springboot项目
tags:
  - jenkins
categories:
  - jenkins
abbrlink: 5b02ceab
date: 2021-07-06 16:56:45
urlname:
---

# 创建任务

在[安装并配置好Jenkins](/20210706/jenkins/a15eda66/)后，我们来构建并部署springboot项目

创建任务首先准备一个SpringBoot项目上传到上面凭据所在的git托管网站中，以便Jenkins可以正常拉取源码

新建Item-选择【构建一个Maven项目】(如果这里没有这个选项，回到上篇安装插件Maven Integration并重启Jenkins)

![new-job](new-job.png)

## JDK

选择该项目构建时的Java版本(如果这里没有所需的版本，回到上篇配置配置JDK、Maven、Git环境，新增即可)

## 源码管理中

选择Git，填写仓库地址，选择之前添加的凭证

## 构建触发器

这里先选择Build whenever a SNAPSHOT dependency is built

如果需要自动构建则勾选对应webhook，这里我们选择Gitee webhook(如果没有这个选项需要安装Gitee插件)，生成Gitee WebHook 密码

![gitee-webhook](gitee-webhook.png)

使用浏览器打开码云对应的项目点开【管理】-【Webhook】,添加相关配置

![add-webhook](add-webhook.png)

## 构建环境

勾选Add timestamps to the Console Output， 代码构建的过程中会将日志打印出来

## Pre Steps

### 部署本地

点击add-pre-build-step,选择【Execute Windows batch command】

![add-pre-build-step](add-pre-build-step.png)

添加批处理所在路径xxx/stop.bat(先将批处理放置到对应目录中)

![execute-windows-batch-command](execute-windows-batch-command.png)

### 部署远程Windows Server

点击add-pre-build-step,选择【Send files or execute commands over SSH】

选择之前配置的SSH Server的远程windows服务器，在Exec command中添加批处理所在路径xxx/stop.bat

> 使用SSH Publishers时一定要勾选【高级】-【Verbose output in console】, 输出日志便于出错时查看具体原因

这个批处理是在构建项目前执行的，一般是停止服务备份jar等，以下是笔者的stop.bat(供参考):

```shell
@echo off
echo stop
set str_time_first_bit="%time:~0,1%"
if %str_time_first_bit%==" " (	
set str_date_time=%date:~0,4%%date:~5,2%%date:~8,2%0%time:~1,1%%time:~3,2%%time:~6,2%
)else ( 	
set str_date_time=%date:~0,4%%date:~5,2%%date:~8,2%%time:~0,2%%time:~3,2%%time:~6,2%
)

set port=8081
for /f "tokens=1-5" %%i in ('netstat -ano^|findstr ":%port%"') do (
    echo kill the process %%m who use the port 
    taskkill /pid %%m -t -f
    goto start
)
:start

cd /d %~dp0

if not exist backup md backup

copy mybatis-sample-0.0.1-SNAPSHOT.jar backup\mybatis-sample-0.0.1-SNAPSHOT-%str_date_time%.jar.jar
 
exit
```

port=8081是因为我的这个项目的运行端口是8081

## Build

在Build中，填写 Root POM 和 Goals and options，也就是构建项目的命令

![build](build.png)

一般SpringBoot项目的命令为

```shell
clean package -Dmaven.test.skip=true
```

## Post Steps

构建后可以做的事情，这里我们选择【Run only if build succeeds】，即构建成功后触发

### 部署本地

点击add-post-build-step,选择【Execute Windows batch command】,添加批处理所在路径

这个批处理一般是启动项目，以下是笔者的start.bat(供参考):

```shell
@echo off
set BUILD_ID=dontKillMe  
echo start

cd /d %~dp0
START javaw -jar mybatis-sample-0.0.1-SNAPSHOT.jar & exit
```

### 部署远程Windows Server

点击add-post-build-step,选择【Send files or execute commands over SSH】

选择之前配置的SSH Server的远程windows服务器，在Exec command中添加批处理所在路径xxx/start.bat

> Transfer set

- name:前面添加的SSH Server
- Source files:要推送的文件
- Remove prefix:文件路径中要去掉的前缀
- Remote directory:要推送到目标服务器上的哪个目录下
- Exec command:目标服务器上要执行的脚本

### 部署远程Linux

点击add-post-build-step,选择【Send files or execute commands over SSH】,选择之前配置的SSH Server的远程Linux服务器

![ssh-ser-ubuntu](ssh-ser-ubuntu.png)

startup.sh(先将sh放置到对应目录中)与windows版的start.bat不太一样(供参考)

```shell
#!/bin/bash 
#export BUILD_ID=dontKillMe这一句很重要，这样指定了，项目启动之后才不会被Jenkins杀掉。
export BUILD_ID=dontKillMe
#!/bin/bash -ile
project=mybatis-sample-0.0.1-SNAPSHOT.jar
pathName=mybatis-sample-0.0.1-SNAPSHOT
cd /root/home/mybatis-sample/


if [ ! -d "backup" ];then
    mkdir backup
else
    echo "backup is exist"
fi

rm -rf backup/$project
cp  $project backup/$project

pid=`ps -ef | grep $dir$project | grep -v grep | awk '{print $2}'`
if [ -n "$pid" ]
then
   kill -9 $pid
   echo "kill"
fi

echo "run"
BUILD_ID=dontkillMe nohup java -jar $project >/dev/null 2>&1 &
echo "run success"
```

> 如果远程执行遇到权限问题，执行chmod +x startup.sh

## 构建设置

可以配置邮件通知等

## 构建后操作

可以添加很多操作

![build-after](build-after.png)

# 构建任务

点击 立即构建 可以开始构建任务，控制台可以看到log输出，如果构建失败，在log中会输出原因

![start-build](start-build.png)

构建成功后就可以浏览器中打开项目测试，至此便完成jenkins构建并部署springboot项目的流程~~~~

如果配置的自动构建的地址，则使用idea编写好代码提交到git后，Jenkins便会自动构建项目

![auto-build](auto-build.png)