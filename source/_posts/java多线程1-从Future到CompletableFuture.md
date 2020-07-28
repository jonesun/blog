---
title: java多线程1-从Future到CompletableFuture
date: 2020-07-14 13:50:58
categories: java 
tags: [java, 多线程, future]
---

# 引言
Java项目编程中，为了充分利用计算机CPU资源，一般开启多个线程来执行异步任务。多线有很多好处，其中最重要的是：

- 可以发挥多核CPU的优势

随着工业的进步，现在的笔记本、台式机乃至商用的应用服务器至少也都是双核的，4核、8核甚至16核的也都不少见，如果是单线程的程序，那么在双核CPU上就浪费了50%，在4核CPU上就浪费了75%。单核CPU上所谓的”多线程”那是假的多线程，同一时间处理器只会处理一段逻辑，只不过线程之间切换得比较快，看着像多个线程”同时”运行罢了。多核CPU上的多线程才是真正的多线程，它能让你的多段逻辑同时工作，多线程，可以真正发挥出多核CPU的优势来，达到充分利用CPU的目的。

- 防止阻塞

从程序运行效率的角度来看，单核CPU不但不会发挥出多线程的优势，反而会因为在单核CPU上运行多线程导致线程上下文的切换，而降低程序整体的效率。但是单核CPU我们还是要应用多线程，就是为了防止阻塞。试想，如果单核CPU使用单线程，那么只要这个线程阻塞了，比方说远程读取某个数据吧，对端迟迟未返回又没有设置超时时间，那么你的整个程序在数据返回回来之前就停止运行了。多线程可以防止这个问题，多条线程同时运行，哪怕一条线程的代码执行读取数据阻塞，也不会影响其它任务的执行。

# 多线程发展

## 一、Thread&Runable

java1开始，常见的两种创建线程的方式。一种是直接继承Thread，另外一种就是实现Runnable接口。

从源码中可以看到，Thread也是实现Runable接口的：

```
public class Thread implements Runnable {
    private Runnable target;

    //构造方法
    public Thread(Runnable target) {
        this(null, target, "Thread-" + nextThreadNum(), 0);
    }

    //run()方法
    @Override
    public void run() {
        if (target != null) {
            target.run();
        }
    }
}


```
区别在于，Thread并没有直接实现run()方法，而调用的是 Runnable 接口中的 run() 方法，也就是说此方法是由 Runnable 子类完成的，所以如果要通过继承 Thread 类实现多线程，则必须覆写 run()；

但这两种方式存在一些问题：

- 没有参数

- 没有返回值

- 无法抛出异常

 <!-- more -->

```
 public static void main(String[] args) {
        System.out.println("starting");

        System.out.println("准备执行thread....");
        handleWithThread();
//        handleWithoutThread();
        System.out.println("thread执行完成");

        //执行结果，可以发现线程中出现异常后，主线程并不会停止
    }

    private static void handleWithThread() {
        Thread thread = new Thread(new Runnable() {
            @Override
            public void run() {
                makeNPE();
            }
        });
        thread.start();
    }

    private static void handleWithoutThread() {
        makeNPE();
    }

    private static void makeNPE(){
        String s = null;
        if(s.equals("abc")) {
            //do something
        }
    }
```
## 二、Callable

为了解决上面的问题，java5引入了Callable类。从源码中可以看到Callable的call() 方法签名有 throws，所以它可以处理受检异常：

```
@FunctionalInterface
public interface Callable<V> {
    /**
     * Computes a result, or throws an exception if unable to do so.
     *
     * @return computed result
     * @throws Exception if unable to compute a result
     */
    V call() throws Exception;
}

```

值得一提的是Callable并不可以单独执行，需要ExecutorService配合线程池使用：

```
<T> Future<T> submit(Callable<T> task);
<T> Future<T> submit(Runnable task, T result);
Future<?> submit(Runnable task);
```
> Future<?>解释，为了可取消性而使用 Future 但又不提供可用的结果，故声明 Future<?> 形式类型、并返回 null 作为底层任务的结果

