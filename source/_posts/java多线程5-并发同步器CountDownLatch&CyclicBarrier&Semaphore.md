---
title: java多线程5-并发同步器CountDownLatch&CyclicBarrier&Semaphore
date: 2020-07-31 10:38:35
categories: [java, 多线程]  
tags: [java, 多线程]
---

# CountDownLatch

一个或多个线程等待其他线程完成操作

## 概念
CountDownLatch能够使一个线程在等待另外一些线程完成各自工作之后，再继续执行。使用一个计数器进行实现。计数器初始值为线程的数量。当每一个线程完成自己任务后，计数器的值就会减一。当计数器的值为0时，表示所有的线程都已经完成一些任务，然后在CountDownLatch上等待的线程就可以恢复执行接下来的任务。

CountDownLatch可以解决那些一个或者多个线程在执行之前必须依赖于某些必要的前提业务先执行的场景

 <!-- more -->

## 常用方法

```
//构造方法，创建一个值为count 的计数器
public CountDownLatch(int count); 
​
//阻塞当前线程，将当前线程加入阻塞队列, 等待直到count值为0才继续执行
await();
​
//和await()类似，只不过等待一定的时间后count值还没变为0的话就会继续执行
await(long timeout, TimeUnit unit);
​
//对计数器进行递减1操作，当计数器递减至0时，当前线程会去唤醒阻塞队列里的所有线程
countDown();
```

## 应用场景

1. 从多个统计结果汇总数据进行报表统计

```
public class CountDownLatchTest1 {
    //用于聚合所有的统计指标
    private static final Map<String, Integer> map = new HashMap<>();
    //创建计数器，这里需要统计4个指标
    private static final CountDownLatch countDownLatch = new CountDownLatch(4);

    public static void main(String[] args) {
        long startTime = System.currentTimeMillis();

        CompletableFuture.runAsync(() -> {
            try {
                System.out.println("正在统计新增用户数量");
                Thread.sleep(3000);//任务执行需要3秒
                map.put("userNumber", 1);//保存结果值
                countDownLatch.countDown();//标记已经完成一个任务
                System.out.println("统计新增用户数量完毕");
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        });

        CompletableFuture.runAsync(() -> {
            try {
                System.out.println("正在统计订单数量");
                Thread.sleep(3000);//任务执行需要3秒
                map.put("countOrder", 2);//保存结果值
                countDownLatch.countDown();//标记已经完成一个任务
                System.out.println("统计订单数量完毕");
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

        });

        CompletableFuture.runAsync(() -> {
            try {
                System.out.println("正在商品销量");
                Thread.sleep(3000);//任务执行需要3秒
                map.put("countGoods", 3);//保存结果值
                countDownLatch.countDown();//标记已经完成一个任务
                System.out.println("统计商品销量完毕");
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        });

        CompletableFuture.runAsync(() -> {
            try {
                System.out.println("正在总销售额");
                Thread.sleep(3000);//任务执行需要3秒
                map.put("countmoney", 4);//保存结果值
                countDownLatch.countDown();//标记已经完成一个任务
                System.out.println("统计销售额完毕");
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        });
        try {
            //主线程等待所有统计指标执行完毕
            countDownLatch.await();
            long endTime = System.currentTimeMillis();//记录结束时间
            System.out.println("------统计指标全部完成--------");
            System.out.println("统计结果为：" + map.toString());
            System.out.println("任务总执行时间为" + (endTime - startTime) / 1000 + "秒");
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```

2. 百米赛跑, 当所有选手到达终点, 裁判进行汇总排名

```
public class CountdownLatchTest2 {

    public static void main(String[] args) {
        ExecutorService service = Executors.newCachedThreadPool();
        final CountDownLatch cdOrder = new CountDownLatch(1);
        final CountDownLatch cdAnswer = new CountDownLatch(4);
        for (int i = 0; i < 4; i++) {
            Runnable runnable = () -> {
                try {
                    System.out.println("选手" + Thread.currentThread().getName() + "正在等待裁判发布口令");
                    cdOrder.await();
                    System.out.println("选手" + Thread.currentThread().getName() + "已接受裁判口令");
                    Thread.sleep((long) (Math.random() * 10000));
                    System.out.println("选手" + Thread.currentThread().getName() + "到达终点");
                    cdAnswer.countDown();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            };
            service.execute(runnable);
        }
        try {
            Thread.sleep((long) (Math.random() * 10000));
            System.out.println("裁判"+Thread.currentThread().getName()+"即将发布口令");
            cdOrder.countDown();
            System.out.println("裁判"+Thread.currentThread().getName()+"已发送口令，正在等待所有选手到达终点");
            cdAnswer.await();
            System.out.println("所有选手都到达终点");
            System.out.println("裁判"+Thread.currentThread().getName()+"汇总成绩排名");
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        service.shutdown();
    }

}
```

