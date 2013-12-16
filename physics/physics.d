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
import util;
import world.world;
import entity.entity;
import block.block;

public struct CollisionMask
{
    private static shared ulong nextCollisionMaskBit = 0x1;
    public static ulong getNewCollisionMaskBit()
    {
        ulong retval = nextCollisionMaskBit;
        assert(retval != 0);
        nextCollisionMaskBit <<= 1;
        return retval;
    }
    public ulong mask = ~0;
    public EntityData * ignore = null;
    public this(ulong mask, EntityData * ignore = null)
    {
        this.mask = mask;
        this.ignore = ignore;
    }
    public this(EntityData * ignore)
    {
        this(~0, ignore);
    }
    public bool matches(ulong mask, EntityData * e)
    {
        if((mask & this.mask) != 0 && (e !is ignore || e is null))
            return true;
        return false;
    }
}

public struct Collision
{
    public Vector point; /// the point to move to
    public Vector normal = Vector(0, 0, 0);
    public int count = 0;
    public Dimension dimension;
    public this(Vector point, Dimension dimension, Vector normal)
    {
        this.point = point;
        this.normal = normal;
        this.dimension = dimension;
        this.count = 1;
    }
    public @property bool good()
    {
        return this.count > 0;
    }
    public void normalize()
    {
        if(good)
        {
            point /= count;
            normal /= count;
            count = 1;
        }
    }
}

public Collision combine(Collision a, Collision b)
{
    if(!a.good)
        return b;
    if(!b.good)
        return a;
    Collision retval = Collision(a.point + b.point, a.dimension, a.normal + b.normal);
    retval.count = a.count + b.count;
    return retval;
}

public struct Ray
{
    public Vector origin;
    public Vector dir;
    public Dimension dimension;
    public this(Vector origin, Dimension dimension, Vector dir)
    {
        this.origin = origin;
        assert(dir != Vector.ZERO);
        this.dir = normalize(dir);
        this.dimension = dimension;
    }
    public Ray transformAndSet(Matrix m)
    {
        Vector prevOrigin = origin;
        origin = m.apply(origin);
        dir = normalize(m.apply(prevOrigin + dir) - origin);
        return this;
    }
    public Vector eval(float t)
    {
        return origin + t * dir;
    }
}

public abstract class RayCollision
{
    public enum Type
    {
        Uninitialized,
        Block,
        Entity
    }
    public immutable Type type;
    public Vector point;
    public Dimension dimension;
    public float distance;
    public this(Type type, Vector point, Dimension dimension, float distance)
    {
        this.type = type;
        this.point = point;
        this.distance = distance;
        this.dimension = dimension;
    }
    public RayCollision transformAndSet(Matrix m)
    {
        point = m.apply(point);
        return this;
    }
}

public RayCollision min(RayCollision a, RayCollision b)
{
    if(a is null)
        return b;
    if(b is null)
        return a;
    if(a.distance < b.distance)
        return a;
    return b;
}

public interface RayCollisionArgs
{
}

public final class UninitializedRayCollision : RayCollision
{
    public this(Vector point, Dimension dimension, float distance)
    {
        super(Type.Uninitialized, point, dimension, distance);
    }
}

public final class BlockRayCollision : RayCollision
{
    public BlockPosition block;
    public this(Vector point, Dimension dimension, float distance, BlockPosition block)
    {
        super(Type.Block, point, dimension, distance);
        this.block = block;
    }
}

public final class EntityRayCollision : RayCollision
{
    public EntityData * entity;
    public this(Vector point, Dimension dimension, float distance, ref EntityData entity)
    {
        super(Type.Entity, point, dimension, distance);
        this.entity = &entity;
    }
    public this(Vector point, Dimension dimension, float distance, EntityData * entity)
    {
        this(point, dimension, distance, *entity);
        assert(entity !is null);
    }
    public this(RayCollision c, ref EntityData entity)
    {
        this(c.point, c.dimension, c.distance, entity);
    }
    public this(RayCollision c, EntityData * entity)
    {
        this(c.point, c.dimension, c.distance, entity);
    }
}

