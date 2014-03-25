//
// Copyright 2013 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

//
// Copyright (C) 2012-2013 Eloy Durán eloy.de.enige@gmail.com
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "UserNotifier.h"

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>
#import <objc/runtime.h>

#pragma mark -
#pragma mark NSBundle Hacks

static BOOL InstallFakeBundleIdentifierHook()
{
  Class class = objc_getClass("NSBundle");
  if (class) {
    method_exchangeImplementations(class_getInstanceMethod(class, @selector(bundleIdentifier)),
                                   class_getInstanceMethod(class, @selector(__bundleIdentifier)));
    return YES;
  }
  return NO;
}

static BOOL IsMavericks()
{
  return floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8;
}

static BOOL IsNSUserNotificationCenterAvailable()
{
  return NSClassFromString(@"NSUserNotificationCenter") != nil;
}

NSString * const XctoolNotifierBundleID = @"com.facebook.xctool";
NSString *_fakeBundleIdentifier = nil;

@implementation NSBundle (FakeBundleIdentifier)

- (NSString *)__bundleIdentifier;
{
  if (self == [NSBundle mainBundle]) {
    return _fakeBundleIdentifier ? _fakeBundleIdentifier : XctoolNotifierBundleID;
  } else {
    return [self __bundleIdentifier];
  }
}

@end

@implementation NSUserDefaults (SubscriptAndUnescape)

- (id)objectForKeyedSubscript:(id)key;
{
  id obj = [self objectForKey:key];
  if ([obj isKindOfClass:[NSString class]] && [(NSString *)obj hasPrefix:@"\\"]) {
    obj = [(NSString *)obj substringFromIndex:1];
  }
  return obj;
}

@end

#pragma mark -
#pragma mark Main methods

@interface UserNotifier ()
@end

@implementation UserNotifier

+ (void)initialize
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  // initialize the dictionary with default values depending on OS level
  NSDictionary *appDefaults;

  if (IsMavericks()) {
    appDefaults = @{@"sender": XctoolNotifierBundleID};
  } else {
    appDefaults = @{@"": @"message"};
  }

  // and set them appropriately
  [defaults registerDefaults:appDefaults];

  // Install the fake bundle ID hook so we can fake the sender.
  if (defaults[@"sender"]) {
    @autoreleasepool {
      if (InstallFakeBundleIdentifierHook()) {
        _fakeBundleIdentifier = defaults[@"sender"];
      }
    }
  }
}

+ (instancetype)shareInstance
{
  static UserNotifier *singleton;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (IsNSUserNotificationCenterAvailable()) {
      singleton = [[self alloc] init];
    } else {
      singleton = nil;
    }
  });
  return singleton;
}

#pragma mark - 
#pragma mark Public method

+ (void)sendNotificationWithTitle:(NSString *)title subtitle:(NSString *)subtitle message:(NSString *)message
{
  NSMutableDictionary *options = [NSMutableDictionary dictionary];

  [[self shareInstance] deliverNotificationWithTitle:title
                                            subtitle:subtitle
                                             message:message
                                             options:options
                                               sound:NSUserNotificationDefaultSoundName];
}

#pragma mark -
#pragma mark Private methods

- (void)deliverNotificationWithTitle:(NSString *)title
                            subtitle:(NSString *)subtitle
                             message:(NSString *)message
                             options:(NSDictionary *)options
                               sound:(NSString *)sound;
{
  NSUserNotification *userNotification = [[NSUserNotification alloc] init];
  userNotification.title = title;
  userNotification.subtitle = subtitle;
  userNotification.informativeText = message;
  userNotification.userInfo = options;
  userNotification.soundName = sound;

  NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
  [center scheduleNotification:userNotification];
}

@end
