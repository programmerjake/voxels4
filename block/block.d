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
    protected abstract BlockData readInternal(GameLoadStream gls);
    public abstract bool graphicsChanges(BlockPosition pos);
    public abstract bool isSideBlocked(BlockData data, BlockFace face);
    public abstract bool isOpaque(BlockData data);
    protected uint getEmittedLight(BlockData data)
    {
        return 0;
    }
    protected abstract void writeInternal(BlockData data, GameStoreStream gss);

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
            return bd.descriptor.isSideBlocked(bd, f);
        return true;
    }
}
