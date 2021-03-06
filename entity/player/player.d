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
import entity.block;
import block.block;
import render.generate;
import resource.texture_atlas;
import std.stdio;

private immutable float playerHeight = 1.8;
private immutable float playerEyeHeight = 1.7;
private immutable float playerWidth = 0.5;

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

    protected override EntityData readInternal(GameLoadStream gls, World world)
    {
        Player p = Player.readInternal(gls, world);
        EntityData data = EntityData(Player.PLAYER, p.position, p.dimension);
        data.data = cast(void *)p;
        return data;
    }

    public override void move(ref EntityData data, World world, in double deltaTime)
    {
        Player p = cast(Player)data.data;
        assert(p !is null);
        p.move(deltaTime, &data);
        data.position = p.position;
        data.dimension = p.dimension;
    }

    protected override void writeInternal(EntityData data, GameStoreStream gss, World world)
    {
        Player p = cast(Player)data.data;
        assert(p !is null);
        p.writeInternal(gss, world);
    }

    public override ulong getCollideMask()
    {
        return Player.PLAYER_MASK;
    }

    public override Collision collideWithCylinder(ref EntityData data, Cylinder c, CollisionMask mask)
    {
        if(!mask.matches(Player.PLAYER_MASK, &data))
            return Collision();
        return collideCylinderWithCylinder(Cylinder(data.position - Vector(0, -playerEyeHeight, 0), 0.5 * playerWidth, playerHeight), data.dimension, c);
    }

    public override Collision collideWithBox(ref EntityData data, Vector min, Vector max, CollisionMask mask)
    {
        if(!mask.matches(Player.PLAYER_MASK, &data))
            return Collision();
        return collideAABBWithBox(data.position + Vector(-0.5 * playerWidth, -playerEyeHeight, -0.5 * playerWidth), data.position + Vector(0.5 * playerWidth, playerHeight - playerEyeHeight, 0.5 * playerWidth), data.dimension, min, max);
    }

    public override RayCollision collide(ref EntityData data, Ray ray, RayCollisionArgs cArgs)
    {
        Player p = cast(Player)data.data;
        assert(p !is null);
        if(p.reportRayHit)
        {
            struct CollideArgs
            {
                EntityData * data;
                RayCollision fn(Vector position, Dimension dimension, float t)
                {
                    return EntityRayCollision(position, dimension, t, data);
                }
            }
            CollideArgs collideArgs;
            collideArgs.data = &data;
            return collideWithAABB(data.position + Vector(-0.5 * playerWidth, -playerEyeHeight, -0.5 * playerWidth), data.position + Vector(0.5 * playerWidth, playerHeight - playerEyeHeight, 0.5 * playerWidth), ray, &collideArgs.fn);
        }
        return RayCollision();
    }

    public override CollisionBox getBoundingBox(EntityData data)
    {
        return CollisionBox(data.position + Vector(-0.5 * playerWidth, -playerEyeHeight, -0.5 * playerWidth), data.position + Vector(0.5 * playerWidth, playerHeight - playerEyeHeight, 0.5 * playerWidth), data.dimension);
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
    void drawOverlay();
    @property bool sneakButton();
    @property bool attackButton();
    @property bool motionUp();
    @property bool motionDown();
    @property bool motionForward();
    @property bool motionBack();
    @property bool motionLeft();
    @property bool motionRight();
    @property bool flyMode();
    @property bool creativeMode();
    @property void creativeMode(bool);
    void move();
}

public final class Player
{
    private static ulong PLAYER_MASK_ = 0;
    private static PlayerDescriptor PLAYER_ = null;
    static this()
    {
        PLAYER_ = new PlayerDescriptor();
    }
    package static @property EntityDescriptor PLAYER()
    {
        return PLAYER_;
    }
    public static @property ulong PLAYER_MASK()
    {
        if(PLAYER_MASK_ == 0)
            PLAYER_MASK_ = CollisionMask.getNewCollisionMaskBit();
        return PLAYER_MASK_;
    }

    private string name;
    package Vector position, velocity;
    package Dimension dimension;
    private float viewTheta, viewPhi;
    private PlayerInput input;
    private World world;
    public BlockStackArray!(9, 4) blocks;
    private this()
    {

    }

    public @property EntityData data()
    {
        EntityData retval = EntityData(PLAYER, position, dimension);
        retval.data = cast(void *)this;
        return retval;
    }

    public static Player make(string name, PlayerInput input, World world, Vector position, Dimension dimension)
    {
        Player retval = new Player();
        retval.name = name;
        retval.position = position;
        retval.velocity = Vector.ZERO;
        retval.dimension = dimension;
        retval.input = input;
        retval.viewTheta = 0;
        retval.viewPhi = 0;
        retval.world = world;
        return retval;
    }

    //FIXME (jacob#): finish Player

    public TransformedMesh getDrawMesh(RenderLayer rl)
    {
        return TransformedMesh(); //FIXME (jacob#): finish
    }

    private static Mesh highlightBlockMesh;
    static this()
    {
        TextureDescriptor td = TextureAtlas.BlockHighlight.td;
        highlightBlockMesh = Generate.unitBox(td, td, td, td, td, td).transform(Matrix.translate(-0.5, -0.5, -0.5).concat(Matrix.scale(1.05f)).concat(Matrix.translate(0.5, 0.5, 0.5))).seal();
    }

