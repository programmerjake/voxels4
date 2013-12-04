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
import entity.entity;
import block.block;

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
        EntityData data = EntityData(BLOCK, position, dimension);
        Data * data_data = new Data();
        data_data.theta = 0; // TODO(jacob#): change to random
        data_data.existDuration = INITIAL_EXIST_DURATION;
        data_data.block = block;
        data_data.velocity = Vector.ZERO;
        data.data = cast(void *)data_data;
        return data;
    }

    private static struct Data
    {
        public float theta;
        public double existDuration;
        public BlockData block;
        public Vector velocity;
    }

    public override TransformedMesh getDrawMesh(ref EntityData data, RenderLayer rl)
    {
        Data * data_data = cast(Data *)data.data;
        if(data_data is null)
            return TransformedMesh();
        assert(data_data.block.good);
        return TransformedMesh(data_data.block.descriptor.getEntityDrawMesh(data_data.block, rl), Matrix.rotateY(data_data.theta).concat(Matrix.translate(data.position - Vector(0, blockSize, 0))));
    }

    protected override EntityData readInternal(GameLoadStream gls)
    {
        Vector position = gls.readFiniteVector();
        Dimension dimension = gls.readDimension();
        EntityData data = EntityData(BLOCK, position, dimension);
        Data * data_data = new Data();
        data_data.theta = gls.readAngleTheta();
        data_data.existDuration = gls.readRangeLimitedDouble(0, 1e5);
        data_data.block = BlockDescriptor.read(gls);
        data_data.velocity = gls.readFiniteVector();
        data.data = cast(void *)data_data;
        return data;
    }

    public override void move(ref EntityData data, in double deltaTime)
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
        data.position += deltaTime * data_data.velocity;
        data_data.theta += deltaTime * PI;
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
        gss.write(data_data.existDuration);
        BlockDescriptor.write(data_data.block, gss);
        gss.write(data_data.velocity);
    }
}
