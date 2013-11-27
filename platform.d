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
module platform;

public import derelict.sdl.sdl;
public import derelict.opengl.gl;
public import derelict.ogg.ogg;
public import derelict.ogg.vorbis;
public import derelict.sdl.image;
private import std.string;
private import std.file;
private import std.path;
private import core.runtime;
private import core.time;
private import core.thread;
private import std.conv;

public immutable(string) ResourcePrefix;

static this()
{
	string exePath = absolutePath(Runtime.args[0]);
	ResourcePrefix = absolutePath(buildNormalizedPath(dirName(exePath), "res"));
}

private
{
	import event;
	import std.exception;
	import core.runtime;
	import std.c.stdlib;
	const shared Object SDLSyncObject;
	static this()
	{
		SDLSyncObject = new shared(const(Object))();
 	}
}

public shared(const(Object)) getSDLSyncObject()
{
	return SDLSyncObject;
}

public bool isOpenGLLoaded()
{
	return needSDLQuit && DerelictGL.isLoaded();
}

private immutable int ImageDecoderFlags = IMG_INIT_PNG;

static this()
{
	DerelictSDL.load();
	DerelictGL.load();
	DerelictVorbis.load();
	DerelictSDLImage.load();
	enforceSDL(0 == SDL_Init(SDL_INIT_TIMER | SDL_INIT_VIDEO | SDL_INIT_AUDIO), "can't start SDL : %s");
	needSDLQuit = true;
	enforceIMG(ImageDecoderFlags == (ImageDecoderFlags & IMG_Init(ImageDecoderFlags)), "can't start SDLImage : %s");
	needIMGQuit = true;
	enforceSDL(0 == SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8), "can't call SDL_GL_SetAttribute : %s");
	enforceSDL(0 == SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8), "can't call SDL_GL_SetAttribute : %s");
	enforceSDL(0 == SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8), "can't call SDL_GL_SetAttribute : %s");
	enforceSDL(0 == SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24), "can't call SDL_GL_SetAttribute : %s");
	enforceSDL(0 == SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1), "can't call SDL_GL_SetAttribute : %s");
	videoSurface = cast(shared SDL_Surface *)SDL_SetVideoMode(640, 480, 32, SDL_OPENGL);
	enforceSDL(videoSurface != null, "can't set video mode : %s");
	SDL_EnableUNICODE(1);
	enforceSDL(0 == SDL_EnableKeyRepeat(SDL_DEFAULT_REPEAT_DELAY, SDL_DEFAULT_REPEAT_INTERVAL), "can't call SDL_EnableKeyRepeat : %s");
}

private static shared bool needSDLQuit = false, needIMGQuit = false;
private static shared SDL_Surface * videoSurface = null;

private void enforceSDL(lazy bool value, string msg)
{
	enforce(value, format(msg, SDL_GetError()));
}

private void enforceIMG(lazy bool value, string msg)
{
	enforce(value, format(msg, IMG_GetError()));
}

private shared TickDuration lastFlipTime;

private shared TickDuration oldLastFlipTime;

public immutable float defaultFPS = 60;

static this()
{
	lastFlipTime = TickDuration.currSystemTick;
	immutable float fps = defaultFPS;
	oldLastFlipTime = cast(TickDuration)(cast(Duration)*cast(TickDuration *)&lastFlipTime - dur!"hnsecs"(cast(long)(1e7 / fps)));
}

private @property double instantaneousFPS()
{
	synchronized(FPSSyncObject)
	{
		long hnsecs = (*cast(TickDuration *)&lastFlipTime - *cast(TickDuration *)&oldLastFlipTime).hnsecs();
		if(hnsecs <= 0)
			return averageFPSInternal;
		return 1e7 / hnsecs;
	}
}

private shared float averageFPSInternal = defaultFPS;
private immutable float FPSUpdateFactor = 0.1f;
private immutable shared Object FPSSyncObject;

private @property float averageFPS()
{
	synchronized(FPSSyncObject)
	{
		return averageFPSInternal;
	}
}

