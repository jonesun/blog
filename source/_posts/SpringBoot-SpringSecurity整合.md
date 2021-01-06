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
> 概念解析

CSRF: 跨站请求伪造,是一种挟制用户在当前已登录的Web应用程序上执行非本意的操作的攻击方法

对普通用户可能由浏览器处理的任何请求使用CSRF保护。如果仅创建非浏览器客户端使用的服务，则可能需要禁用CSRF保护。

CORS: 跨域资源共享, 它允许浏览器向跨源服务器，发出XMLHttpRequest请求，从而克服了AJAX只能同源使用的限制。

Spring Security的默认设置是禁用缓存以保护用户的内容。

> **cors实现了直接跨域,安全性和灵活性更高**,关键在配置好AllowedOrigin。CORS需要浏览器和服务器同时支持。它的通信过程，都是浏览器自动完成，不需要用户参与。

还有一种支持跨域访问的方式就是[nginx](SpringBoot 实现前后端分离的跨域访问（Nginx）)]了，有兴趣可以了解下

关于cors的介绍可以参考[跨域资源共享 CORS 详解](http://www.ruanyifeng.com/blog/2016/04/cors.html)

使用这种方式的好处在于: cookie+sessionId的维护由浏览器自动完成，无需额外编写代码

[示例源码-web-rest](https://github.com/jonesun/spring-security-demo/tree/master/web-rest)

> 如果是一般的中小型项目，这种方式就行了，而如果项目访问量较大, 或者需要支持分布式的话，会面临以下问题:

* 服务端保存大量数据，增加服务端压力
* 服务端保存用户状态，不支持集群化部署

这个时候可以进行改造采用redis将session缓存起来，配合一些分布式session共享技术

## 前后端分离-为app、桌面程序或者小程序等提供服务

因为不是基于浏览器，无法使用session, 这里就需要引入[jwt](https://jwt.io/)技术了，但JWT是一种规范，并没有和某一种语言绑定在一起，实际使用过程中可根据自己需要选择相应库：

- com.auth0: ava-jwt 
- org.bitbucket.b_c: jose4j 
- com.nimbusds: nimbus-jose-jwt
- io.jsonwebtoken: jjwt-root
- io.fusionauth: fusionauth-jwt
- io.vertx: vertx-auth-jwt 
- ......

之前看到Spring Security OAuth中使用的是nimbus-jose-jwt，我们就以这个库来举下例子

1. pom.xml中加入依赖:

```xml
<dependencies>
    <dependency>
        <groupId>com.nimbusds</groupId>
        <artifactId>nimbus-jose-jwt</artifactId>
        <version>9.2</version>
    </dependency>

    <!-- 这个是为了演示时使用随机数生成keyId 非必须 -->
    <dependency>
        <groupId>org.apache.commons</groupId>
        <artifactId>commons-lang3</artifactId>
        <version>3.11</version>
    </dependency>
</dependencies>
```

2. 编写JwtUtils

```java
import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.JWSSigner;
import com.nimbusds.jose.crypto.RSASSASigner;
import com.nimbusds.jose.crypto.RSASSAVerifier;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import org.apache.commons.lang3.RandomStringUtils;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;

import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.NoSuchAlgorithmException;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.text.ParseException;
import java.util.Base64;
import java.util.Collection;
import java.util.Date;


public class JWTUtils {

    /**
     * 过期时间50秒
     */
    private static final long EXPIRE_TIME = 1000 * 50;

    //todo 这里仅仅为了演示rsa的加解密功能，实际项目中需自行生成好再读取。或者使用jks的方式读取
    //公钥
    private static String publicKeyStr = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvSja2vpalTbaNg8ChQt133AC6RPD3mpvkPzezb5lw48+AmVyodtJ817Uoi6p+QpkeNyxoivRYEq4Swyf8F18galvstKsR56cjr4oG4XngV0IKNbG+u+/LWqrI8i64PVhn5+wV8L9gwxF/F6tqh4uxoMLK1UAiQ+Pbwk7VTCiVgDAllIk8hAxGKXYN2e2i/ZjeP3jjvyClTYxBKEXWD+EqTflGnbLDs9yqcLgjwcpH+9csY6b7KCIbvFUY/CWJi9n7shRYZZHv3aTJAMbo3VpwDEOpXQXbrZw6mYF7OrHjWVWiMmUHhaVXk73gOx/DbyNp89UOa+t7wyk0A5coPii5wIDAQAB";

    //私钥
    private static String privateKeyStr = "MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC9KNra+lqVNto2DwKFC3XfcALpE8Peam+Q/N7NvmXDjz4CZXKh20nzXtSiLqn5CmR43LGiK9FgSrhLDJ/wXXyBqW+y0qxHnpyOvigbheeBXQgo1sb6778taqsjyLrg9WGfn7BXwv2DDEX8Xq2qHi7GgwsrVQCJD49vCTtVMKJWAMCWUiTyEDEYpdg3Z7aL9mN4/eOO/IKVNjEEoRdYP4SpN+UadssOz3KpwuCPBykf71yxjpvsoIhu8VRj8JYmL2fuyFFhlke/dpMkAxujdWnAMQ6ldBdutnDqZgXs6seNZVaIyZQeFpVeTveA7H8NvI2nz1Q5r63vDKTQDlyg+KLnAgMBAAECggEAYSK3sDdbiMBQMe5nRtbpwsGMXRAvRum1POj9qP2a2F+YYjaiNQec5ALQgjAgTKjPi1kZRsPlkuML3E4xW4dGRncxysxwd561mn9/rRKIHWAerooMSBQRQktCcu/DN34KkaO5NHgHIuKMldowp+kz7/CfLbNKwRdieoxtEYQV+L8rjCYOQUHJMez02G8N4IRkLmY73XlHKQmKBHSuLP/IKNZQbJrmr6Tsjj5NoBKHTSuuEY3QDDqMbZHNh3XYoYOVNnFbqDRjlUx4BLQgLpz5KBOxcV+xP5xyuPZuUlWuS9+3ADeiCptiTO9fDZHxZDHjw0qJo7KBWgLbL+e14KCO8QKBgQDsot+ZVJI9jpOoqPbej7jDDlRSo3zV73IfIHKPiNnbCRJgFUCYXIf6xtOi5+z908T1Cv3e6aQGW8pNUTwco1EMuNgMIPmITMoq6NWzBsbIVw+plIWpOzJQnIPsN8UZAAaxtP+DLrYCgOKDfQa7jKgMlgjWIzIovP7e2oG2eWKTewKBgQDMo207lNmvqIMr8LD3guEjN7GJOVp8yHKbpqMjZwwLoI3BADJDWef0nT/fyB1agfvq80IeA3f6H/ID0qztkNVEqfQWoDrN08Q8pn5K+GGXIirkSivzIM4+mV1SOHDgyoNks8pK2gGmG5bO3SvUlo1Q6MW1pXOrSVwJ0krltvTMhQKBgFIEhdGEQYe6ci1kGuS7FcPtpIZcCfmwm3J0caCUQ0Yq18abtx7X+32NCm+NSVQU4VA5dhKcEnDtwamYvWgDpyTssF1L1JFMZEoJF4CMmbt4iYIyaz1juiW8ifEGx3bJzogrfuA+AXHOsDP40quQrfJm0js+SbVbBE/Dlm/jlKofAoGAUuVQ9nXRyOqGWGJkDZ+i+9UvwdrN4QaCBrN2Gn0/z+X2BlzB/66H2/tnSIuT+Hn3RrHL8sSM8XHHY+0PyByHiA0gp5m4uHA0ai03s77yKXrZzSiOrSp44brWptvePfFLUJvUMoYlbNh4Osw1WSSzkjb5ACBJvvU0p3XciTmX6NECgYEAgoN0GvFls1A+Jhcr9BqVCk+jHcAUhxmQtuQjgGPnUUovrbCc/PtfiM9FKvpxa30SbBjW4t7itfqKLg1zpJcnCOhrhQl7QnnRpGFkRh9STA3xsjsp/dRS5popNR6iGOvEulgobWxK9Ogln61mreZFQSmHVjWPSQQOitJiKWmWxAI=";
//
//    static {
//        try {
//            generateRSAKey();
//        } catch (NoSuchAlgorithmException e) {
//            e.printStackTrace();
//        }
//    }
//
//    private static void generateRSAKey() throws NoSuchAlgorithmException {
//
//        KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");
//        keyPairGenerator.initialize(2048);
//        KeyPair keyPair = keyPairGenerator.generateKeyPair();
//        RSAPublicKey publicKey = (RSAPublicKey) keyPair.getPublic();
//        RSAPrivateKey privateKey = (RSAPrivateKey) keyPair.getPrivate();
//
//        publicKeyStr = Base64.getEncoder().encodeToString(publicKey.getEncoded());
//        privateKeyStr = Base64.getEncoder().encodeToString(privateKey.getEncoded());
//        System.out.println("公钥：" + publicKeyStr);
//        System.out.println("私钥：" + privateKeyStr);
//    }


    public static String buildToken(Authentication authentication) {
        try {
            //keyId 全数字的随机值
            String keyId = RandomStringUtils.random(32, false, true);

            JWSSigner jwsSigner = new RSASSASigner(getRSAPrivateKey(privateKeyStr));

            JWSHeader header = new JWSHeader.Builder(JWSAlgorithm.RS512).keyID(keyId).build();

            final String payloadText = "I am jonesun [RSA]";
            JWTClaimsSet claimsSet = new JWTClaimsSet.Builder()
                    .subject(authentication.getName())
                    .issuer("http://localhost:8080/web-server-jwt/")
                    // 设置登录用户的角色
                    .audience(authentication.getAuthorities().stream().map(GrantedAuthority::getAuthority).collect(Collectors.toList()))
                    .claim("payloadText", payloadText)
                    .expirationTime(new Date(System.currentTimeMillis() + EXPIRE_TIME))
                    .build();

            SignedJWT signedJWT = new SignedJWT(header, claimsSet);
            signedJWT.sign(jwsSigner);
            return signedJWT.serialize();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public static JWTClaimsSet verifyToken(String token) {
        SignedJWT jwt = null;
        try {
            jwt = SignedJWT.parse(token);
            //使用公钥 进行解密
            RSASSAVerifier rsassaVerifier = new RSASSAVerifier(getRSAPublicKey(publicKeyStr));
            //校验是否有效
            if (!jwt.verify(rsassaVerifier)) {
                //todo token无效
                return null;
            }
            return jwt.getJWTClaimsSet();
        } catch (ParseException | JOSEException | NoSuchAlgorithmException | InvalidKeySpecException e) {
            e.printStackTrace();
            return null;
        }
    }

    private static RSAPublicKey getRSAPublicKey(String publicKeyStr) throws NoSuchAlgorithmException, InvalidKeySpecException {
        // base64编码的公钥
        byte[] decoded = Base64.getDecoder().decode(publicKeyStr);
        return (RSAPublicKey) KeyFactory.getInstance("RSA").generatePublic(new X509EncodedKeySpec(decoded));
    }

    private static RSAPrivateKey getRSAPrivateKey(String privateKeyStr) throws NoSuchAlgorithmException, InvalidKeySpecException {
        byte[] decoded = Base64.getDecoder().decode(privateKeyStr);
        return (RSAPrivateKey) KeyFactory.getInstance("RSA").generatePrivate(new PKCS8EncodedKeySpec(decoded));
    }

}

```

3. 加入JwtLoginFilter过滤器-用于生成token

```java
import com.fasterxml.jackson.databind.ObjectMapper;
import com.jonesun.serverjwt.JWTUtils;
import com.jonesun.serverjwt.LoginUser;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationServiceException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.authentication.AbstractAuthenticationProcessingFilter;
import org.springframework.security.web.util.matcher.AntPathRequestMatcher;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.Map;

/**
 * 用户登录的过滤器
 * 在用户的登录的过滤器中校验用户是否登录成功
 * 如果登录成功，则生成一个 token 返回给客户端，登录失败则给前端一个登录失败的提示
 */
public class JwtLoginFilter extends AbstractAuthenticationProcessingFilter {


    public JwtLoginFilter(String defaultFilterProcessesUrl, AuthenticationManager authenticationManager) {
        super(new AntPathRequestMatcher(defaultFilterProcessesUrl));
        setAuthenticationManager(authenticationManager);
    }

    @Override
    public Authentication attemptAuthentication(HttpServletRequest req, HttpServletResponse httpServletResponse) throws AuthenticationException, IOException {
        // 支持json与form表单登录方式
        String contentType = req.getContentType();
        if (req.getContentType().startsWith(MediaType.APPLICATION_FORM_URLENCODED_VALUE)) {
            String username = req.getParameter("username");
            String password = req.getParameter("password");
            //进行登录校验，如果校验成功，会到 successfulAuthentication 的回调中，否则到 unsuccessfulAuthentication 的回调中
            return getAuthenticationManager().authenticate(new UsernamePasswordAuthenticationToken(username, password));
        } else if (req.getContentType().startsWith(MediaType.APPLICATION_JSON_VALUE)) {
            LoginUser loginUser = new ObjectMapper().readValue(req.getInputStream(), LoginUser.class);
            return getAuthenticationManager().authenticate(new UsernamePasswordAuthenticationToken(loginUser.getUsername(), loginUser.getPassword()));
        } else {
            throw new AuthenticationServiceException("contentType not supported: " + contentType);
        }
    }

    @Override
    protected void successfulAuthentication(HttpServletRequest request, HttpServletResponse resp, FilterChain chain, Authentication authentication) throws IOException, ServletException {
        String jwt = JWTUtils.buildToken(authentication);

        resp.setContentType("application/json;charset=utf-8");
        Map<String, String> map = new HashMap<>();
        map.put("token", jwt);
        map.put("msg", "登录成功");
        PrintWriter out = resp.getWriter();
        out.write(new ObjectMapper().writeValueAsString(map));
        out.flush();
        out.close();
    }

    @Override
    protected void unsuccessfulAuthentication(HttpServletRequest req, HttpServletResponse resp, AuthenticationException failed) throws IOException, ServletException {
        resp.setContentType("application/json;charset=utf-8");
        Map<String, String> map = new HashMap<>();
        map.put("msg", "登录失败");
        map.put("error", failed.getMessage());
        PrintWriter out = resp.getWriter();
        out.write(new ObjectMapper().writeValueAsString(map));
        out.flush();
        out.close();
    }
}
```

以上的LoginUser为简单的用户名密码，可自行添加字段:
```java
public class LoginUser implements Serializable {
    private String username;
    private String password;

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
}

```

4. 加入JwtFilter过滤器-用于验证接口token有效性

```java
import com.jonesun.serverjwt.JWTUtils;
import com.nimbusds.jwt.JWTClaimsSet;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.GenericFilterBean;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.util.List;
import java.util.stream.Collectors;

public class JwtFilter extends GenericFilterBean {

    private final Logger logger = LoggerFactory.getLogger(this.getClass());

    @Override
    public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain filterChain) throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) servletRequest;
        // 获取 token ，注意获取方式要跟前台传的方式保持一致
        // 这里请求时注意认证方式选择 Bearer Token，会用 header 传递
        String jwtToken = req.getHeader("authorization");
        if (jwtToken == null) {
            filterChain.doFilter(servletRequest, servletResponse);
            return;
        }

        //todo 校验后需做一些逻辑上的判断: 如是否为空、是否有效等
        JWTClaimsSet jwtClaimsSet = JWTUtils.verifyToken(jwtToken.replace("Bearer ", ""));
        // 获取用户名
        String username = jwtClaimsSet.getSubject();
        logger.info("username: " + username);

        // 获取用户角色，注意 "authorities" 要与生成 token 时的保持一致
        List<GrantedAuthority> authorities = jwtClaimsSet.getAudience().stream().map(SimpleGrantedAuthority::new).collect(Collectors.toList());
        UsernamePasswordAuthenticationToken token = new UsernamePasswordAuthenticationToken(username, null, authorities);
        
        //设置到Spring Security中，用于后面的校验(这步是关键)
        SecurityContextHolder.getContext().setAuthentication(token);
        filterChain.doFilter(servletRequest, servletResponse);
    }

}
```

5. 配置过滤器到WebSecurityConfig中

```java
import com.fasterxml.jackson.databind.ObjectMapper;
import com.jonesun.serverjwt.filter.JwtFilter;
import com.jonesun.serverjwt.filter.JwtLoginFilter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.NoOpPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

import javax.servlet.http.HttpServletResponse;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

/**
 * @author jone.sun
 * @date 2020-12-23 15:44
 */
@Configuration
public class WebSecurityConfig extends WebSecurityConfigurerAdapter {

    @Autowired
    private ObjectMapper objectMapper;

    @Bean
    public UserDetailsService userDetailsService() {
        //获取用户账号密码及权限信息
        return username -> User.withUsername("admin").password("123456").passwordEncoder(s -> s).roles("USER").build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        // todo 设置默认的加密方式 此处仅为演示用，实际项目请改为其他加密方式如BCryptPasswordEncoder采用了SHA-256 +随机盐+密钥对密码进行加密，更加安全
       //Spring Security默认使用DelegatingPasswordEncoder
        //PasswordEncoder passwordEncoder = PasswordEncoderFactories.createDelegatingPasswordEncoder();
        //return new BCryptPasswordEncoder();
        return NoOpPasswordEncoder.getInstance();
    }

    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {
        auth.userDetailsService(userDetailsService());
    }

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.authorizeRequests()
                .anyRequest().authenticated()
                .and()
                .addFilterBefore(new JwtLoginFilter("/login", authenticationManager()), UsernamePasswordAuthenticationFilter.class)
                .addFilterBefore(new JwtFilter(), UsernamePasswordAuthenticationFilter.class)
                .cors()
                .and()
                .csrf().disable()
                .exceptionHandling()
                //未登录
                .authenticationEntryPoint((req, resp, authException) -> {
                    resp.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    resp.setCharacterEncoding(StandardCharsets.UTF_8.toString());
                    resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    PrintWriter out = resp.getWriter();
                    Map<String, Object> map = new HashMap<>();
                    map.put("code", HttpServletResponse.SC_FORBIDDEN);
                    map.put("message", "未登录-token为空");
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
                });
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

6. 编写测试：这里我们还是用html演示，实际上可以改写为任意平台使用http发送请求即可

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
<form id="loginForm" action="http://localhost:8080/web-server-jwt/login" method="post">
    <div>
        <input type="text" name="username" placeholder="Username" value="admin"/>
    </div>
    <div>
        <input type="password" name="password" placeholder="Password" value="123456"/>
    </div>
    <input id="submitBtn" type="submit" value="登录" />
</form>
<input id="myBtn" type="button" value="模拟json登录" />
<script>

    $(function () {
        $('#loginForm').ajaxForm({
            beforeSubmit: validate,
            xhrFields: {withCredentials: true},    //前端适配：允许session跨域
            crossDomain: true,
            success: function(data) {
                //返回数据处理
                console.log(data);

                //测试是否可以获取到数据
                test("Bearer " + data.token);
            },
            error: function (ex) {
                alert(ex);
                console.log(ex);
            }
        });

        $("#myBtn").click(function(){
            $.ajax({
                type:"post",
                crossDomain: true,
                xhrFields: {
                    withCredentials: true
                },
                url:"http://localhost:8080/web-server-jwt/login",
                contentType: "application/json;charset=utf-8",
                data: JSON.stringify({"username":"admin","password":"123456"}),
                dataType: "json",
                success:function(data){
                    console.log(data);
                    test(data.token);
                },
                error: function (jqXHR, textStatus, errorThrown) {
                    console.error(jqXHR);
                    console.error(textStatus);
                    console.error(errorThrown);
                }
            });
        });
    });

    function validate() {
        console.log("校验参数");
    }

    function test(token) {
        $.ajax({
            type:"get",
            dataType: "json",
            crossDomain: true,
            xhrFields: {
                withCredentials: true
            },
            beforeSend: function(request) {
                // request.setRequestHeader("Authorization", sessionStorage.getItem("Authorization"));
                request.setRequestHeader("Authorization", token);
            },
            url:"http://localhost:8080/web-server-jwt/api/sayHello",
            success:function(data){
                console.log(data);
            },
            error: function (jqXHR, textStatus, errorThrown) {
                console.log("异常处理");
                console.error(jqXHR);
                console.error(textStatus);
                console.error(errorThrown);
                // if(jqXHR.status === 403) {
                //     //可以编写一个公共js, 遇到接口返回需要登录时统一跳转到登录页
                //     $(location).attr('href', 'login.html');
                // }
            }
        });
    }
</script>
</body>
</html>
```

[示例源码-jwt](https://github.com/jonesun/spring-security-demo/tree/master/jwt)

## 同时支持web表单、web前后端分离和jwt

日常有些项目可能需要支持后台管理页面+h5+app, 那就需要我们的后台服务同时支持web表单、web前后端分离和jwt等方式登录了

改写WebSecurityConfig即可: 

```java
import com.fasterxml.jackson.databind.ObjectMapper;
import com.jonesun.multiplehttpsecurityserver.filter.JwtFilter;
import com.jonesun.multiplehttpsecurityserver.filter.JwtLoginFilter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.WebAttributes;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

import javax.servlet.RequestDispatcher;
import javax.servlet.http.HttpServletResponse;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

@Configuration
public class MultiHttpSecurityConfig {


    @Bean
    public UserDetailsService userDetailsService() throws Exception {
        // ensure the passwords are encoded properly
        User.UserBuilder users = User.withDefaultPasswordEncoder();
        InMemoryUserDetailsManager manager = new InMemoryUserDetailsManager();
        manager.createUser(users.username("user").password("111111").roles("USER").build());
        manager.createUser(users.username("admin").password("123456").roles("USER", "ADMIN").build());
        return manager;
    }

    @Configuration
    @Order(1)
    public static class JwtApiWebSecurityConfigurationAdapter extends WebSecurityConfigurerAdapter {

        @Autowired
        private ObjectMapper objectMapper;

        @Override
        protected void configure(HttpSecurity http) throws Exception {
            http.
                    antMatcher("/app/**")
                    .authorizeRequests(authorize -> authorize
                            .anyRequest().hasRole("USER")
                    )
                    .addFilterBefore(new JwtLoginFilter("/app/login", authenticationManager()), UsernamePasswordAuthenticationFilter.class)
                    .addFilterBefore(new JwtFilter(), UsernamePasswordAuthenticationFilter.class)
                    .cors()
                    .and()
                    .csrf().disable()
                    .exceptionHandling()
                    //未登录
                    .authenticationEntryPoint((req, resp, authException) -> {
                        resp.setContentType(MediaType.APPLICATION_JSON_VALUE);
                        resp.setCharacterEncoding(StandardCharsets.UTF_8.toString());
                        resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                        PrintWriter out = resp.getWriter();
                        Map<String, Object> map = new HashMap<>();
                        map.put("code", HttpServletResponse.SC_FORBIDDEN);
                        map.put("message", "未登录-token为空");
                        out.write(objectMapper.writeValueAsString(map));
                        out.flush();
                        out.close();
                    })
                    //权限不足
                    .accessDeniedHandler((request, httpServletResponse, ex) -> {
                        ex.printStackTrace();
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
                    });
        }

    }

    @Configuration
    @Order(2)
    public static class ApiWebSecurityConfigurationAdapter extends WebSecurityConfigurerAdapter {

        @Autowired
        private ObjectMapper objectMapper;

        protected void configure(HttpSecurity http) throws Exception {

            http.antMatcher("/fore-web/**")
                    .authorizeRequests(authorize -> authorize
                            .anyRequest().hasRole("USER")
                    )
                    .cors()
                    .and()
                    .csrf().disable()
                    .formLogin()
                    .loginProcessingUrl("/fore-web/login")
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
    }

    @Configuration
    public static class FormLoginWebSecurityConfigurerAdapter extends WebSecurityConfigurerAdapter {

        @Autowired
        private ObjectMapper objectMapper;

        @Override
        protected void configure(HttpSecurity http) throws Exception {
            http
//                    .authorizeRequests(authorize -> authorize
//                            .anyRequest().authenticated()
//                    )
                    .authorizeRequests(authorize -> authorize
                            .anyRequest().hasRole("ADMIN")
                    )
                    .formLogin()
                    .loginPage("/login")
                    .permitAll()
                    .and() //权限不足
                    .exceptionHandling()
                    .accessDeniedHandler((request, httpServletResponse, ex) -> {
                        request.setAttribute(WebAttributes.ACCESS_DENIED_403, ex);
                        httpServletResponse.setStatus(HttpServletResponse.SC_FORBIDDEN);
                        RequestDispatcher dispatcher = request.getRequestDispatcher("forbidden");
                        dispatcher.forward(request, httpServletResponse);
                    });

//                    .formLogin(withDefaults());
        }
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

[示例源码-multiple-http-security](https://github.com/jonesun/spring-security-demo/tree/master/multiple-http-security)

## 使用数据库

以上代码都是模拟了用户数据，实际项目中更多的用户数据是保存在数据库中的，Spring Security提供了一个JdbcUserDetailsManager，下面我们就看下如何集成

1. 执行创建数据库表sql：

```mysql
CREATE SCHEMA if not exists `spring_security_test` ;

use `spring_security_test`;

CREATE TABLE users (
                       username VARCHAR(50) NOT NULL PRIMARY KEY,
                       password VARCHAR(500) NOT NULL,
                       enabled BOOLEAN NOT NULL
);
CREATE TABLE authorities (
                             username VARCHAR(50) NOT NULL,
                             authority VARCHAR(50) NOT NULL,
                             CONSTRAINT fk_authorities_users FOREIGN KEY (username)
                                 REFERENCES users (username)
);
create unique index ix_auth_username on authorities (username,authority);
```

> 这个是参考org/springframework/security/core/userdetails/jdbc/users.ddl，具体可根据自己的项目扩展

2. pom.xml 加入jdbc和mysql相关依赖

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-jdbc</artifactId>
    </dependency>
    <dependency>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
    </dependency>
</dependencies>

```

3. application.yml中加入数据库相关配置

```yaml
spring:
  datasource:
    password: root123
    url: jdbc:mysql://localhost:3306/spring_security_test?useUnicode=true&characterEncoding=UTF-8&serverTimezone=Asia/Shanghai
    username: root

```

2. 改写MultiHttpSecurityConfig的userDetailsService

```java
@Configuration
public class MultiHttpSecurityConfig {
    @Autowired
    DataSource dataSource;

    @Bean
    public UserDetailsService userDetailsService() throws Exception {
//        // ensure the passwords are encoded properly
//        User.UserBuilder users = User.withDefaultPasswordEncoder();
//        InMemoryUserDetailsManager manager = new InMemoryUserDetailsManager();
//        manager.createUser(users.username("user").password("111111").roles("USER").build());
//        manager.createUser(users.username("admin").password("123456").roles("USER", "ADMIN").build());

        JdbcUserDetailsManager manager = new JdbcUserDetailsManager();
        manager.setDataSource(dataSource);
        //todo 为测试方便手动加入两个用户 实际项目根据自己需要改为注册方式
        if (!manager.userExists("admin")) {
            manager.createUser(User.withUsername("admin").password("123456").roles("USER", "ADMIN").build());
        }
        if (!manager.userExists("user")) {
            manager.createUser(User.withUsername("user").password("111111").roles("USER").build());
        }
        return manager;
    }
}
```

### 使用Mybatis

国内项目中很多会集成Mybatis，改写为Mybatis也比较简单，我们来参考实现JdbcUserDetailsManager自己的MybatisUserDetailManager

1. 首先引入Mybatis，参考[SpringBoot-集成Mybatis](/2020/09/29/SpringBoot-集成Mybatis)

2. 编写自定义的UserDetailsService

```java
import com.jonesun.multiplehttpsecurityserver.dao.AuthorityDao;
import com.jonesun.multiplehttpsecurityserver.dao.UserDao;
import com.jonesun.multiplehttpsecurityserver.model.AuthorityDO;
import com.jonesun.multiplehttpsecurityserver.model.UserDO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import java.util.*;
import java.util.stream.Collectors;

public class MybatisUserDetailsService implements UserDetailsService {

    private final Logger logger = LoggerFactory.getLogger(getClass());

    @Autowired
    private UserDao userDao;

    @Autowired
    private AuthorityDao authorityDao;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        UserDO userDO = userDao.getByUsername(username);
        if (userDO == null) {
            this.logger.error("用户: " + username + "不存在");
            throw new UsernameNotFoundException("用户: " + username + "不存在");
        }
        List<AuthorityDO> authorityDOList = authorityDao.listByUsername(username);
        if (authorityDOList == null || authorityDOList.size() == 0) {
            this.logger.error("用户:  " + username + " 无任何权限");
            throw new UsernameNotFoundException("用户:  " + username + " 无任何权限");
        }

        List<GrantedAuthority> authorities = authorityDOList.stream()
                .map(authorityDO -> new SimpleGrantedAuthority(authorityDO.getAuthority()))
                .collect(Collectors.toList());


        return new User(userDO.getUsername(), userDO.getPassword(), userDO.getEnabled(),
                true, true, true, authorities);
    }

}
```

3. 改写改写MultiHttpSecurityConfig的userDetailsService

```java
@Configuration
public class MultiHttpSecurityConfig {
    @Bean
    public UserDetailsService userDetailsService() throws Exception {
        return new MybatisUserDetailsService();
    }
}

```

[示例源码-multiple-http-security](https://github.com/jonesun/spring-security-demo/tree/master/multiple-http-security)

> 如果是企业内部需要使用域账户来控制的，可以结合Spring LDAP使用，具体代码可自己搜索下

# Test

> 要使用Spring Security测试支持，必须加入spring-security-test依赖项

具体查看[官方教程](https://docs.spring.io/spring-security/site/docs/current/reference/html5/#test)

# Spring Security with OAuth2

以上都是单体应用的权限管理，现在Spring Cloud比较火，下面我们就看下如何在Spring Cloud下或者或者编写一个专门用于权限认证的微服务，这里就会涉及到OAuth2的概念了，推荐看下[OAuth 2.0 的一个简单解释](http://www.ruanyifeng.com/blog/2019/04/oauth_design.html)

## 选择哪个库?

使用SpringSecurity来实现OAuth2，之前网上的文章中大都推荐使用[spring-security-oauth](https://github.com/spring-projects/spring-security-oauth)，但目前(2020年12月)在其github上看到了这个: 

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

**所以答案是：使用Spring Security来实现Oauth2**

如果看到的博客或者代码中使用的groupId是

```xml
<dependency>
    <groupId>org.springframework.security.oauth</groupId>
    <artifactId>xxx</artifactId>
</dependency>
```

那使用的就是Spring Security OAuth项目，不建议使用(虽然也挺好用的，有兴趣可以找找相关资源看看，或者接手的项目使用的是这个的可以了解下): 

授权服务器(能够成功验证资源拥有者和获取授权，并在此之后分发令牌的服务器) [示例源码-oauth2-server](https://github.com/jonesun/spring-security-demo/tree/master/oauth2-server)
资源服务器(存储用户的数据资源，能够接受和响应受保护资源请求的服务器) [示例源码-oauth2-resource](https://github.com/jonesun/spring-security-demo/tree/master/oauth2-resource)

spring-cloud-starter-security也是依赖这个包的也尽量不要用。里面的类也被废弃了。

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-security</artifactId>
</dependency>
```

> 补充一点，最近发布的Spring cloud 2020.0.0版本已经[将Spring Cloud Security这个项目删除了](https://spring.io/blog/2020/12/22/spring-cloud-2020-0-0-aka-ilford-is-available) ，其代码已经移到了 Spring Cloud 各个子项目中了。

## 开始使用OAuth2

OAuth2.0 定义了四个角色:

- Client：客户端，第三方应用程序。
- Resource Owner：资源所有者，授权 Client 访问其帐户的用户。
- Authorization server：授权服务器，服务商专用于处理用户授权认证的服务器。
- Resource server：资源服务器，服务商用于存放用户受保护资源的服务器，它**可以与授权服务器是同一台服务器，也可以是不同的服务器**。

oauth2-server专用术语:

- Access token：用于访问受保护资源的令牌。
- Authorization code：发放给应用程序的中间令牌，客户端应用使用此令牌交换 access token。
- Scope：授予应用程序的权限范围。
- JWT：Json Web Token 是一种用于安全传输的数据传输格式

OAuth2.0 定义了四种授权模式，以应对不同情况时的授权:

- authorization_code: 授权码模式(功能最完整、流程最严密的授权模式，第三方如github提供的默认模式)
- implicit: 隐式授权模式(现已不推荐)
- password: 密码模式
- client_credentials: 客户端模式

> 刷新访问令牌(access token): 访问令牌有一个较短的存活时间，在过期后，客户端通过刷新令牌来获得新的访问令牌与刷新令牌。当用户长时间不活跃，刷新令牌也过期后，就需要重新获取授权

### 实现OAuth2客户端 spring-boot-starter-oauth2-client

以下都默认采用authorization_code授权码的方式

#### 使用Github作为授权服务器

1. 首先在Github中新增[OAuth App](https://github.com/settings/developers)

![github-new-oauth](github-new-oauth.png)

默认情况下，Spring Boot将此重定向URI配置为/login/oauth2/code/{registrationId}。因此回调地址填: http://localhost:8080/oauth2-client/login/oauth2/code/github

> 地址取决于你项目的配置，这里只是演示

2. 新建好Spring Boot项目，pom.xml中加入：

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-oauth2-client</artifactId>
    </dependency>
</dependencies>

```

> spring-boot-starter-oauth2-client，默认已经引用了Spring Security，因此不需要显式添加它

4. application.yml中加入配置

```yaml
server:
  port: 8080
  servlet:
    context-path: /oauth2-client

spring:
  security:
    oauth2:
      client:
        registration:
          github:
            client-id: <your client id>
            client-secret: <your client secret>
```

> client-id和client-secret从第一步中创建好的Github的OAuth App中获取

5. 创建测试Controller:
```java
@RestController
public class HelloController {

    @GetMapping
    public String sayHello() {
        return "hello world";
    }

}
```

打开浏览器访问http://localhost:8080/oauth2-client/，页面将会跳转到Github的授权页面，确认后即可访问api

> 除了GitHub外，Spring Security项目还包含Google、Facebook和Okta的默认配置。

#### 使用码云Gitee作为授权服务器

1. 类似Github，在码云中[创建第三方应用](https://gitee.com/oauth/applications/new)

![gitee-new-oauth](gitee-new-oauth.png)

回调地址写http://localhost:8080/oauth2-client/login/oauth2/code/gitee

2. application.yml中改写配置(由于官方并没有gitee的默认配置，故需要自己配置provider)

```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          github:
            client-id: <your client id>
            client-secret: <your client secret>
          gitee:
            provider: gitee
            client-id: <your client id>
            client-secret: <your client secret>
            authorizationGrantType: authorization_code
            redirectUri: "{baseUrl}/{action}/oauth2/code/{registrationId}"
            clientName: '码云'
        provider:
          gitee:
            authorization-uri: https://gitee.com/oauth/authorize
            token-uri: https://gitee.com/oauth/token
            user-info-uri: https://gitee.com/api/v5/user
            user-name-attribute: "name"

```

> client-id和client-secret从第一步中创建好的码云中的第三方应用中获取

3. 打开浏览器访问http://localhost:8080/oauth2-client/，页面将会Spring Security默认的OAuth 2.0的登录页，选择码云，确认后即可访问api

码云相关配置可参考[官网-OAuth文档](https://gitee.com/api/v5/oauth_doc#/) ，其他第三方如QQ、微信、新浪微博等都提供了OAuth2的授权服务，可以到各自官方网站查看说明即可

#### 自定义登录页

实际项目中肯定不会直接用默认的登录页, 需要实现自己的登录页

1. 编写LoginController，用于映射页面(为了方便读取数据pom.xml中引入thymeleaf)

```java
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.ResolvableType;
import org.springframework.security.oauth2.client.registration.ClientRegistration;
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.util.HashMap;
import java.util.Map;

@Controller
public class WebController {

    private static final String authorizationRequestBaseUri = "oauth2/authorization";
    Map<String, String> oauth2AuthenticationUrls = new HashMap<>();

    @Autowired
    private ClientRegistrationRepository clientRegistrationRepository;

    @GetMapping("/login")
    public String getLoginPage(Model model) {
        //将可用的客户端及其授权端点的映射发送到view
        Iterable<ClientRegistration> clientRegistrations = null;
        ResolvableType type = ResolvableType.forInstance(clientRegistrationRepository).as(Iterable.class);
        if (type != ResolvableType.NONE &&
                ClientRegistration.class.isAssignableFrom(type.resolveGenerics()[0])) {
            clientRegistrations = (Iterable<ClientRegistration>) clientRegistrationRepository;
        }

        clientRegistrations.forEach(registration ->
                oauth2AuthenticationUrls.put(registration.getClientName(),
                        authorizationRequestBaseUri + "/" + registration.getRegistrationId()));
        model.addAttribute("urls", oauth2AuthenticationUrls);

        return "login";
    }
}


```

2. 编写自定义的登录页login.html

```html
<!DOCTYPE html>
<html lang="en" xmlns:th="https://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <title>自定义OAuth2登录页</title>
</head>
<body>
    <h3>Login with:</h3>
    <p th:each="url : ${urls}">
        <a th:text="${url.key}" th:href="${url.value}">Client</a>
    </p>
</body>
</html>
```

3. 修改SecurityConfig配置

```java
@Configuration
public class SecurityConfig extends WebSecurityConfigurerAdapter {

    @Autowired
    ClientRegistrationRepository clientRegistrationRepository;

    @Autowired
    OAuth2AuthorizedClientService authorizedClientService;

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.authorizeRequests()
                .antMatchers("/login")
                .permitAll()
                .anyRequest()
                .authenticated()
                .and()
                .oauth2Login()
                .loginPage("/login")
                .clientRegistrationRepository(clientRegistrationRepository)
                .authorizedClientService(authorizedClientService);
    }

}

```

4. 打开浏览器访问http://localhost:8080/oauth2-client/，页面就显示我们自己的OAuth 2.0的登录页了，后面也可以同时支持用户名/密码登录的方式(MultiHttpSecurityConfig)


#### 自定义身份验证成功和失败

可以使用不同的方法来控制验证后的行为：

- defaultSuccessUrl() 和failureUrl() –将用户重定向到给定的URL
- successHandler() 和failureHandler() –在身份验证过程之后执行自定义逻辑

> 创建一个实现AuthenticationSuccessHandler或AuthenticationFailureHandler接口的类，重写继承的方法，然后使用successHandler() 和failureHandler()方法设置bean即可

[示例源码-oauth2-client](https://github.com/jonesun/spring-security-demo/tree/master/oauth2/oauth2-client)

### 实现OAuth2授权服务器

如果要自己实现OAuth2 的授权服务器，一个选择就是用第三方的例如[KeyCloak](https://www.keycloak.org/) ,
另外可以尝鲜[Spring Authorization Server](https://github.com/spring-projects-experimental/spring-authorization-server) -期待下正式版

> 另外还有一些授权服务器的提供商Keycloak和ForgeRock等，有兴趣可以了解下

#### 使用KeyCloak搭建OAuth2授权服务器

Keycloak是RedHat管理的开源身份和访问管理解决方案，由JBoss用Java开发。Spring Boot可以嵌入Keycloak, 当然Keycloak也可以作为独立服务器运行

[嵌入在Spring Boot应用程序中的Keycloak](https://www.baeldung.com/keycloak-embedded-in-spring-boot-app)

Keycloak目前的访问类型共有3种，可根据自己项目的需要进行配置：
- confidential：适用于服务端应用，且需要浏览器登录以及需要通过密钥获取access token的场景。典型的使用场景就是服务端渲染的web系统。
- public：适用于客户端应用，且需要浏览器登录的场景。典型的使用场景就是前端web系统，包括采用vue、react实现的前端项目等。
- bearer-only：适用于服务端应用，不需要浏览器登录，只允许使用bearer token请求的场景。典型的使用场景就是restful api。

1. 配置并添加Client(可参考网上一些教程)
![keycloak-new-client](keycloak-new-client.png)
   
2. OAuth2 Client项目中配置

```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          keycloak:
            provider: keycloak
            client-id: oauth2-client
            client-secret: d7a1acbc-40c8-4c68-a903-b5d01dac2a35
            authorizationGrantType: authorization_code
            redirectUri: "{baseUrl}/{action}/oauth2/code/{registrationId}"
            clientName: 'keycloak'
        provider:
          keycloak:
            issuer-uri: http://localhost:8083/auth/realms/jonesun
            authorization-uri: http://localhost:8083/auth/realms/jonesun/protocol/openid-connect/auth
            token-uri: http://localhost:8083/auth/realms/jonesun/protocol/openid-connect/token
            jwk-set-uri: http://localhost:8083/auth/realms/jonesun/protocol/openid-connect/certs
            user-info-uri: http://localhost:8083/auth/realms/jonesun/protocol/openid-connect/userinfo
```

> client-id默认为我们在keycloak创建的client名称、client-secret可以打开credentialsTab栏获取

3. 与之前使用github一样，打开浏览器测试OAuth2 Client项目即可，这里可以在Controller中获取到token信息client.getAccessToken().getTokenValue()，有了token就可以在任意资源服务器中获取资源了

#### 使用Spring Authorization Server搭建OAuth2授权服务器

先占个坑，刚在github看到目前的[0.0.3版本暂时还不支持Spring Boot 2.4.0](https://github.com/spring-projects-experimental/spring-authorization-server/issues/154)，等这个项目发布更稳定的版本后再研究下

> **以下为笔者草稿，不建议阅读，文章整理好后会进行删除**

### 实现OAuth2资源服务器 spring-boot-starter-oauth2-resource-server

1. pom.xml中加入引用
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
</dependency>
```
> spring-boot-starter-oauth2-resource-server, 默认已经引用了Spring Security，因此不需要显式添加它

2. application.yml中加入配置:

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          # 授权服务器将颁发的JWT令牌的iss声明中包含的值
          issuer-uri: http://localhost:8083/auth/realms/jonesun
          jwk-set-uri: http://localhost:8083/auth/realms/jonesun/protocol/openid-connect/certs
```

3. 配置ResourceServerConfig：

```java
@Configuration
public class ResourceServerConfig extends WebSecurityConfigurerAdapter {

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
                .mvcMatcher("/api/**")
                .authorizeRequests()
                .anyRequest().permitAll()
                .and()
                .oauth2ResourceServer(OAuth2ResourceServerConfigurer::jwt);
    }
}

```

4. 编写测试ApiController

```java
@RestController
@RequestMapping("/api")
public class ApiController {
    
    @GetMapping("/hello")
    public String apiHelloWorld() {
        return "apiHelloWorld";
    }

}
```

5. 使用测试工具如postman或编写测试代码，那之前OAuth2 Client登录获取到的token添加到Header中即可访问资源服务器受保护的资源

```
GET http://localhost:8180/oauth2-resource-server/api/hello
authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJJYV9uS2NHY1hkR3FNbWFTQ0RySkR2ZzNzYS1lN21RX2xRLTNnQkhocDAwIn0.eyJleHAiOjE2MDk0MDQ5MzUsImlhdCI6MTYwOTQwNDYzNSwiYXV0aF90aW1lIjoxNjA5NDAzODk0LCJqdGkiOiI1NzAwZTkwNS04ZmE1LTRkOWItOTdiYy1kYzVlYjIzZDY1ZjIiLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODMvYXV0aC9yZWFsbXMvam9uZXN1biIsImF1ZCI6ImFjY291bnQiLCJzdWIiOiJkYmYyMDE5Yi05N2U4LTQzZDQtOWEyNi00YTQzZGVhZmU5NjMiLCJ0eXAiOiJCZWFyZXIiLCJhenAiOiJvYXV0aDItY2xpZW50Iiwic2Vzc2lvbl9zdGF0ZSI6IjM3MmNlYmE3LThlZGItNDFhNi1iNWIwLWQxYTdmYThhMGNmMyIsImFjciI6IjAiLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsib2ZmbGluZV9hY2Nlc3MiLCJ1bWFfYXV0aG9yaXphdGlvbiJdfSwicmVzb3VyY2VfYWNjZXNzIjp7ImFjY291bnQiOnsicm9sZXMiOlsibWFuYWdlLWFjY291bnQiLCJtYW5hZ2UtYWNjb3VudC1saW5rcyIsInZpZXctcHJvZmlsZSJdfX0sInNjb3BlIjoicHJvZmlsZSBlbWFpbCBqb25lc3Vuc2VjdXJpdHkiLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsIm5hbWUiOiJqb25lIHN1biIsInByZWZlcnJlZF91c2VybmFtZSI6ImpvbmVzdW4iLCJnaXZlbl9uYW1lIjoiam9uZSIsImZhbWlseV9uYW1lIjoic3VuIiwiZW1haWwiOiJzdW5qb25lcjdAZ21haWwuY29tIn0.XuqlW8Ry9Le7_0Aao8e1WGfUmSnEz27P3vFK44toQJaN7XVNqVkdOKTt36JgV6ctguRyaDT1xmow78Y1yZM-5_Ki74aLHWsHgt9aITxdMRNygW6WC3dY3y9-8EcHkh8WgvDbTr58JNEmerSCkC7UFPvhKPcvfQGTjG1XmDwmTDTP7umhZBK408HxLjqJWr6GulIGya_QCJrLCCoO5QDhsiT5tfGqaANtQapfC-TS11NvEoPP9U2oqUtJ6xdosT9AIj9BZbpezCQ5nsE5zb5XvKvmph45VDPa2l9y9YMpdnECTvIX7hEyyMEu_nQfZcyASUazOpyv7Q95fCBEhABUcg
Content-Type: application/x-www-form-urlencoded
```

综上，**就可以实现在OAuth Client中使用OAuth授权服务器(或第三方授权登录)，拿到token后访问OAuth资源服务器中的相关资源**

![OAuth2流程](OAuth2流程.png)

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


# security oauth2 整合的3个核心配置类

1. 资源服务配置 ResourceServerConfiguration

2. 授权认证服务配置 AuthorizationServerConfiguration

3. security 配置 SecurityConfiguration



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



spring-security-data

**security-spring的使用参考[Spring Security Reference 官方网站](https://docs.spring.io/spring-security/site/docs/current/reference/html5/)
和大神baeldung的文章[Spring Security OAuth 2指南](https://www.baeldung.com/spring-security-oauth)**