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

using namespace rayclipper;

@implementation ClipperWrapper
{
    rayclipper::Polygon input;
    std::vector<rayclipper::Polygon> output;
    rayclipper::rect _cliprect;
    NSInteger nextTest;
    FILE *polyFile;
}

-(instancetype)init
{
    self = [super init];
    
    nextTest = 100;
    
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


-(NSData *)binaryData
{
    printf("Failed rectangle: (%d, %d) -> (%d, %d)\n", _cliprect.l.x, _cliprect.l.y,
           _cliprect.h.x, _cliprect.h.y);
    
    NSArray *inputAll = [self getInputPolygons];
    NSAssert (inputAll.count == 1, @"1 at a time please");
    
    NSArray *inputOnly = inputAll[0];
    for ( NSValue *v in inputOnly )
    {
        NSPoint point = [v pointValue];
        printf("%d, %d\n", (int) point.x, (int) point.y);
    }

    NSMutableData *data = [NSMutableData data];
    [data appendBytes:&_cliprect length:sizeof(struct rect)];
    int nrCoords = (int) input.size();
    [data appendBytes:&nrCoords length:sizeof(int)];
    struct coord *rawCoordPtr = &input[0];
    [data appendBytes:rawCoordPtr length:sizeof(struct coord) * nrCoords];
    
    return data;
}


long long
geom_poly_area(const struct coord *c, size_t count)
{
    long long area=0;
    int i,j=0;
    for (i=0; i<count; i++) {
        if (++j == count)
            j=0;
        area+=(long long)(c[i].x+c[j].x)*(c[i].y-c[j].y);
    }
    return area/2;
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



-(CGRect)clipRectAsCGRect
{
    CGRect rect = CGRectMake((double)_cliprect.l.x, _cliprect.l.y, _cliprect.h.x - _cliprect.l.x, _cliprect.h.y - _cliprect.l.y);
    return rect;
}


-(BOOL)loadInput
{
    if ( polyFile != NULL )
    {
        if ( fread(&_cliprect, sizeof( struct rect ), 1, polyFile) != 1 ) return NO;
        int nrCoords = 0;
        if ( fread(&nrCoords, sizeof( int ), 1, polyFile ) != 1 ) return NO;
        int nrHoles = 0;
        if ( fread(&nrHoles, sizeof( int ), 1, polyFile ) != 1 ) return NO;
        input.resize(nrCoords);
        if ( fread(&input[0], sizeof(struct coord), nrCoords, polyFile ) != nrCoords ) return NO;
        input.holes.resize(nrHoles);
        
        for ( int i = 0; i < nrHoles; i++ )
        {
            int nrHoleCoords = 0;
            if ( fread(&nrHoleCoords, sizeof( int ), 1, polyFile ) != 1 ) return NO;
            input.holes[i].resize(nrHoleCoords);
            if ( fread(&input.holes[i][0], sizeof(struct coord), nrHoleCoords, polyFile ) != nrHoleCoords ) return NO;
            reverse(input.holes[i].begin(), input.holes[i].end());
        }
        
        return YES;
    }
    
    //[self test15];
    NSString *testName = [NSString stringWithFormat:@"test%ld", (long)nextTest];
    nextTest++; // = ( nextTest + 1 ) % 12;
    SEL testSel = NSSelectorFromString(testName);
    
    if ( ![self respondsToSelector:testSel] )
    {
        nextTest = 101;
        [self test100];
        return YES;
    }
    
    [self performSelector:testSel];
    return YES;
}


/*-(bool)inputSelfIntersects
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
}*/


-(void)runClipper
{
    if ( rayclipper::PolygonArea( input ) < 0 )
    {
        std::reverse( input.begin(), input.end() );
    }
    
    //rayclipper::Polygon cleaned;
    //rayclipper::CleanPolygon( input, cleaned );
    output.clear();
    rayclipper::RayClipPolygon(input, _cliprect, output);
}


-(NSArray<UIPolygon *> *)getInputPolygons
{
    NSMutableArray *polygons = [NSMutableArray array];
    UIPolygon *polygon = [self getUIPolygonForPolygon:input];
    
    for ( UIPolygon *hole in polygon.holes )
    {
        hole.contour = [NSMutableArray arrayWithArray:[[hole.contour reverseObjectEnumerator] allObjects]];
    }
    
    [polygons addObject:polygon];
    return polygons;
}


-(NSArray<UIPolygon *> *)getOutputPolygons
{
    NSMutableArray<UIPolygon *> *polygons = [NSMutableArray array];
    
    for ( auto outPoly : output )
    {
        UIPolygon *polygon = [self getUIPolygonForPolygon:outPoly];
        [polygons addObject:polygon];
    }
    
    return polygons;
}


-(UIPolygon *)getUIPolygonForPolygon:(rayclipper::Polygon)source
{
    UIPolygon *polygon = [[UIPolygon alloc] init];
    
    for ( auto coord : source )
    {
        NSPoint p = NSMakePoint(coord.x, coord.y);
        [polygon.contour addObject:[NSValue valueWithPoint:p]];
    }
    
    for ( auto &hole : source.holes )
    {
        [polygon.holes addObject:[self getUIPolygonForPolygon:hole]];
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

#define c(x...) coord{ x }

-(void)test100
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << coord{ 20,20 } << coord{ 20,80 } << coord{ 80,80 } << coord{ 80,20 };
    
    rayclipper::Polygon hole;
    hole << coord{ 40,40 } << coord{ 40,60 } << coord{ 60,60 } << coord{ 60,40 };
    reverse( hole.begin(), hole.end() );
    p.holes << hole;
    
    input = p;
}


-(void)test101
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << c( -20,150 ) << c( 90,150 ) << c( 90,70 ) << c( 70,70 ) << c( 70,120 ) << c( 30,120 ) << c( 30,50 )
    << c( 30,-20 ) << c( -20,-20 );
    
    rayclipper::Polygon hole;
    hole << coord{ -10,40 } << coord{ -10,60 } << coord{ 10,60 } << coord{ 10,40 };
    reverse( hole.begin(), hole.end() );
    p.holes << hole;

    input = p;
}

-(void)test102
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << c( -20,150 ) << c( 90,150 ) << c( 90,70 ) << c( 70,70 ) << c( 70,120 ) << c( 30,120 ) << c( 30,50 )
    << c( 30,-20 ) << c( -20,-20 );
    
    rayclipper::Polygon hole;
    hole << c( -5,-5 ) << c(-5,40 ) << c( 10,40 ) << c( 10,60 ) << c (-5,60) << c (-5,105) << c (20,100) << c(20,-5);
    reverse( hole.begin(), hole.end() );
    p.holes << hole;
    
    input = p;
}


-(void)test103
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << c( -20,-20 ) << c( -20,120 ) << c( 120,120 ) << c( 120,-20 );
    
    rayclipper::Polygon hole;
    hole << coord{ -10,40 } << coord{ -10,60 } << coord{ 110,60 } << coord{ 110,40 };
    reverse( hole.begin(), hole.end() );
    p.holes << hole;
    
    input = p;
}



