---
title: java设计模式-中介者模式
date: 2020-11-05 13:58:34
categories: [java, 设计模式] 
tags: [java, 设计模式]
---

# 前言

中介者模式(Mediator): 用一个中介对象来封装一系列的对象交互。中介者使各个对象不需要显式地相互引用，从而使其耦合松散，而且可以独立地改变它们之间的交互。

中介模式是通过引入一个中介对象，把多边关系变成多个双边关系，从而简化系统组件的交互耦合度。

中介者模式也是用来降低类类之间的耦合的，因为如果类类之间有依赖关系的话，不利于功能的拓展和维护，因为只要修改一个对象，其它关联的对象都得进行修改。如果使用中介者模式，只需关心和Mediator类的关系，具体类类之间的关系及调度交给Mediator就行，这有点像spring容器的作用。

> Mediator模式经常用在有众多交互组件的UI上。为了简化UI程序，MVC模式以及MVVM模式都可以看作是Mediator模式的扩展。

- 各个UI组件互不引用，这样就减少了组件之间的耦合关系；
- Mediator用于当一个组件发生状态变化时，根据当前所有组件的状态决定更新某些组件；
- 如果新增一个UI组件，我们只需要修改Mediator更新状态的逻辑，现有的其他UI组件代码不变。

 <!-- more -->

 # 实现

 我们来模拟下RadioButton的实现: 单选框，需保证在同一组中的单选框只能选中一个

 ```java
 /**
 * 单选框
 */
public class RadioButton {

    private boolean select = false;

    private String id;

    public RadioButton(String id) {
        this.id = id;
    }

    public boolean isSelect() {
        return select;
    }

    public void setSelect(boolean select) {
        this.select = select;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }
}


/**
 * 单选框组
 */
public class RadioGroup {

    private final Map<String, RadioButton> radioButtonMap = new LinkedHashMap<>();

    public void add(RadioButton radioButton) {
        radioButtonMap.put(radioButton.getId(), radioButton);
    }

    public void addAll(RadioButton... radioButtons) {
        Arrays.stream(radioButtons).forEach(this::add);

    }

    public void select(String radioId) {
        RadioButton radioButton = radioButtonMap.getOrDefault(radioId, null);
        if(radioButton != null) {
            radioButtonMap.forEach((id, radioButton1) -> {
                if(id.equals(radioId)) {
                    radioButton1.setSelect(true);
                } else {
                    radioButton1.setSelect(false);
                }
            });
        }
    }

    public RadioButton getSelect() {
        return radioButtonMap.values().stream().filter(RadioButton::isSelect).findFirst().orElse(null);
    }

    public List<RadioButton> getAll() {
        return new ArrayList<>(radioButtonMap.values());
    }

}


public class RadioMediatorTest {

    public static void main(String[] args) {
        RadioGroup radioGroup = new RadioGroup();

        RadioButton radioButton1 = new RadioButton("radio1");

        RadioButton radioButton2 = new RadioButton("radio2");

        RadioButton radioButton3 = new RadioButton("radio3");

        radioGroup.addAll(radioButton1, radioButton2, radioButton3);

        //查看选择情况
        radioGroup.getAll().forEach(radioButton -> System.out.println(radioButton.getId() + " select: " + radioButton.isSelect()));

        //选中radioButton2
        radioGroup.select(radioButton2.getId());

        System.out.println("===============================");

        //再次查看选择情况
        radioGroup.getAll().forEach(radioButton -> System.out.println(radioButton.getId() + " select: " + radioButton.isSelect()));

        System.out.println("选中了: " + radioGroup.getSelect().getId());
    }

}

//输出
radio1 select: false
radio2 select: false
radio3 select: false
===============================
radio1 select: false
radio2 select: true
radio3 select: false
选中了: radio2
 ```

 以上通过引入RadioGroup这个中介，就可以模拟实现单选按钮的功能，同样的可以再加上其他组件实现单选的话，只要在中介类中引入即可，组件之间相互不关联
