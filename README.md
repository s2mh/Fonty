# Fonty
[![Build Status](https://travis-ci.org/s2mh/Fonty.svg?branch=master)](https://travis-ci.org/s2mh/Fonty)

# When to use it?

You want to use thirdparty fonts in your iOS Apps, without putting the font files (each file can be dozens of MB) in bundle directly to expand your app significantly.

# What is it used for?

It can be used to:
- dowload and cache font files
- register and provide the fonts in the files
- clear cached files and unregister fonts

# Demo

![](https://raw.githubusercontent.com/s2mh/Fonty/master/Screenshot/Fonty-Demo.gif)

# How to use it?

### Prepare URLs

You need to make some downloadable URLs of font files. One way is by uploading your font files to GitHub, then you can get some URLs like:
*https://github.com/s2mh/FontFile/raw/master/Chinese/Simplified%20Chinese/ttc/Xingkai.ttc*. The format of the font file could be ttf, otf or ttc.

### Install

There are two ways to use Fonty in your project:

- using [CocoaPods](https://cocoapods.org/)
```ruby
target 'TargetName' do
pod 'Fonty'
end
```
- by cloning the Fonty directory into your repository

Import the header file `Fonty.h` when you use Fonty.

### Set URLs

Tell `FYFontManager`( manages files and fonts) where to download the font files each time your app is launched:

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
...

[FYFontManager setFileURLStrings:@[@"https://github.com/s2mh/FontFile/raw/master/Chinese/Simplified%20Chinese/ttc/Xingkai.ttc",
@"https://github.com/s2mh/FontFile/raw/master/Common/Regular/YuppySC-Regular.otf",
@"https://github.com/s2mh/FontFile/raw/master/English/Bold/Luminari.ttf",
@"https://github.com/s2mh/FontFile/raw/master/Common/Bold/LiHeiPro.ttf"]];

return YES;
}
```

It makes `FYFontManager` generate an array of `FYFontFile`(describes a font file) accordingly:

```objective-c
NSArray<FYFontFile *> *fontFiles = [FYFontManager fontFiles];
```

### Download Files & Register Fonts

Make `FYFontManager` download a font file:

```objective-c
[FYFontManager downloadFontFile:file];
```
`FYFontManager` will cache the file and register the fonts in it automatically. When the registering completes, a natification named `FYFontFileRegisteringDidCompleteNotification` will be posted. The file is associated with the notification:

```objective-c
- (void)completeFile:(NSNotification *)notification {
FYFontFile *file = [notification.userInfo objectForKey:FYFontFileNotificationUserInfoKey];
...
}
```

>Note：Each ttf or otf file contains only one font, a ttc file contains one or more fonts。

### Use Fonts

There is an array of `FYFontModel`(represents a registered font) in `FYFontFile`. We can get the font from `FYFontModel` directly:

```objective-c
FYFontModel *model = file.fontModels[0];
UIFont *font = [model.font fontWithSize:17.0];
```

In another way, if we have set the main font of `FYFontManager`, we can use it by a UIFont category method anywhere:

```objective-c
[FYFontManager setMainFont:font];
...

textView.font = [UIFont fy_mainFontWithSize:17.0];
```

### Delete Files & Unregister Fonts

Use `FYFontManager` to delete font files.  The fonts will be unregistered before the deletion:

```objective-c
[FYFontManager deleteFontFile:file];
```

### Archive

To make Fonty remember the settings, archive `FYFontManager ` before your app is terminated:

```objective-c
[FYFontManager archive];
```
