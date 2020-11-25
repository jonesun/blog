---
title: javaFx发展
date: 2020-05-20 16:16:37
categories: [java, javafx] 
tags: [java, javafx]
---

## javaFx发展

从 JDK 11 开始，Oracle 将从 JDK 中删除 JavaFX，但在 2022 年之前，Oracle 还会继续为 JDK 8 中的 JavaFX 提供商业支持。2011 年，JavaFX 成为 Open JDK 的一部分开源，这项技术的发展现在由 [OpenFX](https://openjfx.io/) ( [国内网站](https://openjfx.cn/) )社区负责

 <!-- more -->

## 为何使用javaFx


> 跨平台

JavaFX可在Windows、Mac OS X和Linux上运行，利用 JavaFX 能够非常轻松的搭建出在各个平台下体验基本一致的应用，甚至有人还将 JavaFX 移植到安卓上

> 学习成本低

- 有 Java 基础的完全能够通过阅读项目源码以及少量借助搜索引擎来学会使用，由于本身是基于java开发的，所以可以支持各类java第三方库，包括集成Spring Boot来构建项目

- 支持通过 fxml 和 css 来编写界面，有前端或者android开发经验者均可快速上手

> web方向支持

- 拥有一个 WebView 组件，可以通过js与原生java交互，实现丰富的功能

- 可运行于服务器端，通过浏览器提供用户访问 [jpro](https://www.jpro.one/?page=demos)

> 支持使用Spring Boot管理

- 可充分使用Spring Boot各类支持库

[TestOpenJfx14](https://gitee.com/sunr7/TestOpenjfx14)

> 支持自动更新

java8使用[fxlauncher](https://github.com/edvin/fxlauncher), java9+使用[update4j](https://github.com/update4j/update4j)

