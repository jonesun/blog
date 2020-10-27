---
title: java设计模式-责任链模式
date: 2020-09-27 10:33:05
categories: [java, 设计模式]
tags: [java, 设计模式]
---

> 设计模式是为了可扩展性，不要为了使用设计模式而使用

# 概念

> 责任链模式(Chain of Responsibility): 使多个对象都有机会处理请求，从而避免请求的发送者和接收者之间的耦合关系。将这个对象连成一条链，并沿着这条链传递该请求，直到有一个对象处理它为止

像我们日常使用的spring框架中的拦截器和过滤器都是使用了该模式，每次请求都会经过一系列的拦截，只有当前面的拦截通过后才会进入下一步

责任链模式包含如下角色:

- Handler: 抽象处理者，处理请求的接口类包含抽象处理方法和一个后继连接
- Concrete Handler: 实现抽象处理者的处理类，判断能否处理本次请求，如果可以处理请求则处理，否则将该请求转给它的后继者
- Client: 创建处理链，并向链头的具体处理者对象提交请求，它不关心处理细节和请求的传递过程

抽象的处理者实现三个职责：
一是定义一个请求的处理方法handleMessage，唯一对外开放的方法；
二是定义一个链的编排方法setNext，设置下一个处理者；
三是定义了具体的请求者必须实现的两个方法：定义自己能够处理的级别getHandlerLevel和具体的处理任务echo。
注意事项：
链中节点数量需要控制，避免出现超长链的情况，一般的做法是在Handler中设置一个最大节点数量，在setNext方法中判断是否已经是超过其阈值，超过则不允许该链建立，避免无意识地破坏系统性能

# 使用场景

审批流程、多轮面试等需要多级处理的场景都适合使用责任链模式来实现，可解决大量的分支判断造成难维护、灵活性差的问题


 <!-- more -->

# 实现方式

1. 有固定上下级关系的带等级和处理范围的, 如公司的请假审批

