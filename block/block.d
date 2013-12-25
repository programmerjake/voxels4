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
module block.block;
public import render.mesh;
public import render.texture_descriptor;
public import world.world;
public import world.block_face;
public import persistance.game_load_stream;
public import persistance.game_store_stream;
import block.air;
public import physics.physics;
import platform;

public struct BlockData
{
    BlockDescriptor descriptor = null;
    uint data = 0;
    void * extraData = null;
    ubyte sunlight = 0, scatteredSunlight = 0, light = 0;
    public this(BlockDescriptor descriptor)
    {
        this.descriptor = descriptor;
    }
    public @property bool good() const
    {
        return descriptor !is null;
    }
    public TransformedMesh getDrawMesh(BlockPosition pos, RenderLayer rl)
    {
        assert(good);
        return descriptor.getDrawMesh(pos, rl);
    }
    public TransformedMesh getEntityDrawMesh(RenderLayer rl)
    {
        assert(good);
        return descriptor.getEntityDrawMesh(this, rl);
    }
    public TransformedMesh getItemDrawMesh()
    {
        assert(good);
        return descriptor.getItemDrawMesh(this);
    }
    public bool graphicsChanges(BlockPosition pos)
    {
        assert(good);
        return descriptor.graphicsChanges(pos);
    }
    public bool isSideBlocked(BlockFace face)
    {
        assert(good);
        return descriptor.isSideBlocked(this, face);
    }
    public bool isOpaque()
    {
        assert(good);
        return descriptor.isOpaque(this);
    }
    public Collision collideWithCylinder(BlockPosition pos, Cylinder c, CollisionMask mask)
    {
        assert(good);
        return descriptor.collideWithCylinder(pos, c, mask);
    }
    public Collision collideWithBox(BlockPosition pos, Vector min, Vector max, CollisionMask mask)
    {
        assert(good);
        return descriptor.collideWithBox(pos, min, max, mask);
    }
    public RayCollision collide(Ray ray, RayCollisionArgs cArgs)
    {
        if(!good)
            return collideWithBlock(ray, delegate RayCollision(Vector position, Dimension dimension, float t) {return new UninitializedRayCollision(position, dimension, t);});
        return descriptor.collide(this, ray, cArgs);
    }
    public RayCollision collide(BlockPosition pos, Ray ray, RayCollisionArgs cArgs)
    {
        ray.origin -= Vector(pos.position.x, pos.position.y, pos.position.z);
        RayCollision retval;
        if(!good)
            retval = collideWithBlock(ray, delegate RayCollision(Vector position, Dimension dimension, float t) {return new UninitializedRayCollision(position, dimension, t);});
        else
            retval = descriptor.collide(this, ray, cArgs);
        if(cast(BlockRayCollision)retval !is null)
        {
            (cast(BlockRayCollision)retval).block = pos;
        }
        if(retval !is null)
            retval.point += Vector(pos.position.x, pos.position.y, pos.position.z);
        return retval;
    }
    public BoxList getCollisionBoxes(BlockPosition pos)
    {
        if(!good)
            return [CollisionBox(Vector(pos.position.x, pos.position.y, pos.position.z), Vector(pos.position.x + 1, pos.position.y + 1, pos.position.z + 1), pos.position.dimension)];
        return descriptor.getCollisionBoxes(pos);
    }
    public CollisionBox getBoundingBox(BlockPosition pos)
    {
        if(!good)
            return CollisionBox(Vector(pos.position.x, pos.position.y, pos.position.z), Vector(pos.position.x + 1, pos.position.y + 1, pos.position.z + 1), pos.position.dimension);
        return descriptor.getBoundingBox(pos);
    }
    public ulong getCollisionMask()
    {
        if(!good)
            return ~0;
        return descriptor.getCollisionMask();
    }
    public bool opEquals(BlockData rt)
    {
        if(descriptor !is rt.descriptor)
            return false;
        if(!good)
            return true;
        return descriptor.isEqual(this, rt);
    }
    public int maxStackSize()
    {
        if(good)
            return descriptor.maxStackSize();
        return 0;
    }
}

public abstract class BlockDescriptor
{
    public immutable string name;
    public this(string name)
    {
        this.name = name;
        addToBlockList(this);
    }

    public abstract TransformedMesh getDrawMesh(BlockPosition pos, RenderLayer rl);
    public abstract TransformedMesh getEntityDrawMesh(BlockData data, RenderLayer rl);
    public abstract TransformedMesh getItemDrawMesh(BlockData data);
    public abstract bool graphicsChanges(BlockPosition pos);
    public abstract bool isSideBlocked(BlockData data, BlockFace face);
    public abstract bool isOpaque(BlockData data);
    protected abstract BlockData readInternal(GameLoadStream gls);
    protected uint getEmittedLight(BlockData data)
    {
        return 0;
    }
    protected abstract void writeInternal(BlockData data, GameStoreStream gss);
    public abstract Collision collideWithCylinder(BlockPosition pos, Cylinder c, CollisionMask mask);
    public abstract Collision collideWithBox(BlockPosition pos, Vector min, Vector max, CollisionMask mask);
    public abstract RayCollision collide(BlockData data, Ray ray, RayCollisionArgs cArgs);
    public abstract BoxList getCollisionBoxes(BlockPosition pos);
    public abstract ulong getCollisionMask();
    public bool isEqual(BlockData l, BlockData r)
    {
        return l is r;
    }
    public int maxStackSize()
    {
        return 64;
    }
    public CollisionBox getBoundingBox(BlockPosition pos)
    {
        BoxList boxes = getCollisionBoxes(pos);
        if(boxes.length == 0)
            return CollisionBox(Vector(pos.position.x, pos.position.y, pos.position.z), Vector(pos.position.x + 1, pos.position.y + 1, pos.position.z + 1), pos.position.dimension);
        CollisionBox retval = boxes[0];
        foreach(CollisionBox b; boxes[1 .. boxes.length])
        {
            if(retval.min.x > b.min.x)
                retval.min.x = b.min.x;
            if(retval.min.y > b.min.y)
                retval.min.y = b.min.y;
            if(retval.min.z > b.min.z)
                retval.min.z = b.min.z;
            if(retval.max.x < b.max.x)
                retval.max.x = b.max.x;
            if(retval.max.y < b.max.y)
                retval.max.y = b.max.y;
            if(retval.max.z < b.max.z)
                retval.max.z = b.max.z;
        }
        return retval;
    }

