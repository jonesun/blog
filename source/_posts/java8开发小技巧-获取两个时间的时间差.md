---
title: java8开发小技巧-获取两个时间的时间差
categories:
  - java
  - java8
tags:
  - java
  - java8
abbrlink: '16e93703'
date: 2020-08-12 10:52:32
---

日常开发中经常会需要计算一个方法执行了多久:

```
long startTime = System.currentTimeMillis();

//模拟方法执行，花费2s
TimeUnit.SECONDS.sleep(2);

long endTime = System.currentTimeMillis();

System.out.println("花费 " + (endTime - startTime) + " 毫秒");
```

java8之后提供了新的时间日期处理类，那么Java8之后就可以使用ChronoUnit:

```
LocalDateTime startTime = LocalDateTime.now();

//模拟方法执行，花费2s
TimeUnit.SECONDS.sleep(2);

LocalDateTime endTime =  LocalDateTime.now();

System.out.println("花费 " + ChronoUnit.MILLIS.between(startTime, LocalDateTime.now()) + " 毫秒");
```

 <!-- more -->

> System.currentTimeMillis()只能精确到毫秒，如果你有更高的要求，要精确到纳秒，或者只需要秒、分钟等，java8可以轻松搞定，利用ChronoUnit的不同枚举单位计算即可：

- CENTURIES	代表一个世纪概念的单位。
- **DAYS**	代表一天概念的单位
- DECADES	代表十年概念的单位
- ERAS	代表一个时代概念的单位
- FOREVER	代表永恒概念的人工单位
- HALF_DAYS	代表AM / PM中使用的半天概念的单位
- **HOURS**	表示一小时概念的单位
- **MICROS**	表示微秒概念的单位
- MILLENNIA	代表千年概念的单位
- **MILLIS**	表示毫秒概念的单位
- **MINUTES**	表示一分钟概念的单位
- **MONTHS**	代表一个月概念的单位
- **NANOS**	代表纳秒概念的单位，是支持的最小时间单位
- **SECONDS**	表示一秒概念的单位。
- WEEKS	表示一周概念的单位。
- YEARS	代表一年概念的单位