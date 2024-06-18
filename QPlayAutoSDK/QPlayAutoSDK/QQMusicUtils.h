//
//  QQMusicUtils.h
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/7.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QQMusicUtils : NSObject

+ (NSDictionary*)paserURLParam:(NSURL *)url;

+ (NSString *)queryComponent:(NSURL*)url Named:(NSString *)name;

+ (id)objectWithJsonData:(NSData *)data error:(__autoreleasing NSError **)error targetClass:(Class)targetClass;

+ (NSString *)strWithJsonObject:(id)object;

+ (void)openUrl:(NSString*)strUrl;

+ (NSArray *)getArrayFromJSON:(NSDictionary *)json forKey:(NSString *)key;
+ (NSString *)getStringFromJSON:(NSDictionary *)json forKey:(NSString *)key;
+ (float)getFloatFromJSON:(NSDictionary *)json forKey:(NSString *)key;
+ (double)getDoubleFromJSON:(NSDictionary *)json forKey:(NSString *)key;
+ (int64_t)getInt64FromJSON:(NSDictionary *)json forKey:(NSString *)key;
+ (int)getIntegerFromJSON:(NSDictionary *)json forKey:(NSString *)key;
+ (NSNumber *)getNumberFromJSON:(NSDictionary *)json forKey:(NSString *)key;
+ (BOOL)getBoolFromJSON:(NSDictionary *)json forKey:(NSString *)key;
+ (NSDictionary *)getDictionaryFromJSON:(NSDictionary *)json forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
