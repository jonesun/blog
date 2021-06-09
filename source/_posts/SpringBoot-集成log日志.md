---
title: SpringBoot-集成log日志
date: 2020-07-24 17:04:02 
categories: [java,springboot]
tags: [java, springboot]
---

# 前言

日志是开发过程中必不可少的模块，出现异常后可以通过查看日志看排查原因

# 使用

## 常用日志框架

> JDK Logging

JDK提供的日志框架，由于自身有些局限性，故不太流行

> Commons Logging

Commons Logging是一个第三方日志库，它是由Apache创建的日志模块。Commons Logging的特色是，它可以挂接不同的日志系统，并通过配置文件指定挂接的日志系统。默认情况下，Commons
Loggin自动搜索并使用Log4j（Log4j是另一个流行的日志系统），如果没有找到Log4j，再使用JDK Loggin

> Log4j

Apache的提供的一种日志实现，现已不推荐使用

> SLF4J

SLF4J类似于Commons Logging，也是一个日志接口，比Commons Logging更加好用，现在流行程度也更高

> Logback

Logback是由log4j创始人设计的另一个开源日志组件，性能比Log4j要高很多

> Log4j2

Log4j的重构版，性能提升很多，尤其在多线程环境下，性能也高于Logback

**一般使用SLF4J提供的接口，引入Logback或者Log4j2**

## 集成

SpringBoot2默认已经集成了logback，如果不想修改可直接在resource中新建logback.xml进行配置即可。

不过一般都推荐使用log4j2(SpringBoot2高版本已经不再支持log4j)，故可以在pom.xml中修改引用:

```xml
<dependencies>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <!-- 去掉logback配置 -->
    <exclusions>
      <exclusion>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-logging</artifactId>
      </exclusion>
    </exclusions>
  </dependency>
  <!-- 引入log4j2依赖 -->
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-log4j2</artifactId>
  </dependency>

  //如果没有引入web模块，则
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter</artifactId>
    <exclusions>
      <exclusion>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-logging</artifactId>
      </exclusion>
    </exclusions>
  </dependency>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-log4j2</artifactId>
  </dependency>

</dependencies>

```

在resource中新建log4j2-spring.xml(或者log4j2.xml)进行配置即可

喜欢yml格式的话，加入支持yml格式

```xml
 <dependency><!-- 支持yml格式 -->
    <groupId>com.fasterxml.jackson.dataformat</groupId>
    <artifactId>jackson-dataformat-yaml</artifactId>
</dependency>
```

在resources目录下新建log4j2.yml进行配置(推荐使用yml格式)

> 相比与其他的日志系统，log4j2丢数据这种情况少；disruptor技术，在多线程环境下，性能高于logback等10倍以上；利用jdk1.5并发的特性，减少了死锁的发生

## 应用

需要注意的时，一般推荐使用slf4j(这里使用了设计模式中的外观模式或者叫门面模式),方便灵活的替换日志组件:

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

private static final Logger logger = LoggerFactory.getLogger(TestService.class);

//打印日志

logger.info("xxxxxxxxxxxxxxx");
```

> 日志级别从低到高分为TRACE < DEBUG < INFO < WARN < ERROR < FATAL，只会输出大于或等于设置级别的内容

## 配合lombok

如果项目使用了lombok插件，则引用可直接在类上注解即可:

```java
@Slf4j
public class Main {
  
  public static void main(Strin[] args) {
    log.error("Something else is wrong here");
  }
}
```

# 拼接字符串

SLF4J的日志接口可以这样来拼接字符串:

```java
int score = 99;
logger.info("Set score {} for Person {} ok.", score, p.getName());
```

## 使用日志的好处

如果使用日志有很多好处：

* 可以设置输出样式，避免自己每次都写"ERROR: " + var；
* 可以设置输出级别，禁止某些级别输出。例如，只输出错误日志；
* 可以被重定向到文件，这样可以在程序运行结束后查看日志；
* 可以按包名控制日志级别，只输出某些包打的日志；
* 可以输出到不同的目的地：
    * console：输出到屏幕；
    * file：输出到文件；
    * socket：通过网络输出到远程计算机；
    * jdbc：输出到数据库
* ……

日常开发中有些童鞋在跟进bug时会习惯性的使用**System.out.println()**来打印log日志，然后再删除掉，下次再出现问题再打印，可以自己考虑哪个更好

[log42j官方配置参考](https://logging.apache.org/log4j/2.x/manual/layouts.html)

[springboot推荐配置](https://www.baeldung.com/spring-boot-logging)

> 控制台打印的日志配上颜色

在配置文件的PatternLayout标签里指定disableAnsi="false" noConsoleNoAnsi="false"

```xml
        <Console name="Console" target="SYSTEM_OUT">
            <PatternLayout disableAnsi="false" noConsoleNoAnsi="false"
                    pattern="%style{%d{ISO8601}} %highlight{%-5level }{ERROR=Bright RED, WARN=Bright Yellow, INFO=Bright Green, DEBUG=Bright Cyan, TRACE=Bright White}[%style{%t}{bright,blue}] %l: %msg%n%style{%throwable}{red}" />
        </Console>
