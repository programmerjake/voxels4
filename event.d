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
module event;

private import platform;

public interface EventHandler
{
	/**
	 * Returns:
	 * if this event handler handled the event
	 */
    public bool handleMouseUp(MouseUpEvent event);/// ditto
    public bool handleMouseDown(MouseDownEvent event);/// ditto
    public bool handleMouseMove(MouseMoveEvent event);/// ditto
    public bool handleMouseScroll(MouseScrollEvent event);/// ditto
    public bool handleKeyUp(KeyUpEvent event);/// ditto
    public bool handleKeyDown(KeyDownEvent event);/// ditto
    public bool handleKeyPress(KeyPressEvent event);/// ditto
    public bool handleQuit(QuitEvent event);/// ditto
}

public final class CombinedEventHandler : EventHandler
{
	private EventHandler first, second;
	public this(EventHandler first, EventHandler second)
	{
		this.first = first;
		this.second = second;
	}
    public bool handleMouseUp(MouseUpEvent event)
    {
		if(first.handleMouseUp(event))
			return true;
		return second.handleMouseUp(event);
	}
    public bool handleMouseDown(MouseDownEvent event)
    {
		if(first.handleMouseDown(event))
			return true;
		return second.handleMouseDown(event);
	}
    public bool handleMouseMove(MouseMoveEvent event)
    {
		if(first.handleMouseMove(event))
			return true;
		return second.handleMouseMove(event);
	}
    public bool handleMouseScroll(MouseScrollEvent event)
    {
		if(first.handleMouseScroll(event))
			return true;
		return second.handleMouseScroll(event);
	}
    public bool handleKeyUp(KeyUpEvent event)
    {
		if(first.handleKeyUp(event))
			return true;
		return second.handleKeyUp(event);
	}
    public bool handleKeyDown(KeyDownEvent event)
    {
		if(first.handleKeyDown(event))
			return true;
		return second.handleKeyDown(event);
	}
    public bool handleKeyPress(KeyPressEvent event)
    {
		if(first.handleKeyPress(event))
			return true;
		return second.handleKeyPress(event);
	}
    public bool handleQuit(QuitEvent event)
    {
		if(first.handleQuit(event))
			return true;
		return second.handleQuit(event);
	}
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
    public abstract bool dispatch(EventHandler eventHandler);
}

public class MouseEvent : Event
{
    public immutable float x, y;
	public immutable float deltaX, deltaY;
    protected this(Type type, float x, float y, float deltaX, float deltaY)
    {
        super(type);
        this.x = x;
        this.y = y;
        this.deltaX = deltaX;
        this.deltaY = deltaY;
    }
}

public class KeyEvent : Event
{
    public immutable KeyboardKey key;
    public immutable KeyboardModifiers mods;
    protected this(Type type, KeyboardKey key, KeyboardModifiers mods)
    {
        super(type);
        this.key = key;
        this.mods = mods;
    }
}

public class KeyDownEvent : KeyEvent
{
	public immutable bool isRepetition;
	public this(KeyboardKey key, KeyboardModifiers mods, bool isRepetition = false)
	{
		super(Type.KeyDown, key, mods);
		this.isRepetition = isRepetition;
	}
	public override bool dispatch(EventHandler eventHandler)
	{
		return eventHandler.handleKeyDown(this);
	}
}

public class KeyUpEvent : KeyEvent
{
	public this(KeyboardKey key, KeyboardModifiers mods)
	{
		super(Type.KeyUp, key, mods);
	}
	public override bool dispatch(EventHandler eventHandler)
	{
		return eventHandler.handleKeyUp(this);
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
	public override bool dispatch(EventHandler eventHandler)
	{
		return eventHandler.handleKeyPress(this);
	}
}

public class MouseButtonEvent : MouseEvent
{
	public immutable MouseButton button;
	protected this(Type type, float x, float y, float deltaX, float deltaY, MouseButton button)
	{
		super(type, x, y, deltaX, deltaY);
		this.button = button;
	}
}

public class MouseUpEvent : MouseButtonEvent
{
    public this(float x, float y, float deltaX, float deltaY, MouseButton button)
    {
        super(Type.MouseUp, x, y, deltaX, deltaY, button);
    }

    public override bool dispatch(EventHandler eventHandler)
    {
        return eventHandler.handleMouseUp(this);
    }
}

public class MouseDownEvent : MouseButtonEvent
{
    public this(float x, float y, float deltaX, float deltaY, MouseButton button)
    {
        super(Type.MouseDown, x, y, deltaX, deltaY, button);
    }

    public override bool dispatch(EventHandler eventHandler)
    {
        return eventHandler.handleMouseDown(this);
    }
}

public class MouseMoveEvent : MouseEvent
{
    public this(float x, float y, float deltaX, float deltaY)
    {
        super(Type.MouseMove, x, y, deltaX, deltaY);
    }

    public override bool dispatch(EventHandler eventHandler)
    {
        return eventHandler.handleMouseMove(this);
    }
}

public class MouseScrollEvent : MouseEvent
{
    public immutable int scrollX, scrollY;
    public this(float x, float y, float deltaX, float deltaY, int scrollX, int scrollY)
    {
        super(Type.MouseScroll, x, y, deltaX, deltaY);
        this.scrollX = scrollX;
        this.scrollY = scrollY;
    }

    public override bool dispatch(EventHandler eventHandler)
    {
        return eventHandler.handleMouseScroll(this);
    }
}

public class QuitEvent : Event
{
	public this()
	{
		super(Type.Quit);
	}
	public override bool dispatch(EventHandler eventHandler)
	{
		return eventHandler.handleQuit(this);
	}
}
