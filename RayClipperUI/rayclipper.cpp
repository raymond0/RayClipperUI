//
//  rayclipper.cpp
//  navit
//
//  Created by Ray Hunter on 18/11/2016.
//
//

#include "rayclipper.h"
#include <assert.h>

using namespace std;

namespace rayclipper
{

vector<Polygon> GetAllSubPolygons( const Polygon &inputPolygon, struct rect rect, size_t lastPointOutside )
{
    vector<Polygon> allPolygons;
    bool inside = false;
    shared_ptr<Polygon> currentPolygon;
    
    size_t inputSize = inputPolygon.size();
    
    for ( size_t i = 0; i < inputPolygon.size(); i++ )
    {
        struct coord firstPoint = inputPolygon[(i + lastPointOutside) % inputSize];
        struct coord secondPoint = inputPolygon[(i + 1 + lastPointOutside) % inputSize];

        if ( geom_point_is_inside_rect(secondPoint, &rect ) )
        {
            if ( inside )
            {
                if ( currentPolygon->size() == 0 || !coord_is_equal( currentPolygon->back(), secondPoint ) )
                {
                    currentPolygon->emplace_back(secondPoint);
                }
            }
            else
            {
                currentPolygon = shared_ptr<Polygon>(new Polygon());
                inside = true;
                struct coord intersection = geom_interestion_of_rect(&firstPoint, &secondPoint, &rect);
                
                assert ( intersection.y == rect.l.y || intersection.y == rect.h.y ||
                         intersection.x == rect.l.x || intersection.x == rect.h.x );
                
                if ( currentPolygon->size() == 0 || !coord_is_equal( currentPolygon->back(), intersection ) )
                {
                    currentPolygon->emplace_back(intersection);
                }
                
                if ( currentPolygon->size() == 0 || !coord_is_equal( currentPolygon->back(), secondPoint ) )
                {
                    currentPolygon->emplace_back(secondPoint);
                }
            }
        }
        else
        {
            if ( inside )
            {
                struct coord intersection = geom_interestion_of_rect(&firstPoint, &secondPoint, &rect);
                
                assert ( intersection.y == rect.l.y || intersection.y == rect.h.y ||
                         intersection.x == rect.l.x || intersection.x == rect.h.x );
                
                if ( currentPolygon->size() == 0 || !coord_is_equal( currentPolygon->back(), intersection ) )
                {
                    currentPolygon->emplace_back( intersection );
                }
                
                assert ( currentPolygon->size() >= 3 );
                allPolygons.emplace_back( *currentPolygon );
                
                inside = false;
            }
            else
            {
                //
                // Both outside and currently outside - could be intersection
                //
                struct coord intersections[2];
                int nrIntersections = geom_intersections_of_rect(&firstPoint, &secondPoint, &rect, intersections);
                
                if ( nrIntersections == 2 )
                {
                    currentPolygon = shared_ptr<Polygon>(new Polygon());
                    
                    assert ( intersections[0].y == rect.l.y || intersections[0].y == rect.h.y ||
                             intersections[0].x == rect.l.x || intersections[0].x == rect.h.x );
                    assert ( intersections[1].y == rect.l.y || intersections[1].y == rect.h.y ||
                             intersections[1].x == rect.l.x || intersections[1].x == rect.h.x );
                    
                    assert( ! coord_is_equal(intersections[0], intersections[1]) );
                    
                    double d0 = coord_distance(firstPoint, intersections[0]);
                    double d1 = coord_distance(firstPoint, intersections[1]);
                    
                    if ( d0 <= d1 )
                    {
                        currentPolygon->emplace_back(intersections[0]);
                        currentPolygon->emplace_back(intersections[1]);
                    }
                    else
                    {
                        currentPolygon->emplace_back(intersections[1]);
                        currentPolygon->emplace_back(intersections[0]);
                    }

                    allPolygons.emplace_back( *currentPolygon );
                }
            }
        }
    }
    
    assert( ! inside );
    //assert( allPolygons.size() > 0 );
    
    return allPolygons;
}


typedef enum
{
    EdgeTop = 0,
    EdgeRight = 1,
    EdgeBottom = 2,
    EdgeLeft = 3
} EdgeType;


EdgeType EdgeForCoord( struct coord coord, struct rect rect )
{
    struct coord topLeft = {rect.l.x, rect.h.y};
    struct coord bottomRight = {rect.h.x, rect.l.y};
    
    if ( coord_is_equal(coord, rect.l) )
    {
        return EdgeLeft;
    }
    
    if ( coord_is_equal(coord, topLeft) )
    {
        return EdgeTop;
    }
    
    if ( coord_is_equal(coord, rect.h) )
    {
        return EdgeRight;
    }
    
    if ( coord_is_equal(coord, bottomRight) )
    {
        return EdgeBottom;
    }
    
    if ( coord.y == rect.h.y ) return EdgeTop;
    if ( coord.x == rect.h.x ) return EdgeRight;
    if ( coord.y == rect.l.y ) return EdgeBottom;
    if ( coord.x == rect.l.x ) return EdgeLeft;
    
    assert ( false );
}


int DistanceAlongEdge( EdgeType edge, struct coord from, struct coord to )
{
    switch ( edge )
    {
        case EdgeTop:
            assert( from.y == to.y );
            return to.x - from.x;
        case EdgeRight:
            assert( from.x == to.x );
            return from.y - to.y;
        case EdgeBottom:
            assert( from.y == to.y );
            return from.x - to.x;
        case EdgeLeft:
            assert( from.x == to.x );
            return to.y - from.y;
    }
}


struct coord NextCorner( struct coord coord, struct rect rect )
{
    EdgeType edge = EdgeForCoord( coord, rect );
    
