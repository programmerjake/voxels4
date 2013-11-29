module png;

import derelict.sdl.image;
import derelict.sdl.sdl;
import platform;
import core.exception;
import color;
import std.conv;
import file.stream;

class PNGLoadException : IOException
{
	public this(string msg)
	{
		super(msg);
	}
}

private
{
	version(LittleEndian)
	{
		immutable Uint32 rMask = 0x000000ff, gMask = 0x0000ff00, bMask = 0x00ff0000, aMask = 0xff000000;
	}
	else
	{
		immutable Uint32 rMask = 0xff000000, gMask = 0x00ff0000, bMask = 0x0000ff00, aMask = 0x000000ff;
	}
}

final class PNGDecoder
{
	private ubyte[] data_ = null;
	private ushort w, h;
	public this(string filename)
	{
		synchronized(getSDLSyncObject())
		{
			SDL_RWops * rw = SDL_RWFromFile(cast(const char *)(filename ~ "\0"), "rb");
			if(rw == null)
				throw new PNGLoadException("can't open " ~ filename ~ " : " ~ to!string(SDL_GetError()));
			SDL_Surface* surface = IMG_LoadPNG_RW(rw);
			if(surface == null)
				throw new PNGLoadException("can't load " ~ filename ~ " : " ~ to!string(IMG_GetError()));
			data_ = new ubyte[surface.w * surface.h * 4];
			w = cast(ushort)surface.w;
			h = cast(ushort)surface.h;
			SDL_Surface * dest = SDL_CreateRGBSurfaceFrom(cast(void *)data_, w, h, 32, w * 4, rMask, gMask, bMask, aMask);
			SDL_SetAlpha(surface, 0, 0);
			SDL_SetAlpha(dest, 0, 0);
			SDL_Rect srcRect, destRect;
			srcRect.x = 0;
			srcRect.y = 0;
			srcRect.w = w;
			srcRect.h = h;
			destRect.x = 0;
			destRect.y = 0;
			destRect.w = w;
			destRect.h = h;
			SDL_BlitSurface(surface, &srcRect, dest, &destRect);
			SDL_FreeSurface(dest);
			SDL_FreeSurface(surface);
		}
	}

	public @property int width() const
	{
		return w;
	}

	public @property int height() const
	{
		return h;
	}

	/**
	 * Returns:
	 *  an array of ubyte where each pixel is 4 ubytes in the order r, g, b, a
	 */
	public @property const(ubyte[]) data() const
	{
		return data_;
	}
}