static this()
{
	FPSSyncObject = new immutable(Object)();
}

private void flipDisplay(float fps = defaultFPS)
{
	synchronized(SDLSyncObject)
	{
		Duration sleepTime;
		synchronized(FPSSyncObject)
		{
			TickDuration curTime = TickDuration.currSystemTick;
			sleepTime = dur!"hnsecs"(cast(long)(1e7 / fps)) - (curTime - lastFlipTime);
			if(sleepTime <= dur!"hnsecs"(0))
			{
				oldLastFlipTime = lastFlipTime;
				lastFlipTime = curTime;
				averageFPSInternal *= 1 - FPSUpdateFactor;
				averageFPSInternal += FPSUpdateFactor * instantaneousFPS;
			}
		}
		if(sleepTime > dur!"hnsecs"(0))
		{
			Thread.sleep(sleepTime);
			synchronized(FPSSyncObject)
			{
				oldLastFlipTime = lastFlipTime;
				lastFlipTime = TickDuration.currSystemTick;
				averageFPSInternal *= 1 - FPSUpdateFactor;
				averageFPSInternal += FPSUpdateFactor * instantaneousFPS;
			}
		}
		SDL_GL_SwapBuffers();
	}
}

private KeyboardKey translateKey(SDLKey input)
{
	switch(input)
	{
	case SDLK_BACKSPACE:
		return KeyboardKey.Backspace;
	case SDLK_TAB:
		return KeyboardKey.Tab;
	case SDLK_CLEAR:
		return KeyboardKey.Clear;
	case SDLK_RETURN:
		return KeyboardKey.Return;
	case SDLK_PAUSE:
		return KeyboardKey.Pause;
	case SDLK_ESCAPE:
		return KeyboardKey.Escape;
	case SDLK_SPACE:
		return KeyboardKey.Space;
	case SDLK_EXCLAIM:
		return KeyboardKey.EMark;
	case SDLK_QUOTEDBL:
		return KeyboardKey.DQuote;
	case SDLK_HASH:
		return KeyboardKey.Pound;
	case SDLK_DOLLAR:
		return KeyboardKey.Dollar;
	case SDLK_AMPERSAND:
		return KeyboardKey.Amp;
	case SDLK_QUOTE:
		return KeyboardKey.SQuote;
	case SDLK_LEFTPAREN:
		return KeyboardKey.LParen;
	case SDLK_RIGHTPAREN:
		return KeyboardKey.RParen;
	case SDLK_ASTERISK:
		return KeyboardKey.Star;
	case SDLK_PLUS:
		return KeyboardKey.Plus;
	case SDLK_COMMA:
		return KeyboardKey.Comma;
	case SDLK_MINUS:
		return KeyboardKey.Dash;
	case SDLK_PERIOD:
		return KeyboardKey.Period;
	case SDLK_SLASH:
		return KeyboardKey.FSlash;
	case SDLK_0:
		return KeyboardKey.Num0;
	case SDLK_1:
		return KeyboardKey.Num1;
	case SDLK_2:
		return KeyboardKey.Num2;
	case SDLK_3:
		return KeyboardKey.Num3;
	case SDLK_4:
		return KeyboardKey.Num4;
	case SDLK_5:
		return KeyboardKey.Num5;
	case SDLK_6:
		return KeyboardKey.Num6;
	case SDLK_7:
		return KeyboardKey.Num7;
	case SDLK_8:
		return KeyboardKey.Num8;
	case SDLK_9:
		return KeyboardKey.Num9;
	case SDLK_COLON:
		return KeyboardKey.Colon;
	case SDLK_SEMICOLON:
		return KeyboardKey.Semicolon;
	case SDLK_LESS:
		return KeyboardKey.LAngle;
	case SDLK_EQUALS:
		return KeyboardKey.Equals;
	case SDLK_GREATER:
		return KeyboardKey.RAngle;
	case SDLK_QUESTION:
		return KeyboardKey.QMark;
	case SDLK_AT:
		return KeyboardKey.AtSign;
	case SDLK_LEFTBRACKET:
		return KeyboardKey.LBracket;
	case SDLK_BACKSLASH:
		return KeyboardKey.BSlash;
	case SDLK_RIGHTBRACKET:
		return KeyboardKey.RBracket;
	case SDLK_CARET:
		return KeyboardKey.Caret;
	case SDLK_UNDERSCORE:
		return KeyboardKey.Underline;
	case SDLK_BACKQUOTE:
		return KeyboardKey.BQuote;
	case SDLK_a:
		return KeyboardKey.A;
	case SDLK_b:
		return KeyboardKey.B;
	case SDLK_c:
		return KeyboardKey.C;
	case SDLK_d:
		return KeyboardKey.D;
	case SDLK_e:
		return KeyboardKey.E;
	case SDLK_f:
		return KeyboardKey.F;
	case SDLK_g:
		return KeyboardKey.G;
	case SDLK_h:
		return KeyboardKey.H;
	case SDLK_i:
		return KeyboardKey.I;
	case SDLK_j:
		return KeyboardKey.J;
	case SDLK_k:
		return KeyboardKey.K;
	case SDLK_l:
		return KeyboardKey.L;
	case SDLK_m:
		return KeyboardKey.M;
	case SDLK_n:
		return KeyboardKey.N;
	case SDLK_o:
		return KeyboardKey.O;
	case SDLK_p:
		return KeyboardKey.P;
	case SDLK_q:
		return KeyboardKey.Q;
	case SDLK_r:
		return KeyboardKey.R;
	case SDLK_s:
		return KeyboardKey.S;
	case SDLK_t:
		return KeyboardKey.T;
	case SDLK_u:
		return KeyboardKey.U;
	case SDLK_v:
		return KeyboardKey.V;
	case SDLK_w:
		return KeyboardKey.W;
	case SDLK_x:
		return KeyboardKey.X;
	case SDLK_y:
		return KeyboardKey.Y;
	case SDLK_z:
		return KeyboardKey.Z;
	case SDLK_DELETE:
		return KeyboardKey.Delete;
	case SDLK_KP0:
		return KeyboardKey.KPad0;
	case SDLK_KP1:
		return KeyboardKey.KPad1;
	case SDLK_KP2:
		return KeyboardKey.KPad2;
	case SDLK_KP3:
		return KeyboardKey.KPad3;
	case SDLK_KP4:
		return KeyboardKey.KPad4;
	case SDLK_KP5:
		return KeyboardKey.KPad5;
	case SDLK_KP6:
		return KeyboardKey.KPad6;
	case SDLK_KP7:
		return KeyboardKey.KPad7;
	case SDLK_KP8:
		return KeyboardKey.KPad8;
	case SDLK_KP9:
		return KeyboardKey.KPad8;
	case SDLK_KP_PERIOD:
		return KeyboardKey.KPadPeriod;
	case SDLK_KP_DIVIDE:
		return KeyboardKey.KPadFSlash;
	case SDLK_KP_MULTIPLY:
		return KeyboardKey.KPadStar;
	case SDLK_KP_MINUS:
		return KeyboardKey.KPadDash;
	case SDLK_KP_PLUS:
		return KeyboardKey.KPadPlus;
	case SDLK_KP_ENTER:
		return KeyboardKey.KPadReturn;
	case SDLK_KP_EQUALS:
		return KeyboardKey.KPadEquals;
	case SDLK_UP:
		return KeyboardKey.Up;
	case SDLK_DOWN:
		return KeyboardKey.Down;
	case SDLK_RIGHT:
		return KeyboardKey.Right;
	case SDLK_LEFT:
		return KeyboardKey.Left;
	case SDLK_INSERT:
		return KeyboardKey.Insert;
	case SDLK_HOME:
		return KeyboardKey.Home;
	case SDLK_END:
		return KeyboardKey.End;
	case SDLK_PAGEUP:
		return KeyboardKey.PageUp;
	case SDLK_PAGEDOWN:
		return KeyboardKey.PageDown;
	case SDLK_F1:
		return KeyboardKey.F1;
	case SDLK_F2:
		return KeyboardKey.F2;
	case SDLK_F3:
		return KeyboardKey.F3;
	case SDLK_F4:
		return KeyboardKey.F4;
	case SDLK_F5:
		return KeyboardKey.F5;
	case SDLK_F6:
		return KeyboardKey.F6;
	case SDLK_F7:
		return KeyboardKey.F7;
	case SDLK_F8:
		return KeyboardKey.F8;
	case SDLK_F9:
		return KeyboardKey.F9;
	case SDLK_F10:
		return KeyboardKey.F10;
	case SDLK_F11:
		return KeyboardKey.F11;
	case SDLK_F12:
		return KeyboardKey.F12;
	case SDLK_F13:
	case SDLK_F14:
	case SDLK_F15:
		// TODO: implement keys
		return KeyboardKey.Unknown;
	case SDLK_NUMLOCK:
		return KeyboardKey.NumLock;
	case SDLK_CAPSLOCK:
		return KeyboardKey.CapsLock;
	case SDLK_SCROLLOCK:
		return KeyboardKey.ScrollLock;
	case SDLK_RSHIFT:
		return KeyboardKey.RShift;
	case SDLK_LSHIFT:
		return KeyboardKey.LShift;
	case SDLK_RCTRL:
		return KeyboardKey.RCtrl;
	case SDLK_LCTRL:
		return KeyboardKey.LCtrl;
	case SDLK_RALT:
		return KeyboardKey.RAlt;
	case SDLK_LALT:
		return KeyboardKey.LAlt;
	case SDLK_RMETA:
		return KeyboardKey.RMeta;
	case SDLK_LMETA:
		return KeyboardKey.LMeta;
	case SDLK_LSUPER:
		return KeyboardKey.LSuper;
	case SDLK_RSUPER:
		return KeyboardKey.RSuper;
	case SDLK_MODE:
		return KeyboardKey.Mode;
	case SDLK_COMPOSE:
	case SDLK_HELP:
		// TODO: implement keys
		return KeyboardKey.Unknown;
	case SDLK_PRINT:
		return KeyboardKey.PrintScreen;
	case SDLK_SYSREQ:
		return KeyboardKey.SysRequest;
	case SDLK_BREAK:
		return KeyboardKey.Break;
	case SDLK_MENU:
		return KeyboardKey.Menu;
	case SDLK_POWER:
	case SDLK_EURO:
	case SDLK_UNDO:
		// TODO: implement keys
		return KeyboardKey.Unknown;
	default:
		return KeyboardKey.Unknown;
	}
}

