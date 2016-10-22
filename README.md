## Fonty
Use it to download, cache and register your font.

## CocoaPods
Podfile:
```ruby
platform :ios, '7.0'

target 'TargetName' do
pod 'Fonty'
end
```

## Usage

### 1. By setting "main font"

- List URL strings of your font files and set one as main font:

```objective-c
#import "FYHeader.h"

FYFontManager *fontManager = [FYFontManager sharedManager];

fontManager.fontURLStringArray = @"http://115.28.28.235:8088/SizeKnownFont.ttf",
                                         @"http://115.28.28.235:8088/SizeUnknownFont.ttf"; 
                                                                                                                  
fontManager.mainFontIndex = 1;
```
    	
- Get main font by category method.

```objective-c
#import "UIFont+FY_Fonty.h"

self.label.font = [UIFont fy_mainFontOfSize:24.0f];
```
    	
### 2. From URL
- Get font from URL by category method:	

```objective-c
#import "UIFont+FY_Fonty.h"

NSURL *URL = [NSURL URLWithString:@"http://115.28.28.235:8088/SizeUnknownFont.ttf"];
self.label.font = [UIFont fy_fontWithURL:URL size:24.0f];
```

## Demo

![](https://github.com/s2mh/Fonty/raw/master/Screenshot/Fonty-Demo.gif)