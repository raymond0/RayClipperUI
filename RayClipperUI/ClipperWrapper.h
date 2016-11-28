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
#import "geom.h"

@interface ClipperWrapper : NSObject

-(instancetype)init;
-(instancetype)initWithPath:(NSString *)path;
-(BOOL)loadInput;
-(void)runClipper;
-(NSArray *)getInputPolygons;
-(NSArray *)getOutputPolygons;
@property (nonatomic, readonly) struct rect cliprect;
-(struct coord *)rawInputCoords;
-(bool)inputSelfIntersects;
-(bool)outputSelfIntersects;
-(BOOL)outputWasLarge;

@end

#endif /* ClipperWrapper_hpp */