3. 模拟并发操作

```
//模拟的并发量
    private static final int CONCURRENT_NUM = 199;

    public static void main(String[] args) throws InterruptedException {
        Runnable taskTemp = new Runnable() {

            // 注意，此处是非线程安全的，留坑
            private AtomicInteger iCounter = new AtomicInteger();

            @Override
            public void run() {
                doSomething(iCounter);
            }
        };
        LatchTest latchTest = new LatchTest();
        latchTest.startTaskAllInOnce(CONCURRENT_NUM, taskTemp);
    }

    private static void doSomething(AtomicInteger iCounter) {
        for(int i = 0; i < 10; i++) {
            // 发起请求
            //此处模拟方法
            int value = iCounter.incrementAndGet();
            System.out.println(System.nanoTime() + " [" + Thread.currentThread().getName() + "] iCounter = " + value);
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    public long startTaskAllInOnce(int threadNums, final Runnable task) throws InterruptedException {
        final CountDownLatch startGate = new CountDownLatch(1);
        final CountDownLatch endGate = new CountDownLatch(threadNums);
        for(int i = 0; i < threadNums; i++) {
            Thread t = new Thread(() -> {
                try {
                    // 使线程在此等待，当开始门打开时，一起涌入门中
                    startGate.await();
                    try {
                        task.run();
                    } finally {
                        // 将结束门减1，减到0时，就可以开启结束门了
                        endGate.countDown();
                    }
                } catch (InterruptedException ie) {
                    ie.printStackTrace();
                }
            });
            t.start();
        }
        long startTime = System.nanoTime();
        System.out.println(startTime + " [" + Thread.currentThread() + "] All thread is ready, concurrent going...");
        // 因开启门只需一个开关，所以立马就开启开始门
        startGate.countDown();
        // 等等结束门开启
        endGate.await();
        long endTime = System.nanoTime();
        System.out.println(endTime + " [" + Thread.currentThread() + "] All thread is completed.");
        return endTime - startTime;
    }
```

4. A，B，C的工作都分为两个阶段，A只需要等待B，C各自完成他们工作的第一个阶段就可以执行了

```
public class Employee extends Thread{

    private String employeeName;

    private long time;

    private CountDownLatch countDownLatch;

    public Employee(String employeeName,long time, CountDownLatch countDownLatch){
        this.employeeName = employeeName;
        this.time = time;
        this.countDownLatch = countDownLatch;
    }

    @Override
    public void run() {
        try {
            System.out.println(employeeName+ " 第一阶段开始准备");
            Thread.sleep(time);
            System.out.println(employeeName+" 第一阶段准备完成");

            countDownLatch.countDown();

            System.out.println(employeeName+ " 第二阶段开始准备");
            Thread.sleep(time);
            System.out.println(employeeName+" 第二阶段准备完成");

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) throws InterruptedException {
        CountDownLatch countDownLatch = new CountDownLatch(2);
        Employee a = new Employee("A", 3000,countDownLatch);
        Employee b = new Employee("B", 3000,countDownLatch);
        Employee c = new Employee("C", 4000,countDownLatch);

        b.start();
        c.start();
        countDownLatch.await();
        System.out.println("B,C准备完成");
        a.start();
    }
}

```

## 不足

CountDownLatch是一次性的，计算器的值只能在构造方法中初始化一次，之后没有任何机制再次对其设置值，当CountDownLatch使用完毕后，它不能再次被使用，而CyclicBarrier可以实现循环拦截

# CyclicBarrier

同步屏障

## 概念

循环栅栏，CyclicBarrier的计数器像一个阀门，需要所有线程都到达，然后继续执行，计数器递增，提供reset功能，可以多次使用。通过它可以实现让一组线程等待至某个状态之后再全部同时执行。

## 常用方法

```
//构造方法
//要拦截的线程数 每一阶段结束时要执行的任务
 public CyclicBarrier(int parties, Runnable barrierAction)

//用来挂起当前线程，直至所有线程都到达barrier状态再同时执行后续任务
public int await() throws InterruptedException, BrokenBarrierException { };

//让线程等待至一定的时间，如果还有线程没有到达barrier状态就直接让到达barrier的线程执行后续任务
public int await(long timeout, TimeUnit unit)throws InterruptedException,BrokenBarrierException,TimeoutException { };

//重置
reset();
```

## 应用场景

现实生活中我们经常会遇到这样的情景，在进行某个活动前需要等待人全部都齐了才开始。例如吃饭时要等全家人都上座了才动筷子，旅游时要等全部人都到齐了才出发，比赛时要等运动员都上场后才开始。在JUC包中为我们提供了一个同步工具类能够很好的模拟这类场景，它就是CyclicBarrier类。

