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

@interface ClipperWrapper : NSObject

-(instancetype)init;
-(void)loadInput;
-(void)runClipper;
-(NSArray *)getInputPolygons;
-(NSArray *)getOutputPolygons;
@property (nonatomic, readonly) struct rect cliprect;

@end

#endif /* ClipperWrapper_hpp */
