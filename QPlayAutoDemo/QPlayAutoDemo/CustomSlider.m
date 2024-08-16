//
//  CustomSlider.m
//  QMOpenApiDemo
//
//  Created by maczhou on 2021/11/2.
//

#import "CustomSlider.h"

@implementation CustomSlider

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event {
    CGRect bounds = self.bounds;
    bounds = CGRectInset(bounds, -50, -50);
    return CGRectContainsPoint(bounds, point);
}

@end
