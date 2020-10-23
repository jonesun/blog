---
title: java-时间
date: 2020-10-22 17:21:42
categories: [java]  
tags: [java]
---

# 前言

日常开发中必不可少要与时间打交道，而关于时间的处理网上有很多文章，下面基于大神的文章和我自己的理解对时间做一个整理

开始之前我们得先明确下一些概念，有助于后面程序代码得理解

- 时间：类似于**08:00**和**2020年10月1日12:00**，这个叫做时间，时间是一个相对得概念。在国内我们说得时间和国外得时间表示得就不一样，比如现在是2020年10月1日10:00，在美国芝加哥得话现在就是2020年09月30日21:00，所以一般需要说当地时间(本地时间)

- 时刻：时刻就是一个准确得时间，如现在我们和国外同时做了一个事情，如果以上帝得视角来看，那这个时间点就是可以确定得哪个时刻(程序里就是时间戳)

- 时区: 但我们不是上帝，我们对应得如果要准确得表示一个事情得时间，就得加上时区了。全球一共分为24个时区，伦敦所在的时区称为标准时区，其他时区按东／西偏移的小时区分，北京所在的时区是东八区

> 总结一下，如果要表示准确得时间，得这样说: 北京时间(东八区) 2020年10月1日12:00

下面我们就看下在Java中对于时间得处理

我们都知道Java8加入了LocalDateTime等基础类，改进了时间得运算处理，所以如果是新项目想都不要想，直接上java8+，如果是旧项目或者有引用库还是java7及以下得也有方法可以解决，但不管怎样，放弃Date或者Calendar从现在开始


> 新API的类型几乎全部是不变类型，可以在多线程情况下放心使用, 并且修正了旧API一些不合理的常量设计：

  - Month的范围用1~12表示1月到12月(再也不用记要不要加1减1了)
  - Week的范围用1~7表示周一到周日
  - 处理加减会自动调整日期，例如从2019-10-31减去1个月得到的结果是2019-09-30，因为9月没有31日

# 重要类

* LocalDateTime: 表示一个带日期得时间(LocalDateTime.now())

* LocalDate: 表示一个日期(不带时分秒得时间)

* LocalTime: 表示一个不带日期得时间

*当需要在程序上显示时就用到了*:

* DateTimeFormatter: 格式化显示时间

*当需要对时间进行计算时就用到了*：

* Duration: 两个LocalDateTime之间的差值(相差多少时间)，比如PT1235H10M30S，表示1235小时10分钟30秒
* Period：两个LocalDate之间的差值(相差多少天), 比如P1M21D，表示1个月21天

*当需要准确得表示时间时就得用到时区*：

* ZoneId: 仅表示时区
* ZonedDateTime: 带时区的时间(ZoneId+LocalDateTime)
  
*当需要表示时刻时就得用时间戳*：

* Instant: 用Instant.now()获取当前时间戳，比System.currentTimeMillis()多了一个更高精度的纳秒

```
//获取当前时间戳
Instant instant = Instant.now();
System.out.println("当前时间戳: " + instant.toEpochMilli());//与System.currentTimeMillis类似

//加一个时区组合成ZonedDateTime 默认东八区
ZonedDateTime zonedDateTime = instant.atZone(ZoneId.systemDefault());

//输出显示
System.out.println("北京时间: " + zonedDateTime.format(DateTimeFormatter.ISO_DATE));

//去掉时区显示时间
LocalDateTime localDateTime = zonedDateTime.toLocalDateTime();
System.out.println("当前时间: " + localDateTime.format(DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm:ss")));

//去掉日期
LocalTime localTime = localDateTime.toLocalTime();
System.out.println("当前时间: " + localTime.format(DateTimeFormatter.ofPattern("HH:mm:ss")));

//计算两个时间
LocalDateTime localDateTime1 = LocalDateTime.of(2000, 9, 1, 9, 20);
Duration duration = Duration.between(localDateTime1, localDateTime);
System.out.println("duration相差: " + duration);

//计算两个日期
Period period = Period.between(localDateTime1.toLocalDate(), localDateTime.toLocalDate());
System.out.println("period相差: " + period);
```

# 新老版本转换


LocalDateTime，ZoneId，Instant，ZonedDateTime和long都可以互相转换：

```
┌─────────────┐
│LocalDateTime│────┐
└─────────────┘    │    ┌─────────────┐
                   ├───>│ZonedDateTime│
┌─────────────┐    │    └─────────────┘
│   ZoneId    │────┘           ▲
└─────────────┘      ┌─────────┴─────────┐
                     │                   │
                     ▼                   ▼
              ┌─────────────┐     ┌─────────────┐
              │   Instant   │<───>│    long     │
              └─────────────┘     └─────────────┘
```
> 转换的时候，需要留意long类型以毫秒还是秒为单位即可

## 旧API转新API

