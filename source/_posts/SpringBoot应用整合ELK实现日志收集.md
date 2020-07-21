---
title: SpringBoot应用整合ELK实现日志收集
date: 2020-07-21 10:59:39
categories: [java,springboot]
tags: [java, springboot, ELK, 日志]
---

# 概念

ELK：Elasticsearch、Logstash、Kibana,组合起来可以搭建线上日志系统

## 各服务作用

- Elasticsearch:用于存储收集到的日志信息；
- Logstash:用于收集日志，SpringBoot应用整合了Logstash以后会把日志发送给Logstash,- Logstash再把日志转发给Elasticsearch；
- Kibana:通过Web端的可视化界面来查看日志

<!-- more -->

## 安装部署

1. 安装docker与Docker Compose

2. 安装Elasticsearch

    ```
    docker pull elasticsearch:6.4.0
    ```

3. 安装Logstash 

    ```
    docker pull logstash:6.4.0
    ```

4. 安装Kibana 

    ```
    docker pull kibana:6.4.0
    ```

# 编写 docker-compose.yml

    在SpringBoot项目中的scr/main/docker/docker-compose.yml编写

```
version: '3'
services:
  elasticsearch:
    image: elasticsearch:6.4.0
    container_name: elasticsearch
    environment:
      - "cluster.name=elasticsearch" #设置集群名称为elasticsearch
      - "discovery.type=single-node" #以单一节点模式启动
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m" #设置使用jvm内存大小
    ports:
      - 9200:9200
  kibana:
    image: kibana:6.4.0
    container_name: kibana
    links:
      - elasticsearch:es #可以用es这个域名访问elasticsearch服务
    depends_on:
      - elasticsearch #kibana在elasticsearch启动之后再启动
    environment:
      - "elasticsearch.hosts=http://es:9200" #设置访问elasticsearch的地址
    ports:
      - 5601:5601
  logstash:
    image: logstash:6.4.0
    container_name: logstash
    volumes:
      - ./:/configdir
    command: logstash -f /configdir/logstash-springboot.conf
logstash.conf #挂载logstash的配置文件
    depends_on:
      - elasticsearch #kibana在elasticsearch启动之后再启动
    links:
      - elasticsearch:es #可以用es这个域名访问elasticsearch服务
    ports:
      - 4560:4560
```

# 编写 logstash-springboot.conf

    在SpringBoot项目中的scr/main/docker/logstash-springboot.conf编写:

```
input {
  tcp {
    mode => "server"
    host => "192.168.31.13"
    port => 4560
    codec => json_lines
  }
}
output {
  elasticsearch {
    hosts => "es:9200"
    index => "springboot-logstash-%{+YYYY.MM.dd}"
  }
}
```

# 执行

cmd切换到docker文件夹下,执行

```
docker-compose up -d
```

# 安装json_lines插件

```
# 进入logstash容器
docker exec -it logstash /bin/bash
# 进入bin目录
cd /bin/
# 安装插件
logstash-plugin install logstash-codec-json_lines
# 退出容器
exit
# 重启logstash服务
docker restart logstash
```

# 访问

浏览器打开

 ```
 http://localhost:5601/app/kibana#/management?_g=()
 ```

![image](https://github.com/jonesun/blog/blob/master/source/image/elk/kibana.jpg?raw=true) 

# SpringBoot应用集成Logstash

## pom.xml添加引用

```
<!--集成logstash-->
<dependency>
    <groupId>net.logstash.logback</groupId>
    <artifactId>logstash-logback-encoder</artifactId>
    <version>5.3</version>
</dependency>
```

## resource中新增logback-spring.xml

```
<?xml version="1.0" encoding="UTF-8"?>
<!--<!DOCTYPE configuration>-->
<configuration>
    <include resource="org/springframework/boot/logging/logback/defaults.xml"/>
    <include resource="org/springframework/boot/logging/logback/console-appender.xml"/>
    <!--应用名称-->
    <property name="APP_NAME" value="mall-admin"/>
    <!--日志文件保存路径-->
    <property name="LOG_FILE_PATH" value="${LOG_FILE:-${LOG_PATH:-${LOG_TEMP:-${java.io.tmpdir:-/tmp}}}/logs}"/>
    <contextName>${APP_NAME}</contextName>
    <!--每天记录日志到文件appender-->
    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${LOG_FILE_PATH}/${APP_NAME}-%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>30</maxHistory>
        </rollingPolicy>
        <encoder>
            <pattern>${FILE_LOG_PATTERN}</pattern>
        </encoder>
    </appender>
    <!--输出到logstash的appender-->
    <appender name="LOGSTASH" class="net.logstash.logback.appender.LogstashTcpSocketAppender">
        <!--可以访问的logstash日志收集端口-->
        <destination>192.168.31.13:4560</destination>
        <encoder charset="UTF-8" class="net.logstash.logback.encoder.LogstashEncoder"/>
    </appender>
    <root level="INFO">
        <appender-ref ref="CONSOLE"/>
        <appender-ref ref="FILE"/>
        <appender-ref ref="LOGSTASH"/>
    </root>
</configuration>

```

## 编写日志

```
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TestController {
    private static final Logger LOGGER = LoggerFactory.getLogger(TestController.class);

    @GetMapping("/test")
    public String test() {
        LOGGER.debug("TestController:{}", "Hello World!!!ELK-debug");
        LOGGER.error("TestController:{}", "Hello World!!!ELK-error");
        LOGGER.warn("TestController:{}", "Hello World!!!ELK-warn");
        LOGGER.info("TestController:{}", "Hello World!!!ELK-info");
//        int i = 1 /0;
        return "Hello World!!!ELK";
    }

}
```

## 运行SpringBoot应用

运行SpringBoot项目，浏览器访问```http://192.168.31.13:8901/test```

# 在kibana中查看日志信息

## 创建index pattern

![image](https://github.com/jonesun/blog/blob/master/source/image/elk/create-index-pattern.jpg?raw=true) 

![image](https://github.com/jonesun/blog/blob/master/source/image/elk/create-index-pattern-1.jpg?raw=true) 

## 查看日志

![image](https://github.com/jonesun/blog/blob/master/source/image/elk/kibana-discover.jpg?raw=true) 

> 注意ipd地址```192.168.31.13```需改为自己的本机ip

# 总结

搭建了ELK日志收集系统之后，如果要查看SpringBoot应用的日志信息，就不需要查看日志文件了，直接在Kibana中查看即可