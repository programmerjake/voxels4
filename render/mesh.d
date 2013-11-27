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
import vector;
import color;
import image;
import platform;
import util;

public struct Triangle
{
	Vector[3] p;
	Color[3] c;
	float[3] u, v;
	public this(Vector p1, Color c1, float u1, float v1, Vector p2, Color c2, float u2, float v2, Vector p3, Color c3, float u3, float v3)
	{
		p[] = {p1, p2, p3};
		c[] = {c1, c2, c3};		
		u[] = {u1, u2, u3};
		v[] = {v1, v2, v3};
	}
}

public struct TransformedMesh
{
	public Mesh mesh = null;
	public Matrix transform = Matrix.IDENTITY;
	public this(Mesh mesh, Matrix transform = Matrix.IDENTITY)
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
	
	public this(Image texture, Triangle[] triangles = null)
	{
		textureInternal = texture;
		if(triangles is null || triangles.length == 0)
			return;
		checkForSpace(triangles.length);
		trianglesUsed = triangles.length;
		foreach(int triIndex, Triangle tri; triangles)
		{
			int v = VERTICES_ELEMENTS_PER_TRIANGLE * triIndex;
			int c = COLORS_ELEMENTS_PER_TRIANGLE * triIndex;
			int t = TEXTURE_COORDS_ELEMENTS_PER_TRIANGLE * triIndex;
			vertices[v++] = tri.p[0].x;
			vertices[v++] = tri.p[0].y;
			vertices[v++] = tri.p[0].z;
			vertices[v++] = tri.p[1].x;
			vertices[v++] = tri.p[1].y;
			vertices[v++] = tri.p[1].z;
			vertices[v++] = tri.p[2].x;
			vertices[v++] = tri.p[2].y;
			vertices[v++] = tri.p[2].z;
			colors[c++] = tri.c[0].rf;
			colors[c++] = tri.c[0].gf;
			colors[c++] = tri.c[0].bf;
			colors[c++] = tri.c[0].af;
			colors[c++] = tri.c[1].rf;
			colors[c++] = tri.c[1].gf;
			colors[c++] = tri.c[1].bf;
			colors[c++] = tri.c[1].af;
			colors[c++] = tri.c[2].rf;
			colors[c++] = tri.c[2].gf;
			colors[c++] = tri.c[2].bf;
			colors[c++] = tri.c[2].af;
			textureCoords[t++] = tri.u[0];
			textureCoords[t++] = tri.v[0];
			textureCoords[t++] = tri.u[1];
			textureCoords[t++] = tri.v[1];
			textureCoords[t++] = tri.u[2];
			textureCoords[t++] = tri.v[2];
		}
	}

