---
title: java多线程3-fork/join框架
categories:
  - java
  - 多线程
tags:
  - java
  - 多线程
  - 线程池
abbrlink: a490755
date: 2020-07-28 10:19:44
---

# 概念

JDK1.7引入了一种新的并行编程模式"fork-join"，它是实现了"分而治之"思想的Java并发编程框架。它对问题的解决思路是分而治之，先将一个问题fork（分为）几个子问题，然后子问题又分为孙子问题，直至细分为一个容易计算的问题，然后再将结果依次join(结合)为最终的答案。对程序员来说，叫递归思想更加合适。只不过普通的递归是在单线程中完成的，而这里的递归则把递归任务通过invokeAll()方法丢进了线程池中，让线程池来调度执行。

**ForkJoinPool 不是为了替代 ExecutorService，而是它的补充，在某些应用场景下性能比 ExecutorService 更好**

 <!-- more -->

# 特点

在运行线程时，它使用“work-steal”（任务偷取）算法。一般来说，fork-join会启动多个线程（由参数指定，若不指定则默认为CPU核心数量），每个线程负责一个任务队列，并依次从队列头部获得任务并执行。当某个线程空闲时，它会从其他线程的任务队列尾部偷取一个任务来执行，这样就保证了线程的运行效率达到最高

它面向的问题域是可以大量并行执行的计算任务，其计算对象最好是一些独立的元素，不会被其他线程访问，也没有同步、互斥要求，更不要涉及IO或者无限循环。当然此框架也可以执行普通的并发编程任务，但是这时就失去了性能优势

# 工具类

1. ForkJoinTask：fork-join的任务抽象类，同时也是Future接口，并提供了fork和join方法

    - fork()    在当前线程运行的线程池中安排一个异步执行。简单的理解就是再创建一个子任务
    - join()    当任务完成的时候返回计算结果。
    - invoke()    开始执行任务，如果必要，等待计算完成
    - invokeAll() 提交多个forkJoinTasks到ForkJoinPool的便捷方式

1. ForkJoinPool: fork-join的线程池，所有的ForkJoinTask任务都必须在其中运行，主要使用invoke()、invokeAll()等方法来执行任务, 当然也可以使用原有的execute()和submit()方法

1. RecursiveAction: ForkJoinTask的具体实现类，用于没有返回值的任务

1. RecursiveTask: ForkJoinTask的具体实现类，用于有返回值的任务


# 使用

## 常用方法
```
//实例化
ForkJoinPool forkJoinPool = ForkJoinPool.commonPool();

//任务提交

//方式1： submit()或execute() 
forkJoinPool.execute(ForkJoinTask<?> task);
int result = customRecursiveTask.join();

//方式2: invoke()或者invokeAll()
//invoke()方法拆分任务并等待结果，并且不需要任何手动join
//invokeAll()方法是提交多个forkJoinTasks到ForkJoinPool的便捷方式。
//它将任务作为参数，forks它们将按照生成它们的顺序返回Future对象的集合
int result = forkJoinPool.invoke(ForkJoinTask<?> task);

//方式3：使用单独的fork()和join()
//fork()方法将任务提交到一个线程池中，但它不会触发它的执行。
//join()方法被用于触发执行。在RecursiveAction的情况下，join()只返回null ; 对于RecursiveTask <V>，它返回任务执行的结果
forkJoinTask.fork();
result = forkJoinTask.join();
```

为避免混淆，使用invokeAll()方法向ForkJoinPool提交多个任务通常是个好主意


## 示例

计算1至1000的正整数之和


> fork-join的效率跟CPU的核数有直接关系，不同性能机器，测试结果会不一样

```java
//定义一个简单的接口
public interface Calculator {

    long sumUp(long[] numbers);

}

```

```java
public class ForkJoinCalculator implements Calculator {
    private ForkJoinPool pool;

    private static class SumTask extends RecursiveTask<Long> {
        private long[] numbers;
        private int from;
        private int to;

        public SumTask(long[] numbers, int from, int to) {
            this.numbers = numbers;
            this.from = from;
            this.to = to;
        }

        @Override
        protected Long compute() {
            // 当需要计算的数字小于6时，直接计算结果
            if (to - from < 6) {
                long total = 0;
                for (int i = from; i <= to; i++) {
                    total += numbers[i];
                }
                return total;
                // 否则，把任务一分为二，递归计算
            } else {
                int middle = (from + to) / 2;
                SumTask taskLeft = new SumTask(numbers, from, middle);
                SumTask taskRight = new SumTask(numbers, middle+1, to);
                taskLeft.fork();
                taskRight.fork();
                return taskLeft.join() + taskRight.join();
            }
        }
    }

    public ForkJoinCalculator() {
        // 也可以使用公用的 ForkJoinPool：
        // pool = ForkJoinPool.commonPool()
        pool = new ForkJoinPool();
    }

    @Override
    public long sumUp(long[] numbers) {
        return pool.invoke(new SumTask(numbers, 0, numbers.length-1));
    }

}

```

测试代码

```java
public class Test {

    public static void main(String[] args) {
        long[] numbers = LongStream.rangeClosed(1, 1000).toArray();

//        Calculator calculator = new ForLoopCalculator();
//        System.out.println(calculator.sumUp(numbers)); 

//        Calculator executorCalculator = new ExecutorServiceCalculator();
//        System.out.println(executorCalculator.sumUp(numbers));

        Calculator forkJoinCalculator = new ExecutorServiceCalculator();
        System.out.println(forkJoinCalculator.sumUp(numbers)); 
        
    }

}
```

## 注意要点

- 需使用合理的阈值将ForkJoinTask拆分为子任务
- 避免在 ForkJoinTask中出现任何阻塞

ForkJoinTask在执行的时候可能会抛出异常，在主线程中是无法直接获取的，但是可以通过ForkJoinTask提供的isCompletedAbnormally()方法来检查任务是否已经抛出异常或已经被取消了

Fork/Join线程池在Java标准库中就有应用。Java标准库提供的java.util.Arrays.parallelSort(array)可以进行并行排序，它的原理就是内部通过Fork/Join对大数组分拆进行并行排序，在多核CPU上就可以大大提高排序的速度。

