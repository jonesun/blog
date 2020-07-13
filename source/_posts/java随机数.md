---
title: java随机数
date: 2020-07-13 10:51:10
categories: java 
tags: [java]
---

# 1.Random

Random从java1.0开始就已经引入，是线程安全的。

> 初始化

Random初始化时，默认采用seeduniquifier方法生成的seed和获取到的当前原子时钟的当前时间的与操作后的值来初始化一个随机数种子。因为System.nanoTime()是一直变化的，所以种子一定是每次都不一样的，默认初始化的源码如下：

```
public Random() {
        this(seedUniquifier() ^ System.nanoTime());
    }

/**
* seedUniquifier解释
* 该方法是一个类似while(true)的无限循环for (;;)
* 循环结束的条件是把seedUniquifier和一个常量值的乘积赋值给seedUniquifier，然后判断是否等于seedUniquifier.get()
*/
  private static long seedUniquifier() {
        // L'Ecuyer, "Tables of Linear Congruential Generators of
        // Different Sizes and Good Lattice Structure", 1999
        for (;;) {
            long current = seedUniquifier.get();
            long next = current * 1181783497276652981L;
            if (seedUniquifier.compareAndSet(current, next))
                return next;
        }
    }

    private static final AtomicLong seedUniquifier
        = new AtomicLong(8682522807148012L);
}

```

> 随机方法

其核心方法是 next方法，不管是调用了nextDouble还是nextInt还是nextBoolean，底层都是调这个next(int bits)：

```
/**
* 为了保证多线程下每次生成随机数都是用的不同，next()得保证seed的更新是原子操作，所以用了AtomicLong的compareAndSet()，以保证原子更新一个数。
* 当然也可以看出多个线程如果更新设置失败，会不停的在while循环执行，并且由于采用了多个线程共享一个 Random 实例。这样就会导致多个线程争用，出现性能上的问题
*/
protected int next(int bits) {
    long oldseed, nextseed;
    AtomicLong seed = this.seed;
    do {
        oldseed = seed.get();
        nextseed = (oldseed * multiplier + addend) & mask;
    } while (!seed.compareAndSet(oldseed, nextseed));
    return (int)(nextseed >>> (48 - bits));
}
```

# 2.ThreadLocalRandom

为了在多线程并发情况下，减少多线程资源竞争，保证线程的安全性。java1.7新增了ThreadLocalRandom，继承于Random。

> 初始化

因为构造器是默认访问权限，只能在java.util包中创建对象，故提供了一个方法ThreadLocalRandom.current()用于返回当前类的对象, 可以看到每个线程都持有一个本地的种子变量，该种子变量只有在使用随机数时才会被初始化。在多线程下计算新种子时，是根据自己线程内维护的种子变量进行更新，这就完全杜绝了线程间的竞争问题：

```
public static ThreadLocalRandom current() {
    if (U.getInt(Thread.currentThread(), PROBE) == 0)
        localInit();
    return instance;
}

static final void localInit() {
    int p = probeGenerator.addAndGet(PROBE_INCREMENT);
    int probe = (p == 0) ? 1 : p; // skip 0
    long seed = mix64(seeder.getAndAdd(SEEDER_INCREMENT));
    Thread t = Thread.currentThread();
    U.putLong(t, SEED, seed);
    U.putInt(t, PROBE, probe);
}
```

> 随机方法

ThreadLocalRandom是通过ThreadLocal改进的用于随机数生成的工具类，每个线程单独持有一个ThreadLocalRandom对象引用，这就完全杜绝了线程间的竞争问题：

```
final long nextSeed() {
    Thread t; long r; // read and update per-thread seed
    U.putLong(t = Thread.currentThread(), SEED,
                r = U.getLong(t, SEED) + GAMMA);
    return r;
}

```

# 使用JMH进行测试

## 随机0-10

```
@BenchmarkMode(Mode.AverageTime) //平均时间
@State(Scope.Benchmark) //所有测试线程共享一个实例
@OutputTimeUnit(TimeUnit.NANOSECONDS) //统计结果的时间单位
@Warmup(iterations = 3, time = 1, timeUnit = TimeUnit.SECONDS) //预热迭代3次，每次1s
@Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS) //实际测试5次，每次1s
@Fork(2) //进行 fork 的次数
//@Threads(4)
public class RandomTest {

    public static void main(String[] args) throws RunnerException {
        Options opt = new OptionsBuilder()
                .include(RandomTest.class.getSimpleName())
                .result("random-result.json")
                .resultFormat(ResultFormatType.JSON).build();
        new Runner(opt).run();
    }

    @Benchmark
    public void testRandom(Blackhole blackhole) {
        Random random = new Random();
        int result = random.nextInt(10);
        System.out.println("random随机数: " + result);
        //JVM 可能会认为变量 result 从来没有使用过，从而进行优化把整个方法内部代码移除掉，这就会影响测试结果。
        // JMH 提供了两种方式避免这种问题，一种是将这个变量作为方法返回值 return a，一种是通过 Blackhole 的 consume 来避免 JIT 的优化消除
        blackhole.consume(result);
    }

    @Benchmark
    public void testThreadLocalRandom(Blackhole blackhole) {
        ThreadLocalRandom threadLocalRandom = ThreadLocalRandom.current();
        int result = threadLocalRandom.nextInt(10);
        blackhole.consume(result);
    }
}
```

## 测试结果

![image](https://github.com/jonesun/blog/blob/master/source/image/jmh/JMH-Visual-Chart-Random.png?raw=true) 

可以看到ThreadLocalRandom效率最高