//
//  rayclipper.hpp
//  navit
//
//  Created by Ray Hunter on 18/11/2016.
//
//

#ifndef rayclipper_hpp
#define rayclipper_hpp

#define ENABLE_SELF_INTERSECTION_FUNCTION

#include <stdio.h>
#include "geom.h"
#include <vector>
    
namespace rayclipper {

typedef std::vector<struct coord> Polygon;
std::vector<Polygon> RayClipPolygon( const Polygon &inputPolygon, struct rect rect );

#ifdef ENABLE_SELF_INTERSECTION_FUNCTION
bool PolygonSelfIntersects(const rayclipper::Polygon &polygon);
#endif

}


#endif /* rayclipper_hpp */
