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
module world.world;
import block.block;
import util;
import std.math;
import world.block_face;
import block.air;
import matrix;
import block.stone.bedrock;
import render.mesh;
import platform;
import vector;
import std.conv;
import entity.entity;
import std.stdio;
import physics.physics;

public enum Dimension
{
    Overworld,
}

public enum RenderLayer
{
    Opaque, /// also totally transparent
    Translucent,
}

private static void renderLayerSetup(RenderLayer rl)
{
    final switch(rl)
    {
    case RenderLayer.Opaque:
        glDepthMask(GL_TRUE);
        break;
    case RenderLayer.Translucent:
        glDepthMask(GL_FALSE);
        break;
    }
}

private struct ChunkPosition
{
    public int x, z;
    public Dimension dimension = Dimension.Overworld;
    public this(int x, int z, Dimension dimension)
    {
        this.x = x;
        this.z = z;
        this.dimension = dimension;
    }

    public this(Vector p, Dimension dimension)
    {
        this.x = ifloor(p.x) & Chunk.FLOOR_SIZE_MASK;
        this.z = ifloor(p.z) & Chunk.FLOOR_SIZE_MASK;
        this.dimension = dimension;
    }

    public @property ChunkPosition nx()
    {
        return ChunkPosition(this.x - Chunk.XZ_SIZE, this.z, this.dimension);
    }

    public @property ChunkPosition px()
    {
        return ChunkPosition(this.x + Chunk.XZ_SIZE, this.z, this.dimension);
    }

    public @property ChunkPosition nz()
    {
        return ChunkPosition(this.x, this.z - Chunk.XZ_SIZE, this.dimension);
    }

    public @property ChunkPosition pz()
    {
        return ChunkPosition(this.x, this.z + Chunk.XZ_SIZE, this.dimension);
    }
}

public struct Position
{
    public int x, y, z;
    public Dimension dimension;
    this(int x, int y, int z, Dimension dimension)
    {
        this.x = x;
        this.y = y;
        this.z = z;
        this.dimension = dimension;
    }
}

public struct BlockPosition
{
    private World worldInternal = null;
    public @property World world()
    {
        return worldInternal;
    }
    public @property bool good()
    {
        return world !is null;
    }
    private int x, y, z, chunkIndex;
    private Dimension dimension;
    package Chunk chunk = null;

    package this(World world, in int x, in int y, in int z, in Dimension dimension)
    {
        this.worldInternal = world;
        this.x = x;
        this.y = y;
        this.z = z;
        this.dimension = dimension;
        int chunkX = x & Chunk.FLOOR_SIZE_MASK;
        int chunkZ = z & Chunk.FLOOR_SIZE_MASK;
        this.chunk = world.getOrAddChunk(ChunkPosition(chunkX,
                                                           chunkZ,
                                                           dimension));
        this.chunkIndex = (x & Chunk.MOD_SIZE_MASK) + Chunk.Y_INDEX_FACTOR * y
                + Chunk.Z_INDEX_FACTOR * (z & Chunk.MOD_SIZE_MASK);
    }

    package this(in int x, in int y, in int z, Chunk c)
    {
        this.worldInternal = c.world;
        this.x = x;
        this.y = y;
        this.z = z;
        this.dimension = c.position.dimension;
        this.chunk = c;
        this.chunkIndex = (x & Chunk.MOD_SIZE_MASK) + Chunk.Y_INDEX_FACTOR * y
                + Chunk.Z_INDEX_FACTOR * (z & Chunk.MOD_SIZE_MASK);
    }

    public this(BlockPosition rt)
    {
        this.worldInternal = rt.world;
        this.x = rt.x;
        this.y = rt.y;
        this.z = rt.z;
        this.dimension = rt.dimension;
        this.chunk = rt.chunk;
        this.chunkIndex = rt.chunkIndex;
    }

    public static struct BlockPositionPosition
    {
        public immutable int x, y, z;
        public immutable Dimension dimension;
        public @disable this();
        package this(int x, int y, int z, Dimension dimension)
        {
            this.x = x;
            this.y = y;
            this.z = z;
            this.dimension = dimension;
        }
        public Position opCast(T = Position)()
        {
            return Position(x, y, z, dimension);
        }
    }

    public @property BlockPositionPosition position()
    {
        assert(good);
        return BlockPositionPosition(x, y, z, dimension);
    }

    public void moveTo(in int x, in int y, in int z)
    {
        moveBy(x - this.x, y - this.y, z - this.z);
    }

    public void moveTo(Vector p)
    {
        moveTo(ifloor(p.x), ifloor(p.y), ifloor(p.z));
    }

    public void moveBy(in int dx, in int dy, in int dz)
    {
        assert(good);
        this.x = this.x + dx;
        this.y = this.y + dy;
        this.z = this.z + dz;
        this.chunkIndex = (this.x & Chunk.MOD_SIZE_MASK) + Chunk.Y_INDEX_FACTOR
                * this.y + Chunk.Z_INDEX_FACTOR
                * (this.z & Chunk.MOD_SIZE_MASK);
        int newChunkX = this.x & Chunk.FLOOR_SIZE_MASK;
        int newChunkZ = this.z & Chunk.FLOOR_SIZE_MASK;
        if(abs(newChunkX - this.chunk.position.x) <= Chunk.XZ_SIZE
                && abs(newChunkZ - this.chunk.position.z) <= Chunk.XZ_SIZE)
        {
            do
            {
                if(newChunkX == this.chunk.position.x - Chunk.XZ_SIZE
                        && this.chunk.nx !is null)
                {
                    this.chunk = this.chunk.nx;
                }
                else
                    break;
                if(newChunkX == this.chunk.position.x + Chunk.XZ_SIZE
                        && this.chunk.px !is null)
                {
                    this.chunk = this.chunk.px;
                }
                else
                    break;
                if(newChunkZ == this.chunk.position.z - Chunk.XZ_SIZE
                        && this.chunk.nz !is null)
                {
                    this.chunk = this.chunk.nz;
                }
                else
                    break;
                if(newChunkZ == this.chunk.position.z + Chunk.XZ_SIZE
                        && this.chunk.pz !is null)
                {
                    this.chunk = this.chunk.pz;
                }
                else
                    break;
                return;
            }
            while(false);
        }
        this.chunk = this.world.getOrAddChunk(ChunkPosition(newChunkX,
                                                                newChunkZ,
                                                                this.dimension));
    }

    public void moveBy(in BlockFace bf)
    {
        assert(good);
        final switch(bf)
        {
        case BlockFace.NX:
            if((this.x & Chunk.MOD_SIZE_MASK) == 0)
            {
                this.chunkIndex += (Chunk.XZ_SIZE - 1);
                this.x--;
                if(this.chunk.nx !is null)
                    this.chunk = this.chunk.nx;
                else
                    this.chunk = this.world.getOrAddChunk(ChunkPosition(this.x
                                                                                    & Chunk.FLOOR_SIZE_MASK,
                                                                            this.z
                                                                                    & Chunk.FLOOR_SIZE_MASK,
                                                                            this.dimension));
            }
            else
            {
                this.chunkIndex -= 1;
                this.x--;
            }
            break;
        case BlockFace.NY:
            this.y--;
            this.chunkIndex -= Chunk.Y_INDEX_FACTOR;
            break;
        case BlockFace.NZ:
            if((this.z & Chunk.MOD_SIZE_MASK) == 0)
            {
                this.chunkIndex += (Chunk.XZ_SIZE - 1) * Chunk.Z_INDEX_FACTOR;
                this.z--;
                if(this.chunk.nz !is null)
                    this.chunk = this.chunk.nz;
                else
                    this.chunk = this.world.getOrAddChunk(ChunkPosition(this.x
                                                                                    & Chunk.FLOOR_SIZE_MASK,
                                                                            this.z
                                                                                    & Chunk.FLOOR_SIZE_MASK,
                                                                            this.dimension));
            }
            else
            {
                this.chunkIndex -= Chunk.Z_INDEX_FACTOR;
                this.z--;
            }
            break;
        case BlockFace.PX:
            if((this.x & Chunk.MOD_SIZE_MASK) == Chunk.XZ_SIZE - 1)
            {
                this.chunkIndex -= (Chunk.XZ_SIZE - 1);
                this.x++;
                if(this.chunk.px !is null)
                    this.chunk = this.chunk.px;
                else
                    this.chunk = this.world.getOrAddChunk(ChunkPosition(this.x
                                                                                    & Chunk.FLOOR_SIZE_MASK,
                                                                            this.z
                                                                                    & Chunk.FLOOR_SIZE_MASK,
                                                                            this.dimension));
            }
            else
            {
                this.chunkIndex += 1;
                this.x++;
            }
            break;
        case BlockFace.PY:
            this.y++;
            this.chunkIndex += Chunk.Y_INDEX_FACTOR;
            break;
        case BlockFace.PZ:
            if((this.z & Chunk.MOD_SIZE_MASK) == Chunk.XZ_SIZE - 1)
            {
                this.chunkIndex -= (Chunk.XZ_SIZE - 1) * Chunk.Z_INDEX_FACTOR;
                this.z++;
                if(this.chunk.pz !is null)
                    this.chunk = this.chunk.pz;
                else
                    this.chunk = this.world.getOrAddChunk(ChunkPosition(this.x
                                                                                    & Chunk.FLOOR_SIZE_MASK,
                                                                            this.z
                                                                                    & Chunk.FLOOR_SIZE_MASK,
                                                                            this.dimension));
            }
            else
            {
                this.chunkIndex += Chunk.Z_INDEX_FACTOR;
                this.z++;
            }
            break;
        }
    }

