---
title: java设计模式-工厂方法模式
date: 2020-10-27 10:42:56
categories: [java, 设计模式]
tags: [java, 设计模式]
---

# 前言

> 定义一个用于创建对象的接口，让子类决定实例化哪一个类。Factory Method使一个类的实例化延迟到其子类。

工厂方法(Factory Method)是指定义工厂接口和产品接口，但如何创建实际工厂和实际产品被推迟到子类实现，从而使调用方只和抽象工厂与抽象产品打交道, 目的是使得创建对象和使用对象是分离的，并且客户端总是引用抽象工厂和抽象产品

 <!-- more -->

# 实现

```
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

```
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

```
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

```
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

```
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

工厂方法模式有一个问题就是，类的创建依赖工厂类，也就是说，如果想要拓展程序，必须对工厂类进行修改，这违背了**闭包原则**，所以，从设计角度考虑，有一定的问题。

这个时候就要用到[抽象工厂模式](/2020/10/27/java设计模式-抽象工厂模式)，创建多个工厂类，这样一旦需要增加新的功能，直接增加新的工厂类就可以了，不需要修改之前的代码。

> 需要注意得是，如果不是特别复杂得工厂产品创建，一般静态工厂方法就够了，只有像多个供应商负责提供一系列类型的产品时才需要用到抽象工厂模式

> 见名思意，无论是自己编写还是看到别人代码中的类是以Factory结尾的都应联想到是否是使用了工厂方法模式
