//
//  ResultsViewController.h
//  QPlayAutoDemo
//
//  Created by macrzhou on 2024/7/31.
//  Copyright © 2024 腾讯音乐. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QPlayAutoSDK.h"

NS_ASSUME_NONNULL_BEGIN

@interface ResultsViewController : UIViewController
- (instancetype)initWithItems:(NSArray<QPlayAutoListItem *> *) items title:(NSString  *)title;
@end

NS_ASSUME_NONNULL_END
