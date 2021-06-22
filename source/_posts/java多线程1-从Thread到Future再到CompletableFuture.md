---
title: java多线程1-从Thread到Future再到CompletableFuture
categories:
  - java
  - 多线程
tags:
  - java
  - 多线程
  - future
abbrlink: 36c04c8a
date: 2020-07-14 13:50:58
---

# 引言

Java项目编程中，为了充分利用计算机CPU资源，一般开启多个线程来执行异步任务。多线有很多好处，其中最重要的是：

- 可以发挥多核CPU的优势

随着工业的进步，现在的笔记本、台式机乃至商用的应用服务器至少也都是双核的，4核、8核甚至16核的也都不少见，如果是单线程的程序，那么在双核CPU上就浪费了50%，在4核CPU上就浪费了75%。单核CPU上所谓的”多线程”那是假的多线程，同一时间处理器只会处理一段逻辑，只不过线程之间切换得比较快，看着像多个线程”同时”运行罢了。多核CPU上的多线程才是真正的多线程，它能让你的多段逻辑同时工作，多线程，可以真正发挥出多核CPU的优势来，达到充分利用CPU的目的。

- 防止阻塞

从程序运行效率的角度来看，单核CPU不但不会发挥出多线程的优势，反而会因为在单核CPU上运行多线程导致线程上下文的切换，而降低程序整体的效率。但是单核CPU我们还是要应用多线程，就是为了防止阻塞。试想，如果单核CPU使用单线程，那么只要这个线程阻塞了，比方说远程读取某个数据吧，对端迟迟未返回又没有设置超时时间，那么你的整个程序在数据返回回来之前就停止运行了。多线程可以防止这个问题，多条线程同时运行，哪怕一条线程的代码执行读取数据阻塞，也不会影响其它任务的执行。

# 一、Thread&Runnable

java1开始，常见的两种创建线程的方式。一种是直接继承Thread，另外一种就是实现Runnable接口。

从源码中可以看到，Thread也是实现Runnable接口的：

 <!-- more -->

```java
//Thread源码
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
    
    //......
}


```

区别在于，Thread并没有直接实现run()，而是调用Runnable接口中的run()，所以如果要通过继承Thread类实现多线程，则必须覆写run()方法。

但这两种方式存在一些问题：

- 没有参数
- 没有返回值
- 无法抛出异常

```java
class Test {
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
}

```

> 中断线程interrupt: 调用 interrupt() 方法，表示向当前线程打个招呼，告诉其可以中断线程了，至于什么时候终止，取决于当前线程自己，其实原理跟自定义标志位相似，只是打一个停止的标志，并不会去真的停止线程。
> 这种通过标志位或中断操作的方式能够使线程在终止时可以继续执行内部逻辑，而不是立即停止线程，所以，这种中断线程的方式更加的优雅安全，推荐此种方式：

```
Thread thread = new Thread(() -> {

        // isInterrupted()默认为false
        while (!Thread.currentThread().isInterrupted()) {
            i++;
        }
        System.out.println("i:"+i);

    });
thread.start();
TimeUnit.SECONDS.sleep(1);

// 将isInterrupted()设置为true
thread.interrupt();

```

# 二、Callable

为了解决上面的问题，java5引入了Callable类。从源码中可以看到Callable的call()方法签名有throws，所以它可以处理受检异常：

```java
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

但Callable并不可以单独执行，需要ExecutorService配合线程池使用：

```
<T> Future<T> submit(Callable<T> task);
<T> Future<T> submit(Runnable task, T result);
Future<?> submit(Runnable task);
```
> Future<?>解释，为了可取消性而使用 Future 但又不提供可用的结果，故声明 Future<?> 形式类型、并返回 null 作为底层任务的结果

可以看到使用线程池时，无论使用Runnable还是Callable，都默认返回Future，下面我们就来看看这个Future是何方神圣。

# 三、Future

Future与Callable一样都是java1.5开始引入的。同Callable与Runnable一样，Future也是一个接口类：

```java
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

