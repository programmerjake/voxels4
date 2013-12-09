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
module entity.player.player;
public import entity.entity;
import util;

private final class PlayerDescriptor : EntityDescriptor
{
    public this()
    {
        super("Builtin.Player");
    }

    public override TransformedMesh getDrawMesh(ref EntityData data, RenderLayer rl)
    {
        Player p = cast(Player)data.data;
        assert(p !is null);
        return p.getDrawMesh(rl);
    }

    protected override EntityData readInternal(GameLoadStream gls)
    {
        Player p = Player.readInternal(gls);
        EntityData data = EntityData(Player.PLAYER, p.position, p.dimension);
        data.data = cast(void *)p;
        return data;
    }

    public override void move(ref EntityData data, World world, in double deltaTime)
    {
        Player p = cast(Player)data.data;
        assert(p !is null);
        p.move(world, deltaTime);
        data.position = p.position;
        data.dimension = p.dimension;
    }

    protected override void writeInternal(EntityData data, GameStoreStream gss)
    {
        Player p = cast(Player)data.data;
        assert(p !is null);
        p.writeInternal(gss);
    }
}

public abstract class PlayerInputEvent
{
    public enum Type
    {
        UseButtonPress,
        AttackButtonDown,
        ViewChange,
        HotBarMoveLeft,
        HotBarMoveRight,
        HotBarSelect,
        Jump,
    }
    public immutable Type type;
    public this(Type type)
    {
        this.type = type;
    }
    public abstract void dispatch(Player p);
    public static final class UseButtonPress : PlayerInputEvent
    {
        this()
        {
            super(Type.UseButtonPress);
        }
        public override void dispatch(Player p)
        {
            p.handleUseButtonPress(this);
        }
    }
    public static final class AttackButtonDown : PlayerInputEvent
    {
        this()
        {
            super(Type.AttackButtonDown);
        }
        public override void dispatch(Player p)
        {
            p.handleAttackButtonDown(this);
        }
    }
	public static final class ViewChange : PlayerInputEvent
	{
	    public immutable float deltaTheta, deltaPhi;
		this(float deltaTheta, float deltaPhi)
		{
			super(Type.ViewChange);
			this.deltaTheta = deltaTheta;
			this.deltaPhi = deltaPhi;
		}
		public override void dispatch(Player p)
		{
			p.handleViewChange(this);
		}
	}
	public static final class HotBarMoveLeft : PlayerInputEvent
	{
		this()
		{
			super(Type.HotBarMoveLeft);
		}
		public override void dispatch(Player p)
		{
			p.handleHotBarMoveLeft(this);
		}
	}
	public static final class HotBarMoveRight : PlayerInputEvent
	{
		this()
		{
			super(Type.HotBarMoveRight);
		}
		public override void dispatch(Player p)
		{
			p.handleHotBarMoveRight(this);
		}
	}
	public static final class Jump : PlayerInputEvent
	{
		this()
		{
			super(Type.Jump);
		}
		public override void dispatch(Player p)
		{
			p.handleJump(this);
		}
	}
	public static final class HotBarSelect : PlayerInputEvent
	{
	    public immutable int selection;
		this(int selection)
		{
			super(Type.HotBarSelect);
			this.selection = selection;
		}
		public override void dispatch(Player p)
		{
			p.handleHotBarSelect(this);
		}
	}
}

//FIXME (jacob#): finish PlayerInputEvent

public interface PlayerInput
{
    PlayerInputEvent nextEvent();
    void drawOverlay(Player p);
    @property bool sneakButton();
    @property bool attackButton();
    @property bool motionUp();
    @property bool motionDown();
    @property bool motionForward();
    @property bool motionBack();
    @property bool motionLeft();
    @property bool motionRight();
}

public final class Player
{
    private static PlayerDescriptor PLAYER_;
    static this()
    {
        PLAYER_ = new PlayerDescriptor();
    }
    package static @property EntityDescriptor PLAYER()
    {
        return PLAYER_;
    }

    private string name;
    package Vector position;
    package Dimension dimension;
    private float viewTheta, viewPhi;
    private PlayerInput input;
    private this()
    {

    }

    public @property EntityData data()
    {
        EntityData retval = EntityData(PLAYER, position, dimension);
        retval.data = cast(void *)this;
        return retval;
    }

    public static Player make(string name, PlayerInput input, Vector position, Dimension dimension)
    {
        Player retval = new Player();
        retval.name = name;
        retval.position = position;
        retval.dimension = dimension;
        retval.input = input;
        retval.viewTheta = 0;
        retval.viewPhi = 0;
        return retval;
    }

    //FIXME (jacob#): finish Player

    public TransformedMesh getDrawMesh(RenderLayer rl)
    {
        return TransformedMesh(); //FIXME (jacob#): finish
    }

    public void drawAll(World world)
    {
        world.draw(position, viewTheta, viewPhi, dimension);
        input.drawOverlay(this);
        //FIXME (jacob#): finish
    }

    package static Player readInternal(GameLoadStream gls)
    {
        assert(false, "finish"); //FIXME (jacob#): finish
    }

    public void move(World world, in double deltaTime)
    {
        //FIXME (jacob#): finish
        for(;;)
        {
            PlayerInputEvent event = input.nextEvent();
            if(event is null)
                break;
            event.dispatch(this);
        }
    }

    package void writeInternal(GameStoreStream gss)
    {
        assert(false, "finish"); //FIXME (jacob#): finish
    }

    private static LinkedList!Player players;

    static this()
    {
        players = new LinkedList!Player();
    }

    package void handleUseButtonPress(PlayerInputEvent.UseButtonPress event)
    {
        //FIXME(jacob#): finish
    }

    package void handleAttackButtonDown(PlayerInputEvent.AttackButtonDown event)
    {
        //FIXME(jacob#): finish
    }

    package void handleViewChange(PlayerInputEvent.ViewChange event)
    {
        //FIXME(jacob#): finish
        viewTheta += event.deltaTheta;
        viewTheta %= 2 * PI;
        viewPhi += event.deltaPhi;//FIXME(jacob#): finish
        if(viewPhi < -PI / 2) viewPhi = -PI / 2;
        if(viewPhi > PI / 2) viewPhi = PI / 2;
    }

    package void handleHotBarMoveLeft(PlayerInputEvent.HotBarMoveLeft event)
    {
        //FIXME(jacob#): finish
    }

    package void handleHotBarMoveRight(PlayerInputEvent.HotBarMoveRight event)
    {
        //FIXME(jacob#): finish
    }

    package void handleHotBarSelect(PlayerInputEvent.HotBarSelect event)
    {
        //FIXME(jacob#): finish
    }

    package void handleJump(PlayerInputEvent.Jump event)
    {
        //FIXME(jacob#): finish
    }
}
