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
module main;

import platform;
import event;
import std.string;
import world.world;
import block.block;
import block.air;
import block.stone.bedrock;
import block.stone.stone;
import matrix;
import std.conv;
import std.stdio;
import std.math;
import vector;

int main(string[] args)
{
    bool done = false;
    World w = new World();
    for(int x = -20; x <= 20; x++)
    {
        for(int y = 0; y < World.MAX_HEIGHT; y++)
        {
            for(int z = -20; z <= 20; z++)
            {
                if(x * x + (y - 64) * (y - 64) + z * z < 5 * 5 || y >= 65)
                    w.setBlock(x, y, z, Dimension.Overworld, BlockData(Air.AIR));
                else if(y >= 64)
                    w.setBlock(x, y, z, Dimension.Overworld, BlockData(Stone.STONE));
                else
                    w.setBlock(x, y, z, Dimension.Overworld, BlockData(Bedrock.BEDROCK));
            }
        }
    }
    while(!done)
    {
		Display.initFrame();
		w.draw(Vector(0.5, 65.5, 0.5), ((Display.timer * 0.03) % 1) * (PI * 2), -PI / 6, Dimension.Overworld);
		Display.flip();
		Display.handleEvents(null);
		static int i = 0;
		if(++i >= Display.averageFPS)
		{
			i = 0;
			Display.title = format("FPS : %g", Display.averageFPS);
		}
	}
	return 0;
}