1. 小明、小红、小亮兄妹三个要吃早吃饭，妈妈说先洗手，洗完手之后大家一起吃，等三个人吃完饭，再一起去玩。

> 在这个例子中第一个barrier状态是大家都洗好手，第二个barrier状态是大家都吃完饭。第二个barrier在第一个barrier释放后可以重用。

```
public class CyclicBarrierTest {
    public static void main(String[] args) {
        CyclicBarrier barrier = new CyclicBarrier(3, () -> System.out.println("开始做下一件事吧..."));

        ExecutorService executorService = Executors.newFixedThreadPool(3);

        executorService.execute(new Child(barrier, "小明", 3));
        executorService.execute(new Child(barrier, "小红", 5));
        executorService.execute(new Child(barrier, "小亮", 2));

        executorService.shutdown();
    }

    static class Child implements Runnable {
        private final CyclicBarrier cyclicBarrier;
        private final String name;
        private final long sleep;

        public Child(CyclicBarrier cyclicBarrier, String name, long sleep) {
            this.cyclicBarrier = cyclicBarrier;
            this.name = name;
            this.sleep = sleep;
        }

        @Override
        public void run() {
            System.out.println(this.name + "正在洗手...");
            try {
                TimeUnit.SECONDS.sleep(sleep);//以睡眠来模拟洗手
                System.out.println(this.name + "洗好了，等待其他小朋友洗完...");
//                cyclicBarrier.await();
                cyclicBarrier.await(10, TimeUnit.SECONDS);
            } catch (InterruptedException | BrokenBarrierException | TimeoutException e) {
                e.printStackTrace();
            }

            try {
                TimeUnit.SECONDS.sleep(sleep);      //以睡眠来模拟吃饭
                System.out.println(this.name + "吃好了，等待其他小朋友吃完.....");
                cyclicBarrier.await();
            } catch (InterruptedException | BrokenBarrierException e) {
                e.printStackTrace();
            }

        }
    }
}
```

2. 多轮赛马

```
public class Horse implements Runnable {

    private static int counter = 0;
    private final int id = counter++;
    private int strides = 0;
    private static Random rand = new Random(47);
    private static CyclicBarrier barrier;

    public Horse(CyclicBarrier b) { barrier = b; }

    @Override
    public void run() {
        try {
            while(!Thread.interrupted()) {
                synchronized(this) {
                    //赛马每次随机跑几步
                    strides += rand.nextInt(3);
                }
                barrier.await();
            }
        } catch(Exception e) {
            e.printStackTrace();
        }
    }

    public String tracks() {
        StringBuilder s = new StringBuilder();
        for(int i = 0; i < getStrides(); i++) {
            s.append("*");
        }
        s.append(id);
        return s.toString();
    }

    public synchronized int getStrides() { return strides; }
    @Override
    public String toString() { return "Horse " + id + " "; }

}

public class HorseRace implements Runnable {

    private static final int FINISH_LINE = 75;
    private static List<Horse> horses = new ArrayList<Horse>();
    private static ExecutorService exec = Executors.newCachedThreadPool();

    @Override
    public void run() {
        StringBuilder s = new StringBuilder();
        //打印赛道边界
        for(int i = 0; i < FINISH_LINE; i++) {
            s.append("=");
        }
        System.out.println(s);
        //打印赛马轨迹
        for(Horse horse : horses) {
            System.out.println(horse.tracks());
        }
        //判断是否结束
        for(Horse horse : horses) {
            if(horse.getStrides() >= FINISH_LINE) {
                System.out.println(horse + "won!");
                exec.shutdownNow();
                return;
            }
        }
        //休息指定时间再到下一轮
        try {
            TimeUnit.MILLISECONDS.sleep(200);
        } catch(InterruptedException e) {
            System.out.println("barrier-action sleep interrupted");
        }
    }

    public static void main(String[] args) {
        CyclicBarrier barrier = new CyclicBarrier(7, new HorseRace());
        for(int i = 0; i < 7; i++) {
            Horse horse = new Horse(barrier);
            horses.add(horse);
            exec.execute(horse);
        }
    }

}
```

> 在CyclicBarrier的内部定义了一个ReentrantLock的对象，然后再利用这个ReentrantLock对象生成一个Condition的对象。每当一个线程调用CyclicBarrier的await方法时，首先把剩余屏障的线程数减1，然后判断剩余屏障数是否为0：如果不是，利用Condition的await方法阻塞当前线程；如果是，首先利用Condition的signalAll方法唤醒所有线程，最后重新生成Generation对象以实现屏障的循环使用。

## CountDownLatch与CyclicBarrier不同

CountDownLatch和CyclicBarrier都能够实现线程之间的等待，只不过它们侧重点不同：

