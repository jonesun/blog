---
title: SpringBoot-集成log日志
date: 2020-07-24 17:04:02
categories: [java,springboot]
tags: [java, springboot]
---

# 前言

日志是开发过程中必不可少的模块，出现异常后可以通过查看日志看排查原因

# 使用

## 集成

SpringBoot2默认已经集成了logback，如果不想修改可直接在resource中新建logback.xml进行配置即可。

不过一般都推荐使用log4j2(SpringBoot2高版本已经不再支持log4j)，故可以在pom.xml中修改引用:

```
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

```

在resource中新建log4j2-spring.xml(或者log4j2.xml)进行配置即可

喜欢yml格式的话，加入支持yml格式

```
//喜欢yml格式的话，加入支持yml格式
 <dependency><!-- 支持yml格式 -->
    <groupId>com.fasterxml.jackson.dataformat</groupId>
    <artifactId>jackson-dataformat-yaml</artifactId>
</dependency>
```
在resources目录下新建log4j2.yml进行配置(推荐使用yml格式)

> 相比与其他的日志系统，log4j2丢数据这种情况少；disruptor技术，在多线程环境下，性能高于logback等10倍以上；利用jdk1.5并发的特性，减少了死锁的发生


## 应用

需要注意的时，一般推荐使用slf4j(这里使用了设计模式中的外观模式或者叫门面模式),方便灵活的替换日志组件:

```
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

private static final Logger logger = LoggerFactory.getLogger(TestService.class);

//打印日志

logger.info("xxxxxxxxxxxxxxx");
```

> 日志级别从低到高分为TRACE < DEBUG < INFO < WARN < ERROR < FATAL，只会输出大于或等于设置级别的内容

## 配合lombok

如果项目使用了lombok插件，则引用可直接在类上注解即可:

```
@Slf4j
public class Main {
  
  public static void main(Strin[] args) {
    log.error("Something else is wrong here");
  }
}
```

# 高阶

随着业务量的提高，普通日志已经满足不了需求，此时可以引入Elasticsearch，使用[ELK](/2020/07/21/SpringBoot应用整合ELK实现日志收集)来搭建日线日志系统，，这几个组件都挺能抢内存的，elasticsearch默认就要2g内存，线上机器性能不够的话，还是乖乖使用原始log收集