public BlockFace getRayEnterFace(Position pos, Ray ray)
{
    assert(ray.origin.x <= pos.x || ray.origin.x >= pos.x + 1 ||
       ray.origin.y <= pos.y || ray.origin.y >= pos.y + 1 ||
       ray.origin.z <= pos.z || ray.origin.z >= pos.z + 1);
    assert(ray.dimension == pos.dimension);
    Vector t = Vector.NXNYNZ;
    Vector cPos = Vector(pos.x, pos.y, pos.z);
    BlockFace xFace = BlockFace.NX;
    BlockFace yFace = BlockFace.NY;
    BlockFace zFace = BlockFace.NZ;
    if(fabs(ray.dir.x) >= eps)
    {
        if(ray.dir.x < 0)
        {
            cPos.x += 1;
            xFace = BlockFace.PX;
        }
        t.x = (cPos.x - ray.origin.x) / ray.dir.x;
        if(t.x > 0)
        {
            Vector hitPt = ray.eval(t.x);
            if(hitPt.y < pos.y || hitPt.y > pos.y + 1 || hitPt.z < pos.z || hitPt.z > pos.z + 1)
                t.x = -1;
        }
    }
    else if(ray.origin.x < pos.x || ray.origin.x > pos.x + 1)
        assert(false);
    if(fabs(ray.dir.y) >= eps)
    {
        if(ray.dir.y < 0)
        {
            cPos.y += 1;
            yFace = BlockFace.PY;
        }
        t.y = (cPos.y - ray.origin.y) / ray.dir.y;
        if(t.y > 0)
        {
            Vector hitPt = ray.eval(t.y);
            if(hitPt.x < pos.x || hitPt.x > pos.x + 1 || hitPt.z < pos.z || hitPt.z > pos.z + 1)
                t.y = -1;
        }
    }
    else if(ray.origin.y < pos.y || ray.origin.y > pos.y + 1)
        assert(false);
    if(fabs(ray.dir.z) >= eps)
    {
        if(ray.dir.z < 0)
        {
            cPos.z += 1;
            zFace = BlockFace.PZ;
        }
        t.z = (cPos.z - ray.origin.z) / ray.dir.z;
        if(t.z > 0)
        {
            Vector hitPt = ray.eval(t.z);
            if(hitPt.x < pos.x || hitPt.x > pos.x + 1 || hitPt.y < pos.y || hitPt.y > pos.y + 1)
                t.z = -1;
        }
    }
    else if(ray.origin.z < pos.z || ray.origin.z > pos.z + 1)
        assert(false);
    float minT = -1;
    BlockFace retval;
    if(t.x > 0 && (minT < 0 || minT > t.x))
    {
        retval = xFace;
        minT = t.x;
    }
    if(t.y > 0 && (minT < 0 || minT > t.y))
    {
        retval = yFace;
        minT = t.y;
    }
    if(t.z > 0 && (minT < 0 || minT > t.z))
    {
        retval = zFace;
        minT = t.z;
    }
    assert(minT > 0);
    return retval;
}

public BlockFace getRayExitFace(Position pos, Ray ray)
{
    assert(pos.dimension == ray.dimension);
    Vector t = Vector.NXNYNZ;
    Vector cPos = Vector(pos.x, pos.y, pos.z);
    BlockFace xFace = BlockFace.NX;
    BlockFace yFace = BlockFace.NY;
    BlockFace zFace = BlockFace.NZ;
    if(fabs(ray.dir.x) >= eps)
    {
        if(ray.dir.x > 0)
        {
            cPos.x += 1;
            xFace = BlockFace.PX;
        }
        t.x = (cPos.x - ray.origin.x) / ray.dir.x;
        if(t.x > 0)
        {
            Vector hitPt = ray.eval(t.x);
            if(hitPt.y < pos.y || hitPt.y > pos.y + 1 || hitPt.z < pos.z || hitPt.z > pos.z + 1)
                t.x = -1;
        }
    }
    else if(ray.origin.x < pos.x || ray.origin.x > pos.x + 1)
        assert(false);
    if(fabs(ray.dir.y) >= eps)
    {
        if(ray.dir.y > 0)
        {
            cPos.y += 1;
            yFace = BlockFace.PY;
        }
        t.y = (cPos.y - ray.origin.y) / ray.dir.y;
        if(t.y > 0)
        {
            Vector hitPt = ray.eval(t.y);
            if(hitPt.x < pos.x || hitPt.x > pos.x + 1 || hitPt.z < pos.z || hitPt.z > pos.z + 1)
                t.y = -1;
        }
    }
    else if(ray.origin.y < pos.y || ray.origin.y > pos.y + 1)
        assert(false);
    if(fabs(ray.dir.z) >= eps)
    {
        if(ray.dir.z > 0)
        {
            cPos.z += 1;
            zFace = BlockFace.PZ;
        }
        t.z = (cPos.z - ray.origin.z) / ray.dir.z;
        if(t.z > 0)
        {
            Vector hitPt = ray.eval(t.z);
            if(hitPt.x < pos.x || hitPt.x > pos.x + 1 || hitPt.y < pos.y || hitPt.y > pos.y + 1)
                t.z = -1;
        }
    }
    else if(ray.origin.z < pos.z || ray.origin.z > pos.z + 1)
        assert(false);
    float minT = -1;
    BlockFace retval;
    if(t.x > 0 && (minT < 0 || minT > t.x))
    {
        retval = xFace;
        minT = t.x;
    }
    if(t.y > 0 && (minT < 0 || minT > t.y))
    {
        retval = yFace;
        minT = t.y;
    }
    if(t.z > 0 && (minT < 0 || minT > t.z))
    {
        retval = zFace;
        minT = t.z;
    }
    assert(minT > 0);
    return retval;
}

