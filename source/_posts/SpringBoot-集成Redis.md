---
title: SpringBoot-集成Redis
date: 2020-08-26 15:36:38
categories: [java,springboot]
tags: [java, springboot]
---

# Redis介绍

> Redis is an open source (BSD licensed), in-memory data structure store, used as a database, cache and message broker.

>  C语言开发的、开源的、基于内存的数据结构存储器，可以用作数据库、缓存和消息中间件

> 一种 NoSQL（not-only sql，泛指非关系型数据库）的数据库，性能优秀，数据在内存中，读写速度非常快，支持并发 10W QPS

[Redis](https://redis.io/) 的应用场景包括：缓存系统（“热点”数据：高频读、低频写）、计数器、消息队列系统、排行榜、社交网络和实时系统。

## 为什么要使用redis

> 性能

由于MySql数据存储在磁盘中，对于一些需要执行耗时非常长的，但结果不会频繁改动的SQL操作(经常是查询，如每日排行榜或者高频业务热数据)，就适合将运行结果放到到redis中。
后面的请求优先去redis中获取，加快访问速度、提高性能

> 并发

mysql支持并发访问的能力有限(当然现在一般会使用一些数据库连接池的来加强并发能力)，当有大量的并发请求，直接访问数据库的话，mysql会挂掉。所以可以使用redis作为缓冲，让请求先访问到redis，而不是直接访问数据库，提高系统的并发能力。

> 当然redis是基于内存的，存储容量肯定要比磁盘少很多，要存储大量数据，需升级内存，造成在一些不需要高性能的地方是相对比较浪费的，所以建议在需要性能的地方使用redis，在不需要高性能的地方使用mysql。不要一味的什么数据都丢到redis中。

<!-- more -->

# 集成方式

## 下载安装

### windows

截至2021年1月，官方也没提供windows版本的下载，如果是为了学习需要，可以到[MicrosoftArchive Github](https://github.com/MicrosoftArchive/redis/releases) 上下载(最后的更新时间为2016年)

下载后像常用的软件类似：双击redis-server.exe即可启动redis服务器, 可参考[Redis下载及安装(windows版)](https://www.cnblogs.com/xing-nb/p/12146449.html)

> 此版本对应的是redis的3.2.1版本，而目前redis已经发展到了6.x，故生产环境不建议使用，自己学习就好;
> 当然如果生产环境中的服务器恰好是windows的，小型项目使用也可以(毕竟没那么多并发量)，但还是建议使用下面的docker方式安装，使用较新的稳定版本

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

使用docker:

下载镜像
```
docker pull redis
```

运行

```
docker run --name my-redis -p 6379:6379 -d redis
```

其他定制配置可参考[hub.docker](https://hub.docker.com/_/redis/)

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

> 当然一般情况下，在接口层增加校验即可，真正业务发展大了，存在攻击了，所采取的策略不会这么简单

## 缓存击穿

缓存击穿是指缓存中没有但数据库中有的数据(一般是缓存时间到期)，这时由于并发用户特别多，同时读缓存没读到数据，又同时去数据库去取数据，引起数据库压力瞬间增大，造成过大压力

**如何解决？**

- 设置热点数据永远不过期
- 加锁

```
//使用lock解决缓存击穿问题(粗颗粒度锁)
private Lock lock = new ReentrantLock();

//使用ConcurrentHashMap解决缓存击穿问题(细颗粒度锁-推荐)
private ConcurrentHashMap<String, Lock> lockConcurrentHashMap = new ConcurrentHashMap<>();
```
## 缓存雪崩

缓存雪崩是指缓存中数据大批量到过期时间，而查询数据量巨大，引起数据库压力过大甚至down机。和缓存击穿不同的是，缓存击穿指并发查同一条数据，缓存雪崩是不同数据都过期了，很多数据都查不到从而查数据库

**如何解决？**

- 缓存数据的过期时间设置随机，防止同一时间大量数据过期现象发生。
- 如果缓存数据库是**分布式部署**，将热点数据均匀分布在不同搞得缓存数据库中。
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

## sentinel(哨兵)模式

部署在多台服务器中, 心跳机制+投票裁决，是建立在主从模式的基础上，这也是目前的**主流方案**, 可参考[官方文章-Redis Sentinel文档](https://redis.io/topics/sentinel)

**优点**

有效解决主从模式主库异常手动主从切换的问题

**缺点**

当数据量过大到一台服务器存放不下的情况时，主从模式或sentinel模式就不能满足需求了，这个时候需要对存储的数据进行分片，将数据存储到多个Redis实例中

## cluster(集群)模式

部署在多台服务器中,3.0版本开始正式引入，cluster的出现是为了解决单机Redis容量有限的问题，将Redis的数据根据一定的规则分配到多台机器，可以理解为是哨兵和主从模式的结合体

> 这种模式适合数据量巨大的缓存要求，当数据量不是很大使用sentinel即可

[IBM开发者文章-了解 Redis 并在 Spring Boot 项目中使用 Redis](https://developer.ibm.com/zh/languages/java/articles/know-redis-and-use-it-in-springboot-projects/)


> Spring Boot 2.4.0「新增RedisCacheMetrics」：用于监控使用redis时的puts、gets、deletes以及缓存命中率等信息
此指标信息默认不开启，需你增加配置spring.cache.redis.enable-statistics = true

[Redis vs MongoDB](https://www.baeldung.com/java-redis-mongodb)

[本文示例源码](https://github.com/jonesun/spring-boot-redis-demo)