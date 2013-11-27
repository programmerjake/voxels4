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
module render.generate;
import render.mesh;
import render.texture_descriptor;
import color;
import vector;
import matrix;
import image;
	
public Mesh invert(Mesh input)
{
	if(input.length <= 0)
		return new Mesh(input);
	Triangle[] triangles = new Triangle[input.length];
	foreach(int i, Triangle t; input)
	{
		for(int j = 0, k = 3 - 1; j < 3; j++, k--)
		{				
			triangles[i].p[j] = t.p[k];
			triangles[i].c[j] = t.c[k];
			triangles[i].u[j] = t.u[k];
			triangles[i].v[j] = t.v[k];
		}
	}
	return new Mesh(input.texture, triangles);
}
	
public TransformedMesh invert(TransformedMesh input)
{
	if(input.mesh is null)
	{
		return input;
	}
	
	return TransformedMesh(invert(input.mesh), input.transform);
}

public struct Generate
{
	public @disable this();
	
	public static Mesh parallelogram(TextureDescriptor texture, Vector p1, Color c1, Vector p2, Color c2, Vector p3, Color c3, Color c4)
	{
		Vector p4 = p2 - p1 + p3;
		immutable float u1 = texture.minU, v1 = texture.minV;
		immutable float u2 = texture.maxU, v2 = texture.minV;
		immutable float u3 = texture.maxU, v3 = texture.maxV;
		immutable float u4 = texture.minU, v4 = texture.maxV;
		Triangle[2] triangles = {Triangle(p1, c1, u1, v1, p2, c2, u2, v2, p3, c3, u3, v3), Triangle(p3, c3, u3, v3, p4, c4, u4, v4, p1, c1, u1, v1)};
		return new Mesh(texture.image, triangles);
	}
	
	/// make a box from <0, 0, 0> to <1, 1, 1>
	public static Mesh unitBox(TextureDescriptor nx, TextureDescriptor px, TextureDescriptor ny, TextureDescriptor py, TextureDescriptor nz, TextureDescriptor pz)
	{
		assert(0, "finish making unitBox"); // TODO: finish making unitBox
	}
}
