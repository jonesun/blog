---
title: SpringBoot-SpringSecurity整合
date: 2020-07-22 13:23:09
categories: [java,springboot]
tags: [java, springboot, springsecurity]
---

# SpringSecurity

以下代码基于SpringBoot 2.4.1(SpringSecurity 5.4.2)

## 简易版

使用SpringBoot可以很轻松的完成SpringSecurity的集成，因为SpringBoot默认帮我们做了[很多事](https://docs.spring.io/spring-security/site/docs/current/reference/html5/#servlet-hello-auto-configuration)

> 默认创建一个UserDetailsService具有用户名user和随机生成的密码的Bean，并将其记录到控制台

未整理完成......

 <!-- more -->

直接pom.xml中加入引用即可:

```xml
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.security</groupId>
            <artifactId>spring-security-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

```

编写一个测试controller:

```java
@RestController
public class HelloController {

    @GetMapping("/")
    public String sayHello() {
        return "hello world";
    }

}
```

启动项目，浏览器中输入http://localhost:8080/, 此时会自动跳转到SpringSecurity提供的默认登录页，输入用户名(user)和密码(从控制台中找到随机密码)后页面输出: hello world

如果不想用随机密码，可在application.yml(默认application.properties建议改下后缀)配置默认账户密码:

```yaml
spring:
  security:
    user:
      name: admin
      password: 123456
```

## Web表单登录

SpringSecurity提供了一个默认的登录页面，我们需要改用为自己的登录页面(不想改也没关系，毕竟默认的登录页比有些自定义的还好看些):

* 新建WebSecurityConfig用于对SpringSecurity进行配置(大部分配置都是在这个类中修改):

```java
@Configuration
public class WebSecurityConfig extends WebSecurityConfigurerAdapter {

    @Override
    protected void configure(HttpSecurity http) throws Exception {
//        super.configure(http);
        http
                .formLogin(form -> form
                        .loginPage("/login")
                        .permitAll()
                );
    }
}

```

* 为了编写方便，引入[Thymeleaf](https://www.thymeleaf.org/)模板：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>
```

* 编写登录页(src/main/resources/templates/login.html)

```html
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:th="https://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <title>登录页</title>
</head>
<body>
<h1>登录页</h1>
<div th:if="${param.error}">
    用户名或密码错误.</div>
<div th:if="${param.logout}">
    您已登出.</div>
<form th:action="@{/login}" method="post">
    <div>
        <input type="text" name="username" placeholder="Username"/>
    </div>
    <div>
        <input type="password" name="password" placeholder="Password"/>
    </div>
    <input type="submit" value="登录" />
</form>
</body>
</html>
```

> 登录页面根据自己的需求进行改写，但需要注意: 必须发送的登录请求为POST形式的/login, 必须包含username和password字段(即可以不用Thymeleaf或者使用ajax模拟form表单请求), 否则需要改写:

```java
@Configuration
public class WebSecurityConfig extends WebSecurityConfigurerAdapter {

    @Override
    public void configure(WebSecurity web) throws Exception {
        //如果登录页面引用了js、css等静态资源的话需要加入
        web.ignoring().antMatchers("/js/**", "/css/**","/images/**");
    }

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        super.configure(http);
        http
                .formLogin(form -> form
                        .loginPage("/login")
                        .loginProcessingUrl("/doLogin")
                        .usernameParameter("custom_username")
                        .passwordParameter("custom_password")
                        .permitAll()
                );
    }
}

```

因为我们引入了web模块，使用的是Spring MVC，则需要一个映射GET形式的/login 到我们创建的登录页面的controller(当然也可以使用统一的WebMvcConfig, 这里就不展开了):

```java
@Controller
public class WebController {

    @GetMapping("/login")
    String login() {
        return "login";
    }
}

```

重新启动项目，访问http://localhost:8080/, 此时会自动跳转到我们编写的登录页，输入用户名和密码后页面输出: hello world

[示例源码-web-server](https://github.com/jonesun/spring-security-demo/tree/master/web-server)

## Web前后端分离

日常开发中经常会使用前后端分离技术： 将web页面做成静态页面(可能使用vue等技术)单独部署，后台提供restful接口

* 改写WebSecurityConfig:

```java
@Configuration
public class WebSecurityConfig extends WebSecurityConfigurerAdapter {

    @Autowired
    private ObjectMapper objectMapper;

    @Bean
    public UserDetailsService userDetailsService() {
        //获取用户账号密码及权限信息
        return username -> {
            System.out.println("username: " + username);
            return User.withUsername("admin").password("123456").passwordEncoder(s -> s).roles("USER").build();
        };
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        // 设置默认的加密方式（强hash方式加密）
        return NoOpPasswordEncoder.getInstance();
    }

    @Override
    public void configure(WebSecurity web) throws Exception {
        //如果登录页面引用了js、css等静态资源的话需要加入
        web.ignoring().antMatchers("/*.html","/js/**", "/css/**","/images/**");
    }

    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {
        auth.userDetailsService(userDetailsService());
    }

    @Override
    protected void configure(HttpSecurity http) throws Exception {
//        super.configure(http);

        http.authorizeRequests()
                .anyRequest().authenticated()
                .and()
                .cors()
                .and()
                .csrf().disable()
                .formLogin()
                .successHandler((httpServletRequest, httpServletResponse, authentication) -> {
                    System.out.println("登录成功: " + httpServletRequest.getSession().getId());
                    Map<String, Object> map = new HashMap<>();
                    map.put("code", 200);
                    map.put("message", "登录成功");
                    map.put("data", authentication);
                    httpServletResponse.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    httpServletResponse.setCharacterEncoding(StandardCharsets.UTF_8.toString());
                    PrintWriter out = httpServletResponse.getWriter();
                    out.write(objectMapper.writeValueAsString(map));
                    out.flush();
                    out.close();
                })
                .failureHandler((req, resp, ex) -> {
//                    ex.printStackTrace();
                    resp.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    resp.setCharacterEncoding(StandardCharsets.UTF_8.toString());
                    resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    PrintWriter out = resp.getWriter();
                    Map<String, Object> map = new HashMap<>();
                    map.put("code", HttpServletResponse.SC_UNAUTHORIZED);
                    if (ex instanceof UsernameNotFoundException || ex instanceof BadCredentialsException) {
                        map.put("message", "用户名或密码错误");
                    } else if (ex instanceof DisabledException) {
                        map.put("message", "账户被禁用");
                    } else {
                        map.put("message", "登录失败!");
                    }
                    out.write(objectMapper.writeValueAsString(map));
                    out.flush();
                    out.close();
                })
                .permitAll()
                .and()
                .logout()
                .logoutSuccessHandler((req, resp, authentication) -> {
                    Map<String, Object> map = new HashMap<String, Object>();
                    map.put("code", 200);
                    map.put("message", "退出成功");
                    map.put("data", authentication);
                    resp.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    resp.setCharacterEncoding(StandardCharsets.UTF_8.toString());
                    PrintWriter out = resp.getWriter();
                    out.write(objectMapper.writeValueAsString(map));
                    out.flush();
                    out.close();
                })
                .permitAll()
                .and()
                .exceptionHandling()
                //未登录
                .authenticationEntryPoint((req, resp, authException) -> {
                    resp.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    resp.setCharacterEncoding(StandardCharsets.UTF_8.toString());
                    resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    PrintWriter out = resp.getWriter();
                    Map<String, Object> map = new HashMap<>();
                    map.put("code", HttpServletResponse.SC_FORBIDDEN);
                    map.put("message", "未登录");
                    out.write(objectMapper.writeValueAsString(map));
                    out.flush();
                    out.close();
                })
                //权限不足
                .accessDeniedHandler((request, httpServletResponse, ex) -> {
                    httpServletResponse.setStatus(HttpServletResponse.SC_OK);
                    httpServletResponse.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    httpServletResponse.setCharacterEncoding(StandardCharsets.UTF_8.toString());
//                    httpServletResponse.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    PrintWriter out = httpServletResponse.getWriter();
                    Map<String, Object> map = new HashMap<>();
                    map.put("code", HttpServletResponse.SC_FORBIDDEN);
                    map.put("message", "权限不足");
                    out.write(objectMapper.writeValueAsString(map));
                    out.flush();
                    out.close();
                })
        ;
    }

    @Bean
    public CorsFilter corsFilter() {
        CorsConfiguration corsConfiguration = new CorsConfiguration();
        //1,允许任何来源 *表示任何请求都视为同源(生产环境尽量在配置文件中动态配置部署到的域名)，若需指定ip和端口可以改为如“localhost：8080”
        corsConfiguration.setAllowedOriginPatterns(Collections.singletonList("*"));
        //2,允许任何请求头
        corsConfiguration.addAllowedHeader(CorsConfiguration.ALL);
        //3,允许任何方法
        corsConfiguration.addAllowedMethod(CorsConfiguration.ALL);
        //4,允许凭证
        corsConfiguration.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", corsConfiguration);
        return new CorsFilter(source);
    }

}

```

> 注意: 一定要开启cors允许跨域访问，这样就可以让session共享，但生产环境中不要直接允许所有请求，根据实际情况指定域名列表

* 在任意文件夹中新建html静态文件:

login.html 建议引入Jquery的ajax表单提交插件[jquery-form](https://github.com/jquery-form/form)，以便处理form表单请求

```html
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="UTF-8">
    <title>登录页</title>
    <script src="js/jquery-3.5.1.js"></script>

    <script src="js/jquery.form.min.js"></script>
</head>
<body>
<h1>登录页</h1>
<form id="loginForm" action="http://localhost:8080/web-server-rest/login" method="post">
    <div>
        <input type="text" name="username" placeholder="Username"/>
    </div>
    <div>
        <input type="password" name="password" placeholder="Password"/>
    </div>
    <input id="submitBtn" type="submit" value="登录" />
</form>
<script>

    $(function () {
        $('#loginForm').ajaxForm({
            beforeSubmit: validate,
            xhrFields: {withCredentials: true},    //前端适配：允许session跨域
            crossDomain: true,
            success: function(data) {
                //返回数据处理
                console.log(data);
                $(location).attr('href', 'index.html');
            },
            error: function (ex) {
                alert(ex);
                console.log(ex);
            }
        });
    });

    function validate() {
        console.log("校验参数");
    }

</script>
</body>
</html>
```

index.html **ajax请求需加上withCredentials以便支持跨域请求(将cookie中JSESSIONID发送到服务端)**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>这是首页</title>
    <script src="js/jquery-3.5.1.js"></script>
</head>
<body>
这是首页
<p><input id="logoutBtn" type="button" value="登出" /></p>
<script type="text/javascript">
    $(function(){
        $.ajax({
            type:"get",
            // dataType: "json",
            crossDomain: true,
            xhrFields: {
                withCredentials: true
            },
            url:"http://localhost:8080/web-server-rest/api/sayHello",
            success:function(data){
                console.log(data);
            },
            error: function (jqXHR, textStatus, errorThrown) {
                console.log("异常处理");
                console.error(jqXHR);
                console.error(textStatus);
                console.error(errorThrown);
                if(jqXHR.status === 403) {
                    //可以编写一个公共js, 遇到接口返回需要登录时统一跳转到登录页
                    $(location).attr('href', 'login.html');
                }
            }
        });


        $("#logoutBtn").click(function(){
            $.ajax({
                type:"post",
                crossDomain: true,
                xhrFields: {
                    withCredentials: true
                },
                url:"http://localhost:8080/web-server-rest/logout",
                success:function(data){
                    console.log(data);
                },
                error: function (jqXHR, textStatus, errorThrown) {
                    console.error(jqXHR);
                    console.error(textStatus);
                    console.error(errorThrown);
                }
            });
        })

    })
</script>
</body>
</html>
```
> **cors实现了直接跨域,安全性和灵活性更高**,关键在配置好AllowedOrigin

还有一种支持跨域访问的方式就是[nginx](SpringBoot 实现前后端分离的跨域访问（Nginx）)]了，有兴趣可以了解下

