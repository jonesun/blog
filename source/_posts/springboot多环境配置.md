---
title: springboot多环境配置
categories:
  - java
  - springboot
tags:
  - java
  - springboot
abbrlink: 5ca3dffb
date: 2021-07-12 16:35:58
urlname:
---

# 前言

日常项目中经常会针对不同环境进行不同配置，比如数据库配置，在开发的时候，我们一般用测试数据库，而在生产环境的时候，我们是用正式的数据。或者像日志的配置等等......
这时候，我们可以利用profile在不同的环境下配置不同的配置文件

而在SpringBoot中是允许约定按照一定的格式(application-{profile}.yml)来定义多个配置文件，然后通过在application.yml中通过指定spring.profiles.active来具体激活一个或者多个配置文件。

> 如果没有没有指定任何profile的配置文件的话，spring boot默认会启动application-default.yml

 <!-- more -->

# 使用

现在大多流行4个环境配置，具体看项目的大小(较小的项目直接dev+prod):

- dev: 开发环境，一般是供开发人员日常编写代码自测使用
- test(或者sit): 测试环境，用于给测试人员验证功能时使用
- pre: 预发布环境，使用真实的数据进行上线前的功能流程验证用，基本上模拟了真实的生产环境
- prod: 生产环境，实际的生产环境

下面我就看下如何在maven下进行配置

## yml多环境配置

在resources中分别新建不同环境用的yml(如果项目使用的是properties则修改yml后缀并改写配置为properties格式即可)配置（演示方便只分别设置不同端口）

- application-dev.yml:

```yaml
# 应用名称
server:
  port: 8081
```

- application-test.yml:

```yaml
server:
  port: 8082
```

- application-prod.yml:

```yaml
server:
  port: 8083
```

# pom配置

这时需要在pom.xml中加入多环境配置(如果是多模块的项目则在最外层的pom.xml中配置即可，无需每个模块都配置)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project>
  
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>

    <profiles>
        <profile>
            <id>dev</id>
            <properties>
                <profileActive>dev</profileActive>
            </properties>
            <activation>
                <!--默认打包环境-->
                <activeByDefault>true</activeByDefault>
            </activation>
        </profile>
        <profile>
            <id>test</id>
            <properties>
                <profileActive>test</profileActive>
            </properties>
        </profile>
        <profile>
            <id>prod</id>
            <properties>
                <profileActive>prod</profileActive>
            </properties>
        </profile>
    </profiles>

</project>

```

再在原有application.yml加入(注意一定要配置pom.xml，不然会报类似@profileActive@找不到的错误):

```yaml
spring:
  profiles:
    active: @profileActive@
```

> 如果不想定义多个yml，也可以直接在application.yml中配置多个环境

通过---可以把一个yml文档分割为多个，并可以通过 spring.profiles.active 属性指定使用哪个配置文件

application.yml
```yaml
spring:
  profiles:
    active: @profileActive@
---
# 应用名称
#spring:
#  profiles: dev
spring:
  config:
    activate:
      on-profile: dev
server:
  port: 8081

---

# 应用名称
#spring:
#  profiles: prod
spring:
  config:
    activate:
      on-profile: dev
server:
  port: 8082

```

> springBoot 2.4开始废弃了原有的spring.profiles, 改为了spring.config.activate.on-profile，故如果项目的springBoot版本是2.4+的推荐用新的配置

# 切换环境

这个使用就默认使用dev环境进行运行，如果要开发中切换环境修改pom.xml中的默认打包环境即可(如切换为test环境):

```xml
<profile>
    <id>test</id>
    <properties>
        <profiles.active>test</profiles.active>
    </properties>
    <activation>
        <!--默认打包环境-->
        <activeByDefault>true</activeByDefault>
    </activation>
</profile>
```

或者使用idea的话，配置启动配置(推荐):

![idea-config](idea-config.png)

不过一般我们也很少会在开发中更改环境，更多是打包时指定环境，这个时候就要使用mvn命令了:

```shell
mvn clean package -Dmaven.test.skip=true -Ptest   #测试环境

mvn clean package -Dmaven.test.skip=true -Pprod #生产环境
```

## @Profile

在某些情况下除了静态配置，某些业务如发送邮件仅生产环境中才实际执行，而开发环境里则不发送以免向用户发送无意义的垃圾邮件。

可以借助Spring的注解 **@Profile** 实现这样的功能

```java
public interface IEmailService {

    void send(String content);
}

@Service
@Profile("prod")
public class EmailService implements IEmailService{

    private final Logger logger = LoggerFactory.getLogger(getClass());

    @Override
    public void send(String content) {
        //测试方便，仅仅打印日志
        logger.info("发送邮件: {}", content);
    }
}

@SpringBootTest
class EmailServiceTest {

    private final Logger logger = LoggerFactory.getLogger(this.getClass());

    @Autowired(required = false)
    IEmailService emailService;

    @Value("${spring.profiles.active}")
    private String env;

    @Test
    void testSend() {
        if(emailService == null) {
            logger.error("当前环境：{} 不支持发送邮件",env);
        } else {
            emailService.send("这是一封测试邮件");
        }
    }


}
```

切换环境，可以发现只有设置为prod环境时才会打印发送邮件的日志

# 后记

网上还有一种配置的方式，就是不配置pom.xml，通过Java名称进行环境指定: 

```shell
java -jar xxx.jar --spring.profiles.active=test # 运行测试环境的配置
java -jar xxx.jar --spring.profiles.active=prod # 运行生产环境的配置
```

这种也是可以的

另外如果有些配置不方便放到源码管理中，可以指定加载外部配置的方式(当然如果使用了springCloud的话可以用springConfig或者nacosConfig):

```shell
java -jar xxx.jar --spring.config.location=application-prod.yml
```


如果jar(或者war)包会分发到客户机器中，由于jar可以直接当成zip解压，就会暴露不同环境的配置

![jar-未过滤版本](jar-未过滤版本.png)

这个时候就得根据不同环境过滤打包后的文件了，在pom.xml中加入过滤相关配置:

```xml
    <build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>
    </plugins>

    <finalName>${project.artifactId}</finalName>
    <resources>
        <resource>
            <directory>src/main/java</directory>
            <includes>
                <include>**/*.*</include>
            </includes>
        </resource>
        <resource>
            <directory>src/main/resources</directory>
            <excludes>
                <exclude>application-**.yml</exclude>
            </excludes>
            <filtering>false</filtering>
        </resource>
        <resource>
            <directory>src/main/resources</directory>
            <includes>
                <include>application.yml</include>
                <include>application-${profileActive}.yml</include>
            </includes>
            <filtering>true</filtering>
        </resource>
    </resources>
</build>
```

再次打包，可以发现

![jar-已过滤版本](jar-已过滤版本.png)


最后同样附上[样例代码](https://github.com/jonesun/mybatis-sample)