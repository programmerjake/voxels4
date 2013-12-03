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

    public override void move(ref EntityData data, in double deltaTime)
    {
        Player p = cast(Player)data.data;
        assert(p !is null);
        p.move(deltaTime);
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
        AttackButtonUp,
        ViewChange,
    }
    public immutable Type type;
    public this(Type type)
    {
        this.type = type;
    }
    public abstract void dispatch(Player p);
}

//FIXME (jacob#): finish PlayerInputEvent

public interface PlayerInput
{
    PlayerInputEvent nextEvent();
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
    private this()
    {

    }

    //FIXME (jacob#): finish Player

    public TransformedMesh getDrawMesh(RenderLayer rl)
    {
        assert(false, "finish"); //FIXME (jacob#): finish
    }

    package static Player readInternal(GameLoadStream gls)
    {
        assert(false, "finish"); //FIXME (jacob#): finish
    }

    public void move(in double deltaTime)
    {
        assert(false, "finish"); //FIXME (jacob#): finish
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

}
