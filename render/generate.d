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
public import render.mesh;

public Mesh invert(Mesh dest, Mesh input)
{
    dest.clear();
	if(input.length <= 0)
		return dest;
    Triangle tri;
	foreach(int i, Triangle t; input)
	{
		for(int j = 0, k = 3 - 1; j < 3; j++, k--)
		{
			tri.p[j] = t.p[k];
			tri.c[j] = t.c[k];
			tri.u[j] = t.u[k];
			tri.v[j] = t.v[k];
		}
        TextureDescriptor td = TextureDescriptor(input.texture);
        dest.add(td, tri);
	}
	return dest;
}

public TransformedMesh invert(Mesh dest, TransformedMesh input)
{
	if(input.mesh is null)
	{
		return input;
	}

	return TransformedMesh(invert(dest, input.mesh), input.transform);
}

public struct Generate
{
	public @disable this();

	public static Mesh quadrilateral(TextureDescriptor texture, Vector p1, Color c1, Vector p2, Color c2, Vector p3, Color c3, Vector p4, Color c4)
	{
		if(!texture)
			return new Mesh();
		immutable float u1 = texture.minU, v1 = texture.minV;
		immutable float u2 = texture.maxU, v2 = texture.minV;
		immutable float u3 = texture.maxU, v3 = texture.maxV;
		immutable float u4 = texture.minU, v4 = texture.maxV;
		Triangle[2] triangles = [Triangle(p1, c1, u1, v1, p2, c2, u2, v2, p3, c3, u3, v3), Triangle(p3, c3, u3, v3, p4, c4, u4, v4, p1, c1, u1, v1)];
		return new Mesh(texture.image, triangles);
	}

	public static immutable Color[24] defaultBoxColors =
	[
		Color.WHITE,
		Color.WHITE,
		Color.WHITE,
		Color.WHITE,

		Color.WHITE,
		Color.WHITE,
		Color.WHITE,
		Color.WHITE,

		Color.WHITE,
		Color.WHITE,
		Color.WHITE,
		Color.WHITE,

		Color.WHITE,
		Color.WHITE,
		Color.WHITE,
		Color.WHITE,

		Color.WHITE,
		Color.WHITE,
		Color.WHITE,
		Color.WHITE,

		Color.WHITE,
		Color.WHITE,
		Color.WHITE,
		Color.WHITE
	];

	public enum Coordinate
	{
		X = 0, Y = 1, Z = 2
	};

	public static pure int unitBoxColorIndex(bool x, bool y, bool z, Coordinate coordinate)
	{
		int retval = 0;
		retval += x ? 1 : 0;
		retval *= 2;
		retval += y ? 1 : 0;
		retval *= 2;
		retval += z ? 1 : 0;
		retval *= 3;
		retval += cast(int)coordinate;
		return retval;
	}

	/// make a box from <0, 0, 0> to <1, 1, 1>
	public static Mesh unitBox(TextureDescriptor nx, TextureDescriptor px, TextureDescriptor ny, TextureDescriptor py, TextureDescriptor nz, TextureDescriptor pz, const Color[] colors = defaultBoxColors)
	{
		assert(colors !is null && colors.length >= 24);
		const Color[] c = colors[0 .. 24];
		immutable Vector p0 = Vector.ZERO;
		immutable Vector p1 = Vector.X;
		immutable Vector p2 = Vector.Y;
		immutable Vector p3 = Vector.XY;
		immutable Vector p4 = Vector.Z;
		immutable Vector p5 = Vector.XZ;
		immutable Vector p6 = Vector.YZ;
		immutable Vector p7 = Vector.XYZ;
		Mesh retval = new Mesh();
		if(nx)
		{
			retval.add(quadrilateral(nx,
									 p0, c[unitBoxColorIndex(false, false, false, Coordinate.X)],
									 p4, c[unitBoxColorIndex(false, false, true, Coordinate.X)],
									 p6, c[unitBoxColorIndex(false, true, true, Coordinate.X)],
									 p2, c[unitBoxColorIndex(false, true, false, Coordinate.X)],
									 ));
		}
		if(px)
		{
			retval.add(quadrilateral(px,
									 p3, c[unitBoxColorIndex(true, true, false, Coordinate.X)],
									 p7, c[unitBoxColorIndex(true, true, true, Coordinate.X)],
									 p5, c[unitBoxColorIndex(true, false, true, Coordinate.X)],
									 p1, c[unitBoxColorIndex(true, false, false, Coordinate.X)]
									 ));
		}
		if(ny)
		{
			retval.add(quadrilateral(ny,
									 p0, c[unitBoxColorIndex(false, false, false, Coordinate.Y)],
									 p1, c[unitBoxColorIndex(true, false, false, Coordinate.Y)],
									 p5, c[unitBoxColorIndex(true, false, true, Coordinate.Y)],
									 p4, c[unitBoxColorIndex(false, false, true, Coordinate.Y)]
									 ));
		}
		if(py)
		{
			retval.add(quadrilateral(py,
									 p6, c[unitBoxColorIndex(false, true, true, Coordinate.Y)],
									 p7, c[unitBoxColorIndex(true, true, true, Coordinate.Y)],
									 p3, c[unitBoxColorIndex(true, true, false, Coordinate.Y)],
									 p2, c[unitBoxColorIndex(false, true, false, Coordinate.Y)]
									 ));
		}
		if(nz)
		{
			retval.add(quadrilateral(nz,
									 p1, c[unitBoxColorIndex(true, false, false, Coordinate.Z)],
									 p0, c[unitBoxColorIndex(false, false, false, Coordinate.Z)],
									 p2, c[unitBoxColorIndex(false, true, false, Coordinate.Z)],
									 p3, c[unitBoxColorIndex(true, true, false, Coordinate.Z)],
									 ));
		}
		if(pz)
		{
			retval.add(quadrilateral(pz,
									 p4, c[unitBoxColorIndex(false, false, true, Coordinate.Z)],
									 p5, c[unitBoxColorIndex(true, false, true, Coordinate.Z)],
									 p7, c[unitBoxColorIndex(true, true, true, Coordinate.Z)],
									 p6, c[unitBoxColorIndex(false, true, true, Coordinate.Z)],
									 ));
		}
		return retval;
	}
}