- CountDownLatch一般用于某个线程A等待若干个其他线程执行完任务之后，它才执行；
- CyclicBarrier一般用于一组线程互相等待至某个状态，然后这一组线程再同时执行；
- CountDownLatch是不能够重用的，而CyclicBarrier是可以重用的。

# Semaphore

控制并发线程数

## 概念

Semaphore（信号量）是用来控制同时访问特定资源的线程数量，它通过协调各个线程，以保证合理的使用公共资源

## 常用方法

```
//构造函数 接受一个整型的数字，表示可用的许可证数量(允许同时运行的线程数目), 也就是最大并发数
public Semaphore(int permits) 

公平（获得锁的顺序与线程启动顺序有关）：
//构造函数  获得锁的顺序与线程启动顺序是否有关
public Semaphore(int permits,boolean fair)

//获取一个许可证
void acquire() throws InterruptedException

//当前线程尝试去阻塞的获取1个许可证(不可中断的)
acquireUninterruptibly()

//归还许可证
void release()

//尝试获取许可证, 若获取成功返回true，若获取失败返回false
boolean tryAcquire()

//返回此信号量中当前可用的许可证数
int availablePermits()

//返回正在等待获取许可证的线程数
int getQueueLength()

//是否有线程正在等待获取许可证
boolean hasQueuedThreads()

```

## 应用场景

Semaphore可以用于做流量控制，特别公用资源有限的应用场景，比如数据库连接。假如有一个需求，要读取几万个文件的数据，因为都是IO密集型任务，我们可以启动几十个线程并发的读取，但是如果读到内存后，还需要存储到数据库中，而数据库的连接数只有10个，这时我们必须控制只有十个线程同时获取数据库连接保存数据，否则会报错无法获取数据库连接。这个时候，我们就可以使用Semaphore来做流控

1. 只有10个线程可以同时访问

```
public class SemaphoreTest {

    private static final int THREAD_COUNT = 30;

    private static ExecutorService threadPool = Executors.newFixedThreadPool(THREAD_COUNT);

    private static Semaphore s = new Semaphore(10);

    public static void main(String[] args) {
        for (int i = 0; i < THREAD_COUNT; i++) {
            threadPool.execute(() -> {
                try {
                    ////请求获得许可，如果有可获得的许可则继续往下执行，许可数减1。否则进入阻塞状态
                    s.acquire();
                    System.out.println("save data");

                    //释放许可，许可数加1
                    s.release();
                } catch (InterruptedException e) {
                }
            });
        }

        threadPool.shutdown();
    }
}
```

2. 模拟学校食堂的窗口打饭过程


```
public class SemaphoreTest3 {

    public static void main(String[] args) {

        //定义3个打饭窗口
        Semaphore semaphore = new Semaphore(3);

        //10个学生过来打饭
        for(int i = 0; i < 10; i++) {
            new Student(semaphore, "学生" + i).start();
        }
    }

    static class Student extends Thread {

        private Semaphore semaphore;
        private String name;

        public Student(Semaphore semaphore, String name) {
            this.semaphore = semaphore;
            this.name = name;
        }

        @Override
        public void run() {
            try {
                System.out.println(name + "进入了餐厅");
                semaphore.acquire();
                System.out.println(name + "拿到了打饭许可");
                TimeUnit.SECONDS.sleep(2);
            } catch (InterruptedException e) {
                e.printStackTrace();
            } finally {
                System.out.println(name + " 打好了饭，释放这个窗口");
                semaphore.release();
            }
        }
    }
}
```

模拟5000次请求，同时最大200个并发操作

```

    /**
     * 请求总数
     */
    private static final int THREAD_COUNT = 5000;

    /**
     * 同时并发执行的线程数
     */
    private static final int CONCURRENT_COUNT = 200;


    private static int count = 0;
    public static void main(String[] args) throws InterruptedException {
        ExecutorService executorService = Executors.newCachedThreadPool();

        //信号量 能保证同时执行的线程最多200个，模拟出稳定的并发量
        final Semaphore semaphore = new Semaphore(CONCURRENT_COUNT);

        //闭锁，实现计数器递减
        final CountDownLatch countDownLatch = new CountDownLatch(THREAD_COUNT);
        for (int i = 0; i < THREAD_COUNT; i++) {
            executorService.execute(() -> {
                try {
                    //获取执行许可，当总计未释放的许可数不超过200是，允许通过
                    //否则线程阻塞等待，直到获取许可
                    semaphore.acquire();
                    add();
                    //执行后，释放许可
                    semaphore.release();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                //闭锁减一
                countDownLatch.countDown();
            });
        }
        //线程阻塞，直到闭锁值为0时，继续往下执行
        countDownLatch.await();
        executorService.shutdown();
        System.out.println(count);
    }

    private static void add(){
        count++;
    }
```