    private Mesh temp = null;

    private @property float reachDistance()
    {
        if(input.creativeMode)
            return 15;
        return 3.975;
    }

    public void drawAll()
    {
        if(temp is null)
            temp = new Mesh();
        temp.clear();
        RayCollision rc = getRayCollision(null);
        final switch(rc.type)
        {
        case RayCollision.Type.None:
            break;
        case RayCollision.Type.Uninitialized:
            //writefln("hit: uninitialized");
            break;
        case RayCollision.Type.Block:
        {
            BlockPosition b = rc.block;
            assert(b.get().good);
            CollisionBox bb = b.get().getBoundingBox(b);
            //writefln("hit: block: <%s, %s, %s> to <%s, %s, %s>", bb.min.x, bb.min.y, bb.min.z, bb.max.x, bb.max.y, bb.max.z);
            temp.add(TransformedMesh(highlightBlockMesh, Matrix.scale(bb.max - bb.min).concat(Matrix.translate(bb.min))));
            break;
        }
        case RayCollision.Type.Entity:
        {
            EntityData * e = rc.entity;
            assert(e !is null && e.good);
            CollisionBox bb = e.getBoundingBox();
            //writefln("hit: entity: <%s, %s, %s> to <%s, %s, %s>", bb.min.x, bb.min.y, bb.min.z, bb.max.x, bb.max.y, bb.max.z);
            temp.add(TransformedMesh(highlightBlockMesh, Matrix.scale(bb.max - bb.min).concat(Matrix.translate(bb.min))));
            break;
        }
        }
        world.draw(position, viewTheta, viewPhi, dimension, temp);
        input.drawOverlay();
        //FIXME (jacob#): finish
    }

    private RayCollision getRayCollision(RayCollisionArgs cArgs)
    {
        reportRayHit = false;
        RayCollision retval = world.collide(Ray(position, dimension, Matrix.thetaPhi(viewTheta, viewPhi).invert().apply(Vector(0, 0, -1))), reachDistance, cArgs);
        reportRayHit = true;
        return retval;
    }

    package static Player readInternal(GameLoadStream gls, World world)
    {
        assert(false, "finish"); //FIXME (jacob#): finish
    }

    private CollisionMask getCollideCollisionMask(EntityData * data = null)
    {
        return CollisionMask(~BlockEntity.BLOCK_MASK, data);
    }

    public void move(in double deltaTime, EntityData * data)
    {
        //FIXME (jacob#): finish
        input.move();
        for(;;)
        {
            PlayerInputEvent event = input.nextEvent();
            if(event is null)
                break;
            event.dispatch(this);
        }
        const float moveVelocity = 2.5;
        Vector deltaPosition = Vector.ZERO;
        if(input.flyMode)
        {
            if(input.motionUp)
                deltaPosition.y = deltaTime * moveVelocity;
            else if(input.motionDown)
                deltaPosition.y = -deltaTime * moveVelocity;
        }
        else
        {
            deltaPosition += deltaTime * velocity;
            velocity += deltaTime * World.GRAVITY;
        }
        Vector forward = Matrix.rotateY(-viewTheta).apply(Vector.NZ);
        Vector left = Matrix.rotateY(-viewTheta).apply(Vector.NX);
        if(input.motionLeft)
            deltaPosition += deltaTime * moveVelocity * left;
        else if(input.motionRight)
            deltaPosition -= deltaTime * moveVelocity * left;
        if(input.motionForward)
            deltaPosition += deltaTime * moveVelocity * forward;
        else if(input.motionBack)
            deltaPosition -= deltaTime * moveVelocity * forward;
        int count = iceil(10.0 * abs(deltaPosition) + 1);
        try
        {
            for(int i = 0; i < count; i++)
            {
                position += deltaPosition / count;
                Vector delta = world.findBestBoxPositionWithBlocksOnly(CollisionBox(position + Vector(-0.5 * playerWidth, -playerEyeHeight, -0.5 * playerWidth), position + Vector(0.5 * playerWidth, playerHeight - playerEyeHeight, 0.5 * playerWidth), dimension), getCollideCollisionMask(data));
                if(delta != Vector.ZERO)
                {
                    position += delta;
                    if(velocity.y > 0 || !onGround())
                        velocity = Vector(0, velocity.y, 0);
                    else
                        velocity = Vector.ZERO;
                }
            }
        }
        catch(World.NoSpaceToPutException e)
        {
            return;
        }
    }

    package void writeInternal(GameStoreStream gss, World world)
    {
        assert(false, "finish"); //FIXME (jacob#): finish
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

    private void handleJump()
    {
        if(!onGround())
            return;
        velocity = Vector.Y * 5;
    }

    package void handleJump(PlayerInputEvent.Jump event)
    {
        handleJump();
    }

    private bool onGround()
    {
        const float onGroundDistance = 0.05;
        return world.collidesWithBoxBlocksOnly(CollisionBox(position + Vector(-0.5 * playerWidth, -playerEyeHeight - onGroundDistance, -0.5 * playerWidth), position + Vector(0.5 * playerWidth, -playerEyeHeight, 0.5 * playerWidth), dimension), getCollideCollisionMask());
    }

    package bool reportRayHit = true;
}
