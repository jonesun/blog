---
title: java设计模式-桥接模式
date: 2020-10-30 11:02:49
categories: [java, 设计模式] 
tags: [java, 设计模式]
---

# 前言

> 桥接模式通过分离一个抽象接口和它的实现部分，使得设计可以按两个维度独立扩展

桥接模式(Bridge): 将抽象化与实现化解耦，使得二者可以独立变化。是为了避免直接继承带来的子类爆炸

像我们常用的JDBC桥DriverManager一样，JDBC进行连接数据库的时候，在各个数据库之间进行切换，基本不需要动太多的代码，甚至丝毫不用动，原因就是JDBC提供统一接口，每个数据库提供各自的实现，用一个叫做数据库驱动的程序来桥接就行了

 <!-- more -->

 # 实现

## 示例一

汽车由引擎与品牌组成，但引擎与品牌独立变化，在两个变化维度中任意扩展一个，都不需要修改原有系统

 ```java
/**
 * 引擎
 */
public interface Engine {

    void start();

}

/**
 * 混合发动机
 */
public class HybridEngine implements Engine{
    @Override
    public void start() {
        System.out.println("混合发动机启动......");
    }
}



 /**
 * 汽车
 */
public abstract class Car {

    private Engine engine;

    public Car(Engine engine) {
        this.engine = engine;
    }

    public abstract void drive();

    public Engine getEngine() {
        return engine;
    }
}

/**
 * 品牌汽车
 */
public abstract class BrandCar extends Car {

    public BrandCar(Engine engine) {
        super(engine);
    }

    @Override
    public void drive() {
        getEngine().start();
        System.out.println("正在驾驶： " + brand() + "汽车");
    }

    /**
     * 品牌名称
     * @return
     */
    public abstract String brand();
}

/**
 * 奔驰品牌汽车
 */
public class BenBrandCar extends BrandCar {
    public BenBrandCar(Engine engine) {
        super(engine);
    }

    @Override
    public String brand() {
        return "奔驰";
    }
}

public class BridgeTest {

    public static void main(String[] args) {
        BrandCar brandCar = new BenBrandCar(new HybridEngine());
        brandCar.drive();
    }

}
 ```

使用桥接模式的好处在于，如果要增加一种引擎，只需要针对Engine派生一个新的子类，如果要增加一个品牌车，只需要针对BrandCar派生一个子类，任何BrandCar的子类都可以和任何一种Engine自由组合，即一辆汽车的两个维度：品牌和引擎都可以独立地变化。

```
       ┌───────────┐
       │    Car    │
       └───────────┘
             ▲
             │
       ┌───────────┐       ┌─────────┐
       │BrandCar   │ ─ ─ ─>│ Engine  │
       └───────────┘       └─────────┘
             ▲                  ▲
    ┌────────┼────────┐         │ ┌──────────────┐
    │                 │         ├─│  FuelEngine  │
┌────────────┐    ┌───────────┐ │ └──────────────┘
│AudiBrandCar│    │BenBrandCar│ │ ┌──────────────┐
└────────────┘    └───────────┘ ├─│ElectricEngine│
                                │ └──────────────┘
                                │ ┌──────────────┐
                                └─│ HybridEngine │
                                  └──────────────┘
```

> 不要过度使用继承，而是优先拆分某些部件，使用组合的方式来扩展功能

## 示例二

画笔，可以画正方形、长方形、圆形......又可以对这些不同形状上不同颜色

```java
/**
 * 颜色
 */
public interface Color {

    void paint(String shape);

}

/**
 * 白色
 */
public class WhiteColor implements Color{
    @Override
    public void paint(String shape) {
        System.out.println("使用白色画: " + shape);
    }
}

/**
 * 蓝色
 */
public class BlueColor implements Color {
    @Override
    public void paint(String shape) {
        System.out.println("使用蓝色画: " + shape);
    }
}

/**
 * 形状
 */
public abstract class Shape {

    private Color color;

    public void setColor(Color color) {
        this.color = color;
    }

    public abstract void draw();

    public Color getColor() {
        return color;
    }
}

/**
 * 圆形
 */
public class CircleShape extends Shape {
    @Override
    public void draw() {
        getColor().paint("圆形");
    }
}

/**
 * 正方形
 */
public class SquareShape extends Shape{
    @Override
    public void draw() {
        getColor().paint("正方形");
    }
}

public class PaintBridgeTest {

    public static void main(String[] args) {
        //定义白色
        Color white = new WhiteColor();

        //定义圆形
        Shape circle = new CircleShape();

        //使用白色画圆形
        circle.setColor(white);
        circle.draw();

        //再定义蓝色
        Color blue = new BlueColor();

        //使用蓝色画圆形
        circle.setColor(blue);
        circle.draw();

        //定义正方形
        Shape square = new SquareShape();

        //使用蓝色画正方形
        square.setColor(blue);
        square.draw();

        //使用白色画正方形
        square.setColor(white);
        square.draw();
    }

}

```

以上形状类Shape就像一个桥接，可以组合任一形状和颜色进行绘画，同时可以分别拓展形状(继承Shape类)和颜色(实现Color接口)