private KeyboardModifiers translateModifiers(SDLMod input)
{
	KeyboardModifiers retval = KeyboardModifiers.None;
	if(input & KMOD_LSHIFT) retval |= KeyboardModifiers.LShift;
	if(input & KMOD_RSHIFT) retval |= KeyboardModifiers.RShift;
	if(input & KMOD_LALT) retval |= KeyboardModifiers.LAlt;
	if(input & KMOD_RALT) retval |= KeyboardModifiers.RAlt;
	if(input & KMOD_LCTRL) retval |= KeyboardModifiers.LCtrl;
	if(input & KMOD_RCTRL) retval |= KeyboardModifiers.RCtrl;
	if(input & KMOD_LMETA) retval |= KeyboardModifiers.LMeta;
	if(input & KMOD_RMETA) retval |= KeyboardModifiers.RMeta;
	if(input & KMOD_NUM) retval |= KeyboardModifiers.NumLock;
	if(input & KMOD_CAPS) retval |= KeyboardModifiers.CapsLock;
	if(input & KMOD_MODE) retval |= KeyboardModifiers.Mode;
	return retval;
}

private MouseButton translateButton(Uint8 button)
{
	switch(button)
	{
	case SDL_BUTTON_LEFT:
		return MouseButton.Left;
	case SDL_BUTTON_MIDDLE:
		return MouseButton.Middle;
	case SDL_BUTTON_RIGHT:
		return MouseButton.Right;
	case SDL_BUTTON_X1:
		return MouseButton.X1;
	case SDL_BUTTON_X2:
		return MouseButton.X2;
	default:
		return MouseButton.None;
	}
}

