//
//  UIView+MPTouchHandler.m
//  Boomerang
//
//  Created by Giri Senji on 4/29/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "UIView+MPTouchHandler.h"

@implementation UIView (MPTouchHandler)

- (BOOL)childOf:(UIView*)view
{
  UIView *parent = [self superview];
  while(parent != nil)
  {
    if([parent isEqual:view])
      return YES;
    parent = [parent superview];
  }
  return NO;
}

-(NSString *) getTextForXpath
{
  // Some views such as UITableViewCells will respond to text selector when it's actually a label inside that has the text
  if (![self isKindOfClass:NSClassFromString(@"UIWebBrowserView")] && [self respondsToSelector:@selector(text)] && [[self performSelector:@selector(text)] length] > 0)
  {
    NSString *value = [self performSelector:@selector(text)];
    if ([value length] > 0)
      return value;
  }
  
  return @"";
}

@end
