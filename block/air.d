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
module block.air;
import block.block;
import world.world;
import render.mesh;
import persistance.game_load_stream;
import world.block_face;

public final class Air : BlockDescriptor
{
    private static Air AIR_ = null;
    public static @property Air AIR()
    {
        if(AIR_ is null)
            AIR_ = new Air();
        return AIR_;
    }

    public static @property BlockData LIT_AIR()
    {
        BlockData retval = BlockData(AIR);
        retval.sunlight = World.MAX_LIGHTING;
        retval.scatteredSunlight = World.MAX_LIGHTING;
        return retval;
    }

    private this()
    {
        super("Builtin.Air");
    }

    public override TransformedMesh getDrawMesh(BlockPosition pos, RenderLayer rl)
    {
        return TransformedMesh();
    }

    public override TransformedMesh getEntityDrawMesh(BlockData data, RenderLayer rl)
    {
        return TransformedMesh();
    }

    protected override BlockData readInternal(GameLoadStream gls)
    {
        return BlockData(AIR);
    }

    public override bool graphicsChanges(BlockPosition pos)
    {
        return false;
    }

    public override bool isSideBlocked(BlockData data, BlockFace face)
    {
        return false;
    }

    public override bool isOpaque(BlockData data)
    {
        return false;
    }

    protected override void writeInternal(BlockData data, GameStoreStream gss)
    {
    }

    public override Collision collideWithCylinder(BlockPosition pos, Cylinder c)
    {
        return Collision();
    }

    public override Collision collideWithBox(BlockPosition pos, Matrix boxTransform)
    {
        return Collision();
    }

    public override RayCollision collide(BlockData pos, Ray ray, RayCollisionArgs cArgs)
    {
        return null;
    }
}
