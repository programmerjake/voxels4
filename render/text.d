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
module render.text;
public import render.mesh;
import resource.texture_atlas;
import util;
import render.generate;

public struct Text
{
    public @disable this();

    private static immutable TextureAtlas Font;
    static this()
    {
        Font = TextureAtlas.Font8x8;
    }
    private static immutable uint fontWidth = 8, fontHeight = 8;
    private static immutable int textureXRes = 128, textureYRes = 128;
    private static immutable float pixelOffset = TextureAtlas.pixelOffset;

    private static immutable uint[128] topPageTranslations =
    [
        0x00C7,
        0x00FC,
        0x00E9,
        0x00E2,
        0x00E4,
        0x00E0,
        0x00E5,
        0x00E7,
        0x00EA,
        0x00EB,
        0x00E8,
        0x00EF,
        0x00EE,
        0x00EC,
        0x00C4,
        0x00C5,
        0x00C9,
        0x00E6,
        0x00C6,
        0x00F4,
        0x00F6,
        0x00F2,
        0x00FB,
        0x00F9,
        0x00FF,
        0x00D6,
        0x00DC,
        0x00A2,
        0x00A3,
        0x00A5,
        0x20A7,
        0x0192,
        0x00E1,
        0x00ED,
        0x00F3,
        0x00FA,
        0x00F1,
        0x00D1,
        0x00AA,
        0x00BA,
        0x00BF,
        0x2310,
        0x00AC,
        0x00BD,
        0x00BC,
        0x00A1,
        0x00AB,
        0x00BB,
        0x2591,
        0x2592,
        0x2593,
        0x2502,
        0x2524,
        0x2561,
        0x2562,
        0x2556,
        0x2555,
        0x2563,
        0x2551,
        0x2557,
        0x255D,
        0x255C,
        0x255B,
        0x2510,
        0x2514,
        0x2534,
        0x252C,
        0x251C,
        0x2500,
        0x253C,
        0x255E,
        0x255F,
        0x255A,
        0x2554,
        0x2569,
        0x2566,
        0x2560,
        0x2550,
        0x256C,
        0x2567,
        0x2568,
        0x2564,
        0x2565,
        0x2559,
        0x2558,
        0x2552,
        0x2553,
        0x256B,
        0x256A,
        0x2518,
        0x250C,
        0x2588,
        0x2584,
        0x258C,
        0x2590,
        0x2580,
        0x03B1,
        0x00DF,
        0x0393,
        0x03C0,
        0x03A3,
        0x03C3,
        0x00B5,
        0x03C4,
        0x03A6,
        0x0398,
        0x03A9,
        0x03B4,
        0x221E,
        0x03C6,
        0x03B5,
        0x2229,
        0x2261,
        0x00B1,
        0x2265,
        0x2264,
        0x2320,
        0x2321,
        0x00F7,
        0x2248,
        0x00B0,
        0x2219,
        0x00B7,
        0x221A,
        0x207F,
        0x00B2,
        0x25A0,
        0x00A0
    ];

    private static uint[uint] topPageTranslationMap;

    static this()
    {
        foreach(uint i, uint v; topPageTranslations)
            topPageTranslationMap[v] = i + 0x80;
    }

    private static uint translateToCodePage437(in dchar ch)
    {
        uint character = cast(uint)ch;
        if(character == '\0')
            return character;
        if(character >= 0x20 && character <= 0x7E)
            return character;
        switch(character)
        {
        case '\u263A':
            return 0x01;
        case '\u263B':
            return 0x02;
        case '\u2665':
            return 0x03;
        case '\u2666':
            return 0x04;
        case '\u2663':
            return 0x05;
        case '\u2660':
            return 0x06;
        case '\u2022':
            return 0x07;
        case '\u25D8':
            return 0x08;
        case '\u25CB':
            return 0x09;
        case '\u25D9':
            return 0x0A;
        case '\u2642':
            return 0x0B;
        case '\u2640':
            return 0x0C;
        case '\u266A':
            return 0x0D;
        case '\u266B':
            return 0x0E;
        case '\u263C':
            return 0x0F;
        case '\u25BA':
            return 0x10;
        case '\u25C4':
            return 0x11;
        case '\u2195':
            return 0x12;
        case '\u203C':
            return 0x13;
        case '\u00B6':
            return 0x14;
        case '\u00A7':
            return 0x15;
        case '\u25AC':
            return 0x16;
        case '\u21A8':
            return 0x17;
        case '\u2191':
            return 0x18;
        case '\u2193':
            return 0x19;
        case '\u2192':
            return 0x1A;
        case '\u2190':
            return 0x1B;
        case '\u221F':
            return 0x1C;
        case '\u2194':
            return 0x1D;
        case '\u25B2':
            return 0x1E;
        case '\u25BC':
            return 0x1F;
        case '\u2302':
            return 0x7F;
        case '\u03B2':
            return 0xE1;
        case '\u03A0':
        case '\u220F':
            return 0xE3;
        case '\u2211':
            return 0xE4;
        case '\u03BC':
            return 0xE6;
        case '\u2126':
            return 0xEA;
        case '\u00F0':
        case '\u2202':
            return 0xEB;
        case '\u2205':
        case '\u03D5':
        case '\u2300':
        case '\u00F8':
            return 0xED;
        case '\u2208':
        case '\u20AC':
            return 0xEE;
        default:
        {
            uint result = topPageTranslationMap.get(character, 0);
            if(result != 0)
                return result;
            return cast(uint)'?';
        }
        }
    }

