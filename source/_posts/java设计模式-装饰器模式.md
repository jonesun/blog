---
title: java设计模式-装饰器模式
date: 2020-10-29 10:37:43
categories: [java, 设计模式]
tags: [java, 设计模式]
---

# 前言

> 装饰器模式(Decorator)，是一种在运行期动态给某个对象的实例增加功能的方法。

Decorator模式的目的就是把一个一个的附加功能，用Decorator的方式给一层一层地累加到原始数据源上，最终，通过组合获得我们想要的功能。

实际上Java标准库中对于IO流的处理就应用了装饰器模式: 通过FileInputStream获取原始文件流，如果需要增加缓冲功能就用BufferedInputStream包装下，如果还需要解压缩功能就再用GZIPInputStream包装下..., 无论包装多少次，得到的对象始终是InputStream。

使用Decorator模式**实际上把核心功能和附加功能给分开了**。核心功能指FileInputStream这些真正读数据的源头，附加功能指加缓冲、压缩、解密这些功能。

- 如果我们要新增核心功能，就增加Component的子类，例如ByteInputStream。
- 如果我们要增加附加功能，就增加Decorator的子类，例如CipherInputStream。

两部分都可以独立地扩展，而具体如何附加功能，由调用方自由组合，从而极大地增强了灵活性。


```
             ┌───────────┐
             │ Component │
             └───────────┘
                   ▲
      ┌────────────┼─────────────────┐
      │            │                 │
┌───────────┐┌───────────┐     ┌───────────┐
│ComponentA ││ComponentB │...  │ Decorator │
└───────────┘└───────────┘     └───────────┘
                                     ▲
                              ┌──────┴──────┐
                              │             │
                        ┌───────────┐ ┌───────────┐
                        │DecoratorA │ │DecoratorB │...
                        └───────────┘ └───────────┘
```
 <!-- more -->

 > 装饰模式在不改变原先核心功能的情况下，可以实现增强，并且不会产生很多继承类，按照业务模块划分，通过不同的方法进行装饰。

 # 实现

我们以给汽车加装饰来举例

* 定义一辆车

```
/**
 * 汽车
 */
public interface Car {

    void drive();
}

/**
 * 奥迪车
 */
public class AudiCar implements Car {
    @Override
    public void drive() {
        System.out.println("奥迪车启动");
    }
}

```

* 定义装饰器

```
/**
 * 汽车装饰器
 */
public class CarDecorator implements Car {

    private Car car;

    public CarDecorator(Car car) {
        this.car = car;
    }

    @Override
    public void drive() {
        car.drive();
    }
}

/**
 * 车灯装饰器
 */
public class CarLightDecorator extends CarDecorator {
    public CarLightDecorator(Car car) {
        super(car);
    }

    @Override
    public void drive() {
        System.out.println("改装一个大灯");
        super.drive();
    }
}

/**
 * 车贴装饰器
 */
public class CarStickerDecorator extends CarDecorator {

    public CarStickerDecorator(Car car) {
        super(car);
    }

    @Override
    public void drive() {
        System.out.println("贴上一个车贴");
        super.drive();
    }
}

```

* 测试验证

```
public class DecoratorTest {

    public static void main(String[] args) {
        Car car = new AudiCar();

        //改装大灯-带改装大灯的车
        car = new CarLightDecorator(car);

        //贴上车贴-带车贴的车
        car = new CarStickerDecorator(car);

        //启动
        car.drive();
    }

}

```

后面如果想要增加带新的装饰的车只要编写新类继承CarDecorator即可，想要增加新车则编写新类继承Car。互不影响

或者不想有车贴，直接去除CarStickerDecorator即可

> Spring中用到的包装器模式在类名上有两种表现：一种是类名中含有Wrapper，另一种是类名中含有Decorator
