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
module block.anim_test;
import block.block;
import render.text;
import platform;
import std.math;
import render.generate;

public final class BlockAnimTest : BlockDescriptor
{
    private static BlockAnimTest BLOCK_ANIM_TEST_;
    static this()
    {
        BLOCK_ANIM_TEST_ = new BlockAnimTest();
    }
    public static @property BLOCK_ANIM_TEST()
    {
        return BLOCK_ANIM_TEST_;
    }

    private this()
    {
        super("Debug.Builtin.AnimTest");
    }

    private static Mesh theMesh;
    static this()
    {
        theMesh = new Mesh();
        string theText = "AnimTest";
        int width = Text.width(theText), height = Text.height(theText);
        Text.render(theMesh, Matrix.translate(-0.5 * width, -0.5 * height, 0).concat(Matrix.scale(1.0 / width)), Color.GREEN, theText);
        Mesh temp = new Mesh();
        theMesh.add(invert(temp, theMesh));
        theMesh.seal();
    }

    public override TransformedMesh getDrawMesh(BlockPosition pos, RenderLayer rl)
    {
        if(rl != RenderLayer.Opaque)
            return TransformedMesh();
        return TransformedMesh(theMesh, Matrix.rotateY(PI * Display.timer).concat(Matrix.translate(0.5, 0.5, 0.5)));
    }

    public override TransformedMesh getEntityDrawMesh(BlockData data, RenderLayer rl)
    {
        if(rl != RenderLayer.Opaque)
            return TransformedMesh();
        return TransformedMesh(theMesh, Matrix.translate(0.5, 0.5, 0.5));
    }

    public override TransformedMesh getItemDrawMesh(BlockData data)
    {
        return TransformedMesh(theMesh, Matrix.translate(0.5, 0.5, 0));
    }

    protected override BlockData readInternal(GameLoadStream gls)
    {
        return BlockData(BLOCK_ANIM_TEST);
    }

    public override bool graphicsChanges(BlockPosition pos)
    {
        return true;
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

    public override Collision collideWithCylinder(BlockPosition pos, Cylinder c, CollisionMask mask)
    {
        return Collision();
    }

    public override Collision collideWithBox(BlockPosition pos, Vector min, Vector max, CollisionMask mask)
    {
        return Collision();
    }

    public override RayCollision collide(BlockData pos, Ray ray, RayCollisionArgs cArgs)
    {
        return RayCollision();
    }

    public override BoxList getCollisionBoxes(BlockPosition pos)
    {
        return [];
    }

    public override CollisionBox getBoundingBox(BlockPosition pos)
    {
        return CollisionBox(Vector(pos.position.x, pos.position.y, pos.position.z), Vector(pos.position.x + 1, pos.position.y + 1, pos.position.z + 1), pos.position.dimension);
    }

    public override ulong getCollisionMask()
    {
        return CollisionMask.COLLIDE_NONE;
    }
}