    public BlockData getNotNull()
    {
        assert(good);
        if(this.y < 0)
            return BlockData(Bedrock.BEDROCK);
        if(this.y >= World.MAX_HEIGHT)
            return BlockData(Air.AIR);
        BlockData retval = this.chunk.blocks[this.chunkIndex];
        if(!retval.good)
            return BlockData(Air.AIR);
        return retval;
    }

    public BlockData get()
    {
        assert(good);
        if(this.y < 0 || this.y >= World.MAX_HEIGHT)
            return BlockData();
        return this.chunk.blocks[this.chunkIndex];
    }

    public void updateAbsolute(in UpdateType type, in double theTime)
    {
        assert(good);
        if(this.y < 0 || this.y >= World.MAX_HEIGHT)
            return;
        this.world.replaceBlockUpdateIfNewer(this.chunk,
                                             new BlockUpdateEvent(BlockUpdatePosition(this.x,
                                                                  this.y,
                                                                  this.z,
                                                                  this.dimension,
                                                                  type),
                                                                  theTime,
                                                                  this.chunk, this.world));
    }

    public void updateRelative(in UpdateType type, in double deltaTime)
    {
        assert(good);
        updateAbsolute(type, deltaTime + this.world.currentTime);
    }

    public void set(BlockData blockData)
    {
        assert(good);
        if(this.y < 0 || this.y >= World.MAX_HEIGHT)
            return;
        this.world.setBlock(this.x, this.y, this.z, this.dimension, blockData);
    }

    public Position getPosition()
    {
        assert(good);
        return Position(this.x, this.y, this.z, this.dimension);
    }

    package void clearUpdate(in BlockUpdatePosition pos)
    {
        assert(good);
        this.world.removeBlockUpdate(this.chunk, pos);
    }

    public void clearUpdate(in UpdateType type)
    {
        assert(good);
        if(this.y < 0 || this.y >= World.MAX_HEIGHT)
            return;
        clearUpdate(BlockUpdatePosition(this.x,
                                       this.y,
                                       this.z,
                                       this.dimension,
                                       type));
    }
}

public enum UpdateType
{
    Lighting = 0,
    General,
}

public @property bool autoAddUpdate(UpdateType ut)
{
    final switch(ut)
    {
    case UpdateType.Lighting:
        return true;
    case UpdateType.General:
        return false;
    }
}

private struct BlockUpdatePosition
{
    public int x, y, z;
    public Dimension dimension;
    public UpdateType updateType;
    public this(int x, int y, int z, Dimension dimension, UpdateType updateType)
    {
        this.x = x;
        this.y = y;
        this.z = z;
        this.dimension = dimension;
        this.updateType = updateType;
    }
    public hash_t opHash() const
    {
        return x + 9 * (y + 9 * (z + 9 * (cast(hash_t)dimension + 9 * cast(hash_t)updateType)));
    }
    public bool opEquals(ref const BlockUpdatePosition rt) const
    {
        return x == rt.x && y == rt.y && z == rt.z && dimension == rt.dimension && updateType == rt.updateType;
    }
}

private final class BlockUpdateEvent
{
    public double updateTime;
    public BlockUpdatePosition position;
    public Chunk chunk;
    public World world;
    public this(BlockUpdatePosition position, double updateTime, Chunk chunk, World world)
    {
        this.position = position;
        this.chunk = chunk;
        this.world = world;
        this.updateTime = updateTime;
    }
}

private struct MeshOctTree(uint minSize, uint size, uint xOrigin, uint yOrigin, uint zOrigin)
{
    static assert(size >= minSize);
    private Mesh mesh = null;
    private Mesh oldMesh = null;
    static if(size > minSize)
    {

        private static immutable uint subSize = size / 2;
        private MeshOctTree!(minSize, subSize, xOrigin, yOrigin, zOrigin) nnn;
        private MeshOctTree!(minSize, subSize, xOrigin, yOrigin, zOrigin + subSize) nnp;
        private MeshOctTree!(minSize, subSize, xOrigin, yOrigin + subSize, zOrigin) npn;
        private MeshOctTree!(minSize, subSize, xOrigin, yOrigin + subSize, zOrigin + subSize) npp;
        private MeshOctTree!(minSize, subSize, xOrigin + subSize, yOrigin, zOrigin) pnn;
        private MeshOctTree!(minSize, subSize, xOrigin + subSize, yOrigin, zOrigin + subSize) pnp;
        private MeshOctTree!(minSize, subSize, xOrigin + subSize, yOrigin + subSize, zOrigin) ppn;
        private MeshOctTree!(minSize, subSize, xOrigin + subSize, yOrigin + subSize, zOrigin + subSize) ppp;
    }

    public void invalidate(uint x, uint y, uint z) // relative to chunk origin
    {
        assert(x >= xOrigin && x < xOrigin + size);
        assert(y >= yOrigin && y < yOrigin + size);
        assert(z >= zOrigin && z < zOrigin + size);
        mesh = null;
        static if(size > minSize)
        {
            if(x < xOrigin + subSize)
            {
                if(y < yOrigin + subSize)
                {
                    if(z < zOrigin + subSize)
                    {
                        nnn.invalidate(x, y, z);
                    }
                    else
                    {
                        nnp.invalidate(x, y, z);
                    }
                }
                else
                {
                    if(z < zOrigin + subSize)
                    {
                        npn.invalidate(x, y, z);
                    }
                    else
                    {
                        npp.invalidate(x, y, z);
                    }
                }
            }
            else
            {
                if(y < yOrigin + subSize)
                {
                    if(z < zOrigin + subSize)
                    {
                        pnn.invalidate(x, y, z);
                    }
                    else
                    {
                        pnp.invalidate(x, y, z);
                    }
                }
                else
                {
                    if(z < zOrigin + subSize)
                    {
                        ppn.invalidate(x, y, z);
                    }
                    else
                    {
                        ppp.invalidate(x, y, z);
                    }
                }
            }
        }
    }