* 如果发起cancel时任务还没有开始运行，则随后任务就不会被执行
* 如果发起cancel时，任务已经执行完成了，则返回false
* 如果发起cancel时，任务已经被取消过了，则返回false
* 如果发起cancel时任务已经在运行了，则这时就需要看 mayInterruptIfRunning 参数了：
    - 如果mayInterruptIfRunning 为true, 则返回true，且当前在执行的任务会被中断
    - 如果mayInterruptIfRunning 为false, 则返回true,且正在执行的任务继续运行，直到它执行完


```
//FutureTask中cancel源码如下
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

```java
public class FutureAndCallableTest {
    
    public static void main(String[] args) {
        ExecutorService executorService = Executors.newSingleThreadExecutor();

        System.out.println(Thread.currentThread().getName() + "主线程开始执行");
        Future<String> stringFuture = executorService.submit(new Callable<String>() {
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

## FutureTask

通过查看源码，可以发现FutureTask实现了RunnableFuture接口，而RunnableFuture又继承了Runnable, Future两个接口。

```java
public interface RunnableFuture<V> extends Runnable, Future<V> {
    /**
     * Sets this Future to the result of its computation
     * unless it has been cancelled.
     */
    void run();
}
```

所以就可以解释为什么ExecutorService会返回Future了，因为它既可以作为Runnable被线程执行，又可以作为Future得到Callable的返回值。

## Future不足

以上是单个Future的使用，但在开发过程中，我们可能会有以下需求

- 将两个异步计算合并为一个（这两个异步计算之间相互独立，同时第二个又依赖于第一个的结果）
- 等待Future集合中的所有任务都完成
- 仅等待Future集合中最快结束的任务完成，并返回它的结果
- ...

那么单使用Future是不够的，Future很难直接表述多个Future结果之间的依赖性，没有提供方法去判断第一个完成的任务；同时Future也没有提供Callback机制，只能通过阻塞的get方法去获取结果。

所以java8引入了**CompletableFuture**

# 四、CompletableFuture

CompletableFuture实现了Future接口，另外还实现了CompletionStage接口(它里面的方法表示的是是在某个运行阶段得到了结果之后要做的事情)

CompletableFuture的命名规则：

- xxx()：表示该方法将继续在已有的线程中执行；
- xxxAsync()：表示将异步在线程池中执行
- xxxApplyxxx(): 表示变换结果
- xxxAcceptxxx(): 表示消费结果

## create-创建CompletableFuture任务

```
//如果没有指定，默认会在ForkJoinPool.commonPool()中执行
public static CompletableFuture<Void> runAsync(Runnable runnable);
public static CompletableFuture<Void> runAsync(Runnable runnable, Executor executor);
public static <U> CompletableFuture<U> supplyAsync(Supplier<U> supplier);
public static <U> CompletableFuture<U> supplyAsync(Supplier<U> supplier, Executor executor);
```

> 示例

```java
class CompletableFutureTest {
    
    void testCreateFuture() {
      ExecutorService executor = Executors.newCachedThreadPool();
      CompletableFuture<Void> runAsyncFuture = CompletableFuture
              .runAsync(() -> System.out.println("hello world from runAsync!"),
                      executor);

      //supplyAsync的使用
      CompletableFuture<String> supplyAsyncFuture = CompletableFuture
              .supplyAsync(() -> "hello world from supplyAsync",
                      executor);

      //阻塞等待，runAsync的future无返回值
      runAsyncFuture.join();

      String supplyAsyncResult = supplyAsyncFuture.join();
      System.out.println("supplyAsyncResult: " + supplyAsyncResult);

      executor.shutdown();
    }
    
}

```

> CompletableFuture默认运行使用的是ForkJoin的的线程池，这个线程池默认线程数是CPU的核数，所以强烈建议使用后两个方法，根据任务类型不同，主动创建线程池，进行资源隔离，避免互相干
扰

> >! 在线程操作中，可以使用 join() 方法让一个线程强制运行，线程强制运行期间，其他线程无法运行，必须等待此线程完成之后才可以继续执行，join在遇到底层的异常时，会抛出未受查的CompletionException，get在遇到底层异常时，会抛出受查异常ExecutionException


## 串行执行线程

**任务完成则执行**

### thenRunXXX: 不关心上一个任务的结果，无返回值

```
public CompletableFuture<Void> thenRun(Runnable action)
public CompletableFuture<Void> thenRunAsync(Runnable action)
public CompletableFuture<Void> thenRunAsync(Runnable action, Executor executor)
```

> 示例

```java
class CompletableFutureTest { 
   void testThenRun(){
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
      //这里仅仅为测试方便让主线程不要立刻结束，否则CompletableFuture默认使用的线程池会立刻关闭。实际开发不能这么写
      while (true){}
  }
}

```

### thenAcceptXXX: 消费结果，无返回值

```
//这些方法只是针对结果进行消费，入参是Consumer，没有返回值
public CompletableFuture<Void> thenAccept(Consumer<? super T> action)
public CompletableFuture<Void> thenAcceptAsync(Consumer<? super T> action)
public CompletableFuture<Void> thenAcceptAsync(Consumer<? super T> action, Executor executor)
```

> 示例

```java
class CompletableFutureTest {
  public void testThenAccept(){
      //返回值在回调中
      CompletableFuture.supplyAsync(() -> "hello").thenAccept(s -> System.out.println(s+" world"));
  }
}
```

### thenApplyXXX: 变换结果，有返回值

```
//这些方法的输入是上一个阶段计算后的结果，返回值是经过变换后的结果
public <U> CompletableFuture<U> thenApply(Function<? super T,? extends U> fn)
public <U> CompletableFuture<U> thenApplyAsync(Function<? super T,? extends U> fn)        
public <U> CompletableFuture<U> thenApplyAsync(Function<? super T,? extends U> fn, Executor executor)
```

> 示例

```java
class CompletableFutureTest {
    
  void testThenApply() {
    String result = CompletableFuture.supplyAsync(() -> "hello").thenApply(s -> s + " world").join();
    //同样可以使用get进行阻塞获取值，返回值需自己获取
    System.out.println(result);
  }
  
}

```

> thenApply 只可以执行正常的任务，任务出现异常则会不执行 thenApply 方法

### thenComposeXXX: 将结果作为参数传递给下一个操作，有返回值

第一个操作完成时，将其结果作为参数传递给第二个操作

```
public <U> CompletableFuture<U> thenCompose(Function<? super T, ? extends CompletionStage<U>> fn) 
public <U> CompletableFuture<U> thenComposeAsync(Function<? super T, ? extends CompletionStage<U>> fn)
public <U> CompletableFuture<U> thenComposeAsync(Function<? super T, ? extends CompletionStage<U>> fn, Executor executor)     
```

> thenCompose的返回值是CompletionStage，可以和其他CompletableFuture任务更好地配套组合使用

> 示例

```java
class CompletableFutureTest {
  public void testThenCompose() throws Exception {
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
}
```


## 线程并行执行

**两个CompletableFuture[并行]执行完，然后执行**

### runAfterBothXXX: 不依赖上两个任务的结果，无返回值

```
public CompletableFuture<Void> runAfterBoth(CompletionStage<?> other, Runnable action)
public CompletableFuture<Void> runAfterBothAsync(CompletionStage<?> other, Runnable action)
public CompletableFuture<Void> runAfterBothAsync(CompletionStage<?> other, Runnable action, Executor executor)
```

两个CompletionStage都运行完后执行

> 示例

```java
class CompletableFutureTest {
   void testRunAfterBoth() {
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
    while (true) {
    }
  }
}
```

### thenAcceptBothXXX: 依赖上两个任务的结果，无返回值

```
public <U> CompletableFuture<Void> thenAcceptBoth(CompletionStage<? extends U> other, BiConsumer<? super T, ? super U> action)  
public <U> CompletableFuture<Void> thenAcceptBothAsync(CompletionStage<? extends U> other, BiConsumer<? super T, ? super U> action)              
public <U> CompletableFuture<Void> thenAcceptBothAsync(CompletionStage<? extends U> other, BiConsumer<? super T, ? super U> action, Executor executor) 
```

### thenCombineXXX: 依赖上两个任务的结果，有返回值

结合两个CompletionStage的结果，进行转化后返回

```
//需要上一阶段的返回值，并且other代表的CompletionStage也要返回值之后，把这两个返回值，进行转换后返回指定类型的值
public <U,V> CompletableFuture<V> thenCombine(CompletionStage<? extends U> other, BiFunction<? super T,? super U,? extends V> fn)
public <U,V> CompletableFuture<V> thenCombineAsync(CompletionStage<? extends U> other, BiFunction<? super T,? super U,? extends V> fn)       
public <U,V> CompletableFuture<V> thenCombineAsync(CompletionStage<? extends U> other, BiFunction<? super T,? super U,? extends V> fn, Executor executor) 
```

> 示例

```java
class CompletableFutureTest { 
    void testThenCombine() {
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
}

```

---

**线程并行执行，谁先执行完则谁触发下一个任务**

### runAfterEitherXXX: 不依赖前一任务的结果，无返回值

```
public CompletableFuture<Void> runAfterEither(CompletionStage<?> other, Runnable action)   
public CompletableFuture<Void> runAfterEitherAsync(CompletionStage<?> other, Runnable action)
public CompletableFuture<Void> runAfterEitherAsync(CompletionStage<?> other, Runnable action, Executor executor)
```

### acceptEitherXXX: 依赖最先完成任务的结果，无返回值

两个CompletionStage，谁计算的快，就用那个CompletionStage的结果进行下一步的**消费**操作

```
public CompletableFuture<Void> acceptEither(CompletionStage<? extends T> other, Consumer<? super T> action)
public CompletableFuture<Void> acceptEitherAsync(CompletionStage<? extends T> other, Consumer<? super T> action, Executor executor)       
public CompletableFuture<Void> acceptEitherAsync(CompletionStage<? extends T> other, Consumer<? super T> action, Executor executor)    
```

> 示例

```java
class Test {
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
}
```

### applyToEitherXXX: 依赖最先完成任务的结果，有返回值

两个CompletionStage，谁计算的快，就用那个CompletionStage的结果进行下一步的转化操作(**需要注意的是，两个CompletionStage都会执行完**)

```
//两种渠道完成同一个事情，就可以调用这个方法，找一个最快的结果进行处理返回
public <U> CompletableFuture<U> applyToEither(CompletionStage<? extends T> other, Function<? super T, U> fn) 
public <U> CompletableFuture<U> applyToEitherAsync(CompletionStage<? extends T> other, Function<? super T, U> fn)         
public <U> CompletableFuture<U> applyToEitherAsync(CompletionStage<? extends T> other, Function<? super T, U> fn, Executor executor)  
```

> 示例

```java
class CompletableFutureTest { 
  public void testApplyToEither() {
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
}

```


## 处理任务结果或者异常

### exceptionally: 处理异常

运行时出现了异常，通过exceptionally进行补偿

```
public CompletionStage<T> exceptionally(Function<Throwable, ? extends T> fn);
```

> 示例

```java
class CompletableFutureTest {
  public void testExceptionally() {
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
}
```

### handleXXX: 任务完成或者异常时运行fn，返回值为fn的返回值

运行完成时，对结果的处理

```
public <U> CompletableFuture<U> handle(BiFunction<? super T, Throwable, ? extends U> fn) 
public <U> CompletableFuture<U> handleAsync(BiFunction<? super T, Throwable, ? extends U> fn) 
public <U> CompletableFuture<U> handleAsync(BiFunction<? super T, Throwable, ? extends U> fn, Executor executor)    
```

handle 方法和 thenApply 方法处理方式基本一样。不同的是 **handle 是在任务完成后再执行，还可以处理异常的任务**。thenApply 只可以执行正常的任务，任务出现异常则不执行 thenApply 方法。

> 示例

```java
class Test {
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
}
```

### whenCompleteXXX: 任务完成或者异常时运行action，有返回值

当运行完成时，对结果的记录

```
//这里为什么要说成记录，因为这几个方法都会返回CompletableFuture，当Action执行完毕后它的结果返回原始的CompletableFuture的计算结果或者返回异常。所以不会对结果产生任何的作用
public CompletableFuture<T> whenComplete(BiConsumer<? super T, ? super Throwable> action) 
public CompletableFuture<T> whenCompleteAsync(BiConsumer<? super T, ? super Throwable> action) 
public CompletableFuture<T> whenCompleteAsync(BiConsumer<? super T, ? super Throwable> action, Executor executor)  
```

- whenComplete与handle的区别在于，它不参与返回结果的处理，把它当成监听器即可
- 即使异常被处理，在CompletableFuture外层，异常也会再次复现
- 使用whenCompleteAsync时，返回结果则需要考虑多线程操作问题，毕竟会出现两个线程同时操作一个结果


> 示例

```java
class CompletableFutureTest {
  public void testWhenComplete() {
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
      if (t != null) {
        System.out.println("whenComplete>>throwable" + t.getMessage());
      }
    }).exceptionally(e -> {
      System.out.println("exceptionally>>throwable: " + e.getMessage());
      return "hello world from exceptionally";
    }).join();
    System.out.println("result: " + result);
  }
}
```

## 多个任务的简单组合

### allOf: 所有任务都执行完成后

```
public static CompletableFuture<Void> allOf(CompletableFuture<?>... cfs)
```

> 示例

```java
class CompletableFutureTest {
    void testAllOf() {
      CompletableFuture<Void> future =  CompletableFuture.allOf(future1,future2,future3);
      try {
        System.out.println(future.get()); //return null
      } catch (InterruptedException | ExecutionException e) {
        e.printStackTrace();
      } 
    }
}
```

可以看到使用allOf的话，默认是没有返回值的。当需要获取返回值做一些处理时，可以利用java8的Stream来组合多个future的结果：

```java
class CompletableFutureTest {
    void testAllOf1() {
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
    }
}
```

### anyOf: 任意任务执行完成后

多个CompletableFuture谁计算的快，就用那个CompletionStage的结果进行下一步的**消费**操作。

anyOf是CompletableFuture静态方法，和 acceptEither、applyToEither的区别在于，后两者只能使用在两个future中，而anyOf可以使用在多个future中

```
public static CompletableFuture<Object> anyOf(CompletableFuture<?>... cfs)
```

> 示例

```java
class CompletableFutureTest {
  public void testAnyOf() {

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

    CompletableFuture<Object> future = CompletableFuture.anyOf(future1, future2, future3);
    try {
      System.out.println(future.get());
    } catch (InterruptedException | ExecutionException e) {
      e.printStackTrace();
    }
  }
}
```


## 取消执行线程任务

```
// 如果任务未完成,则返回异常
public boolean cancel(boolean mayInterruptIfRunning) 
//任务是否取消
public boolean isCancelled()
```

> 示例

```java
class CompletableFutureTest {
  public void testCancel() {
    CompletableFuture<Integer> future = CompletableFuture
            .supplyAsync(() -> {
              try { Thread.sleep(1000);  } catch (Exception e) { }
              return "hello world";
            })
            .thenApply(data -> 1);

    System.out.println("任务取消前:" + future.isCancelled());
    // 如果任务未完成,则返回异常,需要对使用exceptionally，handle 对结果处理
    future.cancel(true);
    System.out.println("任务取消后:" + future.isCancelled());
    future = future.exceptionally(e -> {
      e.printStackTrace();
      return 0;
    });
    System.out.println(future.join());
  }
}

//输出结果
//任务取消前:false
//任务取消后:true
//java.util.concurrent.CancellationException
//at java.util.concurrent.CompletableFuture.cancel(CompletableFuture.java:2276)
//0
```

## 任务的获取和完成与否判断

```
// 任务是否执行完成
public boolean isDone()
//阻塞等待 获取返回值
public T join()
// 阻塞等待 获取返回值,区别是get需要返回受检异常
public T get()
//等待阻塞一段时间，并获取返回值
public T get(long timeout, TimeUnit unit)
//未完成则返回指定value
public T getNow(T valueIfAbsent)
//未完成，使用value作为任务执行的结果，任务结束。需要future.get获取
public boolean complete(T value)
//未完成，则是异常调用,返回异常结果，任务结束
public boolean completeExceptionally(Throwable ex)
//判断任务是否因发生异常结束的
public boolean isCompletedExceptionally()
//强制地将返回值设置为value，无论该之前任务是否完成；类似complete
public void obtrudeValue(T value)
//强制地让异常抛出，异常返回，无论该之前任务是否完成；类似completeExceptionally
public void obtrudeException(Throwable ex) 
```


### completedFuture()

将常量值作为CompletableFuture返回

```
public static <U> CompletableFuture<U> completedFuture(U value)
```

示例

```java
public class CompletableFutureTest {
    
    void completedFutureTest() {
      ExecutorService executorService = Executors.newFixedThreadPool(2);
      CompletableFuture<String> completableFuture = CompletableFuture
              .supplyAsync(() -> "hello", executorService)
              .thenComposeAsync(data -> {
                //thenCompose - 依赖上一个任务的结果
                System.out.println("上一个结果: " + data);
                return CompletableFuture.completedFuture("last");
              }, executorService);

      System.out.println(completableFuture.join());
    }
}

//输出结果
//上一个结果: hello
//        last
```

以上是CompletableFuture的常用方法，另外由于方法都是返回CompletableFuture，故可以通过各种排列组合，完成日常工作中的复杂逻辑。如获取商品的信息时，需要调用多个服务来处理这一个请求并返回结果等

## Java9新增

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

## 生产建议

事实上，如果每个操作都很简单的话没有必要用这种多线程异步的方式，因为创建线程还需要时间，还不如直接同步执行来得快。

事实证明，只有当每个操作很复杂需要花费相对很长的时间（比如，调用多个其它的系统的接口；比如，商品详情页面这种需要从多个系统中查数据显示的）的时候用CompletableFuture才合适，不然区别真的不大，还不如顺序同步执行。

### 自定义线程池

在生产环境下，不建议直接使用上述示例代码形式。因为示例代码中使用的

```
CompletableFuture.supplyAsync(() -> {});
```

结合源码来看一下：

```java
public class CompletableFuture<T> implements Future<T>, CompletionStage<T> { 
    private static final boolean USE_COMMON_POOL =
        (ForkJoinPool.getCommonPoolParallelism() > 1);

    /**
     * Default executor -- ForkJoinPool.commonPool() unless it cannot
     * support parallelism.
     */
    private static final Executor ASYNC_POOL = USE_COMMON_POOL ?
        ForkJoinPool.commonPool() : new ThreadPerTaskExecutor();

    /** Fallback if ForkJoinPool.commonPool() cannot support parallelism **/
    static final class ThreadPerTaskExecutor implements Executor {
        public void execute(Runnable r) { new Thread(r).start(); }
    }

}
//多核情况下，默认使用ForkJoinPool.commonPool()
```

> 需要说明的是parallelStream和CompletableFuture默认使用的都是 ForkJoinPool.commonPool() 默认线程池；

基于服务器内核的限制，如果你是八核，每次线程只能起八个;适用于对list密集计算操作充分利用CPU资源，如果需要调用远端服务不建议使用

如果所有 CompletableFuture 都使用默认[ForkJoinPool.commonPool()](/20200728/java/多线程/a490755) 线程池，一旦有任务执行很慢的 I/O 操作，就会导致所有线
程都阻塞在 I/O 操作上，进而影响系统整体性能。
所以，建议大家在生产环境使用时，根据不同的业务类型创建不同的线程池，以避免互相影响。

# 五、延伸

可以看到CompletableFuture的写法与特性跟RxJava很像，但应用场景还是有些区别的：

composable | lazy | resuable | async | cached | push | back | pressure
---|---|---|---|---|---|---|---
CompletableFuture | 支持 | 不支持 | 支持 | 支持 | 支持 | 支持 | 不支持
Stream | 支持 | 支持 | 不支持 | 不支持 | 不支持 | 不支持 | 不支持
Observable(RxJava1) | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持
Observable(RxJava2) | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 | 不支持
Flowable(RxJava2) | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持

有关rxjava和stream的用法，限于篇幅，后面进行介绍
