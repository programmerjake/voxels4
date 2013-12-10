/*
 * Voxels is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Voxels is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Voxels; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 */
module physics.physics;
public import vector;
public import matrix;

public struct Ray
{
    public Vector origin;
    public Vector dir;
    public this(Vector origin, Vector dir)
    {
        this.origin = origin;
        assert(dir != Vector.ZERO);
        this.dir = normalize(dir);
    }
    public Ray transform(Matrix m)
    {
        Vector prevOrigin = origin;
        origin = m.apply(origin);
        dir = m.apply(prevOrigin + dir) - origin;
    }
    public Vector eval(float t)
    {
        return origin + t * dir;
    }
}

public struct PlaneEq
{
    public Vector dir;
    public float d;
    public this(Vector dir, float d)
    {
        this.dir = dir;
        this.d = d;
    }
    public this(float a, float b, float c, float d)
    {
        this.dir = Vector(a, b, c);
        this.d = d;
    }
    public this(Vector normal, Vector p)
    {
        this.dir = normal;
        this.d = -dot(this.dir, p);
    }
    public this(Vector p1, Vector p2, Vector p3)
    {
	    this(normalize(cross(p2 - p1, p3 - p1)), p1);
    }
    public float eval(Vector p)
    {
        return dot(p, dir) + d;
    }
    public float intersect(Ray ray)
    {
        float divisor = dot(ray.dir, dir);
        if(divisor == 0)
            return -1;
        float numerator = -d - dot(ray.origin, dir);
        return numerator / divisor;
    }
    public PlaneEq transform(Matrix m)
    {
        Ray r = Ray(this.dir * -d, this.dir);
        r.transform(m);
        this = PlaneEq(r.dir, r.origin);
        return this;
    }
}

public bool blockIntersectsPlane(PlaneEq planeEq, Vector min, Vector max)
{
    assert(false, "finish"); //FIXME(jacob#): finish
    /*Vector pts[8] =
    [
        Vector(min.x, min.y, min.z),
        Vector(min.x, min.y, max.z),
        Vector(min.x, max.y, min.z),
        Vector(min.x, max.y, max.z),
        Vector(max.x, min.y, min.z),
        Vector(max.x, min.y, max.z),
        Vector(max.x, max.y, min.z),
        Vector(max.x, max.y, max.z),
    ];
    foreach(Vector pt; pts)
    {
        if(planeEq.eval(pt))
    }*/
}
