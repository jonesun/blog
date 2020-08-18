---
title: java多线程8-locks锁
date: 2020-08-17 18:10:27
categories: [java, 多线程]  
tags: [java, 多线程]
---

# 前言

> 任何一个新引入的知识都是为了**解决以往系统中出现的问题**，否则新引入的将变得毫无价值

如果一个代码块被synchronized修饰了，当一个线程获取了对应的锁，并执行该代码块时，其他线程便只能一直等待，等待获取锁的线程释放锁。

但当有多个线程读写文件时，读操作和写操作会发生冲突现象，写操作和写操作会发生冲突现象，但是**读操作和读操作**不会发生冲突现象，通过Lock就可以实现。

Lock接口, 提供了与synchronized一样的锁功能。虽然它失去了像synchronize关键字隐式加锁解锁的便捷性，但是却拥有了锁获取和释放的可操作性，可中断的获取锁以及超时获取锁等多种synchronized关键字所不具备的同步特性

> Lock必须要用户去手动释放锁，如果没有主动释放锁，就有可能导致出现死锁现象

![locks](locks.png)

> 一个线程获取多少次锁，就必须释放多少次锁。这对于内置锁也是适用的，每一次进入和离开synchornized方法(代码块)，就是一次完整的锁获取和释放。

# lock

## Lock

```
public interface Lock {

    //获取锁。如果锁已被其他线程获取，则进行等待
    void lock();


    //通过这个方法去获取锁时，如果线程正在等待获取锁，则这个线程能够响应中断，即中断线程的等待状态。也就使说，当两个线程同时通过lock.lockInterruptibly()想获取某个锁时，假若此时线程A获取到了锁，而线程B只有在等待，那么对线程B调用threadB.interrupt()方法能够中断线程B的等待过程
    void lockInterruptibly() throws InterruptedException;

    //tryLock()方法是有返回值的，它表示用来尝试获取锁，如果获取成功，则返回true，如果获取失败（即锁已被其他线程获取），则返回false，也就说这个方法无论如何都会立即返回。在拿不到锁时不会一直在那等待
    boolean tryLock();

    //这个方法在拿不到锁时会等待一定的时间，在时间期限之内如果还拿不到锁，就返回false。如果如果一开始拿到锁或者在等待期间内拿到了锁，则返回true
    boolean tryLock(long time, TimeUnit unit) throws InterruptedException;

    //释放锁
    void unlock();

    //获取与lock绑定的等待通知组件，当前线程必须获得了锁才能进行等待，进行等待时会先释放锁，当再次获取锁时才能从等待中返回
    Condition newCondition();
}
```

一般来说，使用Lock必须在try{}catch{}块中进行，并且将释放锁的操作放在finally块中进行，以保证锁一定被被释放，防止死锁的发生():


> 锁【lock.lock】必须紧跟try代码块，且unlock要放到finally第一行。


## ReentrantLock

可重入锁, 支持重入性，表示能够对共享资源重复加锁，即当前线程获取该锁再次获取不会被阻塞。ReentrantLock实现了Lock接口的，并且ReentrantLock提供了更多的方法

```
private ArrayList<Integer> arrayList = new ArrayList<Integer>();
private Lock lock = new ReentrantLock(); 

public static void main(String[] args) {
    final LocksTest test = new LocksTest();

    new Thread(() -> test.insert(Thread.currentThread())).start();

    new Thread(() -> test.insert(Thread.currentThread())).start();
}

    public void insert(Thread thread) {
        lock.lock();
        try {
            System.out.println(thread.getName() + "得到了锁");
            for (int i = 0; i < 5; i++) {
                arrayList.add(i);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            System.out.println(thread.getName() + "释放了锁");
            lock.unlock();
        }
    }


//打印

```

一般情况下通过tryLock来获取锁时是这样使用的

```
public void insert(Thread thread) {
    if(lock.tryLock()) {
        try {
            System.out.println(thread.getName()+"得到了锁");
            for(int i=0;i<5;i++) {
                arrayList.add(i);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }finally {
            System.out.println(thread.getName()+"释放了锁");
            lock.unlock();
        }
    } else {
        System.out.println(thread.getName()+"获取锁失败");
    }
}

//打印
Thread-0得到了锁
Thread-1获取锁失败
Thread-0释放了锁
```

由于lockInterruptibly()的声明中抛出了异常，所以lock.lockInterruptibly()必须放在try块中或者在调用lockInterruptibly()的方法外声明抛出InterruptedException

```
public class InterruptTest {

    private Lock lock = new ReentrantLock();
    public static void main(String[] args)  {
        InterruptTest test = new InterruptTest();
        MyThread thread1 = new MyThread(test);
        MyThread thread2 = new MyThread(test);
        thread1.start();
        thread2.start();

        try {
            TimeUnit.SECONDS.sleep(2);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        thread2.interrupt();
    }

    public void insert(Thread thread) throws InterruptedException{
        lock.lockInterruptibly();   //注意，如果需要正确中断等待锁的线程，必须将获取锁放在外面，然后将InterruptedException抛出
        try {
            System.out.println(thread.getName()+"得到了锁");
            long startTime = System.currentTimeMillis();
            for(    ;     ;) {
                if(System.currentTimeMillis() - startTime >= Integer.MAX_VALUE) {
                    break;
                }
                //插入数据
            }
        }
        finally {
            System.out.println(Thread.currentThread().getName()+"执行finally");
            lock.unlock();
            System.out.println(thread.getName()+"释放了锁");
        }
    }

}

class MyThread extends Thread {
    private InterruptTest test;
    public MyThread(InterruptTest test) {
        this.test = test;
    }
    @Override
    public void run() {

        try {
            test.insert(Thread.currentThread());
        } catch (InterruptedException e) {
            System.out.println(Thread.currentThread().getName()+"被中断");
        }
    }
}


```

