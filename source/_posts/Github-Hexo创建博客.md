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
4. 运行部署
```
hexo g
hexo s
hexo d
```

  [1]: https://nodejs.org/en/
  [2]: https://git-scm.com/
  [3]: http://theme-next.iissnan.com/
  [4]: https://www.zybuluo.com/mdeditor

