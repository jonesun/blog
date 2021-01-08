---
title: SpringBoot集成使用
date: 2020-10-09 10:16:56
categories: [java,springboot]
tags: [java, springboot]
top: 999
---

# 目录

> SpringBoot版本为2.x, 2.4.0开始版本号没有.RELEASE后缀

[SpringBoot-Starters](/2020/12/26/SpringBoot-Starters)

## 第三方组件

[SpringBoot-集成log日志](/2020/07/24/SpringBoot-集成log日志)

[SpringBoot-集成Mybatis](/2020/09/29/SpringBoot-集成Mybatis)

[SpringBoot-集成swagger3](/2020/10/10/SpringBoot-集成swagger)

[SpringBoot-集成Redis](/2020/08/26/SpringBoot-集成Redis)

[SpringBoot-SpringSecurity5整合](/2020/07/22/SpringBoot-SpringSecurity整合)

[SpringBoot-集成websocket](/2020/09/04/SpringBoot-集成websocket)

[SpringBoot应用整合ELK实现日志收集](/2020/07/21/SpringBoot应用整合ELK实现日志收集)

[SpringBoot-监控](/2020/11/20/SpringBoot-监控)

[SpringBoot-集成flyway实现数据库版本控制](/2020/12/09/SpringBoot-集成flyway实现数据库版本控制)

[SpringBoot-SpringInitializr说明](/2020/12/07/SpringBoot-SpringInitializr说明)

## 开发小技巧

[SpringBoot开发小技巧-对象属性拷贝BeanUtils.copyProperties](/2020/08/31/SpringBoot开发小技巧-对象属性拷贝BeanUtils.copyProperties)

[SpringBoot开发小技巧-打印Mybatis中的sql语句](/2020/08/17/SpringBoot开发小技巧-打印Mybatis中的sql语句)

