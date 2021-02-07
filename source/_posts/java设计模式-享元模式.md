---
title: java设计模式-享元模式
date: 2020-11-02 13:57:40
categories: [java, 设计模式]
tags: [java, 设计模式]
---

# 前言

享元模式(Flyweight): 主要目的是实现对象的共享，即共享池，当系统中对象多的时候可以减少内存的开销，通常与工厂模式一起使用。享元模式的设计思想是尽量复用已创建的对象，常用于工厂方法内部的优化。

如果一个对象实例一经创建就不可变，那么反复创建相同的实例就没有必要，直接向调用方返回一个共享的实例就行，这样即节省内存，又可以减少创建对象的过程，提高运行速度。

> 总是使用工厂方法而不是new操作符创建实例，可获得享元模式的好处。

在学习享元模式之前需要先了解一下 细粒度 和享元对象中的 内部状态、外部状态 这三个概念：

* 内部状态：不随环境改变而改变的状态，内部状态可以共享，例如人的性别，不管任何环境下都不会改变
* 外部状态：随着环境改变而改变的状态，不可以共享的状态，享元对象的外部状态通常由客户端保存，并在享元对象创建后，需要的时候传入享元对象内部，不同的外部状态是相互独立的。例如衣服和鞋子，人在不同的环境下会穿不同的衣服和鞋子，但是衣服和鞋子又是相互独立不受彼此影响的
* 细粒度：较小的对象，所包含的内部状态较小

java中的string字符的不变性其实就是享元模式的应用！

 <!-- more -->

通过查看Integer类的源码我们可以看到Integer会把[-128, 127]之间的数字直接返回共享池中的对象:

```
    //IntegerCache.low = -128
    //IntegerCache.high = 127
    public static Integer valueOf(int i) {
        if (i >= IntegerCache.low && i <= IntegerCache.high)
            return IntegerCache.cache[i + (-IntegerCache.low)];
        return new Integer(i);
    }

```

# 实现

## 示例一

```java
/**
 * 抽象享元角色
 * 父接口，以规定出所有具体享元角色需要实现的方法
 */
public interface Flyweight {

    void operation(String state);

}


/**
 * 具体享元角色
 * 实现抽象享元角色所规定出的接口
 */
public class ConcreteFlyweight implements Flyweight{

    private Character intrinsicState = null;

    public ConcreteFlyweight(Character state) {
        this.intrinsicState = state;
    }

    @Override
    public void operation(String state) {
        //内部状态不变
        System.out.println(this.toString() + "intrinsicState is : " + intrinsicState);
        //外部状态实时变化
        System.out.println(this.toString() + "extrinsicState is : " + state);
    }
}

/**
 * 享元工厂
 * 本角色负责创建和管理享元角色。本角色必须保证享元对象可以被系统适当地共享。
 * 当一个客户端对象调用一个享元对象的时候，享元工厂角色会检查系统中是否已经有一个符合要求的享元对象。
 * - 如果已经有了，享元工厂角色就应当提供这个已有的享元对象；
 * - 如果系统中没有一个适当的享元对象的话，享元工厂角色就应当创建一个合适的享元对象。
 */
public class FlyweightFactory {

    private static final FlyweightFactory factory = new FlyweightFactory();

    public static FlyweightFactory getInstance() {
        return factory;
    }

    private FlyweightFactory() {}

    private Map<Character, Flyweight> cache = new HashMap<>();

    public Flyweight factory(Character character) {
        Flyweight flyweight = cache.get(character);
        if(flyweight == null) {
            flyweight = new ConcreteFlyweight(character);
            cache.put(character, flyweight);
        }
        return flyweight;
    }

}



/**
 * 享元模式测试类
 */
public class FlyweightTest {

    public static void main(String[] args) {
        Flyweight fly = FlyweightFactory.getInstance().factory('a');
        fly.operation("First Call");

        fly = FlyweightFactory.getInstance().factory('b');
        fly.operation("Second Call");

        fly = FlyweightFactory.getInstance().factory('a');
        fly.operation("Third Call");
    }

}

//输出
com.jonesun.tool.pattern.flyweight.ConcreteFlyweight@78e03bb5intrinsicState is : a
com.jonesun.tool.pattern.flyweight.ConcreteFlyweight@78e03bb5extrinsicState is : First Call
com.jonesun.tool.pattern.flyweight.ConcreteFlyweight@6ae40994intrinsicState is : b
com.jonesun.tool.pattern.flyweight.ConcreteFlyweight@6ae40994extrinsicState is : Second Call
com.jonesun.tool.pattern.flyweight.ConcreteFlyweight@78e03bb5intrinsicState is : a
com.jonesun.tool.pattern.flyweight.ConcreteFlyweight@78e03bb5extrinsicState is : Third Call
```

> 虽然客户端申请了三个享元对象，但是实际创建的享元对象只有两个，这就是共享的含义


## 示例二

我们再看一个具体一点的例子

```java
/**
 * 图书-相当于Flyweight
 */
public interface Book {

    void borrowBy(String studentName);

    void backFrom(String studentName);
}

/**
 * 具体实现的图书-相当于ConcreteFlyweight
 */
public class ConcreteBook implements Book {

    private String bookName;

    public ConcreteBook(String bookName) {
        this.bookName = bookName;
    }


    @Override
    public void borrowBy(String studentName) {
        System.out.println(studentName + "借了: " + bookName);
    }

    @Override
    public void backFrom(String studentName) {
        System.out.println(studentName + "归还了: " + bookName);
    }
}

/**
 * 图书馆-相当于FlyweightFactory
 */
public class BookLibrary {

    private Map<String, Book> bookMap = new HashMap<>();

    private static final BookLibrary instance = new BookLibrary();

    public static BookLibrary getInstance() {
        return instance;
    }

    private BookLibrary() {}

    public Book getBook(String bookName) {
        if(bookMap.containsKey(bookName)) {
            return bookMap.get(bookName);
        }
        Book book = new ConcreteBook(bookName);
        bookMap.put(bookName, book);
        return book;
    }

    public int bookSize() {
        return bookMap.size();
    }

}


public class BookLibraryTest {

    public static void main(String[] args) {
        Book book1 = BookLibrary.getInstance().getBook("图书1");
        book1.borrowBy("张三");
        Book book2 = BookLibrary.getInstance().getBook("图书2");

        book2.borrowBy("张三");
        Book book3 = BookLibrary.getInstance().getBook("图书3");
        book3.borrowBy("张三");

        //一段时间后张三还完书，李四过来借阅
        book1.backFrom("张三");
        book2.backFrom("张三");
        book3.backFrom("张三");

        Book book4 = BookLibrary.getInstance().getBook("图书1");
        book4.borrowBy("李四");
        Book book5 = BookLibrary.getInstance().getBook("图书2");
        book5.borrowBy("李四");

        System.out.println("总共借出: " + BookLibrary.getInstance().bookSize() + "本图书");
    }

}

//输出
张三借了: 图书1
张三借了: 图书2
张三借了: 图书3
张三归还了: 图书1
张三归还了: 图书2
张三归还了: 图书3
李四借了: 图书1
李四借了: 图书2
总共借出: 3本图书
```

> 在使用的时候只需要记住享元模式的核心思想，然后根据自己的业务需求来选择，因为大多情况下都不会使用一种设计模式，而是**多种设计模式的组合**。
