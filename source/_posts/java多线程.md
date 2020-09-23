---
title: java多线程
date: 2020-08-1 14:28:36
categories: [java, 多线程] 
tags: [java, 多线程]
top: 1000
---

# 目录

> 任何并发能做的事情，单进程也能够实现，只不过这种方式效率很低，它是一种顺序性的

[java多线程1-从Thread到Future再到CompletableFuture](/2020/07/14/java多线程1-从Thread到Future再到CompletableFuture)

[java多线程2-线程池](/2020/07/23/java多线程2-线程池)

[java多线程3-fork-join框架](/2020/07/28/java多线程3-fork-join框架)

[java多线程4-volatile&synchronized](/2020/07/30/java多线程4-volatile&synchronized/)

[java多线程5-并发同步器CountDownLatch&CyclicBarrier&Semaphore](/2020/07/31/java多线程5-并发同步器CountDownLatch&CyclicBarrier&Semaphore)

[java多线程6-ConcurrentHashMap-待细化](/2020/08/11/java多线程6-ConcurrentHashMap)

[java多线程7-atomic原子类](/2020/08/11/java多线程7-atomic原子类)

[java多线程8-locks锁](/2020/08/17/java多线程8-locks锁)

[java多线程9-BlockingQueue和BlockingDeque-待细化](/2020/08/18/java多线程9-BlockingQueue和BlockingDeque)

[java多线程10-ThreadLocal](/2020/08/24/java多线程10-ThreadLocal)

 <!-- more -->

# java14并发包结构

共计 17(atomic) + 10(locks) + 61 = 88个类

## juc-atomic 原子类

### 1. 原子类

AtomicInteger AtomicLong AtomicBoolean

AtomicReference AtomicStampedReference AtomicMarkableReference

### 2. 原子数组

AtomicIntegerArray AtomicLongArray AtomicReferenceArray

### 3. java8优化原子类

Striped64 -> DoubleAccumulator DoubleAdder LongAccumulator LongAdder

### 4. 属性原子修改器

AtomicIntegerFieldUpdater AtomicLongFieldUpdater AtomicReferenceFieldUpdater

---

## juc-locks 锁

## 1. 锁与读写锁

Lock ReadWriteLock

## 2. 锁的具体实现类(可重入锁)

ReentrantLock ReentrantReadWriteLock

### 3. java8新增锁

StampedLock

### 4. 等待/唤醒线程类

Condition

### 5. 辅助类

LockSupport

AbstractOwnableSynchronizer AbstractQueuedSynchronizer AbstractQueuedLongSynchronizer

---

##  juc-sync 同步器

CountDownLatch CyclicBarrier Semaphore

Exchanger Phaser

---

## juc-collections 集合

### 1.map

ConcurrentMap ConcurrentHashMap ConcurrentSkipListMap ConcurrentNavigableMap

### 2.set

CopyOnWriteArraySet ConcurrentSkipListSet

### 3.list

CopyOnWriteArrayList

### 4.queue

#### 4.1普通队列

BlockingQueue ArrayBlockingQueue ConcurrentLinkedQueue LinkedBlockingQueue LinkedTransferQueue PriorityBlockingQueue SynchronousQueue DelayQueue TransferQueue

Delayed

#### 4.2双端队列

BlockingDeque LinkedBlockingDeque ConcurrentLinkedDeque

---

## juc-executors 执行器

### 1.Executor线程池

AbstractExecutorService Executor ExecutorCompletionService Executors ExecutorService ScheduledThreadPoolExecutor RejectedExecutionHandler ThreadFactory ThreadPoolExecutor ScheduledExecutorService CompletionService CompletionStage

### 2.Future

Callable CompletableFuture Future FutureTask RunnableFuture RunnableScheduledFuture ScheduledFuture

### 3.Fork/Join

ForkJoinPool ForkJoinTask ForkJoinWorkerThread RecursiveAction RecursiveTask CountedCompleter

---

## jus-其他

### 1.java9新增支持响应式编程类

SubmissionPublisher Flow

### 2.异常类

BrokenBarrierException CancellationException CompletionException ExecutionException RejectedExecutionException TimeoutException

### 3.其他

ThreadLocalRandom TimeUnit Helpers(非公开类)

# 基础概念

并发：系统能处理多个任务，但同时只能处理一个的任务处理机制

