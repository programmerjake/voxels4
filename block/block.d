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
import persistance.game_load_stream;
import persistance.game_store_stream;
import world.block_face;
import world.world;
import render.mesh;

public struct BlockData
{
    BlockDescriptor descriptor = null;
    uint data = 0;
    void * extraData = null;
    ubyte sunlight = 0, scatteredSunlight = 0, light = 0;
}

public abstract class BlockDescriptor
{
    public this()
    {
        addToBlockList(this);
    }

    public abstract TransformedMesh getDrawMesh(ref BlockData data);
    public abstract @property string name();
    protected abstract BlockData readInternal(GameLoadStream gls);
    public abstract bool graphicsChanged(ref BlockData data, BlockIterator pos);
    public abstract bool isSideBlocked(ref BlockData data, BlockFace face);
    public abstract bool isOpaque(ref BlockData data);
    protected uint getEmittedLight(ref BlockData data)
    {
        return 0;
    }

    public static final BlockData read(GameLoadStream gls)
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
}
