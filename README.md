# What is Fonty?

[Fonty](https://github.com/s2mh/Fonty) is a plugin that allows you to use third-party ttf, otf or ttc fonts in your iOS applications without bundling font files directly into the package. It was developed for use with heavy font files for pictographic languages, like Chinese and Japanese, but can be used with any font.

Fonty can: 
-	Download and cache fonts files from an external server
-	Register fonts
-	Clear cached files and unregister fonts

# Demo

![](https://raw.githubusercontent.com/s2mh/Fonty/master/Screenshot/Fonty-Demo.gif)

# How to use it

### Prepare URLs

Upload font files to your preferred host and note the font file URL. For example, hosting Xingkai.ttc on Github might produce the URL:
*https://github.com/s2mh/FontFile/raw/master/Chinese/Simplified%20Chinese/ttc/Xingkai.ttc*. 

### Install

There are two ways to call Fonty in your project:

- using [CocoaPods](https://cocoapods.org/)
```ruby
target 'TargetName' do
pod 'Fonty', '~>2.0.0'
end
```
- by cloning the Fonty directory into your repository


### Set URLs

Tell FYFontManager( manages files and fonts) where to download the font files each time your app is launched:

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

This causes FYFontManager to generate the array FYFontFile: 

```objective-c
NSArray<FYFontFile *> *fontFiles = [FYFontManager fontFiles];
```

### Download Files & Register Fonts

To make FYFontManager download a font file:

```objective-c
[FYFontManager downloadFontFile:file];
```
FYFontManager will cache the file and register the fonts in it automatically. When the registration completes, the notification FYFontFileRegisterDidCompleteNotification will be posted. 

```objective-c
- (void)completeFile:(NSNotification *)notification {
    FYFontFile *file = [notification.userInfo objectForKey:FYFontFileNotificationUserInfoKey];
    ...
}
```

The file is associated with the notification. 

>Note：Each ttf or otf file contains only one font, a ttc file contains one or more fonts。

### Using Fonts in your App

FYFontFile contains the array FYFontModel which represents a registered font. We can get the font from FYFontModel directly:

```objective-c
FYFontModel *model = file.fontModels[0];
UIFont *font = [model.font fontWithSize:17.0];
```

Another method is to set the main font in FYFontManager, and call it via a UIFont category from anywhere: 

```objective-c
[FYFontManager setMainFont:font];
...

textView.font = [UIFont fy_mainFontWithSize:17.0];
```

### Delete Files & Unregister Fonts

Use FYFontManager to delete front files:

```objective-c
[FYFontManager deleteFontFile:file];
```

### Archive

To make Fonty remember your settings, archive FYFontManager before your app terminates:

```objective-c
[FYFontManager archive];
```