可以看到使用线程池时，无论使用Runable还是Callable，都默认返回Future，下面我们就来看看这个Future是何方神圣。

## 三、Future

Future与Callable一样都是java1.5开始引入的。同Callable与Runable一样，Future也是一个接口类：

```
public interface Future<V> {

    /**
     * 取消
     * @param mayInterruptIfRunning
     * @return
     */
    boolean cancel(boolean mayInterruptIfRunning);

    /**
     * 判断是否取消
     * 如果在任务正常完成前被取消成功，才返回 true
     * @return
     */
    boolean isCancelled();

    /**
     * 判断是否完成
     * @return
     */
    boolean isDone();

    /**
     * 获取执行结果
     * @return
     * @throws InterruptedException
     * @throws ExecutionException
     */
    V get() throws InterruptedException, ExecutionException;

    /**
     * 获取执行结果，如果指定时间内未完成则抛出异常(TimeoutException)
     * @param timeout
     * @param unit
     * @return
     * @throws InterruptedException
     * @throws ExecutionException
     * @throws TimeoutException
     */
    V get(long timeout, TimeUnit unit)
            throws InterruptedException, ExecutionException, TimeoutException;

}

```

这里需要着重说明下cancel(mayInterruptIfRunning)方法：

1. 如果发起cancel时任务还没有开始运行，则随后任务就不会被执行；
1. 如果发起cancel时，任务已经执行完成了，则返回false
1. 如果发起cancel时，任务已经被取消过了，则返回false
1. 如果发起cancel时任务已经在运行了，则这时就需要看 mayInterruptIfRunning 参数了：
    - 如果mayInterruptIfRunning 为true, 则返回true，且当前在执行的任务会被中断
    - 如果mayInterruptIfRunning 为false, 则返回true,且正在执行的任务继续运行，直到它执行完


```
//cancel源码如下
    public boolean cancel(boolean mayInterruptIfRunning) {
        if (!(state == NEW && STATE.compareAndSet
              (this, NEW, mayInterruptIfRunning ? INTERRUPTING : CANCELLED)))
            return false;
        try {    // in case call to interrupt throws exception
            if (mayInterruptIfRunning) {
                try {
                    Thread t = runner;
                    if (t != null)
                        t.interrupt();
                } finally { // final state
                    STATE.setRelease(this, INTERRUPTED);
                }
            }
        } finally {
            finishCompletion();
        }
        return true;
    }
```

由此可以知道Future可以对于具体的Runnable或者Callable任务的执行结果进行**取消**、查询是否完成、获取结果：

```
public class FutureAndCallableTest {
    
    public static void main(String[] args) {
        ExecutorService executorService = Executors.newSingleThreadExecutor();

        System.out.println(Thread.currentThread().getName() + "主线程开始执行");
        Future<String> stringFuture =executorService.submit(new Callable<String>() {
            @Override
            public String call() throws Exception {
                System.out.println( Thread.currentThread().getName() + "执行Callable的call方法");
                //因为Callable的call方法会throw异常，故这边无需像Runnable显示try/catch
                TimeUnit.SECONDS.sleep(5);
                System.out.println( Thread.currentThread().getName() + "执行Callable的call方法完成");
                return "这是Callable的返回值";
            }
        });
        System.out.println(Thread.currentThread().getName() + "主线程继续执行");

        LocalTime startLocalTime = LocalTime.now();
        while (!stringFuture.isDone()) {
            System.out.println(Thread.currentThread().getName() + "主线程等待callable");
            if(ChronoUnit.SECONDS.between(startLocalTime, LocalTime.now()) >= 2) {
                System.out.println(Thread.currentThread().getName() + "主线程不想等待，取消任务");
                stringFuture.cancel(true);
            }
            try {
                TimeUnit.SECONDS.sleep(1);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        String futureResult = null;
        try {
            if(!stringFuture.isCancelled()) {
                futureResult = stringFuture.get(8, TimeUnit.SECONDS);
                System.out.println("主线程获取到返回值>>" + futureResult);
            } else {
                System.out.println("任务已取消>>" + futureResult);
            }
        } catch (InterruptedException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
        } finally {
            //注意一定要显示shutdown线程池，否则线程池不会自动关闭
            executorService.shutdown();
        }

    }
}

```