private ref shared(bool) keyState(KeyboardKey key)
{
	static shared bool state[KeyboardKey.max + 1 - KeyboardKey.min];
	return state[cast(int)key + KeyboardKey.min];
}

private shared MouseButton buttonState = MouseButton.None;

private Event makeEvent()
{
	synchronized(SDLSyncObject)
	{
		while(true)
		{
			SDL_Event SDLEvent;
			if(SDL_PollEvent(&SDLEvent) == 0)
				return null;
			switch(SDLEvent.type)
			{
			case SDL_ACTIVEEVENT:
				// TODO: handle SDL_ACTIVEEVENT
				break;
			case SDL_KEYDOWN:
			{
				KeyboardKey key = translateKey(SDLEvent.key.keysym.sym);
				Event retval = new KeyDownEvent(key, translateModifiers(SDLEvent.key.keysym.mod), keyState(key));
				keyState(key) = true;
				return retval;
			}
			case SDL_KEYUP:
			{
				KeyboardKey key = translateKey(SDLEvent.key.keysym.sym);
				Event retval = new KeyUpEvent(key, translateModifiers(SDLEvent.key.keysym.mod));
				keyState(key) = false;
				return retval;
			}
			case SDL_MOUSEMOTION:
				return new MouseMoveEvent(SDLEvent.motion.x, SDLEvent.motion.y, SDLEvent.motion.xrel, SDLEvent.motion.yrel);
			case SDL_MOUSEBUTTONDOWN:
			{
				MouseButton button = translateButton(SDLEvent.button.button);
				buttonState |= button; // set bit
				return new MouseDownEvent(SDLEvent.button.x, SDLEvent.button.y, 0, 0, button);
			}
			case SDL_MOUSEBUTTONUP:
			{
				MouseButton button = translateButton(SDLEvent.button.button);
				buttonState &= ~button; // clear bit
				return new MouseUpEvent(SDLEvent.button.x, SDLEvent.button.y, 0, 0, button);
			}
			case SDL_JOYAXISMOTION:
			case SDL_JOYBALLMOTION:
			case SDL_JOYHATMOTION:
			case SDL_JOYBUTTONDOWN:
			case SDL_JOYBUTTONUP:
				//TODO: handle joysticks
				break;
			case SDL_QUIT:
				return new QuitEvent();
			case SDL_SYSWMEVENT:
				//TODO: handle SDL_SYSWMEVENT
				break;
			case SDL_VIDEORESIZE:
				//TODO: handle SDL_VIDEORESIZE
				break;
			case SDL_VIDEOEXPOSE:
				//TODO: handle SDL_VIDEOEXPOSE
				break;
			case SDL_EVENT_RESERVEDA:
			case SDL_EVENT_RESERVEDB:
			case SDL_EVENT_RESERVED2:
			case SDL_EVENT_RESERVED3:
			case SDL_EVENT_RESERVED4:
			case SDL_EVENT_RESERVED5:
			case SDL_EVENT_RESERVED6:
			case SDL_EVENT_RESERVED7:
			default:
				break;
			}
		}
	}
}