    public Mesh makeMesh(ref bool canCache, Mesh delegate(int x, int y, int z, ref bool canCache) makeMeshBottom)
    {
        canCache = true;
        if(mesh !is null)
        {
            return mesh;
        }
        static if(size > minSize)
        {
            bool canPartCache;
            if(oldMesh is null)
                oldMesh = new Mesh();
            else
                oldMesh.clear();
            mesh = oldMesh;
            mesh.add(nnn.makeMesh(canPartCache, makeMeshBottom));
            if(!canPartCache)
                canCache = false;
            mesh.add(nnp.makeMesh(canPartCache, makeMeshBottom));
            if(!canPartCache)
                canCache = false;
            mesh.add(npn.makeMesh(canPartCache, makeMeshBottom));
            if(!canPartCache)
                canCache = false;
            mesh.add(npp.makeMesh(canPartCache, makeMeshBottom));
            if(!canPartCache)
                canCache = false;
            mesh.add(pnn.makeMesh(canPartCache, makeMeshBottom));
            if(!canPartCache)
                canCache = false;
            mesh.add(pnp.makeMesh(canPartCache, makeMeshBottom));
            if(!canPartCache)
                canCache = false;
            mesh.add(ppn.makeMesh(canPartCache, makeMeshBottom));
            if(!canPartCache)
                canCache = false;
            mesh.add(ppp.makeMesh(canPartCache, makeMeshBottom));
            if(!canPartCache)
                canCache = false;
            Mesh retval = mesh;
            if(!canCache)
                mesh = null;
            return retval;
        }
        else
        {
            bool canPartCache;
            if(oldMesh is null)
                oldMesh = new Mesh();
            else
                oldMesh.clear();
            mesh = oldMesh;
            for(uint z = zOrigin; z < zOrigin + size; z++)
            {
                for(uint y = yOrigin; y < yOrigin + size; y++)
                {
                    for(uint x = xOrigin; x < xOrigin + size; x++)
                    {
                        mesh.add(makeMeshBottom(x, y, z, canPartCache));
                        if(!canPartCache)
                            canCache = false;
                    }
                }
            }
            Mesh retval = mesh;
            if(!canCache)
                mesh = null;
            return retval;
        }
    }
}

public struct IteratableEntityRange
{
    public @disable this();
    private EntityRange range;
    private World world;
    package this(EntityRange range, World world)
    {
        this.range = range;
        this.world = world;
    }
    public int opApply(int delegate(ref EntityData data) dg)
    {
        return world.forEachEntityInRange(dg, range);
    }
}

public struct EntityRange
{
    public float minx, miny, minz, maxx, maxy, maxz;
    public Dimension dimension;
    this(float minx, float miny, float minz, float maxx, float maxy, float maxz, Dimension dimension)
    {
        this.minx = minx;
        this.miny = miny;
        this.minz = minz;
        this.maxx = maxx;
        this.maxy = maxy;
        this.maxz = maxz;
        this.dimension = dimension;
    }

    public bool opBinaryRight(string op)(in EntityData e) if(op == "in")
    {
        if(e.dimension != dimension)
            return false;
        if(e.position.x < minx)
            return false;
        if(e.position.x > maxx)
            return false;
        if(e.position.y < miny)
            return false;
        if(e.position.y > maxy)
            return false;
        if(e.position.z < minz)
            return false;
        if(e.position.z > maxz)
            return false;
        return true;
    }

    public IteratableEntityRange iterate(World world)
    {
        return IteratableEntityRange(this, world);
    }

    public void addPoint(Vector point)
    {
        if(minx > point.x)
            minx = point.x;
        if(maxx < point.x)
            maxx = point.x;
        if(miny > point.y)
            miny = point.y;
        if(maxy < point.y)
            maxy = point.y;
        if(minz > point.z)
            minz = point.z;
        if(maxz < point.z)
            maxz = point.z;
    }
}

public struct IteratableBlockRange
{
    public @disable this();
    private BlockRange range;
    private World world;
    package this(BlockRange range, World world)
    {
        this.range = range;
        this.world = world;
    }
    public int opApply(int delegate(ref BlockPosition pos) dg)
    {
        return world.forEachBlockInRange(dg, range);
    }
}

public struct BlockRange
{
    public int minx, miny, minz, maxx, maxy, maxz;
    public Dimension dimension;
    this(int minx, int miny, int minz, int maxx, int maxy, int maxz, Dimension dimension)
    {
        this.minx = minx;
        this.miny = miny;
        this.minz = minz;
        this.maxx = maxx;
        this.maxy = maxy;
        this.maxz = maxz;
        this.dimension = dimension;
    }

    this(EntityRange r)
    {
        this(ifloor(r.minx), ifloor(r.miny), ifloor(r.minz), iceil(r.maxx), iceil(r.maxy), iceil(r.maxz), r.dimension);
    }

    public bool opBinaryRight(string op)(in Position p) if(op == "in")
    {
        if(p.dimension != dimension)
            return false;
        if(p.x < minx)
            return false;
        if(p.x > maxx)
            return false;
        if(p.y < miny)
            return false;
        if(p.y > maxy)
            return false;
        if(p.z < minz)
            return false;
        if(p.z > maxz)
            return false;
        return true;
    }

    public IteratableBlockRange iterate(World world)
    {
        return IteratableBlockRange(this, world);
    }
}

private alias EntityData * EntityNode;

private final class Chunk
{
    public static immutable int LOG2_XZ_SIZE = 4, LOG2_Y_SIZE = 8;
    static assert(LOG2_XZ_SIZE <= LOG2_Y_SIZE);
    public static immutable int XZ_SIZE = 1 << LOG2_XZ_SIZE;
    public static immutable int Y_SIZE = 1 << LOG2_Y_SIZE; // aka world height
    public static immutable int MOD_SIZE_MASK = XZ_SIZE - 1;
    public static immutable int FLOOR_SIZE_MASK = ~MOD_SIZE_MASK;
    public static immutable int Y_INDEX_FACTOR = XZ_SIZE;
    public static immutable int Z_INDEX_FACTOR = Y_SIZE * XZ_SIZE;

    public ChunkPosition position;
    public World world;
    public Chunk nx = null, px = null, nz = null, pz = null;
    public BlockData[XZ_SIZE * Y_SIZE * XZ_SIZE] blocks;
    private alias BlockUpdateEvent[UpdateType.max + 1] BlockUpdateSubArray;
    public BlockUpdateSubArray[XZ_SIZE * Y_SIZE * XZ_SIZE] blockUpdatesArray;
    public LinkedHashMap!(BlockUpdatePosition, BlockUpdateEvent) blockUpdatesMap;
    public alias MeshOctTree!(4, XZ_SIZE, 0, 0, 0)[Y_SIZE / XZ_SIZE] MeshCacheType;
    public MeshCacheType[RenderLayer.max + 1] meshCache;
    public Mesh[RenderLayer.max + 1] overallMesh = null;
    private static immutable int LOG2_ENTITY_BLOCK_SIZE = 2;
    static assert(LOG2_ENTITY_BLOCK_SIZE <= XZ_SIZE);
    private static immutable int ENTITY_BLOCK_SIZE = 1 << LOG2_ENTITY_BLOCK_SIZE;
    private LinkedHashMap!EntityNode[XZ_SIZE * Y_SIZE * XZ_SIZE / ENTITY_BLOCK_SIZE / ENTITY_BLOCK_SIZE / ENTITY_BLOCK_SIZE] entities;
    private LinkedHashMap!EntityNode otherEntities;
    private Mesh blockMeshCache = null;

    public LinkedHashMap!EntityNode getEntityList(int x, int y, int z)
    {
        if(y < 0 || y >= Y_SIZE)
            return otherEntities;
        return entities[((x - position.x) >> LOG2_ENTITY_BLOCK_SIZE) + (y >> LOG2_ENTITY_BLOCK_SIZE) * (XZ_SIZE >> LOG2_ENTITY_BLOCK_SIZE) + ((z - position.z) >> LOG2_ENTITY_BLOCK_SIZE) * (XZ_SIZE * Y_SIZE >> 2 * LOG2_ENTITY_BLOCK_SIZE)];
    }

    public LinkedHashMap!EntityNode getEntityList(Vector p)
    {
        return getEntityList(ifloor(p.x), ifloor(p.y), ifloor(p.z));
    }

