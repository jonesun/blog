---
title: SpringBoot-监控
date: 2020-11-20 16:59:02
categories: [java,springboot]
tags: [java, springboot]
---

## 前言

方式一： Spring Boot Actuator + Micrometer + Prometheus + Grafana

方式二： Spring Boot Admin

 <!-- more -->


# 搭建

## 方式一

Spring Boot Actuator + Micrometer + Prometheus + Grafana

pom.xml
```
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
  <groupId>io.micrometer</groupId>
  <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

> 如果使用了Spring Security等权限框架需要放开

```
web.ignoring().antMatchers("/actuator", "/actuator/**");
```

```
management:
  endpoints:
    web:
      exposure:
        include: 'prometheus'
  metrics:
    tags:
      application: ${spring.application.name}
```

浏览器测试

```
http://localhost:8080/actuator/prometheus
```

### Prometheus

Prometheus是一款开源的监控 + 时序数据库 + 报警软件

[Prometheus官网](https://prometheus.io/download/)下载，或者访问[docker](https://hub.docker.com/u/prom)进行安装

```
docker pull prom/statsd-exporter

docker run -d -p 9090:9090 \
    -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus --config.file=/etc/prometheus/prometheus.yml
```

> 需编写prometheus.yml

新增

```
scrape_configs:
- job_name: 'springboot'
  scrape_interval: 15s
  scrape_timeout: 10s
  metrics_path: '/actuator/prometheus'
  static_configs:
  - targets: ['localhost:8080']
```


如果不是采用的docker方式，直接找到安装目录下的prometheus.yml，在scrape_configs新增
```
scrape_configs:
  - job_name: 'springboot'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.
    metrics_path: '/actuator/prometheus'
    static_configs:
    - targets: ['localhost:8080']
```
> targets对应需要监控的服务地址

浏览器访问测试

```
http://localhost:9090
```

至此，已经用Prometheus实现了监控数据的可视化，然而使用体验并不好。下面来用Grafana实现更友好、更贴近生产的监控可视化。

### grafana

Grafana是一个开源的跨平台度量分析和可视化 + 告警工具

[grafana](https://grafana.com/grafana/download?pg=hp&platform=docker&plcmt=hero-btn2)

使用docker安装
```
docker run -d --name=grafana -p 3000:3000 grafana/grafana
```

Windows的话下载zip或者安装包直接安装即可

登录：访问 http://localhost:3000 ，初始账号/密码为：admin/admin

![grafana-home](grafana-home.png)

#### 绑定Prometheus

左侧菜单选择Configuration-datasources-Add data source

添加Prometheus地址

![grafana-add-proetheus](grafana-add-proetheus.png)

点击 save&test，测试成功即可


#### 创建监控Dashboard

左侧菜单选择+Create-Import，输入id为**4701**，这个是为Micrometer提供的增强包。有兴趣可以前往 [Grafana Lab - Dashboards](https://grafana.com/dashboards)，输入关键词即可搜索指定Dashboard, 详情页的右上角找到id

![grafana-dashboard-id](grafana-dashboard-id.png)

比较好用的Dashboard
- JVM (Micrometer)
- JVM (Actuator)
- Spring Boot Statistic

> 注意是以 Prometheus 作为数据源，支持Micrometer的Dashboard

![grafana-import](grafana-import.png)

点击右侧load后，选择prometheus，确认后import

![grafana-import-select-prometheus](grafana-import-select-prometheus.png)

> 如果选择项是空的，注意是否开启了prometheus

![grafana-dashboard](grafana-dashboard.png)

可查看监控的服务jvm等情况

## 告警

Grafana支持的告警渠道非常丰富，例如邮件、钉钉、Slack、Webhook等，有兴趣可以了解下

# 方式二

Spring Boot Admin

Spring Boot Admin是一个开源社区项目，用于管理和监控SpringBoot应用程序。 应用程序作为Spring Boot Admin Client向为Spring Boot Admin Server注册（通过HTTP）或使用SpringCloud注册中心（例如Eureka，Consul）发现。 UI是的AngularJs应用程序，展示Spring Boot Admin Client的Actuator端点上的一些监控。

## 搭建

创建两个SpringBoot项目，一个作为监控端(admin-server-demo)，一个作为被监控端(admin-client-demo)

### server端

pom.xml

```
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>2.4.0</version>
		<relativePath/> <!-- lookup parent from repository -->
	</parent>
	<groupId>com.jonesun</groupId>
	<artifactId>admindemo</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<name>admin-server-demo</name>
	<description>Demo project for Spring Boot</description>

	<properties>
		<java.version>14</java.version>
		<spring-boot-admin.version>2.3.1</spring-boot-admin.version>
	</properties>

	<dependencies>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-web</artifactId>
		</dependency>
		<dependency>
			<groupId>de.codecentric</groupId>
			<artifactId>spring-boot-admin-starter-server</artifactId>
		</dependency>

		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-test</artifactId>
			<scope>test</scope>
		</dependency>
	</dependencies>

	<dependencyManagement>
		<dependencies>
			<dependency>
				<groupId>de.codecentric</groupId>
				<artifactId>spring-boot-admin-dependencies</artifactId>
				<version>${spring-boot-admin.version}</version>
				<type>pom</type>
				<scope>import</scope>
			</dependency>
		</dependencies>
	</dependencyManagement>

	<build>
		<plugins>
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
			</plugin>
		</plugins>
	</build>

</project>

```

application.yml

```
server:
  port: 8001
spring:
  application:
    name: admin-server
```

AdminServerDemoApplication.java

```
@EnableAdminServer
@SpringBootApplication
public class AdminServerDemoApplication {

	public static void main(String[] args) {
		SpringApplication.run(AdminServerDemoApplication.class, args);
	}

}

```

### client端

pom.xml

```
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>2.4.0</version>
		<relativePath/> <!-- lookup parent from repository -->
	</parent>
	<groupId>com.jonesun</groupId>
	<artifactId>admin-client-demo</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<name>admin-client-demo</name>
	<description>Demo project for Spring Boot</description>

	<properties>
		<java.version>14</java.version>
		<spring-boot-admin.version>2.3.1</spring-boot-admin.version>
	</properties>

	<dependencies>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-web</artifactId>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-actuator</artifactId>
		</dependency>
		<dependency>
			<groupId>de.codecentric</groupId>
			<artifactId>spring-boot-admin-starter-client</artifactId>
		</dependency>

		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-test</artifactId>
			<scope>test</scope>
		</dependency>
	</dependencies>

	<dependencyManagement>
		<dependencies>
			<dependency>
				<groupId>de.codecentric</groupId>
				<artifactId>spring-boot-admin-dependencies</artifactId>
				<version>${spring-boot-admin.version}</version>
				<type>pom</type>
				<scope>import</scope>
			</dependency>
		</dependencies>
	</dependencyManagement>

	<build>
		<plugins>
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
			</plugin>
		</plugins>
	</build>

</project>

```

application.yml

```
spring:
  application:
    name: admin-client
  boot:
    admin:
      client:
        url: http://localhost:8001
server:
  port: 8002

management:
  endpoints:
    web:
      exposure:
        include: '*'
  endpoint:
    health:
      show-details: ALWAYS
```

## 运行验证

分别启动两个服务，然后浏览器中打开server端的网址: http://localhost:8001/

即可查看监控信息，和服务的详细情况

![springboot-admin](springboot-admin.png)

## 告警

可以结合spring-boot-starter-mail进行告警