如果使用Debug可以发现，实际上ExecutorService返回的是Future的实现类FutureTask，下面我们就了解下FutureTask

## 四、FutureTask

通过查看源码，可以发现FutureTask实现了RunnableFuture接口，而RunnableFuture又继承了Runnable, Future两个接口。

所以就可以解释为什么ExecutorService会返回Future了，因为它既可以作为Runnable被线程执行，又可以作为Future得到Callable的返回值。

### Future不足

以上是单个Future的使用，但在开发过程中，我们可能会有以下需求

- 将两个异步计算合并为一个（这两个异步计算之间相互独立，同时第二个又依赖于第一个的结果）
- 等待 Future 集合中的所有任务都完成
- 仅等待 Future 集合中最快结束的任务完成，并返回它的结果


那么单使用Future是不够的，Future很难直接表述多个Future 结果之间的依赖性，没有提供方法去判断第一个完成的任务；同时Future也没有提供Callback机制，只能通过阻塞的get方法去获取结果。

所以java8引入了CompletableFuture

## 五、CompletableFuture

CompletableFuture也实现了Future接口，另外还实现了CompletionStage接口(它里面的方法表示的是是在某个运行阶段得到了结果之后要做的事情)

 ### 1. 创建CompletableFuture对象

```
//如果没有指定，默认会在ForkJoinPool.commonPool()中执行
public static CompletableFuture<Void> runAsync(Runnable runnable)
public static CompletableFuture<Void> runAsync(Runnable runnable, Executor executor)
public static <U> CompletableFuture<U> supplyAsync(Supplier<U> supplier)
public static <U> CompletableFuture<U> supplyAsync(Supplier<U> supplier, Executor executor)
```

 ### 2. thenApply-变换结果

```
//这些方法的输入是上一个阶段计算后的结果，返回值是经过转化后结果
public <U> CompletionStage<U> thenApply(Function<? super T,? extends U> fn);
public <U> CompletionStage<U> thenApplyAsync(Function<? super T,? extends U> fn);
public <U> CompletionStage<U> thenApplyAsync(Function<? super T,? extends U> fn,Executor executor);
```

> 示例

```
public void thenApply() {
    String result = CompletableFuture.supplyAsync(() -> "hello").thenApply(s -> s + " world").join();
    //同样可以使用get进行阻塞获取值，返回值需自己获取
    System.out.println(result);
}
```

>! 在线程操作中，可以使用 join() 方法让一个线程强制运行，线程强制运行期间，其他线程无法运行，必须等待此线程完成之后才可以继续执行

 ### 3. thenAccept-**消费**结果

```
//这些方法只是针对结果进行消费，入参是Consumer，没有返回值
public CompletionStage<Void> thenAccept(Consumer<? super T> action);
public CompletionStage<Void> thenAcceptAsync(Consumer<? super T> action);
public CompletionStage<Void> thenAcceptAsync(Consumer<? super T> action,Executor executor);
```

> 示例

```

public void thenAccept(){    

    //返回值在回调中
    CompletableFuture.supplyAsync(() -> "hello").thenAccept(s -> System.out.println(s+" world"));
}
```

 ### 4. thenRun-对上一步的计算结果不关心，执行下一个操作

```
public CompletionStage<Void> thenRun(Runnable action);
public CompletionStage<Void> thenRunAsync(Runnable action);
public CompletionStage<Void> thenRunAsync(Runnable action,Executor executor);
```

> 示例