    private int forEachEntityInRangeHelper(LinkedHashMap!EntityNode list, int delegate(ref EntityData data) dg, EntityRange range)
    {
        for(auto i = list.begin; !i.ended;)
        {
            if((*i.value) in range)
            {
                EntityNode node = i.value;
                Vector position = node.position;
                Dimension dimension = node.dimension;
                int retval;
                try
                {
                    retval = dg(*node);
                }
                finally
                {
                    if(node.position != position || node.dimension != dimension || !node.good)
                    {
                        if(ChunkPosition(node.position, node.dimension) != this.position || !node.good || getEntityList(node.position) !is list)
                        {
                            i.removeAndGoToNext();
                            world.insertEntityInChunk(node);
                        }
                        else
                            i++;
                    }
                    else
                        i++;
                }
                if(retval != 0)
                    return retval;
            }
            else
                i++;
        }
        return 0;
    }

    public int forEachEntityInRange(int delegate(ref EntityData data) dg, EntityRange range)
    {
        BlockRange bRange = BlockRange(range);
        if(bRange.miny < 0 || bRange.maxy >= Y_SIZE)
        {
            int retval = forEachEntityInRangeHelper(otherEntities, dg, range);
            if(retval != 0)
                return retval;
        }
        if(bRange.miny < 0)
            bRange.miny = 0;
        if(bRange.maxy > Y_SIZE - 1)
            bRange.maxy = Y_SIZE - 1;
        bRange.minx -= position.x;
        bRange.maxx -= position.x;
        bRange.minz -= position.z;
        bRange.maxz -= position.z;
        if(bRange.minx < 0)
            bRange.minx = 0;
        if(bRange.maxx > XZ_SIZE - 1)
            bRange.maxx = XZ_SIZE - 1;
        if(bRange.minz < 0)
            bRange.minz = 0;
        if(bRange.maxz > XZ_SIZE - 1)
            bRange.maxz = XZ_SIZE - 1;
        for(int z = bRange.minz >> LOG2_ENTITY_BLOCK_SIZE; z <= bRange.maxz >> LOG2_ENTITY_BLOCK_SIZE; z++)
        {
            for(int y = bRange.miny >> LOG2_ENTITY_BLOCK_SIZE; y <= bRange.maxy >> LOG2_ENTITY_BLOCK_SIZE; y++)
            {
                for(int x = bRange.minx >> LOG2_ENTITY_BLOCK_SIZE; x <= bRange.maxx >> LOG2_ENTITY_BLOCK_SIZE; x++)
                {
                    int retval = forEachEntityInRangeHelper(entities[x + y * (XZ_SIZE >> LOG2_ENTITY_BLOCK_SIZE) + z * (XZ_SIZE * Y_SIZE >> 2 * LOG2_ENTITY_BLOCK_SIZE)], dg, range);
                    if(retval != 0)
                        return retval;
                }
            }
        }
        return 0;
    }

    private int forEachEntityInCylinderHelper(LinkedHashMap!EntityNode list, int delegate(ref EntityData data) dg, Vector origin, Vector dir, float r) // dir must be normalized
    {
        for(auto i = list.begin; !i.ended;)
        {
            if(i.value.good && pointInRayCylinder(i.value.position, origin, dir, r))
            {
                EntityNode node = i.value;
                Vector position = node.position;
                Dimension dimension = node.dimension;
                int retval;
                try
                {
                    retval = dg(*node);
                }
                finally
                {
                    if(node.position != position || node.dimension != dimension || !node.good)
                    {
                        if(ChunkPosition(node.position, node.dimension) != this.position || !node.good || getEntityList(node.position) !is list)
                        {
                            i.removeAndGoToNext();
                            world.insertEntityInChunk(node);
                        }
                        else
                            i++;
                    }
                    else
                        i++;
                }
                if(retval != 0)
                    return retval;
            }
            else
                i++;
        }
        return 0;
    }

    public int forEachEntityInCylinder(int delegate(ref EntityData data) dg, Vector origin, Vector dir, float r) // dir must be normalized
    {
        int retval;
        retval = forEachEntityInCylinderHelper(otherEntities, dg, origin, dir, r);
        if(retval != 0)
            return retval;
        for(int x = 0; x < XZ_SIZE; x += ENTITY_BLOCK_SIZE)
        {
            for(int z = 0; z < XZ_SIZE; z += ENTITY_BLOCK_SIZE)
            {
                int startY = Y_SIZE;
                RayCollision collideFn(Vector pos, Dimension d, float t)
                {
                    startY = ifloor(pos.y - r);
                    return null;
                }
                collideWithAABB(Vector(position.x + x - r, -r, position.z + z - r), Vector(position.x + x + ENTITY_BLOCK_SIZE + r, Y_SIZE + r, position.z + z + ENTITY_BLOCK_SIZE + r), Ray(origin, position.dimension, dir), &collideFn);
                if(startY < 0)
                    startY = 0;
                startY &= ~(ENTITY_BLOCK_SIZE - 1);
                bool wasInCylinder = false;
                for(int y = startY; y < Y_SIZE; y += ENTITY_BLOCK_SIZE)
                {
                    if(rayIntersectsAABB(Vector(position.x + x - r, y - r, position.z + z - r), Vector(position.x + x + ENTITY_BLOCK_SIZE + r, y + ENTITY_BLOCK_SIZE + r, position.z + z + ENTITY_BLOCK_SIZE + r), origin, dir))
                    {
                        wasInCylinder = true;
                        retval = forEachEntityInCylinderHelper(getEntityList(x, y, z), dg, origin, dir, r);
                        if(retval != 0)
                            return retval;
                    }
                    else if(wasInCylinder)
                        break;
                }
            }
        }
        return 0;
    }

    public this(World world, ChunkPosition position)
    {
        this.world = world;
        this.position = position;
        blockUpdatesMap = new LinkedHashMap!(BlockUpdatePosition, BlockUpdateEvent)();
        foreach(ref BlockData b; blocks)
        {
            b = BlockData(null);
        }
        foreach(ref LinkedHashMap!EntityNode e; entities)
        {
            e = new LinkedHashMap!EntityNode();
        }
        otherEntities = new LinkedHashMap!EntityNode();
    }

    public void invalidate(int x, int y, int z)
    {
        for(int rl = 0; rl <= RenderLayer.max; rl++)
        {
            overallMesh[rl] = null;
            meshCache[rl][y / XZ_SIZE].invalidate(x & MOD_SIZE_MASK, y & MOD_SIZE_MASK, z & MOD_SIZE_MASK);
        }
    }

    public void addEntitiesToMesh(LinkedHashMap!EntityNode list, Mesh mesh, RenderLayer rl)
    {
        for(auto iter = list.begin; !iter.ended; iter++)
        {
            EntityNode data = iter.value;
            if(data.good)
            {
                mesh.add(data.getDrawMesh(rl));
            }
        }
    }

    private Mesh[RenderLayer.max + 1] oldEntitiesMesh;

    public Mesh makeEntitiesMesh(RenderLayer rl)
    {
        if(oldEntitiesMesh[rl] is null)
            oldEntitiesMesh[rl] = new Mesh();
        oldEntitiesMesh[rl].clear();
        Mesh retval = oldEntitiesMesh[rl];
        addEntitiesToMesh(otherEntities, retval, rl);
        foreach(LinkedHashMap!EntityNode list; entities)
        {
            addEntitiesToMesh(list, retval, rl);
        }
        return retval;
    }

    private Mesh[RenderLayer.max + 1] oldOverallMesh;

    public Mesh makeMesh(RenderLayer rl)
    {
        if(overallMesh[rl] !is null)
            return overallMesh[rl];
        if(oldOverallMesh[rl] is null)
            oldOverallMesh[rl] = new Mesh();
        oldOverallMesh[rl].clear();
        Mesh retval = oldOverallMesh[rl];
        overallMesh[rl] = retval;
        if(blockMeshCache is null)
            blockMeshCache = new Mesh();
        for(int yBlock = 0, i = 0; yBlock < Y_SIZE; yBlock += XZ_SIZE, i++)
        {
            Mesh makeMeshBlock(int x, int y, int z, ref bool canCache)
            {
                canCache = true;
                BlockPosition pos = BlockPosition(x + position.x, y + yBlock, z + position.z, this);
                BlockData b = pos.get();
                if(!b.good)
                {
                    return Mesh.EMPTY;
                }
                canCache = !b.graphicsChanges(pos);
                TransformedMesh drawMesh = b.getDrawMesh(pos, rl);
                if(drawMesh.mesh is null)
                    return Mesh.EMPTY;
                blockMeshCache.clear();
                Mesh retval = blockMeshCache;
                return retval.add(TransformedMesh(drawMesh, Matrix.translate(x + position.x, y + yBlock, z + position.z)));
            }
            bool canCache;
            retval.add(meshCache[rl][i].makeMesh(canCache, &makeMeshBlock));
            if(!canCache)
                overallMesh[rl] = null;
        }
        return retval;
    }
}

