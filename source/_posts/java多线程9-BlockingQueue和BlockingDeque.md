---
title: java多线程9-BlockingQueue和BlockingDeque
date: 2020-08-18 15:01:39
categories: [java, 多线程] 
tags: [java, 多线程]

---

![BlockingQueue](BlockingQueue.png)

# 概念

## queue&deque

queue: 先进先出队列

deque: 双端队列，继承自queue，可以在首尾插入或删除元素

## BlockingQueue&BlockingDeque

BlockingQueue: 阻塞队列

BlockingDeque: 阻塞双端队列，在不能够插入元素时，它将阻塞住试图插入元素的线程；在不能够抽取元素时，它将阻塞住试图抽取的线程

> 阻塞

