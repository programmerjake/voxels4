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

public enum Dimension
{
    Overworld,
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
    private World worldInternal;
    public @property World world()
    {
        return worldInternal;
    }
    private int x, y, z, chunkIndex;
    private immutable Dimension dimension;
    private Chunk chunk;

    public @disable this();

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

    public void move(in int dx, in int dy, in int dz)
    {
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

    public void move(in BlockFace bf)
    {
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
        if(this.y < 0 || this.y >= World.MAX_HEIGHT)
            return BlockData();
        return this.chunk.blocks[this.chunkIndex];
    }

    public void updateAbsolute(in UpdateType type, in double theTime)
    {
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
        updateAbsolute(type, deltaTime + this.world.currentTime);
    }

    public void set(BlockData blockData)
    {
        if(this.y < 0 || this.y >= World.MAX_HEIGHT)
            return;
        this.world.setBlock(this.x, this.y, this.z, this.dimension, blockData);
    }

    public Position getPosition()
    {
        return Position(this.x, this.y, this.z, this.dimension);
    }

    package void clearUpdate(in BlockUpdatePosition pos)
    {
        this.world.removeBlockUpdate(this.chunk, pos);
    }

    public void clearUpdate(in UpdateType type)
    {
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
    General, // must not assign to any names after Lighting so we can use UpdateType.max as (length - 1)
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
            mesh = new Mesh();
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
            mesh.seal();
            Mesh retval = mesh;
            if(!canCache)
                mesh = null;
            return retval;
        }
        else
        {
            bool canPartCache;
            mesh = new Mesh();
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
            mesh.seal();
            Mesh retval = mesh;
            if(!canCache)
                mesh = null;
            return retval;
        }
    }

    public Mesh makeMesh(Mesh delegate(int x, int y, int z, ref bool canCache) makeMeshBottom)
    {
        bool canCache;
        return makeMesh(canCache, makeMeshBottom);
    }
}

private final class Chunk
{
    public static immutable int LOG2_XZ_SIZE = 4, LOG2_Y_SIZE = 8;
    static assert(LOG2_XZ_SIZE <= LOG2_Y_SIZE);
    public static immutable int XZ_SIZE = 1 << LOG2_XZ_SIZE;
    public static immutable int Y_SIZE = 1 << LOG2_Y_SIZE; // aka world height
    public static immutable int MOD_SIZE_MASK = XZ_SIZE - 1;
    public static immutable int FLOOR_SIZE_MASK = ~MOD_SIZE_MASK;
    public static immutable int Y_INDEX_FACTOR = Y_SIZE;
    public static immutable int Z_INDEX_FACTOR = Y_SIZE * XZ_SIZE;

    public ChunkPosition position;
    public World world;
    public Chunk nx = null, px = null, nz = null, pz = null;
    public BlockData[XZ_SIZE * Y_SIZE * XZ_SIZE] blocks;
    public BlockUpdateEvent[XZ_SIZE * Y_SIZE * XZ_SIZE][UpdateType.max + 1] blockUpdatesArray;
    public LinkedHashMap!(BlockUpdatePosition, BlockUpdateEvent) blockUpdatesMap;
    public MeshOctTree!(2, XZ_SIZE, 0, 0, 0)[Y_SIZE / XZ_SIZE] meshCache;

    public this(World world, ChunkPosition position)
    {
        this.world = world;
        this.position = position;
        blockUpdatesMap = new LinkedHashMap!(BlockUpdatePosition, BlockUpdateEvent)();
        foreach(int i, ref BlockData b; blocks)
        {
            b = BlockData(Air.AIR);
        }
    }

    public void invalidate(int x, int y, int z)
    {
        meshCache.invalidate(x & MOD_SIZE_MASK, y, z & MOD_SIZE_MASK);
    }
}

public final class World
{
    public static immutable int MAX_HEIGHT = Chunk.Y_SIZE;
    public static immutable ubyte MAX_LIGHTING = 15;
    private LinkedHashMap!(ChunkPosition, Chunk) chunks;
    package LinkedHashMap!(BlockUpdatePosition, BlockUpdateEvent) blockUpdates;
    package LinkedList!BlockUpdateEvent blockUpdatesInZeroTime;
    private double currentTimeInternal = 0;

    private @property void currentTime(double t)
    {
        currentTimeInternal = t;
    }

    public @property double currentTime()
    {
        return currentTimeInternal;
    }
    //FIXME (jacob#): finish
    public this()
    {
        chunks = new LinkedHashMap!(ChunkPosition, Chunk)();
        blockUpdates = new LinkedHashMap!(BlockUpdatePosition, BlockUpdateEvent)();
        blockUpdatesInZeroTime = new LinkedList!BlockUpdateEvent();
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
        int index = (p.x - c.position.x) + p.y * Chunk.Y_INDEX_FACTOR
                + (p.z - c.position.z) * Chunk.Z_INDEX_FACTOR;
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

    public void setBlock(in int x,
                         in int y,
                         in int z,
                         in Dimension dimension,
                         BlockData blockData)
    {
        if(y < 0 || y >= World.MAX_HEIGHT)
            return;
        int chunkX = x & Chunk.FLOOR_SIZE_MASK;
        int chunkZ = z & Chunk.FLOOR_SIZE_MASK;
        Chunk chunk = getOrAddChunk(ChunkPosition(chunkX, chunkZ, dimension));
        int chunkIndex = (x & Chunk.MOD_SIZE_MASK) + Chunk.Y_INDEX_FACTOR * y
                + Chunk.Z_INDEX_FACTOR * (z & Chunk.MOD_SIZE_MASK);
        chunk.blocks[chunkIndex] = blockData;
        chunk.invalidate(x, y, z);
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
        }
        while(anyUpdates);
    }

    public void advanceTime(in double amount)
    {
        currentTime = currentTime + amount;
        checkUpdates();
        //TODO (jacob#): finish
    }

    private void drawChunk(Chunk c)
    {

    }

    public uint viewDistance = 16;

    public void draw(Matrix viewMatrix)
    {
        //TODO (jacob#): finish
        assert(false, "finish");
    }
}