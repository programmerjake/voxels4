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
module block.stone.stone;
public import block.block;
import render.generate;
import resource.texture_atlas;

public abstract class StoneType : BlockDescriptor
{
    public this(string name)
    {
        super(name);
        for(int nx = 0; nx < 2; nx++)
            for(int px = 0; px < 2; px++)
                for(int ny = 0; ny < 2; ny++)
                    for(int py = 0; py < 2; py++)
                        for(int nz = 0; nz < 2; nz++)
                            for(int pz = 0; pz < 2; pz++)
                                theMesh[nx][px][ny][py][nz][pz] = makeMesh(nx != 0, px != 0, ny != 0, py != 0, nz != 0, pz != 0);
    }

    protected abstract TextureDescriptor getFaceTexture(BlockFace f);

    protected Mesh makeMesh(bool nx, bool px, bool ny, bool py, bool nz, bool pz)
    {
        TextureDescriptor nxTexture;
        if(nx)
            nxTexture = getFaceTexture(BlockFace.NX);
        TextureDescriptor nyTexture;
        if(ny)
            nyTexture = getFaceTexture(BlockFace.NY);
        TextureDescriptor nzTexture;
        if(nz)
            nzTexture = getFaceTexture(BlockFace.NZ);
        TextureDescriptor pxTexture;
        if(px)
            pxTexture = getFaceTexture(BlockFace.PX);
        TextureDescriptor pyTexture;
        if(py)
            pyTexture = getFaceTexture(BlockFace.PY);
        TextureDescriptor pzTexture;
        if(pz)
            pzTexture = getFaceTexture(BlockFace.PZ);
        return Generate.unitBox(nxTexture, pxTexture, nyTexture, pyTexture, nzTexture, pzTexture).seal();
    }

    private Mesh[2][2][2][2][2][2] theMesh;

    public override TransformedMesh getDrawMesh(BlockPosition pos, RenderLayer rl)
    {
        if(rl != RenderLayer.Opaque)
            return TransformedMesh();
        bool nx = !BlockDescriptor.isSideBlocked(pos, BlockFace.NX);
        bool px = !BlockDescriptor.isSideBlocked(pos, BlockFace.PX);
        bool ny = !BlockDescriptor.isSideBlocked(pos, BlockFace.NY);
        bool py = !BlockDescriptor.isSideBlocked(pos, BlockFace.PY);
        bool nz = !BlockDescriptor.isSideBlocked(pos, BlockFace.NZ);
        bool pz = !BlockDescriptor.isSideBlocked(pos, BlockFace.PZ);
        return TransformedMesh(theMesh[nx][px][ny][py][nz][pz]);
    }

    public override TransformedMesh getEntityDrawMesh(BlockData data, RenderLayer rl)
    {
        if(rl != RenderLayer.Opaque)
            return TransformedMesh();
        return TransformedMesh(theMesh[1][1][1][1][1][1], Matrix.translate(-0.5, 0, -0.5).concat(Matrix.scale(0.25)));
    }

    public override bool graphicsChanges(BlockPosition pos)
    {
        return false;
    }

    public override bool isSideBlocked(BlockData data, BlockFace face)
    {
        return true;
    }

    public override bool isOpaque(BlockData data)
    {
        return true;
    }
}

public final class Stone : StoneType
{
    private this()
    {
        super("Default.Stone");
    }

    private static Stone STONE_ = null;

    public static @property STONE()
    {
        if(STONE_ is null)
            STONE_ = new Stone();
        return STONE_;
    }

    protected override BlockData readInternal(GameLoadStream gls)
    {
        return BlockData(STONE);
    }

    protected override TextureDescriptor getFaceTexture(BlockFace f)
    {
        return TextureAtlas.Stone.td;
    }

    protected override void writeInternal(BlockData data, GameStoreStream gss)
    {
    }
}