-(void)test104
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << c( -20,-20 ) << c( -20,120 ) << c( 120,120 ) << c( 120,-20 );
    
    rayclipper::Polygon hole;
    hole << coord{ -10,-10 } << coord{ -10,110 } << coord{ 110,110 } << coord{ 110,-10 };
    reverse( hole.begin(), hole.end() );
    p.holes << hole;
    
    input = p;
}


-(void)test105
{
    // -9714353, 5641458 -> -9713131, 5642679
    _cliprect = { {-9714353, 5641458}, {-9713131, 5642679}};
    
    rayclipper::Polygon p;
    p << c(-9704580, 5639015)
    << c(-9714353, 5639015)
    << c(-9714353, 5648788)
    << c(-9704580, 5648788);
    
    rayclipper::Polygon hole;
    hole << c(-9710384, 5639985)
    << c(-9711540, 5640775)
    << c(-9712965, 5641663)
    << c(-9714346, 5642449)
    << c(-9714353, 5642453)
    << c(-9714353, 5647149)
    << c(-9714139, 5646734)
    << c(-9714127, 5646553)
    << c(-9713966, 5646375)
    << c(-9713363, 5646372)
    << c(-9713214, 5646419)
    << c(-9712935, 5646622)
    << c(-9712350, 5647172)
    << c(-9712248, 5647465)
    << c(-9712220, 5647920)
    << c(-9711984, 5648177)
    << c(-9711601, 5648465)
    << c(-9711508, 5648581)
    << c(-9711305, 5648570)
    << c(-9711201, 5648498)
    << c(-9711154, 5648243)
    << c(-9710906, 5647727)
    << c(-9710934, 5647624)
    << c(-9711215, 5647283)
    << c(-9711242, 5647234)
    << c(-9711202, 5647200)
    << c(-9711224, 5647159)
    << c(-9711228, 5647196)
    << c(-9711291, 5647223)
    << c(-9711349, 5647195)
    << c(-9711445, 5647125)
    << c(-9711472, 5647024)
    << c(-9711436, 5646800)
    << c(-9711254, 5646283)
    << c(-9711147, 5645736)
    << c(-9711279, 5644365)
    << c(-9711292, 5643709)
    << c(-9711404, 5643248)
    << c(-9711546, 5642897)
    << c(-9711562, 5642211)
    << c(-9711487, 5641883)
    << c(-9711330, 5641510)
    << c(-9711097, 5641156)
    << c(-9710767, 5640510);

    reverse( hole.begin(), hole.end() );

    p.holes << hole;
    
    input = p;
}


