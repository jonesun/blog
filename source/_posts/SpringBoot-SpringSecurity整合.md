---
title: SpringBoot-SpringSecurity整合
date: 2020-07-22 13:23:09
categories: [java,springboot]
tags: [java, springboot, springsecurity]
---

# JWT

Json Web Token （JWT） 近几年是前后端分离常用的 Token 技术，是目前最流行的跨域身份验证
解决方案。

未整理完成......

 <!-- more -->

# spring-security-jwt

spring-security-jwt 是 Spring Security Crypto 提供的 JWT 工具包 。

```
<dependency>
    <groupId>org.springframework.security</groupId>
    <artifactId>spring-security-jwt</artifactId>
    <version>${spring-security-jwt.version}</version>
</dependency>
```
核心类只有一个: org.springframework.security.jwt.JwtHelper 。它提供了两个非常有用的静态方法:

## encode

JwtHelper 提供的第一个静态方法就是 encode(CharSequence content, Signer signer) 这个是用来生成jwt的方法 需要指定 payload跟 signer 签名算法。payload 存放了一些可用的不敏感信息：
- iss jwt签发者
- sub jwt所面向的用户
- aud 接收jwt的一方
- iat jwt的签发时间
- exp jwt的过期时间，这个过期时间必须要大于签发时间 iat
- jti jwt的唯一身份标识，主要用来作为一次性token,从而回避重放攻击

除了以上提供的基本信息外，我们可以定义一些我们需要传递的信息，比如目标用户的权限集 等等。切记不要传递密码等敏感信息，因为 JWT 的前两段都是用了 BASE64 编码，几乎算是明文了。

# OAuth2授权方式

OAuth2为我们提供了四种授权方式：

1、授权码模式（authorization code）

通过客户端的后台服务器与服务提供商的认证服务器交互来完成

2、简化模式（implicit）

这种模式不通过服务器端程序来完成，直接由浏览器发送请求获取令牌，令牌是完全暴露在浏览器中的，这种模式极力不推崇

3、密码模式（resource owner password credentials）

密码模式也是比较常用到的一种，客户端向授权服务器提供用户名、密码然后得到授权令牌。这种模式不过有种弊端，我们的客户端需要存储用户输入的密码，但是对于用户来说信任度不高的平台是不可能让他们输入密码的

4、客户端模式（client credentials）

客户端模式是客户端以自己的名义去授权服务器申请授权令牌，并不是完全意义上的授权


OAuth2服务器分为两部分组成：认证授权服务器和资源服务器 认证主要由Spring-Security负责，而授权则由Oauth2负责

# Oauth2提供的默认端点（endpoints）

- /oauth/authorize：授权端点

- /oauth/token：令牌端点

- /oauth/confirm_access：用户确认授权提交端点

- /oauth/error：授权服务错误信息端点

- /oauth/check_token：用于资源服务访问的令牌解析端点

- /oauth/token_key：提供公有密匙的端点，如果使用JWT令牌的话


# security oauth2 整合的3个核心配置类

1. 资源服务配置 ResourceServerConfiguration

2. 授权认证服务配置 AuthorizationServerConfiguration

3. security 配置 SecurityConfiguration