    struct coord topLeft = {rect.l.x, rect.h.y};
    struct coord bottomRight = {rect.h.x, rect.l.y};
    
    switch( edge )
    {
        case EdgeTop:
            return rect.h;
        case EdgeRight:
            return bottomRight;
        case EdgeBottom:
            return rect.l;
        case EdgeLeft:
            return topLeft;
    }
    
    assert(false);
}


int DistanceToNextCorner( struct coord from, struct rect rect, struct coord *nextCorner )
{
    EdgeType fromEdge = EdgeForCoord( from, rect );
    struct coord corner = NextCorner( from, rect );
    
    if ( nextCorner != NULL )
    {
        *nextCorner = corner;
    }
    
    return DistanceAlongEdge( fromEdge, from, corner );
}


int ClockwiseDistance( struct coord from, struct coord to, struct rect rect )
{
    int distance = 0;
    
    EdgeType fromEdge = EdgeForCoord( from, rect );
    EdgeType toEdge = EdgeForCoord( to, rect );
    
    if ( fromEdge == toEdge )
    {
        int d = DistanceAlongEdge( fromEdge, from, to );
        if ( d >= 0 )
        {
            return d;
        }
    }
    
    struct coord currentPosition = from;
    EdgeType currentEdge = fromEdge;
    
    while ( currentEdge != toEdge || distance == 0 )  // Check - 0 check forces us all the way round. Is 0 vaild?
    {
        distance += DistanceToNextCorner( currentPosition, rect, &currentPosition );
        currentEdge = (EdgeType) ((currentEdge + 1) % 4);
    }
    
    assert( currentEdge == toEdge );
    distance += DistanceAlongEdge(currentEdge, currentPosition, to );
    
    return distance;
}


void ClosePolygon( Polygon &polygon, vector<Polygon> &otherPolygons, struct rect rect )
{
    while ( true )
    {
        size_t closestPolygon = -1;
        int closestPolygonDistance = INT_MAX;
        
        for ( size_t i = 0; i < otherPolygons.size(); i++ )
        {
            auto &other = otherPolygons[i];
            
            int d = ClockwiseDistance(polygon.back(), other.front(), rect );
            if ( d < closestPolygonDistance )
            {
                closestPolygonDistance = d;
                closestPolygon = i;
            }
        }
        
        struct coord nextCorner;
        int distanceToNextCorner = DistanceToNextCorner(polygon.back(), rect, &nextCorner);
        int distanceToEndOfCurrent = ClockwiseDistance(polygon.back(), polygon.front(), rect);

        if ( distanceToEndOfCurrent <= distanceToNextCorner && distanceToEndOfCurrent <= closestPolygonDistance )
        {
            //  No corners or other polygons in the way
            return;
        }
        
        if ( closestPolygonDistance <= distanceToNextCorner )
        {
            auto &other = otherPolygons[closestPolygon];
            polygon.insert( polygon.end(), other.begin(), other.end() );
            otherPolygons.erase( otherPolygons.begin() + closestPolygon );
            
            continue;
        }
        
        assert( distanceToNextCorner < distanceToEndOfCurrent && distanceToNextCorner < closestPolygonDistance );
        polygon.emplace_back( nextCorner );
    }
}


vector<Polygon> ClosePolygons( vector<Polygon> &polygons, struct rect rect )
{
    vector<Polygon> closedPolygons;
    
    while ( polygons.size() > 0 )
    {
        auto polygon = polygons.back();
        polygons.pop_back();
        ClosePolygon(polygon, polygons, rect);
        closedPolygons.emplace_back( polygon );
    }
    
    return closedPolygons;
}


vector<Polygon> RayClipPolygon( const Polygon &inputPolygon, struct rect rect )
{
    vector<Polygon> output;

    if ( inputPolygon.size() < 3 )
    {
        return output;
    }
    
    size_t firstPointOutside = -1;
    bool allPointsAbove = true;
    bool allPointsRight = true;
    bool allPointsBelow = true;
    bool allPointsLeft = true;
    
    for ( size_t i = 0; i < inputPolygon.size(); i++ )
    {
        struct coord c = inputPolygon[i];
        if ( ! geom_point_is_inside_rect(c, &rect ) )
        {
            if ( firstPointOutside == -1 )
            {
                firstPointOutside = i;
            }
        }

        if ( c.y < rect.h.y ) { allPointsAbove = false; }
        if ( c.y > rect.l.y ) { allPointsBelow = false; }
        if ( c.x < rect.h.x ) { allPointsRight = false; }
        if ( c.x > rect.l.x ) { allPointsLeft = false; }
    }
    
    //
    //  Simple cases - all inside, or no possible overlap
    //
    if ( firstPointOutside == -1 )
    {
        output.emplace_back(inputPolygon);
        return output;
    }
    
    if ( allPointsAbove || allPointsLeft || allPointsRight || allPointsBelow )
    {
        return output;
    }
    
    //
    //  Search for incident edges
    //
    size_t inputSize = inputPolygon.size();
    size_t firstPointBackInside = -1;
    
    for ( size_t i = 0; i < inputPolygon.size(); i++ )
    {
        size_t outsidePointIndex = (i + firstPointOutside) % inputSize;
        size_t insidePointIndex = (i + firstPointOutside + 1) % inputSize;
        struct coord outsidePoint = inputPolygon[outsidePointIndex];
        struct coord insidePoint = inputPolygon[insidePointIndex];
        
        if ( geom_point_is_inside_rect(insidePoint, &rect )  ||
             geom_line_intersets_rect(&outsidePoint, &insidePoint, &rect) )
        {
            firstPointBackInside = insidePointIndex;
            break;
        }
    }
    
    if ( firstPointBackInside == - 1 )
    {
        //
        //  No intersections or points inside. Either completely surrounded and included, or completely surrounded with no overlap
        //
        struct coord rectCenter = { ( rect.l.x + rect.h.x ) / 2, ( rect.l.y + rect.h.y ) / 2 };
        if ( ! geom_poly_point_inside( &inputPolygon[0], (int) inputPolygon.size(), &rectCenter) )
        {
            //
            // We are not covered
            //
            return output;
        }
        
        //
        // We are covered
        //
        Polygon rectAsPolygon;
        rectAsPolygon.emplace_back(rect.l);
        rectAsPolygon.emplace_back(coord{rect.l.x, rect.h.y});
        rectAsPolygon.emplace_back(rect.h);
        rectAsPolygon.emplace_back(coord{rect.h.x, rect.l.y});
        output.emplace_back( rectAsPolygon );
        return output;
    }
    
    assert ( firstPointBackInside != -1);
    
    size_t lastPointOutside = firstPointBackInside -1;
    if ( lastPointOutside == -1 )
    {
        lastPointOutside = inputSize - 1;
    }
    
    vector<Polygon> allPolygons = GetAllSubPolygons(inputPolygon, rect, lastPointOutside );
    vector<Polygon> closedPolygons = ClosePolygons(allPolygons, rect);
    assert ( closedPolygons.size() > 0 );
    return closedPolygons;
}

}
