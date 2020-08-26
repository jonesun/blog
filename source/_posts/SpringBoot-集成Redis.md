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

Redis 的应用场景包括：缓存系统（“热点”数据：高频读、低频写）、计数器、消息队列系统、排行榜、社交网络和实时系统。


<!-- more -->

# 集成方式

## 引入

在pom.xml中加入
```
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
```

> Springboot2以后，底层访问redis已经不再是jedis了，而是lettuce

- 使用jedis：当多线程使用同一个连接时，是线程不安全的。所以要使用连接池，为每个jedis实例分配一个连接。
- 使用Lettuce：当多线程使用同一连接实例时，是线程安全的。是采用netty连接redis server，实例可以在多个线程间共享，不存在线程不安全的情况，这样可以减少线程数量

所以如果要继续使用jedis的话需要改为:

```
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
```

> 推荐使用lettuce

## 配置

如果使用默认lettuce的话，直接在application.yml配置redis服务连接基本参数即可(spring-boot-starter-xx的好处之一):

```
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

```
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

```
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

```
@EnableCaching
@Configuration
public class CacheConfig extends CachingConfigurerSupport {

    /**
     * 自定义生成redis-key
     */
    @Override
    public KeyGenerator keyGenerator() {
        return (o, method, objects) -> {
            StringBuilder sb = new StringBuilder();
            sb.append(o.getClass().getName()).append(".");
            sb.append(method.getName()).append(".");
            for (Object obj : objects) {
                sb.append(obj.toString());
            }
            return sb.toString();
        };
    }

    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory redisConnectionFactory) {

        RedisTemplate<String, Object> redisTemplate = new RedisTemplate<>();
        redisTemplate.setKeySerializer(new StringRedisSerializer());
        redisTemplate.setConnectionFactory(redisConnectionFactory);

        Jackson2JsonRedisSerializer<Object> j2jrs = new Jackson2JsonRedisSerializer<>(Object.class);
        ObjectMapper om = new ObjectMapper();
        om.setVisibility(PropertyAccessor.ALL, JsonAutoDetect.Visibility.ANY);
        // 解决jackson2无法反序列化LocalDateTime的问题
        om.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        om.registerModule(new JavaTimeModule());
//        om.enableDefaultTyping(ObjectMapper.DefaultTyping.NON_FINAL, JsonTypeInfo.As.PROPERTY);
        om.activateDefaultTyping(LaissezFaireSubTypeValidator.instance,
                ObjectMapper.DefaultTyping.NON_FINAL, JsonTypeInfo.As.PROPERTY);
        j2jrs.setObjectMapper(om);
        // 序列化 value 时使用此序列化方法
        redisTemplate.setValueSerializer(j2jrs);
        redisTemplate.setHashValueSerializer(j2jrs);


        return redisTemplate;
    }

    @Bean
    public CacheManager cacheManager(RedisConnectionFactory redisConnectionFactory) {
        RedisCacheConfiguration cacheConfiguration = RedisCacheConfiguration
                .defaultCacheConfig()
//                .entryTtl(Duration.ofDays(1))
                .disableCachingNullValues()
                .computePrefixWith(cacheName -> "spring-redis".concat(":").concat(cacheName).concat(":"))
                .serializeValuesWith(RedisSerializationContext.SerializationPair.fromSerializer(new GenericJackson2JsonRedisSerializer()));

        Set<String> cacheNames = new HashSet<>();
        cacheNames.add("user");
        cacheNames.add("test");

        // 对每个缓存空间应用不同的配置
        Map<String, RedisCacheConfiguration> configMap = new HashMap<>();
        configMap.put("user", cacheConfiguration.entryTtl(Duration.ofSeconds(120)));
        configMap.put("test", cacheConfiguration.entryTtl(Duration.ofSeconds(2)));
        return RedisCacheManager.builder(redisConnectionFactory)
                .cacheDefaults(cacheConfiguration)
                .initialCacheNames(cacheNames)
                .withInitialCacheConfigurations(configMap)
                //在spring事务正常提交时才缓存数据
                .transactionAware()
                .build();
    }


}
```

### service中使用

> 注意推荐使用SpringCache中的注解和类，这样就算后期不使用redis，改用mongodb或者其他缓存中间件时，业务代码都不需要变更，这里体现了Java中的门面模式(外观模式)

- 注解使用

```
Service
@CacheConfig(cacheNames = "user")
public class UserServiceImpl implements UserService {

    private static final Logger logger = LoggerFactory.getLogger(UserServiceImpl.class);

    @Autowired
    UserDao userDao;

    /**
     * Cacheable[] cacheable() default {}; //声明多个@Cacheable
     * CachePut[] put() default {};        //声明多个@CachePut
     * CacheEvict[] evict() default {};    //声明多个@CacheEvict
     * 插入用户
     */
    @Caching(
            put = {
//                    @CachePut(key = "#user.id"),
                    @CachePut(key = "#user.username"),
                    @CachePut(value = "user1", key = "#user.username")
            }
    )
    @Override
    public User saveUser(User user) {
        System.out.println("插入用户..." + user.getUsername());
        userDao.insert(user);
        return user;
    }

