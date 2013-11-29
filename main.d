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

import std.stdio;
import platform;
import event;
import file.stream;
import core.time;
import std.string;
import std.math;
import resource.texture_atlas;
import matrix;
import render.mesh;
import render.generate;
import render.texture_descriptor;
import std.c.stdlib;

private Mesh makeMesh()
{
    srand(1);
	Mesh retval = new Mesh();
	immutable int size = 5;
	for(int x=-size;x<=size;x++)
	{
		for(int y=-size;y<=size;y++)
		{
			for(int z=-size;z<=size;z++)
			{
			    TextureDescriptor woodSide;
			    switch(rand() % 4)
			    {
                case 0:
                    woodSide = TextureAtlas.OakWood.td;
                    break;
                case 1:
                    woodSide = TextureAtlas.BirchWood.td;
                    break;
                case 2:
                    woodSide = TextureAtlas.SpruceWood.td;
                    break;
                default:
                    woodSide = TextureAtlas.JungleWood.td;
			    }
				retval.add(Generate.unitBox(
							x == -size ? woodSide : TextureDescriptor(),
							x == size ? woodSide : TextureDescriptor(),
							y == -size ? TextureAtlas.WoodEnd.td : TextureDescriptor(),
							y == size ? TextureAtlas.WoodEnd.td : TextureDescriptor(),
							z == -size ? woodSide : TextureDescriptor(),
							z == size ? woodSide : TextureDescriptor()).transform(Matrix.translate(x, y, z)));
			}
		}
	}
	return retval.transform(Matrix.translate(-0.5, -0.5, -0.5));
}

private void dumpMesh(Mesh mesh)
{
	writefln("mesh : %s", mesh);
	writefln("    length : %s", mesh.length);
	writefln("    texture : %s", mesh.texture);
	foreach(int i, Triangle t; mesh)
	{
		writefln("    mesh[%s] =\n    {", i);
		for(int j=0;j<3;j++)
			writefln("        <%f, %f, %f> <%f, %f, %f, %f> <%f, %f>", t.p[j].x, t.p[j].y, t.p[j].z, t.c[j].rf, t.c[j].gf, t.c[j].bf, t.c[j].af, t.u[j], t.v[j]);
		writefln("    }");
	}
	writefln("\n");
}

int main(string[] args)
{
    bool done = false;
    Mesh theMesh = makeMesh().seal();
    Mesh curMesh;
    while(!done)
    {
		glClearColor(0, 0, 0, 0);
		glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
		Display.initFrame();
		Matrix worldToCamera = Matrix.rotateX(Display.timer / 10).concat(Matrix.rotateY(Display.timer * 2.1 / 10)).concat(Matrix.translate(0, 0, -10 * sqrt(3)));
		curMesh = (new Mesh(theMesh)).transform(worldToCamera);
		Renderer.render(curMesh);
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
