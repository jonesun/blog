---
title: windows上安装jenkins
abbrlink: a15eda66
date: 2021-07-06 14:27:25
tags:
    - jenkins 
categories:
    - jenkins
---

# 安装前准备

## 下载配置jdk

从Jenkins的官网可以看到

![jenkins-jdk](jenkins-jdk.png)

较新的Jenkins需要运行在Java 8 或者 Java 11上，我们安装java8版本，由于Oracle下载jdk需要注册账户，我们下载openjdk，这里推荐 [Liberica OpenJDK](https://bell-sw.com/pages/downloads/)

直接下载zip版本，并在环境变量中配置JAVA_HOME，使用cmd执行java -version查看是否配置成功

> 如果电脑里已经安装了Java环境，直接用java -version验证是否Java8+版本

## 下载安装Git

我们需要使用Jenkins拉取项目源码，故需要先安装下git

从[git](http://git-scm.com/downloads) 官网下载安装即可

命令行输入git --version验证安装是否成功

## 下载配置Maven

目前大多数SpringBoot项目都采用的是Maven的方式进行构建，故为了进行自动构建，需要安装

可以[官网](http://maven.apache.org/download.cgi) 直接下载zip，配置环境变量M2_HOME即可

![maven_home](maven_home.png)

命令行输入mvn -v验证

# 安装配置

windows版直接[官网](https://www.jenkins.io/download/) 下载最新版本即可，如果是实际生产环境建议下载LTS(长期支持版本)

按照提示直接安装即可

![step1](step1.png)

![step2](step2.png)

![这里直接选择本地用户即可](step3.png)

![Jenkins默认端口为8080，可能会与其他软件冲突，可以修改为其他端口，点击【Test-Port】通过即可](step4.png)

![Java运行环境这里默认会显示JAVA_HOME所在的目录](step5.png)

![step6](step6.png)

## 配置

如果前面安装的时候没有修改默认端口为，可以打开配置(Windows版的配置在安装目录的jenkins.xml中)进行配置, 修改--httpPort=8080为其他端口

如果使用nginx代理的话需要加上 --prefix=/jenkins

以下是笔者的配置，供参考(省略了其他配置，不要直接复制，重点在arguments中的修改)

```xml

<service>
  <id>jenkins</id>
  <name>Jenkins</name>
  <description>This service runs Jenkins automation server.</description>
  <env name="JENKINS_HOME" value="%LocalAppData%\Jenkins\.jenkins"/>
  <executable>D:\env\Java\jdk1.8.0_231\bin\java.exe</executable>
  <arguments>-Xrs -Xmx256m -Dhudson.lifecycle=hudson.lifecycle.WindowsServiceLifecycle -jar "C:\Program Files\Jenkins\jenkins.war" --prefix=/jenkins --httpPort=8080 --webroot="%LocalAppData%\Jenkins\war"</arguments>
</service>

```

需要注意的是Windows版的Jenkins的默认工作目录在C:\Windows\System32\config\systemprofile\AppData\Local\Jenkins\.jenkins，如果需要修改，同样在jenkins.xml中搜索修改JENKINS_HOME即可(可修改为env name="JENKINS_HOME" value="%JENKINS_HOME%"，然后环境变量加入JENKINS_HOME)


以上工作完成后，就可以运行jenkins了，需要注意的是Windows的安装版的Jenkins安装时会注册为Windows服务，需要从任务管理器-服务中找到Jenkins重启

## 初始化

浏览器打开http://localhost:8080/(如果配置了prefix，则为http://localhost:8080/jenkins/)

![init1](init1.png)

![init2](init2.png)

![init3](init3.png)

![init4](init4.png)

![init5](init5.png)

![init6](init6.png)

![init7](init7.png)

按照步骤一步步配置即可，需要注意的插件安装推荐的插件如果有安装失败的，一般是网络原因，重试几次即可(如果还不行，可以后面到插件管理里再安装)

## 安装插件

除了初始化配置中安装的插件外，还需要安装：

- Maven Integration：便于新建maven任务
- Publish Over SSH: 用于远程连接服务器
- [Gitee](https://gitee.com/help/articles/4193): 如果是使用码云作为托管网站的推荐安装

打开系统管理(Manage Jenkins) -> 插件管理(Manage Plugins)，选择可选插件，勾选中 Maven Integration 和 Publish Over SSH，点击直接安装

![install-plugin](install-plugin.png)

在安装界面勾选上安装完成后重启 Jenkins

![install-plugin2](install-plugin-2.png)

## 配置JDK、Maven、Git环境

Jenkins集成需要用到Maven、JDK、Git环境， 打开系统管理(Manage Jenkins) -> 全局工具配置(Global Tool Configuration)

![config](config.png)

**新增JDK时，需要去掉自动安装(Install automatically)勾选，才能配置本地Java环境，这里可以配置多个jdk，主要是为了构建项目时使用，与Jenkins运行时的jdk不是一个概念**

## 添加凭据

添加凭据用来从 Git 仓库拉取代码的，打开 凭据 -> 系统 -> 全局凭据 -> 添加凭据, 直接使用用户名和密码，设置Github或者码云等git托管网站的账户信息

![new-credentials](new-credentials.png)

## 添加 SSH Server

SSH Server 是用来连接部署服务器的，用于在项目构建完成后将你的应用推送到服务器中并执行相应的脚本。

打开 (Manage Jenkins) -> 系统配置，找到 Publish Over SSH 部分，选择新增

![ssh-server](ssh-server.png)

这里需要远程服务器支持ssh连接

### 远程Windows Server配置SSH

如果服务器是Windows的，可以下载并安装[freeSSHD](http://www.freesshd.com/?ctt=download)，安装流程可以参考这篇文章 [本机（Windows）通过SSH软件工具freeSSHD、puTTY远程连接虚拟机（Windows）](https://blog.csdn.net/yangdan1025/article/details/81985903)

> 这里推荐freeSSHD是因为远程执行bat比较稳定，之前使用openSSH时总会有些莫名的问题，可能时我配置的有问题，就不继续探究的。

配置好后，点击【Test Configuration】出现 "Success"即可保存，如果出现的是异常日志，首先检查远程服务器是否支持ssh连接，再检查配置是否正确尤其用户名密码和端口号
 
> ssh客户端如果使用的是windows10推荐直接使用powershell

```shell
ssh root@192.168.197.129 -p 22
```

### 远程Linux配置SSH

一般云服务都支持SSH连接，可以用SSH的客户端连接测试(注意可能有些云服务器的安全组未开放端口，配置下即可)。当然如果确实没有安装ssh server，可以打开Terminal：

```shell
# 更新软件下载源
sudo apt update

# 安装ssh服务
sudo apt install openssh-server

# 开启防火墙ssh的服务端口
sudo ufw allow ssh

# 开启ssh服务
systemctl start ssh

# 设置开启自启
sudo systemctl enable ssh

# 查看ssh服务状态
systemctl status ssh
```

修改sshd_config，主要是放开"PasswordAuthentication yes"和“PermitRootLogin yes”

```shell
#	$OpenBSD: sshd_config,v 1.103 2018/04/09 20:41:22 tj Exp $

# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/usr/bin:/bin:/usr/sbin:/sbin

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

Include /etc/ssh/sshd_config.d/*.conf

#Port 22
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

#HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_ecdsa_key
#HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# Logging
#SyslogFacility AUTH
#LogLevel INFO

# Authentication:

LoginGraceTime 2m
PermitRootLogin yes 
StrictModes yes
#MaxAuthTries 6
#MaxSessions 10

#PubkeyAuthentication yes

# Expect .ssh/authorized_keys2 to be disregarded by default in future.
#AuthorizedKeysFile	.ssh/authorized_keys .ssh/authorized_keys2

#AuthorizedPrincipalsFile none

#AuthorizedKeysCommand none
#AuthorizedKeysCommandUser nobody

# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
#IgnoreUserKnownHosts no
# Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
PasswordAuthentication yes
#PermitEmptyPasswords no

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
ChallengeResponseAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes
#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the ChallengeResponseAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via ChallengeResponseAuthentication may bypass
# the setting of "PermitRootLogin without-password".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and ChallengeResponseAuthentication to 'no'.
UsePAM yes

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
X11Forwarding yes
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
PrintMotd no
#PrintLastLog yes
#TCPKeepAlive yes
#PermitUserEnvironment no
#Compression delayed
#ClientAliveInterval 0
#ClientAliveCountMax 3
#UseDNS no
#PidFile /var/run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

# no default banner path
#Banner none

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

# override default of no subsystems
Subsystem	sftp	/usr/lib/openssh/sftp-server

# Example of overriding settings on a per-user basis
#Match User anoncvs
#	X11Forwarding no
#	AllowTcpForwarding no
#	PermitTTY no
#	ForceCommand cvs server
```

# 配置Nginx代理

**如果需要配置了Nginx代理，必须设置Jenkins的配置中加入--prefix=/jenkins**

nginx中server加入配置：

```
location /jenkins/ {
  proxy_pass http://127.0.0.1:8080/jenkins/;
  proxy_set_header X-Forwarded-Host $host:$server_port;
  proxy_set_header X-Forwarded-Server $host;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto $scheme;
  proxy_set_header X-Real-IP $remote_addr;
}

```

设置Jenkins Location中的Jenkins URL地址为http://xxx/jenkins/, 如果有公网地址添加公网地址(没有可以用类似花生壳的内网穿透软件代理下)

这里最好有公网地址，不然无法做到自动构建(自动构建需要结合webhook功能)。

# 配置镜像

使用官方默认地址安装插件的速度比较慢，可以配置国内的镜像地址

Dashboard -> Manage jenkins -> 点击右下角的中文社区jenkins中文社区(如果没有则先安装首先安装 Localization: Chinese (Simplified)插件)

点击【使用】按钮，再点击【设置更新中心地址】，在最底部填入镜像的代理地址 https://updates.jenkins-zh.cn/update-center.json

![update-url](update-url.png)

下面我们看下如何在[Windows上使用Jenkins构建并部署SpringBoot项目](/20210706/jenkins/5b02ceab/)
