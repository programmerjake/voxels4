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
import entity.player.player;
import entity.player.input;
import persistance.game_version;

void dumpPixel(int x, int y)
{
    Color c = TextureAtlas.texture.getPixel(x, y);
    writefln("%s, %s : %s, %s, %s, %s", x, y, c.rf, c.gf, c.bf, c.af);
}

int main(string[] args)
{
    bool done = false;
    World w = new World();
    auto playerInput = new DefaultPlayerInput();
    const int size = 20;
    for(int x = -size; x <= size; x++)
    {
        for(int y = 0; y < World.MAX_HEIGHT; y++)
        {
            Display.title = format("Building World : %s%%", 100.0 * (x + size + cast(float)y / World.MAX_HEIGHT) / (size * 2 + 1));
            Display.handleEvents(null);
            for(int z = -size; z <= size; z++)
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
            w.advanceTime(0);
        }
    }
    Player player = Player.make("", playerInput, Vector(0.5, 65.5, 0.5), Dimension.Overworld);
    playerInput.setPlayer(player);
    w.addEntity(player.data);
    w.advanceTime(0);
    Display.title = "Voxels " ~ GameVersion.VERSION;
    w.viewDistance = 48;
    playerInput.creativeMode = true;
    //playerInput.initMode();
    bool doMove = false;
    string title = "";
    Mesh textMesh = new Mesh();
    while(!done)
    {
		Display.initFrame();
		player.drawAll(w);
		Display.initOverlay();
		textMesh.clear();
		const float textDistance = 20.0;
		Text.render(textMesh, Matrix.translate(-textDistance * Display.scaleX, textDistance * Display.scaleY - Text.height(title), -textDistance), Color.GREEN, title);
		Renderer.render(textMesh);
		Display.flip();
		Display.handleEvents(playerInput);
		if(doMove)
            w.advanceTime(Display.frameDeltaTime);
        else
            doMove = true;
		static float i = 0;
		i += 1.0;
		while(i >= Display.averageFPS * 0.5)
		{
			i -= Display.averageFPS * 0.5;
			title = format("FPS : %g", Display.averageFPS);
			static bool type = false;
			type = !type;
            w.addEntity(BlockEntity.make(Vector(0.5, 65, 0.5), vrandom() * 0.5, Dimension.Overworld, BlockData(Stone.STONE)));
		}
	}
	return 0;
}