public RayCollision collideWithBlock(Ray ray, RayCollision delegate(Vector position, Dimension dimension, float t) makeRetval)
{
    return collideWithBlock(Position(0, 0, 0, ray.dimension), ray, makeRetval);
}

public RayCollision collideWithBlock(Position pos, Ray ray, RayCollision delegate(Vector position, Dimension dimension, float t) makeRetval)
{
    assert(pos.dimension == ray.dimension);
    if(ray.origin.x >= pos.x && ray.origin.x <= pos.x + 1 &&
       ray.origin.y >= pos.y && ray.origin.y <= pos.y + 1 &&
       ray.origin.z >= pos.z && ray.origin.z <= pos.z + 1)
        return makeRetval(ray.origin, ray.dimension, 0);
    Vector t = Vector.NXNYNZ;
    Vector cPos = Vector(pos.x, pos.y, pos.z);
    if(fabs(ray.dir.x) >= eps)
    {
        if(ray.dir.x < 0)
            cPos.x += 1;
        t.x = (cPos.x - ray.origin.x) / ray.dir.x;
        if(t.x > 0)
        {
            Vector hitPt = ray.eval(t.x);
            if(hitPt.y < pos.y || hitPt.y > pos.y + 1 || hitPt.z < pos.z || hitPt.z > pos.z + 1)
                t.x = -1;
        }
    }
    else if(ray.origin.x < pos.x || ray.origin.x > pos.x + 1)
        return null;
    if(fabs(ray.dir.y) >= eps)
    {
        if(ray.dir.y < 0)
            cPos.y += 1;
        t.y = (cPos.y - ray.origin.y) / ray.dir.y;
        if(t.y > 0)
        {
            Vector hitPt = ray.eval(t.y);
            if(hitPt.x < pos.x || hitPt.x > pos.x + 1 || hitPt.z < pos.z || hitPt.z > pos.z + 1)
                t.y = -1;
        }
    }
    else if(ray.origin.y < pos.y || ray.origin.y > pos.y + 1)
        return null;
    if(fabs(ray.dir.z) >= eps)
    {
        if(ray.dir.z < 0)
            cPos.z += 1;
        t.z = (cPos.z - ray.origin.z) / ray.dir.z;
        if(t.z > 0)
        {
            Vector hitPt = ray.eval(t.z);
            if(hitPt.x < pos.x || hitPt.x > pos.x + 1 || hitPt.y < pos.y || hitPt.y > pos.y + 1)
                t.z = -1;
        }
    }
    else if(ray.origin.z < pos.z || ray.origin.z > pos.z + 1)
        return null;
    float minT = -1;
    if(t.x > 0 && (minT < 0 || minT > t.x))
        minT = t.x;
    if(t.y > 0 && (minT < 0 || minT > t.y))
        minT = t.y;
    if(t.z > 0 && (minT < 0 || minT > t.z))
        minT = t.z;
    if(minT > 0)
        return makeRetval(ray.eval(minT), ray.dimension, minT);
    return null;
}

