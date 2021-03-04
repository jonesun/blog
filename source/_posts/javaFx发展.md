---
title: javaFx发展
date: 2020-05-20 16:16:37
categories: [java, javafx] 
tags: [java, javafx]
---

## javaFx发展

从 JDK 11 开始，Oracle 将从 JDK 中删除 JavaFX，但在 2022 年之前，Oracle 还会继续为 JDK 8 中的 JavaFX 提供商业支持。2011 年，JavaFX 成为 Open JDK 的一部分开源，这项技术的发展现在由 [OpenFX](https://openjfx.io/) ([国内网站](https://openjfx.cn/) )社区负责

当然如果是基于高版本的jdk开发, 推荐使用[Liberica JDK-不仅包含了 JavaFX，还继续为 Windows 以及 Linux 提供 32 位构建](https://bell-sw.com/pages/java-8u242/), 下载Full version版本就可以无缝切换

 <!-- more -->

## 为何使用javaFx


> 跨平台

JavaFX可在Windows、Mac OS X和Linux上运行，利用 JavaFX 能够非常轻松的搭建出在各个平台下体验基本一致的应用，甚至有人还将 JavaFX 移植到安卓上

> 学习成本低

- 有 Java 基础的完全能够通过阅读项目源码以及少量借助搜索引擎来学会使用，由于本身是基于java开发的，所以可以支持各类java第三方库，包括集成Spring Boot来构建项目

- 支持通过 fxml 和 css 来编写界面，有前端或者android开发经验者均可快速上手

> web方向支持

- 拥有一个 WebView 组件，可以通过js与原生java交互，实现丰富的功能

- 可运行于服务器端，通过浏览器提供用户访问，可参考[jpro](https://www.jpro.one/?page=demos)

> 支持使用Spring Boot管理

- 可充分使用Spring Boot各类支持库

[javafx-test-with-javapackager](https://github.com/jonesun/javafx-test-with-javapackager)

[TestOpenJfx14](https://gitee.com/sunr7/TestOpenjfx14)


```java
@SpringBootApplication
public class MyApplication extends Application {

    private ConfigurableApplicationContext springContext;

    @Override
    public void init() {
        springContext = SpringApplication.run(MyApplication.class);
    }

    @Override
    public void start(Stage primaryStage) throws Exception {
        //Parent root = FXMLLoader.load(getClass().getResource("/fxml/main.fxml"), null, null, springContext::getBean);
        //或者
        FXMLLoader fxmlLoader = new FXMLLoader(getClass().getResource("/fxml/main.fxml"));
        fxmlLoader.setControllerFactory(springContext::getBean);
        root = fxmlLoader.load();

        primaryStage.setTitle("xxx");
        primaryStage.setScene(new Scene(root, 800, 700));
        primaryStage.show();
    }
    
    @Override
    public void stop(){
        springContext.close();
    }

    public static void main(String[] args) {
        //为了能正常使用Desktop.getDesktop()相关方法
        System.setProperty("java.awt.headless", Boolean.toString(false));
        launch();
    }

}

public abstract class BaseController implements Initializable {

    protected final Logger logger = LoggerFactory.getLogger(getClass());

    @Autowired
    protected ApplicationContext springContext;

    /**
     * 获取Scene
     * @param actionEvent
     * @return
     */
    public Scene getScene(ActionEvent actionEvent) {
        return ((Node) actionEvent.getSource()).getScene();
    }

    /**
     * 获取Stage
     * @param actionEvent
     * @return
     */
    public Stage getStage(ActionEvent actionEvent) {
        Scene scene = getScene(actionEvent);
        return (Stage) scene.getWindow();
    }

    /**
     * 获取Stage
     * 注意如果是在initialize中获取的话需使用 Platform.runLater(() -> Stage stage = getStage(node);});
     * @param node
     * @return
     */
    public Stage getStage(Node node) {
        return (Stage) node.getScene().getWindow();
    }

    /**
     * 打开页面
     * @param actionEvent
     * @param fxmlName
     * @throws IOException
     */
    public void openController(ActionEvent actionEvent, String fxmlName) throws IOException {
        Scene scene = getScene(actionEvent);
        Parent root = FXMLLoader.load(getClass().getResource(fxmlName), null, null, springContext::getBean);
        scene.setRoot(root);
    }
}


```

> 支持自动更新

java8使用[fxlauncher](https://github.com/edvin/fxlauncher), java9+使用[update4j](https://github.com/update4j/update4j)


```
//bufferedImage转image java11+需引用javafx-swing
new ImageView(SwingFXUtils.toFXImage(bufferedImage, null))
```