    /**
     * --@Cacheable注解会先查询是否已经有缓存，有会使用缓存，没有则会执行方法并缓存
     * 命名空间:@Cacheable的value会替换@CacheConfig的cacheNames(两者必须有一个)
     * --key是[命名空间]::[@Cacheable的key或者KeyGenerator生成的key](@Cacheable的key优先级高,KeyGenerator不配置走默认KeyGenerator SimpleKey [])
     * 使用 sync = true保证只有一个线程访问数据库，避免缓存击穿 ，注意sync = true不能与unless="#result == null"一起使用
     */
    @Cacheable(key = "#username", sync = true)
    @Override
    public User findUser(String username) {
        //并发时，不加缓存，使用默认mybatis连接池HikariPool(springboot2默认使用HikariPool连接池) 会报错(Failed to obtain JDBC Connection; nested exception is java.sql.SQLTransientConnectionException: HikariPool-1 - Connection is not available, request timed out after 30007ms.)
        System.out.println("执行方法...");
        return userDao.getByUsername(username);
    }

    /**
     * --@CachePut注解的作用 主要针对方法配置，能够根据方法的请求参数对其结果进行缓存，
     * 和 @Cacheable 不同的是，它每次都会触发真实方法的调用
     * 简单来说就是用户更新缓存数据。但需要注意的是该注解的value 和 key 必须与要更新的缓存相同，也就是与@Cacheable 相同
     * 默认先执行数据库更新再执行缓存更新
     * 注意返回值必须是要修改后的数据
     */
    @Override
    @CachePut(key = "#user.username")
    public User updateUser(User user) {
        System.out.println("更新用户...：" + user.getUsername());
        userDao.update(user);
        return user;
    }

    /**
     * --@CachEvict 的作用 主要针对方法配置，能够根据一定的条件对缓存进行清空
     * 触发缓存清除
     * 默认先执行数据库删除再执行缓存删除
     */
    @Override
    @CacheEvict(allEntries = true)
    public void clearUsers() {
        System.out.println("清除缓存...");
        userDao.deleteAll();
    }

    @Cacheable(sync = true)
    @Override
    public Map<String, BigDecimal> sumMoneyGroupBySex() {
        //注意如果 此处获取的是缓存中的信息，则方法内部不会被执行到
        return userDao.sumMoneyGroupBySex();
    }

}

```

- 使用CacheManager

注解方式适合逻辑不是很复杂的情况，当业务逻辑需要更加灵活的控制缓存处理时，可使用CacheManager来管理

```
@Service
public class LockGoodsNumServiceImpl implements LockGoodsNumService {

    private final Logger logger = LoggerFactory.getLogger(this.getClass());

    private final String TEST_KEY = "goods-1";

    @Resource
    private CacheManager cacheManager;

    private Lock lock = new ReentrantLock();


    @Override
    public void initData(int num) {
        Cache goodsCache = getGoodsCache();
        goodsCache.put(TEST_KEY, num);
        logger.info("初始化成功: 库存数量为: " + goodsCache.get(TEST_KEY, Integer.class));
    }

    @Override
    public boolean buy() {
//        //非并发情况下
//        return normalBuy(getGoodsCache());

//        //单机并发-使用jvm锁
//        return withLock(getGoodsCache());
//
        //多台机器(分布式)并发-使用redis的key作为全局锁
        return withRedisLockKey(getGoodsCache());
    }

    private boolean normalBuy(Cache goodsCache) {
        //        synchronized (this) {
        Integer num = goodsCache.get(TEST_KEY, Integer.class);
        //操作原子性
        if (num != null && num > 0) {
            //购买
            num = num - 1;
            goodsCache.put(TEST_KEY, num);
            logger.info("购买成功，还剩: " + num);
            return true;
        } else {
            logger.error("购买失败，库存不足！");
            return false;
        }
    }

    /***
     * 使用JVM相关锁
     * @param goodsCache
     * @return
     */
    private boolean withLock(Cache goodsCache) {
        lock.lock();
        try {
            //        synchronized (this) {
            return normalBuy(goodsCache);
//        }
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        } finally {
            lock.unlock();
        }
    }

    /**
     * 使用redis的key作为lock锁
     *
     * @param goodsCache
     * @return
     */
    private boolean withRedisLockKey(Cache goodsCache) {
        String clientId = UUID.randomUUID().toString();
        final String lockName = "goods-lock";
        try {
            Cache.ValueWrapper result = goodsCache.putIfAbsent(lockName, clientId);
            //这里可以加入过期时间，防止较长时间未解锁
            if (result != null) {
                //说明该锁已存在
                logger.error("购买失败，请刷新后重试！");
                return false;
            }
            return normalBuy(goodsCache);
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        } finally {
            if (clientId.equals(goodsCache.get(lockName, String.class))) {
                goodsCache.evict(lockName);
            }
        }

    }

    private Cache getGoodsCache() {
        return cacheManager.getCache("goods");
    }
}
```

- 直接使用RedisTemplate

当然如果直接使用RedisTemplate也是可以的，不过一般不推荐

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

部署在多台服务器中, 心跳机制+投票裁决，是建立在主从模式的基础上，这也是目前的**主流方案**

**优点**

有效解决主从模式主库异常手动主从切换的问题

**缺点**

当数据量过大到一台服务器存放不下的情况时，主从模式或sentinel模式就不能满足需求了，这个时候需要对存储的数据进行分片，将数据存储到多个Redis实例中

## cluster(集群)模式

部署在多台服务器中,3.0版本开始正式引入，cluster的出现是为了解决单机Redis容量有限的问题，将Redis的数据根据一定的规则分配到多台机器，可以理解为是哨兵和主从模式的结合体

> 这种模式适合数据量巨大的缓存要求，当数据量不是很大使用sentinel即可