public final class World
{
    public static immutable int MAX_HEIGHT = Chunk.Y_SIZE;
    public static immutable ubyte MAX_LIGHTING = 15;
    public static @property Vector GRAVITY()
    {
        return Vector(0, -9.8, 0);
    }
    private LinkedHashMap!(ChunkPosition, Chunk) chunks;
    package LinkedHashMap!(BlockUpdatePosition, BlockUpdateEvent) blockUpdates;
    package LinkedList!BlockUpdateEvent blockUpdatesInZeroTime;
    private double currentTimeInternal = 0;
    package LinkedHashMap!EntityNode entities;

    private @property void currentTime(double t)
    {
        currentTimeInternal = t;
    }

    public @property double currentTime()
    {
        return currentTimeInternal;
    }

    public this()
    {
        chunks = new LinkedHashMap!(ChunkPosition, Chunk)();
        blockUpdates = new LinkedHashMap!(BlockUpdatePosition, BlockUpdateEvent)();
        blockUpdatesInZeroTime = new LinkedList!BlockUpdateEvent();
        entities = new LinkedHashMap!EntityNode();
    }

    private LinkedHashMap!EntityNode getEntityList(EntityNode node)
    {
        Chunk c = getOrAddChunk(ChunkPosition(node.position, node.dimension));
        return c.getEntityList(node.position);
    }

    package void insertEntityInChunk(EntityNode node)
    {
        if(!node.good)
        {
            entities.remove(node);
            return;
        }
        getEntityList(node).set(node, node);
    }

    public void addEntity(EntityData data)
    {
        if(!data.good)
            return;
        EntityNode node = new EntityData();
        *node = data;
        entities.set(node, node);
        insertEntityInChunk(node);
    }

    package Chunk getOrAddChunk(ChunkPosition chunkPos)
    {
        Chunk retval = this.chunks.get(chunkPos, null);
        if(retval !is null)
            return retval;
        retval = new Chunk(this, chunkPos);
        retval.nx = this.chunks.get(chunkPos.nx(), null);
        retval.nz = this.chunks.get(chunkPos.nz(), null);
        retval.px = this.chunks.get(chunkPos.px(), null);
        retval.pz = this.chunks.get(chunkPos.pz(), null);
        if(retval.nx !is null)
            retval.nx.px = retval;
        if(retval.px !is null)
            retval.px.nx = retval;
        if(retval.nz !is null)
            retval.nz.pz = retval;
        if(retval.pz !is null)
            retval.pz.nz = retval;
        this.chunks.set(chunkPos, retval);
        return retval;
    }

    public BlockData getBlockNotNull(in int x,
                                     in int y,
                                     in int z,
                                     in Dimension dimension)
    {
        if(y < 0)
            return BlockData(Bedrock.BEDROCK);
        if(y >= World.MAX_HEIGHT)
            return Air.LIT_AIR;
        int chunkX = x & Chunk.FLOOR_SIZE_MASK;
        int chunkZ = z & Chunk.FLOOR_SIZE_MASK;
        Chunk chunk = getOrAddChunk(ChunkPosition(chunkX, chunkZ, dimension));
        int chunkIndex = (x & Chunk.MOD_SIZE_MASK) + Chunk.Y_INDEX_FACTOR * y
                + Chunk.Z_INDEX_FACTOR * (z & Chunk.MOD_SIZE_MASK);
        BlockData retval = chunk.blocks[chunkIndex];
        if(!retval.good)
            return BlockData(Air.AIR);
        return retval;
    }

    public BlockData getBlock(in int x,
                              in int y,
                              in int z,
                              in Dimension dimension)
    {
        if(y < 0 || y >= World.MAX_HEIGHT)
            return BlockData(null);
        int chunkX = x & Chunk.FLOOR_SIZE_MASK;
        int chunkZ = z & Chunk.FLOOR_SIZE_MASK;
        Chunk chunk = getOrAddChunk(ChunkPosition(chunkX, chunkZ, dimension));
        int chunkIndex = (x & Chunk.MOD_SIZE_MASK) + Chunk.Y_INDEX_FACTOR * y
                + Chunk.Z_INDEX_FACTOR * (z & Chunk.MOD_SIZE_MASK);
        return chunk.blocks[chunkIndex];
    }

    public BlockPosition getBlockPosition(in int x,
                                          in int y,
                                          in int z,
                                          in Dimension dimension)
    {
        return BlockPosition(this, x, y, z, dimension);
    }

    public BlockPosition getBlockPosition(in Vector p,
                                          in Dimension dimension)
    {
        return BlockPosition(this, ifloor(p.x), ifloor(p.y), ifloor(p.z), dimension);
    }

    public BlockPosition getBlockPosition(in Position position)
    {
        return BlockPosition(this,
                                 position.x,
                                 position.y,
                                 position.z,
                                 position.dimension);
    }

    public BlockPosition getBlockPosition(in BlockUpdatePosition p)
    {
        return BlockPosition(this, p.x, p.y, p.z, p.dimension);
    }

    package void removeBlockUpdate(Chunk c, in BlockUpdatePosition p)
    {
        if(p.y < 0 || p.y >= World.MAX_HEIGHT)
            return;
        assert(c.position.x == (p.x & Chunk.FLOOR_SIZE_MASK)
                && c.position.z == (p.z & Chunk.FLOOR_SIZE_MASK)
                && c.position.dimension == p.dimension);
        int index = (p.x - c.position.x) + p.y * Chunk.Y_INDEX_FACTOR
                + (p.z - c.position.z) * Chunk.Z_INDEX_FACTOR;
        this.blockUpdates.remove(p);
        c.blockUpdatesMap.remove(p);
        int typeIndex = p.updateType;
        c.blockUpdatesArray[index][typeIndex] = null;
    }

    package void replaceBlockUpdateIfNewer(Chunk c, BlockUpdateEvent e)
    {
        BlockUpdatePosition p = e.position;
        if(p.y < 0 || p.y >= World.MAX_HEIGHT)
            return;
        int typeIndex = p.updateType;
        assert(c.position.x == (p.x & Chunk.FLOOR_SIZE_MASK)
                && c.position.z == (p.z & Chunk.FLOOR_SIZE_MASK)
                && c.position.dimension == p.dimension);
        int index = (p.x & Chunk.MOD_SIZE_MASK) + p.y * Chunk.Y_INDEX_FACTOR
                + (p.z & Chunk.MOD_SIZE_MASK) * Chunk.Z_INDEX_FACTOR;
        if(c.blockUpdatesArray[index][typeIndex] is null
                || c.blockUpdatesArray[index][typeIndex].updateTime > e.updateTime)
        {
            this.blockUpdates.remove(p);
            c.blockUpdatesMap.remove(p);
            c.blockUpdatesArray[index][typeIndex] = e;
            this.blockUpdates.set(p, e);
            c.blockUpdatesMap.set(p, e);
        }
    }

    private void invalidate(in int x, in int y, in int z, in Dimension dimension)
    {
        if(y < 0 || y >= World.MAX_HEIGHT)
            return;
        int chunkX = x & Chunk.FLOOR_SIZE_MASK;
        int chunkZ = z & Chunk.FLOOR_SIZE_MASK;
        Chunk chunk = getOrAddChunk(ChunkPosition(chunkX, chunkZ, dimension));
        chunk.invalidate(x, y, z);
    }

    private void invalidateGraphics(in int x, in int y, in int z, in Dimension dimension)
    {
        invalidate(x, y, z, dimension);
        invalidate(x + 1, y, z, dimension);
        invalidate(x - 1, y, z, dimension);
        invalidate(x, y + 1, z, dimension);
        invalidate(x, y - 1, z, dimension);
        invalidate(x, y, z + 1, dimension);
        invalidate(x, y, z - 1, dimension);
    }

