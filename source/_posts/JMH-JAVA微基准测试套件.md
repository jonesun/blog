---
title: JMH-Java微基准测试套件
date: 2020-07-20 16:36:30
categories: [java]
tags: [java, JMH, 测试]
---

# JMH(Java Microbenchmark Harness)和jMeter的不同

> JMH和jMeter的使用场景还是有很大的不同的，jMeter更多的是对rest api进行压测，而JMH关注的粒度更细，它更多的是发现某块性能槽点代码，然后对优化方案进行基准测试对比。比如json序列化方案对比，bean copy方案对比，文中提高的洗牌算法对比等。

[官方样例](http://hg.openjdk.java.net/code-tools/jmh/file/tip/jmh-samples/src/main/java/org/openjdk/jmh/samples/)

[国人翻译的demo](https://github.com/Childe-Chen/goodGoodStudy/tree/master/src/main/java/com/cxd/benchmark)

# 应用场景

JMH比较典型的应用场景有：

- 想准确的知道某个方法需要执行多长时间，以及执行时间和输入之间的相关性
- 对比接口不同实现在给定条件下的吞吐量，找到最优实现
- 查看多少百分比的请求在多长时间内完成
- ...


# JMH 可视化

将测试例子结果的 json 文件导入，就可以实现可视化

[JMH Visual Chart](http://deepoove.com/jmh-visual-chart/)

[JMH Visualizer](https://jmh.morethan.io/)

<!-- more -->

# JMH 插件

可以通过 IDEA 安装 JMH 插件使 JMH 更容易实现基准测试，在 IDEA 中点击 File->Settings...->Plugins，然后搜索 jmh，选择安装 JMH plugin

这个插件可以让我们能够以 JUnit 相同的方式使用 JMH，主要功能如下：

- 自动生成带有 @Benchmark 的方法
- 像 JUnit 一样，运行单独的 Benchmark 方法
- 运行类中所有的 Benchmark 方

比如可以通过右键点击 Generate...，选择操作 Generate JMH benchmark 就可以生成一个带有 @Benchmark 的方法。

还有将光标移动到方法声明并调用 Run 操作就运行一个单独的 Benchmark 方法。

将光标移到类名所在行，右键点击 Run 运行，该类下的所有被 @Benchmark 注解的方法都会被执行。

## 使用

# maven 引用

```
        <!-- https://mvnrepository.com/artifact/org.openjdk.jmh/jmh-core -->
        <dependency>
            <groupId>org.openjdk.jmh</groupId>
            <artifactId>jmh-core</artifactId>
            <version>1.23</version>
        </dependency>

        <!-- https://mvnrepository.com/artifact/org.openjdk.jmh/jmh-generator-annprocess -->
        <dependency>
            <groupId>org.openjdk.jmh</groupId>
            <artifactId>jmh-generator-annprocess</artifactId>
            <version>1.23</version>
            <!--            <scope>test</scope>-->
        </dependency>

```

## JMH 基础

**@BenchmarkMode**

用来配置 Mode 选项，可用于类或者方法上，这个注解的 value 是一个数组，可以把几种 Mode 集合在一起执行，如：@BenchmarkMode({Mode.SampleTime, Mode.AverageTime})，还可以设置为 Mode.All，即全部执行一遍：

- Throughput：整体吞吐量，每秒执行了多少次调用，单位为 ops/time
- AverageTime：用的平均时间，每次操作的平均时间，单位为 time/op
- SampleTime：随机取样，最后输出取样结果的分布
- SingleShotTime：只运行一次，往往同时把 Warmup 次数设为 0，用于测试冷启动时的性能
- All：上面的所有模式都执行一次

**@State**

通过 State 可以指定一个对象的作用范围，JMH 根据 scope 来进行实例化和共享操作。@State 可以被继承使用，如果父类定义了该注解，子类则无需定义。由于 JMH 允许多线程同时执行测试，不同的选项含义如下：

- Scope.Benchmark：所有测试线程共享一个实例，测试有状态实例在多线程共享下的性能
- Scope.Group：同一个线程在同一个 group 里共享实例
- Scope.Thread：默认的 State，每个测试线程分配一个实例

**@OutputTimeUnit**

为统计结果的时间单位，可用于类或者方法注解。例如OutputTimeUnit申明为纳秒，所以基准测试单位是ns/op，即每次操作的纳秒单位平均时间
如果@BenchmarkMode(Mode.Throughput)和@OutputTimeUnit(TimeUnit.MILLISECONDS)那么基准测试结果就是每毫秒的吞吐量（即每毫秒多少次操作）


**@Warmup**

预热所需要配置的一些基本测试参数，可用于类或者方法上。一般前几次进行程序测试的时候都会比较慢，所以要让程序进行几轮预热，保证测试的准确性。参数如下所示：

- iterations：预热的次数
- time：每次预热的时间
- timeUnit：时间的单位，默认秒
- batchSize：批处理大小，每次操作调用几次方法


```
//代码预热总计5秒（迭代5次，每次1秒
@Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
```


> 为什么需要预热？

    因为 JVM 的 JIT 机制的存在，如果某个函数被调用多次之后，JVM 会尝试将其编译为机器码，从而提高执行速度，所以为了让 benchmark 的结果更加接近真实情况就需要进行预热。

**@Measurement**

实际调用方法所需要配置的一些基本测试参数，可用于类或者方法上，参数和 @Warmup 相同。


```
//表示循环运行5次，总计5秒时间
@Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
```


**@Threads**

每个进程中的测试线程，可用于类或者方法上。

**@Fork**

进行 fork 的次数，可用于类或者方法上。如果@Fork(1)，那么就是一个线程，这时候就是同步模式。如果 fork 数是 2 的话，则 JMH 会 fork 出两个进程来进行测试。

**@Param**

指定某项参数的多种情况，特别适合用来测试一个函数在不同的参数输入的情况下的性能，只能作用在字段上，使用该注解必须定义 @State 注解。


```
@Param({"1","2","3"})
int  outputType;
@Benchmark
public String benchmark() throws TemplateException, IOException {
  if(outputType==3){
			return doStream();
  }else if(outputType==2) {
    return doCharStream()
  }else{
    return  doString();
  }
 
}
```


**@Setup 和 @TearDown**

这是一对注解，作用于方法上，前者用于测试前的初始化工作，后者用于回收某些资源，比如压测前需要准备一些数据

**@Level**

用于控制 @Setup，@TearDown 的调用时机，有如下含义

- Level.Tiral: 运行每个性能测试的时候执行，推荐的方式
- Level.Iteration, 每次迭代的时候执行
- Level.Invocation,每次调用方法的时候执行，这个选项需要谨慎使用

## 运行Benchmark

JMH提供了Runner类能运行Benchmark类


```

public static void main(String[] args) throws RunnerException {
    Options opt = new OptionsBuilder()
        .include(MyBenchmark.class.getSimpleName())
        .build();
    new Runner(opt).run();
}

 public static void main(String[] args) throws RunnerException {
        Options opt = new OptionsBuilder()
                .include(StringConnectTest.class.getSimpleName())
                .result("result.json")
                .resultFormat(ResultFormatType.JSON).build();
        new Runner(opt).run();
    }
//include接受一个字符串表达式，如只测试方法名字包含“testObjectKey“的方法
include(MyBenchmark.class.getSimpleName()+".*testObjectKey*")

//用4个子进程做性能测试，每个进程预热一次，执行5次迭代
public static void main(String[] args) throws RunnerException {
    Options opt = new OptionsBuilder()
        .include(MyBenchmark.class.getSimpleName())
        .forks(4)
        .warmupIterations(1)
        .measurementIterations(5)
        .build();
    new Runner(opt).run();
}
```