---
title: javaFx-属性绑定
date: 2020-11-19 18:12:43
categories: [java, javafx] 
tags: [java, javafx]
---

# 前言

javafx.beans.property包提供了丰富的Property类用于对java对象中的属性和javaFX UI控件进行绑定，可达到：
* 在任意位置修改java对象的值时可实时更新绑定的UI控件的显示，无需手动编写更新方法
* javaFX UI控件进行变化时(如用户输入内容)，实时写入对应的java对象中，无需手动设置

java属性 | javaFx对应Property | 绑定构建类
---|---|---
int | IntegerProperty | JavaBeanIntegerPropertyBuilder
Integer | ObjectProperty\<Integer> | JavaBeanObjectPropertyBuilder
long | LongProperty | JavaBeanLongPropertyBuilder
Long | ObjectProperty\<Long> | JavaBeanObjectPropertyBuilder
String | StringProperty | JavaBeanStringPropertyBuilder
... | ... | ...

> 需要注意的是，如果java对象中的属性为基本数据类型的包装类，则不能直接使用对应的Property，需使用ObjectProperty<T>, 否则在属性值为null时会报空指针异常(原因是其内部都是使用基本数据类型转换的，感兴趣可以看看源码中的实现)

 <!-- more -->

# 实现

下面我们就来看看如何实现的

* 新建简单javaBean

```
public class MyJavaBean implements Serializable {

    private int myInt;

    private Integer myInteger;

    private String myString;

    public int getMyInt() {
        return myInt;
    }

    public void setMyInt(int myInt) {
        this.myInt = myInt;
    }

    public Integer getMyInteger() {
        return myInteger;
    }

    public void setMyInteger(Integer myInteger) {
        this.myInteger = myInteger;
    }


    public String getMyString() {
        return myString;
    }

    public void setMyString(String myString) {
        this.myString = myString;
    }

    @Override
    public String toString() {
        return "MyJavaBean{" +
                "myInt=" + myInt +
                ", myInteger=" + myInteger +
                ", myString='" + myString + '\'' +
                '}';
    }
}

```

* 新建javaFxWrapper类，用于实现javaBean与javaFx UI控件的属性绑定

重点在于**JavaBeanObjectPropertyBuilder**等的使用

```
public class MyJavaBeanFxWrapper {

    private MyJavaBean myJavaBean;

    private IntegerProperty myInt;

    private ObjectProperty<Integer> myInteger;

    private StringProperty myString;

    public MyJavaBeanFxWrapper(MyJavaBean myJavaBean) throws NoSuchMethodException {
        this.myJavaBean = myJavaBean;
        intProperty();
    }

    private MyJavaBeanFxWrapper() {
    }

    @SuppressWarnings({"unchecked"})
    private void intProperty() throws NoSuchMethodException {

        myInt = JavaBeanIntegerPropertyBuilder.create().bean(this.myJavaBean).name("myInt").build();

        //IntegerProperty如果遇到bean中属性值为null时，初始化会报错(内部使用int，转换出错)，故需使用ObjectProperty<Integer>
        myInteger = JavaBeanObjectPropertyBuilder.create().bean(this.myJavaBean).name("myInteger").build();

        myString = JavaBeanStringPropertyBuilder.create().bean(this.myJavaBean).name("myString").build();
    }

    public MyJavaBean getMyJavaBean() {
        return myJavaBean;
    }

    public void setMyJavaBean(MyJavaBean myJavaBean) throws NoSuchMethodException {
        this.myJavaBean = myJavaBean;
        intProperty();
    }

    public int getMyInt() {
        return myInt.get();
    }

    public IntegerProperty myIntProperty() {
        return myInt;
    }

    public Integer getMyInteger() {
        return myInteger.get();
    }

    public ObjectProperty<Integer> myIntegerProperty() {
        return myInteger;
    }


    public String getMyString() {
        return myString.get();
    }

    public StringProperty myStringProperty() {
        return myString;
    }

}

```

> 一个比较好的习惯就是两个对象中的属性命名尽量保持一致，可以减少因属性名不一致造成的绑定失败的概率

* Controller中进行绑定
  