    public void setBlock(in int x,
                         in int y,
                         in int z,
                         in Dimension dimension,
                         BlockData blockData)
    {
        if(y < 0 || y >= World.MAX_HEIGHT)
            return;
        invalidateGraphics(x, y, z, dimension);
        int chunkX = x & Chunk.FLOOR_SIZE_MASK;
        int chunkZ = z & Chunk.FLOOR_SIZE_MASK;
        Chunk chunk = getOrAddChunk(ChunkPosition(chunkX, chunkZ, dimension));
        int chunkIndex = (x & Chunk.MOD_SIZE_MASK) + Chunk.Y_INDEX_FACTOR * y
                + Chunk.Z_INDEX_FACTOR * (z & Chunk.MOD_SIZE_MASK);
        chunk.blocks[chunkIndex] = blockData;
        for(UpdateType type = cast(UpdateType)0; type <= UpdateType.max; type++)
            if(autoAddUpdate(type))
                replaceBlockUpdateIfNewer(chunk,
                                          new BlockUpdateEvent(BlockUpdatePosition(x,
                                                               y,
                                                               z,
                                                               dimension,
                                                               type),
                                                               this.currentTime,
                                                               chunk,
                                                               this));
    }

    public void setBlock(in Vector p,
                         in Dimension dimension,
                         BlockData blockData)
    {
        setBlock(ifloor(p.x),
                 ifloor(p.y),
                 ifloor(p.z),
                 dimension,
                 blockData);
    }

    public void setBlock(in Position position, BlockData blockData)
    {
        setBlock(position.x,
                 position.y,
                 position.z,
                 position.dimension,
                 blockData);
    }

    public void setBlock(in BlockUpdatePosition position,
                         BlockData blockData)
    {
        setBlock(position.x,
                 position.y,
                 position.z,
                 position.dimension,
                 blockData);
    }

    private void runUpdate(BlockUpdateEvent e)
    {
        // TODO(jacob#): add lighting
        BlockPosition position = BlockPosition(this,
                                                   e.position.x,
                                                   e.position.y,
                                                   e.position.z,
                                                   e.position.dimension);
        BlockData data = position.get();
        if(!data.good)
            return;
        // TODO(jacob#): finish
    }

    private bool moveUpdatesToZeroTimeList()
    {
        bool anyUpdates = false;
        for(auto iter = blockUpdates.begin; !iter.ended;)
        {
            BlockUpdateEvent e = iter.value;
            if(e.updateTime <= currentTime)
            {
                iter.removeAndGoToNext();
                Chunk c = e.chunk;
                c.blockUpdatesMap.remove(e.position);
                blockUpdatesInZeroTime.addBack(e);
                removeBlockUpdate(c, e.position);
                anyUpdates = true;
            }
            else
                iter++;
        }
        return anyUpdates;
    }

    private void runAllZeroTimeUpdates()
    {
        for(auto iter = blockUpdatesInZeroTime.begin; !iter.ended; iter.removeAndGoToNext())
        {
            runUpdate(*iter);
        }
    }

    private void checkUpdates()
    {
        bool anyUpdates;
        do
        {
            anyUpdates = moveUpdatesToZeroTimeList();
            runAllZeroTimeUpdates();
        }
        while(anyUpdates);
    }

    private void moveAllEntities(in double deltaTime)
    {
        for(auto iter = entities.begin; !iter.ended;)
        {
            EntityNode node = iter.value;
            LinkedHashMap!EntityNode startList = getEntityList(node);
            if(node.good)
                node.move(this, deltaTime);
            if(!node.good)
            {
                startList.remove(node);
                iter.removeAndGoToNext();
            }
            else
            {
                LinkedHashMap!EntityNode endList = getEntityList(node);
                if(endList !is startList)
                {
                    startList.remove(node);
                    endList.set(node, node);
                }
                iter++;
            }
        }
        for(auto iter = entities.begin; !iter.ended;)
        {
            EntityNode node = iter.value;
            LinkedHashMap!EntityNode startList = getEntityList(node);
            if(node.good)
                node.postMove(this);
            if(!node.good)
            {
                startList.remove(node);
                iter.removeAndGoToNext();
            }
            else
            {
                LinkedHashMap!EntityNode endList = getEntityList(node);
                if(endList !is startList)
                {
                    startList.remove(node);
                    endList.set(node, node);
                }
                iter++;
            }
        }
        for(auto iter = entities.begin; !iter.ended;)
        {
            EntityNode node = iter.value;
            if(!node.good)
            {
                LinkedHashMap!EntityNode startList = getEntityList(node);
                startList.remove(node);
                iter.removeAndGoToNext();
            }
            else
                iter++;
        }
    }

    public void advanceTime(in double amount)
    {
        currentTime = currentTime + amount;
        checkUpdates();
        moveAllEntities(amount);
        checkUpdates();
        //TODO (jacob#): finish
    }

    private void drawChunk(Chunk c, RenderLayer rl)
    {
        Renderer.render(lightMesh(c.makeMesh(rl)));
        Renderer.render(lightMesh(c.makeEntitiesMesh(rl)));
    }

    public uint viewDistance = 16;

    public void draw(Vector viewPoint, float theta, float phi, Dimension dimension)
    {
        glDepthMask(GL_TRUE);
        glClearColor(0.5, 0.5, 1, 1);
        glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
        glMatrixMode(GL_MODELVIEW);
        glLoadMatrix(Matrix.translate(-viewPoint).concat(Matrix.thetaPhi(theta, phi)));
        int viewX = ifloor(viewPoint.x);
        int viewZ = ifloor(viewPoint.z);
        int minCX = (viewX - viewDistance) & Chunk.FLOOR_SIZE_MASK, maxCX = (viewX + viewDistance) & Chunk.FLOOR_SIZE_MASK;
        int minCZ = (viewZ - viewDistance) & Chunk.FLOOR_SIZE_MASK, maxCZ = (viewZ + viewDistance) & Chunk.FLOOR_SIZE_MASK;
        for(int i = RenderLayer.min; i <= RenderLayer.max; i++)
        {
            RenderLayer rl = cast(RenderLayer)i;
            renderLayerSetup(rl);
            for(int cx = minCX; cx <= maxCX; cx += Chunk.XZ_SIZE)
            {
                for(int cz = minCZ; cz <= maxCZ; cz += Chunk.XZ_SIZE)
                {
                    Chunk c = getOrAddChunk(ChunkPosition(cx, cz, dimension));
                    drawChunk(c, rl);
                }
            }
        }
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        //TODO (jacob#): finish
    }

    package int forEachEntityInRange(int delegate(ref EntityData data) dg, EntityRange range)
    {
        int mincx = ifloor(range.minx) & Chunk.FLOOR_SIZE_MASK;
        int maxcx = ifloor(range.maxx) & Chunk.FLOOR_SIZE_MASK;
        int mincz = ifloor(range.minz) & Chunk.FLOOR_SIZE_MASK;
        int maxcz = ifloor(range.maxz) & Chunk.FLOOR_SIZE_MASK;
        for(int cx = mincx; cx <= maxcx; cx++)
        {
            for(int cz = mincz; cz <= maxcz; cz++)
            {
                int retval = getOrAddChunk(ChunkPosition(cx, cz, range.dimension)).forEachEntityInRange(dg, range);
                if(retval != 0)
                    return retval;
            }
        }
        return 0;
    }

    private Mesh lightMeshRetval = null;

    private Mesh lightMesh(Mesh mesh)
    {
        static immutable Vector light = normalize(Vector(1, 1.2, -0.7));
        if(lightMeshRetval is null)
            lightMeshRetval = new Mesh();
        Mesh retval = lightMeshRetval.clear();
        TextureDescriptor texture = TextureDescriptor(mesh.texture);
        foreach(Triangle tri; mesh)
        {
            Vector normal = tri.normal;
            float s = dot(normal, light);
            if(s < 0) s = 0;
            s = 0.4 + s * 0.6;
            tri.c[0] = scale(tri.c[0], s);
            tri.c[1] = scale(tri.c[1], s);
            tri.c[2] = scale(tri.c[2], s);
            retval.add(texture, tri);
        }
        //TODO(jacob#): finish
        return retval;
    }

