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

public struct Collision
{
    public Vector point, normal = Vector(0, 0, 0);
    public Dimension dimension;
    public this(Vector point, Dimension dimension, Vector normal)
    {
        this.point = point;
        this.normal = normal;
        this.dimension = dimension;
    }
    public @property bool good()
    {
        return this.normal != Vector.ZERO;
    }
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
    public PlaneEq transform(Matrix m)
    {
        Ray r = Ray(this.dir * -d, Dimension.Overworld, this.dir);
        r.transform(m);
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

public bool rayIntersectsAABB(Vector min, Vector max, Vector origin, Vector dir)
{
    if(origin.x >= min.x && origin.x <= max.x &&
       origin.y >= min.y && origin.y <= max.y &&
       origin.z >= min.z && origin.z <= max.z)
        return true;
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
        return false;
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
        return false;
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