```
public class Controller implements Initializable {

    public Label intLabel, integerLabel, stringLabel;

    public TextField intTextField, integerTextField, stringTextField;

    private MyJavaBeanFxWrapper myJavaBeanFxWrapper;
    private MyJavaBean myJavaBean;

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        try {
            //定义java对象
            myJavaBean = new MyJavaBean();

            //将java对象设置到javafx辅助类中，以支持属性绑定
            myJavaBeanFxWrapper = new MyJavaBeanFxWrapper(myJavaBean);

            //控件只做显示, 单向绑定即可
            intLabel.textProperty().bind(myJavaBeanFxWrapper.myIntProperty().asString());
            integerLabel.textProperty().bind(myJavaBeanFxWrapper.myIntegerProperty().asString());
            stringLabel.textProperty().bind(myJavaBeanFxWrapper.myStringProperty());

            //控件可编辑，双向绑定
            intTextField.textProperty().bindBidirectional(myJavaBeanFxWrapper.myIntProperty(), new StringConverter<>() {
                @Override
                public String toString(Number object) {
                    return String.valueOf(object);
                }

                @Override
                public Number fromString(String string) {
                    return Integer.valueOf(string);
                }
            });

            integerTextField.textProperty().bindBidirectional(myJavaBeanFxWrapper.myIntegerProperty(), new StringConverter<>() {
                @Override
                public String toString(Integer object) {
                    return String.valueOf(object);
                }

                @Override
                public Integer fromString(String string) {
                    if("".equals(string)) {
                        return null;
                    }
                    return Integer.valueOf(string);
                }
            });

            stringTextField.textProperty().bindBidirectional(myJavaBeanFxWrapper.myStringProperty());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

...
}
```

以上就达到了在不破坏原有javabean的基础上通过新建一个javaFx的辅助类，即可实现UI与数据对象的绑定，大大方便了javaFx的的日常开发

> 日常开发时建议将java对象设置到javaFx辅助类中后，就直接使用javaFx的辅助类进行操作，只有最后需要保存或者传递时才获取java原始对象

## list的绑定

javaFx中承载list数据的控件一般为listView，下面我们就演示下如何进行list的绑定

* javabean中新增list属性

```
public class MyJavaBean implements Serializable { 

    ...

    private List<String> myStringList;

    //省略getter/setter

    ...
}
```

* javaFxWrapper类中新增对应绑定

javaFx提供了**ObservableList**以实现list数据的动态监听，而UI控件也直接与这个ObservableList进行交互

```
public class MyJavaBeanFxWrapper { 
    ...
    private ListProperty<String> myStringList;

    @SuppressWarnings({"unchecked"})
    private void intProperty() throws NoSuchMethodException {
        ...
        myStringList = new SimpleListProperty<>(FXCollections.observableArrayList());
        if(myJavaBean.getMyStringList() != null) {
            myStringList.addAll(myJavaBean.getMyStringList());
        }

        //这里需手动设置到原始对象中(暂时没找到自动绑定的方法)
        //除非原始javabean中的list属性为ObservableList类型，才可以直接使用
        //myStringList = new SimpleListProperty<>(this.myJavaBean, "myStringList", myJavaBean.getMyStringList());
        //但如此javabean中就会引入javafx相关包，当然不介意这个的就可以改写使用
        myStringList.addListener((observable, oldValue, newValue) -> myJavaBean.setMyStringList(newValue));
    }

    public ObservableList<String> getMyStringList() {
        return myStringList.get();
    }

    public ListProperty<String> myStringListProperty() {
        return myStringList;
    }

    ...
}
```

* Controller中进行绑定
  
```
public class Controller implements Initializable { 

    ...
    public ListView<String> listView;

     @Override
    public void initialize(URL location, ResourceBundle resources) {
        try {
           //有关UI上的操作尽量都使用myJavaBeanFxWrapper来修改数据
            myJavaBeanFxWrapper.myStringListProperty().addAll("123", "456", "789");
            myJavaBeanFxWrapper.getMyStringList().addAll("www", "eee", "rrr");
            listView.itemsProperty().bind(myJavaBeanFxWrapper.myStringListProperty());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

}
```

> 当然以上做法有一个注意要点，即javabean在初始化后就不能自己通过setMyStringList来同步UI了(除非直接使用的ObservableList)，尽量都使用myJavaBeanFxWrapper或listView的getItems()进行操作，当javabean因为外在因素，如从网络上重新加载了，需重新设置到myJavaBeanFxWrapper

## 自定义对象绑定

javabean中除了基本数据类型及其包装类、String、list(集合)外，还可能会有自定义的对象属性，使用ObjectProperty即可, 但这种做法的颗粒度不太细，推荐还是新增对应自定义子对象的Fxwrapper，并在javabean变化时进行绑定初始化

示例代码使用的是java14+javafx14，[github-javafx-property-test](https://github.com/jonesun/javafx-property-test), 如果还是使用的javafx8则不需要pom.xml中对于openjfx的引用
