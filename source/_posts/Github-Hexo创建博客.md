---
title: Github-Hexo创建博客
date: 2016-08-08 08:33:50
categories: hexo             # 分类
tags: [nodejs, hexo, NexT]   # [标签1, 标签2..., 标签n]
---

## 环境准备 ##
[安装nodejs][1]
[安装git][2]
 <!-- more -->

## 安装Hexo ##
打开cmd命令行，输入
```
D:
cd D:/hexo
npm install hexo-cli -g
//卸载
npm uninstall hexo-cli
```

## 初始化Hexo ##
```
hexo init blog
cd blog
npm install #安装package.json中的依赖包
npm install hexo-deployer-git --save #安装deploy插件，用于部署到GitHub
```

## 测试运行 ##
```
hexo generate #可简写为hexo g 生成静态文件，会在当前目录下生成一个新的叫做public的文件夹
hexo server #可简写为hexo s 启动本地web服务，用于博客的预览
hexo deploy #可简写为hexo d 部署播客到远端（比如github, heroku等平台）
```

## 查看效果 ##
打开浏览器，输入http://localhost:4000

## 切换主题 ##
在blog目录下运行
```
git clone https://github.com/iissnan/hexo-theme-next themes/next #将next主题下载到themes文件夹下
//更新主题
git pull
```
打开blog目录下的配置文件_config.xml,修改
```
theme: next #next即为主题名称
```

## 启用主题 ##
```
hexo clean #清理hexo缓存
hexo s #重新启动本地web服务器
```
主题的其他设置见next主题[官网][3].

## 创建Github Pages ##
打开blog目录下的配置文件_config.xml,修改
```
deploy:
    type: git
    repo: https://github.com/jonesun/jonesun.github.io.git
    branch: master
    name: jone sun
    email: sunjoner7@gmail.com
```
## 部署到Github Pages ##
执行命令
```
hexo d
```
完成部署,过程中需要github账号/密码

## 保存Hexo博客源文件 ##

1. 在GitHub新建仓库blog 
2. 删除blog目录和主题目录下的.git文件夹(如果存在)
3. 修改blog目录的.gitignore文件,加入
```
/.deploy_git
/public
```
4. 同步到Github中
```
git init 
git add .
# 若出现`warning: LF will be replaced by CRLF in`
# 执行:
# git config --global core.autocrlf  false
git commit -m "first commit"
git remote add origin https://github.com/jonesun/jonesun.github.io.git
git push -u origin master
# 此时可能会出错failed to push some refs to git  出现错误的主要原因是github中的README.md文件不在本地代码目录中，可以通过如下命令进行代码合并
# git pull --rebase origin master
# 此时再执行语句 
# git push -u origin master
```

## 日常操作 ##
1. 检查更新，将本地博客源文件更新至最新版本
```
git pull
```
2. 新建文章
```
hexo new <新的文章>
```
3. 编辑文章
打开blog\source\_posts文件夹，使用自己喜欢的Markdowm编辑器进行编辑保存，这里推荐一个在线编辑器[作业部落][4]
运行查看
```
hexo g
hexo s
```
4. 同步Hexo源文件
```
git add . #不添加被删除的文件,`git add -A`会添加所有修改.
git commit -m "更新描述"
git remote add origin https://github.com/jonesun/blog.git
git push origin master
```
5. 部署
```
hexo d
```

## 新电脑配置 ##
1. 安装nodejs和git
2. 安装Hexo
```
npm install -g hexo-cli
```
3. 下载博客源文件
```
git clone https://github.com/jonesun/blog.git
```

4. 安装模块

```
rm -rf node_modules && npm install --force
```

1. 运行部署
```
hexo g
hexo s
hexo d
```

  [1]: https://nodejs.org/en/
  [2]: https://git-scm.com/
  [3]: http://theme-next.iissnan.com/
  [4]: https://www.zybuluo.com/mdeditor


# 博客提交搜索引擎收录

请确保Next主题版本为NexT-7.1.2及以上 

## 百度和Google收录

- 安装百度和 Google 的站点地图生成插件

```
npm install hexo-generator-baidu-sitemap --save
npm install hexo-generator-sitemap --save
```

- 修改配置文件(最外层的_config.yml), 可搜索sitemap字段(默认都有，没有再添加)

```
# 自动生成sitemap
sitemap:
  path: sitemap.xml
baidusitemap:
  path: baidusitemap.xml

```

hexo g 生成后进入 public 目录，你会发现里面有 sitemap.xml 和 baidusitemap.xml 两个文件，这就是生成的站点地图。里面包含了网站上所有页面的链接，搜索引擎通过这两个文件来抓取网站页面: 

sitemap.xml 用来提交给 Google

baidusitemap.xml 用来提交给百度

## Google Search Console

- 进入 [Google Web Master Search Console](https://www.google.com/webmasters)，首先需要进行站点验证，在**主题配置文件_config.yml** 把验证代码写上：

```
google_site_verification: 7MWmpu7Y_liZprzsvd1MxYuG1tRYQ7V1eK9_rLcHmB0
```

- 通过hexo g 和 hexo d部署后，再点击Google Search Console需要的验证

- 验证是否收录

打开谷歌搜索,输入: 
```
//换成自己的域名，查看结果
site: https://jonesun.github.io/
```

## 百度站长平台

首先注册百度账号，完善个人信息，然后打开[站长平台](https://ziyuan.baidu.com/site), 添加网站，得到验证代码后，在**主题配置文件_config.yml** 把验证代码写上：

```
baidu_site_verification: code-SeFMiHxes9
```

- 通过hexo g 和 hexo d部署后，再点击验证，等待结果

## 链接提交

安装插件

```
npm install hexo-baidu-url-submit --save

```

在**主题配置文件_config.yml** 加入：

```
baidu_url_submit:
  count: 5 				     ## 提交最新的五个链接
  host: jonesun.github.io	     ## 百度站长平台中注册的域名
  token: wxEYCMr7JzpSUEfi	 ## 准入秘钥
  path: baidu_urls.txt ## 文本文档的地址， 新链接会保存在此文本文档里

```

## hexo 创建草稿

使用草稿新建的文章就不会发布，会存放在/source/_drafts路径下：
```
hexo new draft <title>
```

发布草稿，会把/source/_drafts下的文章移到/source/_posts下：

```
hexo publish <title>
```

## 显示字数及阅读时长

安装hexo-symbols-count-time
```
npm install hexo-symbols-count-time --save
```

next主题中_config.yml中配置
```yml
symbols_count_time:
  separated_meta: true     # 是否另起一行（true的话不和发表时间等同一行）
  item_text_post: true     # 首页文章统计数量前是否显示文字描述（本文字数、阅读时长）
  item_text_total: false   # 页面底部统计数量前是否显示文字描述（站点总字数、站点阅读时长）
  awl: 4                   # Average Word Length
  wpm: 275                 # Words Per Minute（每分钟阅读词数）
  suffix: mins.
```

> 如果显示为阅读时长NaN:aN, 执行 hexo clean即可

在 Hexo 更新至 5.x 版本，Next 更新至 7.x 版本后，会出现文章的中文目录点击跳转失效的 bug, 参见[Github Issues](https://github.com/theme-next/hexo-theme-next/pull/1540/files)

排版布局和翻译风格上可以参考了阮一峰老师的[中文技术文档的写作规范](https://github.com/ruanyf/document-style-guide)