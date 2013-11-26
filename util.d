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
module util;

private import std.c.math;

template limit(T)
{
	T limit(T v, T minV, T maxV)
	{
		if(v < minV)
			return minV;
		if(v > maxV)
			return maxV;
		return v;
	}
}

ubyte convertToUByte(int v)
{
	return cast(ubyte)limit(v, 0, 0xFF);
}

ubyte convertToUByte(float v)
{
	return convertToUByte(cast(int)(v * 0x100));
}

float convertFromUByteToFloat(ubyte v)
{
	return cast(float)v / 0xFF;
}

int ifloor(float v)
{
	if(v < 0)
		return -cast(int)-v;
	return cast(int)v;
}

int iceil(float v)
{
	if(v > 0)
		return -cast(int)-v;
	return cast(int)v;
}

