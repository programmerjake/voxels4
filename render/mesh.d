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
public import matrix;
public import vector;
public import color;
public import image;
public import render.texture_descriptor;
import platform;
import util;
import std.string;
import std.stdio;

public struct Triangle
{
	Vector[3] p;
	Color[3] c;
	float[3] u, v;
	public this(Vector p1, Color c1, float u1, float v1, Vector p2, Color c2, float u2, float v2, Vector p3, Color c3, float u3, float v3)
	{
		p[] = [p1, p2, p3];
		c[] = [c1, c2, c3];
		u[] = [u1, u2, u3];
		v[] = [v1, v2, v3];
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
		this.transform = mesh.transform.concat(transform);
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
    private size_t trianglesUsed = 0, trianglesAllocated = 0;
    public static immutable int VERTICES_ELEMENTS_PER_TRIANGLE = 3 * 3;
    public static immutable int TEXTURE_COORDS_ELEMENTS_PER_TRIANGLE = 2 * 3;
    public static immutable int COLORS_ELEMENTS_PER_TRIANGLE = 4 * 3;

    private float[] expandArray(float[] a, size_t newSize)
    {
        assert(a is null || a.length <= newSize);
        if(a is null)
            return new float[newSize];
        float[] retval = new float[newSize];
        for(int i = 0; i < a.length; i++)
            retval[i] = a[i];
        delete a;
        return retval;
    }

    private void expandArrays(size_t newSize)
    {
		vertices = expandArray(vertices, VERTICES_ELEMENTS_PER_TRIANGLE * newSize);
		textureCoords = expandArray(textureCoords, TEXTURE_COORDS_ELEMENTS_PER_TRIANGLE * newSize);
		colors = expandArray(colors, COLORS_ELEMENTS_PER_TRIANGLE * newSize);
		trianglesAllocated = newSize;
	}

	private size_t getExpandedAmount(size_t increment)
	{
		return trianglesAllocated + increment + 16 + trianglesAllocated / 8 + increment / 2;
	}

	private void checkForSpace(size_t increment)
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
        trianglesAllocated = 0;
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
        trianglesAllocated = 0;
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
        trianglesAllocated = 0;
		if(rt.mesh !is null)
		{
			textureInternal = rt.mesh.textureInternal;
			vertices = dupFloatArray(rt.mesh.vertices);
			textureCoords = dupFloatArray(rt.mesh.textureCoords);
			colors = dupFloatArray(rt.mesh.colors);
			trianglesAllocated = rt.mesh.trianglesAllocated;
			trianglesUsed = rt.mesh.trianglesUsed;
			immutable size_t limit = VERTICES_ELEMENTS_PER_TRIANGLE * trianglesUsed;
			for(size_t i = 0; i < limit; i += 3)
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
		if(this.texture is null)
			this.textureInternal = mesh.mesh.texture;
		else if(this.texture !is mesh.mesh.texture)
            throw new ImageNotSameException();
        checkForSpace(mesh.mesh.trianglesUsed);
        immutable size_t finalSize = trianglesUsed + mesh.mesh.trianglesUsed;
        for(size_t i = trianglesUsed * VERTICES_ELEMENTS_PER_TRIANGLE, j = 0; i < finalSize * VERTICES_ELEMENTS_PER_TRIANGLE; i += 3, j += 3)
        {
			Vector v = mesh.transform.apply(Vector(mesh.mesh.vertices[j], mesh.mesh.vertices[j + 1], mesh.mesh.vertices[j + 2]));
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
        if(this.texture is null)
			this.textureInternal = mesh.texture;
		else if(this.texture !is mesh.texture)
            throw new ImageNotSameException();
        checkForSpace(mesh.trianglesUsed);
        immutable size_t finalSize = trianglesUsed + mesh.trianglesUsed;
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

    public Mesh transform(Matrix transform)
    {
        if(this.sealed)
            throw new SealedException();
        for(int i = 0; i < this.trianglesUsed * VERTICES_ELEMENTS_PER_TRIANGLE;)
        {
            float x = this.vertices[i];
            float y = this.vertices[i + 1];
            float z = this.vertices[i + 2];
            Vector v = Vector(x, y, z);
            v = transform.apply(v);
            this.vertices[i++] = v.x;
            this.vertices[i++] = v.y;
            this.vertices[i++] = v.z;
        }
        return this;
    }

    package void render()
    {
		if(trianglesUsed <= 0 || texture is null)
			return;
		synchronized(getSDLSyncObject())
		{
			texture.bind();
			static if(true)
			{
				glVertexPointer(3, GL_FLOAT, 0, cast(void *)vertices);
				glTexCoordPointer(2, GL_FLOAT, 0, cast(void *)textureCoords);
				glColorPointer(4, GL_FLOAT, 0, cast(void *)colors);
				glDrawArrays(GL_TRIANGLES, 0, cast(GLint)trianglesUsed * 3);
			}
			else
			{
				glBegin(GL_TRIANGLES);
				foreach(Triangle t; this)
				{
					for(int i = 0; i < 3; i++)
					{
						glTexCoord2f(t.u[i], t.v[i]);
						glColor4f(t.c[i].rf, t.c[i].gf, t.c[i].bf, t.c[i].af);
						glVertex3f(t.p[i].x, t.p[i].y, t.p[i].z);
					}
				}
				glEnd();
			}
		}
	}

	public int opApply(int delegate(ref Triangle) dg) const
	{
		int retval = 0;
		size_t v = 0, c = 0, t = 0;
		Triangle tri;
		for(size_t i = 0; i < trianglesUsed; i++)
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

	public int opApply(int delegate(ref int, ref Triangle) dg) const
	{
		int retval = 0;
		size_t v = 0, c = 0, t = 0;
		Triangle tri;
		for(size_t i = 0; i < trianglesUsed; i++)
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
			int index = cast(int)i;
			retval = dg(index, tri);
			if(retval != 0)
				return retval;
		}
		return retval;
	}

	public Triangle opIndex(size_t i) const
	{
		assert(i >= 0 && i < trianglesUsed);
		Triangle tri;
		size_t v = VERTICES_ELEMENTS_PER_TRIANGLE * i;
		size_t c = COLORS_ELEMENTS_PER_TRIANGLE * i;
		size_t t = TEXTURE_COORDS_ELEMENTS_PER_TRIANGLE * i;
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

	public size_t opDollar(size_t arg)() const if(arg == 0)
	{
		return trianglesUsed;
	}

	public @property size_t length() const
	{
		return trianglesUsed;
	}

	private static Mesh EMPTY_;
	public static @property Mesh EMPTY()
	{
        if(EMPTY_ is null)
            EMPTY_ = (new Mesh()).seal();
        return EMPTY_;
	}

	public void dump()
	{
        writefln("Mesh : image:%s length:%s", cast(void *)texture, trianglesUsed);
        writefln("{");
        foreach(int i, Triangle tri; this)
        {
            writefln("%s:\t<%s, %s, %s>, <%s, %s, %s>, <%s, %s, %s>", i, tri.p[0].x, tri.p[0].y, tri.p[0].z, tri.p[1].x, tri.p[1].y, tri.p[1].z, tri.p[2].x, tri.p[2].y, tri.p[2].z);
        }
        writefln("}");
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
