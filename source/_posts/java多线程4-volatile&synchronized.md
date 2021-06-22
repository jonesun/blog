---
title: java多线程4-volatile&synchronized
categories:
  - java
  - 多线程
tags:
  - java
  - 多线程
abbrlink: cc62b819
date: 2020-07-30 10:32:00
---

# 并发编程三要素

## 1. 原子性

**即一个操作或者多个操作 要么全部执行并且执行的过程不会被任何因素打断，要么就都不执行**

只有简单的读取、赋值（而且必须是将数字赋值给某个变量，变量之间的相互赋值不是原子操作）才是原子操作

可以通过 synchronized 和 Lock 来实现。由于 synchronized 和 Lock 能够保证任一时刻只有一个线程执行该代码块，那么自然就不存在原子性问题了，从而保证了原子性

 <!-- more -->

## 2. 可见性 

**指当多个线程访问同一个变量时，一个线程修改了这个变量的值，其他线程能够立即看得到修改的值**

Java提供了 volatile 关键字来保证可见性。当一个共享变量被 volatile 修饰时，它会保证修改的值会立即被更新到主存，当有其他线程需要读取时，它会去内存中读取新值

另外，通过 synchronized 和 Lock 也能够保证可见性，synchronized 和 Lock 能保证同一时刻只有一个线程获取锁然后执行同步代码，并且在释放锁之前会将对变量的修改刷新到主存当中。因此可以保证可见性

## 3. 有序性

**即程序执行的顺序按照代码的先后顺序执行**

可以通过 volatile 关键字来保证一定的有序性

另外可以通过 synchronized 和 Lock 来保证有序性，很显然，synchronized 和 Lock 保证每个时刻是有一个线程执行同步代码，相当于是让线程顺序执行同步代码，自然就保证了有序性

# volatile

> 被volatile修饰的变量能够保证每个线程能够获取该变量的最新值，从而避免出现数据脏读的现象

下面的代码是很典型的一段代码，很多人在中断线程时可能都会采用这种标记办法：

```java
public class VolatileTest {

    private boolean stop = false;
    //    private volatile boolean stop = false;

    public void doWork() {
        System.out.println("准备工作");
        doWorkWithThread();
        try {
            TimeUnit.SECONDS.sleep(2);
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            stop = true;
            System.out.println("可以停止工作了");
        }
    }

    private void doWorkWithThread() {
        new Thread(() -> {
            while(!stop){
                //doSomethings
//                System.out.println("正在工作...");
            }
            System.out.println("停止工作");
        }).start();
    }


    private void doWorkWithCompletableFuture() {
        CompletableFuture.runAsync(() -> {
            while(!stop){
                //doSomethings
//                System.out.println("正在工作...");
            }
            System.out.println("停止工作");
        });
    }


    public static void main(String[] args) {
        VolatileTest volatileTest = new VolatileTest();
        volatileTest.doWork();
    }

}

//打印结果
//准备工作
//可以停止工作了

```

事实上，这段代码并不会完全运行正确，甚至使用原始的Thread可以发现，程序执行结束了并没有停止掉。这个时候volatile就派上用场了，在变量修饰符前加上volatile，可以发现程序按照既定要求执行了。

> ps: 如果把线程中的System.out.println注释去掉，这个时候可以发现，程序又执行正确了，不要奇怪，这是因为System.out.println源码中使用了synchronized，感兴趣的可以看看:

```
//java8 源码
public void println(String x) {
    synchronized (this) {
        print(x);
        newLine();
    }
}

//java14 源码
public void println(String x) {
    if (getClass() == PrintStream.class) {
        writeln(String.valueOf(x));
    } else {
        synchronized (this) {
            print(x);
            newLine();
        }
    }
}
```

当然我们也可以不用volatile，可以改为AtomicBoolean达到同样的效果(通过查看源码可以发现底层同样使用的是volatile修饰的)。感兴趣的可以看看java.util.concurrent.atomic包中提供的各个类的使用: 

![image](atomic.png) 

# synchronized

> synchronized保证在同一时刻最多只有一个线程执行该段代码

上面看了volatile的用法，值得一提的是volatile只能修饰变量。那如果要保证一个操作或者方法的原子性时(防止多个线程同时执行一段代码)就得使用synchronized了:

```java
public class SynchronizedTest {

    private int studentsCount = 0;

    private void addStudent() {
        studentsCount++;
    }

    private void removeStudent() {
        studentsCount--;
    }


    public int getStudentsCount() {
        return studentsCount;
    }

    public Runnable onePeopleComingRunnable() {
        return new Runnable() {
            @Override
            public void run() {
                addStudent();
                try {
                    TimeUnit.SECONDS.sleep(2);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                removeStudent();
            }
        };
    }

    public static void main(String[] args) throws InterruptedException {
        SynchronizedTest synchronizedTest = new SynchronizedTest();
        ExecutorService executor = Executors.newFixedThreadPool(50);
        for (int i = 0; i < 100; i++) {
            executor.execute(synchronizedTest.onePeopleComingRunnable());
        }

        executor.shutdown();
        while (!executor.awaitTermination(1, TimeUnit.SECONDS)) {
//            System.out.println("尚未结束");
        }
        System.out.println("总共有1: " + synchronizedTest.getStudentsCount());

    }

}


//打印结果
//不定，可能出现不同结果，这种现象就是线程不安全的一种表现
```

