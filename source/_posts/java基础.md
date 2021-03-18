---
title: java基础
date: 2020-08-11 13:44:00
categories: [java]
tags: [java]
top: 1000
---

# 基础

[java-引用](/2020/11/30/java-引用)

[java-集合](/2020/10/14/java-集合)

[java-时间](/2020/10/22/java-时间)

[java-io](/2020/10/22/java-io)

[java-随机数](/2020/07/13/java随机数)

## 高级

[java多线程](/2020/08/01/java多线程)

[java设计模式](/2020/08/11/java设计模式)

[SpringBoot集成使用](/2020/10/09/SpringBoot集成使用)

## 资料整理

[Java新特性](https://sunr7.gitee.io/java-new-features/) Java9之后到Java14

[Java8特性介绍](https://sunr7.gitee.io/java8-learning/) 

[RxJava学习](https://sunr7.gitee.io/rxjava_learning/) 

 <!-- more -->

# 开发小技巧

[java8开发小技巧-获取两个时间的时间差](/2020/08/12/java8开发小技巧-获取两个时间的时间差)

[JMH-Java微基准测试套件](/2020/07/20/JMH-Java微基准测试套件)


> 使用```System.getProperties().list(System.out);```可输出可用的环境信息列表, 或者使用System.getenv()获取map


> float 和 double 类型主要是为了科学计算和工程计算而设计的。它们执行二进制浮点运算（binary floating-point arithmetic），这是为了在广泛的数值范围上提供较为精确为快速的近似计算而精心设计的。
然而，它们并没有提供完全精确的结果，所以不应该被用于需要精确结果的场合。
使用 BigDecimal、int 或者 long 进行货币计算(如果数值范围没有超过 9 为十进制数字，就可以使用 int；如果不超过 18 位数字，就可以使用 long。
如果数值可能超过 18 位数字，就必须使用 BigDecimal。)