    private static immutable int assumedMaxEntitySize = 4;
    static assert(assumedMaxEntitySize <= Chunk.XZ_SIZE);

    private RayCollision collideEntityHelper(LinkedHashMap!ChunkPosition collidedChunks, ChunkPosition pos, Ray ray, float maxT, RayCollisionArgs cArgs)
    {
        RayCollision ec = null;
        int collideFn(ref EntityData data)
        {
            ec = min(ec, data.collide(ray, cArgs));
            return 0;
        }
        for(int dx = -Chunk.XZ_SIZE; dx <= Chunk.XZ_SIZE; dx++)
        {
            for(int dz = -Chunk.XZ_SIZE; dz <= Chunk.XZ_SIZE; dz++)
            {
                ChunkPosition curPos = ChunkPosition(pos.x + dx, pos.z + dz, pos.dimension);
                if(!collidedChunks.containsKey(curPos))
                {
                    getOrAddChunk(curPos).forEachEntityInCylinder(&collideFn, ray.origin, ray.dir, assumedMaxEntitySize);
                    collidedChunks.set(curPos, curPos);
                }
            }
        }
        if(ec !is null && ec.distance > maxT)
            ec = null;
        return ec;
    }


    private RayCollision collideEntity(Ray ray, float maxT, RayCollisionArgs cArgs)
    {
        LinkedHashMap!ChunkPosition collidedChunks = new LinkedHashMap!ChunkPosition();
        ChunkPosition pos = ChunkPosition(ray.origin, ray.dimension);
        RayCollision ec = collideEntityHelper(collidedChunks, pos, ray, maxT, cArgs);
        if(ec !is null && ec.distance > maxT)
            ec = null;
        if(ec !is null)
            return ec;
        bool useX = (fabs(ray.dir.x) >= eps);
        bool useZ = (fabs(ray.dir.z) >= eps);
        if(!useX && !useZ)
            return ec;
        Vector invDir = Vector.ZERO;
        Vector next, step;
        Vector currentPos = ray.origin;
        int destX, destZ;
        int deltaX, deltaZ;
        if(useX)
        {
            invDir.x = 1 / ray.dir.x;
            step.x = fabs(invDir.x) * Chunk.XZ_SIZE;
            int target;
            if(ray.dir.x < 0)
            {
                target = (iceil(currentPos.x) + Chunk.XZ_SIZE - 1) & Chunk.FLOOR_SIZE_MASK - 1;
                deltaX = -Chunk.XZ_SIZE;
            }
            else
            {
                deltaX = Chunk.XZ_SIZE;
                target = ifloor(currentPos.x) & Chunk.FLOOR_SIZE_MASK + 1;
            }
            destX = target;
            if(ray.dir.x < 0)
                destX -= Chunk.XZ_SIZE;
            next.x = (target - ray.origin.x) * invDir.x;
        }
        if(useX)
        {
            invDir.z = 1 / ray.dir.z;
            step.z = fabs(invDir.z) * Chunk.XZ_SIZE;
            int target;
            if(ray.dir.z < 0)
            {
                target = (iceil(currentPos.z) + Chunk.XZ_SIZE - 1) & Chunk.FLOOR_SIZE_MASK - 1;
                deltaZ = -Chunk.XZ_SIZE;
            }
            else
            {
                deltaZ = Chunk.XZ_SIZE;
                target = ifloor(currentPos.z) & Chunk.FLOOR_SIZE_MASK + 1;
            }
            destZ = target;
            if(ray.dir.z < 0)
                destZ -= Chunk.XZ_SIZE;
            next.z = (target - ray.origin.z) * invDir.z;
        }
        while(true)
        {
            float t;
            if(useX && (!useZ || next.x < next.z))
            {
                t = next.x;
                next.x += step.x;
                pos.x = destX;
                destX += deltaX;
            }
            else // if(useZ) // useZ must be true
            {
                t = next.z;
                next.z += step.z;
                pos.z = destZ;
                destZ += deltaZ;
            }
            if(t > maxT)
                return null;
            ec = collideEntityHelper(collidedChunks, pos, ray, maxT, cArgs);
            if(ec !is null && ec.distance > maxT)
                ec = null;
            if(ec !is null)
                return ec;
        }
    }

    private RayCollision collideBlock(Ray ray, float maxT, RayCollisionArgs cArgs)
    {
        BlockPosition pos = getBlockPosition(ray.origin, ray.dimension);
        RayCollision bc = pos.get().collide(pos, ray, cArgs);
        if(bc !is null && bc.distance > maxT)
            bc = null;
        if(bc !is null)
            return bc;
        bool useX = (fabs(ray.dir.x) >= eps);
        bool useY = (fabs(ray.dir.y) >= eps);
        bool useZ = (fabs(ray.dir.z) >= eps);
        assert(useX || useY || useZ);
        Vector invDir = Vector.ZERO;
        Vector next, step;
        Vector currentPos = ray.origin;
        int destX, destY, destZ;
        int deltaX, deltaY, deltaZ;
        if(useX)
        {
            invDir.x = 1 / ray.dir.x;
            step.x = fabs(invDir.x);
            int target;
            if(ray.dir.x < 0)
            {
                target = iceil(currentPos.x) - 1;
                deltaX = -1;
            }
            else
            {
                deltaX = 1;
                target = ifloor(currentPos.x) + 1;
            }
            destX = target;
            if(ray.dir.x < 0)
                destX--;
            next.x = (target - ray.origin.x) * invDir.x;
        }
        if(useY)
        {
            invDir.y = 1 / ray.dir.y;
            step.y = fabs(invDir.y);
            int target;
            if(ray.dir.y < 0)
            {
                target = iceil(currentPos.y) - 1;
                deltaY = -1;
            }
            else
            {
                deltaY = 1;
                target = ifloor(currentPos.y) + 1;
            }
            destY = target;
            if(ray.dir.y < 0)
                destY--;
            next.y = (target - ray.origin.y) * invDir.y;
        }
        if(useZ)
        {
            invDir.z = 1 / ray.dir.z;
            step.z = fabs(invDir.z);
            int target;
            if(ray.dir.z < 0)
            {
                target = iceil(currentPos.z) - 1;
                deltaX = -1;
            }
            else
            {
                deltaX = 1;
                target = ifloor(currentPos.z) + 1;
            }
            destZ = target;
            if(ray.dir.z < 0)
                destZ--;
            next.z = (target - ray.origin.z) * invDir.z;
        }
        while(true)
        {
            float t;
            if(useX && (!useY || next.x < next.y) && (!useZ || next.x < next.z))
            {
                t = next.x;
                next.x += step.x;
                pos.moveTo(destX, pos.position.y, pos.position.z);
                destX += deltaX;
            }
            else if(useY && (!useZ || next.y < next.z))
            {
                t = next.y;
                next.y += step.y;
                pos.moveTo(pos.position.x, destY, pos.position.z);
                destY += deltaY;
            }
            else // if(useZ) // useZ must be true
            {
                t = next.z;
                next.z += step.z;
                pos.moveTo(pos.position.x, pos.position.y, destZ);
                destZ += deltaZ;
            }
            if(t > maxT)
                return null;
            bc = pos.get().collide(pos, ray, cArgs);
            if(bc !is null && bc.distance > maxT)
                bc = null;
            if(bc !is null)
                return bc;
        }
    }

    public RayCollision collide(Ray ray, float maxT, RayCollisionArgs cArgs)
    {
        RayCollision bc = collideBlock(ray, maxT, cArgs);
        if(bc is null)
            return collideEntity(ray, maxT, cArgs);
        RayCollision ec = collideEntity(ray, bc.distance, cArgs);
        return min(ec, bc);
    }

