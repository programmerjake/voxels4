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
module render.mesh;
import matrix;

public struct Triangle
{
	Vector[3] p;
	Color[3] c;
	float[3] u, v;
}

public struct TransformedMesh
{
	public Mesh mesh = null;
	public Matrix transform = Matrix.IDENTITY;
	public this(Mesh mesh, Matrix transform = IDENTITY)
	{
		this.mesh = mesh;
		this.transform = transform;
	}

	public this(TransformedMesh mesh, Matrix transform)
	{
		this.mesh = mesh.mesh;
		this.transform = mesh.transform ~ transform;
	}
}

public final class Mesh
{
	public static final class ImageNotSameException : Exception
	{
		this()
		{
			super("can't use more than one image per mesh");
		}
	}
	public static final class SealedException : Exception
	{
		this()
		{
			super("can't modify a sealed Mesh");
		}
	}
	private Image textureInternal = null;
	public @property Image texture()
	{
		return textureInternal;
	}
	private bool sealed = false;
    private float[] vertices = null, textureCoords = null, colors = null;
    private int trianglesUsed = 0, trianglesAllocated = 0;
    public static immutable int VERTICES_ELEMENTS_PER_TRIANGLE = 3 * 3;
    public static immutable int TEXTURE_COORDS_ELEMENTS_PER_TRIANGLE = 2 * 3;
    public static immutable int COLORS_ELEMENTS_PER_TRIANGLE = 4 * 3;
    private void expandArrays(int newSize)
    {
		if(vertices is null)
		{
			vertices = new float[VERTICES_ELEMENTS_PER_TRIANGLE * newSize];
			textureCoords = new float[TEXTURE_COORDS_ELEMENTS_PER_TRIANGLE * newSize];
			colors = new float[COLORS_ELEMENTS_PER_TRIANGLE * newSize];
			return;
		}
		vertices.length = VERTICES_ELEMENTS_PER_TRIANGLE * newSize;
		textureCoords.length = TEXTURE_COORDS_ELEMENTS_PER_TRIANGLE * newSize;
		colors.length = COLORS_ELEMENTS_PER_TRIANGLE * newSize;
	}

	private int getExpandedAmount(int increment)
	{
		return trianglesAllocated + increment + 16 + trianglesAllocated / 8 + increment / 2;
	}

	private void checkForSpace(int increment)
	{
		if(trianglesUsed + increment <= trianglesAllocated)
			return;
		expandArrays(getExpandedAmount(increment));
	}

	private static float[] dupFloatArray(float[] a)
	{
		if(a is null)
			return null;
		return a.dup;
	}

	public this()
	{
	}

	public this(TransformedMesh rt)
	{
		sealed = false;
		textureInternal = null;
		if(rt.mesh !is null)
		{
			textureInternal = rt.mesh.textureInternal;
			vertices = dupFloatArray(rt.mesh.vertices);
			textureCoords = dupFloatArray(rt.mesh.textureCoords);
			colors = dupFloatArray(rt.mesh.colors);
		}
	}

	public this(Mesh rt)
	{
		sealed = false;
		textureInternal = rt.textureInternal;
		vertices = dupFloatArray(rt.vertices);
		textureCoords = dupFloatArray(rt.textureCoords);
		colors = dupFloatArray(rt.colors);
	}

	public Mesh add(TransformedMesh mesh)
	{

	}
}
