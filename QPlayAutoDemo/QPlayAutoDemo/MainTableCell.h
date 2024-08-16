//
//  MainTableCell.h
//  QPlayAutoDemo
//
//  Created by macrzhou on 2024/7/9.
//  Copyright © 2024 腾讯音乐. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Masonry.h"
#import "QPlayAutoDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface NewPlayingTagLabel : UILabel
@end

@interface MainTableCell : UITableViewCell
@property (nonatomic) UIButton *lyricButton;
- (void)updateWithItem:(QPlayAutoListItem *)item;
@end

NS_ASSUME_NONNULL_END
