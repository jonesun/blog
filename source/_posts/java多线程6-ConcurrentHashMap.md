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

> loadFactor 是装载因子，表示HashMap 满的程度，默认值为0.75f，设置成
0.75 有一个好处，那就是0.75 正好是3/4，而capacity 又是2 的幂。所以，两个
数的乘积都是整数。

> 对于一个默认的HashMap 来说，默认情况下，当其size 大于12(16*0.75) 时
就会触发扩容

> HashMap 中size 表示当前共有多少个KV 对，capacity 表示当前
HashMap 的容量是多少，默认值是16，每次扩容都是成倍的。loadFactor 是装
载因子，当Map 中元素个数超过loadFactor* capacity 的值时，会触发扩容。
loadFactor* capacity 可以用threshold 表示

> 如果用户通过构造
函数指定了一个数字作为容量，那么Hash 会选择大于该数字的第一个2 的幂作为容
量。(3->4、7->8、9->16)

> 在已知HashMap 中将要存放的KV 个数的时候，
设置一个合理的初始化容量可以有效的提高性能

> HashMap 中的扩容机制决定了每次扩容都需要重建hash 表，是非
常影响性能的。

> JDK 会默认帮我们计算一个相对合理的值当做初始容量。所谓合理值，其实是
找到第一个比用户传入的值大的2 的幂。

> 当我们明确知道HashMap 中元素的个数的时候，把默
认容量设置成expectedSize / 0.75F + 1.0F 是一个在性能上相对好的选择，但
是，同时也会牺牲些内存。

guava中可以利用以下公式来初始化容量:

```
//return (int) ((float) expectedSize / 0.75F + 1.0F);
Map<String, String> map = Maps.newHashMapWithExpectedSize(7);
```