---
title: SpringBoot-集成Redis
categories:
  - java
  - springboot
tags:
  - java
  - springboot
abbrlink: b11f77d1
date: 2020-08-26 15:36:38
---

# Redis介绍

> Redis is an open source (BSD licensed), in-memory data structure store, used as a database, cache and message broker.

>  C语言开发的、开源的、基于内存的数据结构存储器，可以用作数据库、缓存和消息中间件

> 一种 NoSQL（not-only sql，泛指非关系型数据库）的数据库，性能优秀，数据在内存中，读写速度非常快，支持并发 10W QPS

[Redis](https://redis.io/) [中文网站](http://www.redis.cn/) 的应用场景包括：缓存系统（“热点”数据：高频读、低频写）、计数器、消息队列系统、排行榜、社交网络和实时系统。

## 为什么要使用redis

> 性能

由于MySql数据存储在磁盘中，对于一些需要执行耗时非常长的，但结果不会频繁改动的SQL操作(经常是查询，如每日排行榜或者高频业务热数据)，就适合将运行结果放到到redis中。
后面的请求优先去redis中获取，加快访问速度、提高性能

> 并发

mysql支持并发访问的能力有限(当然现在一般会使用一些数据库连接池的来加强并发能力)，当有大量的并发请求，直接访问数据库的话，mysql会挂掉。所以可以使用redis作为缓冲，让请求先访问到redis，而不是直接访问数据库，提高系统的并发能力。

> 当然redis是基于内存的，存储容量肯定要比磁盘少很多，要存储大量数据，需升级内存，造成在一些不需要高性能的地方是相对比较浪费的，所以建议在需要性能的地方使用redis，在不需要高性能的地方使用mysql。不要一味的什么数据都丢到redis中。

<!-- more -->

**Redis主要有5种数据类型，包括String、list、Set、ZSet、Hash**

数据类型 | 可以存储的值 | 操作 | 应用场景 | Java对应
---|---|---|---|---
String | 字符串、整数或者浮点数 | 对整个字符串或者字符串的其中一部分执行操作;对整数和浮点数执行自增或者自减操作 | 做简单的键值对缓存 | 类似Java的String
List | 列表 | 从两端压入或者弹出元素;对单个或者多个元素进行修剪,只保留一个范围内的元素 | 存储一些列表型的数据结构，类似粉丝列表、文章的评论列表之类的数据 | 类似Java的LinkedList
Set | 无序集合 | 添加、获取、移除单个元素;检查一个元素是否存在于集合中;计算交集、并集、差集;从集合里面随机获取元素 | 交集、并集、差集的操作，比如交集，可以把两个人的粉丝列表整一个交集 | 类似Java中的HashSet
ZSet(Sorted sets) | 有序集合 | 添加、获取、删除元素;根据分值范围或者成员来获取元素;计算一个键的排名 | 去重但可以排序，如获取排名前几名的用户 | 类似Java的SortedSet和HashMap的结合体
Hash | 包含键值对的无序散列表 | 添加、获取、移除单个键值对;获取所有键值对;检查某个键是否存在 | 结构化的数据，比如一个对象 | 类似Java的HashMap

# 集成方式

## 下载安装

### windows

截至2021年1月，官方也没提供windows版本的下载，如果是为了学习需要，可以到[MicrosoftArchive Github](https://github.com/MicrosoftArchive/redis/releases) 上下载(最后的更新时间为2016年)

下载后像常用的软件类似：双击redis-server.exe即可启动redis服务器, 可参考[Redis下载及安装(windows版)](https://www.cnblogs.com/xing-nb/p/12146449.html)

> 此版本对应的是redis的3.2.1版本，而目前redis已经发展到了6.x，故生产环境不建议使用，自己学习就好;
> 当然如果生产环境中的服务器恰好是windows的，小型项目使用也可以(毕竟没那么多并发量)，但还是建议使用下面的docker方式安装，使用较新的稳定版本
> 另外还有一种方案就是到github上下载redis对应版本的源码自己编译(或者找找网络大神的编译好的版本)

### linux

直接输入命令: 
```
sudo apt-get install redis-server
```
安装完成后，Redis服务器会自动启动。

使用
```
ps -aux|grep redis
```
可以看到服务器系统进程默认端口6379

需要手动下载安装包并运行的话，可参考[Ubuntu安装Redis及使用](https://blog.csdn.net/hzlarm/article/details/99432240)


### docker

使用docker

#### 下载镜像
```
docker pull redis
```

#### 准备redis的配置文件

因为需要redis的配置文件，这里最好去redis的[官方网站](http://www.redis.cn/download.html) 去下载一个redis使用里面的配置文件即可

拿到redis.conf 后放到指定目录(这个目录用于后面docker指定本地目录用，比如我放在D:\Software\docker\env\redis\redis.conf)

修改redis.conf配置文件的以下配置：

  - 注释掉 bind 127.0.0.1 使redis可以外部访问，则注释掉这部分
  - 修改 protected-mode no 不限制只能本地访问
  - 修改 requirepass 123456 #给redis设置密码(如果需要)

运行

```shell
# docker run -p 6379:6379 --name redis -v D:\Software\docker\env\redis\redis.conf:/etc/redis/redis.conf  -v D:\Software\docker\env\redis\data:/data -d redis redis-server /etc/redis/redis.conf --appendonly yes
docker run -p 6379:6379 --name redis --restart=always -v /d/Software/docker/env/redis/redis.conf:/etc/redis/redis.conf  -v /d/Software/docker/env/redis/data:/data -d redis redis-server /etc/redis/redis.conf --appendonly yes
# /d/ Windows的D盘
```

参数解释：
  * -p 6379:6379:把容器内的6379端口映射到宿主机6379端口
  * -v /d/Software/docker/env/redis.conf:/etc/redis/redis.conf：把宿主机配置好的redis.conf放到容器内的这个位置中
  * -v /d/Software/docker/env/redis/data:/data：把redis持久化的数据在宿主机内显示，做数据备份
  * redis-server /etc/redis/redis.conf：这个是关键配置，让redis不是无配置启动，而是按照这个redis.conf的配置启动
  * appendonly yes：redis启动后数据持久化

其他定制配置可参考[hub.docker](https://hub.docker.com/_/redis/)

## Redis可视化客户端

Redis的可视化客户端目前较流行的有：

* Redis Desktop Manager: 基于Qt5的跨平台Redis桌面管理软件，[下载地址](http://docs.redisdesktop.com/en/latest/install/#windows) , 不过[0.9.3](https://github.com/uglide/RedisDesktopManager/releases/tag/0.9.3) 版本之后就开始付费使用了，只能下载0.9.3的版本。

![redis-desktop-manager](redis-desktop-manager.png)

* Another Redis Desktop Manager：基于nodejs开发的免费的Redis可视化管理工具 [下载地址](https://github.com/qishibo/AnotherRedisDesktopManager/releases) [码云下载地址](https://gitee.com/qishibo/AnotherRedisDesktopManager/releases)
  
* ![another-redis-desktop-manager](another-redis-desktop-manager.png)

> 个人推荐 Another Redis DeskTop Manager，作为替代方案

## 引入

访问Redis，直接引入spring-boot-starter-data-redis依赖即可(它实际上是Spring Data的一个子项目——[Spring Data Redis](https://docs.spring.io/spring-data/data-redis/docs/current/reference/html/#preface))

在pom.xml中加入
```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-redis</artifactId>
    </dependency>
    <!-- lettuce pool 缓存连接池 如果不需要在yml中自定义pool配置, 则不需要引用-->
    <dependency>
        <groupId>org.apache.commons</groupId>
        <artifactId>commons-pool2</artifactId>
        <version>2.5.0</version>
    </dependency>
</dependencies>

```

> Springboot2以后，底层访问redis已经不再是jedis了，而是默认lettuce

- 使用jedis：当多线程使用同一个连接时，是线程不安全的。所以要使用连接池，为每个jedis实例分配一个连接。
- 使用Lettuce：当多线程使用同一连接实例时，是线程安全的。是采用netty连接redis server，实例可以在多个线程间共享，不存在线程不安全的情况，这样可以减少线程数量

所以如果要继续使用jedis的话需要改为:

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-redis</artifactId>
        <exclusions>
            <exclusion>
                <groupId>io.lettuce</groupId>
                <artifactId>lettuce-core</artifactId>
            </exclusion>
        </exclusions>
    </dependency>
    <dependency>
        <groupId>redis.clients</groupId>
        <artifactId>jedis</artifactId>
    </dependency>
</dependencies>
```

> 推荐使用lettuce

## 配置

如果使用默认lettuce的话，直接在application.yml配置redis服务连接基本参数即可(spring-boot-starter-xx的好处之一):

```yaml
spring:
  ## Redis 配置
  redis:
    ## Redis数据库索引（默认为0）
    database: 1
    ## Redis服务器地址
    host: 127.0.0.1
    ## Redis服务器连接端口
    port: 6379
    ## Redis服务器连接密码（默认为空）
    password:
```

如果需要配置连接池的参数的话:

- 使用lettuce：

```yaml
lettuce:
    pool:
        ## 连接池最大连接数（使用负值表示没有限制） 默认8
        max-active: 500
        ## 连接池中的最小空闲连接 默认0
        min-idle: 0
        ## 连接池中的最大空闲连接 默认8
        max-idle: 500
        ##连接池最大阻塞等待时间（使用负值表示没有限制）
        max-wait: 1000
```

- 使用jedis

```yaml
jedis:
    pool:
        ## 连接池最大连接数（使用负值表示没有限制）
        #spring.redis.pool.max-active=8
        max-active: 8
        ## 连接池最大阻塞等待时间（使用负值表示没有限制）
        #spring.redis.pool.max-wait=-1
        max-wait: -1
        ## 连接池中的最大空闲连接
        #spring.redis.pool.max-idle=8
        max-idle: 8
        ## 连接池中的最小空闲连接
        #spring.redis.pool.min-idle=0
        min-idle: 0
```

## 使用

### 编写公共配置

```java
@EnableCaching
@Configuration("cache")
public class RedisConfig extends CachingConfigurerSupport {

    @Autowired
    RedisConnectionFactory redisConnectionFactory;

    @Bean
    public RedisTemplate<String, Object> objectRedisTemplate() {
        return configRedisTemplate(Object.class, redisConnectionFactory);
    }
    
    /**
     * 可以根据自己实际项目需要，定制多个CacheManager，注解的地方可以指定使用哪个CacheManager
     * @param objectRedisTemplate
     * @return
     */
    @Bean
    public CacheManager cacheManager(RedisTemplate<String, Object> objectRedisTemplate) {
        //如果支持使用objectRedisTemplate，没有用注解或者cacheManager方式的话，则此配置不生效，即key相关的规则，需使用者自己定义
        RedisCacheConfiguration cacheConfiguration = RedisCacheConfiguration
                .defaultCacheConfig()
//                .entryTtl(Duration.ofDays(1))
                .disableCachingNullValues()
                .computePrefixWith(cacheName -> "spring-redis".concat(":").concat(cacheName).concat(":"))
                .serializeKeysWith(RedisSerializationContext.SerializationPair.fromSerializer(objectRedisTemplate.getStringSerializer()))
                .serializeValuesWith(RedisSerializationContext.SerializationPair.fromSerializer(objectRedisTemplate.getValueSerializer()));

        Set<String> cacheNames = new HashSet<>();
        cacheNames.add("user");


        // 对每个缓存空间应用不同的配置
        Map<String, RedisCacheConfiguration> configMap = new HashMap<>();
        configMap.put("user", cacheConfiguration.entryTtl(Duration.ofSeconds(120)));

        return RedisCacheManager.builder(Objects.requireNonNull(objectRedisTemplate.getConnectionFactory()))
                .cacheDefaults(cacheConfiguration)
                .initialCacheNames(cacheNames)
                .withInitialCacheConfigurations(configMap)
                //在spring事务正常提交时才缓存数据
                .transactionAware()
                .build();
    }

    private <T> RedisTemplate<String, T> configRedisTemplate(Class<T> clazz, RedisConnectionFactory redisConnectionFactory) {
        RedisTemplate<String, T> redisTemplate = new RedisTemplate<>();
        redisTemplate.setConnectionFactory(redisConnectionFactory);

        Jackson2JsonRedisSerializer<T> j2jrs = new Jackson2JsonRedisSerializer<>(clazz);
        ObjectMapper om = new ObjectMapper();
        // 指定要序列化的域，field,get和set,以及修饰符范围，ANY是都有包括private和public
        om.setVisibility(PropertyAccessor.ALL, JsonAutoDetect.Visibility.ANY);
        // 解决jackson2无法反序列化LocalDateTime的问题
        om.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        om.registerModule(new JavaTimeModule());

        // 指定序列化输入的类型，类必须是非final修饰的，final修饰的类，比如String,Integer等会跑出异常
//        om.enableDefaultTyping(ObjectMapper.DefaultTyping.NON_FINAL, JsonTypeInfo.As.PROPERTY);
        om.activateDefaultTyping(LaissezFaireSubTypeValidator.instance,
                ObjectMapper.DefaultTyping.NON_FINAL, JsonTypeInfo.As.PROPERTY);
        j2jrs.setObjectMapper(om);

        redisTemplate.setKeySerializer(RedisSerializer.string());
        redisTemplate.setHashKeySerializer(RedisSerializer.string());
        redisTemplate.setValueSerializer(j2jrs);
        redisTemplate.setHashValueSerializer(j2jrs);
        redisTemplate.afterPropertiesSet();

        return redisTemplate;
    }

}

```

### service中使用

> 注意推荐使用SpringCache中的注解和类，这样就算后期不使用redis，改用mongodb或者其他缓存中间件时，业务代码都不需要变更，这里体现了Java中的门面模式(外观模式)

#### 使用@CacheConfig相关注解

**项目中一定要加上@EnableCaching**

```java
@Service("cacheAnnotationUserService")
@CacheConfig(cacheNames = "user")
public class CacheAnnotationUserService implements UserService {

    private final Logger logger = LoggerFactory.getLogger(getClass());

    /**
     * Cacheable[] cacheable() default {}; //声明多个@Cacheable
     * CachePut[] put() default {};        //声明多个@CachePut
     * CacheEvict[] evict() default {};    //声明多个@CacheEvict
     * 插入用户
     */
    @Caching(put = {@CachePut(key = "#user.id")})
    @Override
    public User saveUser(User user) {
        logger.info("插入用户: {}", user.getUsername());
        return user;
    }

    /**
     * --@Cacheable注解会先查询是否已经有缓存，有会使用缓存，没有则会执行方法并缓存
     * 命名空间:@Cacheable的value会替换@CacheConfig的cacheNames(两者必须有一个)
     * --key是[命名空间]::[@Cacheable的key或者KeyGenerator生成的key](@Cacheable的key优先级高,KeyGenerator不配置走默认KeyGenerator SimpleKey [])
     * 使用 sync = true保证只有一个线程访问数据库，避免缓存击穿 ，注意sync = true不能与unless="#result == null"一起使用
     */
    @Cacheable(key = "#userId", sync = true)
    @Override
    public User findUser(Long userId) {
        logger.info("查找用户: {}", userId);
        return null;
    }

    /**
     * --@CachePut注解的作用 主要针对方法配置，能够根据方法的请求参数对其结果进行缓存，
     * 和 @Cacheable 不同的是，它每次都会触发真实方法的调用
     * 简单来说就是用户更新缓存数据。但需要注意的是该注解的value 和 key 必须与要更新的缓存相同，也就是与@Cacheable 相同
     * 默认先执行数据库更新再执行缓存更新
     * 注意返回值必须是要修改后的数据
     */
    @Override
    @CachePut(key = "#user.id")
    public User updateUser(User user) {
        logger.info("更新用户：{}", user.getId());
        return user;
    }

    @Override
    @CacheEvict(key = "#userId")
    public User deleteById(Long userId) {
        logger.info("删除用户：{}", userId);
        return null;
    }

    /**
     * --@CachEvict 的作用 主要针对方法配置，能够根据一定的条件对缓存进行清空
     * 触发缓存清除
     * 默认先执行数据库删除再执行缓存删除
     */
    @Override
    @CacheEvict(allEntries = true)
    public void clear() {
        logger.info("清除所有");
    }

}

```

#### 使用CacheManager

注解方式适合逻辑不是很复杂的情况，当业务逻辑需要更加灵活的控制缓存处理时，可使用CacheManager来管理

```java
@Service("cacheManagerUserService")
public class CacheManagerUserService implements UserService {

    private final Logger logger = LoggerFactory.getLogger(getClass());

    @Autowired
    private CacheManager cacheManager;

    @Override
    public User saveUser(User user) {
        getUserCache().put(user.getId(), user);
        logger.info("保存用户: {}", user);
        return user;
    }

    @Override
    public User findUser(Long userId) {
        return getUserCache().get(userId, User.class);
    }

    @Override
    public User updateUser(User user) {
        getUserCache().put(user.getId(), user);
        return user;
    }

    @Override
    public User deleteById(Long userId) {
        getUserCache().evict(userId);
        return null;
    }

    @Override
    public void clear() {
        getUserCache().clear();
    }

    private Cache getUserCache() {
        return cacheManager.getCache("user");
    }
}

```


#### 通过@RedisHash注解存储实体到redis

参考[Introduction to Spring Data Redis](https://www.baeldung.com/spring-data-redis-tutorial) 可以像其他数据库一样继承CrudRepository来操作对象

如果需要将某个属性标识为唯一id，添加@Id注解即可

如果需要在redis存储中拥有生命周期，添加@TimeToLive注解；以秒为单位，可根据需要设置其失效时间: 

```java
@RedisHash("Student")
public class Student implements Serializable {

    @Id
    private String id;
    private String name;
    private Gender gender;
    private int grade;

    /**
     * 以秒为单位，失效时间
     */
    @TimeToLive
    private Long time;

    public enum Gender {
        MALE, FEMALE
    }

    //.......

}
```

当然如果对一个类想要整体设置过期时间，可以使用@RedisHash(value = "Student", timeToLive = 20L)


#### 直接使用RedisTemplate

当然如果直接使用RedisTemplate也是可以的，不过需要注意的是一旦直接使用了RedisTemplate，则cacheManager相关的配置将不会生效，包含CachingConfigurerSupport相关的也不会生效，如发生异常时将不会回调CacheErrorHandler

```java
@Service("redisTemplateUserService")
public class RedisTemplateUserService implements UserService {

    private final Logger logger = LoggerFactory.getLogger(getClass());

    public final String PREFIX_CACHE_REDIS_KEY_USER = "spring-redis:user:";

    @Autowired
    RedisTemplate<String, User> userRedisTemplate;

    @Override
    public User saveUser(User user) {
        userRedisTemplate.opsForValue().set(getRealKeyById(user.getId()), user);
        return null;
    }

    @Override
    public User findUser(Long userId) {
        return userRedisTemplate.opsForValue().get(getRealKeyById(userId));
    }

    @Override
    public User updateUser(User user) {
        userRedisTemplate.opsForValue().set(getRealKeyById(user.getId()), user);
        return null;
    }

    @Override
    public User deleteById(Long userId) {
        Boolean result = userRedisTemplate.delete(getRealKeyById(userId));
        logger.info("删除结果: {}", result);
        return null;
    }

    @Override
    public void clear() {
        Set<String> keys = userRedisTemplate.keys(PREFIX_CACHE_REDIS_KEY_USER + "*");
        if (keys != null) {
            userRedisTemplate.delete(keys);
        }
    }

    /**
     * 获取真实key
     *
     * @param userId
     * @return
     */
    private String getRealKeyById(Long userId) {
        return PREFIX_CACHE_REDIS_KEY_USER + userId;
    }
}

```

> key需要自己定义前缀，当然之间使用RedisTemplate可以直接控制更加底层的api

## 分布式锁实现

单机情况下使用jvm提供的锁机制即可
- 方式一: 直接在方法上加上synchronized(或者在关键代码上使用)，缺点购买多个商品时效率会较低(当然因为java8对于synchronized做了很多优化，效率也不会有多差相较于lock)
- 方式二: 使用lock, 缺点如果逻辑上出现异常(未捕获的)导致锁未及时释放的话，会导致后面的请求都会由于获取不到锁而失败，一个商品抢购还好，如果好多商品，会因为某一个异常导致所有商品都失败
- 方式三(推荐)：使用ConcurrentHashMap，一个商品一个锁(或者一段数量一个锁)，这样可以在某个商品秒杀出现异常时，不影响其他商品

> 如果是单机环境的话，使用ConcurrentHashMap是不错的选择，不过如果是集群情况下(部署到多个服务器上)，使用jvm的锁机制就满足不了需求了

### 使用redis实现

可参考[使用 Spring Boot AOP 实现 Web 日志处理和分布式锁](https://developer.ibm.com/zh/articles/j-spring-boot-aop-web-log-processing-and-distributed-locking/)

```java
@Component
public class RedisLockUtils {

    @Autowired
    RedisTemplate<String, Object> redisTemplate;

    private final Logger logger = LoggerFactory.getLogger(getClass());

    public String getLock(String key, long timeout, TimeUnit timeUnit) {
        try {
            String value = UUID.randomUUID().toString();
            Boolean lockStat = redisTemplate.execute((RedisCallback< Boolean>) connection ->
                    connection.set(key.getBytes(StandardCharsets.UTF_8), value.getBytes(StandardCharsets.UTF_8),
                            Expiration.from(timeout, timeUnit), RedisStringCommands.SetOption.SET_IF_ABSENT));
            if (!lockStat) {
                // 获取锁失败。
                return null;
            }
            return value;
        } catch (Exception e) {
            logger.error("获取分布式锁失败，key={}", key, e);
            return null;
        }
    }

    public void unLock(String key, String value) {
        try {
            String script = "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end";
            boolean unLockStat = redisTemplate.execute((RedisCallback< Boolean>)connection ->
                    connection.eval(script.getBytes(), ReturnType.BOOLEAN, 1,
                            key.getBytes(StandardCharsets.UTF_8), value.getBytes(StandardCharsets.UTF_8)));
            if (!unLockStat) {
                logger.error("释放分布式锁失败，key={}，已自动超时，其他线程可能已经重新获取锁", key);
            }
        } catch (Exception e) {
            logger.error("释放分布式锁失败，key={}", key, e);
        }
    }

}

```

### 使用redisson

使用redis做分布式锁时容易发生死锁等未知情况，实际项目还是推荐使用[redisson](https://redisson.pro/) 来实现 分布式分段锁

pom.xml中引入

```xml
<dependencies>
    <dependency>
        <groupId>org.redisson</groupId>
        <artifactId>redisson-spring-boot-starter</artifactId>
        <version>3.14.0</version>
        <exclusions>
            <exclusion>
                <groupId>org.redisson</groupId>
                <artifactId>redisson-spring-data-23</artifactId>
            </exclusion>
        </exclusions>
    </dependency>
    <dependency>
        <groupId>org.redisson</groupId>
        <artifactId>redisson-spring-data-24</artifactId>
        <version>3.14.0</version>
    </dependency>
</dependencies>

```

> redisson-spring-data-24, 取决于项目中使用的SpringBoot版本，因为我使用了SpringBoot 2.4.2，故引用24，而redisson-spring-boot-starter的3.14.0版本默认引用的是23，故需排除

resource下新建redisson-single.yml(单机版):

```yaml
ngleServerConfig:
  # 连接空闲超时，单位：毫秒
  idleConnectionTimeout: 10000
  # 连接超时，单位：毫秒
  connectTimeout: 10000
  # 命令等待超时，单位：毫秒
  timeout: 3000
  # 命令失败重试次数,如果尝试达到 retryAttempts（命令失败重试次数） 仍然不能将命令发送至某个指定的节点时，将抛出错误。
  # 如果尝试在此限制之内发送成功，则开始启用 timeout（命令等待超时） 计时。
  retryAttempts: 3
  # 命令重试发送时间间隔，单位：毫秒
  retryInterval: 1500
  #  # 重新连接时间间隔，单位：毫秒
  #  reconnectionTimeout: 3000
  #  # 执行失败最大次数
  #  failedAttempts: 3
  # 密码
  password:
  # 单个连接最大订阅数量
  subscriptionsPerConnection: 5
  # 客户端名称
  clientName: null
  #  # 节点地址
  address: "redis://127.0.0.1:6379"
  # 发布和订阅连接的最小空闲连接数
  subscriptionConnectionMinimumIdleSize: 1
  # 发布和订阅连接池大小
  subscriptionConnectionPoolSize: 50
  # 最小空闲连接数
  connectionMinimumIdleSize: 32
  # 连接池大小
  connectionPoolSize: 64
  # 数据库编号
  database: 2
  # DNS监测时间间隔，单位：毫秒
  dnsMonitoringInterval: 5000
# 线程池数量,默认值: 当前处理核数量 * 2
threads: 0
# Netty线程池数量,默认值: 当前处理核数量 * 2
nettyThreads: 0
# 编码
codec: !<org.redisson.codec.JsonJacksonCodec> {}
# 传输模式
transportMode : "NIO"
```

在application.yml中加入:

```yaml
spring:
  ## Redis 配置
  redis:

    # redisson相关配置, 会导致redis原有配置失效，使用时需注意
    redisson:
      file: "classpath:redisson-single.yml"
```

> 这样的好处在于，不想引用redisson的话，只要去除pom中的引用并去除spring.redis.redisson配置即可

即可使用RedissonClient获取分布式锁:

```java
@Service
class TestService {
    
    @Autowired(required = false)
    private RedissonClient redissonClient;

    private boolean buyWithRedissonLock(Long productId) {
        if(redissonClient == null) {
            logger.error("未配置RedissonClient");
            return false;
        }
        String key = "xxx_lock_" + productId;
        RLock lock = redissonClient.getLock(key);
        try {
            if(lock.tryLock(2, TimeUnit.SECONDS)) {
                return normalBuy(productId);
            }
            logger.error("获取不到锁");
            return false;
        } catch (Exception e) {
            e.printStackTrace();
            logger.error("获取锁异常", e);
            return false;
        } finally {
            lock.unlock();
        }
    }
}
```

> 再进阶的话就可以再封装一层读写锁

> 另外redis和redisson也支持发布和订阅的功能convertAndSend，有兴趣可以了解下

# 注意要点

缓存的处理策略一般是：前台请求，后台先从缓存中取数据，取到直接返回结果，取不到时从数据库中取，数据库取到更新缓存，并返回结果，数据库也没取到，那直接返回空结果。所以可能就会存在以下问题:

## 缓存穿透

缓存穿透是指缓存和数据库中都没有的数据，而用户不断发起请求，如发起为id为“-1”的数据或id为特别大不存在的数据。这时的用户很可能是攻击者，攻击会导致数据库压力过大

**如何解决？**

- 接口层增加校验，如用户鉴权校验，id做基础校验，id<=0的直接拦截
- 从缓存取不到的数据，在数据库中也没有取到，这时也可以将key-value对写为key-null，缓存有效时间可以设置短点，如30秒（设置太长会导致正常情况也没法使用）。这样可以防止攻击用户反复用同一个id暴力攻击
- 加一层布隆过滤器

> 当然一般情况下，在接口层增加校验即可，真正业务发展大了，存在攻击了，所采取的策略不会这么简单

## 缓存击穿

缓存击穿是指缓存中没有但数据库中有的数据(一般是缓存时间到期)，这时由于并发用户特别多，同时读缓存没读到数据，又同时去数据库去取数据，引起数据库压力瞬间增大，造成过大压力

**如何解决？**

- 加锁
- 将过期时间组合写在value中，通过异步的方式不断的刷新过期时间，防止此类现象
- 设置热点数据永远不过期

```
//使用lock解决缓存击穿问题(粗颗粒度锁)
private Lock lock = new ReentrantLock();

//使用ConcurrentHashMap解决缓存击穿问题(细颗粒度锁-推荐)
private ConcurrentHashMap<String, Lock> lockConcurrentHashMap = new ConcurrentHashMap<>();
```
## 缓存雪崩

缓存雪崩是指缓存中数据大批量到过期时间，而查询数据量巨大，引起数据库压力过大甚至down机。和缓存击穿不同的是，缓存击穿指并发查同一条数据，缓存雪崩是不同数据都过期了，很多数据都查不到从而查数据库

**如何解决？**

- 针对不同key设置不同的过期时间，过期时间设置随机，防止同一时间大量数据过期现象发生。
- 限流，如果redis宕机，可以限流，避免同时刻大量请求打崩DB
- 如果缓存数据库是**分布式部署**，将热点数据均匀分布在不同搞得缓存数据库中。
- 加入二级缓存，提前加载热key数据到内存中，如果redis宕机，走内存查询
- 设置热点数据永远不过期

# 进阶: Redis部署模式

## standalone(单机)模式

部署在一台服务器中，并发需求不太高时

## master/slaver(主从复制)模式

部署在多台服务器中，一个主节点，多个从节点

**优点**

- 数据备份: 当一个节点损坏（指不可恢复的硬件损坏）时，数据因为有备份，可以方便恢复

- 负载均衡：所有客户端都访问一个节点肯定会影响Redis工作效率，有了主从以后，可做读写分离，查询操作就可以通过查询从节点来完成

**缺点**

master节点挂了以后，redis就不能对外提供写服务了，因为剩下的slave不能成为master

### 搭建方式

这里就演示windows docker desktop下的搭建方式, 以下命令都用cmd或者powerShell

1. 拉取最新redis镜像 ```docker pull redis```

2. 从官方下载最新的redis, 找到redis.conf文件，拷贝到本地某个文件夹下，如：D:\env\docker\redis\config\redis.conf

3. 配置并运行主服务器

redis.conf中找到下面的配置并修改:

```
# bind 127.0.0.1
requirepass 123456 #给redis设置密码
appendonly yes #redis持久化　　默认是no

dir /usr/local/etc/redis/redis-master/data/ #db等相关目录位置(根据自己需要配置)
```
> bind配置可以修改为bind 0.0.0.0, 或者指定ip, 或者直接注释掉(这里我们选择直接注释掉，允许所有来自于可用网络接口的连接)，appendonly开启后，Redis会把每次写入的数据在接收后都写入appendonly.aof文件，每次启动时Redis都会先把这个文件的数据读入内存里

实际项目中可能还需要记录日志，可配置logfile并映射本地文件即可

```shell
docker run --name redis -p 6379:6379 -v /d/env/docker/redis/conf/redis.conf:/usr/local/etc/redis/redis-master/redis.conf -v /d/env/docker/redis/data/:/usr/local/etc/redis/redis-master/data/ -d redis redis-server /usr/local/etc/redis/redis-master/redis.conf
```

> #docker run -p <容器端口>:<主机端口> --name <容器名> -v <本地配置文件映射容器配置文件> -v <本地文件夹挂载到容器文件夹> -d(表示以守护进程方式启动容器) <启动redis服务并制定配置文件(容器中的路径)>

4. 使用Redis Desktop Manager测试是否连接成功

5. 配置从服务器1，拷贝新的redis.conf并重命名为redis-slave-1.conf，找到下面的配置并编辑:

```
port 6380
# bind 127.0.0.1
requirepass 123456 #给redis设置密码
appendonly yes #redis持久化　　默认是no

masterauth 123456 #主服务器密码
# replicaof <master ip> <master port>
replicaof 192.168.31.13 6379 #Redis主机(Master)IP 端口
```

> replicaof为主服务器的ip+端口(在redis5.x的主从配置中，从机配置要配置 replicaof 参数。而早期版本，要配置的是slaveof参数)，如果主服务器设置了密码则需配置masterauth

6. 运行从服务器1

```shell
docker run --name redis-slave-1 -p 6380:6380 -v /d/env/docker/redis/conf/redis-slave-1.conf:/usr/local/etc/redis/redis-slave-1/redis.conf -d redis redis-server /usr/local/etc/redis/redis-slave-1/redis.conf
```

7. 按照类似步骤配置并运行从服务器2

为了方便，直接拷贝redis-slave-1.conf并修改port即可

redis-slave-2.conf
```
port 6381
```

运行

```shell
docker run --name redis-slave-2 -p 6381:6381 -v /d/env/docker/redis/conf/redis-slave-2.conf:/usr/local/etc/redis/redis-slave-2/redis.conf -d redis redis-server /usr/local/etc/redis/redis-slave-2/redis.conf
```

以上便可以搭建1主2从的master/slaver(主从复制)模式, 通过向主服务器写入数据，两个从服务器即会自动同步数据

> 如果是本机dockers，可以在每个redis-xx.conf中修改,以便显示声明物理机的ip与port，如redis-slave-1.conf
```
replica-announce-ip 192.168.31.13 # 这里写自己的ip地址
replica-announce-port 6380 # 这里写绑定的redis服务端口
```


## sentinel(哨兵)模式

Sentinel 其实是运行在特殊模式下的 redis server, 部署在多台服务器中, 心跳机制+投票裁决，是建立在主从模式的基础上，这也是目前的**主流方案**, 可参考[官方文章-Redis Sentinel文档](https://redis.io/topics/sentinel)

**优点**

有效解决主从模式主库异常手动主从切换的问题

**缺点**

当数据量过大到一台服务器存放不下的情况时，主从模式或sentinel模式就不能满足需求了，这个时候需要对存储的数据进行分片，将数据存储到多个Redis实例中

### 搭建方式

先搭建1个主服务器和两个从服务器，搭建方式同上面的master/slaver(主从复制)模式，我们还是通过windows docker desktop的方式

> 由于 Sentinel 启动，故障切换，日志文件创建 等情况均需要修改配置文件，因此一定要给文件读写权限，因此启动前先 chmod 777 -R /data/redis/ 给所有文件夹配置好权限

下面再搭建1个哨兵

1. 哨兵1

从官方下载最新的redis, 找到sentinel.conf文件(windows版的是没有这个文件的，需要自己新建或者官网下载linux版本)，拷贝到本地某个文件夹下，如：D:\env\docker\redis\config\sentinel-1.conf

编辑文件

```
# 禁止保护模式
protected-mode no
# 配置监听的主服务器，这里sentinel monitor代表监控，mymaster代表服务器的名称，可以自定义，192.168.11.128代表监控的主服务器，6379代表端口，2代表只有两个或两个以上的哨兵认为主服务器不可用的时候，才会进行failover操作。
sentinel monitor mymaster 192.168.11.128 6379 1
# sentinel author-pass定义服务的密码，mymaster是服务名称，123456是Redis服务器密码
# sentinel auth-pass <master-name> <password>
sentinel auth-pass mymaster 123456
logfile "./sentinel_log.log"
```

运行

```shell
docker run --name sentinel-1 -p 26379:26379 -v  /d/env/docker/redis/conf/sentinel-1.conf:/usr/local/etc/redis/sentinel-1.conf -d redis redis-sentinel /usr/local/etc/redis/sentinel-1.conf
```



实际环境中对于哨兵也会有多个，一个哨兵进程对Redis服务器进行监控，可能会出现问题，为此，需要使用多个哨兵进行监控。各个哨兵之间还会进行监控，这样就形成了多哨兵模式

需先修改sentinel-1.conf中的sentinel monitor

```

# 配置监听的主服务器，这里sentinel monitor代表监控，mymaster代表服务器的名称，可以自定义，192.168.11.128代表监控的主服务器，6379代表端口，2代表只有两个或两个以上的哨兵认为主服务器不可用的时候，才会进行failover操作。
sentinel monitor mymaster 192.168.11.128 6379 2
```

2. 哨兵2
he
拷贝一份sentinel-1.conf, 重命名为sentinel-2.conf，修改端口号即可

```shell
port 26380
```

运行

```shell
docker run --name sentinel-2 -p 26380:26380 -v  /d/env/docker/redis/conf/sentinel-2.conf:/usr/local/etc/redis/sentinel-2.conf -d redis redis-sentinel /usr/local/etc/redis/sentinel-2.conf
```

3. 哨兵3

同样拷贝一份sentinel-1.conf, 重命名为sentinel-3.conf，修改端口号即可

```shell
port 26381
```

运行

```shell
docker run --name sentinel-3 -p 26381:26381 -v  /d/env/docker/redis/conf/sentinel-3.conf:/usr/local/etc/redis/sentinel-3.conf -d redis redis-sentinel /usr/local/etc/redis/sentinel-3.conf
```

如果指定了新的dir, 如

```
#Sentinel服务运行时使用的临时文件夹
dir /usr/local/etc/redis
```
则

```shell
docker run --name sentinel-3 -p 26384:26384  -v  /d/env/docker/redis/conf/sentinel-3.conf:/usr/local/etc/redis-sentinel/sentinel.conf  -v  /d/tmp:/usr/local/etc/redis -d redis redis-sentinel /usr/local/etc/redis-sentinel/sentinel.conf
```


> 注意启动的顺序: 首先是主机的Redis服务进程，然后启动从机的服务进程，最后启动3个哨兵的服务进程

测试

使用redis-cli –p 26379查看信息

![sentinel-info](sentinel-info.png)

关闭主服务器，等待30秒， 可以看到已经切换到某个从服务器中了

> > 如果是本机dockers，可以在每个sentinel-xx.conf中修改,以便显示声明物理机的ip与port，如sentinel-1.conf

```
sentinel announce-ip <ip> # 这里写自己的ip地址
sentinel announce-port <port> # 这里写绑定的redis-sentinel服务端口
```


### Springboot 整合哨兵模式

application.yml
```yaml
spring:
  redis:
    database: 0
    password: 12345
    sentinel:
      master: mymaster ## master 名称
      ## 哨兵节点的 ip和端口好，哨兵会托管主从的架构
      nodes: 127.0.0.1:26379
```

## cluster(集群)模式

部署在多台服务器中,3.0版本开始正式引入，cluster的出现是为了解决单机Redis容量有限的问题，将Redis的数据根据一定的规则分配到多台机器，可以理解为是哨兵和主从模式的结合体

> 这种模式适合数据量巨大的缓存要求，当数据量不是很大使用sentinel即可

[IBM开发者文章-了解 Redis 并在 Spring Boot 项目中使用 Redis](https://developer.ibm.com/zh/languages/java/articles/know-redis-and-use-it-in-springboot-projects/)


> Spring Boot 2.4.0「新增RedisCacheMetrics」：用于监控使用redis时的puts、gets、deletes以及缓存命中率等信息
此指标信息默认不开启，需你增加配置spring.cache.redis.enable-statistics = true

笔者使用了某云服务器部署了一些测试项目，结果竟然被爆出对外存在攻击行为，最后发现是被人攻占了redis的端口6379，所以**部署 redis 建议修改默认端口或者限制 IP 访问，开启密码认证功能，并使用强密码。**

[Redis vs MongoDB](https://www.baeldung.com/java-redis-mongodb)

[本文示例源码](https://github.com/jonesun/spring-boot-redis-demo)

# 面试常问

## Redis为什么快呢？

redis的速度非常的快，单机的redis就可以支撑每秒10几万的并发，相对于mysql来说，性能是mysql的几
十倍。速度快的原因主要有几点：
* 完全基于内存操作
* C语言实现，优化过的数据结构，基于几种基础的数据结构，redis做了大量的优化，性能极高
* 使用单线程，无上下文的切换成本
* 基于非阻塞的IO多路复用机制

## 那为什么Redis6.0之后又改用多线程呢?

redis使用多线程并非是完全摒弃单线程，redis还是使用单线程模型来处理客户端的请求，只是使用多线程
来处理数据的读写和协议解析，执行命令还是使用单线程。
  
这样做的目的是因为redis的性能瓶颈在于网络IO而非CPU，使用多线程能提升IO读写的效率，从而整体提
  高redis的性能。