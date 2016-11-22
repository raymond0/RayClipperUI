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
#ifndef NAVIT_GEOM_H
#define NAVIT_GEOM_H


/*! A integer mercator coordinate */
struct coord {
    int x; /*!< X-Value */
    int y; /*!< Y-Value */
};

#define coord_is_equal(a,b) ((a).x==(b).x && (a).y==(b).y)

#define sq(x) ((double)(x)*(x))

struct rect {struct coord l,h;};

enum geom_poly_segment_type {
	geom_poly_segment_type_none,
	geom_poly_segment_type_way_inner,
	geom_poly_segment_type_way_outer,
	geom_poly_segment_type_way_left_side,
	geom_poly_segment_type_way_right_side,
	geom_poly_segment_type_way_unknown,

};

struct geom_poly_segment {
	enum geom_poly_segment_type type;
	struct coord *first,*last;
};
/* prototypes */
double coord_distance(struct coord from, struct coord to);
void geom_coord_copy(struct coord *from, struct coord *to, int count, int reverse);
void geom_coord_revert(struct coord *c, int count);
int geom_line_middle(struct coord *p, int count, struct coord *c);
long long geom_poly_area(struct coord *c, int count);
int geom_poly_centroid(struct coord *c, int count, struct coord *r);
int geom_poly_point_inside(const struct coord *cp, int count, const struct coord *c);
int geom_poly_closest_point(struct coord *pl, int count, struct coord *p, struct coord *c);
void geom_poly_segment_destroy(struct geom_poly_segment *seg);
int geom_poly_segment_compatible(struct geom_poly_segment *s1, struct geom_poly_segment *s2, int dir);
int geom_clip_line_code(struct coord *p1, struct coord *p2, struct rect *r);
int geom_is_inside(struct coord *p, struct rect *r, int edge);
void geom_poly_intersection(struct coord *p1, struct coord *p2, const struct rect *r, int edge, struct coord *ret);
int geom_rect_intersects_or_contains_any_point(struct coord *coords, int count, const struct rect *r);
int geom_point_is_inside_rect(struct coord coord, const struct rect *r);
int geom_line_intersets_rect(struct coord *p1, struct coord *p2, const struct rect *r);
int geom_intersections_of_rect( struct coord *p1, struct coord *p2, const struct rect *r, struct coord *intersections );

    
/*typedef enum
{
    EdgeLeft = 0,
    EdgeRight = 1,
    EdgeTop = 2,
    EdgeBototm = 3
} EdgeType;*/
    
struct coord geom_interestion_of_rect( struct coord *p1, struct coord *p2, const struct rect *r );

void geom_init(void);
/* end of prototypes */

#endif

