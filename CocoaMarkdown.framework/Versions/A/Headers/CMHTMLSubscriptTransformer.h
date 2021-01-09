//
//  CMHTMLSubscriptTransformer.h
//  CocoaMarkdown
//
//  Created by Indragie on 1/16/15.
//  Copyright (c) 2015 Indragie Karunaratne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMHTMLScriptTransformer.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

/**
 *  Transforms HTML subscript elements (<sub>) into attributed strings.
 */
@interface CMHTMLSubscriptTransformer : CMHTMLScriptTransformer

/**
 *  Initializes the receiver with the default font ratio (0.7)
 *
 *  @return An initialized instance of the receiver.
 */
- (instancetype)init;

/**
 *  Initializes the receiver with a custom font size ratio.
 *
 *  @param ratio The factor to multiply the existing font point
 *  size by to calculate the size of the subscript font.
 *
 *  @return An initialized instance of the receiver.
 */
- (instancetype)initWithFontSizeRatio:(CGFloat)ratio;

/**
 *  Initializes the receiver with a custom font size ratio and a custom baseline offset.
 *
 *  @param ratio The factor to multiply the existing font point
 *  size by to calculate the size of the superscript font.
 *  @param offset The offset for the baseline of the subscript.
 *
 *  @return An initialized instance of the receiver.
 */
- (instancetype)initWithFontSizeRatio:(CGFloat)ratio baselineOffset:(CGFloat)offset;

@end