[screw-简洁好用的数据库表结构文档生成工具](https://toscode.gitee.com/leshalv/screw/tree/master)

<!-- more -->


## 推荐idea插件

* Maven Helper: 查看Maven引入的jar包是否有冲突
* Codota: 右键选中代码会提示很多相关API用法，节省不少查阅资料的时间
* IntelliJad：是一个Java class文件的反编译工具，可以对Jar选择class文件右键Decompile，会出现反编译的结果

## 开发者工具

添加如下依赖到pom.xml：

```
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-devtools</artifactId>
    <scope>runtime</scope><!-- -->
    <optional>true</optional>
</dependency>
```

修改源码后，使用快捷键Ctrl + F9手动构建项目后，Spring Boot会自动重新加载

> 默认配置下，针对/static、/public和/templates目录中的文件修改，不会自动重启，因为禁用缓存后，这些文件的修改可以实时更新

如果不想手动构建，需要对IDEA做一些[配置更改](https://stackoverflow.com/questions/53569745/spring-boot-developer-tools-auto-restart-doesnt-work-in-intellij)

使用springboot的maven插件spring-boot-maven-plugin，可以直接打出可运行的jar：

```
mvn clean package
```

运行后在target文件夹下就可以看到jar了，直接用Java命令即可运行:

```
java -jar springboot-demo-jar-1.0-SNAPSHOT.jar
```

如果不喜欢默认的项目名+版本号作为运行jar文件名，可以加一个配置指定文件名:
``` xml
<project ...>
    ...
    <build>
        <finalName>xxx-app</finalName>
        ...
    </build>
</project>
```

## 测试

> springboot2.x的版本, 默认使用的是junit5版本, junit4和junit5两个版本差别比较大，需要注意下用法

![junit5vsjunit4](junit5vsjunit4.png)

```java
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;


@SpringBootTest
class MySpringTestBeanTest {

    @Autowired
    XXX xxx;

    @Test
    public void xxxTest() {
        xxx.sayHello();
    }

}
```

测试样例可以参考[官方教程](https://docs.spring.io/spring-framework/docs/current/reference/html/testing.html#spring-mvc-test-framework)

## 运行监控

Spring Boot内置了一个监控功能Actuator:

```
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

运行项目后输入http://localhost:8080/actuator，可以查看应用程序当前状态

默认只有health和info可使用web访问，要暴露更多的[访问点](https://docs.spring.io/spring-boot/docs/current/reference/html/production-ready-features.html#production-ready-endpoints)给Web，需要在application.yml中加上配置：
```
management:
  endpoints:
    web:
      exposure:
        include: info, health, beans, env, metrics
```

常用的如下: 

Endpoint ID | Description
---|---
auditevents | 显示应用暴露的审计事件 (比如认证进入、订单失败)
info | 显示应用的基本信息
health | 显示应用的健康状态
metrics | 显示应用多样的度量信息
loggers | 显示和修改配置的loggers
logfile | 返回log file中的内容(如果logging.file或者logging.path被设置)
httptrace | 显示HTTP足迹，最近100个HTTP request/repsponse
env | 显示当前的环境特性
flyway | 显示数据库迁移路径的详细信息
liquidbase | 显示Liquibase 数据库迁移的纤细信息
shutdown | 让你逐步关闭应用
mappings | 显示所有的@RequestMapping路径
scheduledtasks | 显示应用中的调度任务
threaddump | 执行一个线程dump
heapdump | 返回一个GZip压缩的JVM堆dump


### 在运行时改变日志等级

loggers endpoint也允许你在运行时改变应用的日志等级。

举个例子，为了改变root logger的等级为DEBUG ，发送一个POST请求到http://localhost:8080/actuator/loggers/root，加入如下参数:

```json
{
   "configuredLevel": "DEBUG"
}
```

**这个功能对于线上问题的排查非常有用。**

同时，你可以通过传递null值给configuredLevel来重置日志等级。


> spring-boot-autoconfigure 包含了Spring Boot对于第三方库的自动配置，在编写自定义配置时可以参考使用

如果是idea使用gradle编译的话，如果出现中文乱码则打开Help>Edit Custom VM Options，在最后一行加上:

```
-Dfile.encoding=UTF-8
```
## 最佳实践

推荐使用@Autowired(@Qualifier告诉Spring具体去装配哪个对象), @Resource(javax.annotation.Resource) 在 Jdk 11中已经移除，如果要使⽤，需要单独引⼊jar包：

```xml
<dependency>
    <groupId>javax.annotation</groupId>
    <artifactId>javax.annotation-api</artifactId>
    <version>1.3.2</version>
</dependency>
```

@Component注解默认实例化的对象是单例，如果想声明成多例对象可以使用@Scope(“prototype”), Scope的全部可选项
* singleton 全局只有一个实例，即单例模式
* prototype 每次注入Bean都是一个新的实例
* request 每次HTTP请求都会产生新的Bean
* session 每次HTTP请求都会产生新的Bean，该Bean在仅在当前session内有效
* global session 每次HTTP请求都会产生新的Bean，该Bean在 当前global Session（基于portlet的web应用中）内有效

对于不常使⽤的 Bean 设置延迟加载，这样偶尔使⽤的时候再加载，不必要从⼀开始该 Bean 就占 ⽤资源

在Bean的初始化和清理方法上标记@PostConstruct和@PreDestroy

先使用@PropertySource读取配置文件，然后通过@Value以${key:defaultValue}的形式注入，可以极大地简化读取配置的麻烦

Profile: 创建某个Bean时，Spring容器可以根据注解@Profile来决定是否创建

Conditional: Spring还可以根据@Conditional决定是否创建某个Bean

FactoryBean可以⽣成某⼀个类型的Bean实例，也就是说我们可以借助于它⾃定义Bean的创建过程，实现FactoryBean接口即可(获取FactoryBean，需要在id之前添加“&”)。

如果你想要将第三方库中的组件装配到你的应用中，在这种情况下，是没有办法在它的类上添加@Component注解的，因此就不能使用自动化装配的方案了，但是我们可以使用@Bean。