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
module persistance.game_store_stream;
public import persistance.game_load_stream;
public import persistance.game_version;
public import file.stream;
import vector;
import block.block;
import entity.entity;

public final class GameStoreStream : Writer
{
    private Writer writer;
    public static immutable auto MAGIC_STRING = GameLoadStream.MAGIC_STRING;
    public this(Writer writer)
    {
        this.writer = writer;
        assert(writer !is null);
        scope(failure) writer.close();
        writer.write(MAGIC_STRING);
        writer.write(GameVersion.FILE_VERSION);
    }

    alias Writer.write write;

	public void write(ubyte v)
	{
	    writer.write(v);
	}

	public void write(const ubyte[] bytes)
	{
	    writer.write(bytes);
	}

	public void close()
	{
	    writer.close();
	}

	public void write(Vector v)
	{
	    write(v.x);
	    write(v.y);
	    write(v.z);
	}

	private uint[string] blockDescriptors;
	private uint nextBlockDescriptor = 1;

	public void write(BlockDescriptor bd)
	{
	    uint index = blockDescriptors.get(bd.name, 0);
	    write(index);
	    if(index == 0)
        {
            write(cast(wstring)bd.name);
            blockDescriptors[bd.name] = nextBlockDescriptor++;
        }
	}

	private uint[string] entityDescriptors;
	private uint nextEntityDescriptor = 1;

	public void write(EntityDescriptor ed)
	{
	    uint index = entityDescriptors.get(ed.name, 0);
	    write(index);
	    if(index == 0)
        {
            write(cast(wstring)ed.name);
            entityDescriptors[ed.name] = nextEntityDescriptor++;
        }
	}
}
