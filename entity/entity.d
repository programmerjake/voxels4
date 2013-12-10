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
module entity.entity;
public import render.mesh;
public import world.world;
public import persistance.game_load_stream;
public import persistance.game_store_stream;

public struct EntityData
{
    EntityDescriptor descriptor = null;
    Vector position;
    Dimension dimension;
    void * data = null;
    this(EntityDescriptor descriptor, Vector position, Dimension dimension)
    {
        this.descriptor = descriptor;
        this.position = position;
        this.dimension = dimension;
    }
    public @property bool good() const
    {
        return descriptor !is null;
    }
    public TransformedMesh getDrawMesh(RenderLayer rl)
    {
        assert(good);
        return descriptor.getDrawMesh(this, rl);
    }
    public void move(World world, in double deltaTime)
    {
        assert(good);
        descriptor.move(this, world, deltaTime);
    }
}

public abstract class EntityDescriptor
{
    public immutable string name;
    public this(string name)
    {
        this.name = name;
        addToEntityList(this);
    }

    public abstract TransformedMesh getDrawMesh(ref EntityData data, RenderLayer rl);
    protected abstract EntityData readInternal(GameLoadStream gls);
    public abstract void move(ref EntityData data, World world, in double deltaTime);
    protected abstract void writeInternal(EntityData data, GameStoreStream gss);

    public static void write(EntityData data, GameStoreStream gss)
    {
        assert(data.good);
        gss.write(data.descriptor);
        data.descriptor.writeInternal(data, gss);
    }

    public static EntityData read(GameLoadStream gls)
    {
        return gls.readEntityDescriptor().readInternal(gls);
    }

    private static EntityDescriptor[string] entities;
    private static EntityDescriptor[] entityList;
    private static void addToEntityList(EntityDescriptor ed)
    {
        assert(entities.get(ed.name, cast(EntityDescriptor)null) is null);
        entities[ed.name] = ed;
        entityList ~= [ed];
    }
    public static EntityDescriptor getEntity(string name)
    {
        return entities.get(name, cast(EntityDescriptor)null);
    }
    public static size_t getEntityCount()
    {
        return entityList.length;
    }
    public static EntityDescriptor getEntity(size_t index)
    {
        assert(index >= 0 && index < entityList.length);
        return entityList[index];
    }
}
