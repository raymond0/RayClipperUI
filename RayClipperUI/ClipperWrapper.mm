//
//  ClipperWrapper.cpp
//  RayClipperUI
//
//  Created by Ray Hunter on 21/11/2016.
//  Copyright © 2016 Atomic Rabbit Ltd. All rights reserved.
//

#include "ClipperWrapper.h"
#include "rayclipper.h"

@implementation ClipperWrapper
{
    rayclipper::Polygon input;
    std::vector<rayclipper::Polygon> output;
    struct rect _cliprect;
    NSInteger nextTest;
}

-(instancetype)init
{
    self = [super init];
    
    return self;
}


-(void)loadInput
{
    NSString *testName = [NSString stringWithFormat:@"test%ld", (long)nextTest];
    nextTest = ( nextTest + 1 ) % 11;
    SEL testSel = NSSelectorFromString(testName);
    [self performSelector:testSel];
}


-(void)runClipper
{
    output = rayclipper::RayClipPolygon(input, _cliprect);
}


-(NSArray *)getInputPolygons
{
    NSMutableArray *polygons = [NSMutableArray array];
    NSArray *polygon = [self getArrayForPolygon:input];
    [polygons addObject:polygon];
    return polygons;
}


-(NSArray *)getOutputPolygons
{
    NSMutableArray *polygons = [NSMutableArray array];
    
    for ( auto outPoly : output )
    {
        NSArray *polygon = [self getArrayForPolygon:outPoly];
        [polygons addObject:polygon];
    }
    
    return polygons;
}


-(NSArray *)getArrayForPolygon:(rayclipper::Polygon)source
{
    NSMutableArray *polygon = [NSMutableArray array];
    
    for ( auto coord : source )
    {
        NSPoint p = NSMakePoint(coord.x, coord.y);
        [polygon addObject:[NSValue valueWithPoint:p]];
    }

    return polygon;
}


template<typename T>
std::vector<T>& operator << (std::vector<T>& v, const T & item)
{
    v.push_back(item);  return v;
}
template<typename T>
std::vector<T>& operator,(std::vector<T>& v, const T & item)
{
    v.push_back(item);  return v;
}


-(void)test0
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << coord{ 20,20 } << coord{ -20,20 } << coord{ -20,40 } << coord{ 20,40 };
    input = p;
}


-(void)test1
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << coord{ 20,80 } << coord{ 20,120 } << coord{ 40,120 } << coord{ 40,80 };
    input = p;
}


-(void)test2
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << coord{ 80,60 } << coord{ 120,60 } << coord{ 120,40 } << coord{ 80,40 };
    input = p;
}


-(void)test3
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << coord{ 60,20 } << coord{ 60,-20 } << coord{ 40,-20 } << coord{ 40,20 };
    input = p;
}

#define c(x...) coord{ x }

-(void)test4
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << c( -40,140 ) << c( 80,140 ) << c( 80,80 ) << c( 60,80 ) << c( 60,120 ) << c( -20,120 ) << c( -20,60 )
    << c( 20,60 ) << c( 20,40 ) << c( -40,40 ) ;
    input = p;
}


-(void)test5
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << c( -20,150 ) << c( 90,150 ) << c( 90,70 ) << c( 70,70 ) << c( 70,120 ) << c( 30,120 ) << c( 30,50 )
    << c( 30,-20 ) << c( -20,-20 );
    input = p;
}


-(void)test6
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << c( -20,120 ) << c( 30,120 ) << c( 30,80 ) << c( 60,80 ) << c( 60,120 ) << c( 120,120 ) << c( 120,60 )
    << c( 50,60 ) << c( -20,60 );
    input = p;
}


-(void)test7
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << c( 40, 120 ) << c( 60,120 ) << c( 60,-20 ) << c( 40,-20 );
    input = p;
}


-(void)test8
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << c( -20, 120 ) << c( 120,120 ) << c( 120,110 ) << c( -20,110 );
    input = p;
}


-(void)test9
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << c( -20, 120 ) << c( 120,120 ) << c( 120,-20 ) << c( -20,-20 );
    input = p;
}


-(void)test10
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << c( -20, 120 ) << c( 120,120 ) << c( 120, -20 ) << c( -20, -20 ) << c( -20, 40 ) << c( -10, 40 ) << c( -10, -10 )
    << c( 110, -10 ) << c( 110, 110 ) << c( -20, 110 );
    input = p;
}

@end
