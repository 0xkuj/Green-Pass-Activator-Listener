//
//  UIImage+Gif.h
//  GifTest
//
//  Created by daewook kim on 2016. 9. 6..
//  Copyright © 2016년 daewook kim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Gif)

/**
 * Make a animated gif from NSData.
 */
+ (UIImage * _Nullable)gifWithData:(NSData * _Nonnull)data;

/**
 * Make a animated gif from NSURL.
 */
+ (UIImage * _Nullable)gifWithURL:(NSURL * _Nonnull)url;

/**
 * Get image count from the gif image data.
 */
+ (int)gifImageCountWithData:(NSData * _Nonnull)data;


@end
