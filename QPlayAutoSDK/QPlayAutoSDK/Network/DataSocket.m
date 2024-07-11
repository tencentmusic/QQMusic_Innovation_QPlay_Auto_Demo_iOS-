//
//  DataSocket.m
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import "DataSocket.h"
#import "CocoaAsyncSocket.h"
#import "QMNetworkHelper.h"
#import "QMMacros.h"

@interface DataSocket()<GCDAsyncSocketDelegate>

@property (nonatomic,strong) GCDAsyncSocket *tcpSocket;
@property (nonatomic,strong) GCDAsyncSocket *qmSocket;
@end

@implementation DataSocket

- (void)start
{
    if(self.tcpSocket!=nil)
    {
        return;
    }
    self.tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
//    [self.tcpSocket setAutoDisconnectOnClosedReadStream:NO];
    NSError *error = nil;
    if (![self.tcpSocket acceptOnPort:LocalDataPort error:&error])
    {
        NSLog(@"Error acceptOnPort: %@", error);
        return;
    }
}

- (void)stop
{
    if(self.qmSocket!=nil)
    {
        if(self.qmSocket.isConnected)
            [self.qmSocket disconnect];
        self.qmSocket = nil;
    }
    if(self.tcpSocket!=nil)
    {
        if(self.tcpSocket.isConnected)
            [self.tcpSocket disconnect];
        self.tcpSocket = nil;
    }
}

#pragma mark GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    if(newSocket==nil)
        return;
    if(self.qmSocket!=nil)
    {
        NSLog(@"dataSocket cliet socket is exist already. new:%@ %d",newSocket.connectedHost,newSocket.connectedPort);
        return;
    }
    self.qmSocket = newSocket;
    [ self.qmSocket readDataWithTimeout:-1 tag:0];
    NSLog(@"dataSocket didAcceptNewSocket:%@ %d",newSocket.connectedHost,newSocket.connectedPort);
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err;
{
    NSLog(@"dataSocket connect error:%@",err);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"dataSocket didReadData(%ld):%lu",tag,(unsigned long)data.length);
    if ([self.delegate respondsToSelector:@selector(onDataSocket:recvData:)])
    {
        [self.delegate onDataSocket:self recvData:data];
    }
    [sock readDataWithTimeout:-1 tag:0];
}


@end

