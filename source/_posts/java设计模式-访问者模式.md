---
title: java设计模式-访问者模式
date: 2020-11-05 13:26:33
categories: [java, 设计模式] 
tags: [java, 设计模式]
---

# 前言

访问者模式(Visitor)是为了抽象出作用于一组复杂对象的操作，并且后续可以新增操作而不必对现有的对象结构做任何改动

访问者模式的核心思想是为了访问比较复杂的数据结构，不去改变数据结构，而是把对数据的操作抽象出来，在“访问”的过程中以回调形式在访问者中处理操作逻辑。如果要新增一组操作，那么只需要增加一个新的访问者。

访问者模式适用于数据结构相对稳定的系统，把**数据结构和算法解耦**

Java标准库提供的Files.walkFileTree()就实现了一个访问者模式

对XML的SAX处理也是一个访问者模式，我们需要提供一个SAX Handler作为访问者处理XML的各个节点

 <!-- more -->

# 实现

我们来模拟遍历文件夹不同情况的处理

```
/**
 * 文件访问者
 */
public interface FileVisitor {

    void visitFile(File file);

    void visitDir(File dir);

}

/**
 * 文件扫描器
 */
public class FileScanner {

    public static void scan(File file, FileVisitor fileVisitor) {
        if(file.isDirectory()) {
            fileVisitor.visitDir(file);
            File[] files = file.listFiles();
            for(File f : files) {
                scan(f, fileVisitor);
            }
        } else {
            fileVisitor.visitFile(file);
        }
    }
}

public class FileVisitorTest {

    public static void main(String[] args) {
        FileScanner.scan(new File("."), new FileVisitor() {
            @Override
            public void visitFile(File file) {
                System.out.println("文件名: " + file.getName());
            }

            @Override
            public void visitDir(File dir) {
                System.out.println("文件夹名: " + dir);
            }
        });
    }

}
```

这样就把递归遍历文件夹的过程封装起来，外部根据自己的实际要求获取所有的文件和文件夹或者只获取特定类型的文件