关于cors的介绍可以参考[跨域资源共享 CORS 详解](http://www.ruanyifeng.com/blog/2016/04/cors.html)

使用这种方式的好处在于: cookie+sessionId的维护由浏览器自动完成，无需额外编写代码

> 如果是一般的中小型项目，这种方式就行了，而如果项目访问量较大, 或者需要支持分布式的话，会面临以下问题:
* 服务端保存大量数据，增加服务端压力
* 服务端保存用户状态，不支持集群化部署

这个时候可以进行改造采用redis将session缓存起来，配合一些分布式session共享技术

[示例源码-web-rest](https://github.com/jonesun/spring-security-demo/tree/master/web-rest)

## 前后端分离-为app、桌面程序或者小程序等提供服务

因为不是基于浏览器，无法使用session, 这里就需要引入[jwt](https://jwt.io/)技术了，但JWT是一种规范，并没有和某一种语言绑定在一起，实际使用过程中可根据自己需要选择相应库：

- com.auth0: ava-jwt 
- org.bitbucket.b_c: jose4j 
- com.nimbusds: nimbus-jose-jwt
- io.jsonwebtoken: jjwt-root
- io.fusionauth: fusionauth-jwt
- io.vertx: vertx-auth-jwt 
- ......

[示例源码-jwt](https://github.com/jonesun/spring-security-demo/tree/master/jwt)

> 如果是spring cloud推荐使用 OAuth2 中的 password 模式, 如果需要提供给多个服务，就需要OAuth2了

## 同时支持web表单、web前后端分离和jwt

## 使用MySql

## 使用Mybatis

## 授权相关

[官网教程](https://docs.spring.io/spring-security/site/docs/current/reference/html5/#features)


> 以下为笔者草稿，不建议阅读，文章整理好后会进行删除

密码存储配置: Spring Security默认使用DelegatingPasswordEncoder

```java
PasswordEncoder passwordEncoder = PasswordEncoderFactories.createDelegatingPasswordEncoder();
```

CSRF: 跨站请求伪造,是一种挟制用户在当前已登录的Web应用程序上执行非本意的操作的攻击方法

对普通用户可能由浏览器处理的任何请求使用CSRF保护。如果仅创建非浏览器客户端使用的服务，则可能需要禁用CSRF保护。

CORS: 跨域资源共享, 它允许浏览器向跨源服务器，发出XMLHttpRequest请求，从而克服了AJAX只能同源使用的限制。

Spring Security的默认设置是禁用缓存以保护用户的内容。

# SpringSecurity with oauth2

## 选择哪个库?

使用SpringSecurity来实现oauth2，之前网上的文章中大都推荐使用[spring-security-oauth](https://github.com/spring-projects/spring-security-oauth)，但目前(2020年12月)在其github上看到了这个: 

> The Spring Security OAuth project is deprecated. The latest OAuth 2.0 support is provided by Spring Security. See the OAuth 2.0 Migration Guide for further details.

大体意思就是: 不建议使用Spring Security OAuth项目。Spring Security提供了最新的OAuth 2.0支持。(2.4.x 版本开始相关类都已标注为过时)

> 2019年11月下旬，Spring官方在Spring Security OAuth 2.0路线图中 指出2.3.x版本将在2020年3月到达项目生命周期的终点（End Of Life），随后将会发布2.4.x和2.5.x。
后续2.4.x和2.5.x补丁和安全修复程序支持将持续到2021年5月，另外2.5.x的安全修复支持将持续到2022年5月项目终止日期。
相同的寿命终止时间表适用于对应的Spring Boot 2自动配置项目。
Spring Security OAuth 2.0会在2022年5月项目终止后开放给Spring社区中的成员直接管理。

好，那就还回到Spring Security查看[Spring Security OAuth 2.0迁移指南](https://github.com/spring-projects/spring-security/wiki/OAuth-2.0-Migration-Guide), 但前面的一句话是这么说的:

> This document contains guidance for moving OAuth 2.0 Clients and Resource Servers from Spring Security OAuth 2.x to Spring Security 5.2.x. Since Spring Security doesn’t provide Authorization Server support, migrating a Spring Security OAuth Authorization Server is out of scope for this document.

大体意思就是: 本文档包含有关将OAuth 2.0客户端和资源服务器从Spring Security OAuth 2.x迁移到Spring Security 5.2.x的指南。由于Spring Security不提供Authorization Server支持，因此迁移Spring Security OAuth Authorization Server超出了本文档的范围。

继而找到[spring-authorization-server](https://github.com/spring-projects-experimental/spring-authorization-server)

总结一下: **Spring Authorization Server将替代Spring Security OAuth为 Spring 社区提供OAuth2.0授权服务器支持**(等待其发行正式版本后, 目前该项目的最新发行版为0.0.3，可以进行尝鲜)，在此之前建议迁移到Spring Security 5.2.+, [官方文章-Spring Security OAuth 2.0路线图更新](https://spring.io/blog/2019/11/14/spring-security-oauth-2-0-roadmap-update)

security-spring的使用参考大神文章[baeldung-security-spring](https://www.baeldung.com/security-spring)

# SpringSecurity核心类

> 以下源码来自SpringSecurity-5.3.3版本

## Authentiction

包含了用户身份信息，密码，细节信息，认证信息，以及权限列表等:

- getAuthorities，权限列表,通常是代表权限的字符串列表；
- getCredentials，密码信息,由用户输入的密码凭证，**认证之后会移出，来保证安全性**；
- getDetails，细节信息，Web应用中一般是访问者的ip地址和sessionId；
- getPrincipal, 最重要的身份信息，一般返回UserDetails的实现类

>  Authentication继承自来自于java.security包的Principal类,而本身又是spring.security包中的接口。也就是说，Authentication是Spring Security中最高级别的认证


 > AuthenticationManager、AccessDecisionManager 和 AbstractSecurityInterceptor 属于 Spring Security 框架的基础铁三角。AuthenticationManager 和 Access-DecisionManager 负责制定规则，AbstractSecurityInterceptor 负责执行

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

使用Spring Security为的就是写最少的代码，实现更多的功能，在定制化Spring Security，核心思路就是：重写某个功能，然后配置。

- 比如你要查自己的用户表做登录，那就实现UserDetailsService接口；
- 比如前后端分离项目，登录成功和失败后返回json，那就实现AuthenticationFailureHandler/- AuthenticationSuccessHandler接口；
- 比如扩展token存放位置，那就实现HttpSessionIdResolver接口；
- 等等…

# JWT

Json Web Token （JWT） 近几年是前后端分离常用的 Token 技术，是目前最流行的跨域身份验证
解决方案。

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



Spring Security的项目，启用CORS：

```java
@EnableWebSecurity
public class WebSecurityConfig extends WebSecurityConfigurerAdapter {
 
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
            // by default uses a Bean by the name of corsConfigurationSource
            .cors().and()
            ...
    }
 
    //SpringBoot2.4.0以下
//    @Bean
//    CorsConfigurationSource corsConfigurationSource() {
//        UrlBasedCorsConfigurationSource source =   new UrlBasedCorsConfigurationSource();
//        CorsConfiguration corsConfiguration = new CorsConfiguration();
//        corsConfiguration.addAllowedOrigin("*");    //同源配置，*表示任何请求都视为同源(生产环境尽量在配置文件中动态配置部署到的域名)，若需指定ip和端口可以改为如“localhost：8080”，多个以“，”分隔；
//        corsConfiguration.addAllowedHeader("*");//header，允许哪些header
//        corsConfiguration.addAllowedMethod("*");    //允许的请求方法，POST、GET等
//        source.registerCorsConfiguration("/**",corsConfiguration); //配置允许跨域访问的url
//        return source;
////        CorsConfiguration configuration = new CorsConfiguration();
////        configuration.setAllowedOrigins(Arrays.asList("https://example.com"));
////        configuration.setAllowedMethods(Arrays.asList("GET","POST"));
////        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
////        source.registerCorsConfiguration("/**", configuration);
////        return source;
//    }

    //SpringBoot2.4.0以上
    @Bean
    public CorsFilter corsFilter() {
        CorsConfiguration corsConfiguration = new CorsConfiguration();
        //1,允许任何来源 *表示任何请求都视为同源(生产环境尽量在配置文件中动态配置部署到的域名)，若需指定ip和端口可以改为如“localhost：8080”
        corsConfiguration.setAllowedOriginPatterns(Collections.singletonList("*"));
        //2,允许任何请求头
        corsConfiguration.addAllowedHeader(CorsConfiguration.ALL);
        //3,允许任何方法
        corsConfiguration.addAllowedMethod(CorsConfiguration.ALL);
        //4,允许凭证
        corsConfiguration.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", corsConfiguration);
        return new CorsFilter(source);
    }
}
```

# Test

> 要使用Spring Security测试支持，必须加入spring-security-test依赖项

具体查看[官方教程](https://docs.spring.io/spring-security/site/docs/current/reference/html5/#test)

# 常用代码

* 当已登录用户再次访问登录界面时，跳转到index页面

```java
@Controller
public class WebController {

    @GetMapping("/login")
    String login() {
        //当已登录用户再次访问登录界面时，跳转到index页面
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if(auth instanceof AnonymousAuthenticationToken){
            return "login";
        }else{
            return "redirect:index";
        }
    }

    @GetMapping("/index")
    String index() {
        return "index";
    }
}
```

* 自定义了登录成功处理接口后，保持原先系统的自动转向处理

```java
@Configuration
public class WebSecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    protected void configure(HttpSecurity http) throws Exception {
//        super.configure(http);
        //原有配置中加入
        http
                .successHandler((req, resp, authentication) -> {
                    //记录登录日志，初始化用户菜单等等
                    String  redirectUrl = "index"; //缺省的登录成功页面
                    SavedRequest savedRequest = (SavedRequest) req.getSession().getAttribute("SPRING_SECURITY_SAVED_REQUEST");
                    if(savedRequest != null) {
                        redirectUrl =   savedRequest.getRedirectUrl();
                        logger.info("redirectUrl: " + redirectUrl);
                        req.getSession().removeAttribute("SPRING_SECURITY_SAVED_REQUEST");
                    }
                    resp.sendRedirect(redirectUrl);
                });
    }
}

```

> Spring cloud 2020.0.0版本已经将Spring Cloud Security 这个项目删除了，其代码已经移到了 Spring Cloud 各个子项目中了。

spring-security-data