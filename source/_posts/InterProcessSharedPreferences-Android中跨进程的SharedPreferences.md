---
title: InterProcessSharedPreferences-Android中跨进程的SharedPreferences
date: 2016-12-08 08:33:50
categories: android
tags: [android, jonesun]  
---

解决android中的SharedPreferences不能跨进程读写的问题.

 <!-- more -->
 
# 用法 #

## Android Studio ##

- 选择添加:
```
	compile project(':interprocesssharedpreferences')
```
- 或者	
```
	compile 'jone.common.android.data.sharedPreferences:interprocesssharedpreferences:1.0.0' 
	//如果获取不到，则加入 maven { url 'http://dl.bintray.com/sunjoner7/maven' }
```
- 在AndroidManifest.xml注册
```
	<!--authorities 规则：应用的包名 + ".InterProcessContentProvider"-->
    <provider
        android:name="jone.common.android.data.sharedPreferences.InterProcessContentProvider"
        android:authorities="jone.common.android.data.sharedPreferences.sample.InterProcessContentProvider"
        android:enabled="true"
        android:exported="true" />
```
## Eclipse ##
	
	自行copy[源码](https://github.com/jonesun/InterProcessSharedPreferences)。
	
## 用法示例

### 普通读写

```java
InterProcessSharedPreferences interProcessSharedPreferences = InterProcessSharedPreferences.getInstance(getApplication());
interProcessSharedPreferences.putString("testStr", edit_value.getText().toString()); //写入
interProcessSharedPreferences.getString("testStr", "empty"); //读取
interProcessSharedPreferences.remove("testStr"); //删除
```

### 监听

```java
 InterProcessSharedPreferences interProcessSharedPreferences = InterProcessSharedPreferences.getInstance(getApplication());
 
 ISharedPreferences.OnSharedPreferenceChangeListener onSharedPreferenceChangeListener = new ISharedPreferences.OnSharedPreferenceChangeListener() {
         @Override
         public void onSharedPreferenceChanged(ISharedPreferences sharedPreferences, String key) {
             Log.e(TAG, "interProcessSharedPreferences--onSharedPreferenceChanged>>key: " + key + " value: " + sharedPreferences.getString(key, "empty"));
         }
     };
     
 //监听(onCreate)
 interProcessSharedPreferences.registerOnSharedPreferenceChangeListener(onSharedPreferenceChangeListener); 
 
 //取消监听(onDestroy 不需要监听时一定要取消监听)
 interProcessSharedPreferences.unregisterOnSharedPreferenceChangeListener(onSharedPreferenceChangeListener);
```
