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
import resource.texture_atlas;
import entity.block;
import render.text;
import render.generate;
import block.anim_test;

void dumpPixel(int x, int y)
{
    Color c = TextureAtlas.texture.getPixel(x, y);
    writefln("%s, %s : %s, %s, %s, %s", x, y, c.rf, c.gf, c.bf, c.af);
}

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
                if(abs(x) == 3 && abs(z) == 3 && y < 60 && y >= 55)
                    w.setBlock(x, y, z, Dimension.Overworld, BlockData(BlockAnimTest.BLOCK_ANIM_TEST));
                else if((x * x + (y - 64) * (y - 64) + z * z < 10 * 10 && x >= -1) || y >= 64)
                    w.setBlock(x, y, z, Dimension.Overworld, BlockData(Air.AIR));
                else if(y >= 61)
                    w.setBlock(x, y, z, Dimension.Overworld, BlockData(Stone.STONE));
                else
                    w.setBlock(x, y, z, Dimension.Overworld, BlockData(Bedrock.BEDROCK));
            }
        }
    }
    w.advanceTime(0);
    bool doMove = false;
    string title = "";
    Mesh textMesh = new Mesh();
    Mesh textInvMesh = new Mesh();
    while(!done)
    {
		Display.initFrame();
		w.draw(Vector(0.5, 65.5, 0.5), ((Display.timer * 0.03) % 1) * (PI * 2), -PI / 4, Dimension.Overworld);
		Display.initOverlay();
		textMesh.clear();
		const float textDistance = 20.0;
		Text.render(textMesh, Matrix.translate(-textDistance * Display.scaleX, textDistance * Display.scaleY - Text.height(title), -textDistance), Color.GREEN, title);
		Renderer.render(textMesh);
		Renderer.render(invert(textInvMesh, textMesh));
		Display.flip();
		Display.handleEvents(null);
		if(doMove)
            w.advanceTime(Display.frameDeltaTime);
        else
            doMove = true;
		static float i = 0;
		i += 1.0;
		if(i >= Display.averageFPS * 0.1)
		{
			i -= Display.averageFPS * 0.1;
			title = format("FPS : %g", Display.averageFPS);
			static bool type = false;
			type = !type;
            w.addEntity(BlockEntity.make(Vector(0.5, 66, 0.5), vrandom(), Dimension.Overworld, BlockData(Stone.STONE)));
		}
	}
	return 0;
}
