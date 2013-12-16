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
module entity.block;
public import entity.entity;
import block.block;
import std.stdio;
import util;
import entity.player.player;

private immutable float blockSize = 0.25;

public final class BlockEntity : EntityDescriptor
{
    private static BlockEntity BLOCK_;
    static this()
    {
        BLOCK_ = new BlockEntity();
    }
    private static @property BlockEntity BLOCK()
    {
        return BLOCK_;
    }
    private this()
    {
        super("Default.Block");
    }

    public static immutable double INITIAL_EXIST_DURATION = 60.0 * 6; // 6 minutes

    public static EntityData make(Vector position, Dimension dimension, BlockData block)
    {
        return make(position, vrandom() * 0.1, dimension, block);
    }

    public static EntityData make(Vector position, Vector velocity, Dimension dimension, BlockData block)
    {
        EntityData data = EntityData(BLOCK, position, dimension);
        Data * data_data = new Data();
        data_data.theta = frandom(2 * PI);
        data_data.angularVelocity = frandom(-5, 5);
        data_data.existDuration = INITIAL_EXIST_DURATION;
        data_data.block = block;
        data_data.velocity = velocity;
        data.data = cast(void *)data_data;
        return data;
    }

    private static struct Data
    {
        public float theta;
        public float angularVelocity;
        public double existDuration;
        public BlockData block;
        public Vector velocity;
        public Vector newPosition;
        public bool colliding = false;
    }

    private Matrix getDrawTransform(EntityData data, Data * data_data)
    {
        return Matrix.rotateY(data_data.theta).concat(Matrix.translate(data.position - Vector(0, blockSize * 0.5, 0)));
    }

    public override TransformedMesh getDrawMesh(ref EntityData data, RenderLayer rl)
    {
        Data * data_data = cast(Data *)data.data;
        if(data_data is null)
            return TransformedMesh();
        assert(data_data.block.good);
        return TransformedMesh(data_data.block.getEntityDrawMesh(rl), getDrawTransform(data, data_data));
    }

    protected override EntityData readInternal(GameLoadStream gls)
    {
        Vector position = gls.readFiniteVector();
        Dimension dimension = gls.readDimension();
        EntityData data = EntityData(BLOCK, position, dimension);
        Data * data_data = new Data();
        data_data.theta = gls.readAngleTheta();
        data_data.angularVelocity = gls.readRangeLimitedFloat(-20, 20);
        data_data.existDuration = gls.readRangeLimitedDouble(0, 1e5);
        data_data.block = BlockDescriptor.read(gls);
        data_data.velocity = gls.readFiniteVector();
        data.data = cast(void *)data_data;
        return data;
    }

    private float moveH(Vector startPos, Vector endPos, BlockPosition b)
    {
        b.moveTo(startPos);
        if(!b.get().good || b.get().isOpaque())
            return 0;
        b.moveTo(endPos);
        float t = 0, tFactor = 0.5;
        bool allGood = true;
        while(abs(startPos - endPos) > 1e-5)
        {
            Vector midPos = 0.5 * (startPos + endPos);
            b.moveTo(midPos);
            if(b.get().good && !b.get().isOpaque())
            {
                t += tFactor;
                startPos = midPos;
            }
            else
            {
                endPos = midPos;
                allGood = false;
            }
            tFactor *= 0.5;
        }
        if(allGood)
            return 1;
        return t;
    }

    public override void postMove(ref EntityData data, World world)
    {
        Data * data_data = cast(Data *)data.data;
        assert(data_data !is null);
        data.position = data_data.newPosition;
    }

    public override void move(ref EntityData data, World world, in double deltaTime)
    {
        Data * data_data = cast(Data *)data.data;
        assert(data_data !is null);
        data_data.existDuration -= deltaTime;
        if(data_data.existDuration <= 0)
        {
            data.descriptor = null;
            return;
        }
        data_data.velocity += deltaTime * World.GRAVITY;
        data_data.newPosition = data.position + deltaTime * data_data.velocity;
        for(int i = 0; i < 1; i++)
        {
            Collision c = world.collideWithCylinder(data.dimension, Cylinder(data.position - Vector(0, -0.5 * blockSize, 0), 0.5 * blockSize * sqrt(2.0), blockSize), CollisionMask(~Player.PLAYER_MASK, &data));
            if(c.good)
            {
                c.normalize();
                data_data.velocity = c.normal;
                data_data.newPosition = c.point + c.normal * 0.01;
                data_data.angularVelocity *= pow(0.1, deltaTime);
            }
            else
                break;
        }
        data_data.theta += deltaTime * data_data.angularVelocity;
        if(data.position.y < -64)
        {
            data.descriptor = null;
            return;
        }
        //FIXME(jacob#): change to actual implementation
    }

    protected override void writeInternal(EntityData data, GameStoreStream gss)
    {
        Data * data_data = cast(Data *)data.data;
        assert(data_data !is null);
        assert(data_data.block.good);
        gss.write(data.position);
        gss.write(data.dimension);
        gss.write(data_data.theta);
        gss.write(data_data.angularVelocity);
        gss.write(data_data.existDuration);
        BlockDescriptor.write(data_data.block, gss);
        gss.write(data_data.velocity);
    }

    public override Collision collideWithCylinder(ref EntityData data, Cylinder c, CollisionMask mask)
    {
        if(!mask.matches(~Player.PLAYER_MASK, &data))
            return Collision();
        return collideCylinderWithCylinder(Cylinder(data.position - Vector(0, -0.5 * blockSize, 0), 0.5 * blockSize * sqrt(2.0), blockSize), data.dimension, c);
    }

    public override Collision collideWithBox(ref EntityData data, Matrix boxTransform, CollisionMask mask)
    {
        if(!mask.matches(~Player.PLAYER_MASK, &data))
            return Collision();
        return collideAABBWithBox(data.position - 0.5 * blockSize * Vector.XYZ, data.position + 0.5 * blockSize * Vector.XYZ, data.dimension, boxTransform);
    }

    public override RayCollision collide(ref EntityData data, Ray ray, RayCollisionArgs cArgs)
    {
        static if(true) // TODO (jacob#): check if we need ray hits
        {
            Data * data_data = cast(Data *)data.data;
            if(data_data is null)
                return null;
            assert(data_data.block.good);
            Matrix drawTransform = getDrawTransform(data, data_data);
            Matrix invDrawTransform = drawTransform.invert();
            ray.transformAndSet(invDrawTransform);
            RayCollision bc = data_data.block.collide(ray, cArgs);
            if(bc is null)
                return null;
            bc.transformAndSet(drawTransform);
            return new EntityRayCollision(bc, data);
        }
        else
        {
            return null;
        }
    }
}
