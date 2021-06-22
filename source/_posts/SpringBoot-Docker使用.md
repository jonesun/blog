---
title: SpringBoot-Docker使用
tags:
  - java
  - springboot
categories:
  - java
  - springboot
abbrlink: 90c59710
date: 2020-12-17 10:03:02
---


SpringBoot 2.4.0开始官方插件增加了对docker的支持

# 阿里云

登录阿里云[容器镜像服务](https://cr.console.aliyun.com/cn-shanghai/instances/repositories)

创建命名空间

获取访问凭证(这里为了演示方便,采用固定密码方式，企业项目需根据实际情况设置密码或子账号访问等)

pom.xml检查是否为:

```xml
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.4.0</version>
        <relativePath/> <!-- lookup parent from repository -->
    </parent>
```

插件中加入docker配置

```xml
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <image>
                        <name>registry.cn-shanghai.aliyuncs.com/jonesun/${project.artifactId}:${project.version}</name>
                        <!-- 执行完build 自动push -->
                        <publish>true</publish>
                        <!-- 默认build访问的是docker.io/paketobuildpacks/builder:base 这个在国内访问较慢，可从阿里云镜像中心搜索用户公开的镜像代替 -->
                        <builder>registry.cn-shanghai.aliyuncs.com/sannmizu/builder:base</builder>
                        <!-- 默认runImage访问的是docker.io/paketobuildpacks/run:base-cnb 如果在国内访问较慢，可从阿里云镜像中心搜索用户公开的镜像代替 -->
<!--                        <runImage>registry.cn-hangzhou.aliyuncs.com/paketo-buildpacks/run:base-cnb</runImage>-->
                    </image>
                    <!--配置构建远程机信息，本机不用配置-->
                    <docker>
<!--                        &lt;!&ndash;远程docker daemon的连接地址和端口(如果本地未安装docker的话)&ndash;&gt;-->
<!--                        <host>tcp://192.168.99.100:2375</host>-->
<!--                        &lt;!&ndash;如果使用https协议需要设置为true&ndash;&gt;-->
<!--                        <tlsVerify>false</tlsVerify>-->
                        <publishRegistry>
                            <username>xxx</username>
                            <password>xxx</password>
                            <url>registry.cn-shanghai.aliyuncs.com</url>
                        </publishRegistry>
                    </docker>
                </configuration>
            </plugin>
```

maven插件有两种方式构建镜像:

插件与本地docker daemon通信来构建镜像，需要在windows安装docker
插件使用远程连接与docker daemon通信来构建镜像，需要远程服务器上面的docker开启远程连接

安装[私有镜像仓库](https://mp.weixin.qq.com/s?__biz=MzU1Nzg4NjgyMw==&mid=2247486525&idx=1&sn=01103c0629f36a8e9d511acb26fae225&scene=21#wechat_redirect)

拉取镜像

登录
docker login --username=sunr922@163.com registry.cn-shanghai.aliyuncs.com

docker pull registry.cn-shanghai.aliyuncs.com/jonesun/tool:[镜像版本号]

docker run -p 8888:8888 registry.cn-shanghai.aliyuncs.com/jonesun/tool:[镜像版本号]
