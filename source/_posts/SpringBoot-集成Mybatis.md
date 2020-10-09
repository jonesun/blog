---
title: SpringBoot-集成Mybatis
date: 2020-09-29 15:43:05
categories: [java,springboot]
tags: [java, springboot]
---

# 简介


<!-- more -->

# 集成方式

## 引入

在pom.xml中加入
```
<!-- https://mvnrepository.com/artifact/org.mybatis.spring.boot/mybatis-spring-boot-starter -->
<dependency>
    <groupId>org.mybatis.spring.boot</groupId>
    <artifactId>mybatis-spring-boot-starter</artifactId>
    <version>2.1.3</version>
</dependency>

```

## 配置

application.yml中

```
spring:
  profiles:
    active: dev
```

application-dev.yml中

```
mybatis:
  type-aliases-package: com.xxx.entity
  mapper-locations: classpath*:mapper/**/*.xml
  configuration:
    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl
```

application-dev.yml：开发环境
application-test.yml：测试环境
application-prod.yml：生产环境

## 使用

可结合mybatis-plus生成基础sql，结合pagehelper实现分页

# 常用动态SQL标签

## if

只有判断条件为true才会执行其中的SQL语句

```
<update id="update" parameterType="com.jonesun.springredis.entity.User">
    UPDATE
    users
    SET
    <if test="username != null">username = #{username},</if>
    <if test="password != null">password = #{password},</if>
    nick_name = #{nickName}
    WHERE
    id = #{id}
</update>
```

当if中出现多个判断条件时, 使用and:

```
<update id="update" parameterType="com.jonesun.springredis.entity.User">
    UPDATE
    users
    SET
    <if test="username != null">username = #{username},</if>
    <if test="password != null and password !=''">password = #{password},</if>
    nick_name = #{nickName}
    WHERE
    id = #{id}
</update>
```

> XML中对大于＞、＜这种特殊字符串需要做转义处理:
```
<if test='id != null and id gt 28'></if>

大于：&gt;
小于：&lt;
大于等于：&gt;=
小于等于：&lt;=

sql中也可以使用  <![CDATA[ >= ]]>
```

## choose、when、otherwise

有时候，我们不想使用所有的条件，而只是想从多个条件中选择一个使用。针对这种情况，MyBatis 提供了 choose 元素，它有点像 Java 中的 switch 语句，choose 为 switch，when 为 case，otherwise 则为default:

```
 <select id="list" resultMap="defaultDetailMap">
    select
    users.*
    from users
    where
    <choose>
        <when test="sex == '男'">
            users.sex=0
        </when>
        <when test="sex == '女'">
            users.sex=1
        </when>
        <otherwise>
            users.sex IS NOT NULL
        </otherwise>
    </choose>
</select>
```

## where

where 元素只会在子元素返回任何内容的情况下才插入 WHERE 子句。而且，若子句的开头为 AND 或 OR，where 元素也会将它们去除:

当遇到如下场景，status恰好为空时，则会报错(where后面没有条件了): 

```
<select id="findActiveBlogLike" resultType="Blog">
  SELECT * FROM BLOG
  WHERE
  <if test="state != null">
    state = #{state}
  </if>
  <if test="title != null">
    AND title like #{title}
  </if>
  <if test="author != null and author.name != null">
    AND author_name like #{author.name}
  </if>
</select>
```

此时使用<where>可解决：

```
<select id="findActiveBlogLike"  resultType="Blog">
  SELECT * FROM BLOG
  <where>
    <if test="state != null">
         state = #{state}
    </if>
    <if test="title != null">
        AND title like #{title}
    </if>
    <if test="author != null and author.name != null">
        AND author_name like #{author.name}
    </if>
  </where>
</select>
```

## set

使用 set 标签可以将动态的配置 set 关键字，和剔除追加到条件末尾的任何不相关的逗号

当遇到如下场景，hobby恰好为空时，则会报错(最后会多一个,): 

```
<update id="updateStudent" parameterType="Object">
    UPDATE STUDENT    <set>
        <if test="name!=null and name!='' ">
            NAME = #{name},        </if>
        <if test="hobby!=null and hobby!='' ">
            MAJOR = #{major},        </if>
        <if test="hobby!=null and hobby!='' ">
            HOBBY = #{hobby}        </if>
    </set>
    WHERE ID = #{id};
</update>
```

此时使用<set>可解决：

```
<update id="updateStudent" parameterType="Object">
    UPDATE STUDENT    <set>
        <if test="name!=null and name!='' ">
            NAME = #{name},        </if>
        <if test="hobby!=null and hobby!='' ">
            MAJOR = #{major},        </if>
        <if test="hobby!=null and hobby!='' ">
            HOBBY = #{hobby}        </if>
    </set>
    WHERE ID = #{id};
</update>
```

