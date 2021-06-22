---
title: SpringBoot开发小技巧-对象属性拷贝BeanUtils.copyProperties
categories:
  - java
  - springboot
tags:
  - java
  - springboot
abbrlink: c177f6b0
date: 2020-08-31 13:11:32
---

# 前言

平常我们在开发过程中经常会遇到将某个对象的一些属性赋值给另一个对象，常见的是将前端传输的from或者DTO赋值给DO

> DO/DTO/VO/FORM的区别
- DO 就是entity ，对应表实体，和数据库的字段一一对应
- DTO 数据传输对象，DTO本身不是业务对象
- VO 用于封装传递到前端需要展示的字段，数据库表不需要展示的，不要包含
- form 用于封装前端传入的字段， 可以配合@Valid注解，对前端传入数据，进行验证，比如必填字段

# 使用

一般我们会这么写:
```
public class UserInputDTO {

    @NotNull
    private String username;

    @NotNull
    private Integer age;

    private Boolean sex;

    @NotNull
    private String desc;

    private LocalDate birthday;
}

public class User {
    private String userId;

    private String username;

    private String password;

    private Integer age;

    private Boolean sex;

    private String desc;

    private LocalDate birthday;
}

//使用
UserInputDTO userInputDTO = new UserInputDTO();
userInputDTO.setUsername("username");
userInputDTO.setAge(20);
userInputDTO.setBirthday(LocalDate.of(2000, 1, 1));
userInputDTO.setSex(Boolean.TRUE);
userInputDTO.setDesc("this is my desc");

User user = new User();
user.setUsername(userInputDTO.getUsername());
user.setAge(userInputDTO.getAge());
user.setBirthday(userInputDTO.getBirthday());
user.setSex(userInputDTO.getSex());
user.setDesc(userInputDTO.getDesc());
```

而实际上，Spring框架自带一个工具类，可以实现上面的功能，避免编写重复的样板代码:

```
UserInputDTO userInputDTO = new UserInputDTO();
userInputDTO.setUsername("username");
userInputDTO.setAge(20);
userInputDTO.setBirthday(LocalDate.of(2000, 1, 1));
userInputDTO.setSex(Boolean.TRUE);
userInputDTO.setDesc("this is my desc");

User user = new User();
BeanUtils.copyProperties(userInputDTO, user);
```

> BeanUtils提供对Java反射和自省API的包装。其主要目的是利用反射机制对JavaBean的属性进行处理

# 注意要求

当然如果使用了该工具类，有些情况需要开发过程中注意下：

- 对象属性，最好为包装类，否则可能出现null与0的问题
- 这个工具类是对bean之间存在属性名相同的属性进行处理，无论是源bean或者是目标bean中多出来的属性均不处理
- BeanUtils是浅拷贝，需注意深浅拷贝的不同

> 深浅拷贝

- 浅拷贝： 只是调用子对象的set方法，并没有将所有属性拷贝。(也就是说，引用的一个内存地址)
- 深拷贝： 将子对象的属性也拷贝过去

同类的还有Apache的commons库里也有BeanUtils，需注意如果使用了Apache的工具类的话，参数与Spring提供的参数顺序是相反的，当然《阿里巴巴java开发手册》中明确规定:

![注意要点](注意要点.png)

从网上搜索相关资料，可以知晓，大概是效率问题，是因为Apache BeanUtils在代码中增加了非常多的校验、兼容、日志打印等代码，导致性能下降严重(当然在一些特定场景中这些校验还是比较重要的)。