```
//long -> Instance
Instant instant = Instant.ofEpochMilli(System.currentTimeMillis());

// Date -> Instant
Instant ins1 = new Date().toInstant();

// Calendar -> Instant
Calendar calendar = Calendar.getInstance();
Instant ins2 = Calendar.getInstance().toInstant();

//Instance + ZoneId -> ZonedDateTime
ZonedDateTime zonedDateTime = instant.atZone(ZoneId.systemDefault());
//注意，如果源数据是calendar，采用calendar中保存的时区
ZonedDateTime zdt = ins2.atZone(calendar.getTimeZone().toZoneId());


//ZonedDateTime -> LocalDateTime
LocalDateTime localDateTime = zonedDateTime.toLocalDateTime();
```

## 新API转旧API

```
// LocalDateTime -> ZonedDateTime -> long -> Date:
ZonedDateTime zdt = LocalDateTime.now().atZone(ZoneId.systemDefault());
long ts = zdt.toInstant().toEpochMilli();
Date date = new Date(ts);
System.out.println("date: " + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(date));

// LocalDateTime -> ZonedDateTime -> long -> Calendar:
Calendar calendar = Calendar.getInstance();
calendar.clear();
calendar.setTimeZone(TimeZone.getTimeZone(zdt.getZone().getId()));
calendar.setTimeInMillis(ts);
```

# SpringBoot中处理

> 以上配置针对于SpringBoot 2.x及以上版本

**推荐jackson, SpringBoot内置，既能处理json也能处理xml**故这里只讲jackson的处理，其他json库网上搜索即可

一般我们都会用json来作为前后台传递数据用的格式，LocalDateTime类型如果不处理话，直接传递客户端使用是不太方便的:

```
public class MyUser {

    private String name;

    private LocalDateTime createTime;

    private LocalDate localDate;

    private LocalTime localTime;

    private Date date;

    //getter setter
}

//json返回
{
  "createTime": "2020-10-23T05:47:07.670Z",
  "date": "2020-10-23T05:47:07.670Z",
  "localDate": "string",
  "localTime": {
    "hour": 0,
    "minute": 0,
    "nano": 0,
    "second": 0
  },
  "name": "string"
}
```

> ISO 8601规定的日期和时间分隔符是T

故需要作一些配置修改

* 如果是部分实体需要，直接在属性上加上@JsonFormat注解即可:

```
@JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
private LocalDateTime createTime;

@JsonFormat(pattern = "yyyy-MM-dd")
private LocalDate localDate;

@JsonFormat(pattern = "HH:mm:ss")
private LocalTime localTime;

@JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
private Date date;

//返回json
{
  "name": "jone",
  "createTime": "2020-10-23 13:50:48",
  "localDate": "2020-10-23",
  "localTime": "13:50:48",
  "date": "2020-10-23 05:50:48"
}
```

> 如果项目涉及到国内外，还需加上时区如：@JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss",timezone="GMT+8")

* 全局设置

```
@Configuration
public class JsonConfig {

    /**
     * DateTime格式化字符串
     */
    private static final String DEFAULT_DATETIME_PATTERN = "yyyy-MM-dd HH:mm:ss";

    /**
     * Date格式化字符串
     */
    private static final String DEFAULT_DATE_PATTERN = "yyyy-MM-dd";

    /**
     * Time格式化字符串
     */
    private static final String DEFAULT_TIME_PATTERN = "HH:mm:ss";

    @Bean
    public Jackson2ObjectMapperBuilderCustomizer jackson2ObjectMapperBuilderCustomizer() {
        return builder -> builder
                .serializerByType(LocalDateTime.class, new LocalDateTimeSerializer(DateTimeFormatter.ofPattern(DEFAULT_DATETIME_PATTERN)))
                .serializerByType(LocalDate.class, new LocalDateSerializer(DateTimeFormatter.ofPattern(DEFAULT_DATE_PATTERN)))
                .serializerByType(LocalTime.class, new LocalTimeSerializer(DateTimeFormatter.ofPattern(DEFAULT_TIME_PATTERN)))
                .serializerByType(Date.class, new DateSerializer(false, new SimpleDateFormat(DEFAULT_DATETIME_PATTERN)))
                .deserializerByType(LocalDateTime.class, new LocalDateTimeDeserializer(DateTimeFormatter.ofPattern(DEFAULT_DATETIME_PATTERN)))
                .deserializerByType(LocalDate.class, new LocalDateDeserializer(DateTimeFormatter.ofPattern(DEFAULT_DATE_PATTERN)))
                .deserializerByType(LocalTime.class, new LocalTimeDeserializer(DateTimeFormatter.ofPattern(DEFAULT_TIME_PATTERN)))
                .deserializerByType(Date.class, new DateDeserializers.DateDeserializer(DateDeserializers.DateDeserializer.instance, new SimpleDateFormat(DEFAULT_DATETIME_PATTERN), DEFAULT_DATETIME_PATTERN))
                ;
    }

}

```

将前端获取的时间转换为一个符合自定义格式的时间格式存储到数据库@DateTimeFormat

> 关于@JsonFormat与@DateTimeFormat的用法

@JsonFormat 是jackson提供的，@DateTimeFormat 由spring提供的

