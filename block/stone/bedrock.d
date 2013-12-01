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
module block.stone.bedrock;
import block.block;
import block.stone.stone;
import resource.texture_atlas;
import persistance.game_load_stream;
import render.texture_descriptor;
import world.block_face;

public final class Bedrock : StoneType
{
    private this()
    {
        super("Bedrock");
    }

    private static Bedrock BEDROCK_;

    static this()
    {
        BEDROCK_ = new Bedrock();
    }

    public static @property BEDROCK()
    {
        return BEDROCK_;
    }

    protected override BlockData readInternal(GameLoadStream gls)
    {
        return BlockData(BEDROCK);
    }

    protected override TextureDescriptor getFaceTexture(BlockFace f)
    {
        return TextureAtlas.Bedrock.td;
    }

}
