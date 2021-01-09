---
title: SpringBoot-Starters
date: 2020-12-26 10:15:25
categories: [java,springboot]
tags: [java, springboot]
---

# 前言

使用Spring Boot Starters可以快速集成相关组件，无需编写复杂的配置，在引入某项技术框架时，一个比较好的习惯就是看有没有xxx-starter

<!-- more -->

## 一、官方提供的starts

> 以下基于Spring Boot 2.4.0版本，后续版本可能会有新增和删除，有兴趣可以到spring-boot-autoconfigure中查看最新版本

### application starters 应用程序级

* spring-boot-starter: 核心Starter, 包含自动配置、日志及yaml支持等

* spring-boot-starter-aop: 集成Spring AOP和Aspectj, 用于支持面向切面编程

* spring-boot-starter-batch: 集成Spring Batch, 用于批处理相关

* spring-boot-starter-cache: 集成Spring Cache, 用于缓存相关

* spring-boot-starter-hateoas: 集成Spring MVC和Spring HATEOAS构建超媒体RESTFul Web应用

* spring-boot-starter-integration: 集成Spring Integration

* spring-boot-starter-jdbc: 集成JDBC结合Hikari连接池

* spring-boot-starter-jersey: 集成JAX-RS和Jersey构建RESTful Web应用，是spring-boot-starter-web的一个替代品

* spring-boot-starter-jooq: 集成JOOQ访问数据库，是spring-boot-starter-data-jpa或者spring-boot-starter-jdbc的替换品

* spring-boot-starter-json: 集成Jackson用于读写JSON

* spring-boot-starter-jta-atomikos: 集成Atomikos实现JTA事务

* spring-boot-starter-jta-bitronix: 集成Bitronix实现JTA事务，不过2.3.0开始被标识为Deprecated

* spring-boot-starter-mail: 集成Java Mail和Spring架构的邮件发送功能

* spring-boot-starter-security: 集成Spring Security用于权限认证

* spring-boot-starter-oauth2-client: 集成Spring Security's OAuth2/OpenID连接客户端功能

* spring-boot-starter-oauth2-resource-server: 集成Spring Security's OAuth2资源服务器功能

* spring-boot-starter-quartz: 集成Quartz任务调度

* spring-boot-starter-rsocket: 构建RSocket客户端和服务端

* spring-boot-starter-test: 集成JUint Jupiter, Hamcrest和Mockito测试Spring Boot应用和类库

* spring-boot-starter-validation: 集成Java Bean Validation结合Hibernate Validator

* spring-boot-starter-web: 集成Spring MVC构建RESTful Web应用，使用Tomcat作为默认内嵌容器

* spring-boot-starter-web-services: 集成Spring Web Services

* spring-boot-starter-webflux: 集成Spring Reactive Web构建WebFlux应用

* spring-boot-starter-websocket: 集成Spring WebSocket构建WebSocket应用

#### Spring Data

所有Spring Data项目都是为了简化Spring应用的数据访问开发

* spring-boot-starter-data-cassandra: 集成Spring Data Cassandra和分布式数据库Cassandra

* spring-boot-starter-data-cassandra-reactive: 集成Spring Data Cassandra Reactive和分布式数据库Cassandra

* spring-boot-starter-data-couchbase: 集成Spring Data Couchbase和文档型数据库Couchbase

* spring-boot-starter-data-couchbase-reactive: 集成Spring Data Couchbase Reactive和文档型数据库Couchbase

* spring-boot-starter-data-elasticsearch: 集成Spring Data和搜索引擎Elasticsearch

* spring-boot-starter-data-solr: 集成Spring Data Solr和搜索引擎Apache Solr

* spring-boot-starter-data-jdbc: 集成Spring Data JDBC, 给基于JDBC的数据库应用提供Repository封装, 类似于Spring Data JPA中JpaRepository的功能，但是不引入任何ORM框架

* spring-boot-starter-data-jpa: 集成Spring Data Jpa结合Hibernate

* spring-boot-starter-data-ldap: 集成Spring Data LDAP

* spring-boot-starter-data-mongodb: 集成Spring Data MongoDB和文档型数据库MongoDB

* spring-boot-starter-data-mongodb-reactive: 集成Spring Data MongoDB Reactive和文档型数据库MongoDB

* spring-boot-starter-data-neo4j: 集成Spring Data Neo4j和图形数据库Neo4j

* spring-boot-starter-data-r2dbc: 集成Spring Data R2DBC

