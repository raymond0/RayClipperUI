/**
 * Navit, a modular navigation system.
 * Copyright (C) 2005-2011 Navit Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA  02110-1301, USA.
 */
#include <string.h>
#include <math.h>
#include "geom.h"
#include <assert.h>


double coord_distance(struct coord from, struct coord to)
{
    double dx = to.x - from.x;
    double dy = to.y - from.y;
    
    return sqrt( ( dx * dx ) + ( dy * dy ) );
}

void
geom_coord_copy(struct coord *from, struct coord *to, int count, int reverse)
{
	int i;
	if (!reverse) {
		memcpy(to, from, count*sizeof(struct coord));
		return;
	}
	from+=count;
	for (i = 0 ; i < count ; i++) 
		*to++=*--from;	
}


int
geom_line_middle(struct coord *p, int count, struct coord *c)
{
	double length=0,half=0,len=0;
	int i;

	if(count==1) {
		*c=*p;
		return 0;
	}
	
	for (i=0; i<count-1; i++) {
		length+=sqrt(sq(p[i].x-p[i+1].x)+sq(p[i].y-p[i+1].y));
	}

	length/=2;
	for (i=0; (i<count-1) && (half<length); i++) {
		len=sqrt(sq(p[i].x-p[i+1].x)+sq(p[i].y-p[i+1].y));
		half+=len;
	}
	if (i > 0) {
		i--;
		half-=length;
		if (len) {
			c->x=(p[i].x*half+p[i+1].x*(len-half))/len;
			c->y=(p[i].y*half+p[i+1].y*(len-half))/len;
		} else
			*c=p[i];
	} else
		*c=p[0];
	return i;
}


void
geom_coord_revert(struct coord *c, int count)
{
	struct coord tmp;
	int i;

	for (i = 0 ; i < count/2 ; i++) {
		tmp=c[i];
		c[i]=c[count-1-i];
		c[count-1-i]=tmp;
	}
}


long long
geom_poly_area(struct coord *c, int count)
{
	long long area=0;
	int i,j=0;
#if 0
	fprintf(stderr,"count=%d\n",count);
#endif
	for (i=0; i<count; i++) {
		if (++j == count)
			j=0;
#if 0
		fprintf(stderr,"(%d+%d)*(%d-%d)=%d*%d="LONGLONG_FMT"\n",c[i].x,c[j].x,c[i].y,c[j].y,c[i].x+c[j].x,c[i].y-c[j].y,(long long)(c[i].x+c[j].x)*(c[i].y-c[j].y));
#endif
		area+=(long long)(c[i].x+c[j].x)*(c[i].y-c[j].y);
#if 0
		fprintf(stderr,"area="LONGLONG_FMT"\n",area);
#endif
	}
  	return area/2;
}

int
geom_poly_centroid(struct coord *p, int count, struct coord *c)
{
	long long area=0;
	long long sx=0,sy=0,tmp;
	int i,j;
	long long x0=p[0].x, y0=p[0].y, xi, yi, xj, yj;
	
	/*fprintf(stderr,"area="LONGLONG_FMT"\n", area );*/
	for (i=0,j=0; i<count; i++) {
		if (++j == count)
			j=0;
		xi=p[i].x-x0;
		yi=p[i].y-y0;
		xj=p[j].x-x0;
		yj=p[j].y-y0;
		tmp=(xi*yj-xj*yi);
		sx+=(xi+xj)*tmp;
		sy+=(yi+yj)*tmp;
		area+=xi*yj-xj*yi;
	}
	if(area!=0) {
		c->x=(int)(x0+sx/3/area);
		c->y=(int)(y0+sy/3/area);
		return 1;
	}
	return 0;
}


int
geom_poly_closest_point(struct coord *pl, int count, struct coord *p, struct coord *c)
{
	int i,vertex=0;
	long long x, y, xi, xj, yi, yj, u, d, dmin=0;
	if(count<2) {
		c->x=pl->x;
		c->y=pl->y;
		return 0;
	}
	for(i=0;i<count-1;i++) {
		xi=pl[i].x;
		yi=pl[i].y;
		xj=pl[i+1].x;
		yj=pl[i+1].y;
		u=(xj-xi)*(xj-xi)+(yj-yi)*(yj-yi);
		if(u!=0) {
			u=((p->x-xi)*(xj-xi)+(p->y-yi)*(yj-yi))*1000/u;
		}
		if(u<0) 
			u=0;
		else if (u>1000) 
			u=1000;
		x=xi+u*(xj-xi)/1000;
		y=yi+u*(yj-yi)/1000;
		d=(p->x-x)*(p->x-x)+(p->y-y)*(p->y-y);
		if(i==0 || d<dmin) {
			dmin=d;
			c->x=(int)x;
			c->y=(int)y;
			vertex=i;
		}
	}
	return vertex;
}


