---
title: java设计模式-模板方法模式
categories:
  - java
  - designPatterns
tags:
  - java
  - designPatterns
abbrlink: 295e2dfa
date: 2020-11-03 10:35:21
---

# 前言

模板方法(TemplateMethod): 它的主要思想是，定义一个操作的一系列步骤，对于某些暂时确定不下来的步骤，就留给子类去实现好了，这样不同的子类就可以定义出不同的步骤。

模板类定义一个操作中的算法的骨架，而将一些步骤延迟到子类中。使得子类可以不改变一个算法的结构即可重定义该算法的某些特定步骤。

模板方法的核心思想是：**父类定义骨架，子类实现某些细节**。模板方法是一种高层定义骨架，底层实现细节的设计模式，**适用于流程固定，但某些步骤不确定或可替换的情况**。

> 为了防止子类重写父类的骨架方法，可以**在父类中对骨架方法使用final**。对于需要子类实现的抽象方法，一般声明为protected，使得这些方法对外部客户端不可见。

Java标准库也有很多模板方法的应用。在集合类中，AbstractList和AbstractQueuedSynchronizer都定义了很多通用操作，子类只需要实现某些必要方法。

 <!-- more -->

 # 实现

 * 定义模板类

  因为声明了抽象方法，自然整个类也必须是抽象类。如何实现init()和startPlay()、endPlay()这三个方法就交给子类了。

 ```java
 /**
 * 游戏
 */
public abstract class Game {

    public final void pay() {
        System.out.println("准备中...");
        init();
        startPlay();
        endPlay();
        saveRecord();
    }

    protected abstract void init();

    protected abstract void startPlay();

    protected abstract void endPlay();

    /**
     * 保存进度
     */
    private void saveRecord() {
        System.out.println("进度已保存");
    }
}

 ```

 * 定义具体实现类
  
子类其实并不关心核心代码pay()的逻辑，甚至如何保存记录saveRecord()，它只需要关心如何完成三个子方法就可以了。

```java
/**
 * 足球游戏
 */
public class FootballGame extends Game {

    @Override
    protected void init() {
        System.out.println("足球游戏正在加载中...");
    }

    @Override
    protected void startPlay() {
        System.out.println("开始玩足球游戏");
    }

    @Override
    protected void endPlay() {
        System.out.println("结束足球游戏");
    }

}

```

* 测试验证
  
```java
/**
 * 测试类
 */
public class GameTest {

    public static void main(String[] args) {
        //玩足球游戏
        Game footballGame = new FootballGame();
        footballGame.pay();
    }

}

```

后面如果要增加新的游戏，再继承Game实现具体的玩法，然后更换游戏即可

项目中经常用到的从数据库中或者值，为了提高速度，先从缓存中获取，那么获取值的逻辑就可以认为是骨架方法，这个从缓存中获取的方法就可以抽象到子类中实现，由具体的子类来实现用哪个缓存