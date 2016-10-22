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

### 1."main font"

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

self.label.font = [UIFont fy_mainFontOfSize:24.0f];
```
    	
### 2. From URL
用类别方法来获取URL中的字体：

*Get font from URL by category method:*

```objective-c
#import "UIFont+FY_Fonty.h"

NSURL *URL = [NSURL URLWithString:@"http://115.28.28.235:8088/SizeUnknownFont.ttf"];
self.label.font = [UIFont fy_fontWithURL:URL size:24.0f];
```

## Demo

![](https://github.com/s2mh/Fonty/raw/master/Screenshot/Fonty-Demo.gif)
