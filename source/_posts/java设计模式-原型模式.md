---
title: java设计模式-原型模式
categories:
  - java
  - designPatterns
tags:
  - java
  - designPatterns
abbrlink: 2933c5b8
date: 2020-11-06 10:32:23
---

# 前言

原型模式(Prototype): 将一个对象作为原型，通过对其进行复制而克隆出多个和原型类似的新实例

 <!-- more -->

# 实现

## 浅复制

将一个对象复制后，基本数据类型的变量都会重新创建，而引用类型，指向的还是原对象所指向的。使用Java标准库提供的clone方法：

* 定义对象
```java
public class UserInfo {

    private int id;
    private String mobile;
    private Long score;

    public UserInfo(int id, String mobile, Long score) {
        this.id = id;
        this.mobile = mobile;
        this.score = score;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getMobile() {
        return mobile;
    }

    public void setMobile(String mobile) {
        this.mobile = mobile;
    }

    public Long getScore() {
        return score;
    }

    public void setScore(Long score) {
        this.score = score;
    }

    @Override
    public String toString() {
        return "UserInfo{" +
                "id=" + id +
                ", mobile='" + mobile + '\'' +
                ", score=" + score +
                '}';
    }
}


public class User implements Cloneable {

    private Integer id;
    private int age;
    private String name;
    private Boolean enable;

    private UserInfo userInfo;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Boolean getEnable() {
        return enable;
    }

    public void setEnable(Boolean enable) {
        this.enable = enable;
    }

    public UserInfo getUserInfo() {
        return userInfo;
    }

    public void setUserInfo(UserInfo userInfo) {
        this.userInfo = userInfo;
    }

    @Override
    public String toString() {
        return "User{" +
                "id=" + id +
                ", age=" + age +
                ", name='" + name + '\'' +
                ", enable=" + enable +
                ", userInfo=" + userInfo +
                '}';
    }

    @Override
    protected Object clone() throws CloneNotSupportedException {
        return super.clone();
    }
}

```
> 注意如果对象支持复制需要**实现Cloneable接口(空接口)并重写Object的clone方法**

* 测试

```java

public class PrototypeTest {

    public static void main(String[] args) {
        User user1 = new User();
        user1.setId(1000);
        user1.setName("张三");
        user1.setAge(20);
        user1.setEnable(true);
        user1.setUserInfo(new UserInfo(1,"12345678901", 111L));

        try {
            User user2 = (User) user1.clone();
            System.out.println("user1: " + user1);
            System.out.println("user2: " + user2);
            user1.setId(2000);
            user1.setName("李四");
            user1.setAge(30);
            user1.setEnable(false);
            user1.getUserInfo().setId(11);
            user1.getUserInfo().setMobile("98746543210");
            user1.getUserInfo().setScore(11111111L);
            System.out.println("修改user1后");
            System.out.println("user1: " + user1);
            System.out.println("user2: " + user2);

            user2.setId(3000);
            user2.setName("王五");
            user2.setAge(40);
            user2.setEnable(true);
            user1.getUserInfo().setId(12);
            user2.getUserInfo().setMobile("14785236974");
            user1.getUserInfo().setScore(12121212L);
            System.out.println("修改user2后");
            System.out.println("user1: " + user1);
            System.out.println("user2: " + user2);

            System.out.println("======================");

            user1.setUserInfo(new UserInfo(22,"888888888", 22222L));
            System.out.println("修改user1的UserInfo");
            System.out.println("user1: " + user1);
            System.out.println("user2: " + user2);

            user2.setUserInfo(new UserInfo(33, "999999", 333333L));
            System.out.println("修改user2的UserInfo");
            System.out.println("user1: " + user1);
            System.out.println("user2: " + user2);
        } catch (CloneNotSupportedException e) {
            e.printStackTrace();
        }
    }

}


//输出
user1: User{id=1000, age=20, name='张三', enable=true, userInfo=UserInfo{id=1, mobile='12345678901', score=111}}
user2: User{id=1000, age=20, name='张三', enable=true, userInfo=UserInfo{id=1, mobile='12345678901', score=111}}
修改user1后
user1: User{id=2000, age=30, name='李四', enable=false, userInfo=UserInfo{id=11, mobile='98746543210', score=11111111}}
user2: User{id=1000, age=20, name='张三', enable=true, userInfo=UserInfo{id=11, mobile='98746543210', score=11111111}}
修改user2后
user1: User{id=2000, age=30, name='李四', enable=false, userInfo=UserInfo{id=12, mobile='14785236974', score=12121212}}
user2: User{id=3000, age=40, name='王五', enable=true, userInfo=UserInfo{id=12, mobile='14785236974', score=12121212}}
======================
user1的UserInfo重新创建
user1: User{id=2000, age=30, name='李四', enable=false, userInfo=UserInfo{id=22, mobile='888888888', score=22222}}
user2: User{id=3000, age=40, name='王五', enable=true, userInfo=UserInfo{id=12, mobile='14785236974', score=12121212}}
user2的UserInfo重新创建
user1: User{id=2000, age=30, name='李四', enable=false, userInfo=UserInfo{id=22, mobile='888888888', score=22222}}
user2: User{id=3000, age=40, name='王五', enable=true, userInfo=UserInfo{id=33, mobile='999999', score=333333}}

Process finished with exit code 0

```

由此可见，复制后的两个对象中任一对象中所有基本类型的修改都不会影响另一个对象。

而如果对象的属性中包含对象：
- 修改了任一对象中的该属性的值，另一个对象中的该属性的值也会被一同修改
- 将任一对象中的该属性重新赋值(new新对象), 则另一个对象中的该属性就不会被修改了

> Java提供的引用类型因为都是重新赋值了，故修改也不会相互影响

**所以如果使用了浅复制的方法，要注意分辨**

常用场景: 实例会持有类似文件、Socket这样的资源，而这些资源是无法复制给另一个对象共享的，只有存储简单类型的“值”对象可以复制

## 深复制

将一个对象复制后，不论是基本数据类型还有引用类型，都是重新创建的。简单来说，就是深复制进行了完全彻底的复制，而浅复制不彻底，要实现深复制就要借助于io流了：

* 在User对象中加入实现深复制的方法，并把所有关联的自定义的对象都实现**Serializable**接口(如果不实现会出现序列化异常)
```
 public Object deepClone() throws IOException, ClassNotFoundException {
        /* 写入当前对象的二进制流 */
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        ObjectOutputStream objectOutputStream = new ObjectOutputStream(byteArrayOutputStream);
        objectOutputStream.writeObject(this);

        /* 读出二进制流产生的新对象 */
        ByteArrayInputStream byteArrayInputStream = new ByteArrayInputStream(byteArrayOutputStream.toByteArray());
        ObjectInputStream objectInputStream = new ObjectInputStream(byteArrayInputStream);
        return objectInputStream.readObject();

    }
```

* 测试

只需要把测试类PrototypeTest中的clone改成deepClone即可，这样无论对象属性如何修改都不会影响另一个对象，具体代码就不放出来了