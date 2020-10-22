---
title: java设计模式-代理模式
date: 2020-07-16 15:12:48
categories: [java, 设计模式]
tags: [java, 设计模式, 代理模式]
---

> 设计模式是为了可扩展性，不要为了使用设计模式而使用

# 概念

> 为其他对象提供一种代理以控制对这个对象的访问

代理模式包含如下角色：

- Subject:抽象主题角色。可以是接口，也可以是抽象类。
- RealSubject:真实主题角色。业务逻辑的具体执行者。
- ProxySubject:代理主题角色。内部含有RealSubject的引用,负责对真实角色的调用，并在真实主题角色处理前后做预处理和善后工作


# 使用场景

主要可以用于：日志记录，性能统计，安全控制，事务处理，异常处理等场景

 <!-- more -->

# 实现方式

## 静态代理

> 适合预先确定了代理与被代理者的关系，需要一个接口(表示要完成的功能)，一个真实对象和一个代理对象(两者都需实现这个接口)


```
//定义一个程序员接口
public interface ICoder {
    
    /***
     * 实现需求
     * @return 实现结果
     */
    Boolean implDemands(String demands);

}

//定义一个java程序员
public class JavaCoder implements ICoder {

    private final String name = "java程序员";

    @Override
    public Boolean implDemands(String demands) {
        System.out.println(String.format("%s收到需求[%s]", name, demands));
        System.out.println(String.format("%s需求[%s]实现完成", name, demands));
        return true;
    }

}

//定义一个项目经理
public class CoderProxy implements ICoder {

    private final String name = "项目经理";

    private final ICoder coder;

    public CoderProxy(ICoder coder) {
        this.coder = coder;
    }

    @Override
    public Boolean implDemands(String demands) {
        System.out.println(String.format("%s收到需求[%s]", name, demands));
        if(demands.contains("像淘宝")) {
            System.out.println(String.format("%s回复: [%s]无法实现", name, demands));
            return false;
        } else {
            Boolean result = coder.implDemands(demands);
            System.out.println(String.format("%s需求[%s]实现完成", name, demands));
            return result;
        }
    }

}

//客户提出需求
public class Customer {

    public static void main(String[] args) {
        //定义一个客户
        Customer customer = new Customer();

        //找到一个产品经理(底下一个java程序员)
        CoderProxy coderProxy = new CoderProxy(new JavaCoder());

        //提出需求

        customer.putDemands(coderProxy, "做个管理系统");
        System.out.println("--------------------------------------");
        customer.putDemands(coderProxy, "做个网站，像淘宝一样就行");
    }

    /***
     * 提出需求
     * @param coder
     * @param demands
     */
    public void putDemands(ICoder coder, String demands) {
        System.out.println(String.format("客户提出需求[%s]", demands));
        Boolean result = coder.implDemands(demands);
        if(result) {
            System.out.println("感谢!!!");
        } else {
            System.out.println("不能实现啊，好吧!!!");
        }
    }
}

```

## 动态代理

> 代理类在程序运行时创建的代理方式被成为动态代理

使用java.lang.reflect 包中的 Proxy 类与 InvocationHandler 接口

```
//定义一个老师接口
public interface Teacher {

    /***
     * 老师讲课
     * @param bookName
     * @return
     */
    boolean teach(String bookName);

}

//定义一个英语老师
public class EnglishTeacher implements Teacher {
    @Override
    public boolean teach(String bookName) {
        System.out.println("英语老师准备上课");
        System.out.println("今天讲: " + bookName);
        try {
            TimeUnit.SECONDS.sleep(3);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println(bookName + "讲完了");
        return true;
    }
}

//定义一个动态代理类用于记录上课时间
public class DynamicRecordProxy implements InvocationHandler {


    private Object target;

    public DynamicRecordProxy() {

    }

    public Object bind(Object target) {
        this.target = target;
        return Proxy.newProxyInstance(target.getClass().getClassLoader(), target.getClass().getInterfaces(), this);
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        System.out.println("开始记录");
        long startTime = System.currentTimeMillis();
        Object result = method.invoke(target, args);
        System.out.println("记录完成，花费: " + (System.currentTimeMillis() - startTime) + " 毫秒");
        return result;
    }
}

//测试类
public class DynamicProxyTest {

    public static void main(String[] args) {
        DynamicRecordProxy dynamicRecordProxy = new DynamicRecordProxy();
        
        Teacher teacher = (Teacher) dynamicRecordProxy.bind(new EnglishTeacher());
        teacher.teach("Oxford University Press");

    }
}

```

其实就是JDK帮我们自动编写了类（不需要源码，可以直接生成字节码）:

```
public class HelloDynamicProxy implements Hello {
    InvocationHandler handler;
    public HelloDynamicProxy(InvocationHandler handler) {
        this.handler = handler;
    }
    public void morning(String name) {
        handler.invoke(
           this,
           Hello.class.getMethod("morning", String.class),
           new Object[] { name });
    }
}
```

## CgLib

> JDK的动态代理有一个限制,就是使用动态代理的对象必须实现一个或多个接口,如果想代理没有实现接口的类,就可以使用Cglib实现

如果是spring 项目直接使用就行，非spring项目可引用：

```
<dependency>
        <groupId>cglib</groupId>
        <artifactId>cglib</artifactId>
        <version>3.2.10</version>
</dependency>
```

```
//定义一个普通类
public class UserService {

    public Boolean login(String name, String password) {
        System.out.println(name + "用户准备登录, 密码为: " + password);

        try {
            TimeUnit.SECONDS.sleep(1);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println(name + "登录成功");
        return true;
    }
}

//定义cglib代理
public class CglibProxy implements MethodInterceptor {


    private Enhancer enhancer = new Enhancer();

    public Object getProxy(Class<?> clazz) {
        enhancer.setSuperclass(clazz);
        enhancer.setCallback(this);
        return enhancer.create();
    }

    @Override
    public Object intercept(Object o, Method method, Object[] objects, MethodProxy methodProxy) throws Throwable {
        System.out.println("before");
        //注意这里需使用methodProxy.invokeSuper
        Object result = methodProxy.invokeSuper(o, objects);
        System.out.println("after");
        return result;
    }
}

//编写测试类
public class CglibProxyTest {

    public static void main(String[] args) {
        CglibProxy cglibProxy = new CglibProxy();

        UserService userService = (UserService) cglibProxy.getProxy(UserService.class);
        userService.login("admin", "admin123");
    }

}


//可以定义代理工厂，方便多个类使用
public class ProxyFactory {
    
    public static Object getGcLibDynProxy(Object target) {
        Enhancer enhancer = new Enhancer();
        enhancer.setSuperclass(target.getClass());
        enhancer.setCallback(new CglibProxy());
        Object targetProxy = enhancer.create();
        return targetProxy;
    }

}

```

在Spring的AOP编程中:

- 如果加入容器的目标对象有实现接口,用JDK代理
- 如果目标对象没有实现接口,用Cglib代理

不过需要注意：

- 代理的类不能为final,否则报错
- 目标对象的方法如果为final/static,那么就不会被拦截,即不会执行目标对象额外的业务方法