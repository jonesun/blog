---
title: java设计模式-观察者模式
categories:
  - java
  - designPatterns
tags:
  - java
  - designPatterns
abbrlink: 8603fba1
date: 2020-11-03 11:47:39
---

# 前言

> 定义对象间的一种一对多的依赖关系，当一个对象的状态发生改变时，所有依赖于它的对象都得到通知并被自动更新。

观察者模式(Observer): 又称发布-订阅模式（Publish-Subscribe：Pub/Sub）。它是一种通知机制，让发送通知的一方（被观察方）和接收通知的一方（观察者）能彼此分离，互不影响。

Java标准库虽然提供了java.util.Observer和java.util.Observable这两个类用于实现观察者模式，但是Java9开始已经废弃java.util.Observer和java.util.Observable这两个类, 实现观察者模式的时候不推荐使用:

> 此类和Observer接口已被弃用。 Observer和Observable支持的事件模型非常有限，Observable传递的通知顺序未指定，并且状态更改与通知不一一对应。 对于更丰富的事件模型，请考虑使用java.beans包。 为了在线程之间进行可靠且有序的消息传递，请考虑使用java.util.concurrent包中的并发数据结构之一。 有关反应式流样式的编程，请参阅Flow API。

 <!-- more -->

# 实现

## java.bean实现

从java.beans包使用PropertyChangeEvent和PropertyChangeListener(Listeners，类型很多，它们都有回调方法，不需要强制转换)

### PropertyChangeSupport

* addPropertyChangeListener(PropertyChangeListener listener)
顾名思义，添加对bean的监听。
* removePropertyChangeListener(PropertyChangeListener listener)
移除监听。
* firePropertyChange(String propertyName, int oldValue, int newValue)
添加对bean内某个变量的监听，第一个参数最好是变量名，第二个是变量改变前的值，第二个是变量改变后的值

### PropertyChangeEvent

* getPropertyName() 获取发生改变的变量名。
* getSource() 获取改变的bean对象
* getOldValue() 获取发生改变的变量的旧值。
* getNewValue() 获取发生改变的变量的新值

> 当bean很多的时候特别好用，用propertyChangeEvent.getSource()就能区分是哪个bean

```java
public class Product {

    private Integer id;
    private String name;

    private final PropertyChangeSupport propertyChangeSupport = new PropertyChangeSupport(this);

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        Integer oldValue = this.id;
        this.id = id;
        // Fires a property change event
        propertyChangeSupport.firePropertyChange("id", oldValue, id);
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        String oldValue = this.name;
        this.name = name;
        // Fires a property change event
        propertyChangeSupport.firePropertyChange("name", oldValue, name);
    }

    public PropertyChangeSupport getPropertyChangeSupport() {
        return propertyChangeSupport;
    }
}


public class ObserverTest {

    public static void main(String[] args) {

        Product product = new Product();

        product.getPropertyChangeSupport().addPropertyChangeListener(evt ->
                System.out.println("发生了变化: " + evt.getPropertyName() + " 旧值: " + evt.getOldValue() + " 新值: " + evt.getNewValue())
        );

        //也可以直接值监听某个熟悉
        product.getPropertyChangeSupport().addPropertyChangeListener("name", evt -> {
            System.out.println("name发生了变化: " + evt.getPropertyName() + " 旧值: " + evt.getOldValue() + " 新值: " + evt.getNewValue());
        });

        product.setId(1);
        product.setName("admin");
        product.setName("user1");
    }

}

//输出打印
//发生了变化: id 旧值: null 新值: 1
//发生了变化: name 旧值: null 新值: admin
//name发生了变化: name 旧值: null 新值: admin
//发生了变化: name 旧值: admin 新值: user1
//name发生了变化: name 旧值: admin 新值: user1
```

> 需要注意的是初次赋值时oldvalue是null，记得判空，否则会导致后续监听失败

## Flow实现

Java9提供了java.util.concurrent.Flow(熟悉RxJava库的朋友对于这种用法应该非常熟悉)

Flow是一类在Java中9中引入并具有4个相互关联的接口：

* Publisher：发布者，负责发布消息；
* Subscriber：订阅者，负责订阅处理消息；
* Subscription：订阅控制类，可用于发布者和订阅者之间通信；
* Processor：处理者，同时充当Publisher和Subscriber的角色

Flow类还包含defaultBufferSize()静态方法，它返回发布者和订阅者使用的缓冲区的默认大小。 目前，它返回256。

> 另外还有SubmissionPublisher<T>类是Flow.Publisher<T>接口的实现类。 该类实现了AutoCloseable接口，因此可以使用try-with-resources块来管理其实例。 SubmissionPublisher<T>是Flow.Publisher<T>的实现，她可以灵活的生产数据，同时与Reactive Stream兼容:

```
SubmissionPublisher()
SubmissionPublisher(Executor executor, int maxBufferCapacity)
SubmissionPublisher(Executor executor, int maxBufferCapacity, BiConsumer<? super Flow.Subscriber<? super T>,? super Throwable> handler)
```

