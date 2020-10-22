---
title: SpringBoot-集成websocket
date: 2020-09-04 15:42:37
categories: [java,springboot]
tags: [java, springboot]
---

# 前言

> HTTP 协议有一个缺陷：通信只能由客户端发起

HTML5定义了WebSocket协议，能更好的节省服务器资源和带宽，并且能够更实时地进行通讯。服务器可以主动向客户端推送信息，客户端也可以主动向服务器发送信息，是真正的双向平等对话，属于服务器推送技术的一种。可以替代长轮询，用于对实时性要求比较高的场景:

- 聊天室

- 服务端消息实时推送

- ......

# 使用

## 服务端

SpringBoot中使用WebSocket非常简单:

1. pom.xml中加入引用

```
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-websocket</artifactId>
</dependency>
```

2. 新建WebSocketConfig配置类

```
@Configuration
@EnableWebSocket
public class WebSocketConfig {

    /**
     * 如果直接使用springboot的内置容器，而不是使用独立的servlet容器，就要注入ServerEndpointExporter，外部容器则不需要。
     */
    @Bean
    public ServerEndpointExporter serverEndpointExporter() {
        return new ServerEndpointExporter();
    }

}

```

3. 定义接受和处理消息的处理类

注意@ServerEndpoint的使用

```
@Component
@ServerEndpoint("/websocket/{username}")
public class ChatRoomServerEndpoint {

    public static final Map<String, Session> ONLINE_USER_SESSIONS = new ConcurrentHashMap<>();

    @OnOpen
    public void openSession(@PathParam("username") String username, Session session) {
        ONLINE_USER_SESSIONS.put(username, session);
        String message = "[" + username + "] 客户端信息！";
        sendMessageAll("服务器连接成功！");
        sendMessage(session, "");
        System.out.println("连接成功" + message);
    }

    @OnMessage
    public void onMessage(@PathParam("username") String username, String message) {
        System.out.println("服务器收到：" + "[" + username + "] : " + message);
        sendMessageAll("我已收到你的消息》》[" + username + "] : " + message);
    }

    @OnClose
    public void onClose(@PathParam("username") String username, Session session) {
        //当前的Session 移除
        ONLINE_USER_SESSIONS.remove(username);
        //并且通知其他人当前用户已经断开连接了
        sendMessageAll("[" + username + "] 断开连接！");
        try {
            session.close();
        } catch (IOException e) {
        }
    }

    @OnError
    public void onError(Session session, Throwable throwable) {
        try {
            session.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    // 单用户推送
    public void sendMessage(Session session, String message) {
        if (session == null) {
            return;
        }
        final RemoteEndpoint.Basic basic = session.getBasicRemote();
        if (basic == null) {
            return;
        }
        try {
            basic.sendText(message);
        } catch (IOException e) {
            System.out.println("sendMessage IOException " + e);
        }
    }

    // 全用户推送
    public void sendMessageAll(String message) {
        ONLINE_USER_SESSIONS.forEach((sessionId, session) -> sendMessage(session, message));
    }
}
```

以上就实现了websocket server的集成，后面就是使用不同的技术实现客户端了(html、android等)

## 客户端

当然可以编写java版的用于测试连接，这里我们使用Java-WebSocket：

1. pom.xml文件中添加引用

```
<!-- https://mvnrepository.com/artifact/org.java-websocket/Java-WebSocket -->
<dependency>
    <groupId>org.java-websocket</groupId>
    <artifactId>Java-WebSocket</artifactId>
    <version>1.5.1</version>
</dependency>

```

2. 编写测试类

```
@RunWith(Runner.class)
class WebSocketClientTests {

    private final Logger log = LoggerFactory.getLogger(this.getClass());

    WebSocketClient webSocketClient;
    @Test
    void testClient() {
        try {
            webSocketClient = new WebSocketClient(new URI("ws://localhost:8080/websocket/test" + System.currentTimeMillis()),new Draft_6455()) {
                @Override
                public void onOpen(ServerHandshake handshakedata) {
                    log.info("[websocket] 连接成功");
                    webSocketClient.send("你好，我是客户端1111");
                }

                @Override
                public void onMessage(String message) {
                    log.info("[websocket] 收到消息={}",message);

                }

                @Override
                public void onClose(int code, String reason, boolean remote) {
                    log.info("[websocket] 退出连接");
                }

                @Override
                public void onError(Exception ex) {
                    log.info("[websocket] 连接错误={}",ex.getMessage());
                }
            };
            webSocketClient.connect();

            while (!webSocketClient.isClosed()) {

            }
            log.info("[主程序] 退出");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

}

```

3. 运行SpringBoot服务端和测试类，即可看到效果

## 连接地址说明

> ws://localhost:8080/websocket/xxx

客户端需使用websocket的协议ws，由于是用SpringBoot集成的websocket，故url地址与正常的http的类似，后面的websocket/test是取决于@ServerEndpoint的定义(源码里为@ServerEndpoint("/websocket/{username}")，故客户端可以使用websocket/xxx),不同ServerEndpoint处理不同策略

- 如果SpringBoot的application.yml指定了

```
server:
  servlet:
    context-path: /spring-websocket
  port: 8888
```

则此时客户端连接的url应改为：

```
ws://localhost:8888/spring-websocket/websocket/xxx
```

## todo

- 重连心跳机制

- 使用netty：Servlet的线程模型并不适合大规模的长链接。基于NIO的Netty等框架更适合处理WebSocket长链接

- 加入ssl时的处理

- 与HTTP/2推送的不同-HTTP/2 只能推送静态资源，无法推送指定的信息

- fetch-下一代的免刷新web交互手段