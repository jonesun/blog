---
title: java多线程
date: 2020-08-1 14:28:36
categories: [java, 多线程] 
tags: [java, 多线程]
top: 1000
---

# 目录

[java多线程1-从Thread到Future再到CompletableFuture](2020/07/14/java多线程1-从Thread到Future再到CompletableFuture)

[java多线程2-线程池](/2020/07/23/java多线程2-线程池)

[java多线程3-fork-join框架](/2020/07/28/java多线程3-fork-join框架)

[java多线程4-volatile&synchronized](/2020/07/30/java多线程4-volatile&synchronized/)

[java多线程5-并发工具类CountDownLatch&CyclicBarrier&Semaphore](/2020/07/31/java多线程5-并发工具类CountDownLatch&CyclicBarrier&Semaphore)

[java多线程6-ConcurrentHashMap](/2020/08/11/java多线程6-ConcurrentHashMap)

[java多线程7-atomic原子变量](/2020/08/11/java多线程7-atomic原子变量)

 <!-- more -->

# java14并发包结构

共计 17(atomic) + 10(locks) + 61 = 88 个类

 <!-- more -->

![atomic](java14-concurrent-atomic.png) 

![locks](java14-concurrent-locks.png) 

![concurrent-1](java14-concurrent-1.png) 

![concurrent-2](java14-concurrent-2.png) 


# 基础概念

JUC

悲观锁: synchronized是悲观锁，悲观地认为程序中的并发情况严重，所以严防死守。这种线程一旦得到锁，其他需要锁的线程就挂起的情况就是悲观锁.

乐观锁: CAS操作的就是乐观锁，乐观地认为程序中的并发情况不那么严重，所以让线程不断去尝试更新。每次不加锁而是假设没有冲突而去完成某项操作，如果因为冲突失败就重试，直到成功为止

CAS: Compare-and-Swap, 即比较并替换，是一种实现并发算法时常用到的技术，Java并发包中的很多类都使用了CAS技术。CAS的原理是拿期望的值和原本的一个值作比较，如果相同则更新成新的值

AQS：AbstractQueuedSynchronizer，抽象的队列式同步器。它提供了一种实现阻塞锁和一系列依赖FIFO等待队列的同步器的框架，ReentrantLock、Semaphore、CountDownLatch、CyclicBarrier等并发类均是基于AQS来实现的，具体用法是通过继承AQS实现其模板方法，然后将子类作为同步组件的内部类。


AQS 定义了两种资源共享方式：
1.Exclusive：独占，只有一个线程能执行，如ReentrantLock
2.Share：共享，多个线程可以同时执行，如Semaphore、CountDownLatch、ReadWriteLock，CyclicBarrier

红黑树