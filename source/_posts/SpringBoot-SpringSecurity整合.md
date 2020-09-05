---
title: SpringBoot-SpringSecurity整合
date: 2020-07-22 13:23:09
categories: [java,springboot]
tags: [java, springboot, springsecurity]
---

# SpringSecurity核心类

> 以下源码来自SpringSecurity-5.3.3版本

## Authentiction

包含了用户身份信息，密码，细节信息，认证信息，以及权限列表等:

- getAuthorities，权限列表,通常是代表权限的字符串列表；
- getCredentials，密码信息,由用户输入的密码凭证，**认证之后会移出，来保证安全性**；
- getDetails，细节信息，Web应用中一般是访问者的ip地址和sessionId；
- getPrincipal, 最重要的身份信息，一般返回UserDetails的实现类

>  Authentication继承自来自于java.security包的Principal类,而本身又是spring.security包中的接口。也就是说，Authentication是Spring Security中最高级别的认证

## AuthenticationToken

所有的认证请求都会被封装成一个Token的实现，比如最容易理解的UsernamePasswordAuthenticationToken，在Spring Security中提交的用户名和密码，会被封装成了UsernamePasswordAuthenticationToken

## AuthenticationManager

用户认证的管理类(权限验证控制器), 所有的认证请求(如login)都会通过生成一个Authentiction传给AuthenticationManager接口的唯一方法：

```
Authentication authenticate(Authentication authentication) throws AuthenticationException)
```
进行认证处理。当然由于是接口，所以具体的校验动作会转发给具体的实现类。而AuthenticationManager默认实现类为ProviderManager，然后ProviderManager根据配置的AuthenticationProvider列表，按照顺序进行依次认证，每个provider都会尝试认证，或者通过简单地返回null来跳过验证。如果所有实现都返回null，那么ProviderManager将抛出一个ProviderNotFoundException

## AuthenticationProvider

认证的具体实现类，当然这个类也是接口，而且只有两个方法:

```
public interface AuthenticationProvider {

    /**
    * 真正的认证
    **/
    Authentication authenticate(Authentication var1) throws AuthenticationException;

    /**
    * 满足什么样的身份信息才进行如上认证
    **/
    boolean supports(Class<?> var1);
}
```

所以一般实现一个AuthenticationProvider就相当于提供一种认证方式(比如提交的用户名密码通过和数据库内的内容进行比较，那就有一个DaoProvider)。而Spring对于主流的认证方式都已经提供了默认实现:

- DaoAuthenticationProvider 从数据库中读取用户信息验证身份
- AnonymousAuthenticationProvider 匿名用户身份认证
- RememberMeAuthenticationProvider 已存cookie中的用户信息身份认证
- AuthByAdapterProvider 使用容器的适配器验证身份
- CasAuthenticationProvider 使用cas实现单点登陆登录
- JaasAuthenticationProvider 从JASS登陆配置中获取用户信息验证身份
- RemoteAuthenticationProvider 根据远程服务验证用户身份
- RunAsImplAuthenticationProvider 对身份已被管理器替换的用户进行验证
- X509AuthenticationProvider 从X509认证中获取用户信息验证身份
- TestingAuthenticationProvider 单元测试时使用
- ...

> 当然也可以自己实现AuthenticationProvider接口来自定义认证

## UserDetailService

通过上面分析可以知道用户认证是通过各种Provider来实现的，所以需要拿到系统已经保存的用户认证相关信息(即根据用户名加载用户)的任务则是交给了UserDetailsService而这个就是由UserDetailService来实现的，当然这个类也是接口，并且只有唯一的方法(UserDetails loadUserByUsername(String username))，常用的实现类有JdbcDaoImpl和InMemoryUserDetailsManager，前者从数据库中加载用户，后者从内存中。还可以自己实现UserDetailsService

> 在DaoAuthenticationProvider的实现中，对应的方法便是retrieveUser，返回一个UserDetails。然后再将UsernamePasswordAuthenticationToken和UserDetails密码的比对，这便是交给additionalAuthenticationChecks方法完成的，如果这个void方法没有抛异常，则认为比对成功

## UserDetails

UserDetails接口，它代表了最详细的用户信息，这个接口涵盖了一些必要的用户信息字段，具体的实现类对它进行了扩展

> 它和Authentication接口类似，都包含了用户名，密码以及权限信息，而区别就是Authentication中的getCredentials来源于用户提交的密码凭证，而UserDetails中的getPassword取到的则是用户正确的密码信息，认证的第一步就是比较两者是否相同，除此之外，Authentication中的getAuthorities是认证用户名和密码成功之后，由UserDetails中的getAuthorities传递而来。而Authentication中的getDetails信息是经过了AuthenticationProvider认证之后填充的


## AbstractAuthenticationProcessingFilter

Provider认证成功后，AbstractAuthenticationProcessingFilter 在 successfulAuthentication 方法中对登录成功进行了处理，通过 SecurityContextHolder.getContext().setAuthentication() 方法将 Authentication 认证信息对象绑定到 SecurityContext
下次请求时，在过滤器链头的 SecurityContextPersistenceFilter 会从 Session 中取出用户信息并生成 Authentication（默认为 UsernamePasswordAuthenticationToken），并通过 SecurityContextHolder.getContext().setAuthentication() 方法将 Authentication 认证信息对象绑定到 SecurityContext
需要权限才能访问的请求会从 SecurityContext 中获取用户的权限进行验证

> UsernamePasswordAuthenticationFilter继承于AbstractAuthenticationProcessingFilter


## SecurityContext

当用户通过认证之后，就会为这个用户生成一个唯一的SecurityContext，里面包含用户的认证信息Authentication。通过SecurityContext我们可以获取到用户的标识Principle和授权信息GrantedAuthrity。在系统的任何地方只要通过SecurityHolder.getSecruityContext()就可以获取到SecurityContext。

> 在Shiro中通过SecurityUtils.getSubject()到达同样的目的


## SecurityContextHolder

负责存储当前安全上下文信息。即保存着当前用户是什么，是否已经通过认证，拥有哪些权限。。。等等。SecurityContextHolder默认使用ThreadLocal策略来存储认证信息，意味着这是一种与线程绑定的策略。在Web场景下的使用Spring Security，在用户登录时自动绑定认证信息到当前线程，在用户退出时，自动清除当前线程的认证信息。


```
Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
if (principal instanceof UserDetails) {
    String username = ((UserDetails) principal).getUsername();
} else {
    String username = principal.toString();
}

```

## AuthenticationSuccessHandler 

登陆认证成功处理过滤器

## AuthenticationFailureHandler

登陆失败处理过滤器

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

