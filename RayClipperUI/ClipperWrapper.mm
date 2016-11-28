//
//  ClipperWrapper.cpp
//  RayClipperUI
//
//  Created by Ray Hunter on 21/11/2016.
//  Copyright © 2016 Atomic Rabbit Ltd. All rights reserved.
//

#include "ClipperWrapper.h"
#include "rayclipper.h"
#include "PolygonChecking.h"

@implementation ClipperWrapper
{
    rayclipper::Polygon input;
    std::vector<rayclipper::Polygon> output;
    struct rect _cliprect;
    NSInteger nextTest;
    FILE *polyFile;
}

-(instancetype)init
{
    self = [super init];
    
    return self;
}


-(instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    
    if ( self != nil )
    {
        polyFile = fopen(path.UTF8String, "rb");
    }
    
    return self;
}


-(struct coord *)rawInputCoords
{
    return &input[0];
}


-(BOOL)outputWasLarge
{
    long long rectArea = ( (long long) _cliprect.h.x - _cliprect.l.x ) *  ( (long long) _cliprect.h.y - _cliprect.l.y );
    rectArea = (rectArea * 3 )/4;
    
    for ( auto polygon : output )
    {
        if ( geom_poly_area( &polygon[0], polygon.size() ) >= rectArea )
        {
            return YES;
        }
    }
    
    return NO;
}


-(BOOL)loadInput
{
    if ( polyFile != NULL )
    {
        if ( fread(&_cliprect, sizeof( struct rect ), 1, polyFile) != 1 ) return NO;
        int nrCoords = 0;
        if ( fread(&nrCoords, sizeof( int ), 1, polyFile ) != 1 ) return NO;
        input.resize(nrCoords);
        if ( fread(&input[0], sizeof(struct coord), nrCoords, polyFile ) != nrCoords ) return NO;
        return YES;
    }
    
    [self test14];
    /*NSString *testName = [NSString stringWithFormat:@"test%ld", (long)nextTest];
    nextTest = ( nextTest + 1 ) % 12;
    SEL testSel = NSSelectorFromString(testName);
    [self performSelector:testSel];*/
    return YES;
}


-(bool)inputSelfIntersects
{
    return PolygonSelfIntersects( input );
}

-(bool)outputSelfIntersects
{
    for ( auto &outp : output )
    {
        if ( PolygonSelfIntersects( outp ) )
        {
            return YES;
        }
    }
    
    return NO;
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
    
    
-(void)test11
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << c( 0, -20 ) << c( 0, 100 ) << c( 120, 100 ) << c( 120, -20 );
    input = p;
}

    
-(void)test12
{
    _cliprect = { {542400, 6875298}, {547287, 6880185}};
    
    rayclipper::Polygon p;
    p << c( 542387, 6876708 ) << c( 542403, 6876703 ) << c( 542394, 6876715 ) << c( 542318, 6876756 )
      << c( 542249, 6876806 ) << c( 542324, 6876749 );
    input = p;
}
    
    
-(void)test13
{
    _cliprect = { {547287, 6845979}, {548508, 6847200}};
    
    rayclipper::Polygon p;
    p << c( 548613, 6846579 ) << c( 548624, 6846560 ) << c( 548618, 6846556 ) << c( 548609, 6846570 ) << c( 548610, 6846574 )
      << c( 548603, 6846583 ) << c( 548773, 6846685 ) << c( 548839, 6846727 ) << c( 548712, 6846992 ) << c( 548606, 6847183 )
      << c( 548530, 6847307 ) << c( 548478, 6847278 ) << c( 548462, 6847272 ) << c( 548434, 6847266 ) << c( 548438, 6847276 )
      << c( 548463, 6847282 ) << c( 548532, 6847317 ) << c( 548565, 6847269 ) << c( 548614, 6847186 ) << c( 548736, 6846965 )
      << c( 548866, 6846689 ) << c( 548815, 6846599 ) << c( 548805, 6846603 ) << c( 548854, 6846690 ) << c( 548854, 6846697 )
      << c( 548843, 6846719 );
    input = p;
}
    
    
-(void)test14
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << c( 50, -20 ) << c( 50, 50 ) << c( 50, 50 ) << c( 48, -20 );
    input = p;
}


@end
