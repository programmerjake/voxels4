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
}

public final class BlockIterator
{
    private World worldInternal;
    public @property World world()
    {
        return worldInternal;
    }
    private int x, y, z, chunkIndex;
    //TODO: finish
    //private
    package this()
    {
        assert(0);//TODO: finish
    }
}

public enum UpdateType
{
    Lighting = 0,
    General, // must not assign to any names after Lighting so we can use UpdateType.max as (length - 1)
}

public @property bool autoAdd(UpdateType ut)
{
    final switch(ut)
    {
    case UpdateType.Lighting:
        return true;
    case UpdateType.General:
        return false;
    }
}

private immutable hash_t hashPrimeBig = 8191;

private final class BlockUpdateEvent
{
    public double updateTime = 0;
    public int x, y, z;
    public Dimension dimension;
    public UpdateType updateType;
    public Chunk chunk;
    public World world;
    public BlockUpdateEvent chunkNext;
    public BlockUpdateEvent worldNext;
    public BlockUpdateEvent chunkHashNext;
    public BlockUpdateEvent worldHashNext;
    public hash_t opHash() const
    {
        return x + 9 * (y + 9 * (z + 9 * (cast(hash_t)dimension + 9 * cast(hash_t)updateType)));
    }
    public this()
    {
    }
}

private final class Chunk
{
    public static immutable int XZ_SIZE = 0x10; // must be power of 2
    public static immutable int Y_SIZE = 256; // aka world height
    public static immutable int MOD_SIZE_MASK = XZ_SIZE - 1;
    public static immutable int FLOOR_SIZE_MASK = ~MOD_SIZE_MASK;
    public static immutable int Y_INDEX_FACTOR = Y_SIZE;
    public static immutable int Z_INDEX_FACTOR = Y_SIZE * XZ_SIZE;

    public ChunkPosition position;
    public World world;
    public Chunk nx = null, px = null, nz = null, pz = null;
    public BlockData[XZ_SIZE * Y_SIZE * XZ_SIZE] blocks;
    public BlockUpdateEvent[XZ_SIZE * Y_SIZE * XZ_SIZE][UpdateType.max + 1] blockUpdates;
    public BlockUpdateEvent updateListHead = null, updateListTail = null;

    public this(World world, ChunkPosition position)
    {
        this.world = world;
        this.position = position;
        foreach(ref BlockData; blocks)
        {
            //TODO: set to air
        }
    }
}

public final class World
{
    public static immutable int MAX_HEIGHT = Chunk.Y_SIZE;
    public static immutable ubyte MAX_LIGHTING = 15;
    //private
    public this()
    {

    }
}
