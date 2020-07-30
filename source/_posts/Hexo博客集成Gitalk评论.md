---
title: Hexo博客集成Gitalk评论
date: 2020-07-29 14:27:46
categories: hexo 
tags: [nodejs, hexo, NexT, gitalk]   
---

> next高版本的已经默认集成gitalk插件, 如果你本地没找到配置，尽快升级。目前我使用的是next 7.x版本，故只需要在_config.yml中打开gitalk配置即可

1. 在GitHub新建Application

用于用户评论文章时登录授权

 <!-- more -->

[新建](https://github.com/settings/applications/new)

![image](register-a-new-oauth-application.png) 


- Application name： 应用名称

- Homepage URL：主页地址，直接写博客地址就行

- Application description： 描述

- Authorization callback URL：回调地址，也写博客地址就行

2. 拷贝Client ID和Client Secret

![image](client-id-secret.png) 

3. 在Github中新建仓库

用于存放评论数据

[新建](https://github.com/new)

![image](blog-comment.png) 


4. 修改next主题配置

打开next主题配置文件_config.yml(路径为blog\themes\xxx-主题名称\)

```
gitalk:
  enable: true #改为 true 
  github_id: jonesun # 填写自己的github的用户名
  repo: MyBlogGitalk # 存放评论的仓库名
  client_id: xxxxxx # 填写上一步拷贝的Client ID
  client_secret: xxxxxxxxx # 填写上一步拷贝的Client Secret
  admin_user: jonesun # 也填写自己的github的用户名
  distraction_free_mode: true # Facebook-like distraction free mode
  # Gitalk's display language depends on user's browser or system environment
  # If you want everyone visiting your site to see a uniform language, you can set a force language value
  # Available values: en | es-ES | fr | ru | zh-CN | zh-TW
  language: zh-CN
```

5. 部署上传

使用 hexo g 和hexo d上传到博客保存的git上(一般是github)

![image](gitalk-comment-data.png) 

用户在看到文章后，即可进行评论(需要GitHub账户才行)


如果有出现这个，登录一下就行了

![image](no-comment.png) 