```
public void thenRun(){
    CompletableFuture.supplyAsync(() -> {
        try {
            //线程休眠优先使用TimeUnit的方法
            //如果需要休眠1分钟TimeUnit.MINUTES.sleep(1);Thread.sleep(60000);明显可读性TimeUnit更强
            TimeUnit.SECONDS.sleep(2);
        } catch (InterruptedException e) {
            //中断线程会抛出此异常
            e.printStackTrace();
        }
        return "hello1";
    }).thenRun(() -> System.out.println("hello world"));
    //这里仅仅为测试方便，实际开发不能这么写
    while (true){}
}
```

 ### 5. thenCombine-结合两个CompletionStage的结果，进行转化后返回

```
//需要上一阶段的返回值，并且other代表的CompletionStage也要返回值之后，把这两个返回值，进行转换后返回指定类型的值
public <U,V> CompletionStage<V> thenCombine(CompletionStage<? extends U> other,BiFunction<? super T,? super U,? extends V> fn);
public <U,V> CompletionStage<V> thenCombineAsync(CompletionStage<? extends U> other,BiFunction<? super T,? super U,? extends V> fn);
public <U,V> CompletionStage<V> thenCombineAsync(CompletionStage<? extends U> other,BiFunction<? super T,? super U,? extends V> fn,Executor executor);
```

> 示例

```
public void thenCombine() {
    String result = CompletableFuture.supplyAsync(() -> {
        try {
            TimeUnit.SECONDS.sleep(2);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        return "hello";
    }).thenCombine(CompletableFuture.supplyAsync(() -> {
        try {
            TimeUnit.SECONDS.sleep(3);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        return "world";
    }), (s1, s2) -> s1 + " " + s2).join();
    System.out.println(result);
}

```

 ### 6. applyToEither-两个CompletionStage，谁计算的快，就用那个CompletionStage的结果进行下一步的转化操作

```
//两种渠道完成同一个事情，就可以调用这个方法，找一个最快的结果进行处理返回
public <U> CompletionStage<U> applyToEither(CompletionStage<? extends T> other,Function<? super T, U> fn);
public <U> CompletionStage<U> applyToEitherAsync(CompletionStage<? extends T> other,Function<? super T, U> fn);
public <U> CompletionStage<U> applyToEitherAsync(CompletionStage<? extends T> other,Function<? super T, U> fn,Executor executor);
```

> 示例

```
public void applyToEither() {
    String result = CompletableFuture.supplyAsync(() -> {
        try {
            TimeUnit.SECONDS.sleep(3);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        return "s1";
    }).applyToEither(CompletableFuture.supplyAsync(() -> {
        try {
            TimeUnit.SECONDS.sleep(2);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        return "hello world";
    }), s -> s).join();
    System.out.println(result);
}
```

 ### 7. acceptEither-两个CompletionStage，谁计算的快，就用那个CompletionStage的结果进行下一步的**消费**操作

```
public CompletionStage<Void> acceptEither(CompletionStage<? extends T> other,Consumer<? super T> action);
public CompletionStage<Void> acceptEitherAsync(CompletionStage<? extends T> other,Consumer<? super T> action);
public CompletionStage<Void> acceptEitherAsync(CompletionStage<? extends T> other,Consumer<? super T> action,Executor executor);
```

> 示例

```
public static void acceptEither() {
    CompletableFuture<Void> future = CompletableFuture.supplyAsync(() -> {
        try {
            TimeUnit.SECONDS.sleep(3);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        return "s1";
    }).acceptEither(CompletableFuture.supplyAsync(() -> {
        try {
            TimeUnit.SECONDS.sleep(2);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        return "hello world";
    }), System.out::println);
    while (!future.isDone()) {
    }
}
```

 ### 8. runAfterBoth-两个CompletionStage都运行完后执行

```
public void runAfterBoth(){
    CompletableFuture.supplyAsync(() -> {
        try {
            Thread.sleep(2000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        return "s1";
    }).runAfterBothAsync(CompletableFuture.supplyAsync(() -> {
        try {
            TimeUnit.SECONDS.sleep(3);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        return "s2";
    }), () -> System.out.println("hello world"));
    //这里仅仅为测试方便，实际开发不能这么写
    while (true){}
}
```

 ### 9. 运行时出现了异常，通过exceptionally进行补偿