public RayCollision collideWithAABB(Vector min, Vector max, Ray ray, RayCollision delegate(Vector position, Dimension dimension, float t) makeRetval)
{
    if(ray.origin.x >= min.x && ray.origin.x <= max.x &&
       ray.origin.y >= min.y && ray.origin.y <= max.y &&
       ray.origin.z >= min.z && ray.origin.z <= max.z)
        return makeRetval(ray.origin, ray.dimension, 0);
    Vector t = Vector.NXNYNZ;
    Vector cPos = min;
    if(fabs(ray.dir.x) >= eps)
    {
        if(ray.dir.x < 0)
            cPos.x = max.x;
        t.x = (cPos.x - ray.origin.x) / ray.dir.x;
        if(t.x > 0)
        {
            Vector hitPt = ray.eval(t.x);
            if(hitPt.y < min.y || hitPt.y > max.y || hitPt.z < min.z || hitPt.z > max.z)
                t.x = -1;
        }
    }
    else if(ray.origin.x < min.x || ray.origin.x > max.x)
        return null;
    if(fabs(ray.dir.y) >= eps)
    {
        if(ray.dir.y < 0)
            cPos.y = max.y;
        t.y = (cPos.y - ray.origin.y) / ray.dir.y;
        if(t.y > 0)
        {
            Vector hitPt = ray.eval(t.y);
            if(hitPt.x < min.x || hitPt.x > max.x || hitPt.z < min.z || hitPt.z > max.z)
                t.y = -1;
        }
    }
    else if(ray.origin.y < min.y || ray.origin.y > max.y)
        return null;
    if(fabs(ray.dir.z) >= eps)
    {
        if(ray.dir.z < 0)
            cPos.z = max.z;
        t.z = (cPos.z - ray.origin.z) / ray.dir.z;
        if(t.z > 0)
        {
            Vector hitPt = ray.eval(t.z);
            if(hitPt.x < min.x || hitPt.x > max.x || hitPt.y < min.y || hitPt.y > max.y)
                t.z = -1;
        }
    }
    else if(ray.origin.z < min.z || ray.origin.z > max.z)
        return null;
    float minT = -1;
    if(t.x > 0 && (minT < 0 || minT > t.x))
        minT = t.x;
    if(t.y > 0 && (minT < 0 || minT > t.y))
        minT = t.y;
    if(t.z > 0 && (minT < 0 || minT > t.z))
        minT = t.z;
    if(minT > 0)
        return makeRetval(ray.eval(minT), ray.dimension, minT);
    return null;
}

public struct PlaneEq /// dir points away from the inside halfspace
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
    public PlaneEq transformAndSet(Matrix m)
    {
        Ray r = Ray(this.dir * -d, Dimension.Overworld, this.dir);
        r.transformAndSet(m);
        this = PlaneEq(r.dir, r.origin);
        return this;
    }
}

public bool blockIntersectsPlane(PlaneEq planeEq, Vector min, Vector max)
{
    Vector pts[8] =
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
        if(planeEq.eval(pt) <= 0)
            return true;
    }
    return false;
}

public Vector getSurfacePointOnAABB(Vector min, Vector max, Vector pt)
{
    Vector center = (min + max) * 0.5;
    pt -= center;
    pt = normalize(pt);
    if(pt == Vector.ZERO)
        pt = Vector.Y;
    float closest = -1;
    if(fabs(pt.x) >= eps)
    {
        float t;
        if(pt.x > 0)
            t = (max.x - center.x) / pt.x;
        else
            t = (min.x - center.x) / pt.x;
        if(closest < 0 || t < closest)
            closest = t;
    }
    if(fabs(pt.y) >= eps)
    {
        float t;
        if(pt.y > 0)
            t = (max.y - center.y) / pt.y;
        else
            t = (min.y - center.y) / pt.y;
        if(closest < 0 || t < closest)
            closest = t;
    }
    if(fabs(pt.z) >= eps)
    {
        float t;
        if(pt.z > 0)
            t = (max.z - center.z) / pt.z;
        else
            t = (min.z - center.z) / pt.z;
        if(closest < 0 || t < closest)
            closest = t;
    }
    return center + closest * pt;
}