```

> 动态设置日志保存路径

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Configuration>
    <properties>
        <property name="LOG_HOME">${sys:user.dir}</property>
        <property name="FILE_FOLDER">spring-boot-test</property>
    </properties>
    <Appenders>

        <Console name="Console" target="SYSTEM_OUT">
            <PatternLayout disableAnsi="false" noConsoleNoAnsi="false"
                           pattern="%highlight{%d [%t] %-5level %l: %msg%n%throwable}{ERROR=Bright RED, WARN=Bright Yellow, INFO=Normal, DEBUG=Bright Blue, TRACE=Bright White}"/>
        </Console>


        <RollingFile name="RollingFile"
                     fileName="${LOG_HOME}/${FILE_FOLDER}/logs/logger-log4j2.log"
                     filePattern="${LOG_HOME}/${FILE_FOLDER}/logs/$${date:yyyy-MM}/logger-log4j2-%d{-dd-MMMM-yyyy}-%i.log.gz">
            <PatternLayout>
                <pattern>%d %p %C{1.} [%t] %m%n</pattern>
            </PatternLayout>
            <Policies>
                <!-- rollover on startup, daily and when the file reaches
                    10 MegaBytes -->
                <OnStartupTriggeringPolicy/>
                <SizeBasedTriggeringPolicy size="10 MB"/>
                <TimeBasedTriggeringPolicy/>
            </Policies>
        </RollingFile>
    </Appenders>

    <Loggers>
        <!-- LOG everything at INFO level -->
        <Root level="info">
            <AppenderRef ref="Console"/>
            <AppenderRef ref="RollingFile"/>
        </Root>

        <!-- LOG "com.jonesun*" at TRACE level -->
        <Logger name="org.jonesun" level="debug"/>
    </Loggers>

</Configuration>
```

## 异步日志

> 官方建议一般程序员查看的日志改成异步方式，一些运营日志改成同步。日志异步输出的好处在于，使用单独的进程来执行日志打印的功能，可以提高日志执行效率，减少日志功能对正常业务的影响。

Log4j2中的异步日志实现方式有两种:

* AsyncAppender采用了ArrayBlockingQueue来保存需要异步输出的日志事件
* AsyncLogger则使用了Disruptor框架来实现高吞吐

### AsyncAppender

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Configuration>
    <Appenders>
        ...
        <!-- AsyncAppender配置 -->
        <Async name="asyncTest" blocking="true">
            <AppenderRef ref="RollingFile"/>
        </Async>
    </Appenders>


    <Loggers>
        ...
        <Root level="info">
            <AppenderRef ref="Console"/>
            <!--            <AppenderRef ref="RollingFile"/>-->
            <AppenderRef ref="asyncTest"/>
        </Root>
    </Loggers>
</Configuration>
```

### AsyncLogger

AsyncLogger需要加载disruptor-3.0.0.jar或者更高的版本(pom.xml)：

```xml
<!-- log4j2异步日志需要加载disruptor-3.0.0.jar或者更高的版本 -->
<dependency>
  <groupId>com.lmax</groupId>
  <artifactId>disruptor</artifactId>
  <version>3.4.2</version>
</dependency>
```

配置文件loggers改为(或者新增Appender再配置给异步):

```xml
    <Loggers>
<!--        &lt;!&ndash; LOG everything at INFO level &ndash;&gt;-->
<!--        <Root level="info">-->
<!--            <AppenderRef ref="Console" />-->
<!--            <AppenderRef ref="RollingFile" />-->
<!--        </Root>-->

        <!-- LOG "com.baeldung*" at TRACE level -->
        <Logger name="com.jonesun" level="trace"/>

        <asyncRoot level="info" includeLocation="true">
            <appender-ref ref="Console" />
            <appender-ref ref="RollingFile" />
        </asyncRoot>
    </Loggers>
```

# 高阶

随着业务量的提高，普通日志已经满足不了需求，此时可以引入Elasticsearch，使用[ELK](/2020/07/21/SpringBoot应用整合ELK实现日志收集)
来搭建日线日志系统，，这几个组件都挺能抢内存的，elasticsearch默认就要2g内存，线上机器性能不够的话，还是乖乖使用原始log收集