我们试试给addStudent和removeStudent方法加上synchronized
```
private synchronized void addStudent() {
    studentsCount++;
}

private synchronized void removeStudent() {
    studentsCount--;
}

//打印结果永远为0
```

![image](synchronized.png) 

使用时遵守**同步锁的范围越小，效率越高**原则

当然上面的计数的场景完全可以用AtomicInteger来代替: 

```

private AtomicInteger studentsCountAtomicInteger = new AtomicInteger(0);

private void addStudent() {
    studentsCountAtomicInteger.incrementAndGet();
}

private void removeStudent() {
    studentsCountAtomicInteger.decrementAndGet();
}


public int getStudentsCount() {
    return studentsCountAtomicInteger.get();
}

//打印结果永远为0
```

## 结合使用

### 实现单例

- 线程不安全的单例

普通单线程模式下
```java
public class TestSingleton {

    private static TestSingleton instance = null;

    public static TestSingleton getInstance() {
        if (instance == null) {
            System.err.println("实例化对象");
            instance = new TestSingleton();
        }
        return instance;
    }

    public static void main(String[] args) {
        TestSingleton testSingleton = TestSingleton.getInstance();

        System.out.println("1: " + testSingleton.hashCode());

        TestSingleton testSingleton1 = TestSingleton.getInstance();

        System.out.println("2: " + testSingleton1.hashCode());
    }

}

//打印出的hashCode是一样的，说明确实是同一个对象

```

试试多线程调用情况下

```java
public class Test {
    public static void main(String[] args) {

        CompletableFuture<Void> completableFuture1 = CompletableFuture.runAsync(() -> {
            TestSingleton testSingleton = TestSingleton.getInstance();

            System.out.println("1: " + testSingleton.hashCode());
        });

        CompletableFuture<Void>  completableFuture2 =  CompletableFuture.runAsync(() -> {
            TestSingleton testSingleton1 = TestSingleton.getInstance();

            System.out.println("2: " + testSingleton1.hashCode());
        });

        while (!(completableFuture1.isDone() && completableFuture2.isDone())) {

        }
    }

//打印结果，不固定，有时候一样，有时候不一样。说明多线程情况下已不是单例了
//ps: 所以多线程的代码才不好调试，结果不固定，跟实际机器的环境有关系
}

```

- 线程安全的单例

```java
public class TestSingleton {

    //使用volatile保证instance原子性
    private volatile static TestSingleton instance = null;

    public static TestSingleton getInstance() {
        if (instance == null) {
            //使用synchronized锁住类
            synchronized (TestSingleton.class) {
                if(instance==null) {
                    System.err.println("实例化对象");
                    instance = new TestSingleton();
                }
            }
        }
        return instance;
    }

    public static void main(String[] args) {

       CompletableFuture<Void> completableFuture1 = CompletableFuture.runAsync(() -> {
            TestSingleton testSingleton = TestSingleton.getInstance();

            System.out.println("1: " + testSingleton.hashCode());
        });

        CompletableFuture<Void>  completableFuture2 =  CompletableFuture.runAsync(() -> {
            TestSingleton testSingleton1 = TestSingleton.getInstance();

            System.out.println("2: " + testSingleton1.hashCode());
        });

        while (!(completableFuture1.isDone() && completableFuture2.isDone())) {

        }
    }

}

//打印结果就是同一对象了，这样就达到了多线程情况下的单例的实现
```

ps: 上面只是举例，如果日常真的要写线程安全的单例的话，建议：

- 对象实例化占用资源少时

//使用枚举

```java
//使用枚举-推荐
public enum TestSingleton {

    //枚举元素本身就是单例
    INSTANCE;

    //添加自己需要的操作
    public void singletonOperation(){
    }
}

//饿汉模式-不推荐：直接把单例对象创建出来，要用的时候直接返回即可，但如果程序从头到位都没用使用这个单例的话，单例的对象还是会创建。这就造成了不必要的资源浪费。
public class TestSingleton {
    private static TestSingleton instance = new TestSingleton();

    private TestSingleton() {
        System.out.println("实例化对象");
    }

    public static TestSingleton getInstance() {
        return instance;
    }
}
```

- 对象实例化占用资源多且需要延时(第一次使用时再实例化)-使用内部类

```java
public class TestSingleton {
    private static class SingletonClassInstance {
        private static final TestSingleton instance = new TestSingleton();
    }

    private TestSingleton() {
        System.err.println("实例化对象");
    }

    public static TestSingleton getInstance() {
        return SingletonClassInstance.instance;
    }
}
```