    private static Mesh[256] charMesh;
    private static bool didInit = false;

    private static void init()
    {
        if(didInit)
            return;
        didInit = true;
        foreach(uint i, ref Mesh mesh; charMesh)
        {
            int left = (i % (textureXRes / fontWidth)) * fontWidth;
            int top = (i / (textureXRes / fontWidth)) * fontHeight;
            const int width = fontWidth;
            const int height = fontHeight;
            float minU = (left + pixelOffset) / textureXRes;
            float maxU = (left + width - pixelOffset) / textureXRes;
            float minV = 1 - (top + height - pixelOffset) / textureYRes;
            float maxV = 1 - (top + pixelOffset) / textureYRes;
            TextureDescriptor texture = Font.tdNoOffset.subTexture(minU, maxU, minV, maxV);
            mesh = Generate.quadrilateral(texture, Vector.ZERO, Color.WHITE, Vector.X, Color.WHITE, Vector.XY, Color.WHITE, Vector.Y, Color.WHITE).seal();
        }
    }

    private static void renderChar(Mesh dest, Matrix transform, Color color, dchar ch)
    {
        init();
        dest.add(TransformedMesh(charMesh[translateToCodePage437(ch)], transform), color);
    }

    private static void updateFromChar(ref uint x, ref uint y, ref uint w, ref uint h, uint tabWidth, dchar ch)
    {
        if(ch == '\n')
        {
            x = 0;
            y++;
        }
        else if(ch == '\r')
        {
            x = 0;
        }
        else if(ch == '\t')
        {
            x += tabWidth - x % tabWidth;
        }
        else if(ch == ' ')
        {
            x++;
        }
        else
        {
            x++;
            if(x > w)
                w = x;
            if(y + 1 > h)
                h = y + 1;
        }
    }

    public static uint width(in const(char)[] text, uint tabWidth = 8)
    {
        uint x = 0, y = 0, w = 0, h = 0;
        foreach(dchar ch; text)
        {
            updateFromChar(x, y, w, h, tabWidth, ch);
        }
        return w;
    }

    public static uint height(in const(char)[] text, uint tabWidth = 8)
    {
        uint x = 0, y = 0, w = 0, h = 0;
        foreach(dchar ch; text)
        {
            updateFromChar(x, y, w, h, tabWidth, ch);
        }
        return h;
    }

    public static uint xPos(in const(char)[] text, uint tabWidth = 8)
    {
        uint x = 0, y = 0, w = 0, h = 0;
        foreach(dchar ch; text)
        {
            updateFromChar(x, y, w, h, tabWidth, ch);
        }
        return x;
    }

    public static uint yPos(in const(char)[] text, uint tabWidth = 8)
    {
        uint x = 0, y = 0, w = 0, h = 0;
        foreach(dchar ch; text)
        {
            updateFromChar(x, y, w, h, tabWidth, ch);
        }
        return h - y - 1;
    }

    public static Mesh render(Mesh dest, Matrix transform, Color color, in const(char)[] text, uint tabWidth = 8)
    {
        uint x = 0, y = 0, w = 0, h = 0;
        uint totalHeight = height(text, tabWidth);
        foreach(dchar ch; text)
        {
            renderChar(dest, Matrix.translate(x, totalHeight - y - 1, 0).concat(transform), color, ch);
            updateFromChar(x, y, w, h, tabWidth, ch);
        }
        return dest;
    }
}
