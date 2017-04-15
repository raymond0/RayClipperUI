//
//  UIPolygon.h
//  RayClipperUI
//
//  Created by Ray Hunter on 14/04/2017.
//  Copyright © 2017 Atomic Rabbit Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIPolygon : NSObject

@property (nonatomic, strong) NSMutableArray *contour;
@property (nonatomic, strong) NSMutableArray<UIPolygon *> *holes;

@end