```
//简单的例子
 SubmissionPublisher<String> publisher = new SubmissionPublisher<>();

        publisher.subscribe(new Flow.Subscriber<String>() {
            @Override
            public void onSubscribe(Flow.Subscription subscription) {
                logger.debug("onSubscribe");
                //反向控制获取数据个数
                subscription.request(10);
            }

            @Override
            public void onNext(String item) {
                logger.debug("onNext: " + item);
            }

            @Override
            public void onError(Throwable throwable) {
                logger.debug("onError: " + throwable);
            }

            @Override
            public void onComplete() {
                logger.debug("onComplete");
            }
        });

        // 发布单个数据
        publisher.submit("11111");

        //发布多个数据
        String[] items = {"1", "x", "2", "x", "3", "x"};
        Arrays.stream(items).forEach(publisher::submit);

        //关闭发布, 关闭publisher，没有该函数则Subscriber.onComplete()不会被调用
        publisher.close();
        try {
            TimeUnit.SECONDS.sleep(3);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

```

> 注意Flow是异步的流处理, 故可以结合线程池一起处理, 有关Flow的文章后续整理下(尽管Flow API允许程序员开始编写响应式程序，但是生态系统仍然需要发展)


## 自定义实现

当然也可以自己来实现，不过需要注意的是:
* 如果设计成各个观察者是依次获得的同步通知，如果上一个观察者处理太慢，会导致下一个观察者不能及时获得通知
* 如果观察者在处理通知的时候，发生了异常，还需要被观察者处理异常，才能保证继续通知下一个观察者

**注意实际使用观察者模式需关注背压问题(即消费速度赶不上生产速度)**

# Spring中使用

如果是使用的Spring框架，推荐直接使用Spring中实现的观察者模式：

- 自定义需要发布的事件类，需要继承 ApplicationEvent 类或 PayloadApplicationEvent (该类也仅仅是对 ApplicationEvent 的一层封装)
- 使用 @EventListener 来监听事件或者实现 ApplicationListener 接口。
- 使用 ApplicationEventPublisher 来发布自定义事件（@Autowired注入即可）

## 示例

* 编写自定义事件

```java
import org.springframework.context.ApplicationEvent;

public class MyApplicationEvent extends ApplicationEvent {
    /**
     * Create a new {@code ApplicationEvent}.
     *
     * @param source the object on which the event initially occurred or with
     *               which the event is associated (never {@code null})
     */
    public MyApplicationEvent(Object source) {
        super(source);
    }
}

```

* 编写自定义listener, 收到事件后的处理

```java

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.ApplicationListener;

public class MyApplicationListener implements ApplicationListener<MyApplicationEvent> {

    private final Logger logger = LoggerFactory.getLogger(this.getClass());

    private String name;


    public MyApplicationListener(String name) {
        this.name = name;
    }

//    @Async
    @Override
    public void onApplicationEvent(MyApplicationEvent event) {
        String source = (String) event.getSource();
        logger.info("我是: {}, 收到更新数据为：{}s\n", this.name, source);
    }
}

```

* 模拟定义几个事件接收者

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ObserverConfiguration {
    
    @Bean
    public MyApplicationListener readerListener1(){
        return new MyApplicationListener("张三");
    }

    @Bean
    public MyApplicationListener readerListener2(){
        return new MyApplicationListener("李四");
    }

    @Bean
    public MyApplicationListener readerListener3(){
        return new MyApplicationListener("王五");
    }

}

```

* 编写测试代码

```java
@SpringBootTest
class SpringObserverTest extends AbstractJUnit4SpringContextTests {

    @Test
    void publishEventTest() {
        applicationContext.publishEvent(new MyApplicationEvent("Hello World"));
    }
}
```

运行测试用例，可以在控制台中看到打印了

```
我是: 张三, 收到更新数据为：Hello Worlds

我是: 李四, 收到更新数据为：Hello Worlds

我是: 王五, 收到更新数据为：Hello Worlds
```

如果业务逻辑中需要发送事件，可以实现ApplicationEventPublisherAware接口:

```java
@Service
public class UserService implements ApplicationEventPublisherAware { // <1>
    private Logger logger = LoggerFactory.getLogger(getClass());
    private ApplicationEventPublisher applicationEventPublisher;
    @Override
    public void setApplicationEventPublisher(ApplicationEventPublisher applicationEventPublisher) {
        this.applicationEventPublisher = applicationEventPublisher;
    }
    public void register(String username) {
        // ... 执行注册逻辑
        logger.info("[register][执行用户({}) 的注册逻辑]", username);
        // <2> ... 发布
        applicationEventPublisher.publishEvent(new UserRegisterEvent(this, username));
    }
}
```

> spring的事件驱动模型使用的是 观察者模式 ，Spring中Observer模式常用的地方是listener的实现。