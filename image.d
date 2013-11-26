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
module image;

private import png;
private import std.path;
private import platform;
private import std.exception;
import color;

class ImageLoadException : Exception
{
	this(string message)
	{
		super(message);
	}
}

final class Image
{
	private ubyte[] data;
	private uint w, h;
	private static immutable BytesPerPixel = 4;
	private enum RowOrder
	{
		TopDown, BottomUp
	}
	RowOrder rowOrder;
	private GLuint texture = 0;
	private bool textureValid = false;
	public this(string filename)
	{
		try
		{
			PNGDecoder decoder = new PNGDecoder(buildPath(ResourcePrefix, filename));
			data = decoder.data.dup;
			w = decoder.width;
			h = decoder.height;
			rowOrder = RowOrder.TopDown;
		}
		catch(PNGLoadException e)
		{
			throw new ImageLoadException(e.msg);
		}
	}

	public this(uint w, uint h)
	{
		enforce(w != 0, "illegal image width");
		enforce(h != 0, "illegal image height");
		this.w = w;
		this.h = h;
		data = new ubyte[BytesPerPixel * w * h];
		rowOrder = RowOrder.TopDown;
		for(uint i = 0; i < w * h; i += BytesPerPixel)
		{
			static assert(BytesPerPixel == 4);
			data[0] = 0;
			data[1] = 0;
			data[2] = 0;
			data[3] = Color.TRANSPARENT_ALPHA;
		}
	}

	public this(Color c)
	{
		this(1, 1);
		static assert(BytesPerPixel == 4);
		data[0] = c.r;
		data[1] = c.g;
		data[2] = c.b;
		data[3] = c.a;
	}

	public this(const Image rt)
	{
		w = rt.w;
		h = rt.h;
		data = null;
		if(rt.data !is null)
			data = rt.data.dup;
		rowOrder = rt.rowOrder;
		texture = 0;
		textureValid = false;
	}

	public void setPixel(int x, int y, Color c)
	{
		if(x < 0 || x >= w || y < 0 || y >= h || data is null)
			return;
		if(rowOrder == RowOrder.BottomUp)
			y = h - y - 1;
		int index = BytesPerPixel * (x + y * w);
		static assert(BytesPerPixel == 4);
		data[index++] = c.r;
		data[index++] = c.g;
		data[index++] = c.b;
		data[index++] = c.a;
		textureValid = false;
	}

	public Color getPixel(int x, int y) const
	{
		if(x < 0 || x >= w || y < 0 || y >= h || data is null)
			return Color.TRANSPARENT;
		if(rowOrder == RowOrder.BottomUp)
			y = h - y - 1;
		int index = BytesPerPixel * (x + y * w);
		Color retval;
		static assert(BytesPerPixel == 4);
		retval.r = data[index++];
		retval.g = data[index++];
		retval.b = data[index++];
		retval.a = data[index++];
		return retval;
	}

	public @property uint width() const
	{
		return w;
	}

	public @property uint height() const
	{
		return h;
	}

	public @property Image dup() const
	{
		return new Image(this);
	}

	private void swapRows(int y1, int y2)
	{
		int index1 = y1 * w * BytesPerPixel, index2 = y2 * w * BytesPerPixel;
		for(int i = 0; i < w * BytesPerPixel; i++)
		{
			ubyte t = data[index1];
			data[index1++] = data[index2];
			data[index2++] = t;
		}
	}

	private void setRowOrder(RowOrder newRowOrder)
	{
		if(rowOrder == newRowOrder)
			return;
		for(int y1 = 0, y2 = h - 1; y1 < y2; y1++, y2--)
		{
			swapRows(y1, y2);
		}
	}

	public void bind()
	{
		assert(data !is null);
		setRowOrder(RowOrder.BottomUp);
		if(textureValid)
		{
			glBindTexture(GL_TEXTURE_2D, this.texture);
			return;
		}
		if(texture == 0)
			glGenTextures(1, &texture);
		glBindTexture(GL_TEXTURE_2D, texture);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, cast(GLvoid *)data);
	}

	public static void bindNothing()
	{
		glBindTexture(GL_TEXTURE_2D, 0);
	}

	public ~this()
	{
		if(texture != 0 && isOpenGLLoaded())
			glDeleteTextures(1, &texture);
	}
}

