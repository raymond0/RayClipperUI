//
//  PolygonView.h
//  RayClipperUI
//
//  Created by Ray Hunter on 20/11/2016.
//  Copyright © 2016 Atomic Rabbit Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "geom.h"

#ifdef __cplusplus
extern "C" {
#endif
    
@protocol PolygonViewDelegate
-(void)mouseMovedTo:(NSPoint)position;
@end

@interface PolygonView : NSView

@property (nonatomic, assign) struct rect clipRect;
@property (nonatomic, strong) NSArray *polygons;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, weak) id<PolygonViewDelegate> delegate;
-(void)drawString:(NSString *)str atPosition:(CGPoint)position;

@end
    
#ifdef __cplusplus
}
#endif