```
//定义等级
public enum LevelEnum {

    /**
     * 普通员工
     */
    NORMAL(1, "普通员工"),

    /**
     * 小组长
     */
    GROUP_MANAGER(2, "小组长"),

    /**
     * 经理
     */
    COMMON_MANAGER(3, "经理"),

    /**
     * 老板
     */
    BOSS(3, "老板");


    /**
     * 等级
     */
    private final Integer level;

    /**
     * 职位
     */
    private final String office;

    LevelEnum(Integer level, String office) {
        this.level = level;
        this.office = office;
    }

    public Integer getLevel() {
        return level;
    }

    public String getOffice() {
        return office;
    }

    @Override
    public String toString() {
        return "LevelEnum{" +
                "level=" + level +
                ", office='" + office + '\'' +
                '}';
    }
}

//定义请求类
public class LeaveRequest {

    /**
     * 请假人
     */
    private BaseStaff staff;

    /**
     * 请假内容
     */
    private String content;

    /**
     * 请求类型
     */
    private String type;

    /**
     * 请假天数
     */
    private Integer needDays;

    public LeaveRequest(BaseStaff staff, String content, String type, Integer needDays) {
        this.staff = staff;
        this.content = content;
        this.type = type;
        this.needDays = needDays;
    }

    public BaseStaff getStaff() {
        return staff;
    }

    public void setStaff(BaseStaff staff) {
        this.staff = staff;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public Integer getNeedDays() {
        return needDays;
    }

    public void setNeedDays(Integer needDays) {
        this.needDays = needDays;
    }

    @Override
    public String toString() {
        return "LeaveRequest{" +
                "content='" + content + '\'' +
                ", type='" + type + '\'' +
                ", needDays=" + needDays +
                '}';
    }
}

//定义响应类
public class LeaveResponse {

    /**
     * 初始默认状态
     */
    public static final Integer DEFAULT = 0;

    /**
     * 同意
     */
    public static final Integer STATUS_OF_PASS = 1;

    /**
     * 拒绝
     */
    public static final Integer STATUS_OF_REFUSE = 2;


    /**
     * 响应人
     */
    private String name;

    /**
     * 响应结果
     */
    private Integer resultStatus;

    /**
     * 响应内容
     */
    private String resultContent;

    public LeaveResponse() {
        resultStatus = DEFAULT;
    }


    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Integer getResultStatus() {
        return resultStatus;
    }

    public void setResultStatus(Integer resultStatus) {
        this.resultStatus = resultStatus;
    }

    public String getResultContent() {
        return resultContent;
    }

    public void setResultContent(String resultContent) {
        this.resultContent = resultContent;
    }

    @Override
    public String toString() {
        return "LeaveResponse{" +
                "name='" + name + '\'' +
                ", resultStatus=" + resultStatus +
                ", resultContent='" + resultContent + '\'' +
                '}';
    }
}

//定义员工基类
public abstract class BaseStaff {

    /**
     * 姓名
     */
    private String name;

    /**
     * 等级
     */
    private LevelEnum level;

    /**
     * 上级
     */
    private BaseManagerStaff superior;

    public BaseStaff(String name, LevelEnum level) {
        this.name = name;
        this.level = level;
    }

    /**
     * 请假
     *
     * @param request
     * @return
     */
    public void leave(LeaveRequest request, LeaveResponse leaveResponse) {
        if (superior != null) {
            //向上级请假
            System.out.println(String.format("%s 向 %s 发起请假: %s ", getShowName(), superior.getShowName(), request.toString()));
            superior.doHandle(request, leaveResponse);
        } else {
            throw new RuntimeException(String.format("%s 没有上级，无法审批: %s ", getShowName(), request.toString()));
        }
    }


    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public LevelEnum getLevel() {
        return level;
    }

    public void setLevel(LevelEnum level) {
        this.level = level;
    }

    public BaseManagerStaff getSuperior() {
        return superior;
    }

    public void setSuperior(BaseManagerStaff superior) {
        this.superior = superior;
    }

    public String getShowName() {
        return "{" +
                "name='" + name + '\'' +
                ", level=" + level +
                '}';
    }
}

//定义管理层员工基类
public abstract class BaseManagerStaff extends BaseStaff {

    public BaseManagerStaff(String name, LevelEnum level) {
        super(name, level);
    }

    /**
     * 审批请假
     *
     * @param request
     * @return
     */
    public abstract void doHandle(LeaveRequest request, LeaveResponse response);

    /**
     * 审批流程
     *
     * @param request
     * @param response
     * @param predicate
     */
    protected final void approval(LeaveRequest request, LeaveResponse response, Predicate<LeaveRequest> predicate) {
        response.setName(getName());
        if (Objects.isNull(request.getType())) {
            System.err.println(String.format("当前审批人为 %s>>申请未指定类型, 驳回：%s", getShowName(), request.toString()));
            response.setResultStatus(LeaveResponse.STATUS_OF_REFUSE);
            response.setResultContent("申请未指定类型, 驳回");
            return;
        }
        if (predicate.test(request)) {
            response.setResultStatus(LeaveResponse.STATUS_OF_PASS);
            response.setResultContent("同意");
            System.out.println(String.format("当前审批人为 %s>>审批通过：%s", getShowName(), request.toString()));
        } else {
            BaseManagerStaff managerStaff = getSuperior();
            if (managerStaff != null) {
                System.out.println(String.format("当前审批人为 %s>>得由%s审批：%s", getShowName(), managerStaff.getShowName(), request.toString()));
                managerStaff.doHandle(request, response);
            } else {
                System.out.println(String.format("当前审批人为 %s>>没有上级, 无需审批, 直接通过：%s", getShowName(), request.toString()));
                response.setResultStatus(LeaveResponse.STATUS_OF_PASS);
                response.setResultContent("直接同意");
            }
        }
    }

}

//定义普通员工
public class NormalStaff extends BaseStaff {


    public NormalStaff(String name) {
        super(name, LevelEnum.NORMAL);
    }

}

//定义小组长
public class GroupManager extends BaseManagerStaff {


    public GroupManager(String name) {
        super(name, LevelEnum.GROUP_MANAGER);
    }

    @Override
    public void doHandle(LeaveRequest request, LeaveResponse response) {
        //3天内的请假请求，由小组长审批
        approval(request, response, request1 -> request1.getNeedDays() <= 3);
    }
}

//定义经理
public class CommonManager extends BaseManagerStaff {


    public CommonManager(String name) {
        super(name, LevelEnum.COMMON_MANAGER);
    }

    @Override
    public void doHandle(LeaveRequest request, LeaveResponse response) {
        //5天内的请假请求，由经理审批
        approval(request, response, request1 -> request1.getNeedDays() <= 5);
    }
}

//定义老板
public class BossManager extends BaseManagerStaff {


    public BossManager(String name) {
        super(name, LevelEnum.BOSS);
    }

    @Override
    public void leave(LeaveRequest request, LeaveResponse leaveResponse) {
        //老板 请假自己申请即可
//        super.leave(request, leaveResponse);
        System.out.println(String.format("当前审批人为 %s>>没有上级, 无需审批, 直接通过：%s", getShowName(), request.toString()));
        leaveResponse.setResultStatus(LeaveResponse.STATUS_OF_PASS);
        leaveResponse.setResultContent("直接同意");
    }

    @Override
    public void doHandle(LeaveRequest request, LeaveResponse response) {
        response.setName(getName());
        if (request.getNeedDays() > 10) {
            System.err.println(String.format("当前审批人为 %s>>申请未指定类型, 驳回：%s", getShowName(), request.toString()));
            response.setResultStatus(LeaveResponse.STATUS_OF_REFUSE);
            response.setResultContent("请这么多天, 驳回");
            return;
        }
        //5天以上的请假请求，由经理审批
        approval(request, response, request1 -> request1.getNeedDays() > 5);
    }

}

//测试
public class LeaveTest {

    public static void main(String[] args) {

        //初始化公司 人员
        BossManager bossManager1 = new BossManager("张三");
        CommonManager commonManager = new CommonManager("李四");
        GroupManager groupManager1 = new GroupManager("王五");
        NormalStaff normalStaff1 = new NormalStaff("赵六");

        //设置上下级关系
        normalStaff1.setSuperior(groupManager1);
        groupManager1.setSuperior(commonManager);
        commonManager.setSuperior(bossManager1);

        //普通员工请假
        leave(normalStaff1, 1);

        //小组长请假
        leave(groupManager1, 3);

        //经理请假
        leave(commonManager, 6);

        //老板请假
        leave(bossManager1, 6);

    }

    private static void leave(BaseStaff staff, Integer needDays) {
        LeaveResponse leaveResponse1 = new LeaveResponse();
        staff.leave(new LeaveRequest(staff, "国庆请假" + needDays + "天", "事假", needDays), leaveResponse1);
        System.out.println(staff.getName() + ">>国庆请假" + needDays + "天结果：" + leaveResponse1.toString());
    }

}

```

