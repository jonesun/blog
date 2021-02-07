---
title: java设计模式-组合模式
date: 2020-11-02 10:05:50
categories: [java, 设计模式]
tags: [java, 设计模式]
---

# 前言

组合模式(Composite): 将多个对象组合在一起进行操作，常用于表示树形结构中。为了简化代码，使用Composite可以把一个叶子节点与一个父节点统一起来处理。

> Composite模式使得叶子对象和容器对象具有一致性，从而形成统一的树形结构，并用一致的方式去处理它们

听起来有点不好理解，我们举个例子就好理解了: 在XML或HTML中，从根节点开始，每个节点都可能包含任意个其他节点，这些层层嵌套的节点就构成了一颗树。又例如我们开发GUI时用到的Android或者其他技术里的各个布局编写，每个布局都是独立的，但可以任意组合排列成开发者想要的大布局，即横向布局里可以放任意横向/纵向布局，纵向布局里也可以放任意横向/纵向布局，开发者先定义一个根布局，然后在内部添加任意布局

 <!-- more -->

# 举例

模拟xml节点：

* 定义节点接口
```java
/**
 * 节点
 */
public interface Node {

    void add(Node node);

    List<Node> getChildren();

    String toXml();

}

```

* 定义容器节点

```java
/**
 * 容器节点
 */
public class ElementNode implements Node{

    private String name;

    private List<Node> nodeList = new ArrayList<>();

    public ElementNode(String name) {
        this.name = name;
    }

    @Override
    public void add(Node node) {
        nodeList.add(node);
    }

    @Override
    public List<Node> getChildren() {
        return nodeList;
    }

    @Override
    public String toXml() {
        String start = "<" + name + ">\n";
        String end = "</" + name + ">\n";
        StringJoiner sj = new StringJoiner("", start, end);
        nodeList.forEach(node -> {
            sj.add(node.toXml() + "\n");
        });
        return sj.toString();
    }
}

```

* 定义文本节点

```java
/**
 * 文本节点
 */
public class TextNode implements Node {

    private String content;

    public TextNode(String content) {
        this.content = content;
    }

    @Override
    public void add(Node node) {
        throw new UnsupportedOperationException("不支持添加节点");
    }

    @Override
    public List<Node> getChildren() {
        return List.of();
    }

    @Override
    public String toXml() {
        return content;
    }
}

```

* 定义注释节点
  
```java
/**
 * 注释节点
 */
public class CommentNode implements Node {

    private String text;

    public CommentNode(String text) {
        this.text = text;
    }


    @Override
    public void add(Node node) {
        throw new UnsupportedOperationException("不支持添加节点");
    }

    @Override
    public List<Node> getChildren() {
        return List.of();
    }

    @Override
    public String toXml() {
        return "<!--" + text + ">";
    }
}

```

* 测试验证
  
```java
public class CompositeTest {

    public static void main(String[] args) {
        Node studentsNode = new ElementNode("students");

        Node studentNode1 = new ElementNode("student");

        studentsNode.add(studentNode1);

        studentNode1.add(new TextNode("张三"));

        Node studentNode2 = new ElementNode("student");

        studentsNode.add(studentNode2);

        studentNode2.add(new TextNode("李四"));

        //添加注释
        studentNode2.add(new CommentNode("这位同学叫李四"));

        System.out.println(studentsNode.toXml());
    }

}

//输出
<students>
<student>
张三
</student>

<student>
李四
<!--这位同学叫李四>
</student>

</students>

```
通过以上代码就可以实现简易版的xml布局了