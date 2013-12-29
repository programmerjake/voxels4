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
module vector;

public import std.math;
public import util;

public struct Vector
{
    /** x coordinate */
    public float x = 0;
    /** y coordinate */
    public float y = 0;
    /** z coordinate */
    public float z = 0;

    public pure this(float x, float y, float z)
    {
        this.x = x;
        this.y = y;
        this.z = z;
    }

	public pure @property Vector dup() const
	{
		return this;
	}

    public pure Vector opUnary(string op)() const if(op == "-")
	{
		return Vector(-x, -y, -z);
	}

    public pure Vector opUnary(string op)() const if(op == "+")
	{
		return this;
	}

	public pure Vector opBinary(string op)(const Vector rt) const
	{
		return mixin("Vector(x " ~ op ~ " rt.x, y " ~ op ~ " rt.y, z " ~ op ~ " rt.z)");
	}

	public pure Vector opBinary(string op)(Vector rt)
	{
		return mixin("Vector(x " ~ op ~ " rt.x, y " ~ op ~ " rt.y, z " ~ op ~ " rt.z)");
	}

	public pure bool opEquals(ref const Vector rt) const
	{
		return x == rt.x && y == rt.y && z == rt.z;
	}

	public pure void opOpAssign(string op)(const Vector rt)
	{
		mixin("x " ~ op ~ "= rt.x;");
		mixin("y " ~ op ~ "= rt.y;");
		mixin("z " ~ op ~ "= rt.z;");
	}

	public pure void opOpAssign(string op)(const float rt)
	{
		mixin("x " ~ op ~ "= rt;");
		mixin("y " ~ op ~ "= rt;");
		mixin("z " ~ op ~ "= rt;");
	}

    public pure static Vector normalize(in float x, in float y, in float z)
    {
        float r = sqrt(x * x + y * y + z * z);
        if(r == 0)
            r = 1;
        return Vector(x / r, y / r, z / r);
    }

    public static immutable Vector ZERO = Vector(0, 0, 0);
    public static immutable Vector X = Vector(1, 0, 0);
    public static immutable Vector Y = Vector(0, 1, 0);
    public static immutable Vector Z = Vector(0, 0, 1);
    public static immutable Vector XY = Vector(1, 1, 0);
    public static immutable Vector YZ = Vector(0, 1, 1);
    public static immutable Vector XZ = Vector(1, 0, 1);
    public static immutable Vector XYZ = Vector(1, 1, 1);
    public static immutable Vector NX = Vector(-1, 0, 0);
    public static immutable Vector NY = Vector(0, -1, 0);
    public static immutable Vector NZ = Vector(0, 0, -1);
    public static immutable Vector NXY = Vector(-1, 1, 0);
    public static immutable Vector NYZ = Vector(0, -1, 1);
    public static immutable Vector NXZ = Vector(-1, 0, 1);
    public static immutable Vector NXYZ = Vector(-1, 1, 1);
    public static immutable Vector XNY = Vector(1, -1, 0);
    public static immutable Vector YNZ = Vector(0, 1, -1);
    public static immutable Vector XNZ = Vector(1, 0, -1);
    public static immutable Vector NXNY = Vector(-1, -1, 0);
    public static immutable Vector NYNZ = Vector(0, -1, -1);
    public static immutable Vector NXNZ = Vector(-1, 0, -1);
    public static immutable Vector XNYZ = Vector(1, -1, 1);
    public static immutable Vector NXNYZ = Vector(-1, -1, 1);
    public static immutable Vector XYNZ = Vector(1, 1, -1);
    public static immutable Vector NXYNZ = Vector(-1, 1, -1);
    public static immutable Vector XNYNZ = Vector(1, -1, -1);
    public static immutable Vector NXNYNZ = Vector(-1, -1, -1);

    public pure @property float phi()
    {
		float r = abs(this);
		if(r == 0)
			return 0;
        float v = this.y / r;
        v = limit!float(v, -1, 1);
        return asin(v);
    }

    public pure @property float theta()
    {
        return atan2(this.x, this.z);
    }

    public pure @property float rSpherical()
    {
        return sqrt(this.x * this.x + this.y * this.y + this.z
                * this.z);
    }

    public pure @property float rCylindrical()
    {
        return sqrt(this.x * this.x + this.z * this.z);
    }

    public pure static Vector sphericalCoordinate(in float r,
                                             in float theta,
                                             in float phi)
    {
        float cosPhi = cos(phi);
        return Vector(r * sin(theta) * cosPhi, r
                * sin(phi), r * cos(theta) * cosPhi);
    }

    public pure static Vector cylindricalCoordinate(in float r,
                                               in float theta,
                                               in float y)
    {
        return Vector(r * sin(theta), y, r
                * cos(theta));
    }

    public pure @property float rMaximum()
    {
        return fmax(fmax(fabs(this.x), fabs(this.y)),
                        fabs(this.z));
    }

    public pure @property float rCylindricalMaximum()
    {
        return fmax(sqrt(this.x * this.x + this.z * this.z),
                        fabs(this.y));
    }

	public pure Vector opBinaryRight(string op)(float a) const if(op == "*")
	{
		return Vector(a * x, a * y, a * z);
	}

	public pure Vector opBinary(string op)(float b) const if(op == "*" || op == "/")
	{
		return mixin("Vector(x " ~ op ~ " b, y " ~ op ~ " b, z " ~ op ~ " b)");
	}
}

public pure float dot(Vector a, Vector b)
{
	return a.x * b.x + a.y * b.y + a.z * b.z;
}

public pure Vector cross(Vector a, Vector b)
{
	return Vector(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x);
}

public pure float absSquared(Vector v)
{
	return dot(v, v);
}

public pure float abs(Vector v)
{
	return sqrt(absSquared(v));
}

public pure Vector normalize(Vector v)
{
	float r = abs(v);
	if(r == 0)
		r = 1;
	return v / r;
}

public pure Vector normalizeCylindrical(Vector v)
{
	float r = v.rCylindrical;
	if(r == 0)
		r = 1;
	return v / r;
}

public pure Vector normalizeMaximum(Vector v)
{
	float r = v.rMaximum;
	if(r == 0)
		r = 1;
	return v / r;
}

public pure Vector normalizeCylindricalMaximum(Vector v)
{
	float r = v.rCylindricalMaximum;
	if(r == 0)
		r = 1;
	return v / r;
}

public Vector vrandom()
{
    Vector retval;
    do
    {
        retval.x = frandom(-1, 1);
        retval.y = frandom(-1, 1);
        retval.z = frandom(-1, 1);
    }
    while(absSquared(retval) > 1);
    return retval;
}
