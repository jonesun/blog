---
title: java设计模式-适配器模式
categories:
  - java
  - designPatterns
tags:
  - java
  - designPatterns
abbrlink: e9e2ac5d
date: 2020-10-28 10:08:05
---

# 前言

> 将一个类的接口转换成客户希望的另外一个接口，使得原本由于接口不兼容而不能一起工作的那些类可以一起工作。

适配器模式是Adapter，也称Wrapper(所以如果看到源码中有以这两个结尾的类，那么大概率使用了适配器模式), java中实现适配器模式共有三种：

* 类适配器: 当希望将一个类转换成满足另一个新接口的类时，可以使用类的适配器模式，创建一个新类，继承原有的类，实现新的接口即可
* 对象适配器: 当希望将一个对象转换成满足另一个新接口的对象时，可以创建一个Wrapper类，持有原类的一个实例，在Wrapper类的方法中，调用实例的方法就行。使用组合替代继承，故相比较类适配器，**对象适配器更加常用**。
* 接口适配器: 当不希望实现一个接口中所有的方法时，可以创建一个抽象类Wrapper，实现所有方法，我们写别的类的时候，继承抽象类即可

 <!-- more -->

适配器是为了解决类兼容性问题的，实际上java标准库中也有很多地方使用了适配器模式，典型的线程池中为了能让Thread可以调用Callable接口使用了RunnableAdapter这个类：

```java
    private static final class RunnableAdapter<T> implements Callable<T> {
        private final Runnable task;
        private final T result;
        RunnableAdapter(Runnable task, T result) {
            this.task = task;
            this.result = result;
        }
        public T call() {
            task.run();
            return result;
        }
        public String toString() {
            return super.toString() + "[Wrapped task = " + task + "]";
        }
    }
```

# 实现

我们以给手机充电来举例说明适配器的用途


* 定义220V的电源

```java

/**
 * 中国的电源-220V
 */
public class PowerWith220V {

    public Integer discharge() {
        System.out.println("220V的电源正在放电...");
        return 220;
    }
}


```

* 定义充电器
  
```java
/**
 * 充电器
 */
public interface Charger {

    /**
     * 接入电源
     * @param powerWith220V
     * @return
     */
    Boolean connectPower(PowerWith220V powerWith220V);

}


/**
 * 实际充电器
 */
public class ChargerImpl implements Charger {

    private PowerWith220V powerWith220V;

    @Override
    public Boolean connectPower(PowerWith220V powerWith220V) {
        this.powerWith220V = powerWith220V;
        System.out.println("充电器接入电源成功");
        return Boolean.TRUE;
    }

}

```
* 定义手机

```java
/**
 * 手机
 */
public class Phone {

    private String name;

    public Phone(String name) {
        this.name = name;
    }

    public void charge(Charger charger) {
        Integer outVoltage = charger.discharge();
        System.out.println(name + "正在充电...");
    }

}
```

* 模拟下手机充电
```java
public class Test {
    public static void main(String[] args) {
        //定义一个手机
        Phone phone = new Phone("vivo");

        //定义一个220v电源
        PowerWith220V powerWith220V = new PowerWith220V();

        //定义一个充电器
        Charger charger = new ChargerImpl();
        //充电器接入电源
        charger.connectPower(powerWith220V);

        //手机充电
        phone.charge(charger);
    }
}


```

以上没有问题，但突然某一天手机的使用者来到了美国，而美国的电源都是110V的，如果是以上设计，明显就无法满足需求了

所以为了能成功给手机充电，我们就需要一个**适配器**：

* 先定义一个110V的电源

```java
public class PowerWith110V {
    
    public Integer discharge() {
        System.out.println("110V的电源正在放电...");
        return 110;
    }

}

```
* 定义适配器

```java
/**
 * 新充电器
 */
public interface NewCharger extends Charger {

    /**
     * 接入电源
     * @param powerWith110V
     * @return
     */
    Boolean connectPower(PowerWith110V powerWith110V);

}

/**
 * 充电适配器
 */
public class ChargerAdapter implements NewCharger {

    private Charger charger;

    private PowerWith110V powerWith110V;

    public ChargerAdapter(Charger charger) {
        this.charger = charger;
    }

    @Override
    public Boolean connectPower(PowerWith110V powerWith110V) {
        this.powerWith110V = powerWith110V;
        System.out.println("充电器接入110V电源成功");
        return Boolean.TRUE;
    }

    @Override
    public Boolean connectPower(PowerWith220V powerWith220V) {
        return charger.connectPower(powerWith220V);
    }

}

```

* 继续充电

```java
public class Test {
    public static void main(String[] args) {
        //定义一个手机
        Phone phone = new Phone("vivo");

        //定义一个220v电源
        PowerWith220V powerWith220V = new PowerWith220V();

        //定义一个充电器
        Charger charger = new ChargerImpl();
        //接入220V电源
        charger.connectPower(powerWith220V);

        //手机充电
        phone.charge(charger);

        //定义一个110V的电源
        PowerWith110V powerWith110V = new PowerWith110V();

        //定义适配器
        NewCharger newCharger = new ChargerAdapter(charger);
        //接入110V电源
        newCharger.connectPower(powerWith110V);

        //手机充电
        phone.charge(newCharger);

        //同样可以接入220V电源
        newCharger.connectPower(powerWith220V);

        phone.charge(newCharger);
    }
}

```

其实这个示例中可以理解为: 

为了能将电源的电提供给手机，使用了适配器-创建一个充电器(转换电源)

为了能兼容220V和110V的电源，使用了适配器-创建了一个充电适配器(转换不同电源)

> 市面上常用的各种转接头如果用代码实现的话，也可以认为是适配器模式