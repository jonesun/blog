---
title: java设计模式-建造者模式
categories:
  - java
  - designPatterns
tags:
  - java
  - designPatterns
abbrlink: e2a6f58b
date: 2020-11-05 15:44:34
---

# 前言

建造者模式(Builder): 将一个复杂对象分解成多个相对简单的部分，然后根据不同需要分别创建它们，最后构建成该复杂对象

 <!-- more -->

# 实现

我们借助于Lombok的@Builder反编译出来的代码来看如何自己编写

```java
//原始
@Builder
public class User {
    private String username;
    private String password;
}


//反编译后
public class User {
    private String username;
    private String password;
    User(String username, String password) {
        this.username = username; this.password = password;
    }
    public static User.UserBuilder builder() {
        return new User.UserBuilder();
    }
 
    public static class UserBuilder {
        private String username;
        private String password;
        UserBuilder() {}
 
        public User.UserBuilder username(String username) {
            this.username = username;
            return this;
        }
        public User.UserBuilder password(String password) {
            this.password = password;
            return this;
        }
        public User build() {
            return new User(this.username, this.password);
        }
        public String toString() {
            return "User.UserBuilder(username=" + this.username + ", password=" + this.password + ")";
        }
    }
}


//使用
User user = User.builder().username("admin").password("123456").build();
```

> 使用构建器模式，可以比较优雅地解决构建复杂对象的麻烦，这里的“复杂”是指类似需要输入的参数组合较多，如果用构造函数，我们往往需要为每一种可能的输入参数组合实现相应的构造函数，一系列复杂的构造函数会让代码阅读性和可维护性变得很差。