private final class DefaultEventHandler : EventHandler
{
	private static immutable DefaultEventHandler handler;
	static this()
	{
		handler = new immutable(DefaultEventHandler)();
	}
	public bool handleMouseUp(MouseUpEvent event)
	{
		return true;
	}
	public bool handleMouseDown(MouseDownEvent event)
	{
		return true;
	}
	public bool handleMouseMove(MouseMoveEvent event)
	{
		return true;
	}
	public bool handleMouseScroll(MouseScrollEvent event)
	{
		return true;
	}
	public bool handleKeyUp(KeyUpEvent event)
	{
		return true;
	}
	public bool handleKeyDown(KeyDownEvent event)
	{
		return true;
	}
	public bool handleKeyPress(KeyPressEvent event)
	{
		return true;
	}
	public bool handleQuit(QuitEvent event)
	{
		synchronized(SDLSyncObject)
		{
			Runtime.terminate();
			exit(0);
			return true;
		}
	}
}

private void handleEvents(EventHandler eventHandler)
{
	for(Event e = makeEvent(); e !is null; e = makeEvent())
	{
		if(eventHandler is null || !e.dispatch(eventHandler))
			e.dispatch(DefaultEventHandler.handler);
	}
}

static ~this()
{
	if(needIMGQuit)
		IMG_Quit();
	if(needSDLQuit)
	{
		needSDLQuit = false;
		SDL_Quit();
	}
}

