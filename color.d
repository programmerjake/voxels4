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

import util;

public struct Color
{
	public ubyte r, g, b, a;
	public static immutable ubyte OPAQUE_ALPHA = 0xFF;
	public static immutable ubyte TRANSPARENT_ALPHA = 0;
	public this(ubyte r, ubyte g, ubyte b, ubyte a = OPAQUE_ALPHA)
	{
		this.r = r;
		this.g = g;
		this.b = b;
		this.a = a;
	}

	public static immutable Color TRANSPARENT = Color(0, 0, 0, TRANSPARENT_ALPHA);
	public static immutable Color WHITE = Color(0xFF, 0xFF, 0xFF);
	public static immutable Color LIGHT_GRAY = Color(0xC0, 0xC0, 0xC0);
	public static immutable Color GRAY = Color(0x80, 0x80, 0x80);
	public static immutable Color DARK_GRAY = Color(0x40, 0x40, 0x40);
	public static immutable Color BLACK = Color(0, 0, 0);
	public static immutable Color CYAN = Color(0, 0xFF, 0xFF);
	public static immutable Color MAGENTA = Color(0xFF, 0, 0xFF);
	public static immutable Color BLUE = Color(0, 0, 0xFF);
	public static immutable Color YELLOW = Color(0xFF, 0xFF, 0);
	public static immutable Color GREEN = Color(0, 0xFF, 0);
	public static immutable Color RED = Color(0xFF, 0, 0);

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

	public @property const float rf() const
	{
		return convertFromUByteToFloat(r);
	}

	public @property void rf(float v)
	{
		r = convertToUByte(v);
	}

	public @property const float gf() const
	{
		return convertFromUByteToFloat(g);
	}

	public @property void gf(float v)
	{
		g = convertToUByte(v);
	}

	public @property const float bf() const
	{
		return convertFromUByteToFloat(b);
	}

	public @property void bf(float v)
	{
		b = convertToUByte(v);
	}

	public @property const float af() const
	{
		return convertFromUByteToFloat(a);
	}

	public @property void af(float v)
	{
		a = convertToUByte(v);
	}

	public Color compose(Color bkgnd) const
	{
		float foregroundOpacity = af;
		float foregroundTransparency = 1 - foregroundOpacity;
		return RGBAf(rf * foregroundOpacity + bkgnd.rf * foregroundTransparency, gf * foregroundOpacity + bkgnd.gf * foregroundTransparency, bf * foregroundOpacity + bkgnd.bf * foregroundTransparency, 1 - (1 - bkgnd.af) * foregroundTransparency);
	}

	public Color opBinary(string op)(Color rt) const if(op == "*")
	{
	    return RGBAf(rf * rt.rf, gf * rt.gf, bf * rt.bf, af * rt.af);
	}

	public Color opBinary(string op)(Color rt) const if(op == "+")
	{
	    return RGBAi(cast(int)r + rt.r, cast(int)g + rt.g, cast(int)b + rt.b, cast(int)a + rt.a);
	}
}

public Color scale(Color c, float s)
{
    return Color.RGBAf(c.rf * s, c.gf * s, c.bf * s, c.af);
}
