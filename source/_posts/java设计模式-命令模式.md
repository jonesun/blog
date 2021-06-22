---
title: java设计模式-命令模式
categories:
  - java
  - designPatterns
tags:
  - java
  - designPatterns
abbrlink: c08d175c
date: 2020-11-03 16:41:17
---

# 前言

命令模式(Command): 把一个请求或者操作封装到一个对象中。命令模式允许系统使用不同的请求把客户端参数化，对请求排队或者记录请求日志，可以提供命令的撤销和恢复功能。

命令模式是对命令的封装。**命令模式把发出命令的责任和执行命令的责任分割开，委派给不同的对象。**

每一个命令都是一个操作：请求的一方发出请求要求执行一个操作；接收的一方收到请求，并执行操作。命令模式允许请求的一方和接收的一方独立开来，使得请求的一方不必知道接收请求的一方的接口，更不必知道请求是怎么被接收，以及操作是否被执行、何时被执行，以及是怎么被执行的。

命令允许请求的一方和接收请求的一方能够独立演化，从而具有以下的优点：

- 命令模式使新的命令很容易地被加入到系统里
- 允许接收请求的一方决定是否要否决请求
- 能较容易地设计一个命令队列
- 可以容易地实现对请求的撤销和恢复
- 在需要的情况下，可以较容易地将命令记入日志

命令模式涉及到五个角色，它们分别是：

- 客户端(Client)角色：创建一个具体命令(ConcreteCommand)对象并确定其接收者。
- 命令(Command)角色：声明了一个给所有具体命令类的抽象接口。
- 具体命令(ConcreteCommand)角色：定义一个接收者和行为之间的弱耦合；实现execute()方法，负责调用接收者的相应操作。execute()方法通常叫做执行方法。
- 请求者(Invoker)角色：负责调用命令对象执行请求，相关的方法叫做行动方法。
- 接收者(Receiver)角色：负责具体实施和执行一个请求。任何一个类都可以成为接收者，实施和执行请求的方法叫做行动方法。

 <!-- more -->

 命令模式的优点
- 更松散的耦合: 命令模式使得发起命令的对象——客户端，和具体实现命令的对象——接收者对象完全解耦，也就是说发起命令的对象完全不知道具体实现对象是谁，也不知道如何实现。
- 更动态的控制: 命令模式把请求封装起来，可以动态地对它进行参数化、队列化和日志化等操作，从而使得系统更灵活。
- 很自然的复合命令: 命令模式中的命令对象能够很容易地组合成复合命令，也就是宏命令，从而使系统操作更简单，功能更强大。
- 更好的扩展性: 由于发起命令的对象和具体的实现完全解耦，因此扩展新的命令就很容易，只需要实现新的命令对象，然后在装配的时候，把具体的实现对象设置到命令对象中，然后就可以使用这个命令对象，已有的实现完全不用变化。

 # 实现

* 定义接收者-及实际执行者Receiver
  
```java
/**
 * Receiver是被调用者（士兵）
 */
public class Receiver {

    public void action() {
        System.out.println("执行操作");
    }

    public void unAction() {
        System.out.println("撤销执行");
    }

}

```

* 定义命令Command

```java
/**
 * 命令
 */
public interface Command {

    void execute();

    void undo();

}

/**
 * 具体命令
 */
public class ConcreteCommand implements Command {

    private Receiver receiver;

    public ConcreteCommand(Receiver receiver) {
        this.receiver = receiver;
    }

    @Override
    public void execute() {
        receiver.action();
    }

    @Override
    public void undo() {
        receiver.unAction();
    }
}


```

* Invoker调用者（司令员）

```java
/**
 * 请求者-要求该命令执行这个请求
 */
public class Invoker {
    private final List<Command> commandList = new ArrayList<>();


    public Invoker(Command command) {
        commandList.add(command);
    }

    public void addCommand(Command command) {
        commandList.add(command);
    }

    public void action() {
        commandList.forEach(Command::execute);
    }

    // 撤销命令
    public void undo(Command command) {
        commandList.remove(command);
        command.undo();
    }
    
}
```

* 定义客户端

```java
public class Client {

    public static void main(String[] args) {
        //创建接收者
        Receiver receiver = new Receiver();

        //创建命令对象，设定它的接收者
        Command command1 = new ConcreteCommand(receiver);
        Command command2 = new ConcreteCommand(receiver);

        //创建请求者，把命令对象设置进去
        Invoker invoker = new Invoker(command1);
        invoker.addCommand(command2);

        //撤销某个命令
        invoker.undo(command1);
        
        //执行方法
        invoker.action();
    }

}

```