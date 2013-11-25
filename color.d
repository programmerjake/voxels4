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
module color;

private import util;

public struct Color
{
	public const ubyte r, g, b, a;
	public enum : ubyte OPAQUE_ALPHA = 0xFF;
	public enum : ubyte TRANSPARENT_ALPHA = 0;
	public this(ubyte r, ubyte g, ubyte b, ubyte a = OPAQUE_ALPHA)
	{
		this.r = r;
		this.g = g;
		this.b = b;
		this.a = a;
	}

	public this()
	{
		this(0, 0, 0, TRANSPARENT_ALPHA);
	}

	public static immutable Color TRANSPARENT = Color(0, 0, 0, TRANSPARENT_ALPHA);

	public static Color RGBi(int r, int g, int b)
	{
		return Color(convertToUByte(r), convertToUByte(g), convertToUByte(b));
	}

	public static Color RGBf(float r, float g, float b)
	{
		return Color(convertToUByte(r), convertToUByte(g), convertToUByte(b));
	}

	public static Color RGBAi(int r, int g, int b, int a)
	{
		return Color(convertToUByte(r), convertToUByte(g), convertToUByte(b), convertToUByte(a));
	}

	public static Color RGBAf(float r, float g, float b, float a)
	{
		return Color(convertToUByte(r), convertToUByte(g), convertToUByte(b), convertToUByte(a));
	}

	public static Color Vi(int v)
	{
		return RGBi(v, v, v);
	}

	public static Color Vf(float v)
	{
		return RGBf(v, v, v);
	}

	public static Color VAi(int v, int a)
	{
		return RGBAi(v, v, v, a);
	}

	public static Color VAf(float v, float a)
	{
		return RGBAf(v, v, v, a);
	}

	public @property const float rf()
	{
		return convertFromUByteToFloat(r);
	}

	public @property const float gf()
	{
		return convertFromUByteToFloat(g);
	}

	public @property const float bf()
	{
		return convertFromUByteToFloat(b);
	}

	public @property const float af()
	{
		return convertFromUByteToFloat(a);
	}

	public Color compose(Color bkgnd)
	{
		float foregroundOpacity = af;
		float foregroundTransparency = 1 - foregroundOpacity;
		return RGBAf(rf * foregroundOpacity + bkgnd.rf * foregroundTransparency, gf * foregroundOpacity + bkgnd.gf * foregroundTransparency, bf * foregroundOpacity + bkgnd.bf * foregroundTransparency, 1 - (1 - bkgnd.af) * foregroundTransparency);
	}
}