```
public CompletionStage<T> exceptionally(Function<Throwable, ? extends T> fn);
```

> 示例

```
public void exceptionally() {
    String result = CompletableFuture.supplyAsync(() -> {
        try {
            TimeUnit.SECONDS.sleep(3);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        if (1 == 1) {
            throw new RuntimeException("测试一下异常情况");
        }
        return "s1";
    }).exceptionally(e -> {

        //修复空指针
        System.out.println(e.getMessage());
        return "hello world";
    }).join();
    System.out.println(result);
}
```
 ### 10. whenComplete-当运行完成时，对结果的记录

```
//这里为什么要说成记录，因为这几个方法都会返回CompletableFuture，当Action执行完毕后它的结果返回原始的CompletableFuture的计算结果或者返回异常。所以不会对结果产生任何的作用
public CompletionStage<T> whenComplete(BiConsumer<? super T, ? super Throwable> action);
public CompletionStage<T> whenCompleteAsync(BiConsumer<? super T, ? super Throwable> action);
public CompletionStage<T> whenCompleteAsync(BiConsumer<? super T, ? super Throwable> action,Executor executor);
```

> 示例

```
public void whenComplete() {
    String result = CompletableFuture.supplyAsync(() -> {
        try {
            TimeUnit.SECONDS.sleep(3);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        if (1 == 1) {
            throw new RuntimeException("测试一下异常情况");
        }
        return "s1";
    }).whenComplete((s, t) -> {
        System.out.println("whenComplete>>s: " + s);
        if(t != null) {
            System.out.println("whenComplete>>throwable" + t.getMessage());
        }
    }).exceptionally(e -> {
        System.out.println("exceptionally>>throwable: " + e.getMessage());
        return "hello world from exceptionally";
    }).join();
    System.out.println("result: " + result);
}
```

 ### 11. handle-运行完成时，对结果的处理

handle 方法和 thenApply 方法处理方式基本一样。不同的是 handle 是在任务完成后再执行，还可以处理异常的任务。thenApply 只可以执行正常的任务，任务出现异常则不执行 thenApply 方法。

```
public <U> CompletionStage<U> handle(BiFunction<? super T, Throwable, ? extends U> fn);
public <U> CompletionStage<U> handleAsync(BiFunction<? super T, Throwable, ? extends U> fn);
public <U> CompletionStage<U> handleAsync(BiFunction<? super T, Throwable, ? extends U> fn,Executor executor);
```

> 示例

```
public static void handle() {
    String result = CompletableFuture.supplyAsync(() -> {
        try {
            TimeUnit.SECONDS.sleep(3);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        //出现异常
        if (1 == 1) {
            throw new RuntimeException("测试一下异常情况");
        }
        return "s1";
    }).handle((s, t) -> {
        if (t != null) {
            return "hello world";
        }
        return s;
    }).join();
    System.out.println("result: " + result);

}
```

 ### 12. thenCompose -第一个操作完成时，将其结果作为参数传递给第二个操作

```
public <U> CompletableFuture<U> thenCompose(Function<? super T, ? extends CompletionStage<U>> fn);
public <U> CompletableFuture<U> thenComposeAsync(Function<? super T, ? extends CompletionStage<U>> fn) ;
public <U> CompletableFuture<U> thenComposeAsync(Function<? super T, ? extends CompletionStage<U>> fn, Executor executor) ;
```

> 示例

```
public void thenCompose() throws Exception {
    Integer result = CompletableFuture.supplyAsync(() -> {
        int t = new Random().nextInt(3);
        System.out.println("t1=" + t);
        return t;
    }).thenCompose(param -> CompletableFuture.supplyAsync(() -> {
        int t = param * 2;
        System.out.println("t2=" + t);
        return t;
    })).join();
    System.out.println("result : " + result);
}
```

 ### 13. anyOf-多个CompletableFuture谁计算的快，就用那个CompletionStage的结果进行下一步的**消费**操作

