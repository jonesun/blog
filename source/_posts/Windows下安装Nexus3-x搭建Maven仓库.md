---
title: Windows下安装Nexus3.x搭建Maven仓库
categories: maven
tags:
  - maven
  - gradle
  - jonesun
abbrlink: c1ff8d1f
date: 2018-02-09 11:00:13
---

使用android studio或者idea开发应用时，除了可以依赖本地的库之外，还可以依赖网上（公有maven服务器、私有maven服务器、jcenter等）。如果是依赖本地的，必须要将依赖的module和主工程放在一个project里面，这就导致了每个project都需要配置这些依赖关系，如果是公司内多个工程依赖同一个公司内部的控件，控件有更新时，同步非常麻烦，但公司内部的控件不可能部署到公有maven服务器上，所以有必要搭建一个局域网内的maven服务器，方便管理公司内部的公共库。

<!-- more -->

## Nexus ##
> 3.x版本只能运行在JVM8及以上

本地内部仓库在本地构建nexus私服的好处：

1. 加速构建、稳定；
2. 节省带宽、节省中央maven仓库的带宽；
3. 控制和审计；
4. 能够部署第三方构件；
5. 可以建立本地内部仓库、可以建立公共仓库

![image](https://github.com/jonesun/blog/blob/master/source/image/Windows%E4%B8%8B%E5%AE%89%E8%A3%85Nexus3-x%E6%90%AD%E5%BB%BAMaven%E4%BB%93%E5%BA%93/0.png?raw=true) 


[Nexus下载](https://www.sonatype.com/download-sonatype-trial?submissionGuid=8d76d833-cc25-4b42-8c46-123de611dbcb)
![image](https://github.com/jonesun/blog/blob/master/source/image/Windows%E4%B8%8B%E5%AE%89%E8%A3%85Nexus3-x%E6%90%AD%E5%BB%BAMaven%E4%BB%93%E5%BA%93/1.png?raw=true) 



下载了3.x - OS X的源码包之后，解压文件得到两个目录：
nexus-xxx：该目录包含了Nexus运行时所需要的文件，如启动脚本等。
sonatype-work：该目录包含了Nexus生成的配置文件，日志文件，仓库文件等。

运行
cmd 到nexus-xxx\bin文件夹 输入
```
nexus /run
//其他命令
start：在后台启动服务，不在界面上打印任何启动或者运行时信息。
run：启动服务，但是在界面上打印出启动信息以及运行时信息以及日志信息。
stop：关闭服务
status：查看nexus运行状态
restart：重启服务
force-reload：强制重载一遍配置文件，然后重启服务
```

安装为服务
```
nexus.exe /install <optional-service-name> #安装
nexus.exe /start <optional-service-name> #开始
nexus.exe /stop <optional-service-name> #结束
nexus.exe /uninstall <optional-service-name> #卸载
#其中<optional-service-name>为服务的名称，可自定义
```

浏览器访问 http://localhost:8081/
![image](https://github.com/jonesun/blog/blob/master/source/image/Windows%E4%B8%8B%E5%AE%89%E8%A3%85Nexus3-x%E6%90%AD%E5%BB%BAMaven%E4%BB%93%E5%BA%93/2.png?raw=true) 

## 创建代码仓库 ##

> 默认登录用户名密码(admin admin123)

Nexus的主要的仓库类型：
- hosted（宿主）：宿主仓库主要用于存放项目部署的构件、或者第三方构件用于提供下载。
- proxy（代理）：代理仓库就是对远程仓库的一种代理，从远程仓库下载构件和插件然后缓存在Nexus仓库中
- group（仓库组）：对我们已经配置完的仓库的一种组合策略。

Nexus内置的仓库就已经包含了主要的仓库类型：
- maven-central：代理中央仓库、策略为Release、只会下载和缓存中央仓库中的发布版本构件。
- maven-releases：策略为Release的宿主仓库、用来部署组织内部的发布版本内容。
- maven-snapshots：策略为Snapshot的宿主仓库、用来部署组织内部的快照版本内容。
- maven-public：该仓库将上述所有策略为Release的仓库聚合并通过一致的地址提供服务。
- nuget-hosted：用来部署nuget构件的宿主仓库
- nuget.org-proxy：代理nuget远程仓库，下载和缓冲nuget构件。
- nuget-group：该仓库组将nuget-hosted与nuget.org-proxy仓库聚合并通过一致的地址提供服务。
- maven-public：该仓库组将maven-central，maven-releases与maven-snapshots仓库聚合并通过一致的地址提供服务。


点击 Repository 下 Repositories 创建仓库

![image](https://github.com/jonesun/blog/blob/master/source/image/Windows%E4%B8%8B%E5%AE%89%E8%A3%85Nexus3-x%E6%90%AD%E5%BB%BAMaven%E4%BB%93%E5%BA%93/3.png?raw=true) 

## Gradle打包上传 ##

### idea ###
新建gradle项目，在build.gragle中编写配置
```
group 'com.example.mylibrary'
version '1.0-SNAPSHOT'

apply plugin: 'java'
apply plugin: 'maven'

sourceCompatibility = 1.8

uploadArchives {
    repositories.mavenDeployer {
        repository(url:"http://192.168.31.6:8081/repository/colorfulworld/") {
            authentication(userName:"admin", password:"admin123")
        }
        pom.version="1.0"
        pom.artifactId="javaUtils"
        pom.groupId="com.example"
    }
}

repositories {
    mavenCentral()
}

dependencies {
    testCompile group: 'junit', name: 'junit', version: '4.12'
}

```
> 运行 uploadArchives 进行上传

![image](https://github.com/jonesun/blog/blob/master/source/image/Windows%E4%B8%8B%E5%AE%89%E8%A3%85Nexus3-x%E6%90%AD%E5%BB%BAMaven%E4%BB%93%E5%BA%93/4.png?raw=true) 

### android studio ###

新建app项目，然后新建库(android.library 或者 java.library)，在build.gragle中编写配置
```
apply plugin: 'com.android.library'
apply plugin: 'maven'

//...

uploadArchives {
    repositories {
        mavenDeployer {
            repository(url: "http://192.168.31.6:8081/repository/colorfulworld/") {
                authentication(userName: "admin", password: "admin123")
            }

            pom.groupId = 'com.example.mylibrary'
            pom.artifactId = 'utils'
            pom.version = '0.0.1'

            pom.project {
                licenses {
                    license {
                        name 'The Apache Software License, Version 2.0'
                        url 'http://www.apache.org/licenses/LICENSE-2.0.txt'
                    }
                }
            }
        }
    }
}
```
> 运行 uploadArchives 进行上传

![image](https://github.com/jonesun/blog/blob/master/source/image/Windows%E4%B8%8B%E5%AE%89%E8%A3%85Nexus3-x%E6%90%AD%E5%BB%BAMaven%E4%BB%93%E5%BA%93/5.png?raw=true) 

## 查看 ##
![image](https://github.com/jonesun/blog/blob/master/source/image/Windows%E4%B8%8B%E5%AE%89%E8%A3%85Nexus3-x%E6%90%AD%E5%BB%BAMaven%E4%BB%93%E5%BA%93/6.png?raw=true) 

## 项目引用 ##

配置 Project 的build.gradle文件：
```
allprojects {
    repositories {
        maven { url "http://192.168.31.6:8081/repository/colorfulworld/" }
        google()
        jcenter()
    }
}
```

然后在 module 的 build.gradle 中添加依赖即可：

```

//compile 'com.example.mylibrary:utils:0.0.1'

implementation 'com.example.mylibrary:utils:0.0.1'

```