---
title: java多线程6-ConcurrentHashMap
date: 2020-08-11 16:10:50
categories: [java, 多线程]  
tags: [java, 多线程]
---

concurrentHashMap存在是为了解决并发问题

1、get方法不加锁；
2、put、remove方法要使用锁
jdk7使用锁分离机制(Segment分段加锁)
jdk8使用cas + synchronized 实现锁操作
3、Iterator对象的使用，运行一边更新，一遍遍历(可以根据原理自己拓展)
4、复合操作，无法保证线程安全，需要额外加锁保证
5、并发环境下，ConcurrentHashMap 效率较Collections.synchronizedMap()更高