# ReadWriteLock

ReadWriteLock也是一个接口,只有两个方法:

```
public interface ReadWriteLock {
    /**
     * Returns the lock used for reading.
     *
     * @return the lock used for reading
     */
    Lock readLock();

    /**
     * Returns the lock used for writing.
     *
     * @return the lock used for writing
     */
    Lock writeLock();
}

```

一个用来获取读锁，一个用来获取写锁。也就是说将文件的读写操作分开，分成2个锁来分配给线程，从而使得多个线程可以同时进行读操作

# ReentrantReadWriteLock

ReentrantReadWriteLock实现了ReadWriteLock接口，并添加了可重入的特性

> 如果在系统中，读操作次数远远大于写操作，则读写锁就可以发挥最大的功效，提升系统的性能

# Lock和synchronized的选择

　　总结来说，Lock和synchronized有以下几点不同：

　　1）Lock是一个接口，而synchronized是Java中的关键字，synchronized是内置的语言实现；

　　2）synchronized在发生异常时，会自动释放线程占有的锁，因此不会导致死锁现象发生；而Lock在发生异常时，如果没有主动通过unLock()去释放锁，则很可能造成死锁现象，因此使用Lock时需要在finally块中释放锁；

　　3）Lock可以让等待锁的线程响应中断，而synchronized却不行，使用synchronized时，等待的线程会一直等待下去，不能够响应中断；

　　4）通过Lock可以知道有没有成功获取锁，而synchronized却无法办到。

　　5）Lock可以提高多个线程进行读操作的效率。

　　在性能上来说，如果竞争资源不激烈，两者的性能是差不多的，而当竞争资源非常激烈时（即有大量线程同时竞争），此时Lock的性能要远远优于synchronized。所以说，在具体使用时要根据适当情况选择

## Condition

它用来替代传统的Object的wait()、notify()实现线程间的协作，相比使用Object的wait()、notify()，使用Condition的await()、signal()这种方式实现线程间协作更加安全和高效。使用Condition可以实现等待/唤醒，并且能够唤醒制定线程


# LockSupport

LockSupport是一个工具类，可以让线程在任意位置阻塞，也可以在任意位置唤醒，它的内部其实两类主要的方法：park（停车阻塞线程）和unpark（启动唤醒线程）:

```
// 暂停当前线程
public static void park(Object blocker); 

// 暂停当前线程，不过有超时时间的限制
public static void parkNanos(Object blocker, long nanos); 
public static void parkNanos(long nanos); 

// 暂停当前线程，直到某个时间
public static void parkUntil(Object blocker, long deadline);
public static void parkUntil(long deadline);

// 无期限暂停当前线程
public static void park(); 


 // 恢复当前线程
public static void unpark(Thread thread);

//blocker的作用是在dump线程的时候看到阻塞对象的信息
public static Object getBlocker(Thread t);

//java14新增了设置blocker的方法
public static void setCurrentBlocker(Object blocker);
```

```
public static Object u = new Object();
static ChangeObjectThread t1 = new ChangeObjectThread("t1");
static ChangeObjectThread t2 = new ChangeObjectThread("t2");

public static class ChangeObjectThread extends Thread {
    public ChangeObjectThread(String name) {
        super(name);
    }
    @Override public void run() {
        synchronized (u) {
            System.out.println(Thread.currentThread() +"in " + getName());
            LockSupport.park();
            if (Thread.currentThread().isInterrupted()) {
                System.out.println(Thread.currentThread() +"被中断了");
            }
            System.out.println(Thread.currentThread() + "继续执行");
        }
    }
}

public static void main(String[] args) throws InterruptedException {
    t1.start();
    Thread.sleep(1000L);
    t2.start();
    Thread.sleep(3000L);
    t1.interrupt();
    LockSupport.unpark(t2);
    t1.join();
    t2.join();
}
```

> LockSuport主要是针对Thread进进行阻塞处理，可以指定阻塞队列的目标对象，每次可以指定具体的线程唤醒。Object.wait()是以对象为纬度，阻塞当前的线程和唤醒单个(随机)或者所有线程

> park和unpark可以实现类似wait和notify的功能，但是并不和wait和notify交叉，也就是说unpark不会对wait起作用，notify也不会对park起作用

# StampedLock

> 之前的锁或多或少都存在一些缺点，比如synchronized不可中断等，ReentrantLock 未能读写分离实现，虽然ReentrantReadWriteLock能够读写分离了，但是对于其写锁想要获取的话，就必须没有任何其他读写锁存在才可以，这实现了悲观读取。而且如果读操作很多，写很少的情况下，线程有可能遭遇饥饿问题。

> 饥饿问题：ReentrantReadWriteLock实现了读写分离，想要获取读锁就必须确保当前没有其他任何读写锁了，但是一旦读操作比较多的时候，想要获取写锁就变得比较困难了，因为当前有可能会一直存在读锁。而无法获得写锁

所以java8引入了新的锁StampedLock，这个类没有直接实现Lock或者ReadWriteLock方法，源码中是把他当作一个单独的类来实现的。相比于普通的ReentranReadWriteLock主要多了一种乐观读的功能。当然，一个StampedLock可以通过asReadLock，asWriteLock，asReadWriteLock方法来得到全部功能的子集


# AbstractQwnableSynchronizer

抽象拥有同步器，简称AOS

# AbstractQueuedSynchronizer

提供了一个基于FIFO队列，可以用于构建锁或者其他相关同步装置的基础框架, 简称AQS

# AbstractQueuedLongSynchronizer

扩展自AbstractQueuedSynchronizer


---todo 未完待续---