int
geom_poly_point_inside(const struct coord *cp, int count, const struct coord *c)
{
	int ret=0;
	const struct coord *last=cp+count-1;
	while (cp < last)
    {
		if ((cp[0].y > c->y) != (cp[1].y > c->y) &&
			c->x < ( (long long) cp[1].x - cp[0].x ) * ( c->y -cp[0].y ) / ( cp[1].y - cp[0].y ) + cp[0].x )
        {
#if 0
			fprintf(stderr," cross 0x%x,0x%x-0x%x,0x%x %dx%d",cp,cp[0].x,cp[0].y,cp[1].x,cp[1].y,cp[1].x-cp[0].x,c->y-cp[0].y);
			printf("type=selected_line\n");
			coord_print(projection_mg, &cp[0], stdout);
			coord_print(projection_mg, &cp[1], stdout);
#endif
			ret=!ret;
		}
		cp++;
	}
	return ret;
}


static int
clipcode(struct coord *p, struct rect *r)
{
	int code=0;
	if (p->x < r->l.x)
		code=1;
	if (p->x > r->h.x)
		code=2;
	if (p->y < r->l.y)
		code |=4;
	if (p->y > r->h.y)
		code |=8;
	return code;
}


int
geom_clip_line_code(struct coord *p1, struct coord *p2, struct rect *r)
{
	int code1,code2,ret=1;
	long long dx,dy;
	code1=clipcode(p1, r);
	if (code1)
		ret |= 2;
	code2=clipcode(p2, r);
	if (code2)
		ret |= 4;
	dx=p2->x-p1->x;
	dy=p2->y-p1->y;
	while (code1 || code2) {
		if (code1 & code2)
			return 0;
		if (code1 & 1) {
			p1->y+=(r->l.x-p1->x)*dy/dx;
			p1->x=r->l.x;
		} else if (code1 & 2) {
			p1->y+=(r->h.x-p1->x)*dy/dx;
			p1->x=r->h.x;
		} else if (code1 & 4) {
			p1->x+=(r->l.y-p1->y)*dx/dy;
			p1->y=r->l.y;
		} else if (code1 & 8) {
			p1->x+=(r->h.y-p1->y)*dx/dy;
			p1->y=r->h.y;
		}
		code1=clipcode(p1, r);
		if (code1 & code2)
			return 0;
		if (code2 & 1) {
			p2->y+=(r->l.x-p2->x)*dy/dx;
			p2->x=r->l.x;
		} else if (code2 & 2) {
			p2->y+=(r->h.x-p2->x)*dy/dx;
			p2->x=r->h.x;
		} else if (code2 & 4) {
			p2->x+=(r->l.y-p2->y)*dx/dy;
			p2->y=r->l.y;
		} else if (code2 & 8) {
			p2->x+=(r->h.y-p2->y)*dx/dy;
			p2->y=r->h.y;
		}
		code2=clipcode(p2, r);
	}
	if (p1->x == p2->x && p1->y == p2->y)
		ret=0;
	return ret;
}

int
geom_is_inside(struct coord *p, struct rect *r, int edge)
{
	switch(edge) {
	case 0:
		return p->x >= r->l.x;
	case 1:
		return p->x <= r->h.x;
	case 2:
		return p->y >= r->l.y;
	case 3:
		return p->y <= r->h.y;
	default:
		return 0;
	}
}

void
geom_poly_intersection(struct coord *p1, struct coord *p2, const struct rect *r, int edge, struct coord *ret)
{
	float dx=p2->x-p1->x;
	float dy=p2->y-p1->y;
	switch(edge) {
	case 0:
		ret->y=p1->y + ((float)(r->l.x-p1->x)) * dy/dx;
		ret->x=r->l.x;
		break;
	case 1:
		ret->y=p1->y + ((float)(r->h.x-p1->x)) * dy/dx;
		ret->x=r->h.x;
		break;
	case 2:
        ret->x=p1->x + ((float)(r->h.y-p1->y)) * dx/dy;
		ret->y=r->h.y;
		break;
	case 3:
        ret->x=p1->x + ((float)(r->l.y-p1->y)) * dx/dy;
		ret->y=r->l.y;
		break;
	}
}


int
geom_point_is_inside_rect(struct coord coord, const struct rect *r)
{
    if ( coord.x < r->l.x ) return 0;
    if ( coord.x > r->h.x ) return 0;
    if ( coord.y < r->l.y ) return 0;
    if ( coord.y > r->h.y ) return 0;
    
    return 1;
}


// +-2-+
// |   |
// 0   1
// |   |
// +-3-+

int
geom_line_intersets_rect(struct coord *p1, struct coord *p2, const struct rect *r)
{
    if ( p1->x < r->l.x && p2->x < r->l.x ) return 0;
    if ( p1->x > r->h.x && p2->x > r->h.x ) return 0;
    if ( p1->y < r->l.y && p2->y < r->l.y ) return 0;
    if ( p1->y > r->h.y && p2->y > r->h.y ) return 0;
    
    struct coord ret;
    
    // Left + right
    if ( p1->x != p2->x )
    {
        geom_poly_intersection(p1, p2, r, 0, &ret);
        if ( r->l.y <= ret.y && ret.y <= r->h.y ) return 1;
        geom_poly_intersection(p1, p2, r, 1, &ret);
        if ( r->l.y <= ret.y && ret.y <= r->h.y ) return 1;
    }
    
    // Top + bottom
    if ( p1->y != p2->y )
    {
        geom_poly_intersection(p1, p2, r, 2, &ret);
        if ( r->l.x <= ret.x && ret.x <= r->h.x ) return 1;
        geom_poly_intersection(p1, p2, r, 3, &ret);
        if ( r->l.x <= ret.x && ret.x <= r->h.x ) return 1;
    }
    
    return 0;
}


