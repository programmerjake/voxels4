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
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 * 
 */
module event;

public interface EventHandler
{
    public void handleMouseUp(MouseUpEvent event);
    public void handleMouseDown(MouseDownEvent event);
    public void handleMouseMove(MouseMoveEvent event);
    public void handleMouseScroll(MouseScrollEvent event);
    public void handleKeyUp(KeyUpEvent event);
    public void handleKeyDown(KeyDownEvent event);
    public void handleKeyPress(KeyPressEvent event);
    public void handleQuit(QuitEvent event);
}

public class Event
{
    public enum Type
    {
        MouseUp,
        MouseDown,
        MouseMove,
        MouseScroll,
        KeyUp,
        KeyDown,
        KeyPress,
        Quit,
    }
    public immutable Type type;
    protected this(Type type)
    {
        this.type = type;
    }
    public abstract void dispatch(EventHandler eventHandler);
}

public class MouseEvent : Event
{
    public immutable float x, y;
    protected this(Type type, float x, float y)
    {
        super(type);
        this.x = x;
        this.y = y;
    }
}

public class KeyEvent : Event
{
    public immutable KeyboardKey key;
    protected this(Type type, KeyboardKey key)
    {
        super(type);
        this.key = key;
    }
}

public class KeyDownEvent : KeyEvent
{
	public immutable bool isRepetition;
	public this(KeyboardKey key, bool isRepetition = false)
	{
		super(Type.KeyDown, key);
		this.isRepetition = isRepetition;
	}
	public override void dispatch(EventHandler eventHandler)
	{
		eventHandler.handleKeyDown(this);
	}
}

public class KeyUpEvent : KeyEvent
{
	public this(KeyboardKey key)
	{
		super(Type.KeyUp, key);
	}
	public override void dispatch(EventHandler eventHandler)
	{
		eventHandler.handleKeyUp(this);
	}
}

public class KeyPressEvent : Event
{
	public immutable wchar character;
	public this(wchar character)
	{
		super(Type.KeyPress);
		this.character = character;
	}
	public override void dispatch(EventHandler eventHandler)
	{
		eventHandler.handleKeyPress(this);
	}
}

public class MouseButtonEvent : MouseEvent
{
	public immutable MouseButton button;
	protected this(Type type, float x, float y, MouseButton button)
	{
		super(type, x, y);
		this.button = button;
	}
}

public class MouseUpEvent : MouseButtonEvent
{
    public this(float x, float y, MouseButton button)
    {
        super(Type.MouseUp, x, y, button);
    }

    public void dispatch(EventHandler eventHandler)
    {
        eventHandler.handleMouseUp(this);
    }
}

public class MouseDownEvent : MouseButtonEvent
{
    public this(float x, float y, MouseButton button)
    {
        super(Type.MouseDown, x, y, button);
    }

    public void dispatch(EventHandler eventHandler)
    {
        eventHandler.handleMouseDown(this);
    }
}

public class MouseMoveEvent : MouseEvent
{
    public this(float x, float y)
    {
        super(Type.MouseMove, x, y);
    }

    public void dispatch(EventHandler eventHandler)
    {
        eventHandler.handleMouseMove(this);
    }
}

public class MouseScrollEvent : MouseEvent
{
    public immutable int scrollX, scrollY;
    public this(float x, float y, int scrollX, int scrollY)
    {
        super(Type.MouseScroll, x, y);
        this.scrollX = scrollX;
        this.scrollY = scrollY;
    }

    public void dispatch(EventHandler eventHandler)
    {
        eventHandler.handleMouseScroll(this);
    }
}

public class QuitEvent : Event
{
	public this()
	{
		super(Type.Quit);
	}
	public void dispatch(EventHandler eventHandler)
	{
		eventHandler.handleQuit(this);
	}
}