	public this(TextureDescriptor texture, Triangle[] triangles = null)
	{
		textureInternal = texture.image;
		if(triangles is null || triangles.length == 0)
			return;
		checkForSpace(triangles.length);
		trianglesUsed = triangles.length;
		foreach(int triIndex, Triangle tri; triangles)
		{
			int v = VERTICES_ELEMENTS_PER_TRIANGLE * triIndex;
			int c = COLORS_ELEMENTS_PER_TRIANGLE * triIndex;
			int t = TEXTURE_COORDS_ELEMENTS_PER_TRIANGLE * triIndex;
			vertices[v++] = tri.p[0].x;
			vertices[v++] = tri.p[0].y;
			vertices[v++] = tri.p[0].z;
			vertices[v++] = tri.p[1].x;
			vertices[v++] = tri.p[1].y;
			vertices[v++] = tri.p[1].z;
			vertices[v++] = tri.p[2].x;
			vertices[v++] = tri.p[2].y;
			vertices[v++] = tri.p[2].z;
			colors[c++] = tri.c[0].rf;
			colors[c++] = tri.c[0].gf;
			colors[c++] = tri.c[0].bf;
			colors[c++] = tri.c[0].af;
			colors[c++] = tri.c[1].rf;
			colors[c++] = tri.c[1].gf;
			colors[c++] = tri.c[1].bf;
			colors[c++] = tri.c[1].af;
			colors[c++] = tri.c[2].rf;
			colors[c++] = tri.c[2].gf;
			colors[c++] = tri.c[2].bf;
			colors[c++] = tri.c[2].af;
			textureCoords[t++] = interpolate(tri.u[0], texture.minU, texture.maxU);
			textureCoords[t++] = interpolate(tri.v[0], texture.minV, texture.maxV);
			textureCoords[t++] = interpolate(tri.u[1], texture.minU, texture.maxU);
			textureCoords[t++] = interpolate(tri.v[1], texture.minV, texture.maxV);
			textureCoords[t++] = interpolate(tri.u[2], texture.minU, texture.maxU);
			textureCoords[t++] = interpolate(tri.v[2], texture.minV, texture.maxV);
		}
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
			trianglesAllocated = rt.mesh.trianglesAllocated;
			trianglesUsed = rt.mesh.trianglesUsed;
			immutable int limit = VERTICES_ELEMENTS_PER_TRIANGLE * trianglesUsed;
			for(int i = 0; i < limit; i += 3)
			{
				Vector v = rt.transform.apply(Vector(vertices[i], vertices[i + 1], vertices[i + 2]));
				vertices[i] = v.x;
				vertices[i + 1] = v.y;
				vertices[i + 2] = v.z;
			}
		}
	}

	public this(Mesh rt)
	{
		sealed = false;
		textureInternal = rt.textureInternal;
		vertices = dupFloatArray(rt.vertices);
		textureCoords = dupFloatArray(rt.textureCoords);
		colors = dupFloatArray(rt.colors);
		trianglesAllocated = rt.trianglesAllocated;
		trianglesUsed = rt.trianglesUsed;
	}

	public Mesh add(TransformedMesh mesh)
	{
		if(sealed)
			throw new SealedException();
		if(mesh.mesh is null || mesh.mesh.trianglesUsed <= 0)
			return this;
        if(this.texture !is mesh.mesh.texture)
            throw new TextureNotSameException();
        checkForSpace(mesh.mesh.trianglesUsed);
        immutable int finalSize = trianglesUsed + mesh.mesh.trianglesUsed;
        for(int i = trianglesUsed * VERTICES_ELEMENTS_PER_TRIANGLE, j = 0; i < finalSize * VERTICES_ELEMENTS_PER_TRIANGLE; i += 3, j += 3)
        {
			Vector v = rt.transform.apply(Vector(mesh.mesh.vertices[j], mesh.mesh.vertices[j + 1], mesh.mesh.vertices[j + 2]));
			vertices[i] = v.x;
			vertices[i + 1] = v.y;
			vertices[i + 2] = v.z;
		}
		textureCoords[trianglesUsed * TEXTURE_COORDS_ELEMENTS_PER_TRIANGLE .. finalSize * TEXTURE_COORDS_ELEMENTS_PER_TRIANGLE] = mesh.mesh.textureCoords[0 .. mesh.mesh.trianglesUsed * TEXTURE_COORDS_ELEMENTS_PER_TRIANGLE];
		colors[trianglesUsed * COLORS_ELEMENTS_PER_TRIANGLE .. finalSize * COLORS_ELEMENTS_PER_TRIANGLE] = mesh.mesh.colors[0 .. mesh.mesh.trianglesUsed * COLORS_ELEMENTS_PER_TRIANGLE];
		trianglesUsed = finalSize;
		return this;
	}

	public Mesh add(Mesh mesh)
	{
		if(sealed)
			throw new SealedException();
		if(mesh is null || mesh.trianglesUsed <= 0)
			return this;
        if(this.texture !is mesh.texture)
            throw new TextureNotSameException();
        checkForSpace(mesh.trianglesUsed);
        immutable int finalSize = trianglesUsed + mesh.trianglesUsed;
		vertices[trianglesUsed * VERTICES_ELEMENTS_PER_TRIANGLE .. finalSize * VERTICES_ELEMENTS_PER_TRIANGLE] = mesh.vertices[0 .. mesh.trianglesUsed * VERTICES_ELEMENTS_PER_TRIANGLE];
		textureCoords[trianglesUsed * TEXTURE_COORDS_ELEMENTS_PER_TRIANGLE .. finalSize * TEXTURE_COORDS_ELEMENTS_PER_TRIANGLE] = mesh.textureCoords[0 .. mesh.trianglesUsed * TEXTURE_COORDS_ELEMENTS_PER_TRIANGLE];
		colors[trianglesUsed * COLORS_ELEMENTS_PER_TRIANGLE .. finalSize * COLORS_ELEMENTS_PER_TRIANGLE] = mesh.colors[0 .. mesh.trianglesUsed * COLORS_ELEMENTS_PER_TRIANGLE];
		trianglesUsed = finalSize;
		return this;
	}
	
	public Mesh seal()
	{
		sealed = true;
		return this;
	}

    public Mesh transform(in Matrix transform)
    {
        if(this.sealed)
            throw new SealedException();
        for(int i = 0; i < this.trianglesUsed * VERTICES_ELEMENTS_PER_TRIANGLE;)
        {
            float x = this.vertices[i];
            float y = this.vertices[i + 1];
            float z = this.vertices[i + 2];
            this.vertices[i] = x * transform.x00 + y * transform.x10 + z
                    * transform.x20 + transform.x30;
            this.vertices[i++] = x * transform.x01 + y * transform.x11 + z
                    * transform.x21 + transform.x31;
            this.vertices[i++] = x * transform.x02 + y * transform.x12 + z
                    * transform.x22 + transform.x32;
        }
        return this;
    }
    
    package void render()
    {
		if(trianglesUsed <= 0)
			return;
		synchronized(getSDLSyncObject())
		{
			texture.bind();
			glEnableClientState(GL_COLOR_ARRAY);
			glEnableClientState(GL_TEXTURE_COORD_ARRAY);
			glEnableClientState(GL_VERTEX_ARRAY);
			glVertexPointer(3, GL_FLOAT, 0, cast(void *)vertices);
			glTexCoordPointer(2, GL_FLOAT, 0, cast(void *)textureCoords);
			glColorPointer(4, GL_FLOAT, 0, cast(void *)colors);
			glDrawArrays(GL_TRIANGLES, 0, trianglesUsed * 3);
		}
	}
	
	public int opApply(int delegate(Triangle) dg) const
	{
		int retval = 0;
		int v = 0, c = 0, t = 0;
		Triangle tri;
		for(int i = 0; i < trianglesUsed; i++)
		{
			tri.p[0].x = vertices[v++];
			tri.p[0].y = vertices[v++];
			tri.p[0].z = vertices[v++];
			tri.p[1].x = vertices[v++];
			tri.p[1].y = vertices[v++];
			tri.p[1].z = vertices[v++];
			tri.p[2].x = vertices[v++];
			tri.p[2].y = vertices[v++];
			tri.p[2].z = vertices[v++];
			
			tri.c[0].rf = colors[c++];
			tri.c[0].gf = colors[c++];
			tri.c[0].bf = colors[c++];
			tri.c[0].af = colors[c++];
			tri.c[1].rf = colors[c++];
			tri.c[1].gf = colors[c++];
			tri.c[1].bf = colors[c++];
			tri.c[1].af = colors[c++];
			tri.c[2].rf = colors[c++];
			tri.c[2].gf = colors[c++];
			tri.c[2].bf = colors[c++];
			tri.c[2].af = colors[c++];
			
			tri.u[0] = textureCoords[t++];
			tri.v[0] = textureCoords[t++];
			tri.u[1] = textureCoords[t++];
			tri.v[1] = textureCoords[t++];
			tri.u[2] = textureCoords[t++];
			tri.v[2] = textureCoords[t++];
			retval = dg(tri);
			if(retval != 0)
				return retval;
		}
		return retval;
	}
	
	public int opApply(int delegate(int, Triangle) dg) const
	{
		int retval = 0;
		int v = 0, c = 0, t = 0;
		Triangle tri;
		for(int i = 0; i < trianglesUsed; i++)
		{
			tri.p[0].x = vertices[v++];
			tri.p[0].y = vertices[v++];
			tri.p[0].z = vertices[v++];
			tri.p[1].x = vertices[v++];
			tri.p[1].y = vertices[v++];
			tri.p[1].z = vertices[v++];
			tri.p[2].x = vertices[v++];
			tri.p[2].y = vertices[v++];
			tri.p[2].z = vertices[v++];
			
			tri.c[0].rf = colors[c++];
			tri.c[0].gf = colors[c++];
			tri.c[0].bf = colors[c++];
			tri.c[0].af = colors[c++];
			tri.c[1].rf = colors[c++];
			tri.c[1].gf = colors[c++];
			tri.c[1].bf = colors[c++];
			tri.c[1].af = colors[c++];
			tri.c[2].rf = colors[c++];
			tri.c[2].gf = colors[c++];
			tri.c[2].bf = colors[c++];
			tri.c[2].af = colors[c++];
			
			tri.u[0] = textureCoords[t++];
			tri.v[0] = textureCoords[t++];
			tri.u[1] = textureCoords[t++];
			tri.v[1] = textureCoords[t++];
			tri.u[2] = textureCoords[t++];
			tri.v[2] = textureCoords[t++];
			retval = dg(i, tri);
			if(retval != 0)
				return retval;
		}
		return retval;
	}
	
	public Triangle opIndex(size_t i) const
	{
		assert(i >= 0 && i < trianglesUsed);
		Triangle tri;
		int v = VERTICES_ELEMENTS_PER_TRIANGLE * i;
		int c = COLORS_ELEMENTS_PER_TRIANGLE * i;
		int t = TEXTURE_COORDS_ELEMENTS_PER_TRIANGLE * i;
		tri.p[0].x = vertices[v++];
		tri.p[0].y = vertices[v++];
		tri.p[0].z = vertices[v++];
		tri.p[1].x = vertices[v++];
		tri.p[1].y = vertices[v++];
		tri.p[1].z = vertices[v++];
		tri.p[2].x = vertices[v++];
		tri.p[2].y = vertices[v++];
		tri.p[2].z = vertices[v++];
		
		tri.c[0].rf = colors[c++];
		tri.c[0].gf = colors[c++];
		tri.c[0].bf = colors[c++];
		tri.c[0].af = colors[c++];
		tri.c[1].rf = colors[c++];
		tri.c[1].gf = colors[c++];
		tri.c[1].bf = colors[c++];
		tri.c[1].af = colors[c++];
		tri.c[2].rf = colors[c++];
		tri.c[2].gf = colors[c++];
		tri.c[2].bf = colors[c++];
		tri.c[2].af = colors[c++];
		
		tri.u[0] = textureCoords[t++];
		tri.v[0] = textureCoords[t++];
		tri.u[1] = textureCoords[t++];
		tri.v[1] = textureCoords[t++];
		tri.u[2] = textureCoords[t++];
		tri.v[2] = textureCoords[t++];
		return tri;
	}
	
	public int opDollar(size_t arg)() const if(arg == 0)
	{
		return trianglesUsed;
	}
	
	public @property int length() const
	{
		return trianglesUsed;
	}
}

public struct Renderer
{
	public @disable this();
	
	public static void render(Mesh mesh)
	{
		mesh.render();
	}
}
