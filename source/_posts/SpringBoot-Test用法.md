---
title: SpringBoot-Test用法
categories:
  - java
  - springboot
tags:
  - java
  - springboot
abbrlink: 8dec456e
date: 2021-03-05 17:18:09
---

# 前言

使用idea新建SpringBoot项目时，大家应该会发现除了正常的src/main文件夹之外，还会有个test文件夹，相应的会引入spring-boot-starter-test模块，
本文就来聊聊这个test模板的用法

说到test大家都会想到junit，是的spring-boot-starter-test默认集成的就是junit，但需要注意的是：springboot2.x的版本, 默认使用的是[junit5](https://junit.org/junit5/docs/current/user-guide/) 版本, junit4和junit5两个版本差别比较大，需要注意下用法：

*通常我们只要引入 spring-boot-starter-test 依赖就行，它包含了一些常用的模块 Junit、Spring Test、AssertJ、Hamcrest、Mockito 等*

![junit5vsjunit4](junit5vsjunit4.png)

 <!-- more -->

## 为什么使用JUnit5

- JUnit4被广泛使用，但是许多场景下使用起来语法较为繁琐，JUnit5中支持lambda表达式，语法简单且代码不冗余。
- JUnit5易扩展，包容性强，可以接入其他的测试引擎。
- 功能更强大提供了新的断言机制、参数化测试、重复性测试等新功能。
- ...

如无特殊说明，直接使用junit5相关api(org.junit.jupiter.api.*, 这是junit5引入的;  junit4引入的是org.junit.Test这样类似的包)

# 引入

1. pom.xml中加入spring-boot-starter-test模块(一般会默认引入)：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
```

> 需要注意的是SpringBoot2.2开始会需要排除junit-vintage-engine，这个是因为早期的junit5默认引入了junit-vintage-engine用于运行junit4测试(junit-jupiter-engine用于junit5测试), 一般新的项目无需junit4，因此POM中的默认依赖项排除在外

```xml
 <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
    <exclusions>
        <exclusion>
            <groupId>org.junit.vintage</groupId>
            <artifactId>junit-vintage-engine</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

> 但从SpringBoot2.4.0开始spring-boot-starter-test中的junit5已经默认移除了junit-vintage-engine，所以就无需手动排除了

当然，如果有写老的测试代码还是使用了junit4相关api的话:

- SpringBoot 2.2到2.4.0之前，只要将手动排除的代码注释掉即可
- SpringBoot 2.4.0之后，需要手动添加junit-vintage-engine:

```xml
<dependency>
    <groupId>org.junit.vintage</groupId>
    <artifactId>junit-vintage-engine</artifactId>
    <scope>test</scope>
    <exclusions>
        <exclusion>
            <groupId>org.hamcrest</groupId>
            <artifactId>hamcrest-core</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

**看好实际项目中使用的SpringBoot版本**

# 使用

**junit5使用的都是org.junit.jupiter.xxx**

1. 在测试类加入@SpringBootTest：这个注解是SpringBoot自1.4.0版本开始引入的一个用于测试的注解，这样一般就可以了，不用加@RunWith(SpringRunner.class)，这个是junit4的注解

2. 在测试方法中加入@Test: 注意是org.junit.jupiter.api.Test

```java
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class MyApplicationTests {

    @Test
    void contextLoads() {
        //xxx
    }

}

```

右击代码即可运行测试

## @DisplayName()测试显示中文名称

```java
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@DisplayName("测试1")
@SpringBootTest
class StandAloneServerApplicationTests {

    @DisplayName("测试方法1")
    @Test
    void contextLoads() {
        //xxx
    }

}

```

![displayName](displayName.png)

## 指定测试顺序

```java
import org.junit.jupiter.api.*;
import org.springframework.boot.test.context.SpringBootTest;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@DisplayName("测试1")
@SpringBootTest
class StandAloneServerApplicationTests {

    @Order(2)
    @DisplayName("测试方法1")
    @Test
    void contextLoads() {

    }

    @Order(1)
    @DisplayName("测试方法2")
    @Test
    void test2() {

    }

}

```

更多其他注解用法，可查阅官方文档 [writing-tests-annotations](https://junit.org/junit5/docs/current/user-guide/#writing-tests-annotations)

## 测试Controller

测试Controller不建议直接引用Controller类进行测试，因为Controller一般是提供api给外部访问用的，使用http请求更能模拟真实场景，SpringBoot中提供了Mockito可以达到效果

举例

```java
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@DisplayName("用户Controller层测试")
@AutoConfigureMockMvc //不启动服务器,使用mockMvc进行测试http请求
@SpringBootTest
class UserControllerTest {

    private final Logger logger = LoggerFactory.getLogger(this.getClass());

    MockMvc mockMvc;

    ObjectMapper objectMapper;

    @Autowired
    public UserControllerTest(MockMvc mockMvc, ObjectMapper objectMapper) {
        this.mockMvc = mockMvc;
        this.objectMapper = objectMapper;
    }

    @Order(1)
    @DisplayName("注册")
    @Test
    void register() throws Exception {
        UserForm userForm = new UserForm();
        userForm.setName("jonesun");
        userForm.setAge(30);
        userForm.setEmail("sunr922@163.com");
        //请求路径不要错了
        MvcResult mvcResult = mockMvc.perform(MockMvcRequestBuilders.post("/users")
                        //这里要特别注意和content传参数的不同，具体看你接口接受的是哪种
//                        .param("userName",info.getUserName()).param("password",info.getPassword())
                        //传json参数,最后传的形式是 Body = {"password":"admin","userName":"admin"}
                        .content(objectMapper.writeValueAsString(userForm))
                        .accept(MediaType.APPLICATION_JSON)
                        .contentType(MediaType.APPLICATION_JSON)
        )
                .andExpect(MockMvcResultMatchers.status().isOk())
                .andDo(MockMvcResultHandlers.print())
                .andReturn();

        //得到返回代码
        int status = mvcResult.getResponse().getStatus();
        //得到返回结果
        String content = mvcResult.getResponse().getContentAsString();

        logger.info("status: {}, content: {}", status, content);
    }

    @Order(2)
    @DisplayName("列表")
    @Test
    void list() throws Exception {

        RequestBuilder request = MockMvcRequestBuilders.get("/users")
//                .param("searchPhrase","ABC")          //传参
                .accept(MediaType.APPLICATION_JSON)
                .contentType(MediaType.APPLICATION_JSON);  //请求类型 JSON
        MvcResult mvcResult = mockMvc.perform(request)
                // 期望的结果状态 等同于Assert.assertEquals(200,status);
                .andExpect(MockMvcResultMatchers.status().isOk())
                .andDo(MockMvcResultHandlers.print())                 //添加ResultHandler结果处理器，比如调试时 打印结果(print方法)到控制台
                .andReturn();                                         //返回验证成功后的MvcResult；用于自定义验证/下一步的异步处理；
        int status = mvcResult.getResponse().getStatus();                 //得到返回代码
        String content = mvcResult.getResponse().getContentAsString();    //得到返回结果
        logger.info("status: {}, content: {}", status, content);
//
//        mockMvc.perform(MockMvcRequestBuilders.get("/users"))
//                .andDo(print())
//                .andExpect(status().isOk())
//                .andExpect(content().string(containsString("Hello World")));
    }
}
```

完整代码见 [github](https://github.com/jonesun/mybatis-sample/blob/master/src/test/java/org/jonesun/mybatis/sample/controller/UserControllerTest.java)

## 测试并发

有时我们需要对自己编写的代码做并发测试，看在高并发情况下，代码中是否存在线程安全等问题，通常可以利用[Jmeter](https://jmeter.apache.org/)或者浏览器提供的各个插件(如postman)。
实际上我们可以利用JUC提供的[并发同步器CountDownLatch和Semaphore](/20200731/java/多线程/d2a4479b/)来实现

举例，模拟秒杀场景

```java
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@SpringBootTest
class GoodsServiceTest {

    private final Logger logger = LoggerFactory.getLogger(getClass());

    @Autowired
    GoodsService goodsService;


    public static final Long TEST_GOODS_ID = 123L;

    @Order(1)
    @Test
    void init() {
        Goods goods = new Goods(TEST_GOODS_ID, "商品1", 100);
        goodsService.init(goods);
    }


    @Order(2)
    @Test
    void buy() {
        goodsService.buy(TEST_GOODS_ID);
    }

    @DisplayName("秒杀单个商品")
    @Order(3)
    @Test
    void batchBuy() throws InterruptedException {
        Integer inventory = goodsService.getInventoryByGoodsId(TEST_GOODS_ID);
        logger.info("【{}】准备秒杀, 当前库存: {}", TEST_GOODS_ID, inventory);
        LocalDateTime startTime = LocalDateTime.now();
        AtomicInteger buySuccessAtomicInteger = new AtomicInteger();
        AtomicInteger notBoughtAtomicInteger = new AtomicInteger();
        AtomicInteger errorAtomicInteger = new AtomicInteger();
        final int totalNum = 300;
        //用于发出开始信号
        final CountDownLatch countDownLatchSwitch = new CountDownLatch(1);
        final CountDownLatch countDownLatch = new CountDownLatch(totalNum);

        //控制并发量 10 50 100 200
        Semaphore semaphore = new Semaphore(200);

        ExecutorService executorService = Executors.newFixedThreadPool(totalNum);

        for (int i = 0; i < totalNum; i++) {
            executorService.execute(() -> {
                try {
                    countDownLatchSwitch.await();
                    semaphore.acquire();
                    TimeUnit.SECONDS.sleep(1);

                    boolean result = goodsService.buy(TEST_GOODS_ID);
                    if (result) {
                        buySuccessAtomicInteger.incrementAndGet();
                    } else {
                        notBoughtAtomicInteger.incrementAndGet();
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    errorAtomicInteger.incrementAndGet();
                } finally {
                    semaphore.release();
                    countDownLatch.countDown();
                }

            });

        }
        countDownLatchSwitch.countDown();
        countDownLatch.await();
        logger.info("测试完成,花费 {}毫秒，【{}】总共{}个用户抢购{}件商品，{}个人买到 {}个人未买到，{}个人发生异常，商品还剩{}个", TEST_GOODS_ID, ChronoUnit.MILLIS.between(startTime, LocalDateTime.now()), totalNum,
                inventory, buySuccessAtomicInteger.get(), notBoughtAtomicInteger.get(), errorAtomicInteger.get(),
                goodsService.getInventoryByGoodsId(TEST_GOODS_ID));
        assertEquals(inventory, buySuccessAtomicInteger.get());
    }

}
```

完整代码见 [github](https://github.com/jonesun/mybatis-sample/blob/master/src/test/java/org/jonesun/mybatis/sample/controller/UserControllerTest.java)


-- 未完，抽时间继续整理整理 --