public enum KeyboardKey
{
	Unknown = SDLK_UNKNOWN,
	A = SDLK_a,
	B = SDLK_b,
	C = SDLK_c,
	D = SDLK_d,
	E = SDLK_e,
	F = SDLK_f,
	G = SDLK_g,
	H = SDLK_h,
	I = SDLK_i,
	J = SDLK_j,
	K = SDLK_k,
	L = SDLK_l,
	M = SDLK_m,
	N = SDLK_n,
	O = SDLK_o,
	P = SDLK_p,
	Q = SDLK_q,
	R = SDLK_r,
	S = SDLK_s,
	T = SDLK_t,
	U = SDLK_u,
	V = SDLK_v,
	W = SDLK_w,
	X = SDLK_x,
	Y = SDLK_y,
	Z = SDLK_z,

	Backspace = SDLK_BACKSPACE,
	Tab = SDLK_TAB,
	Clear = SDLK_CLEAR,
	Return = SDLK_RETURN,
	Pause = SDLK_PAUSE,
	Escape = SDLK_ESCAPE,
	Space = SDLK_SPACE,
	SQuote = SDLK_QUOTE,
	DQuote = SQuote,
	Equals = SDLK_EQUALS,
	Comma = SDLK_COMMA,
	Dash = SDLK_MINUS,
	Underline = Dash,
	BQuote = SDLK_BACKQUOTE,
	Tilde = BQuote,
	LBracket = SDLK_LEFTBRACKET,
	RBracket = SDLK_RIGHTBRACKET,
	LBrace = LBracket,
	RBrace = RBracket,
	BSlash = SDLK_BACKSLASH,
	Pipe = BSlash,
	Delete = SDLK_DELETE,
	Period = SDLK_PERIOD,
	FSlash = SDLK_SLASH,
	Num0 = SDLK_0,
	Num1 = SDLK_1,
	Num2 = SDLK_2,
	Num3 = SDLK_3,
	Num4 = SDLK_4,
	Num5 = SDLK_5,
	Num6 = SDLK_6,
	Num7 = SDLK_7,
	Num8 = SDLK_8,
	Num9 = SDLK_9,
	EMark = Num1,
	Pound = Num3,
	Dollar = Num4,
	Percent = Num5,
	Caret = Num6,
	Amp = Num7,
	Star = Num8,
	LParen = Num9,
	RParen = Num0,
	Colon = SDLK_COLON,
	Semicolon = Colon,
	LAngle = Comma,
	Plus = Equals,
	RAngle = Period,
	QMark = FSlash,
	AtSign = Num2,
	F1 = SDLK_F1,
	F2 = SDLK_F2,
	F3 = SDLK_F3,
	F4 = SDLK_F4,
	F5 = SDLK_F5,
	F6 = SDLK_F6,
	F7 = SDLK_F7,
	F8 = SDLK_F8,
	F9 = SDLK_F9,
	F10 = SDLK_F10,
	F11 = SDLK_F11,
	F12 = SDLK_F12,
	Up = SDLK_UP,
	Down = SDLK_DOWN,
	Left = SDLK_LEFT,
	Right = SDLK_RIGHT,
	Insert = SDLK_INSERT,
	Home = SDLK_HOME,
	End = SDLK_END,
	PageUp = SDLK_PAGEUP,
	PageDown = SDLK_PAGEDOWN,
	LShift = SDLK_LSHIFT,
	RShift = SDLK_RSHIFT,
	LCtrl = SDLK_LCTRL,
	RCtrl = SDLK_RCTRL,
	KPad0 = SDLK_KP0,
	KPadInsert = KPad0,
	KPad1 = SDLK_KP1,
	KPadEnd = KPad1,
	KPad2 = SDLK_KP2,
	KPadDown = KPad2,
	KPad3 = SDLK_KP3,
	KPadPageDown = KPad3,
	KPad4 = SDLK_KP4,
	KPadLeft = KPad4,
	KPad5 = SDLK_KP5,
	KPad6 = SDLK_KP6,
	KPadRight = KPad6,
	KPad7 = SDLK_KP7,
	KPadHome = KPad7,
	KPad8 = SDLK_KP8,
	KPadUp = KPad8,
	KPad9 = SDLK_KP9,
	KPadPageUp = KPad9,
	KPadFSlash = SDLK_KP_DIVIDE,
	KPadStar = SDLK_KP_MULTIPLY,
	KPadDash = SDLK_KP_MINUS,
	KPadPlus = SDLK_KP_PLUS,
	KPadReturn = SDLK_KP_ENTER,
	KPadPeriod = SDLK_KP_PERIOD,
	KPadDelete = KPadPeriod,
	KPadEquals = SDLK_KP_EQUALS,
	NumLock = SDLK_NUMLOCK,
	CapsLock = SDLK_CAPSLOCK,
	ScrollLock = SDLK_SCROLLOCK,
	LAlt = SDLK_LALT,
	RAlt = SDLK_RALT,
	LMeta = SDLK_LMETA,
	RMeta = SDLK_RMETA,
	LSuper = SDLK_LSUPER,
	RSuper = SDLK_RSUPER,
	AltGr = SDLK_MODE,
	PrintScreen = SDLK_PRINT,
	SysRequest = PrintScreen,
	Break = Pause,
	Menu = SDLK_MENU,
	Mode = SDLK_MODE
}

