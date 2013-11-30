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
module world.block_face;

public enum BlockFace
{
    NX, PX, NY, PY, NZ, PZ
}

public @property int dx(const BlockFace f)
{
    switch(f)
    {
    case BlockFace.NX:
        return -1;
    case BlockFace.PX:
        return 1;
    default:
        return 0;
    }
}

public @property int dy(const BlockFace f)
{
    switch(f)
    {
    case BlockFace.NY:
        return -1;
    case BlockFace.PY:
        return 1;
    default:
        return 0;
    }
}

public @property int dz(const BlockFace f)
{
    switch(f)
    {
    case BlockFace.NZ:
        return -1;
    case BlockFace.PZ:
        return 1;
    default:
        return 0;
    }
}

