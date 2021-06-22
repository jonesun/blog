---
title: java设计模式-抽象工厂模式
categories:
  - java
  - designPatterns
tags:
  - java
  - designPatterns
abbrlink: 5ee502d3
date: 2020-10-27 11:39:27
---

# 前言

抽象工厂模式(Abstract Factory)是为了让创建工厂和一组产品与使用相分离，并可以随时切换到另一个工厂以及另一组产品；

> 工厂方法模式通过引入工厂等级结构，解决了简单工厂模式中工厂类职责太重的问题，但由于工厂方法模式中的每个工厂只生产一类产品，可能会导致系统中存在大量的工厂类，势必会增加系统的开销。
> 此时，我们可以考虑将一些相关的产品组成一个"产品族"，由同一个工厂来统一生产，这就是抽象工厂模式的基本思想

抽象工厂模式实现的关键点是定义工厂接口和产品接口，但如何实现工厂与产品本身需要留给具体的子类实现，客户端只和抽象工厂与抽象产品打交道。

```
                                ┌────────┐
                             ─ >│ProductA│
┌────────┐    ┌─────────┐   │   └────────┘
│ Client │─ ─>│ Factory │─ ─
└────────┘    └─────────┘   │   ┌────────┐
                   ▲         ─ >│ProductB│
           ┌───────┴───────┐    └────────┘
           │               │
      ┌─────────┐     ┌─────────┐
      │Factory1 │     │Factory2 │
      └─────────┘     └─────────┘
           │   ┌─────────┐ │   ┌─────────┐
            ─ >│ProductA1│  ─ >│ProductA2│
           │   └─────────┘ │   └─────────┘
               ┌─────────┐     ┌─────────┐
           └ ─>│ProductB1│ └ ─>│ProductB2│
               └─────────┘     └─────────┘
```

> 这种模式有点类似于多个供应商负责提供一系列类型的产品

 <!-- more -->

# 实现

```java
/**
 * Html处理器
 */
public interface HtmlDocument {

    String toHtml();

    void save(Path path) throws IOException;
}


/**
 * Word处理器
 */
public interface WordDocument {

    void save(Path path) throws IOException;

}


/**
 * 抽象工厂
 */
public interface AbstractFactory {

    HtmlDocument createHtml(String md);

    WordDocument createWord(String md);
}


/**
 * Fast提供得Html处理器
 */
public class FastHtmlDocument implements HtmlDocument {

    private String md;

    public FastHtmlDocument(String md) {
        this.md = md;
    }

    @Override
    public String toHtml() {
        System.out.println("使用fast转换Html");
        return "<html>" + md + "</html>";
    }

    @Override
    public void save(Path path) throws IOException {
        md = toHtml();
        System.out.println("使用fast保存Html内容: " + md +  ">>到: " + path);
    }
}


/**
 * Fast提供得Word处理器
 */
public class FastWordDocument implements WordDocument {

    private String md;

    public FastWordDocument(String md) {
        this.md = md;
    }

    @Override
    public void save(Path path) throws IOException {
        System.out.println("使用fast保存Word内容: " + md + ">>到: " + path);
    }
}


/**
 * Fast提供得工厂类
 */
public class FastFactory implements AbstractFactory {
    @Override
    public HtmlDocument createHtml(String md) {
        return new FastHtmlDocument(md);
    }

    @Override
    public WordDocument createWord(String md) {
        return new FastWordDocument(md);
    }
}

/**
 * 测试类
 */
public class AbstractFactoryTest {

    public static void main(String[] args) throws IOException {
        AbstractFactory factory = new FastFactory();

        // 生成Html文档:
        HtmlDocument html = factory.createHtml("#Hello World");
        html.save(Paths.get(".", "fast.html"));

        // 生成Word文档:
        WordDocument word = factory.createWord("#Hello World");
        word.save(Paths.get(".", "fast.doc"));
    }

}

//当然也可以把创建工厂的方法写到抽象工厂类中(类似工厂方法模式的写法)

public interface AbstractFactory {
    public static AbstractFactory createFactory(String name) {
        if (name.equalsIgnoreCase("fast")) {
            return new FastFactory();
        } else if (name.equalsIgnoreCase("good")) {
            return new GoodFactory();
        } else {
            throw new IllegalArgumentException("Invalid factory name");
        }
    }
}
```

> Factory的创建可以使用单例模式，保证全局一个工厂

抽象工厂方法模式的好处就是，如果需要替换Fast库为Google库，只要分别实现各个产品定义类和抽象工厂即可，就OK了，无需去改动现成的代码。这样做，拓展性较好！