2. 没有固定的上下级管理, 处理者处理好后，由专门的chain管理类继续交由下一个处理者处理，如拦截器

```
//定义请求类
public class MyRequest {


    private String token;

    private String name;

    private String content;

    private String ip;

    public MyRequest(String token, String name, String content, String ip) {
        this.token = token;
        this.name = name;
        this.content = content;
        this.ip = ip;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getIp() {
        return ip;
    }

    public void setIp(String ip) {
        this.ip = ip;
    }

    @Override
    public String toString() {
        return "MyRequest{" +
                "token='" + token + '\'' +
                ", name='" + name + '\'' +
                ", content='" + content + '\'' +
                ", ip='" + ip + '\'' +
                '}';
    }
}

//定义响应类
public class MyResponse {

    public static final Integer STATUS_OF_DEFAULT = 0;

    public static final Integer STATUS_OF_PASS = 1;

    public static final Integer STATUS_OF_REFUSE = -1;

    private MyRequest request;

    private String reason;

    private Integer status;

    public MyResponse(MyRequest request) {
        this.request = request;
        this.status = STATUS_OF_DEFAULT;
    }



    public MyRequest getRequest() {
        return request;
    }

    public void setRequest(MyRequest request) {
        this.request = request;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }

    public Integer getStatus() {
        return status;
    }

    public void setStatus(Integer status) {
        this.status = status;
    }

    @Override
    public String toString() {
        return "MyResponse{" +
                "request=" + request +
                ", reason='" + reason + '\'' +
                ", status=" + status +
                '}';
    }
}

//定义拦截器接口
public interface Interceptor {

    default boolean handle(MyRequest request, MyResponse response) {
        //利用java8默认方法的特性，将是否进入下一阶段统一控制
        doHandle(request, response);
        return MyResponse.STATUS_OF_PASS.equals(response.getStatus());
    }

    void doHandle(MyRequest request, MyResponse response);

}


//定义权限拦截器
public class AuthInterceptor implements Interceptor {

    @Override
    public void doHandle(MyRequest request, MyResponse response) {
        if (request.getToken() == null) {
            response.setStatus(MyResponse.STATUS_OF_REFUSE);
            response.setReason("权限验证不予通过,未传递token>>" + request.toString());
        } else {
            System.out.println("权限验证通过>>" + request.toString());
            response.setStatus(MyResponse.STATUS_OF_PASS);
        }

    }
}

//定义白名单拦截器
public class WhiteListInterceptor implements Interceptor {

    @Override
    public void doHandle(MyRequest request, MyResponse response) {
        //这里测试方便 判断是否内网用最简单的方法(项目中不要这么判断)
        if (request.getIp() == null || !request.getIp().startsWith("192.168.")) {
            response.setStatus(MyResponse.STATUS_OF_REFUSE);
            response.setReason("白名单验证不予通过,非内网访问>>" + request.toString());
        } else {
            System.out.println("白名单验证通过>>" + request.toString());
            response.setStatus(MyResponse.STATUS_OF_PASS);
        }

    }
}

//定义日志拦截器
public class LogInterceptor implements Interceptor {

    @Override
    public void doHandle(MyRequest request, MyResponse response) {
        System.out.println("日志记录成功>>" + request.toString());
        response.setStatus(MyResponse.STATUS_OF_PASS);
    }
}

//定义拦截器责任链
public class InterceptorChain {

    List<Interceptor> interceptors = new ArrayList<>();

    /**
     * 添加拦截器
     *
     * @param interceptor
     * @return
     */
    public InterceptorChain addInterceptor(Interceptor interceptor) {
        interceptors.add(interceptor);
        return this;
    }


    /**
     * 执行过滤
     *
     * @param request
     * @return
     */
    public MyResponse submit(MyRequest request) {
        MyResponse myResponse = new MyResponse(request);
        for (Interceptor interceptor : interceptors) {
            if (!interceptor.handle(request, myResponse)) {
                break;
            }
        }
        return myResponse;
    }

}

//测试
public class InterceptorChainTest {

    public static void main(String[] args) {
        InterceptorChain interceptorChain = new InterceptorChain();

        interceptorChain.addInterceptor(new AuthInterceptor())
                .addInterceptor(new WhiteListInterceptor())
                .addInterceptor(new LogInterceptor());

        MyResponse myResponse = interceptorChain.submit(new MyRequest("xxxxxx", "第一个请求","测试请求内容", "192.168.1.1"));
        System.out.println("执行结果: " + myResponse);

        System.out.println("===========================================");

        MyResponse myResponse1 = interceptorChain.submit(new MyRequest(null, "第二个请求","测试请求内容", "192.168.1.1"));
        System.out.println("没有传递token执行结果: " + myResponse1);

        System.out.println("===========================================");

        MyResponse myResponse2 = interceptorChain.submit(new MyRequest("xxxxxx", "第三个请求","测试请求内容", "111.168.1.1"));
        System.out.println("非内网执行结果: " + myResponse2);

        System.out.println("===========================================");
    }


}

```