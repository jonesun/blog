---
title: java基础
categories:
  - java
tags:
  - java
top: 1000
abbrlink: b8b0eacd
date: 2020-08-11 13:44:00
---

# 基础

[java-引用](/20201130/java/aee68e6b)

[java-集合](/20201014/java/b4ef74d7)

[java-时间](/20201022/java/1956c086)

[java-io](/20201022/java/ddadecb7)

[java-随机数](/20200713/java/3a0ad540)

## 高级

[java多线程](/20200801/java/多线程/11bde6ec)

[java设计模式](/20200811/java/designPatterns/56df777e)

[SpringBoot集成使用](/20201009/java/springboot/7b2ee301)

[SpringCloud集成使用](/20210319/java/springcloud/55535)

## 资料整理

[Java新特性](https://jonesun.gitee.io/java-new-features/) Java9之后到Java14

[Java8特性介绍](https://jonesun.gitee.io/java8-learning/) 

[RxJava学习](https://jonesun.gitee.io/rxjava_learning/) 

 <!-- more -->

# 开发小技巧

[java8开发小技巧-获取两个时间的时间差](/20200812/java/java8/16e93703)

[JMH-Java微基准测试套件](/20200720/java/520c60c5)


> 使用```System.getProperties().list(System.out);```可输出可用的环境信息列表, 或者使用System.getenv()获取map


> float 和 double 类型主要是为了科学计算和工程计算而设计的。它们执行二进制浮点运算（binary floating-point arithmetic），这是为了在广泛的数值范围上提供较为精确为快速的近似计算而精心设计的。
然而，它们并没有提供完全精确的结果，所以不应该被用于需要精确结果的场合。
使用 BigDecimal、int 或者 long 进行货币计算(如果数值范围没有超过 9 为十进制数字，就可以使用 int；如果不超过 18 位数字，就可以使用 long。
如果数值可能超过 18 位数字，就必须使用 BigDecimal。)

# 面试常问

内存泄露怎么分析？怎么知道整条内存泄露的链路？

一般方法，jmap dump出转储文件，然后通过MAT等一些工具来做具体的分析。

怎么查看jvm里线程状态？

jstack进程ID就可以了