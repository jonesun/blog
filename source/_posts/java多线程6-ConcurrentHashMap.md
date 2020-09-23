---
title: java多线程6-ConcurrentHashMap
date: 2020-08-11 16:10:50
categories: [java, 多线程]  
tags: [java, 多线程]
---

# HashMap

1、为什么用HashMap？
HashMap 是一个散列桶（数组和链表），它存储的内容是键值对 key-value 映射
HashMap 采用了数组和链表的数据结构，能在查询和修改方便继承了数组的线性查找和链表的寻址修改
HashMap 是非 synchronized，所以 HashMap 很快
HashMap 可以接受 null 键和值，而 Hashtable 则不能（原因就是 equlas() 方法需要对象，因为 HashMap 是后出的 API 经过处理才可以）

## 工作原理

我们使用 put(key, value) 存储对象到 HashMap 中，使用 get(key) 从 HashMap 中获取对象。当我们给 put() 方法传递键和值时，我们先对键调用 hashCode() 方法，计算并返回的 hashCode 是用于找到 Map 数组的 bucket 位置来储存 Node 对象

### put 过程

对Key 求 Hash 值，然后再计算下标：
- 如果没有碰撞，直接放入桶中（碰撞的意思是计算得到的 Hash 值相同，需要放到同一个 bucket 中）
- 如果碰撞了，以链表的方式链接到后面
- 如果链表长度超过阀值（TREEIFY THRESHOLD==8），就把链表转成红黑树，链表长度低于6，就把红黑树转回链表
- 如果节点已经存在就替换旧值
- 如果桶满了（容量16*加载因子0.75），就需要 resize（扩容2倍后重排）

# HashMap为什么是线程不安全的

HashMap会进行resize操作，在resize操作的时候会造成线程不安全

> resize: HashMap的扩容机制就是重新申请一个容量是当前的2倍的桶数组，然后将原先的记录逐个重新映射到新的桶里面，然后将原先的桶逐个置为null使得引用失效

HashMap在并发执行put操作时发生扩容，可能会导致节点丢失，产生环形链表等情况。 节点丢失，会导致数据不准 生成环形链表，会导致get()方法死循环。在jdk1.7中，由于扩容时使用头插法，在并发时可能会形成环状列表，导致死循环，在jdk1.8中改为尾插法，可以避免这种问题，但是依然避免不了**节点丢失**的问题。

HashTable类是线程安全的，它使用synchronize来做线程安全，全局只有一把锁，在线程竞争比较激烈的情况下hashtable的效率是比较低下的。因为当一个线程访问hashtable的同步方法时，其他线程再次尝试访问的时候，会进入阻塞或者轮询状态，比如当线程1使用put进行元素添加的时候，线程2不但不能使用put来添加元素，而且不能使用get获取元素。所以，竞争会越来越激烈。相比之下，ConcurrentHashMap使用了分段锁技术来提高了并发度，不在同一段的数据互相不影响，多个线程对多个不同的段的操作是不会相互影响的。每个段使用一把锁。所以在需要线程安全的业务场景下，推荐使用ConcurrentHashMap，而HashTable不建议在新的代码中使用，如果需要线程安全，则使用ConcurrentHashMap，否则使用HashMap就足够了

在迭代的过程中，ConcurrentHashMap 仅仅锁定 Map 的某个部分，而 Hashtable 则会锁定整个 Map

> HashMap 一定是线程不安全的吗？

在这个只读的场景下，它就是线程安全的


> java8中当链表长度大于8时，会转换为红黑树(引入红黑树就是为了查找数据快，解决链表查询深度的问题)

concurrentHashMap存在是为了解决并发问题

1、get方法不加锁；
2、put、remove方法要使用锁
jdk7使用锁分离机制(Segment分段加锁)
jdk8使用cas + synchronized 实现锁操作
3、Iterator对象的使用，运行一边更新，一遍遍历(可以根据原理自己拓展)
4、复合操作，无法保证线程安全，需要额外加锁保证
5、并发环境下，ConcurrentHashMap 效率较Collections.synchronizedMap()更高

put 过程

根据 key 计算出 hashcode
判断是否需要进行初始化
通过 key 定位出的 Node，如果为空表示当前位置可以写入数据，利用 CAS 尝试写入，失败则自旋保证成功
如果当前位置的 hashcode == MOVED == -1,则需要进行扩容
如果都不满足，则利用 synchronized 锁写入数据
如果数量大于 TREEIFY_THRESHOLD 则要转换为红黑树

get 过程
根据计算出来的 hashcode 寻址，如果就在桶上那么直接返回值
如果是红黑树那就按照树的方式获取值
就不满足那就按照链表的方式遍历获取值

> loadFactor 是装载因子，表示HashMap 满的程度，默认值为0.75f，设置成
0.75 有一个好处，那就是0.75 正好是3/4，而capacity 又是2 的幂。所以，两个
数的乘积都是整数。

> 对于一个默认的HashMap 来说，默认情况下，当其size 大于12(16*0.75) 时
就会触发扩容

> HashMap 中size 表示当前共有多少个KV 对，capacity 表示当前
HashMap 的容量是多少，默认值是16，每次扩容都是成倍的。loadFactor 是装
载因子，当Map 中元素个数超过loadFactor* capacity 的值时，会触发扩容。
loadFactor* capacity 可以用threshold 表示

> 如果用户通过构造
函数指定了一个数字作为容量，那么Hash 会选择大于该数字的第一个2 的幂作为容
量。(3->4、7->8、9->16)

> 在已知HashMap 中将要存放的KV 个数的时候，
设置一个合理的初始化容量可以有效的提高性能

> HashMap 中的扩容机制决定了每次扩容都需要重建hash 表，是非
常影响性能的。

> JDK 会默认帮我们计算一个相对合理的值当做初始容量。所谓合理值，其实是
找到第一个比用户传入的值大的2 的幂。

> 当我们明确知道HashMap 中元素的个数的时候，把默
认容量设置成expectedSize / 0.75F + 1.0F 是一个在性能上相对好的选择，但
是，同时也会牺牲些内存。

guava中可以利用以下公式来初始化容量:

```
//return (int) ((float) expectedSize / 0.75F + 1.0F);
Map<String, String> map = Maps.newHashMapWithExpectedSize(7);
```

> ConcurrentHashMap 在 Java 8 中存在一个 bug 会进入死循环,computeIfAbsent 中提供的函数中进行递归映射更新导致死锁(在进行 computeIfAbsent 的时候，里面还有一个 computeIfAbsent。而这两个 computeIfAbsent 它们的 key 对应的 hashCode 是一样的)

```
public class ConcurrentHashMapDemo {

    private Map<Integer, Integer> cache = new ConcurrentHashMap<>(15);

    public static void main(String[] args) {
        ConcurrentHashMapDemo ch = new ConcurrentHashMapDemo();
        System.out.println(ch.fibonaacci(80));
    }

    public int fibonaacci(Integer i) {
        if (i == 0 || i == 1) {
            return i;
        }
        return cache.computeIfAbsent(i, (key) -> {
            System.out.println("fibonaacci : " + key);
            return fibonaacci(key - 1) + fibonaacci(key - 2);
        });
    }

}

```

> 有序的Map实现类

- TreeMap 是通过实现 SortMap 接口，能够把它保存的键值对根据 key 排序，基于红黑树，从而保证 TreeMap 中所有键值对处于有序状态。
- LinkedHashMap 则是通过插入排序（就是你 put 的时候的顺序是什么，取出来的时候就是什么样子）和访问排序（改变排序把访问过的放到底部）让键值有序