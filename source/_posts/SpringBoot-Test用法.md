---
title: SpringBoot-Test用法
date: 2021-03-05 17:18:09
categories: [java,springboot]
tags: [java, springboot]
---

# 前言

使用idea新建SpringBoot项目时，大家应该会发现除了正常的src/main文件夹之外，还会有个test文件夹，相应的会引入spring-boot-starter-test模块，
本文就来聊聊这个test模板的用法

说到test大家都会想到junit，是的spring-boot-starter-test默认集成的就是junit，但需要注意的是：springboot2.x的版本, 默认使用的是[junit5](https://junit.org/junit5/docs/current/user-guide/) 版本, junit4和junit5两个版本差别比较大，需要注意下用法：

![junit5vsjunit4](junit5vsjunit4.png)

 <!-- more -->

## 为什么使用JUnit5

- JUnit4被广泛使用，但是许多场景下使用起来语法较为繁琐，JUnit5中支持lambda表达式，语法简单且代码不冗余。
- JUnit5易扩展，包容性强，可以接入其他的测试引擎。
- 功能更强大提供了新的断言机制、参数化测试、重复性测试等新功能。
- ...

如无特殊说明，直接使用junit5相关api(org.junit.jupiter.api.*, 这是junit5引入的;  junit4引入的是org.junit.Test这样类似的包)

# 引入

1. pom.xml中加入spring-boot-starter-test模块(一般会默认引入)：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
```

> 需要注意的是SpringBoot2.2开始会需要排除junit-vintage-engine，这个是因为早期的junit5默认引入了junit-vintage-engine用于运行junit4测试(junit-jupiter-engine用于junit5测试), 一般新的项目无需junit4，因此POM中的默认依赖项排除在外

```xml
 <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
    <exclusions>
        <exclusion>
            <groupId>org.junit.vintage</groupId>
            <artifactId>junit-vintage-engine</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

> 但从SpringBoot2.4.0开始spring-boot-starter-test中的junit5已经默认移除了junit-vintage-engine，所以就无需手动排除了

当然，如果有写老的测试代码还是使用了junit4相关api的话:

- SpringBoot 2.2到2.4.0之前，只要将手动排除的代码注释掉即可
- SpringBoot 2.4.0之后，需要手动添加junit-vintage-engine:

```xml
<dependency>
    <groupId>org.junit.vintage</groupId>
    <artifactId>junit-vintage-engine</artifactId>
    <scope>test</scope>
    <exclusions>
        <exclusion>
            <groupId>org.hamcrest</groupId>
            <artifactId>hamcrest-core</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

**看好实际项目中使用的SpringBoot版本**

# 使用

**junit5使用的都是org.junit.jupiter.xxx**

1. 在测试类加入@SpringBootTest：这个注解是SpringBoot自1.4.0版本开始引入的一个用于测试的注解，这样一般就可以了，不用加@RunWith(SpringRunner.class)，这个是junit4的注解

2. 在测试方法中加入@Test: 注意是org.junit.jupiter.api.Test

```java
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class MyApplicationTests {

    @Test
    void contextLoads() {
        //xxx
    }

}

```

右击代码即可运行测试

# @DisplayName()测试显示中文名称

```java
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@DisplayName("测试1")
@SpringBootTest
class StandAloneServerApplicationTests {

    @DisplayName("测试方法1")
    @Test
    void contextLoads() {
        //xxx
    }

}

```

![displayName](displayName.png)

# 指定测试顺序

```java
import org.junit.jupiter.api.*;
import org.springframework.boot.test.context.SpringBootTest;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@DisplayName("测试1")
@SpringBootTest
class StandAloneServerApplicationTests {

    @Order(2)
    @DisplayName("测试方法1")
    @Test
    void contextLoads() {

    }

    @Order(1)
    @DisplayName("测试方法2")
    @Test
    void test2() {

    }

}

```

更多其他注解用法，可查阅官方文档 [writing-tests-annotations](https://junit.org/junit5/docs/current/user-guide/#writing-tests-annotations)

-- 未完，抽时间继续整理整理 --