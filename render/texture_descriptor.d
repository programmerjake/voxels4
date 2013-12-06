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
module render.texture_descriptor;

public import image;
import util;

public struct TextureDescriptor
{
	public Image image = null;
	public float minU = 0.0, maxU = 1.0, minV = 0.0, maxV = 1.0;

	public this(Image image, float minU, float maxU, float minV, float maxV)
	{
		this.image = image;
        this.minU = minU;
        this.maxU = maxU;
        this.minV = minV;
        this.maxV = maxV;
	}

	public this(Image image)
	{
	    this.image = image;
	    minU = 0;
	    maxU = 1;
	    minV = 0;
	    maxV = 1;
	}

	public bool opCast(T : bool)() const
	{
		return this.image !is null;
	}

	public TextureDescriptor subTexture(const float minU, const float maxU, const float minV, const float maxV)
	{
		return TextureDescriptor(image, interpolate(minU, this.minU, this.maxU), interpolate(maxU, this.minU, this.maxU), interpolate(minV, this.minV, this.maxV), interpolate(maxV, this.minV, this.maxV));
	}
}