anyOf是CompletableFuture静态方法，和 acceptEither、applyToEither的区别在于，后两者只能使用在两个future中，而anyOf可以使用在多个future中

```
 public static CompletableFuture<Object> anyOf(CompletableFuture<?>... cfs) ;
```

示例

```
public void anyOf() {

    CompletableFuture<String> future1 = CompletableFuture.supplyAsync(() -> {
        System.out.println("future1执行...");
        try {
            TimeUnit.SECONDS.sleep(3);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("future1执行完成");
        return "from future1";
    });
    CompletableFuture<String> future2 = CompletableFuture.supplyAsync(() -> {
        System.out.println("future2执行...");
        try {
            TimeUnit.SECONDS.sleep(4);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("future2执行完成");
        return "from future2";
    });
    CompletableFuture<String> future3 = CompletableFuture.supplyAsync(() -> {
        System.out.println("future3执行...");
        try {
            TimeUnit.SECONDS.sleep(5);
            System.out.println("future3执行完成");
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        return "from future3";
    });

    CompletableFuture<Object> future =  CompletableFuture.anyOf(future1,future2,future3);
    try {
        System.out.println(future.get());
    } catch (InterruptedException | ExecutionException e) {
        e.printStackTrace();
    }
}
```

 ### 14. allOf-多个CompletableFuture都执行完后

```
public static CompletableFuture<Void> allOf(CompletableFuture<?>... cfs){}
```

> 示例

```
CompletableFuture<Void> future =  CompletableFuture.allOf(future1,future2,future3);
try {
    System.out.println(future.get()); //return null
} catch (InterruptedException | ExecutionException e) {
    e.printStackTrace();
}
```
可以看到使用allOf的话，默认是没有返回值的。当需要获取返回值做一些处理时，可以利用java8的Stream来组合多个future的结果

> 示例

```
CompletableFuture<Void> future = CompletableFuture.allOf(future1, future2, future3)
        .thenApply(v ->
                Stream.of(future1, future2, future3)
                        .map(CompletableFuture::join)
                        .collect(Collectors.joining(" ")))
        .thenAccept(System.out::println);
try {
    System.out.println(future.get(20, TimeUnit.SECONDS)); //return null
} catch (InterruptedException | ExecutionException | TimeoutException e) {
    e.printStackTrace();
}
```

> CompletableFuture默认运行使用的是ForkJoin的的线程池，这个线程池默认线程数是CPU的核数，所以强烈建议使用后两个方法，根据任务类型不同，主动创建线程池，进行资源隔离，避免互相干
扰

以上是CompletableFuture的常用方法，另外由于方法都是返回CompletableFuture，故可以通过各种排列组合，完成日常工作中的复杂逻辑。如获取商品的信息时，需要调用多个服务来处理这一个请求并返回结果。这里可能会涉及到并发编程，我们完全可以使用Java 8的CompletableFuture或者RxJava来实现

## Java9 CompletableFuture 类新增部分方法

1. 支持对异步方法的超时调用

```
orTimeout()
completeOnTimeout()
```

2. 支持延迟调用

```
Executor delayedExecutor(long delay, TimeUnit unit, Executor executor)
Executor delayedExecutor(long delay, TimeUnit unit)
```

## 延伸

可以看到CompletableFuture的写法与特性跟RxJava很像，但应用场景还是有些区别的：

composable | lazy | resuable | async | cached | push | back | pressure
---|---|---|---|---|---|---|---
CompletableFuture | 支持 | 不支持 | 支持 | 支持 | 支持 | 支持 | 不支持
Stream | 支持 | 支持 | 不支持 | 不支持 | 不支持 | 不支持 | 不支持
Observable(RxJava1) | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持
Observable(RxJava2) | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 | 不支持
Flowable(RxJava2) | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持

有关rxjava和stream的用法，限于篇幅，后面进行介绍

