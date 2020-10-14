---
title: java-集合
date: 2020-10-14 10:13:16
categories: [java]  
tags: [java]
---

# 简介

Java的java.util包主要提供了以下三种类型的集合：

List：一种有序列表的集合，例如，按索引排列的Student的List；
Set：一种保证没有重复元素的集合，例如，所有无重复名称的Student的Set；
Map：一种通过键值（key-value）查找的映射表集合，例如，根据Student的name查找对应Student的Map

Java访问集合总是通过统一的方式——迭代器（Iterator）来实现，它最明显的好处在于无需知道集合内部元素是按什么方式存储的

# List

![list](list.png)

> ArrayList

ArrayList在内部使用了数组来存储所有元素。可以看作是能够自动增长容量的数组。例如，一个ArrayList拥有5个元素，实际数组大小为6（即有一个空位）

> LinkedList

通过链表实现了List接口。在LinkedList中，它的内部每个元素都指向下一个元素

LinkList是一个双链表,在添加和删除元素时具有比ArrayList更好的性能.但在get与set方面弱于ArrayList.当然,这些对比都是指**数据量很大或者操作很频繁**(当插入的数据量很小时，两者区别不太大，当插入的数据量大时，大约在容量的1/10之前，LinkedList会优于ArrayList，在其后就劣与ArrayList，且越靠近后面越差)

> CopyOnWriteArrayList

juc中提供的在并发编程中读多写少的场景下的list实现

> Vector
线程安全的List实现，在方法上加入synchronized。现在一般不推荐使用了，可用Collections.synchronizedList来包装集合使用

## 与Array的区别及转换

数组和List类似，也是有序结构，如果我们使用数组，在添加和删除元素的时候，会非常不方便。例如，从一个已有的数组{'A', 'B', 'C', 'D', 'E'}中删除索引为2的元素

这个“删除”操作实际上是把'C'后面的元素依次往前挪一个位置，而“添加”操作实际上是把指定位置以后的元素都依次向后挪一个位置，腾出来的位置给新加的元素。这两种操作，用数组实现非常麻烦

> list转array

```
Integer[] array = list.toArray(Integer[]::new);

//Integer[] array = list.toArray(new Integer[list.size()]);

```

> array转list

```
Integer[] array = { 1, 2, 3 };
List<Integer> list = List.of(array);

//java 11之前的版本，可以使用Arrays.asList(T...)方法把数组转换成List
```

要注意的是，返回的List不一定就是ArrayList或者LinkedList，因为List只是一个接口，如果我们调用List.of()，它返回的是一个只读List。对只读List调用add()、remove()方法会抛出UnsupportedOperationException

# Set

![set](set.png)

Set用于存储不重复的元素集合,如果我们只需要存储不重复的key，并不需要存储映射的value，那么就可以使用Set。Set实际上相当于只存储key、不存储value的Map。我们经常用Set用于去除重复元素

Set接口并不保证有序，而SortedSet接口则保证元素是有序的：

> HashSet

HashSet是无序的，因为它实现了Set接口，并没有实现SortedSet接口。HashSet内部通过维护一个HashMap来实现读取插入等功能

> TreeSet

TreeSet是有序的，因为它实现了SortedSet接口。使用TreeSet和使用TreeMap的要求一样，添加的元素必须正确实现Comparable接口，如果没有实现Comparable接口，那么创建TreeSet时必须传入一个Comparator对象, 可按照条件进行排序

> LinkedHashSet

LinkedHashSet底层使用LinkedHashMap来保存所有元素，它继承与HashSet，其所有的方法操作上又与HashSet相同, LinkedHashSet中的元素顺序是可以保证的，也就是说遍历序和插入序是一致的

**LinkedHashSet输出顺序是确定的，就是插入时的顺序**

> CopyOnWriteArraySet

juc中提供的在并发编程中读多写少的场景下的set实现，内部维护了一个CopyOnWriteArrayList，CopyOnWriteArraySet相对CopyOnWriteArrayList用来存储不重复的对象

> ConcurrentSkipListSet

juc中提供的在并发编程中线程安全的有序的集合，适用于高并发的场景。ConcurrentSkipListMap其实是TreeMap的并发版本，但实现是不一样的：ConcurrentSkipListSet是通过ConcurrentSkipListMap实现的，而TreeSet是通过TreeMap实现的

# Map

![map](map.png)

由于Java的集合设计非常久远，中间经历过大规模改进，我们要注意到有一小部分集合类是遗留类，不应该继续使用：

Hashtable：一种线程安全的Map实现；
Vector：一种线程安全的List实现；
Stack：基于Vector实现的LIFO的栈。
还有一小部分接口是遗留接口，也不应该继续使用：

Enumeration<E>：已被Iterator<E>取代。