-(void)test106
{
    _cliprect = { {-9715574, 5642679}, {-9714353, 5643901}};
    
    rayclipper::Polygon p;
    p << c(-9714353, 5629242)
    << c(-9733899, 5629242)
    << c(-9733899, 5645985)
    << c(-9733534, 5646872)
    << c(-9733473, 5647177)
    << c(-9733526, 5647214)
    << c(-9733460, 5647214)
    << c(-9733322, 5647583)
    << c(-9732281, 5648646)
    << c(-9732067, 5648788)
    << c(-9714353, 5648788);
    
    rayclipper::Polygon hole;
    hole << c(-9714353, 5642419)
    << c(-9715851, 5643235)
    << c(-9715924, 5643482)
    << c(-9715937, 5644250)
    << c(-9715674, 5644720)
    << c(-9715596, 5645100)
    << c(-9715638, 5646050)
    << c(-9715761, 5646459)
    << c(-9714910, 5646566)
    << c(-9714684, 5646783)
    << c(-9714619, 5647187)
    << c(-9714506, 5647246)
    << c(-9714378, 5647198)
    << c(-9714353, 5647149);
    reverse( hole.begin(), hole.end() );

    p.holes << hole;
    
    input = p;
}


-(void)test107
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << c( 10,10 ) << c( 20,110 ) << c( 110,110 ) << c( 90,90 ) << c( 90,15 );
    
    rayclipper::Polygon hole;
    hole << coord{ 40,40 } << coord{ 60,40 } << coord{ 60,60 } << coord{ 40,60 };
    p.holes << hole;
    
    input = p;
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


-(void)test15
{
    _cliprect = { {527741,6860639}, {547287,6880185}};
    
    rayclipper::Polygon p;
    p << c( 527960, 6878433);
    p << c( 528168, 6878199);
    p << c( 528158, 6878191);
    p << c( 527952, 6878428);
    p << c( 527944, 6878430);
    p << c( 527929, 6878418);
    p << c( 527914, 6878420);
    p << c( 527846, 6878497);
    p << c( 527838, 6878503);
    p << c( 527828, 6878503);
    p << c( 527745, 6878425);
    p << c( 527737, 6878425);
    p << c( 527740, 6878433);
    p << c( 527790, 6878481);
    p << c( 527738, 6878548);
    p << c( 527793, 6878487);
    p << c( 527810, 6878495);
    p << c( 527836, 6878525);
    p << c( 527846, 6878524);
    p << c( 527852, 6878531);
    p << c( 527851, 6878508);
    p << c( 527922, 6878427);
    p << c( 527930, 6878426);
    p << c( 527938, 6878435);
    p << c( 527954, 6878436);
    
    input = p;
}


-(void)test16
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << c( -20, 50 ) << c( 30, 60 ) << c( 50, 30 ) << c( 50, 60 ) << c( 30, 30 );
    input = p;
}


-(void)test17
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << c( -20, 50 ) << c( 50, 80 ) << c( 50, 20 ) << c( 25, 90 );
    input = p;
}


-(void)test18
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << c( -20, 60 ) << c( 60, 60 ) << c( 60, 40 ) << c( 40, 40 ) << c( 40, 80 ) << c( 80, 80 ) << c( 80, 20 ) << c( -20, 20 );
    input = p;
}


-(void)test19
{
    _cliprect = { {0,0}, {100,100}};
    
    rayclipper::Polygon p;
    p << c( -20, 60 ) << c( 60, 60 ) << c( 60, 40 ) << c( 40, 40 ) << c( 40, 120 ) << c( 80, 120 ) << c( 80, 20 ) << c( -20, 20 );
    input = p;
}



@end