    public static void write(BlockData data, GameStoreStream gss)
    {
        assert(data.good);
        gss.write(data.descriptor);
        data.descriptor.writeInternal(data, gss);
    }

    public static BlockData read(GameLoadStream gls)
    {
        return gls.readBlockDescriptor().readInternal(gls);
    }

    private static BlockDescriptor[string] blocks;
    private static BlockDescriptor[] blockList;
    private static void addToBlockList(BlockDescriptor bd)
    {
        assert(blocks.get(bd.name, cast(BlockDescriptor)null) is null);
        blocks[bd.name] = bd;
        blockList ~= [bd];
    }
    public static BlockDescriptor getBlock(string name)
    {
        return blocks.get(name, cast(BlockDescriptor)null);
    }
    public static size_t getBlockCount()
    {
        return blockList.length;
    }
    public static BlockDescriptor getBlock(size_t index)
    {
        assert(index >= 0 && index < blockList.length);
        return blockList[index];
    }
    public static bool isSideBlocked(BlockPosition pos, BlockFace f)
    {
        pos.moveBy(f);
        BlockData bd = pos.get();
        if(bd.good)
            return bd.isSideBlocked(f);
        return true;
    }
    public static TransformedMesh makeBlockItemMesh(TransformedMesh mesh)
    {
        immutable float sqrt_3 = sqrt(3.0);
        immutable Matrix mat = Matrix.translate(-0.5, -0.5, -0.5)
                                     .concat(Matrix.rotateY(-PI / 4))
                                     .concat(Matrix.rotateX(PI / 6))
                                     .concat(Matrix.scale(0.8 / sqrt_3, 0.8 / sqrt_3, 0.1 / sqrt_3))
                                     .concat(Matrix.translate(0.5, 0.5, 0.1));
        return TransformedMesh(mesh, mat);
    }
}

struct BlockStack
{
    private BlockData block_ = BlockData(null);
    private int count_ = 0;
    public @property int count()
    {
        return count_;
    }
    public @property int spaceLeft()
    {
        return block.maxStackSize() - count;
    }
    public @property float fractionUsed()
    {
        int maxStackSize = block.maxStackSize();
        if(maxStackSize <= 0)
            return 0;
        return cast(float)count / maxStackSize;
    }
    public @property BlockData block()
    {
        return block_;
    }
    public this(int c, BlockData b)
    {
        assert(c >= 0 && c <= b.maxStackSize());
        assert(c > 0 || !b.good);
        count_ = c;
        block_ = b;
    }
    public this(BlockData b)
    {
        if(b.maxStackSize() > 0)
            count_ = 1;
        else
        {
            count_ = 0;
            b = BlockData(null);
        }
        block_ = b;
    }
    public int transfer(ref BlockStack src, int c) /// Returns: the transferred count
    {
        if(c <= 0)
            return 0;
        if(block.good && block != src.block)
            return 0;
        if(c > src.count)
            c = src.count;
        if(block.good && c > spaceLeft)
            c = spaceLeft;
        if(c <= 0)
            return 0;
        if(!block.good)
            block_ = src.block;
        src.count_ -= c;
        count_ += c;
        return c;
    }
    public void write(GameStoreStream gss)
    {
        gss.write(cast(ubyte)count);
        if(count > 0)
            BlockDescriptor.write(block, gss);
    }
    public static BlockStack read(GameLoadStream gls)
    {
        int c = cast(ubyte)gls.readByte();
        if(c > 0)
        {
            BlockData b = BlockDescriptor.read(gls);
            if(c > b.maxStackSize())
                throw new InvalidDataValueException("block stack count too large");
            return BlockStack(c, b);
        }
        return BlockStack();
    }
}

struct BlockStackArray(size_t w, size_t h)
{
    public static immutable size_t WIDTH = w, HEIGHT = h;
    private BlockStack[WIDTH * HEIGHT] blocks;
    public BlockStack opIndex(size_t x, size_t y)
    {
        assert(x >= 0 && x < WIDTH && y >= 0 && y < HEIGHT);
        return blocks[x + WIDTH * y];
    }
    public void opIndexAssign(BlockStack bs, size_t x, size_t y)
    {
        assert(x >= 0 && x < WIDTH && y >= 0 && y < HEIGHT);
        blocks[x + WIDTH * y] = bs;
    }

    public int add(ref BlockStack src, int c) /// Returns: the transferred count
    {
        int retval = 0;
        foreach(ref BlockStack bs; blocks)
        {
            retval += bs.transfer(src, c - retval);
        }
        return retval;
    }

    public int remove(ref BlockStack dest, int c) /// Returns: the transferred count
    {
        int retval = 0;
        foreach(ref BlockStack bs; blocks)
        {
            retval += dest.transfer(bs, c - retval);
        }
        return retval;
    }

    public void read(GameLoadStream gls)
    {
        foreach(ref BlockStack bs; blocks)
        {
            bs = BlockStack.read(gls);
        }
    }
    public void write(GameStoreStream gss)
    {
        foreach(BlockStack bs; blocks)
        {
            bs.write(gss);
        }
    }
}
