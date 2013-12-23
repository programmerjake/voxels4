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
    private Player player = null;
    public this()
    {
        events = new LinkedList!PlayerInputEvent();
    }

    public void setPlayer(Player player)
    {
        assert(player !is null);
        assert(this.player is null);
        this.player = player;
    }

    public void initMode()
    {
        Display.grabMouse = true;
        Display.handleEvents(null);
    }

    public PlayerInputEvent nextEvent()
    {
        if(events.empty)
            return null;
        return events.removeFront();
    }

    private bool sneakButton_ = false;
    private bool attackButton_ = false;
    private bool motionForward_ = false;
    private bool motionBack_ = false;
    private bool motionLeft_ = false;
    private bool motionRight_ = false;
    private bool spaceDown = false;

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
        return spaceDown && !sneakButton;
    }

    public @property bool motionDown()
    {
        return sneakButton && !spaceDown;
    }

    public @property bool motionForward()
    {
        return motionForward_ && !motionBack_;
    }

    public @property bool motionBack()
    {
        return motionBack_ && !motionForward_;
    }

    public @property bool motionLeft()
    {
        return motionLeft_ && !motionRight_;
    }

    public @property bool motionRight()
    {
        return motionRight_ && !motionLeft_;
    }

    private bool flyMode_ = false;

    public @property bool flyMode()
    {
        return flyMode_ && creativeMode;
    }

    private bool creativeMode_ = false;

    public @property bool creativeMode()
    {
        return creativeMode_;
    }

    public @property void creativeMode(bool v)
    {
        creativeMode_ = v;
        if(!creativeMode_)
        {
            flyMode_ = false;
        }
    }

    private double lastSpaceDownTime = -1;
    private static immutable double spaceDoubleTapTime = 0.25;

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

    private static immutable bool smoothMouse = true;

    private float lastDeltaX = 0, lastDeltaY = 0, deltaX = 0, deltaY = 0;

    public void move()
    {
        if(smoothMouse)
        {
            float newDeltaX = deltaX / 2 + lastDeltaX / 2;
            lastDeltaX = lastDeltaX / 2 + deltaX / 2;
            float newDeltaY = deltaY / 2 + lastDeltaY / 2;
            lastDeltaY = lastDeltaY / 2 + deltaY / 2;
            deltaX = newDeltaX;
            deltaY = newDeltaY;
        }
        addEvent(new PlayerInputEvent.ViewChange(deltaX, deltaY));
        deltaX = 0;
        deltaY = 0;
    }

    public bool handleMouseMove(MouseMoveEvent event)
    {
        const float sensitivity = 1.0 / 300;
        deltaX += event.deltaX * sensitivity;
        deltaY += -event.deltaY * sensitivity;
        //TODO(jacob#):finish
        return false;
    }

    public bool handleMouseScroll(MouseScrollEvent event)
    {
        //TODO(jacob#):finish
        if(event.scrollY == 0)
        {
            if(event.scrollX < 0)
                addEvent(new PlayerInputEvent.HotBarMoveLeft());
            else if(event.scrollX > 0)
                addEvent(new PlayerInputEvent.HotBarMoveRight());
        }
        else if(event.scrollY < 0)
            addEvent(new PlayerInputEvent.HotBarMoveLeft());
        else //if(event.scrollY > 0)
            addEvent(new PlayerInputEvent.HotBarMoveRight());
        return false;
    }

    public bool handleKeyUp(KeyUpEvent event)
    {
        //TODO(jacob#):finish
        if(event.key == KeyboardKey.LShift)
            sneakButton_ = false;
        if(event.key == KeyboardKey.Space)
            spaceDown = false;
        if(event.key == KeyboardKey.W)
            motionForward_ = false;
        if(event.key == KeyboardKey.S)
            motionBack_ = false;
        if(event.key == KeyboardKey.A)
            motionLeft_ = false;
        if(event.key == KeyboardKey.D)
            motionRight_ = false;
        return false;
    }

    public bool handleKeyDown(KeyDownEvent event)
    {
        //TODO(jacob#):finish
        if(event.key == KeyboardKey.LShift)
            sneakButton_ = true;
        if(event.key == KeyboardKey.Space)
        {
            if(!spaceDown)
            {
                addEvent(new PlayerInputEvent.Jump());
                if(lastSpaceDownTime < 0)
                {
                    lastSpaceDownTime = Display.timer;
                }
                else if(lastSpaceDownTime + spaceDoubleTapTime >= Display.timer)
                {
                    if(creativeMode)
                    {
                        flyMode_ = !flyMode_;
                    }
                    lastSpaceDownTime = -1;
                }
                else
                {
                    lastSpaceDownTime = Display.timer;
                }
            }
            spaceDown = true;
        }
        if(event.key == KeyboardKey.W)
            motionForward_ = true;
        if(event.key == KeyboardKey.S)
            motionBack_ = true;
        if(event.key == KeyboardKey.A)
            motionLeft_ = true;
        if(event.key == KeyboardKey.D)
            motionRight_ = true;
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
