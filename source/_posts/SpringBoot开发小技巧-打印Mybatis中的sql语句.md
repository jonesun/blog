---
title: SpringBoot开发小技巧-打印Mybatis中的sql语句
categories:
  - java
  - springboot
tags:
  - java
  - springboot
abbrlink: 62be47dd
date: 2020-08-17 16:59:51
---

# 前言

我们平常在开发SpringBoot+Mybatis项目时,有时会需要打印sql的执行语句

# 使用

## application.yml

如果项目使用的时yml配置，则:

```
mybatis:
  configuration:
    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl

logging:
    level:
        com:
            xxxxx:
                dao: debug
```

## application.properties

如果项目使用的时properties配置，则:

```
mybatis.configuration.log-impl: org.apache.ibatis.logging.stdout.StdOutImpl
logging.level.com.xxxxx.dao=debug
```

> 注意包名路径应为mybatis对应的方法接口所在的包，而不是mapper.xml所在的包

即可在控制台中打印sql语句：

```
==>  Preparing: SELECT user_change_bind_log_id,user_id,last_bind,bind,bind_type,log_time FROM user_change_bind_log WHERE user_id=? AND bind_type=? AND log_status=0 ORDER BY log_time DESC LIMIT ? 

==> Parameters: 100023(Integer), device(String), 10(Integer)
```

> 注意上线时需要去除打印，可以用application-xx实现

# 推荐使用idea插件

## MyBatis Log Plugin

> 这款插件可以把Mybatis输出的SQL日志还原成完整的SQL语句，就不需要我们去手动转换了(如何配置，百度一下)


## Free MyBatis plugin

> 非常好用的MyBatis插件，对MyBatis的xml具有强大的提示功能，同时可以关联mapper接口和mapper.xml中的sql实现

- 可以通过Mapper接口中方法左侧的箭头直接跳转到对应的xml实现中去
- 也可以从xml中Statement左侧的箭头直接跳转到对应的Mapper接口方法中去
- 还可以通过Alt+Enter键组合直接生成新方法的xml实现