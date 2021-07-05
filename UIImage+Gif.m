//
//  UIImage+Gif.m
//  GifTest
//
//  Created by daewook kim on 2016. 9. 6..
//  Copyright © 2016년 daewook kim. All rights reserved.
//

#import "UIImage+Gif.h"
#import <ImageIO/ImageIO.h>

static const int MaxGapFPS         = 30;

@implementation UIImage (Gif)

#pragma mark - Public methods

+ (UIImage * _Nullable)gifWithData:(NSData * _Nonnull)data
{
    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)data, nil);
    if (source == nil) {
        NSLog(@"ERROR : CGImageSourceCreateWithData == nil");
        return nil;
    }
    UIImage *image = [UIImage animatedImageWithSource:source];
    CFRelease(source);
    
    return image;
}

+ (UIImage * _Nullable)gifWithURL:(NSURL * _Nonnull)url
{
    CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)url, nil);
    if (source == nil) {
        NSLog(@"ERROR : CGImageSourceCreateWithURL == nil");
        return nil;
    }
    UIImage *image = [UIImage animatedImageWithSource:source];
    CFRelease(source);
    
    return image;
}

+ (int)gifImageCountWithData:(NSData * _Nonnull)data;
{
    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)data, nil);
    if (source == nil) {
        NSLog(@"ERROR : CGImageSourceCreateWithData == nil");
        return 0;
    }
    int count = (int)CGImageSourceGetCount(source);
    CFRelease(source);

    return count;
}

#pragma mark - Private methods

+ (UIImage *)animatedImageWithSource:(CGImageSourceRef)source
{
    
    int count = (int)CGImageSourceGetCount(source);
    NSMutableArray<UIImage *> *images = [[NSMutableArray alloc] init];
    NSMutableArray *delays = [[NSMutableArray alloc] init];
    if (count == 0) {
        NSLog(@"ERROR : CGImageSourceGetCount == 0");
        return nil;
    }
    NSLog(@"count=%d", count);
    double totalDelay = 0;
    for (int i=0; i<count; i++) {
        // Add image
        CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, nil);
        
        [images addObject:[[UIImage alloc] initWithCGImage:image]];
        CGImageRelease(image);
        
        // Add delay
        int delay = [UIImage delayForImageAtIndex:i source:source];
        [delays addObject:[NSNumber numberWithInt:delay]];
        
        // Add to totalDelay
        totalDelay += delay;
    }
    
    // If the gif has only one image.
    if (count == 1) {
        return [images objectAtIndex:0];
    }
    
    // Calculate Greatest common divisor
    int gcd = [UIImage arrayGCD:delays];
    if (gcd <= (1.0/MaxGapFPS)*1000) { // FPS < MaxGapFPS
        gcd = (1.0/MaxGapFPS)*1000;
    }

    // Make frames
    NSMutableArray<UIImage *> *frames = [[NSMutableArray alloc] init];
    for (int i=0; i<count; i++) {
        UIImage *frame = [images objectAtIndex:i];
        int delay = [[delays objectAtIndex:i] intValue];
        [frames addObject:frame];
        for (int j =(delay-gcd)/gcd; j>0; j--) {
            [frames addObject:frame];
        }
    }
    
    // Make a animaged image.
    return [UIImage animatedImageWithImages:frames duration:totalDelay/1000.0]; // to seconds
}

+ (int)delayForImageAtIndex:(int)index source:(CGImageSourceRef)source
{
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    double delay = 0.1;
    if (properties) {
        CFDictionaryRef gifProperties = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
        if (gifProperties) {
            NSNumber *number = CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFUnclampedDelayTime);
            if (number == nil || [number doubleValue] == 0) {
                number = CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFDelayTime);
            }
            if ([number doubleValue]>0) {
                delay = [number doubleValue];
            }
        }
        CFRelease(properties);
    }
    return delay*1000; // to milliseconds
}

+ (int) arrayGCD:(NSArray *)values {
    if (values == nil || values.count == 0) {
        return 0;
    }
    int gcd = [[values objectAtIndex:0] intValue];
    int count = (int)values.count;
    for (int i = 1; i < count; ++i) {
        int delay = [[values objectAtIndex:i] intValue];
        if (delay == 0) {
            continue;
        }
        gcd = pairGCD(delay, gcd);
    }
    return gcd;
}

static int pairGCD(int a, int b) {
    if (a < b)
        return pairGCD(b, a);
    while (true) {
        int const r = a % b;
        if (r == 0) {
            return b;
        }
        a = b;
        b = r;
    }
}
@end
