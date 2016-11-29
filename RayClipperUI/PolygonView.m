//
//  PolygonView.m
//  RayClipperUI
//
//  Created by Ray Hunter on 20/11/2016.
//  Copyright © 2016 Atomic Rabbit Ltd. All rights reserved.
//

#import "PolygonView.h"

@implementation PolygonView
{
    NSTrackingArea *_trackingArea;
    CGPoint _renderOrigin;
    CGFloat _renderRatio;
    CGRect _clipDrawingRect;
}

-(void)awakeFromNib
{
    _scale = 0.8;
    CGRect clipRect = { {0, 0}, {100, 100} };
    _clipRect = clipRect;
    
    NSTrackingAreaOptions options = (NSTrackingActiveAlways | NSTrackingInVisibleRect |
                                     NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved);
    
    _trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                 options:options
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
}


-(void)setPolygons:(NSArray *)polygons
{
    _polygons = polygons;
    [self setNeedsDisplay:YES];
}


-(void)setClipRect:(CGRect)clipRect
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

    CGFloat widthRatio =  insetBounds.size.width / _clipRect.size.width;
    CGFloat heightRatio = insetBounds.size.height / _clipRect.size.height;
    
    _renderRatio = MIN( widthRatio, heightRatio );
    CGFloat renderWidth = _clipRect.size.width * _renderRatio;
    CGFloat renderHeight = _clipRect.size.height * _renderRatio;
    CGPoint center = CGPointMake( self.bounds.size.width / 2.0, self.bounds.size.height / 2.0 );
    _renderOrigin = CGPointMake( center.x - (renderWidth / 2.0), center.y - ( renderHeight / 2.0) );
    _clipDrawingRect = CGRectMake(_renderOrigin.x, _renderOrigin.y, renderWidth, renderHeight);
    
    [super drawRect:dirtyRect];
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetRGBFillColor(context, 1.0, 0, 0, 0.3);
    CGContextFillRect(context, _clipDrawingRect);

    NSString *originStr = [NSString stringWithFormat:@"(%d, %d)", (int) _clipRect.origin.x, (int) _clipRect.origin.y];
    NSString *maxStr = [NSString stringWithFormat:@"(%d, %d)", (int) (_clipRect.origin.x + _clipRect.size.width),
                                                               (int) (_clipRect.origin.y + _clipRect.size.height)];
    [self drawString:originStr atPosition:CGPointMake(_clipDrawingRect.origin.x, _clipDrawingRect.origin.y - 10)];
    [self drawString:maxStr atPosition:CGPointMake(_clipDrawingRect.origin.x + _clipDrawingRect.size.width,
                                                   _clipDrawingRect.origin.y + _clipDrawingRect.size.height + 8)];
    
    for ( NSArray *polygon in _polygons )
    {
        CGMutablePathRef path = CGPathCreateMutable();
        for ( NSInteger i = 0; i < polygon.count; i++ )
        {
            NSValue *value = polygon[i];
            NSPoint point = [value pointValue];
            CGFloat relativeX = ( ( point.x - _clipRect.origin.x ) * _renderRatio ) + _renderOrigin.x;
            CGFloat relativeY = ( ( point.y - _clipRect.origin.y ) * _renderRatio ) + _renderOrigin.y;
            
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


-(void)mouseMoved:(NSEvent *)event
{
    NSPoint eventLocation = [event locationInWindow];
    NSPoint localPoint = [self convertPoint:eventLocation fromView:nil];
    localPoint.x = ((localPoint.x - _clipDrawingRect.origin.x) / _renderRatio) + _clipRect.origin.x;
    localPoint.y = ((localPoint.y - _clipDrawingRect.origin.y) / _renderRatio) + _clipRect.origin.y;
    [_delegate mouseMovedTo:localPoint];
}

@end
