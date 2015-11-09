//
//  UIView+MPTouchHandler.h
//  Boomerang
//
//  Created by Giri Senji on 4/29/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (MPTouchHandler)

- (BOOL)childOf:(UIView*)view;
-(NSString *) getTextForXpath;

@end