* 前端 传给 后端。
  - 当前端传来的是键值对，用@DateTimeFormat 规定接收的时间格式。
  - 当前端传来json串，后台用@ReuqestBody接收，用@JsonFormat 规定接收的时间格式。
* 后端 传给 前端。
  - 后端返回给前端的时间值，只能用@JsonFormat 规定返回格式，@DateTimeFormat 无法决定返回值的格式。


# 数据库相关处理

数据库 | 对应Java类（旧） | 对应Java类（新）
---|---|---
DATETIME | java.util.Date | LocalDateTime
DATE | java.sql.Date | LocalDate
TIME | java.sql.Time | LocalTime
TIMESTAMP | java.sql.Timestamp | LocalDateTime

> DATETIME与TIMESTAMP区别：datetime的存储范围是 1000-01-01 00:00:00.000000 到 9999-12-31 23:59:59.999999，而timestamp的范围是 1970-01-01 00:00:01.000000到 2038-01-19 03:14:07.999999

> 新系统最好使用DATETIME，因为TIMESTAMP存储了不在范围内的时间值时，会直接抛出异常

> 还有一种建议即直接用long表示，在数据库中存储为BIGINT类型, 显示的时候再转换

## Mybatis

由于日常开发Mybatis用的比较多，故只讲下Mybatis下的用法，JPA的有兴趣可以自行搜索下

首先检查下项目中引用的Mybatis版本，当然所有的第三方库配合SpringBoot的话，优先看是否存在xxx-spring-boot-starter或者xxx-starter(珍惜时间，远离加班)

如果是新项目建议使用最新版本，如目前我使用的是:

```
<dependency>
    <groupId>org.mybatis.spring.boot</groupId>
    <artifactId>mybatis-spring-boot-starter</artifactId>
    <version>2.1.3</version>
</dependency>

//此版本引用的mybatis版本是3.5.3
```
MyBatis从3.4.5版本开始就完全支持了LocalDateTime, 如果使用的是旧版本请升级下，如果是由于三方库使用的mybatis版本较低，可以排除内嵌的引用，单独引用新版本


# 旧系统处理

当项目无法升级到Java8+环境的，也无需担心，可以使用**Joda-Time**这个库，值得一提的是，Joda-Time的作者Stephen Colebourne和Oracle一起共同参与了java8新的API的设计和实现，用法上基本同Java8一致

当然Joda-Time也有一些功能(如用来表示一对时间的Interval)是java8还没支持的，所以Stephen Colebourne又提供了一个新的第三方库**Threeten**来弥补Java 8的不足

Threeten主要提供两种发行包：
- ThreeTen-Backport：对Java 6和Java 7的项目提供Java 8的date-time类的支持
- ThreeTen-Extra：为Java 8的date-time类提供额外的增强功能（比如：Interval等）

# Android项目

> Android到棉花糖上运行在Java 7("Android N"是第一个引入Java 8语言特性的版本)。因此，除非你只针对Android NoGuAT和以上，否则你不能依赖Java 8语言特性

因为Android项目对于内存要求较高，Joda-Time不是最好的选择，ThreeTen-Backport也存在一些性能问题(使用JAR资源加载时区信息)，这个时候Android界的大神**jakewharton**提供了[threetenabp](https://github.com/JakeWharton/ThreeTenABP), 他的github上也说明了为什么不推荐使用Joda-Time和ThreeTen-Backport

所以如果你的Android项目需兼容老版本(现在还有需要兼容4.4-的):

- 在app/build.gradle中引用threetenabp

```
implementation 'com.jakewharton.threetenabp:threetenabp:1.2.4'
```

- 在Application.onCreate()方法中初始化时区信息：

```
@Override public void onCreate() {
  super.onCreate();
  AndroidThreeTen.init(this);
}
```
就可以愉快的使用LocalDateTime等新类了

# Date及Calendar不便之处

前面说了Java8+的新api，下面我们说一说旧的Date及Calendar的不便之处，以便放弃

* 首先就是获取年月日的时候的加减1了

```
System.out.println(date.getYear() + 1900); // 必须加上1900
System.out.println(date.getMonth() + 1); // 0~11，必须加上1
System.out.println(date.getDate()); // 1~31，不能加1

```

* Date不能直接转换时区，并且总是以当前计算机系统的默认时区为基础进行输出(Date对象无时区信息，时区信息存储在SimpleDateFormat中)

* 相比较locaDateTime丰富的时间处理(获取前一天，两个时间差等)，Date需要额外编写DateUtils(网上各种搜索,还不一定正确)
  
Calendar可以用于获取并设置年、月、日、时、分、秒，多了可以做简单的日期和时间运算的功能，但是:

* Calendar只有一种方式获取，即Calendar.getInstance()，而且一获取到就是当前时间。如果我们想给它设置成特定的一个日期和时间，就必须先清除所有字段

* Calendar获取年月日这些信息变成了get(int field)，返回的年份不必转换，返回的月份仍然要加1，返回的星期要特别注意，1~7分别表示周日，周一，……，周六。

* 最后就是常见的多线程安全的问题了, SimpleDateFormat线程不安全(原因网上自行搜索下)