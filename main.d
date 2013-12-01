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

int main(string[] args)
{
    bool done = false;
    while(!done)
    {
		glClearColor(0, 0, 0, 0);
		glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
		Display.initFrame();
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