并行：系统能处理多个任务，且同时还能处理多个的任务处理机制

高并发：系统能同时并行处理很多请求的任务处理机制

```
你吃饭吃到一半，电话来了，你一直到吃完了以后才去接，这就说明你不支持并发也不支持并行。

你吃饭吃到一半，电话来了，你停了下来接了电话，接完后继续吃饭，这说明你支持并发。

你吃饭吃到一半，电话来了，你一边打电话一边吃饭，这说明你支持并行。

并发的关键是你有处理多个任务的能力，不一定要同时。并行的关键是你有同时处理多个任务的能力。
```

JUC: java.util.concurrent简称

悲观锁: synchronized是悲观锁，悲观地认为程序中的并发情况严重，所以严防死守。这种线程一旦得到锁，其他需要锁的线程就挂起的情况就是悲观锁.

乐观锁: CAS操作的就是乐观锁，乐观地认为程序中的并发情况不那么严重，所以让线程不断去尝试更新。每次不加锁而是假设没有冲突而去完成某项操作，如果因为冲突失败就重试，直到成功为止

CAS: Compare-and-Swap, 即比较并替换，是一种实现并发算法时常用到的技术，Java并发包中的很多类都使用了CAS技术。CAS的原理是拿期望的值和原本的一个值作比较，如果相同则更新成新的值

AQS：AbstractQueuedSynchronizer，抽象的队列式同步器。它提供了一种实现阻塞锁和一系列依赖FIFO等待队列的同步器的框架，ReentrantLock Semaphore CountDownLatch CyclicBarrier等并发类均是基于AQS来实现的，具体用法是通过继承AQS实现其模板方法，然后将子类作为同步组件的内部类。

AQS 定义了两种资源共享方式：
1.Exclusive：独占，只有一个线程能执行，如ReentrantLock
2.Share：共享，多个线程可以同时执行，如Semaphore CountDownLatch ReadWriteLock，CyclicBarrier

FIFO( First Input First Output): 指先进先出

FILO：指先进后出

红黑树

![红黑树](红黑树.jpg)

- 每个节点非红即黑
- 根节点总是黑色的
- 如果节点是红色的，则它的子节点必须是黑色的（反之不一定）
- 每个叶子节点都是黑色的空节点（NIL节点）
- 从根节点到叶节点或空子节点的每条路径，必须包含相同数目的黑色节点（即相同的黑色高度）



并发的指标一般有QPS、TPS、IOPS，这几个指标都是可归为系统吞吐率，QPS越高系统能hold住的请求数越多，但光关注这几个指标不够，我们还需要关注RT，即响应时间，也就是从发出request到收到response的时延，这个指标跟吞吐往往是此消彼长的，我们追求的是一定时延下的高吞吐。

> 一个变量是否是线程安全的，取决于它是否被多个线程访问。要使变量能够被安全访问，必须通过同步机制来对变量进行修饰

线程安全: 当多个线程访问某个类时，这个类始终都能表现出正确的行为，那么就称这个类是线程安全的

# Spring中的多线程疑惑

首先我们需要认清：

- web容器本身就是多线程的，每一个HTTP请求都会产生一个独立的线程（或者从线程池中取得创建好的线程）；
Spring中的bean（用@Repository、@Service、@Component和@Controller注册的bean）都是单例的，即整个程序、所有线程共享一个实例；
- 虽然bean都是单例的，但是Spring提供的模板类（XXXTemplate），在Spring容器的管理下（使用@Autowired注入），会自动使用ThreadLocal以实现多线程；
- 即使类是单例的，但是其中有可能出现并发问题的变量使用ThreadLocal实现了多线程。
- 注意除了Spring本身提供的类以外，在Bean中定义“有状态的变量”（即有存储数据的变量），其会被所有线程共享，很可能导致并发问题，需要自行另外使用ThreadLocal进行处理，或者将Bean声明为prototype型。
- 一个类中的方法实际上是独立，方法内定义的局部变量在每次调用方法时都是独立的，不会有并发问题。只有类的“有状态的”全局变量会有并发问题

结论：

- 使用Spring提供的template等类没有多线程问题！
- 一般来说只有类的属性/全局变量会导致多线程问题，而方法内的局部变量不会有并发问题
- 单例模式肯定是线程不安全的！ spring的Bean中的自定义的成员变量除非进行threadlocal封装，否则都是非线程安全的！