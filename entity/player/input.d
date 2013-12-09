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
module entity.player.input;
public import entity.player.player;
import event;
import util;
import platform;

public final class DefaultPlayerInput : PlayerInput, EventHandler
{
    private LinkedList!PlayerInputEvent events;
    public this()
    {
        events = new LinkedList!PlayerInputEvent();
    }

    public void initMode()
    {
        Display.grabMouse = true;
    }

    public PlayerInputEvent nextEvent()
    {
        if(events.empty)
            return null;
        return events.removeFront();
    }

    private void addEvent(PlayerInputEvent event)
    {
        events.addBack(event);
    }

    public void drawOverlay()
    {
        //TODO(jacob#):finish
    }

    public bool handleMouseUp(MouseUpEvent event)
    {
        if(event.button == MouseButton.Left)
            addEvent(new PlayerInputEvent.AttackButtonUp());
        //TODO(jacob#):finish
        return false;
    }

    public bool handleMouseDown(MouseDownEvent event)
    {
        if(event.button == MouseButton.Left)
            addEvent(new PlayerInputEvent.AttackButtonDown());
        if(event.button == MouseButton.Right)
            addEvent(new PlayerInputEvent.UseButtonPress());
        //TODO(jacob#):finish
        return false;
    }

    public bool handleMouseMove(MouseMoveEvent event)
    {
        const float sensitivity = 1.0 / 300;
        addEvent(new PlayerInputEvent.ViewChange(event.deltaX * sensitivity, -event.deltaY * sensitivity));
        //TODO(jacob#):finish
        return false;
    }

    public bool handleMouseScroll(MouseScrollEvent event)
    {
        //TODO(jacob#):finish
        return false;
    }

    public bool handleKeyUp(KeyUpEvent event)
    {
        //TODO(jacob#):finish
        return false;
    }

    public bool handleKeyDown(KeyDownEvent event)
    {
        //TODO(jacob#):finish
        return false;
    }

    public bool handleKeyPress(KeyPressEvent event)
    {
        //TODO(jacob#):finish
        return false;
    }

    public bool handleQuit(QuitEvent event)
    {
        return false;
    }
}
