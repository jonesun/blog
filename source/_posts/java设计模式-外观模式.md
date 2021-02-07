---
title: java设计模式-外观模式
date: 2020-10-30 09:51:37
categories: [java, 设计模式]
tags: [java, 设计模式]
---

# 前言

外观模式(Facade)，又叫门面模式，是为了解决类与类之家的依赖关系的，给客户端提供一个统一入口，并对外屏蔽内部子系统的调用细节。像spring一样，可以将类和类之间的关系配置到配置文件中，而外观模式就是将他们的关系放在一个Facade类中，降低了类类之间的耦合度

很多Web程序，内部有多个子系统提供服务，经常使用一个统一的Facade入口，例如一个RestApiController，使得外部用户调用的时候，只关心Facade提供的接口，不用管内部到底是哪个子系统处理的。

 <!-- more -->

# 实现

```java
public class CPU {
    
    public void work(){
        System.out.println("cpu start work!");
    }

}

public class Disk {

    public void load(){
        System.out.println("disk start load!");
    }

}

public class Memory {

    public void connect(){
        System.out.println("memory start connect!");
    }

}


public class Computer {

    private CPU cpu;
    private Disk disk;
    private Memory memory;

    public Computer() {
        cpu = new CPU();
        disk = new Disk();
        memory = new Memory();
    }

    public void startup(){
        System.out.println("start the computer!");
        cpu.work();
        memory.connect();
        disk.load();
    }
}

public class FacadeTest {
    
    public static void main(String[] args) {
        Computer computer = new Computer();
        computer.startup();
    }

}

```

计算机内部零部件特别多，他们之间的关系被放在了Computer类里，这样就起到了解耦的作用，而用户使用计算机就只要和计算机这个类打交道，这就是外观模式的特点

> SLF4J使用的就是外观模式(门面)