public bool rayIntersectsAABB(Vector min, Vector max, Vector origin, Vector dir)
{
    if(origin.x >= min.x && origin.x <= max.x &&
       origin.y >= min.y && origin.y <= max.y &&
       origin.z >= min.z && origin.z <= max.z)
        return true;
    Vector t = Vector.NXNYNZ;
    Vector cPos = min;
    if(fabs(dir.x) >= eps)
    {
        if(dir.x < 0)
            cPos.x = max.x;
        t.x = (cPos.x - origin.x) / dir.x;
        if(t.x > 0)
        {
            Vector hitPt = origin + dir * t.x;
            if(hitPt.y < min.y || hitPt.y > max.y || hitPt.z < min.z || hitPt.z > max.z)
                t.x = -1;
        }
    }
    else if(origin.x < min.x || origin.x > max.x)
        return false;
    if(fabs(dir.y) >= eps)
    {
        if(dir.y < 0)
            cPos.y = max.y;
        t.y = (cPos.y - origin.y) / dir.y;
        if(t.y > 0)
        {
            Vector hitPt = origin + dir * t.y;
            if(hitPt.x < min.x || hitPt.x > max.x || hitPt.z < min.z || hitPt.z > max.z)
                t.y = -1;
        }
    }
    else if(origin.y < min.y || origin.y > max.y)
        return false;
    if(fabs(dir.z) >= eps)
    {
        if(dir.z < 0)
            cPos.z = max.z;
        t.z = (cPos.z - origin.z) / dir.z;
        if(t.z > 0)
        {
            Vector hitPt = origin + dir * t.z;
            if(hitPt.x < min.x || hitPt.x > max.x || hitPt.y < min.y || hitPt.y > max.y)
                t.z = -1;
        }
    }
    else if(origin.z < min.z || origin.z > max.z)
        return false;
    float minT = -1;
    if(t.x > 0 && (minT < 0 || minT > t.x))
        minT = t.x;
    if(t.y > 0 && (minT < 0 || minT > t.y))
        minT = t.y;
    if(t.z > 0 && (minT < 0 || minT > t.z))
        minT = t.z;
    if(minT > 0)
        return true;
    return false;
}

public bool pointInRayCylinder(Vector pt, Vector origin, Vector dir, float r) /// assumes that dir is normalized
{
    pt -= origin;
    float t = dot(pt, dir);
    if(t < 0) t = 0;
    return absSquared(dir * t - pt) <= r * r;
}

public struct Cylinder
{
    public Vector origin; /// the center of the bottom
    public float r; /// the radius
    public float height; /// the height
    public this(Vector origin, float r, float height)
    {
        this.origin = origin;
        this.r = r;
        this.height = height;
    }
}

public Collision collideAABBWithCylinder(Vector min, Vector max, Dimension dimension, Cylinder c)
{
    min -= c.origin;
    max -= c.origin;
    if(max.y < 0)
        return Collision();
    if(min.y > c.height)
        return Collision();
    bool anyCollision = false;
    if(min.x <= 0 && max.x >= 0 && min.z <= 0 && max.z >= 0)
    {
        anyCollision = true;
    }
    else if(min.x <= 0 && max.x >= 0 && min.z <= c.r && max.z >= -c.r)
    {
        anyCollision = true;
    }
    else if(min.x <= c.r && max.x >= -c.r && min.z <= 0 && max.z >= 0)
    {
        anyCollision = true;
    }
    else
    {
        Vector center = (min + max) * 0.5;
        Vector corner = min;
        if(center.x > 0)
            corner.x = max.x;
        if(center.z > 0)
            corner.z = max.z;
        if(absSquared(corner) <= c.r * c.r)
            anyCollision = true;
    }
    if(anyCollision)
    {
        Vector center = (min + max) * 0.5;
        Collision retval;
        if(absSquared(Vector(center.x, 0, center.z)) * (c.height * c.height) <= absSquared(Vector(0, center.y - c.height * 0.5, 0)) * (c.r * c.r))
        {
            if(center.y < c.height * 0.5)
                retval = Collision(c.origin, dimension, Vector.Y);
            else
                retval = Collision(c.origin + Vector(0, c.height, 0), dimension, Vector.NY);
        }
        else
        {
            if(fabs(center.x) * (max.z - min.z) > fabs(center.z) * (max.x - min.x))
            {
                if(center.x < 0)
                    retval = Collision(c.origin + Vector(0, c.height * 0.5, 0), dimension, Vector.X);
                else
                    retval = Collision(c.origin + Vector(0, c.height * 0.5, 0), dimension, Vector.NX);
            }
            else
            {
                if(center.z < 0)
                    retval = Collision(c.origin + Vector(0, c.height * 0.5, 0), dimension, Vector.Z);
                else
                    retval = Collision(c.origin + Vector(0, c.height * 0.5, 0), dimension, Vector.NZ);
            }
        }
        retval.point = getSurfacePointOnAABB(min + c.origin, max + c.origin, retval.point);
        return retval;
    }
    return Collision();
}