## foreach

foreach是用来对集合的遍历，这个和Java中的功能很类似。通常处理SQL中的in语句

你可以将任何可迭代对象（如 List、Set 等）、Map 对象或者数组对象作为集合参数传递给 foreach。当使用可迭代对象或者数组时，index 是当前迭代的序号，item 的值是本次迭代获取到的元素。当使用 Map 对象（或者 Map.Entry 对象的集合）时，index 是键，item 是值：

```
<select id="list" resultMap="defaultDetailMap">
    select
    users.*
    from users
    where
    <choose>
        <when test="statusList != null">
            users.status IN
            <foreach item="item" index="index" collection="statusList" open="(" separator="," close=")">
                #{item}
            </foreach>
        </when>
        <otherwise>
            users.status IS NOT NULL
        </otherwise>
    </choose>
</select>
```

## sql

在实际开发中会遇到许多相同的SQL，比如根据某个条件筛选，这个筛选很多地方都能用到，我们可以将其抽取出来成为一个公用的部分，这样修改也方便，一旦出现了错误，只需要改这一处便能处处生效了，此时就用到了<sql>这个标签了

当多种类型的查询语句的查询字段或者查询条件相同时，可以将其定义为常量，方便调用。为求 <select> 结构清晰也可将 sql 语句分解

```
<!-- 查询字段 -->
<sql id="Base_Column_List">
    id,birthday,name,status</sql>
<!-- 查询条件 -->
<sql id="Example_Where_Clause">
    where 1=1    <trim suffixOverrides=",">
        <if test="id != null and id !=''">
            and id = #{id}        
        </if>
        <if test="birthday != null ">
            and birthday = #{birthday}        
        </if>
        <if test="name != null and name != ''">
            and NAME = #{name}        
        </if>
        <if test="status != null and status != ''">
            and status = #{status}       
        </if>
    </trim>
</sql>
```

## include

include用于引用sql标签定义的常量。比如引用上面sql标签定义的常量，如下:

```
<select id="selectAll" resultMap="BaseResultMap">
    SELECT    <include refid="Base_Column_List" />
    FROM student    <include refid="Example_Where_Clause" />
</select>
```

如果遇到resultMap或者<sql>片段已经在另外一个xxxMapper.xml中已经定义过了，此时当前的xml还需要用到，Mybatis中也是支持引用其他Mapper文件中的SQL片段的(类似于Java中的全类名):

```
<include refid="com.xxx.dao.xxMapper.Base_Column_List"></include>
```

> <select>标签中的resultMap同样可以这么引用

> 当遇到表字段冲突时，如users表和user_detail表都有status时，可在字段前加上表名:

<sql id="Base_Column_List">
    ID,MAJOR,BIRTHDAY,AGE,NAME,HOBBY,users.status</sql>

## 常量定义

开过阿里巴巴开发手册的大概都知道代码中是不允许出现魔数的，何为魔数？简单的说就是一个数字，一个只有你知道，别人不知道这个代表什么意思的数字。通常我们在Java代码中都会定义一个常量类专门定义这些数字。在Mybatis中同样可以使用(@+全类名+@+常量)：

```
<if test="type!=null and type==@com.xxx.core.Constants.CommonConstants@DOC_TYPE">
    -- ....获取医生的权限</if>
<if test="type!=null and type==@com.xxx.core.Constants.CommonConstants@NUR_TYPE">
    -- ....获取护士的权限</if>
```

> 除了调用常量类中的常量，还可以类中的方法

## 通过selectKey获取自定义列

假如有些数据库不支持自增主键，或者说我们想插入自定义的主键，而又不想在业务代码中编写逻辑，那么就可以通过MyBatis的selectKey来获取：

```
<insert id="insert2"  useGeneratedKeys="true" keyProperty="address">
    <selectKey keyProperty="address" resultType="String" order="BEFORE">
        select uuid() from lw_user_address
    </selectKey>
        insert into lw_user_address (address) values (#{address})
</insert>
```

selectKey中的order属性有2个选择：BEFORE和AFTER。

- BEFORE：表示先执行selectKey的语句，然后将查询到的值设置到JavaBean对应属性上，然后再执行insert语句。
- AFTER：表示先执行AFTER语句，然后再执行selectKey语句，并将selectKey得到的值设置到JavaBean中的属性。上面示例中如果改成AFTER，那么插入的address就会是空值，但是返回的JavaBean属性内会有值

> selectKey中返回的值只能有一条数据，如果满足条件的数据有多条会报错，所以一般都是用于生成主键，确保唯一，或者在selectKey后面的语句加上条件，确保唯一

## cache