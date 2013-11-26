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
module file.stream;

private import std.stdio;
private import std.string;
private import std.math;

final class EOFException : Exception
{
	this()
	{
		super("read past end of file");
	}
}

private uint rawConvert(float v)
{
	uint negBit = signbit(v) ? 0x80000000 : 0;
	if(isNaN(v))
		return 0x7FC00000 | negBit;
	if(!isFinite(v))
		return 0x7F800000 | negBit;
	if(v == 0)
		return negBit;
	if(negBit) v = -v;
	uint exponent, mantissa;
	if(isSubnormal(v))
	{
		exponent = 0;
		v *= 2.0 ^^ 126;
		v *= 2.0 ^^ 23;
		mantissa = cast(uint)v;
	}
	else
	{
		exponent = 127 + ilogb(v);
		v = scalbn(v, -ilogb(v));
		v -= 1;
		v *= 2.0 ^^ 23;
		mantissa = cast(uint)v;
	}
	return negBit | (exponent << 23) | mantissa;
}

private ulong rawConvert(double v)
{
	ulong negBit = signbit(v) ? 0x8000000000000000L : 0;
	if(isNaN(v))
		return 0x7ff8000000000000L | negBit;
	if(!isFinite(v))
		return 0x7ff0000000000000L | negBit;
	if(v == 0)
		return negBit;
	if(negBit) v = -v;
	ulong exponent, mantissa;
	if(isSubnormal(v))
	{
		exponent = 0;
		v *= 2.0 ^^ 1022;
		v *= 2.0 ^^ 52;
		mantissa = cast(ulong)v;
	}
	else
	{
		exponent = 1023 + ilogb(v);
		v = scalbn(v, -ilogb(v));
		v -= 1;
		v *= 2.0 ^^ 52;
		mantissa = cast(ulong)v;
	}
	return negBit | (exponent << 52) | mantissa;
}

private float rawConvert(uint v)
{
	bool isNeg = (v & 0x80000000) != 0;
	v &= 0x7FFFFFFF;
	uint exponent = v >> 23;
	uint mantissa = v & ((1 << 23) - 1);
	if(exponent == 0)
	{
		if(mantissa == 0)
			return isNeg ? -0.0f : 0.0f;
		if(isNeg)
			mantissa = -mantissa;
		return 2.0 ^^ 149 * mantissa;
	}
	if(exponent == 0xFF)
	{
		if(mantissa == 0)
			return isNeg ? -float.infinity : float.infinity;
		return copysign(float.nan, isNeg ? -1.0 : 1.0);
	}
	return copysign(scalbn(1.0 + 2.0 ^^ -23 * mantissa, exponent - 127), isNeg ? -1.0 : 1.0);
}

private double rawConvert(ulong v)
{
	bool isNeg = (v & 0x8000000000000000L) != 0;
	v &= 0x7FFFFFFFFFFFFFFFL;
	ulong exponent = v >> 52;
	ulong mantissa = v & ((1L << 52) - 1);
	if(exponent == 0)
	{
		if(mantissa == 0)
			return isNeg ? -0.0 : 0.0;
		if(isNeg)
			mantissa = -mantissa;
		return 2.0 ^^ -1074 * mantissa;
	}
	if(exponent == 0x7FF)
	{
		if(mantissa == 0)
			return isNeg ? -double.infinity : double.infinity;
		return copysign(double.nan, isNeg ? -1.0 : 1.0);
	}
	return copysign(scalbn(1.0 + 2.0 ^^ -52 * mantissa, cast(int)(exponent - 1023)), isNeg ? -1.0 : 1.0);
}

public class UTFDataFormatException : Exception
{
	this(string msg)
	{
		super(msg);
	}
}

interface Reader
{
	ubyte readByte();
	size_t read(ubyte[] bytes);
	/*{
		size_t count = 0;
		try
		{
			for(size_t i = 0; i < bytes.length; i++)
			{
				bytes[i] = readByte();
				count++;
			}
		}
		catch(EOFException e)
		{
			return count;
		}
		return count;
	}*/
	void close();
	@property bool eof();

	final void readFully(ubyte[] bytes)
	{
		if(read(bytes) < bytes.length)
			throw new EOFException();
	}

	final ushort readShort()
	{
		ubyte[2] bytes;
		readFully(bytes);
		return (cast(ushort)bytes[0] << 8) | bytes[1];
	}

	final int readInt()
	{
		ushort a, b;
		a = readShort();
		b = readShort();
		return cast(int)((cast(uint)a << 16) | b);
	}

	final long readLong()
	{
		uint a, b;
		a = cast(uint)readShort();
		b = cast(uint)readShort();
		return cast(long)((cast(ulong)a << 32) | b);
	}

	final bool readBool()
	{
		return readByte() != 0;
	}

	final float readFloat()
	{
		return rawConvert(cast(uint)readInt());
	}

	final double readDouble()
	{
		return rawConvert(cast(ulong)readLong());
	}

	private final wchar readUTF8CharL2(ubyte a)
	{
		assert(0, "finish");
	}

	final wchar readUTF8Char()
	{
		ubyte a = readByte();
		if((a & 0x80) == 0)
			return cast(wchar)a;
		if((a & 0xE0) == 0xC0)
			assert(0, "finish");
		assert(0, "finish");
	}

	final wstring readUTF8()
	{
		wstring retval = "";
		assert(0, "finish");
	}
}

interface Writer
{
	void write(ubyte v);
	void write(ubyte[] bytes);
	/*{
		foreach(ubyte b; bytes)
		{
			write(b);
		}
	}*/
	void close();
	final void write(byte v)
	{
		write(cast(ubyte)v);
	}
	final void write(ushort v)
	{
		ubyte a, b;
		a = v >> 8;
		b = cast(ubyte)v;
		write(a);
		write(b);
	}
	final void write(short v)
	{
		write(cast(ushort)v);
	}
	final void write(bool v)
	{
		write(cast(ubyte)(v ? 1 : 0));
	}
	final void write(uint v)
	{
		ushort a, b;
		a = v >> 16;
		b = cast(ushort)v;
		write(a);
		write(b);
	}
	final void write(int v)
	{
		write(cast(uint)v);
	}
	final void write(ulong v)
	{
		uint a, b;
		a = v >> 32;
		b = cast(uint)v;
		write(a);
		write(b);
	}
	final void write(long v)
	{
		write(cast(ulong)v);
	}
	final void write(float v)
	{
		write(rawConvert(v));
	}
	final void write(double v)
	{
		write(rawConvert(v));
	}
}

final class FileReader : Reader
{
	File theFile;
	public this(string fileName)
	{
		theFile = File(fileName, "rb");
	}

	ubyte readByte()
	{
		ubyte[1] array;
		if(theFile.rawRead(array).length == 0)
			throw new EOFException();
		return array[0];
	}

	alias Reader.read read;

	size_t read(ubyte[] bytes)
	{
		return theFile.rawRead(bytes).length;
	}

	void close()
	{
		theFile.detach();
	}

	@property bool eof()
	{
		return theFile.eof;
	}
}

final class FileWriter : Writer
{
	File theFile;
	public this(string fileName)
	{
		theFile = File(fileName, "wb");
	}

	alias Writer.write write;

	void write(ubyte v)
	{
		ubyte[1] data;
		data[0] = v;
		write(data);
	}

	void write(ubyte[] bytes)
	{
		theFile.rawWrite(bytes);
	}

	void close()
	{
		theFile.detach();
	}
}