private Vector getAABBWithBoxNormal(Vector min, Vector max, Vector pt)
{
    PlaneEq[6] peqs =
    [
        PlaneEq(Vector.NX, min),
        PlaneEq(Vector.X, max),
        PlaneEq(Vector.NY, min),
        PlaneEq(Vector.Y, max),
        PlaneEq(Vector.NZ, min),
        PlaneEq(Vector.Z, max)
    ];
    float minDistance = -1;
    PlaneEq minPEq;
    foreach(PlaneEq peq; peqs)
    {
        float distance = peq.eval(pt);
        if(minDistance < 0 || minDistance > distance)
        {
            minPEq = peq;
            minDistance = distance;
        }
    }
    return minPEq.dir;
}

public Collision collideAABBWithBox(Vector min, Vector max, Dimension dimension, Matrix boxTransform)
{
    Vector[8] pts;
    bool retval = false;
    foreach(int i, ref Vector p; pts)
    {
        p = boxTransform.apply(Vector(i & 1 ? 1 : 0, i & 2 ? 1 : 0, i & 4 ? 1 : 0));
        if(p.x >= min.x && p.x <= max.x && p.y >= min.y && p.y <= max.y && p.z >= min.z && p.z <= max.z)
        {
            return Collision(getSurfacePointOnAABB(min, max, p), dimension, getAABBWithBoxNormal(min, max, p));
        }
    }
    PlaneEq[6] peqs =
    [
        PlaneEq(Vector.NX, Vector.ZERO),
        PlaneEq(Vector.X, Vector.X),
        PlaneEq(Vector.NY, Vector.ZERO),
        PlaneEq(Vector.Y, Vector.Y),
        PlaneEq(Vector.NZ, Vector.ZERO),
        PlaneEq(Vector.Z, Vector.Z)
    ];
    foreach(ref PlaneEq peq; peqs)
    {
        peq.transformAndSet(boxTransform);
    }
    for(int i = 0; i <= 0x7; i++)
    {
        Vector p = Vector(i & 1 ? min.x : max.x, i & 2 ? min.y : max.y, i & 4 ? min.z : max.z);
        bool inside = true;
        float minDistance = -1;
        PlaneEq minPEq;
        foreach(PlaneEq peq; peqs)
        {
            float distance = peq.eval(p);
            if(distance > 0)
            {
                inside = false;
                break;
            }
            if(minDistance < 0 || minDistance > distance)
            {
                minPEq = peq;
                minDistance = distance;
            }
        }
        if(inside)
        {
            return Collision(getSurfacePointOnAABB(min, max, p), dimension, minPEq.dir);
        }
    }
    return Collision();
}

public Collision collideCylinderWithCylinder(Cylinder a, Dimension dimension, Cylinder b)
{
    a.origin -= b.origin;
    if(a.origin.y > b.height)
        return Collision();
    if(a.origin.y < -a.height)
        return Collision();
    Vector xzDiff = a.origin;
    xzDiff.y = 0;
    if(absSquared(xzDiff) > (a.r + b.r) * (a.r + b.r))
        return Collision();
    float rOverlap = a.r + b.r - abs(xzDiff);
    float closestR = abs(xzDiff) - a.r;
    if(closestR < 0)
        closestR = 0;
    if(rOverlap > a.r)
        rOverlap = a.r;
    if(rOverlap > b.r)
        rOverlap = b.r;
    float yOverlap;
    if(a.origin.y > 0)
    {
        if(a.origin.y + a.height > b.height)
        {
            yOverlap = b.height - a.origin.y;
        }
        else
        {
            yOverlap = a.height;
        }
    }
    else
    {
        if(a.origin.y + a.height > b.height)
        {
            yOverlap = b.height;
        }
        else
        {
            yOverlap = a.origin.y + a.height;
        }
    }
    float closestY;
    if(a.origin.y > b.height * 0.5)
        closestY = a.origin.y;
    else if(a.origin.y + a.height < b.height * 0.5)
        closestY = a.origin.y + a.height;
    else
    {
        closestY = b.height * 0.5;
        closestR = a.r;
    }
    Vector xzDiffDir = normalize(xzDiff);
    Vector closestPt = xzDiffDir * closestR + Vector(0, closestY, 0);
    if(rOverlap > yOverlap)
    {
        if(a.origin.y + a.height * 0.5 - b.height * 0.5 > 0)
            return Collision(closestPt + b.origin, dimension, Vector.NY);
        return Collision(closestPt + b.origin, dimension, Vector.Y);
    }
    else
    {
        return Collision(closestPt + b.origin, dimension, -xzDiffDir);
    }
}
