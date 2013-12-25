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
module render.overlay;
public import render.mesh;
public import matrix;
public import block.block;
import render.text;
import platform;
import std.string;

public struct Overlay
{
    public @disable this();
    public static Matrix transformFromScreenSpace(int screenWidth, int screenHeight, float screenDepth = 1.0f)
    {
        assert(screenWidth > 0 && screenHeight > 0);
        Matrix retval = Matrix.IDENTITY;
        float xSize = 1, ySize = 1;
        if(screenWidth > screenHeight)
            xSize = cast(float)screenWidth / screenHeight;
        else
            ySize = cast(float)screenHeight / screenWidth;
        if(xSize > Display.scaleX)
        {
            ySize *= Display.scaleX / xSize;
            xSize = Display.scaleX;
        }
        else if(ySize > Display.scaleY)
        {
            xSize *= Display.scaleY / ySize;
            ySize = Display.scaleY;
        }
        float scale = xSize * screenDepth / screenWidth;
        return Matrix.scale(scale * 2).concat(Matrix.translate(-scale, -scale, -screenDepth));
    }
    public static void drawBlockStack(Mesh dest, Matrix transform, BlockStack bs, int x, int y, float zDistance)
    {
        if(bs.count <= 0)
            return;
        transform = transform.concat(Matrix.scale(zDistance));
        if(bs.count > 1)
        {
            string str = format("%2s", bs.count);
            float width = Text.width(str);
            Text.render(dest, Matrix.scale(16 / width).concat(Matrix.translate(x, y, 0)).concat(transform), Color.WHITE, str);
        }
        dest.add(TransformedMesh(bs.block.getItemDrawMesh(), Matrix.scale(16).concat(transform)));
    }
}
