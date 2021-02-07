---
title: java设计模式-策略模式
date: 2020-11-03 09:40:30
categories: [java, 设计模式] 
tags: [java, 设计模式]
---

# 前言

策略模式(Strategy): 定义了一系列算法，并将每个算法封装起来，使他们可以相互替换，且算法的变化不会影响到使用算法的客户。需要设计一个接口，为一系列实现类提供统一的方法，多个实现类实现该接口，设计一个抽象类（可有可无，属于辅助类）即使用策略(指定一个策略或者使用默认策略)的上下文

它实际上指，在一个方法中，**流程是确定的**，但是，某些**关键步骤的算法依赖调用方传入的策略**，这样，传入不同的策略，即可获得不同的结果，大大增强了系统的灵活性。

> 策略模式的决定权在用户，系统本身提供不同算法的实现，新增或者删除算法，对各种算法做封装。因此，策略模式多用在算法决策系统中，外部用户只需要决定用哪个算法即可。

策略模式的核心思想是在一个计算方法中**把容易变化的算法抽出来作为“策略”参数传进去**，从而使得新增策略不必修改原有逻辑。通过扩展策略，不必修改主逻辑，即可获得新策略的结果。

策略模式在Java标准库中应用非常广泛，如Arrays.sort(T[] a, Comparator<? super T> c), 通过传入不同的Comparator实现不同的排序算法就是一种非常典型的策略模式

 <!-- more -->


# 实现

实现商品折扣计算

```
┌───────────────┐      ┌─────────────────┐
│DiscountContext│─ ─ ─>│DiscountStrategy │
└───────────────┘      └─────────────────┘
                                ▲
                                │ ┌─────────────────────┐
                                ├─│ VipDiscountStrategy │
                                │ └─────────────────────┘
                                │ ┌─────────────────────┐
                                └─│OverDiscountStrategy │
                                  └─────────────────────┘
```

```java
/**
 * 折扣策略
 */
public interface DiscountStrategy {

    BigDecimal getDiscount(BigDecimal total);

}

/**
 * 会员折扣策略
 */
public class VipDiscountStrategy implements DiscountStrategy {

    @Override
    public BigDecimal getDiscount(BigDecimal total) {
        //会员打8折
        return total.multiply(new BigDecimal("0.2")).setScale(2, RoundingMode.DOWN);
    }
}

/**
 * 满减折扣策略
 */
public class OverDiscountStrategy implements DiscountStrategy{
    @Override
    public BigDecimal getDiscount(BigDecimal total) {
        // 满100减20优惠:
        return total.compareTo(BigDecimal.valueOf(100)) >= 0 ? BigDecimal.valueOf(20) : BigDecimal.ZERO;
    }
}

/**
 * 折扣策略上下文
 */
public class DiscountStrategyContext {

    //设置默认策略
    private DiscountStrategy strategy = new OverDiscountStrategy();

    public void setStrategy(DiscountStrategy strategy) {
        this.strategy = strategy;
    }

    public BigDecimal calculatePrice(BigDecimal total) {
        return total.subtract(this.strategy.getDiscount(total)).setScale(2);
    }
}

/**
 * 策略模式测试类
 */
public class DiscountStrategyTest {

    public static void main(String[] args) {
        DiscountStrategyContext discountStrategyContext = new DiscountStrategyContext();

        BigDecimal bigDecimal1 = discountStrategyContext.calculatePrice(new BigDecimal(105));
        System.out.println("使用默认策略(满100减20)时: " + bigDecimal1);

        //修改使用会员策略
        discountStrategyContext.setStrategy(new VipDiscountStrategy());
        BigDecimal bigDecimal2 = discountStrategyContext.calculatePrice(new BigDecimal(105));
        System.out.println("使用会员策略时: " + bigDecimal2);
    }

}

```