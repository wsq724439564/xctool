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

#import <Foundation/Foundation.h>

#define kBuiltProductsDir @"BUILT_PRODUCTS_DIR"
#define kFullProductName @"FULL_PRODUCT_NAME"
#define kSdkName @"SDK_NAME"
#define kTestHost @"TEST_HOST"

@interface OCUnitTestQueryRunner : NSObject {
  NSDictionary *_buildSettings;
}

@property (nonatomic, assign) cpu_type_t cpuType;

- (instancetype)initWithBuildSettings:(NSDictionary *)buildSettings;
- (NSTask *)createTaskForQuery;
- (NSArray *)runQueryWithError:(NSString **)error;
- (NSString *)bundlePath;
- (NSString *)testHostPath;

@end
