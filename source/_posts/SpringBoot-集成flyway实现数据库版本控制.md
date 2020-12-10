---
title: SpringBoot-集成flyway实现数据库版本控制
date: 2020-12-09 17:38:57
categories: [java,springboot]
tags: [java, springboot]
---

# 前言

在日常项目开发中，代码可以使用GIT/SVN 来进行版本控制，而数据库的更新却需要人工进行干预。

之前我在项目开发时会根据项目版本手工创建好每次版本迭代会更新的sql文件，发布版本时先在线上执行下对应sql，然后再更新应用版本。在研究自动构建时就想有没有一种技术/框架可以将这种手工行为变为自动。

偶然的机会在网上搜索到[flyway-一个能对数据库变更做版本控制的工具](https://flywaydb.org/)，通过在项目中集成就可以在每次版本更新时自动执行对应版本sql了

Flyway具有以下优点：

* 简单 非常容易安装和学习，同时迁移的方式也很容易被开发者接受。
* 专一 Flyway 专注于搞数据库迁移、版本控制而并没有其它副作用。
* 强大 专为持续交付而设计。让Flyway在应用程序启动时迁移数据库。

<!-- more -->

# 集成

**某个环境使用了 flyway 控制版本之后，就不要再手动增删改表了**

## 新项目

如果是新的项目，直接通过Idea选择Spring Initializr创建SpringBoot项目并勾选[Flyway Migration]即可：

![flyway](flyway.png)

可以发现scr/resources下多了db/migration文件夹，这个文件夹就是提供flyway使用的

* 首先先配置好数据库相关配置，这里为了演示方便使用了H2(实际项目更多使用的是MySQL)

```
spring:
  datasource:
    driver-class-name: org.h2.Driver
    # h2  数据库 持久化到磁盘C:/h2 mysql模式
    url: jdbc:h2:file:C:/h2/test;MODE=MySQL;DATABASE_TO_LOWER=TRUE
    username: root
    password: root123
  h2:
    console:
      enabled: true
      settings:
        trace: true
        web-allow-others: true
      path: /h2-console
```

> 数据库相关配置这边就不多解释了

* 接着需要在application.yml中对flyway进行一些配置：

```
spring:

  # flyway 配置
  flyway:
    # 启用或禁用 flyway 正式环境才开启
    enabled: true
    # 禁用数据库清理 flyway 的 clean 命令会删除指定 schema 下的所有 table, 生产务必禁掉
    clean-disabled: true
    # SQL 脚本的目录,多个路径使用逗号分隔 默认值 classpath:db/migration
    locations: classpath:db/migration
    #  metadata 版本控制信息表 默认 flyway_schema_history,建议后缀指定为当前项目名称
    table: flyway_schema_history_demo
    # 如果没有 flyway_schema_history 这个 metadata 表， 在执行 flyway migrate 命令之前, 必须先执行 flyway baseline 命令
    # 设置为 true 后 flyway 将在需要 baseline 的时候, 自动执行一次 baseline。 针对非空数据库是否默认调用基线版本,为空的话默认会调用基线版本
    baseline-on-migrate: true
    # 指定 baseline 的版本号,默认值为 1, 低于该版本号的 SQL 文件, migrate 时会被忽略
    baseline-version: 1
    # 字符编码 默认 UTF-8
    encoding: UTF-8
    # 是否允许不按顺序迁移 开发建议 true  生产建议 false
    out-of-order: false
    # 需要 flyway 管控的 schema list,这里我们配置为flyway  缺省的话, 使用spring.datasource.url 配置的那个 schema,
    # 可以指定多个schema, 但仅会在第一个schema下建立 metadata 表, 也仅在第一个schema应用migration sql 脚本.
    # 但flyway Clean 命令会依次在这些schema下都执行一遍. 所以 确保生产 spring.flyway.clean-disabled 为 true
    schemas: flyway
    # 执行迁移时是否自动调用验证   当你的 版本不符合逻辑 比如 你先执行了 DML 而没有 对应的DDL 会抛出异常
    validate-on-migrate: true
```

* 编写SQL初始化脚本

在db/migration文件夹下新建V1.0.1__init.sql文件(必须以Vxx__开头，后面根据自己的规则编写即可)：

```
# 示例
DROP TABLE IF EXISTS users;

CREATE TABLE users
(
	id BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
	name VARCHAR(30) NULL DEFAULT NULL COMMENT '姓名',
	age INT(11) NULL DEFAULT NULL COMMENT '年龄',
	email VARCHAR(50) NULL DEFAULT NULL COMMENT '邮箱',
	create_time DATETIME NULL DEFAULT NULL COMMENT '创建日期',
	PRIMARY KEY (id)
);

INSERT INTO users (id, `name`, age, email, create_time) VALUES
(1, 'Jone', 18, 'jone@163.com', '2020-02-09 08:20:00'),
(2, 'Jack', 20, 'jack@163.com', '2020-02-10 11:00:00'),
(3, 'Tom', 28, 'tom@163.com', '2020-03-11 06:10:00'),
(4, 'Sandy', 21, 'sandy@163.com', '2020-04-12 05:30:00'),
(5, 'Billie', 24, 'billie@163.com', '2020-05-13 03:40:00');

```

* 启动项目

可以发现数据库中多了users表和一些数据，同时多了一个flyway数据库里有一个flyway_schema_history_demo表(这些都是在application.yml中配置的)，而这个表就是flyway用来控制sql版本的。

* 后续更新

后续只要根据SQL规则编写新的SQL即可达到每次部署Spring Boot项目时自动更新相应sql了。(需注意flyway社区版目前没有回滚机制，故每次更新时有条件的还是备份下原有数据库，防止意外情况)

> 测试环境存在经常手动修改表增加表的情况的话，建议关闭flyway，因为在手动执行SQL执行之后再执行flyway中的SQL会导致执行失败的情况，当开发稳定后再将需要的SQL语句填入到flyway指定的sql中

### SQL文件编写规则

db/migration文件夹的SQL语句命名需要遵从一定的规范，否则运行的时候flyway会报错。命名规则主要有两种：

- 用于版本升级, 每个版本有唯一的版本号并只能执行一次。以大写的"V"开头，后面跟上"0~9"数字的组合,数字之间可以用“.”或者下划线"_"分割开，然后再以两个下划线分割，其后跟文件名称，最后以.sql结尾。比如，V2.1.5__create_user_ddl.sql、V4.1_2__add_user_dml.sql。
  
- 可重复运行的SQL，以大写的“R”开头，后面再以两个下划线分割，其后跟文件名称，最后以.sql结尾。比如，R__truncate_user_dml.sql。Flyway检测到该类型SQL 脚本的 checksum 有变动, Flyway 就会重新应用该脚本. 它并不用于版本更新
  
> V开头的SQL执行优先级要比R开头的SQL优先级高。

> 另外还有一种：以Ux__开头的SQL，Undo用于撤销具有相同版本的版本化迁移带来的影响。但是该回滚过于粗暴，一般不推荐使用(另外这也是收费版本才支持的)

Flyway 采用左对齐原则比较两个SQL文件的先后顺序, 缺位用 0 代替：
- 1.0.1.1 比 1.0.1 版本高
- 1.0.10 比 1.0.9.4 版本高
- 1.0.10 和 1.0.010 版本号一样高, 每个版本号部分的前导 0 会被忽略

**除了直接在db/migration文件夹中创建sql外，还可以使用自定义的文件夹来对版本进行分类(如db/migration/1.0.0/V1__create_users_by_jonesun.sql)，不会影响flyway对SQL的识别和运行**


## 已有项目集成

已有项目(Spring Boot项目)想要使用Flyway的话：
* pom.xml加入flyway引用:

```
        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-core</artifactId>
        </dependency>

```

* scr/resources下新建db/migration文件夹(注意是先新建db文件夹再新建migration文件夹)
* 同上面的新项目一样在application.yml中对flyway进行配置
* 在db/migration文件夹中增加一个名为 V1.0.0__init.sql的文件，内容为空，用于占位
* 在db/migration文件夹中按照规则新建Vxxx__xxx.sql即可
  
一个好的习惯：先 dump 一份所有环境中当前项目最新版本的表结构，在 resources/db目录中创建一个 base_init.sql 文件，将最新版本的 DDL 以及需要初始化的数据放到这个文件中，这个 sql 文件后期就不要做任何修改

如果需要部署到新的环境，则只需要执行base_init.sql即可，其他版本的交给 flyway 就可以了

## 注意事项

因为flyway针对Vxx__.sql在项目启动后只会执行一次，故开发环境下要不先关闭flyway, 要不sql编写后启动过项目后就不要再变化了，不然会报异常Validate failed，当然如果出现此类异常需要到flyway_schema_history_demo(表名随自己项目的配置)删除对应记录:

```
DELETE IGNORE FROM flyway_schema_history_demo WHERE success = 0;

```

# 其他

flyway也提供了maven插件便于开发调试使用，有兴趣可以了解下: 

```
<plugin>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-maven-plugin</artifactId>
    <configuration>
</plugin>
```

与flyway类似的还有[Liquibase](https://www.liquibase.org/)。对应的flyway和Liquibase都有收费版提供更强大的功能。