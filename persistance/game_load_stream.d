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
module persistance.game_load_stream;
import file.stream;
import std.math;
import persistance.game_version;
import vector;
import block.block;

public final class InvalidDataValueException : IOException
{
    public this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}

public class InvalidFileFormatException : IOException
{
    public this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
    public this(IOException e)
    {
        super("IO Error : " ~ e.msg, e.file, e.line);
    }
}

public final class VersionTooNewException : InvalidFileFormatException
{
    public this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}

public final class GameLoadStream : Reader
{
    private Reader reader;
    public static immutable ubyte[8] MAGIC_STRING = ['V', 'o', 'x', 'e', 'l', 's', ' ', ' '];
    private immutable uint theFileVersion;
    public this(Reader reader)
    {
        blockDescriptors = new BlockDescriptor[1];
        this.reader = reader;
        assert(reader !is null);
        scope(failure) reader.close();
        try
        {
            ubyte[MAGIC_STRING.length] test_magic_string;
            reader.readFully(test_magic_string);
            foreach(int i, ubyte b; test_magic_string)
            {
                if(MAGIC_STRING[i] != b)
                    throw new InvalidFileFormatException("invalid magic string");
            }
            theFileVersion = readInt();
            if(theFileVersion > GameVersion.FILE_VERSION)
                throw new VersionTooNewException("the file is for a later version of this program");
        }
        catch(InvalidFileFormatException e) // so it doesn't get wrapped in another InvalidFileFormatException
        {
            throw e;
        }
        catch(IOException e)
        {
            throw new InvalidFileFormatException(e);
        }
    }

    public final @property uint fileVersion()
    {
        return theFileVersion;
    }

    public final double readFiniteDouble()
    {
        double v = readDouble();
        if(!isFinite(v))
            throw new InvalidDataValueException("read double is not finite");
        return v;
    }

    public final float readFiniteFloat()
    {
        float v = readFloat();
        if(!isFinite(v))
            throw new InvalidDataValueException("read float is not finite");
        return v;
    }

    public final double
        readRangeLimitedDouble(in double min, in double max)
    {
        double v = readFiniteDouble();
        if(v < min || v > max)
            throw new InvalidDataValueException("read double is out of range");
        return v;
    }

    public final float
        readRangeLimitedFloat(in float min, in float max)
    {
        float v = readFiniteFloat();
        if(v < min || v > max)
            throw new InvalidDataValueException("read float is out of range");
        return v;
    }

    public final int
        readRangeLimitedSignedInt(in int min, in int max)
    {
        int v = readInt();
        if(v < min || v > max)
            throw new InvalidDataValueException("read signed int is out of range");
        return v;
    }

    public final uint
        readRangeLimitedUnsignedInt(in uint min, in uint max)
    {
        uint v = readInt();
        if(v < min || v > max)
            throw new InvalidDataValueException("read unsigned int is out of range");
        return v;
    }

    public final byte
        readRangeLimitedSignedByte(in byte min, in byte max)
    {
        byte v = readByte();
        if(v < min || v > max)
            throw new InvalidDataValueException("read signed byte is out of range");
        return v;
    }

    public final ubyte
        readRangeLimitedUnsignedByte(in ubyte min, in ubyte max)
    {
        ubyte v = readByte();
        if(v < min || v > max)
            throw new InvalidDataValueException("read unsigned byte is out of range");
        return v;
    }

    public final short
        readRangeLimitedSignedShort(in short min, in short max)
    {
        short v = readShort();
        if(v < min || v > max)
            throw new InvalidDataValueException("read signed short is out of range");
        return v;
    }

    public final ushort
        readRangeLimitedUnsignedShort(in ushort min, in ushort max)
    {
        ushort v = readShort();
        if(v < min || v > max)
            throw new InvalidDataValueException("read unsigned short is out of range");
        return v;
    }

    public final long
        readRangeLimitedSignedLong(in long min, in long max)
    {
        long v = readLong();
        if(v < min || v > max)
            throw new InvalidDataValueException("read signed long is out of range");
        return v;
    }

    public final ulong
        readRangeLimitedUnsignedLong(in ulong min, in ulong max)
    {
        ulong v = readLong();
        if(v < min || v > max)
            throw new InvalidDataValueException("read unsigned long is out of range");
        return v;
    }

	public ubyte readByte()
	{
	    return reader.readByte();
	}

	public size_t read(ubyte[] bytes)
	{
	    return reader.read(bytes);
	}

	public void close()
	{
	    reader.close();
	}

	public @property bool eof()
	{
        return reader.eof;
	}

	public Vector readFiniteVector()
	{
	    float x = readFiniteFloat();
	    float y = readFiniteFloat();
	    float z = readFiniteFloat();
	    return Vector(x, y, z);
	}

	private BlockDescriptor[] blockDescriptors;

	public BlockDescriptor readBlockDescriptor()
	{
	    uint index = readRangeLimitedUnsignedInt(0, cast(uint)blockDescriptors.length);
	    if(index == 0)
        {
            string name = cast(string)readUTF8();
            BlockDescriptor bd = BlockDescriptor.getBlock(name);
            if(bd is null)
                throw new InvalidDataValueException("block type not found");
            blockDescriptors ~= [bd];
            return bd;
        }
        index--;
        return blockDescriptors[index];
	}
}