* spring-boot-starter-data-redis: 集成Spring Data Redis和内存数据库Redis并使用Lettuce客户端

* spring-boot-starter-data-redis-reactive: 集成Spring Data Redis Reactive和内存数据库Redis并使用Lettuce客户端

* spring-boot-starter-data-rest: 集成Spring Data REST暴露Spring Data Repositories输出REST资源

#### 视图渲染

* spring-boot-starter-thymeleaf: 集成Thymeleaf视图构建MVC Web应用

* spring-boot-starter-freemarker: 集成Freemarker视图构建MVC Web应用

* spring-boot-starter-mustache: 集成Mustache视图构建Web应用

* spring-boot-starter-groovy-templates: 集成Groovy模板视图构建MVC Web应用

#### 消息队列

* spring-boot-starter-activemq: 集成Apache ActiveMQ，基于JMS(Java Message Service 消息服务)的消息队列

* spring-boot-starter-artemis: 集成Apache Artemis，基于JMS的消息队列

* spring-boot-starter-amqp: 集成Spring AMQP和Rabbit MQ的消息队列

### production starters 生产级

* spring-boot-starter-actuator: 集成Spring Boot Actuator, 提供生产功能以帮助监控和管理应用程序

### technical starters 技术类

* spring-boot-starter-log4j2: 集成Log4j2日志框架，注意需排除默认的logback引用

* spring-boot-starter-logging: 集成Logback日志框架，引入Spring Boot时默认已集成

* spring-boot-starter-tomcat: 集成Tomcat作为内嵌的servlet容器，引入web starter时默认已集成

* spring-boot-starter-jetty: 集成Jetty作为内嵌的servlet容器，注意需排除掉web starter原有tomcat引用

* spring-boot-starter-undertow: 集成Undertow作为内嵌的servlet容器，注意需排除掉web starter原有tomcat引用

* spring-boot-starter-reactor-netty: 集成Netty作为内嵌的响应式Http服务器

> 以上所有官方提供的starter，如果你项目pom文件中的parent是spring-boot-starter-parent，则引入时无需指定version，Spring Boot会自动引用相关依赖(感兴趣可以idea安装Maven Helper这个插件看下自己使用的starts各自引用的库的版本)
> 如果发现starter自身引入的库版本较低，或者想体验该库的新版本，需先排除原有库引用再单独引入该库(可从[Maven Central Repository](https://search.maven.org/)中查看)

## 二、第三方starts

一般第三方的框架会提供自制的 Spring Boot Starter，如：mybatis-spring-boot-starter，只要几个依赖，几行配置参数就能轻松实现集成

## 三、自己编写Starter

除了第三方的 Starter，也可以私有定制Starter，方便在公司内部各业务部门快速集成使用，而不用各自造轮子

### 命名风格

- groupId: 不要用官方的org.springframework.boot, 而要用你自己独特的。
- artifactId: Spring Boot官方建议非官方的Starter命名格式遵循 xxx-spring-boot-starter ，例如 mybatis-spring-boot-starter。
官方starter会遵循spring-boot-starter-xxx ,例如的spring-boot-starter-web。
  
### 编写要点

starter集成入应用有两种方式：
- 主动生效，使用@Import注解，集成后在Spring Boot中加入自定义的@Enablexxx就会生效
- 被动生效, 在autoconfigure资源包下新建META-INF/spring.factories写入XXXAutoConfiguration全限定名, 这样在starter组件集成入Spring Boot应用后就会生效

比较好的习惯，编写自定义starter时最好包含以下模块

#### xxx-spring-boot-autoconfigure

普通maven项目即可， 需要引用spring-boot-autoconfigure和spring-boot-configuration-processor(以便在IDE中配置参数时可以进行提示)，主要用来定义配置参数、以及自动配置对外暴露的功能（一般是抽象的接口Spring Bean）

> 注意一定要显式声明你配置的前缀标识（prefix）

#### xxx-spring-boot-starter

starter是一个空jar。它的唯一目的是提供使用库所必需的依赖项。删除掉src文件夹，在pom文件中加入xxx-spring-boot-autoconfigure依赖(普通maven项目即可)

[示例-jonesun-sample-spring-boot](https://github.com/jonesun/jonesun-sample-spring-boot)

> 可以参考[spring官方提供的文章](https://docs.spring.io/spring-boot/docs/2.4.1/reference/html/spring-boot-features.html#boot-features-developing-auto-configuration) ,还有市场上较流行的非官方starter的编写，如[mybatis-spring-boot-starter](https://github.com/mybatis/spring-boot-starter)

