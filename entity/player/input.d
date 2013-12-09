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

    private bool sneakButton_ = false;
    private bool attackButton_ = false;
    private bool motionUp_ = false;
    private bool motionDown_ = false;
    private bool motionForward_ = false;
    private bool motionBack_ = false;
    private bool motionLeft_ = false;
    private bool motionRight_ = false;

    public @property bool sneakButton()
    {
        return sneakButton_;
    }

    public @property bool attackButton()
    {
        return attackButton_;
    }

    public @property bool motionUp()
    {
        return motionUp_;
    }

    public @property bool motionDown()
    {
        return motionDown_;
    }

    public @property bool motionForward()
    {
        return motionForward_;
    }

    public @property bool motionBack()
    {
        return motionBack_;
    }

    public @property bool motionLeft()
    {
        return motionLeft_;
    }

    public @property bool motionRight()
    {
        return motionRight_;
    }

    private void addEvent(PlayerInputEvent event)
    {
        events.addBack(event);
    }

    public void drawOverlay(Player p)
    {
        //TODO(jacob#):finish
    }

    public bool handleMouseUp(MouseUpEvent event)
    {
        if(event.button == MouseButton.Left)
            attackButton_ = false;
        //TODO(jacob#):finish
        return false;
    }

    public bool handleMouseDown(MouseDownEvent event)
    {
        if(event.button == MouseButton.Left)
        {
            attackButton_ = true;
            addEvent(new PlayerInputEvent.AttackButtonDown());
        }
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