public enum KeyboardModifiers : uint
{
	None = KMOD_NONE,
	LShift = KMOD_LSHIFT,
	RShift = KMOD_RSHIFT,
	LCtrl = KMOD_LCTRL,
	RCtrl = KMOD_RCTRL,
	LAlt = KMOD_LALT,
	RAlt = KMOD_RALT,
	LMeta = KMOD_LMETA,
	RMeta = KMOD_RMETA,
	NumLock = KMOD_NUM,
	CapsLock = KMOD_CAPS,
	Mode = KMOD_MODE,
	Ctrl = LCtrl | RCtrl,
	Shift = LShift | RShift,
	Alt = LAlt | RAlt,
	Meta = LMeta | RMeta,
}

public enum MouseButton : uint
{
	None = 0,
	Left = SDL_BUTTON_LMASK,
	Right = SDL_BUTTON_RMASK,
	Middle = SDL_BUTTON_MMASK,
	X1 = SDL_BUTTON_X1MASK,
	X2 = SDL_BUTTON_X2MASK
}

public struct Display
{
	public @disable this();

	public static @property string title()
	{
		synchronized(SDLSyncObject)
		{
			char* title_, icon;
			SDL_WM_GetCaption(&title_, &icon);
			return to!string(title_);
		}
	}

	public static @property void title(string newTitle)
	{
		synchronized(SDLSyncObject)
		{
			SDL_WM_SetCaption(toStringz(newTitle), null);
		}
	}

	public static void handleEvents(EventHandler eventHandler)
	{
		.handleEvents(eventHandler);
	}

	public static void flip(float fps = defaultFPS)
	{
		flipDisplay(fps);
	}

	public static @property double instantaneousFPS()
	{
		return .instantaneousFPS;
	}

	public static @property float averageFPS()
	{
		return .averageFPS;
	}

	public static @property double timer()
	{
		return TickDuration.currSystemTick.hnsecs / 1e7;
	}
}
