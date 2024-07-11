//
//  DataSocket.h
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class DataSocket;
@protocol DataSocketDelegate <NSObject>
- (void)onDataSocket:(DataSocket *)socket recvData:(NSData*)data;
@end

@interface DataSocket : NSObject
@property (nonatomic,weak) id<DataSocketDelegate> delegate;
- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
