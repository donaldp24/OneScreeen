//
//  UIManager.h
//  WhereNow
//
//  Created by Xiaoxue Han on 30/07/14.
//

#import <Foundation/Foundation.h>

@interface UIManager : NSObject

+ (UIColor *)cellHighlightColor;
+ (UIModalTransitionStyle)detailModalTransitionStyle;

+ (NSInteger)navbarStyle;
+ (UIColor *)navbarTintColor;
+ (NSDictionary *)navbarTitleTextAttributes;
+ (UIColor *)navbarBarTintColor;
+ (UIColor *)navbarBorderColor;

+ (UIBarButtonItem *)defaultBackButton:(id)target action:(SEL)action;

+ (id <UIViewControllerTransitioningDelegate>)pushTransitioingDelegate;

@end
