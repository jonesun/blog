---
title: java设计模式-单例模式
date: 2020-11-05 17:02:48
categories: [java, 设计模式] 
tags: [java, 设计模式]
---

# 前言

单例模式Singleton: 单例模式确保某一个类只有一个实例，而且自行实例化并向整个系统提供这个实例，这个类称为单例类，它提供全局访问的方法。

单例模式的要点有三个：
* 一是某个类只能有一个实例
* 二是它必须自行创建这个实例
* 三是它必须自行向整个系统提供这个实例

 <!-- more -->

# 实现

全局只有一个

```java
public class Singleton {
    // 静态字段引用唯一实例:
    private static final Singleton INSTANCE = new Singleton();

    // 通过静态方法返回实例:
    public static Singleton getInstance() {
        return INSTANCE;
    }

    // private构造方法保证外部无法实例化:
    private Singleton() {
    }
}

//或者
public class Singleton {
    // 静态字段引用唯一实例:
    public static final Singleton INSTANCE = new Singleton();

    // private构造方法保证外部无法实例化:
    private Singleton() {
    }
}
```

使用枚举实现

```java

public enum  EnumSingleton {

    //唯一枚举
    INSTANCE;

    public void hello()  {
        System.out.println("Hello World!");
    }

}

class Test {
    
    void test() {
        //使用
        EnumSingleton enumSingleton = EnumSingleton.INSTANCE;
        enumSingleton.hello();
    }
}

//编译器编译出的class大概就像这样
public final class EnumSingleton extends Enum { // 继承自Enum，标记为final class

    public static final EnumSingleton INSTANCE = new EnumSingleton();

    private EnumSingleton() {}

    public void hello()  {
        System.out.println("Hello World!");
    }

}
```

> 如果没有特殊的需求，使用Singleton模式的时候，最好不要延迟加载，这样会使代码更简单。延迟加载会遇到线程安全问题

非要实现的话最好借助内部类来实现

```
public class LazySingleton {

    private static class LazyHolder {
         private static LazySingleton INSTANCE = new LazySingleton();
    }

    public static LazySingleton getInstance() {
        return LazyHolder.INSTANCE;
    }

    private LazySingleton() {}

    public void hello()  {
        System.out.println("Hello World!");
    }
}
```

# Spring中使用

**Spring框架下使用@Component即可实现单例，不需要刻意去实现**，如果需要懒加载再加上@Lazy，即实现了Bean对象在第一次使用时才创建

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Component;

@Component
@Lazy
public class MySpringTestBean {

    private final Logger logger = LoggerFactory.getLogger(this.getClass());

    public MySpringTestBean() {
        logger.info("执行构造函数");
    }

    public void sayHello() {
        logger.info("hello world");
    }
}

//测试

```

测试类
```java
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;


@SpringBootTest
class MySpringTestBeanTest {

    @Autowired
    MySpringTestBean mySpringTestBean;

    @Test
    public void mySpringTestBeanTest() {
        mySpringTestBean.sayHello();
    }

}
```

常用注解的默认实例化方式:

* @Component默认单例
* @Bean默认单例
* @Repository默认单例
* @Service默认单例
* @Controller默认多例

> 如果想声明成多例对象可以使用@Scope(“prototype”)

另外如果需要保证每个线程中都只有一个的话，借助[ThreadLocal](/2020/08/24/java多线程10-ThreadLocal)：

```java
 public class ThreadSingleton {
    
    private static final ThreadLocal<ThreadSingleton> THREAD_LOCAL = ThreadLocal.withInitial(ThreadSingleton::new);
    
    public static ThreadSingleton getInstance() {
        ThreadSingleton threadSingleton = THREAD_LOCAL.get();
        if(threadSingleton == null) {
            threadSingleton = new ThreadSingleton();
            THREAD_LOCAL.set(threadSingleton);
        }
        return threadSingleton;
    }
    
    private ThreadSingleton() {}
    
}
```