    package int forEachBlockInRange(int delegate(ref BlockPosition pos) dg, BlockRange range)
    {
        static if(false)
        {
            int minCX = range.minx & Chunk.FLOOR_SIZE_MASK;
            int minCZ = range.minx & Chunk.FLOOR_SIZE_MASK;
            int maxCX = (range.maxx + Chunk.XZ_SIZE) & Chunk.FLOOR_SIZE_MASK;
            int maxCZ = (range.maxz + Chunk.XZ_SIZE) & Chunk.FLOOR_SIZE_MASK;
            int miny = range.miny;
            if(miny < 0)
                miny = 0;
            int maxy = range.maxy + 1;
            if(maxy > Chunk.Y_SIZE)
                maxy = Chunk.Y_SIZE;
            for(int cx = minCX; cx < maxCX; cx += Chunk.XZ_SIZE)
            {
                for(int cz = minCZ; cz < maxCZ; cz += Chunk.XZ_SIZE)
                {
                    int minx = range.minx;
                    int maxx = range.maxx + 1;
                    int minz = range.minz;
                    int maxz = range.maxz + 1;
                    if(minx < cx)
                        minx = cx;
                    if(maxx > cx + Chunk.XZ_SIZE)
                        maxx = cx + Chunk.XZ_SIZE;
                    if(minz < cz)
                        minz = cz;
                    if(maxz > cz + Chunk.XZ_SIZE)
                        maxz = cz + Chunk.XZ_SIZE;
                    BlockPosition pos = getBlockPosition(cx, 0, cz, range.dimension);
                    for(int x = minx; x < maxx; x++)
                    {
                        for(int y = miny; y < maxy; y++)
                        {
                            for(int z = minz; z < maxz; z++)
                            {
                                BlockPosition curPos = pos;
                                curPos.moveTo(x, y, z);
                                int retval = dg(curPos);
                                if(retval != 0)
                                    return retval;
                            }
                        }
                    }
                }
            }
            return 0;
        }
        else
        {
            if(range.miny < 0)
                range.miny = 0;
            if(range.maxy > Chunk.Y_SIZE - 1)
                range.maxy = Chunk.Y_SIZE - 1;
            BlockPosition pos = getBlockPosition(range.minx, range.miny, range.minz, range.dimension);
            for(int x = range.minx; x <= range.maxx; x++)
            {
                pos.moveTo(x, range.miny, range.minz);
                BlockPosition pos2 = pos;
                for(int z = range.minz; z <= range.maxz; z++)
                {
                    for(int y = range.miny; y <= range.maxy; y++)
                    {
                        pos2.moveTo(x, y, z);
                        BlockPosition pos3 = pos2;
                        int retval = dg(pos3);
                        if(retval != 0)
                            return retval;
                    }
                }
            }
            return 0;
        }
    }

    public Collision collideWithCylinderBlocksOnly(Dimension dimension, Cylinder c, CollisionMask mask)
    {
        EntityRange eRange = EntityRange(c.origin.x - c.r, c.origin.y, c.origin.z - c.r, c.origin.x + c.r, c.origin.y + c.height, c.origin.z + c.r, dimension);
        BlockRange bRange = BlockRange(eRange);
        Collision retval = Collision();
        foreach(BlockPosition pos; bRange.iterate(this))
        {
            if(pos.get().good)
                retval = combine(retval, pos.get().collideWithCylinder(pos, c, mask));
        }
        return retval;
    }

    public Collision collideWithBoxBlocksOnly(Dimension dimension, Vector min, Vector max, CollisionMask mask)
    {
        EntityRange eRange = EntityRange(min.x, min.y, min.z, max.x, max.y, max.z, dimension);
        BlockRange bRange = BlockRange(eRange);
        Collision retval = Collision();
        foreach(BlockPosition pos; bRange.iterate(this))
        {
            if(pos.get().good)
                retval = combine(retval, pos.get().collideWithBox(pos, min, max, mask));
        }
        return retval;
    }

    public Collision collideWithCylinder(Dimension dimension, Cylinder c, CollisionMask mask)
    {
        EntityRange eRange = EntityRange(c.origin.x - c.r, c.origin.y, c.origin.z - c.r, c.origin.x + c.r, c.origin.y + c.height, c.origin.z + c.r, dimension);
        BlockRange bRange = BlockRange(eRange);
        eRange.minx -= assumedMaxEntitySize;
        eRange.miny -= assumedMaxEntitySize;
        eRange.minz -= assumedMaxEntitySize;
        eRange.maxx += assumedMaxEntitySize;
        eRange.maxy += assumedMaxEntitySize;
        eRange.maxz += assumedMaxEntitySize;
        Collision retval = Collision();
        foreach(ref EntityData entity; eRange.iterate(this))
        {
            if(mask.mask & entity.getCollideMask())
                retval = combine(retval, entity.collideWithCylinder(c, mask));
        }
        foreach(BlockPosition pos; bRange.iterate(this))
        {
            if(pos.get().good)
                retval = combine(retval, pos.get().collideWithCylinder(pos, c, mask));
        }
        return retval;
    }

    public Collision collideWithBox(Dimension dimension, Vector min, Vector max, CollisionMask mask)
    {
        EntityRange eRange = EntityRange(min.x, min.y, min.z, max.x, max.y, max.z, dimension);
        BlockRange bRange = BlockRange(eRange);
        eRange.minx -= assumedMaxEntitySize;
        eRange.miny -= assumedMaxEntitySize;
        eRange.minz -= assumedMaxEntitySize;
        eRange.maxx += assumedMaxEntitySize;
        eRange.maxy += assumedMaxEntitySize;
        eRange.maxz += assumedMaxEntitySize;
        Collision retval = Collision();
        foreach(ref EntityData entity; eRange.iterate(this))
        {
            if(mask.mask & entity.getCollideMask())
                retval = combine(retval, entity.collideWithBox(min, max, mask));
        }
        foreach(BlockPosition pos; bRange.iterate(this))
        {
            if(pos.get().good)
                retval = combine(retval, pos.get().collideWithBox(pos, min, max, mask));
        }
        return retval;
    }

    public static final class NoSpaceToPutException : Exception
    {
        this()
        {
            super("no space to put the box");
        }
    }

    private BoxList getCollisionBoxes(BlockRange r, CollisionMask mask)
    {
        static CollisionBox[] boxes;
        int boxesLength = 0;
        foreach(BlockPosition pos; r.iterate(this))
        {
            BlockData b = pos.get();
            if(b.getCollisionMask() & mask.mask)
            {
                BoxList newBoxes = b.getCollisionBoxes(pos);
                if(boxes.length < boxesLength + newBoxes.length)
                    boxes.length = boxesLength + newBoxes.length * 2;
                boxes[boxesLength .. boxesLength + newBoxes.length] = newBoxes[];
                boxesLength += newBoxes.length;
            }
        }
        return boxes[0 .. boxesLength];
    }

    public Vector findBestBoxPositionWithBlocksOnly(CollisionBox movableBox, CollisionMask mask, in float searchDistance = 0.5)
    {
        EntityRange er = EntityRange(movableBox.min.x - 1 - searchDistance, movableBox.min.y - 1 - searchDistance, movableBox.min.z - 1 - searchDistance, movableBox.max.x + 1 + searchDistance, movableBox.max.y + 1 + searchDistance, movableBox.max.z + 1 + searchDistance, movableBox.dimension);
        BlockRange r = BlockRange(er);
        BoxList boxes = getCollisionBoxes(r, mask);
        Vector retval = .findBestBoxPosition(movableBox, boxes);
        if(retval.x < -searchDistance || retval.x > searchDistance)
            throw new NoSpaceToPutException();
        if(retval.y < -searchDistance || retval.y > searchDistance)
            throw new NoSpaceToPutException();
        if(retval.z < -searchDistance || retval.z > searchDistance)
            throw new NoSpaceToPutException();
        return retval;
    }

    public bool collidesWithBoxBlocksOnly(CollisionBox box, CollisionMask mask)
    {
        EntityRange er = EntityRange(box.min.x - eps, box.min.y - eps, box.min.z - eps, box.max.x + eps, box.max.y + eps, box.max.z + eps, box.dimension);
        BlockRange r = BlockRange(er);
        BoxList boxes = getCollisionBoxes(r, mask);
        return collides(boxes, box);
    }
}
