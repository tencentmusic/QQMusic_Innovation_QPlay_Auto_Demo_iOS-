//
//  MainTableCell.m
//  QPlayAutoDemo
//
//  Created by macrzhou on 2024/7/9.
//  Copyright © 2024 腾讯音乐. All rights reserved.
//

#import "MainTableCell.h"
#import "SDWebImage.h"

@interface MainTableCell()
@property (nonatomic) UIImageView *albumImageView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *subtitleLabel;
@property (nonatomic) NewPlayingTagLabel *vipLabel;
@property (nonatomic) NewPlayingTagLabel *tryListenLabel;
@property (nonatomic) NewPlayingTagLabel *orginalLabel;
@end
@implementation MainTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.albumImageView.image = nil;
}


- (void)updateWithItem:(QPlayAutoListItem *)item {
    self.titleLabel.text = item.Name;
    self.lyricButton.hidden = !item.isSong;
    self.vipLabel.hidden = !item.isSong;
    self.tryListenLabel.hidden = !item.isSong;
    self.orginalLabel.hidden = !item.isSong;
    
    if(item.isFolder){
        self.subtitleLabel.text = item.SubName;
    }else if (item.isAlbum) {
        self.subtitleLabel.text = item.singer.name;
    } else if(item.isSong) {
        self.subtitleLabel.text = item.singer.name;
        if(item.isSVIP){
            self.vipLabel.hidden = NO;
            self.vipLabel.text = @"SVIP";
        }else if (item.isVIP){
            self.vipLabel.hidden = NO;
            self.vipLabel.text = @"VIP";
        }else {
            self.vipLabel.hidden = YES;
        }
        self.tryListenLabel.hidden = !item.isTryListen;
        self.orginalLabel.hidden = !item.isOrigin;
    }else{
        self.subtitleLabel.text = nil;
    }
    
    if(item.CoverUri.length){
        [self.albumImageView sd_setImageWithURL:[NSURL URLWithString:item.CoverUri]];
        self.albumImageView.hidden = NO;
    }else {
        self.albumImageView.hidden = YES;
        self.albumImageView.image = nil;
    }
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        if(item.CoverUri.length){
            make.leading.mas_equalTo(self.albumImageView.mas_trailing).offset(6);
        }else {
            make.leading.mas_equalTo(self.contentView.mas_leading).offset(12);
        }
        if(self.vipLabel.hidden){
            if(self.lyricButton.hidden){
                make.trailing.mas_equalTo(self.contentView.mas_trailing).offset(-6);
            }else {
                make.trailing.mas_equalTo(self.lyricButton.mas_leading).offset(-4);
            }
        }
        make.bottom.mas_equalTo(self.contentView.mas_centerY);
    }];
    if(self.tryListenLabel.isHidden == NO){
        [self.tryListenLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(self.titleLabel.mas_centerY);
            make.leading.mas_equalTo(self.vipLabel.isHidden?self.titleLabel.mas_trailing:self.vipLabel.mas_trailing).offset(2);
        }];
    }
}

- (void)commonInit {
    self.albumImageView = [[UIImageView alloc] init];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    self.titleLabel.font = [UIFont systemFontOfSize:15];
    self.titleLabel.textColor = UIColor.blackColor;
    [self.titleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.titleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.textAlignment = NSTextAlignmentLeft;
    self.subtitleLabel.font = [UIFont systemFontOfSize:12];
    self.subtitleLabel.textColor = [UIColor.blackColor colorWithAlphaComponent:0.5];
    [self.subtitleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.subtitleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    self.lyricButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.lyricButton setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    [self.lyricButton setTitle:@"歌词" forState:UIControlStateNormal];
    self.lyricButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    
    self.vipLabel = [[NewPlayingTagLabel alloc] init];
    self.vipLabel.textAlignment = NSTextAlignmentCenter;
    self.vipLabel.textColor = UIColor.blackColor;
    self.vipLabel.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.08];
    [self.vipLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.vipLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    self.orginalLabel = [[NewPlayingTagLabel alloc] init];
    self.orginalLabel.textAlignment = NSTextAlignmentCenter;
    self.orginalLabel.textColor = UIColor.blackColor;
    self.orginalLabel.text = @"原唱";
    self.orginalLabel.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.08];
    [self.orginalLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.orginalLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    self.tryListenLabel = [[NewPlayingTagLabel alloc] init];
    self.tryListenLabel.textAlignment = NSTextAlignmentCenter;
    self.tryListenLabel.textColor = UIColor.blackColor;
    self.tryListenLabel.text = @"试听";
    self.tryListenLabel.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.08];
    [self.tryListenLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    self.tryListenLabel.hidden = YES;
    [self.tryListenLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.contentView addSubview:self.albumImageView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.subtitleLabel];
    [self.contentView addSubview:self.lyricButton];
    [self.contentView addSubview:self.vipLabel];
    [self.contentView addSubview:self.tryListenLabel];
    [self.contentView addSubview:self.orginalLabel];
    
    [self.albumImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.contentView.mas_leading).offset(12);
        make.top.mas_equalTo(self.contentView.mas_top).offset(2);
        make.bottom.mas_equalTo(self.contentView.mas_bottom).offset(-2);
        make.width.mas_equalTo(self.albumImageView.mas_height);
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.albumImageView.mas_trailing).offset(6);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
    }];
    [self.vipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.titleLabel.mas_centerY);
        make.leading.mas_equalTo(self.titleLabel.mas_trailing).offset(3);
    }];
    [self.lyricButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.contentView.mas_trailing).offset(-6);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
        make.top.bottom.mas_equalTo(self.contentView);
        make.width.mas_equalTo(self.lyricButton.mas_height);
    }];
    [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.titleLabel);
        make.top.mas_equalTo(self.contentView.mas_centerY).offset(2);
    }];
    [self.orginalLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.subtitleLabel.mas_centerY);
        make.leading.mas_equalTo(self.subtitleLabel.mas_trailing).offset(2);
        make.trailing.mas_lessThanOrEqualTo(self.lyricButton.mas_leading).offset(-2);
    }];
}

@end

@interface NewPlayingTagLabel()
@property (nonatomic,assign) UIEdgeInsets padding;
@end
@implementation NewPlayingTagLabel

- (void)drawTextInRect:(CGRect)rect {
    self.font = [UIFont systemFontOfSize:9 weight:UIFontWeightRegular];
    self.padding = UIEdgeInsetsMake(1.5, 4, 1.5, 4);
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.padding)];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.cornerRadius = 2;
    self.layer.masksToBounds = YES;
}

- (CGSize)intrinsicContentSize {
    CGSize contentSize = [super intrinsicContentSize];
    contentSize.height += self.padding.top + self.padding.bottom;
    contentSize.width += self.padding.left + self.padding.right;
    return contentSize;
}

@end
