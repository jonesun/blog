---
title: java设计模式-备忘录模式
categories:
  - java
  - designPatterns
tags:
  - java
  - designPatterns
abbrlink: df30fde2
date: 2020-11-05 10:05:29
---

# 前言

备忘录模式(Memento): 在不破坏封装性的前提下，捕获一个对象的内部状态，并在该对象之外保存这个状态。

标准的备忘录模式有这么几种角色：

- Memonto：备忘录类，备份原始类中的信息
- Originator：原始类
- Caretaker：存储备忘录的类

> 备忘录模式是为了保存对象的内部状态，并在将来恢复，大多数软件提供的保存、打开，以及编辑过程中的Undo、Redo都是备忘录模式的应用。

 <!-- more -->

# 实现

* 定义备忘录类

```java
/**
 * 备忘录
 */
public class Memento {

    private String status;

    public Memento(String status) {
        this.status = status;
    }

    public String getStatus() {
        return status;
    }

}

```

* 定义原始类

```java
/**
 * 原始类
 */
public class Originator {

    private String status;

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Memento saveToMemento() {
        return new Memento(status);
    }

    public void restoreFromMemento(Memento memento) {
        status = memento.getStatus();
    }
}

```

* 定义存取备忘录的类

```java
/**
 * 存取者
 */
public class Caretaker {

    private final List<Memento> mementoList = new ArrayList<>();

    public void addMemento(Memento memento) {
        mementoList.add(memento);
    }

    /**
     * 获取上一步
     * @return
     */
    public Memento getPrev() {
        return mementoList.get(mementoList.size() - 2);
    }

    /**
     * 获取当前
     * @return
     */
    public Memento getCurrent() {
        return mementoList.get(mementoList.size() - 1);
    }

    /**
     * 所有历史
     * @return
     */
    public List<Memento> getHistory() {
        return mementoList;
    }

}


```

* 测试

```java
public class MementoTest {

    public static void main(String[] args) {
        //创建存储备忘录的类
        Caretaker caretaker = new Caretaker();

        //创建原始类
        Originator originator = new Originator();

        //设置并保存状态值
        originator.setStatus("status1");
        save(caretaker, originator);

        originator.setStatus("status2");
        save(caretaker, originator);

        originator.setStatus("status3");
        save(caretaker, originator);

        originator.setStatus("status4");
        save(caretaker, originator);

        System.out.println("当前状态: " + originator.getStatus());
        //撤销当前状态(返回上一步状态)
        originator.restoreFromMemento(caretaker.getPrev());
        save(caretaker, originator);
        System.out.println("撤销后，当前状态: " + originator.getStatus());

        //重新从备忘录中获取当前状态
        Originator originator1 = new Originator();
        originator1.setStatus(caretaker.getCurrent().getStatus());
        System.out.println("恢复后当前状态: " + originator1.getStatus());

        //获取操作历史
        System.out.println("===============操作历史=================");
        caretaker.getHistory().forEach(memento -> System.out.println("memento: " + memento.getStatus()));

    }

    private static void save(Caretaker caretaker, Originator originator) {
        //保存状态
        Memento memento1 = originator.saveToMemento();
        caretaker.addMemento(memento1);
    }

}


//输出
当前状态: status4
撤销后，当前状态: status3
恢复后当前状态: status3
===============操作历史=================
memento: status1
memento: status2
memento: status3
memento: status4
memento: status3
```

以上就实现了一个简单的备忘录，可以进行再一次封装，如加上每步的操作时间、地点、人物等, 或者指定恢复到某个进度

> 简单的对象，用一个String就可以表示其状态，对于复杂的对象模型，通常我们会使用JSON、XML等复杂格式