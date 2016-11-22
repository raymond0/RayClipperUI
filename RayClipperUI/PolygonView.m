//
//  PolygonView.m
//  RayClipperUI
//
//  Created by Ray Hunter on 20/11/2016.
//  Copyright © 2016 Atomic Rabbit Ltd. All rights reserved.
//

#import "PolygonView.h"

@implementation PolygonView


-(void)awakeFromNib
{
    _scale = 0.8;
    struct rect clipRect = { {0, 0}, {100, 100} };
    _clipRect = clipRect;
}


-(void)setPolygons:(NSArray *)polygons
{
    _polygons = polygons;
    [self setNeedsDisplay:YES];
}


-(void)setClipRect:(struct rect)clipRect
{
    _clipRect = clipRect;
    [self setNeedsDisplay:YES];
}


-(void)setScale:(CGFloat)scale
{
    _scale = scale;
    [self setNeedsDisplay:YES];
}


-(void)drawString:(NSString *)str atPosition:(CGPoint)position
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

    NSAttributedString *originStr = [[NSAttributedString alloc] initWithString:str];
    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef) originStr );
    CGContextSetTextPosition(context, position.x, position.y);
    CTLineDraw(line, context);
}


- (void)drawRect:(NSRect)dirtyRect
{
    NSRect nsInsetBounds = self.bounds;
    CGRect insetBounds = NSRectToCGRect(nsInsetBounds);
    insetBounds = CGRectApplyAffineTransform(insetBounds, CGAffineTransformMakeScale(_scale, _scale));

    CGFloat clipWidth = _clipRect.h.x - _clipRect.l.x;
    CGFloat clipHeight = _clipRect.h.y - _clipRect.l.y;

    CGFloat widthRatio =  insetBounds.size.width / clipWidth;
    CGFloat heightRatio = insetBounds.size.height / clipHeight;
    
    CGFloat renderRatio = MIN( widthRatio, heightRatio );
    CGFloat renderWidth = clipWidth * renderRatio;
    CGFloat renderHeight = clipHeight * renderRatio;
    CGPoint center = CGPointMake( self.bounds.size.width / 2.0, self.bounds.size.height / 2.0 );
    CGPoint renderOrigin = CGPointMake( center.x - (renderWidth / 2.0), center.y - ( renderHeight / 2.0) );
    CGRect clipRect = CGRectMake(renderOrigin.x, renderOrigin.y, renderWidth, renderHeight);
    
    [super drawRect:dirtyRect];
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetRGBFillColor(context, 1.0, 0, 0, 0.3);
    CGContextFillRect(context, clipRect);

    NSString *originStr = [NSString stringWithFormat:@"(%d, %d)", _clipRect.l.x, _clipRect.l.y];
    NSString *maxStr = [NSString stringWithFormat:@"(%d, %d)", _clipRect.h.x, _clipRect.h.y];
    [self drawString:originStr atPosition:CGPointMake(clipRect.origin.x, clipRect.origin.y - 10)];
    [self drawString:maxStr atPosition:CGPointMake(clipRect.origin.x + clipRect.size.width,
                                                   clipRect.origin.y + clipRect.size.height + 8)];
    
    for ( NSArray *polygon in _polygons )
    {
        CGMutablePathRef path = CGPathCreateMutable();
        for ( NSInteger i = 0; i < polygon.count; i++ )
        {
            NSValue *value = polygon[i];
            NSPoint point = [value pointValue];
            CGFloat relativeX = ( ( point.x - _clipRect.l.x ) * renderRatio ) + renderOrigin.x;
            CGFloat relativeY = ( ( point.y - _clipRect.l.y ) * renderRatio ) + renderOrigin.y;
            
            if ( i == 0 )
            {
                CGPathMoveToPoint(path, NULL, relativeX, relativeY);
            }
            else
            {
                CGPathAddLineToPoint(path, NULL, relativeX, relativeY);
            }
        }
        
        CGPathCloseSubpath(path);
        CGContextAddPath(context, path);
        CGContextSetRGBFillColor(context, 0.0, 0, 1.0, 0.3);
        CGContextDrawPath(context, kCGPathFillStroke);
        CGPathRelease(path);
    }
}

@end
