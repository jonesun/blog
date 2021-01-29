---
title: java设计模式-状态模式 
date: 2020-11-05 11:12:01 
categories: [java, 设计模式]
tags: [java, 设计模式]
---

# 前言

状态模式(State): 当对象的状态改变时，同时改变其行为，设计思想是把不同状态的逻辑分离到不同的状态类中，从而使得增加新状态更容易；

状态模式的实现关键在于状态转换。**简单的状态转换可以直接由调用方指定，复杂的状态转换可以在内部根据条件触发完成。**

> 状态模式经常用在**带有状态的对象**中

 <!-- more -->

# 实现

* 定义几种状态

```
/**
 * 用户状态
 */
public enum  UserStatus {

    ONLINE, OFFLINE, BUSY

}

```

* 定义用户对象

```
/**
 * 用户
 */
public class User {

    private String name;

    private UserStatus userStatus;

    public User(String name) {
        this.name = name;
        //默认在线
        userStatus = UserStatus.ONLINE;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public UserStatus getUserStatus() {
        return userStatus;
    }

    public void setUserStatus(UserStatus userStatus) {
        this.userStatus = userStatus;
    }
}

```

* 定义不同状态时的处理

```
/**
 * 状态
 */
public interface State {

    /**
     * 初始化
     */
    void init();

    /**
     * 回复消息
     * @param message
     */
    Boolean reply(String message);

}


/**
 * 在线状态
 */
public class OnlineState implements State {

    @Override
    public void init() {
        System.out.println("我在线上");
    }

    @Override
    public Boolean reply(String message) {
        System.out.println("收到消息: " + message);
        return Boolean.TRUE;
    }
}


/**
 * 离线状态
 */
public class OfflineState implements State {
    @Override
    public void init() {
        System.out.println("我已下线");
    }

    @Override
    public Boolean reply(String message) {
        return null;
    }
}


/**
 * 忙碌状态
 */
public class BusyState implements State{
    @Override
    public void init() {
        System.out.println("我正忙");
    }

    @Override
    public Boolean reply(String message) {
        System.out.println("我正忙，稍后回复你的消息: " + message);
        return Boolean.FALSE;
    }
}

```

* 定义用于切换状态的上下文

```
/**
 * 状态切换上下文
 */
public class StateContext {

    public static State updateState(UserStatus userStatus) {
        //这个是Java14的写法，Java8的话老老实实写if/else吧
        State state = switch (userStatus) {
            case BUSY -> new BusyState();
            case ONLINE -> new OnlineState();
            case OFFLINE -> new OfflineState();
        };
        state.init();
        return state;
    }
}

```

* 测试

```
public class StateTest {

    public static void main(String[] args) {
        User user = new User("张三");

        State state = StateContext.updateState(user.getUserStatus());
        state.reply("你好");

        //切换到忙碌状态
        System.out.println("============================");
        user.setUserStatus(UserStatus.BUSY);
        state = StateContext.updateState(user.getUserStatus());
        state.reply("你好");

        //切换到离线状态
        System.out.println("============================");
        user.setUserStatus(UserStatus.OFFLINE);
        state = StateContext.updateState(user.getUserStatus());
        state.reply("你好");

    }

}

//输出
我在线上
收到消息: 你好
============================
我正忙
我正忙，稍后回复你的消息: 你好
============================
我已下线
```

所以状态模式的核心是定义一个上下文，根据传递对象的不同状态，切换不同处理(行为)，后续加入新的状态，再新增对应状态的处理逻辑(行为)即可

> 状态模式可以使用枚举定义value的方式,逐级加1以便进入下个状态

```java
public enum Step {
    DOUGH(4), ROLLED(1), SAUCED(1), CHEESED(2),
    TOPPED(5), BAKED(2), SLICED(1), BOXED(0);
    int effort;// Needed to get to the next step

    Step(int effort) {
        this.effort = effort;
    }

    Step forward() {
        if (equals(BOXED)) return BOXED;
        return values()[ordinal() + 1];
    }
}
```