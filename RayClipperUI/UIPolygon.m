//
//  UIPolygon.m
//  RayClipperUI
//
//  Created by Ray Hunter on 14/04/2017.
//  Copyright © 2017 Atomic Rabbit Ltd. All rights reserved.
//

#import "UIPolygon.h"

@implementation UIPolygon

-(instancetype)init
{
    self = [super init];
    
    if ( self != nil )
    {
        _contour = [NSMutableArray array];
        _holes = [NSMutableArray array];
    }
    
    return self;
}

@end
