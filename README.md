## Fonty
用来下载，缓存，注册和删除应用中的字体。

*Use it to download, cache, register and delete fonts in App.*

## CocoaPods
Podfile:

```ruby
platform :ios, '7.0'

target 'TargetName' do
pod 'Fonty'
end
```

## Usage
## Get Font

#### 1."main font"

列举出你的字体文件所在的URL并设置一个主字体：

*List URL strings of your font files and set one as main font:*

```objective-c
#import "FYHeader.h"

FYFontManager *fontManager = [FYFontManager sharedManager];

fontManager.fontURLStringArray = @[@"http://115.28.28.235:8088/SizeKnownFont.ttf", 
                                   @"http://115.28.28.235:8088/SizeUnknownFont.ttf"]; 
                                                                                                                  
fontManager.mainFontIndex = 1;
```
    	
用类别方法来获取主字体：

*Get main font by category method:*

```objective-c
#import "UIFont+FY_Fonty.h"
	
UIFont *font = [UIFont fy_mainFontOfSize:24.0f];
```
    	
#### 2. From URL
用类别方法来获取URL中的字体：

*Get font from URL by category method:*


```objective-c
#import "UIFont+FY_Fonty.h"

NSURL *URL = [NSURL URLWithString:@"http://115.28.28.235:8088/SizeUnknownFont.ttf"];
UIFont *font = [UIFont fy_fontWithURL:URL size:24.0f];
```



#### 3.PostScript name

如果你知道该字体的`PostScript name`，那么直接使用`UIFont.h`的方法获得字体：

*If you have got the PostScript name of the font, use the method in UIFont.h to get it:*


```objective-c
UIFont *font = [UIFont fontWithName:@"SentyChalk" size:24.0f];
```

用`字体书`打开字体文件，就能找到对应的`PostScript name`了。例如：

*Open the font file with Font Book to find the PostScript name, like this:*
![](https://github.com/s2mh/Fonty/raw/master/Screenshot/FindPostScriptNameInFontBook.png)


## Notification

字体下载，缓存和删除过程中，Fonty会在主线程中发出`FYFontStatusNotification`通知。你可以从该通知的`userInfo`字典里中获得一个`FYFontModel`的对象。`FYFontModel`描述了字体的信息，包括字体的下载URL，下载进度，状态和PostScriptName等。你可以通过接收这个通知，从而跟踪字体信息的变化。

*Fonty will post notifications called “FYFontStatusNotification” on the main thread, while it is downloading, caching or deleting fonts. You can get a "FYFontModel" type object in the "userInfo" dictionary of the notifications. The "FYFontModel" class decribes the font infomation, including the download URL, download progress, status and PostScriptName. You can handle this notificaion to track changes of the font information.*

## Demo

![](https://github.com/s2mh/Fonty/raw/master/Screenshot/Fonty-Demo.gif)
