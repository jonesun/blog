---
title: SpringBoot-集成swagger
date: 2020-10-10 14:31:18
categories: [java,springboot]
tags: [java, springboot]
---

# 简介

[Swagger](https://swagger.io/) 是一个规范和完整的文档框架，用于生成、描述、调用和可视化 RESTful 风格的 Web 服务文档

# 集成

swagger3.0.0简化了配置，故推荐直接使用最新版, 如果有还在用2.x版本的请参考时注意区分

> pom.xml

```
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-boot-starter</artifactId>
    <version>3.0.0</version>
</dependency>
```

这样就可以了，不用像2.x版本需要引入springfox-swagger和springfox-swagger-ui

> Swagger3Config

```
@Configuration
public class Swagger3Config {

    @Bean
    public Docket createRestApi() {
        //返回文档摘要信息
        return new Docket(DocumentationType.OAS_30)
                .apiInfo(apiInfo())
                .select()
//                .apis(RequestHandlerSelectors.withMethodAnnotation(ApiOperation.class))
                .apis(RequestHandlerSelectors.withMethodAnnotation(Operation.class))
                .paths(PathSelectors.any())
                .build();
    }

    //生成接口信息，包括标题、联系人等
    private ApiInfo apiInfo() {
        return new ApiInfoBuilder()
                .title("Swagger3接口文档")
                .description("如有疑问，请联系开发工程师")
                .contact(new Contact("JoneSun", "https://jonesun.github.io/", "sunr922@163.com"))
                .version("1.0")
                .build();
    }

}
```

注意只有controller层中标注@Operation注解的才会显示，同样可以@ApiOperation或者其他注解

> UserController

```
@Api(tags = "用户管理接口")
@RestController
@RequestMapping(value = "/users")
public class UserController {

    @Autowired
    UserService userService;

    @Operation(summary = "获取用户列表")
    @GetMapping(value="/")
    public List<User> getUserList() {
        return userService.selectList();
    }

    @Operation(summary = "新增用户")
    @PostMapping(value="/")
    public String postUser(@ModelAttribute User user) {
        userService.insert(user);
        return "success";
    }

    @Operation(summary = "获取用户")
    @GetMapping(value="/{id}")
    public User getUser(@PathVariable Long id) {
        return userService.selectById(id);
    }

    @Operation(summary = "更新用户")
    @PutMapping(value="/{id}")
    public String putUser(@PathVariable Long id, @ModelAttribute User user) {
        user.setId(id);
        userService.updateById(user);
        return "success";
    }

    @Operation(summary = "删除用户")
    @DeleteMapping(value="/{id}")
    public String deleteUser(@PathVariable Long id) {
        userService.deleteById(id);
        return "success";
    }

}
```

以上便完成了swagger3的简单配置，启动服务打开地址：项目地址+/swagger-ui/index.html

> 有人说需要在主类上加入@EnableOpenApi注解，但不加好像就可以用

## 关闭swagger

application-xx.yml

```
springfox:
  documentation:
  # 一键关闭
    enabled: false
    swagger-ui:
    # 控制ui的展示
      enabled: false
```

## 配合Security

WebSecurityConfig加入白名单即可

```
String[] SWAGGER_WHITELIST = {
        "/swagger-ui.html",
        "/swagger-ui/*",
        "/swagger-resources/**",
        "/v2/api-docs",
        "/v3/api-docs",
        "/webjars/**"
};
httpSecurity.cors().antMatchers(SWAGGER_WHITELIST).permitAll();
```

## 全局参数

现在很多项目都使用前后端分离的方式，使用了JWT这样的认证方式(在Header构造一个token), swagger支持在config中加入全局参数配置

> 方式一

每次请求的时候，手动输入token globalRequestParameters

```
Swagger3Config

   @Bean
    public Docket createRestApi() {

        //返回文档摘要信息
        return new Docket(DocumentationType.OAS_30)
                .apiInfo(apiInfo())
                .select()
//                .apis(RequestHandlerSelectors.withMethodAnnotation(ApiOperation.class))
                .apis(RequestHandlerSelectors.withMethodAnnotation(Operation.class))
                .paths(PathSelectors.any())
                .build()
                .globalRequestParameters(globalRequestParameters());
    }



    private List<RequestParameter> globalRequestParameters() {
        RequestParameterBuilder parameterBuilder = new RequestParameterBuilder()
                .in(ParameterType.HEADER).name("Authorization")
                .required(false)
                .query(param -> param.model(model -> model.scalarModel(ScalarType.STRING)));
        return Collections.singletonList(parameterBuilder.build());
    }
```

> 方式二

全局的Auth认证配置 securitySchemes

```
Swagger3Config

    @Bean
    public Docket createRestApi() {

        //返回文档摘要信息
        return new Docket(DocumentationType.OAS_30)
                .apiInfo(apiInfo())
                .select()
//                .apis(RequestHandlerSelectors.withMethodAnnotation(ApiOperation.class))
                .apis(RequestHandlerSelectors.withMethodAnnotation(Operation.class))
                .paths(PathSelectors.any())
                .build()
                .securitySchemes(security());
    }

    private List<SecurityScheme> security() {
        ApiKey apiKey = new ApiKey("Authorization", "Authorization", "header");
        return Collections.singletonList(apiKey);
    }
```
浏览器打开页面，点击右侧的Authorize按钮即可弹框。填入token即可

![auth](auth.png)

## 常用注解说明

```
@Api：用在请求的类上，表示对类的说明
    tags="说明该类的作用，可以在UI界面上看到的注解"
    value="该参数没什么意义，在UI界面上也看到，所以不需要配置"

@ApiOperation：用在请求的方法上，说明方法的用途、作用
    value="说明方法的用途、作用"
    notes="方法的备注说明"

@ApiImplicitParams：用在请求的方法上，表示一组参数说明
    @ApiImplicitParam：用在@ApiImplicitParams注解中，指定一个请求参数的各个方面
        name：参数名
        value：参数的汉字说明、解释
        required：参数是否必须传
        paramType：参数放在哪个地方
            · header --> 请求参数的获取：@RequestHeader
            · query --> 请求参数的获取：@RequestParam
            · path（用于restful接口）--> 请求参数的获取：@PathVariable
            · div（不常用）
            · form（不常用）    
        dataType：参数类型，默认String，其它值dataType="Integer"       
        defaultValue：参数的默认值

@ApiResponses：用在请求的方法上，表示一组响应
    @ApiResponse：用在@ApiResponses中，一般用于表达一个错误的响应信息
        code：数字，例如400
        message：信息，例如"请求参数没填好"
        response：抛出异常的类

@ApiModel：用于响应类上，表示一个返回响应数据的信息
            （这种一般用在post创建的时候，使用@RequestBody这样的场景，
            请求参数无法使用@ApiImplicitParam注解进行描述的时候）
    @ApiModelProperty：用在属性上，描述响应类的属性
```

> 使用swagger要注意

- 在生产环境中必须关闭swagger
- 它本身只用于前后端工程师之间的沟通,可以专门使用一台内部服务器来展示ui供访问

# 扩展

springdoc-openapi-ui，，它自动引入Swagger UI用来创建API文档，也比较方便