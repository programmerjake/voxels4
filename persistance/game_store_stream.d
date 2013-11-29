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
import persistance.game_load_stream;
import persistance.game_version;

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

	public void write(ubyte v)
	{
	    writer.write(v);
	}

	public void write(ubyte[] bytes)
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
}
