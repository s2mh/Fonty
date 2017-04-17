# Fonty
[![Build Status](https://travis-ci.org/s2mh/Fonty.svg?branch=master)](https://travis-ci.org/s2mh/Fonty)

# 使用场景

你希望在iOS App为用户提供第三方字体，但是不想把字体文件直接加进bundle导致安装包的体积增加。

# 主要操作

### 1 准备

准备几个可以下载的字体文件地址，例如`https://github.com/s2mh/FontFile/raw/master/Chinese/Simplified%20Chinese/ttc/Xingkai.ttc`。可以是ttf、otf或ttc格式。

### 2 导入

将Fonty库导入到你的工程中。你可以直接手动导入Fonty文件夹，也可以使用CocoaPods：

```ruby
target 'TargetName' do
pod 'Fonty'
end
```

使用时所需的头文件：

```objective-c
#import "Fonty.h"
```

### 3 配置

在AppDelegate中，将准备好的字体文件地址配置给Fonty：

```objective-c
[FYFontManager setFileURLStrings:@[@"https://github.com/s2mh/FontFile/raw/master/Chinese/Simplified%20Chinese/ttc/Xingkai.ttc",
@"https://github.com/s2mh/FontFile/raw/master/Common/Bold/LiHeiPro.ttf",
@"https://github.com/s2mh/FontFile/raw/master/English/Bold/Luminari.ttf",
@"https://github.com/s2mh/FontFile/raw/master/Common/Regular/YuppySC-Regular.otf"]];
```

FYFontManager（用于管理字体文件）会据此生成对应的FYFontFile对象（用于描述字体文件信息）：

```objective-c
NSArray<FYFontFile *> *fontFiles = [FYFontManager fontFiles];
```

### 4 下载&注册

用FYFontManager的下载字体文件:

```objective-c
[FYFontManager downloadFontFile:file];
```

下载完成后，Fonty会自动保存和注册字体文件。注册成功后，Fonty会发出`FYFontFileRegisteringDidCompleteNotification`通知。该通知包含已注册的文件：

```objective-c
- (void)completeFile:(NSNotification *)notification {
FYFontFile *file = [notification.userInfo objectForKey:FYFontFileNotificationUserInfoKey];
...
}
```

>注意：ttf和otf文件包含一种字体，ttc文件可能包含多个字体。

### 5 获得字体

已注册的字体文件包含一个FYFontModel对象数组，一个FYFontModel代表一种字体。可以直接从FYFontModel中获得字体：

```objective-c
FYFontModel *model = file.fontModels[0];
UIFont *font = [model.font fontWithSize:17.0];
```

也可以设置FYFontManager的mainFont，通过UIFont (FY_Fonty)分类的方法，便捷地获得字体：
```objective-c
[FYFontManager setMainFont:font];
...

textView.font = [UIFont fy_mainFontWithSize:17.0];
```

### 6 存档

在应用关闭前保存设置的信息，可保证每次应用下次启动后使用同样的字体。

```objective-c
[FYFontManager archive];
```