struct coord geom_interestion_of_rect( struct coord *p1, struct coord *p2, const struct rect *r )
{
    assert( geom_point_is_inside_rect(*p1, r) != geom_point_is_inside_rect(*p2, r) );
    
    struct coord ret;
    
    bool leftPossible =   ( p1->x < r->l.x && p2->x >= r->l.x ) || ( p2->x < r->l.x && p1->x >= r->l.x );
    bool rightPossible =  ( p1->x <= r->h.x && p2->x > r->h.x ) || ( p2->x <= r->h.x && p1->x > r->h.x );
    bool bottomPossible = ( p1->y < r->l.y && p2->y >= r->l.y ) || ( p2->y < r->l.y && p1->y >= r->l.y );
    bool topPossible =    ( p1->y <= r->h.y && p2->y > r->h.y ) || ( p2->y <= r->h.y && p1->y > r->h.y );


    // Left + Right
    if ( p1->x != p2->x )
    {
        if ( leftPossible )
        {
            geom_poly_intersection(p1, p2, r, 0, &ret);
            if ( r->l.y <= ret.y && ret.y <= r->h.y ) return ret;
        }
        
        if ( rightPossible )
        {
            geom_poly_intersection(p1, p2, r, 1, &ret);
            if ( r->l.y <= ret.y && ret.y <= r->h.y ) return ret;
        }
    }
    
    // Top + bottom
    if ( p1->y != p2->y )
    {
        if ( topPossible )
        {
            geom_poly_intersection(p1, p2, r, 2, &ret);
            if ( r->l.x <= ret.x && ret.x <= r->h.x ) return ret;
        }
        
        if ( bottomPossible )
        {
            geom_poly_intersection(p1, p2, r, 3, &ret);
            if ( r->l.x <= ret.x && ret.x <= r->h.x ) return ret;
        }
    }
    
    assert( 0 );
}


int geom_intersections_of_rect( struct coord *p1, struct coord *p2, const struct rect *r, struct coord *intersections )
{
    int nrFound = 0;
    
    bool leftPossible =   ( p1->x < r->l.x && p2->x >= r->l.x ) || ( p2->x < r->l.x && p1->x >= r->l.x );
    bool rightPossible =  ( p1->x <= r->h.x && p2->x > r->h.x ) || ( p2->x <= r->h.x && p1->x > r->h.x );
    bool bottomPossible = ( p1->y < r->l.y && p2->y >= r->l.y ) || ( p2->y < r->l.y && p1->y >= r->l.y );
    bool topPossible =    ( p1->y <= r->h.y && p2->y > r->h.y ) || ( p2->y <= r->h.y && p1->y > r->h.y );
    
    
    struct coord ret;
    
    // Left + Right
    if ( p1->x != p2->x )
    {
        if ( leftPossible )
        {
            geom_poly_intersection(p1, p2, r, 0, &ret);
            if ( r->l.y <= ret.y && ret.y <= r->h.y )
            {
                intersections[nrFound] = ret;
                nrFound++;
            }
        }
        
        if ( rightPossible )
        {
            geom_poly_intersection(p1, p2, r, 1, &ret);
            if ( r->l.y <= ret.y && ret.y <= r->h.y )
            {
                intersections[nrFound] = ret;
                nrFound++;
            }
        }
    }
    
    // Top + bottom
    if ( p1->y != p2->y )
    {
        if ( topPossible )
        {
            geom_poly_intersection(p1, p2, r, 2, &ret);
            if ( r->l.x <= ret.x && ret.x <= r->h.x )
            {
                intersections[nrFound] = ret;
                nrFound++;
            }
        }
        
        if ( bottomPossible )
        {
            geom_poly_intersection(p1, p2, r, 3, &ret);
            if ( r->l.x <= ret.x && ret.x <= r->h.x )
            {
                intersections[nrFound] = ret;
                nrFound++;
            }
        }
    }
    
    assert( nrFound <= 2 );
    
    return nrFound;
}


int
geom_rect_intersects_or_contains_any_point(struct coord *coords, int count, const struct rect *r)
{
    int i;
    for ( i = 0; i < count; i++ )
    {
        if ( geom_point_is_inside_rect(coords[i], r) )
        {
            return 1;
        }
    }
    
    for ( i = 0; i < count - 1; i++ )
    {
        if ( geom_line_intersets_rect(&coords[i], &coords[i+1], r) )
        {
            return 1;
        }
    }
    
    return 0;
}

void geom_init()
{
}
