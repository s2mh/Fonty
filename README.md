#Fonty
[![Build Status](https://travis-ci.org/s2mh/Fonty.svg?branch=master)](https://travis-ci.org/s2mh/Fonty)

##Fonty是什么

这是一个处理iOS的自定义字体的开发框架。目前只有OC版本。

##Fonty有什么功能

该框架可以使应用在运行时动态地管理自定义字体，也可以用自定义字体替换系统内置的字体。

##为什么要有Fonty

iOS系统内置有248种字体，但是其中简体汉字只有6种：
![](https://github.com/s2mh/UIFontTesting/raw/master/Screenshot/PingFang%20SC.png)
这六种字体都属于PingFang SC，它们除了粗细之外没有差别。这导致原生iOS应用中的简体汉字样式比较单调。韩语字体和日语字体也是如此。可以参考我的[测试demo](https://github.com/s2mh/UIFontTesting)。

创建Fonty的目的为了丰富iOS的字体。

##Fonty是如何实现的

该框架的主要实现方案如下：

  - 将字体文件下载并保存到应用的bundle中。
  - 使用CoreText框架，注册字体文件并获取字体的PostScript name。
  - 使用UIFont的+fontWithName:size:方法获得字体。


##如何使用Fonty

使用Fonty有两个原则：

  - 先下载后使用。
  - 一个URLString对应一种字体。

###准备

你要有你想使用的字体文件（ttf或otf格式的）。你可以在网上找，也可以自己制作并传到自己的网站（比如GitHub）或者服务器上。
总之，你需要至少一个能用的字体文件地址。例如：

```objective-c
NSString *URLString = @"https://github.com/s2mh/Fonty/raw/master/FontFiles/SizeKnownFont.ttf";
```

###安装

使用CocoaPods的工程，可以使用CocoaPods安装：

```ruby
platform :ios, '7.0'

target 'TargetName' do
pod 'Fonty'
end
```
没有使用CocoaPods的工程，可以直接将框架下的文件直接复制到工程目录下。

###管理字体

Fonty是按照`门面模式`设计的，它的门面是`FYFontManager`。也就是说，框架的使用者主要使用的是`FYFontManager`。

####处理字体文件

<a name="DownloadFontFile"></a>`FYFontManager`包含了开始，暂停和取消下载字体文件，以及删除已下载的字体文件的方法：

```objective-c
+ (void)downloadFontWithURLString:(NSString *)URLString;

+ (void)cancelDownloadingFontWithURLString:(NSString *)URLString;

+ (void)pauseDownloadingWithURLString:(NSString *)URLString;

+ (void)deleteFontWithURLString:(NSString *)URLString;
```

####获得字体

`FYFontManager`提供了获得字体的方法：

```objective-c
+ (UIFont *)fontWithURLString:(NSString *)URLString size:(CGFloat)size;
```
为了方便起见，Fonty给UIFont添加了一个`FY_Fonty`类别。只需要加入头文件*UIFont+FY_Fonty.h*，即可使用其中的方法：

```objective-c
+ (UIFont *)fy_fontWithURLString:(NSString *)URLString size:(CGFloat)size;
```

可以像这样使用：

```objective-c
#import "UIFont+FY_Fonty.h"

label.font = [UIFont fy_fontWithURLString:downloadURLString size:16.0f];
```

###管理多种字体

Fonty可以同时管理多种字体。

####导入字体数组

把需要被Fonty管理的字体文件的URLString装在NSArray中，作为参数传给`FYFontManager`的这个方法：

```objective-c
+ (void)setFontURLStringArray:(NSArray<NSString *> *)fontURLStringArray;
```

建议在应用的AppDelegate中调用：

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [FYFontManager setFontURLStringArray:@[@"https://github.com/s2mh/Fonty/raw/master/FontFiles/SizeKnownFont.ttf",
                                           @"http://115.28.28.235:8088/SizeUnknownFont.ttf"]];
    return YES;
}
```

####字体信息

`FYFontManager`会为每个加入的URLString创建一个`FYFontModel`对象。可以从`FYFontManager`的另一个数组：

```objective-c
@property (nonatomic, strong, readonly, class) NSArray<FYFontModel *> *fontModelArray;
```
中获得这些对象。`FYFontModel`用于描述了字体当前的信息，包括字体的下载URL，下载进度，状态，类型和PostScript name等。[FYFontModel.h](https://github.com/s2mh/Fonty/blob/master/Fonty/FYFontModel.h)

####按序号获取字体

有了字体信息的数组，我们就能按序号获取字体。当然你得先[下载字体文件](#DownloadFontFile)。

```objective-c
+ (UIFont *)fontAtIndex:(NSUInteger)index size:(CGFloat)size;
```
注意：序号不要越界。

####设置主字体

如果在字体数组中，有一种最常用的字体，那么你可以把它设为`主字体`，也就是把它对应的序号设为`主序号`。设置的方法是把序号赋值给`FYFontManager.mainFontIndex`：

```objective-c
@property (nonatomic, assign, class) NSUInteger mainFontIndex;
```

例如：

```objective-c
FYFontManager.mainFontIndex = 0; // 把字体数组的第一种字体设为主字体
```
####获取主字体

获取主字体的方法很简单：

```objective-c
+ (UIFont *)mainFontOfSize:(CGFloat)size;
```

###改变字体风格

在我们原本的工程中，通常使用UIFont的类方法

```objective-c
+ (UIFont *)systemFontOfSize:(CGFloat)fontSize
```
来获得`系统字体`。Fonty可以用`主字体`替换`系统字体`，从而改变整个应用字体的风格。方法也很简单：

```objective-c
FYFontManager.usingMainStyle = YES; // 恢复使用系统字体，则设为NO
```

###bold版本和italic版本

为了突出重点，上述介绍的用法忽略了`系统字体`的另外两种类型`bold`和`italic`：

```objective-c
+ (UIFont *)boldSystemFontOfSize:(CGFloat)fontSize;
+ (UIFont *)italicSystemFontOfSize:(CGFloat)fontSize;
```
Fonty在`FYFontManager`中提供了与上述用法相似的`bold版本`和`italic版本`的属性和方法：

```objective-c
+ (void)setBoldFontURLStringArray:(NSArray<NSString *> *)boldFontURLStringArray;
+ (void)setItalicFontURLStringArray:(NSArray<NSString *> *)italicFontURLStringArray;

+ (UIFont *)boldFontAtIndex:(NSUInteger)index size:(CGFloat)size;
+ (UIFont *)italicFontAtIndex:(NSUInteger)index size:(CGFloat)size;

@property (nonatomic, strong, readonly, class) NSArray<FYFontModel *> *boldFontModelArray;
@property (nonatomic, strong, readonly, class) NSArray<FYFontModel *> *italicFontModelArray;

@property (nonatomic, assign, class) NSUInteger mainBoldFontIndex;
@property (nonatomic, assign, class) NSUInteger mainItalicFontIndex;

+ (UIFont *)mainBoldFontOfSize:(CGFloat)size;
+ (UIFont *)mainItalicFontOfSize:(CGFloat)size;
```

###字体信息变化的通知

程序运行时，下载，缓存和删除会导致字体信息的变化，`FYFontManager`会在主线程中发出`FYFontStatusNotification`通知。通知的`userInfo`字典里中获得一个key值为`FYFontStatusNotificationKey `的`FYFontModel`对象：

```objective-c
[[NSNotificationCenter defaultCenter] postNotificationName:FYFontStatusNotification
                                                    object:self
                                                  userInfo:@{FYFontStatusNotificationKey:model}];
```
监听这个通知，可以实时跟踪字体信息的变化。
