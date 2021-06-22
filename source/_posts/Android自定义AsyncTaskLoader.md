---
title: Android自定义AsyncTaskLoader
categories: android
tags:
  - android
  - jonesun
abbrlink: 11b89789
date: 2016-10-20 15:28:03
---

Android3.0以后推出了Loader,用来异步加载数据的,配合ListView或者GridView等用Adapter作为数据源的来使用，非常方便。
下面是我自己封装的一个自定义的AsyncTaskLoader,可以异步加载List数据，留作以后备用。

<!-- more -->

## 自定义AsyncTaskLoader ##

```
import java.util.Collections;
import java.util.List;

import android.content.Context;
import android.support.v4.content.AsyncTaskLoader;

public class CustomListAsyncTaskLoader extends AsyncTaskLoader<List> {
	private List list;
    private LoadListener listener;
    public CustomListAsyncTaskLoader(Context context, LoadListener listener) {
        super(context);
        this.listener = listener;
    }

    @Override
    protected void onStartLoading() {
        // just make sure if we already have content to deliver
        if (list != null){
        	deliverResult(list);
        }
        
     // otherwise if something has been changed or first try
        if(takeContentChanged() || list == null){
        	forceLoad();
        }        
    }

    @Override
    protected void onStopLoading() {
        cancelLoad();
    }

    @Override
    protected void onReset() {
        super.onReset();
        onStopLoading();

        // clear reference to object
        // it's necessary to allow GC to collect the object
        // to avoid memory leaking
        list = null;
    }

    @Override
    public List loadInBackground() {
        // even if fail return empty list and print exception stack trace
    	list = Collections.unmodifiableList((List) listener.loading());
        return list;
    }
    
    public interface LoadListener {
    	List loading();
    }
}
```

## 使用样例 ##
```
	private LoaderManager.LoaderCallbacks<List> loaderCallbacks = new LoaderManager.LoaderCallbacks<List>() {
		@Override
        public Loader<List> onCreateLoader(int i, Bundle bundle) {
		progress_bar.setVisibility(View.VISITIY);
            return new CustomListAsyncTaskLoader(getActivity(), new LoadListener() {
				
				@Override
				public List loading() {
					return getDataList();//这里可以写自己的耗时的操作，如获取网络数据，获取数据库数据等
				}
			});
        }

        @Override
        public void onLoadFinished(Loader<List> listLoader, List list) {
        	progress_bar.setVisibility(View.GONE);
        	mAdapter.setData(list);
        }

        @Override
        public void onLoaderReset(Loader<List> listLoader) {
        	mAdapter.clear();
        }
    };
	
	
	//这个是自定义Adapter中的setData方法
	public void setData(List<T> dataList){
	        this.clear();
	        if(Build.VERSION.SDK_INT >= 11){
	        	this.addAll(dataList);
	        }else{
	        	for(T data : dataList){
	        		this.add(data);
	        	}
	        }
	        this.notifyDataSetChanged();
	}
```

## 关于Loader的使用如下 ##
```
if(loaderManager.getLoader(001) == null){
	loaderManager.initLoader(001, bundle1, loaderCallbacks); //bundle1是传递的数据，可以为空
}else{
	loaderManager.restartLoader(001, bundle1, loaderCallbacks);
}
```

时间原因，就不上传源码了。如果大家有兴趣交流，欢迎发邮箱sunr922@163.com。