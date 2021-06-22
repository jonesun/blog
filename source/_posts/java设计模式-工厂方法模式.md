---
title: java设计模式-工厂方法模式
categories:
  - java
  - designPatterns
tags:
  - java
  - designPatterns
abbrlink: 8dc1e828
date: 2020-10-27 10:42:56
---

# 前言

> 定义一个用于创建对象的接口，让子类决定实例化哪一个类。Factory Method使一个类的实例化延迟到其子类。

工厂方法(Factory Method)是指定义工厂接口和产品接口，但如何创建实际工厂和实际产品被推迟到子类实现，从而使调用方只和抽象工厂与抽象产品打交道, 目的是使得创建对象和使用对象是分离的，并且客户端总是引用抽象工厂和抽象产品

 <!-- more -->

# 实现

```java
/**
 * 产品
 *
 */
public interface Sender {

    void send(String s);

}

/**
 * 具体产品-邮件
 *
 */
public class EmailSender implements Sender {
    @Override
    public void send(String s) {
        System.out.println("通过邮件发送: " + s);
    }
}

/**
 * 具体产品-短信
 *
 */
public class SMSSender implements Sender {
    @Override
    public void send(String s) {
        System.out.println("通过短信发送: " + s);
    }
}


```

## 普通工厂模式

就是建立一个工厂类，对实现了同一接口的一些类进行实例的创建，根据传递参数绝对创建哪个产品。

```java
/**
 * 产品工厂
 *
 */
public class SenderFactory {

    public Sender product(String name) throws ClassNotFoundException {
        if("email".equalsIgnoreCase(name)) {
            return new EmailSender();
        } else if("SMS".equalsIgnoreCase(name)) {
            return new SMSSender();
        }
        throw new IllegalArgumentException("Invalid factory name: " + name);
    }
}

/**
 * 产品工厂测试类
 *
 */
public class ProductFactoryTest {

    public static void main(String[] args) {
        try {
            SenderFactory senderFactory = new SenderFactory();
            Sender sender = senderFactory.product("SMS");
            sender.send("Hello World!");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

}

```

## 多个工厂方法模式

对普通工厂模式进行升级，提供多个工厂方法，分别创建对象。

```java
/**
 * 产品工厂
 *
 */
public class SenderFactory {

    public Sender productSMS() {
        return new SMSProduct();
    }

    public Sender productEmail() {
        return new EmailProduct();
    }

}

/**
 * 产品工厂测试类
 *
 */
public class ProductFactoryTest {

    public static void main(String[] args) {
        SenderFactory senderFactory = new SenderFactory();
        Sender emailSender = senderFactory.productEmail();
        emailSender.send("Hello World!");

        Sender smsSender = senderFactory.productSMS();
        smsSender.send("Hello World!");
    }

}

```

## 静态工厂方法模式

多个工厂方法模式里的方法置为静态的，不需要创建实例，直接调用即可。

```java
/**
 * 产品工厂
 *
 */
public interface SenderFactory {

    static Sender productSMS() {
        return new SMSProduct();
    }

    static Sender productEmail() {
        return new EmailProduct();
    }

    /**
     * 有时候也可以这么实现
     * 好处在于只有一个工厂方法
     * 缺点就是如果传入的name有误，就不能正确创建对象
     * @param name
     * @return
     * @throws ClassNotFoundException
     */
    static Sender product(String name) throws ClassNotFoundException {
        if("email".equalsIgnoreCase(name)) {
            return new EmailSender();
        } else if("SMS".equalsIgnoreCase(name)) {
            return new SMSSender();
        }
        throw new IllegalArgumentException("Invalid factory name: " + name);
    }
}

/**
 * 产品工厂测试类
 *
 */
public class ProductFactoryTest {

    public static void main(String[] args) {
        Sender emailSender = SenderFactory.productEmail();
        emailSender.send("Hello World!");

        Sender smsSender = SenderFactory.productSMS();
        smsSender.send("Hello World!");

        try {
            Sender sender = SenderFactory.product("SMS");
            sender.send("Hello World!");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

}

```

工厂方法还有一个好处是可以隐藏创建产品的细节，且不一定每次都会真正创建产品，完全可以返回缓存的产品，从而提升速度并减少内存消耗: 

```java
public class LocalDateFactory {
    public static LocalDate fromInt(int yyyyMMdd) {
        //内部优化不是每次都创建对象
        return LocalDate.of(yyyyMMdd / 10000, yyyyMMdd / 100 % 100, yyyyMMdd % 100);
    }
}

public class LocalDateFactoryTest {

    public static void main(String[] args) {
        LocalDate localDate = LocalDateFactory.fromInt(20201002);
        System.out.println(localDate.format(DateTimeFormatter.ISO_LOCAL_DATE));
    }

}

```

大多数情况下选用**静态工厂方法模式**，实际上静态工厂方法广泛地应用在Java标准库中(如List.of()、Integer.valueOf())

# 注意点

**工厂方法模式是简单工厂模式的进一步抽象和推广**

在工厂方法模式中，核心的工厂类不再负责所有产品的创建，而是将具体创建工作交给子类去做。

这个核心类仅仅负责给出具体工厂必须实现的接口，而不负责产品类被实例化这种细节，这使得工厂方法模式可以允许系统在不修改工厂角色的情况下引进新产品。

**优点：**
- 一个调用者想创建一个对象，只要知道其名称就可以了。
- 扩展性高，如果想增加一个产品，只要扩展一个工厂类就可以。
- 屏蔽产品的具体实现，调用者只关心产品的接口。

**缺点：**
- 每次增加一个产品时，都需要增加一个具体类和对象实现工厂，使得系统中类的个数成倍增加，在一定程度上增加了系统的复杂度，同时也增加了系统具体类的依赖。这并不是什么好事。
- 类的创建依赖工厂类，也就是说，如果想要拓展程序，必须对工厂类进行修改，这违背了**闭包原则**，所以，从设计角度考虑，有一定的问题。

这个时候就要用到[抽象工厂模式](/20201027/java/设计模式/5ee502d3)，创建多个工厂类，这样一旦需要增加新的功能，直接增加新的工厂类就可以了，不需要修改之前的代码。

> 需要注意得是，如果不是特别复杂得工厂产品创建，一般静态工厂方法就够了，只有像多个供应商负责提供一系列类型的产品时才需要用到抽象工厂模式

> 见名思意，无论是自己编写还是看到别人代码中的类是以Factory结尾的都应联想到是否是使用了工厂模式


# Spring中使用

改写Sender的两个实现类，加上@Component：
```java
@Component("email")
public class EmailSender implements Sender {
    @Override
    public void send(String s) {
        System.out.println("通过邮件发送: " + s);
    }
}

@Component("SMS")
public class SMSSender implements Sender {
    @Override
    public void send(String s) {
        System.out.println("通过短信发送: " + s);
    }
}
```

工厂类实现

```java
@Component
public class SpringSenderFactory {

    @Autowired
    private Map<String , Sender> senderMap;

    public Sender getSenderByName(String name){
        return senderMap.get(name);
    }

}


@SpringBootTest
class SpringSenderFactoryTest {

    @Autowired
    private SpringSenderFactory senderFactory;

    @Test
    void getSenderByName() {
        senderFactory.getSenderByName("email").send("hello world");
        senderFactory.getSenderByName("SMS").send("hello world");
    }
}
```