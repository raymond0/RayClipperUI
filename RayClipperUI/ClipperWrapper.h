//
//  ClipperWrapper.hpp
//  RayClipperUI
//
//  Created by Ray Hunter on 21/11/2016.
//  Copyright © 2016 Atomic Rabbit Ltd. All rights reserved.
//

#ifndef ClipperWrapper_hpp
#define ClipperWrapper_hpp

#import <Cocoa/Cocoa.h>
#import "UIPolygon.h"

@interface ClipperWrapper : NSObject

-(instancetype)init;
-(instancetype)initWithPath:(NSString *)path;
-(BOOL)loadInput;
-(void)runClipper;
-(NSArray<UIPolygon *> *)getInputPolygons;
-(NSArray<UIPolygon *> *)getOutputPolygons;
//-(NSArray *)rawInputCoords;
//-(bool)inputSelfIntersects;
//-(bool)outputSelfIntersects;
-(BOOL)outputWasLarge;
-(CGRect)clipRectAsCGRect;
-(NSData *)binaryData;

@end

#endif /* ClipperWrapper_hpp */
