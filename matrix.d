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
module matrix;

import vector;

/** 4x4 matrix for 3D transformation with last row always equal to [0 0 0 1]
 *
 * Author:
 *  jacob */
public struct Matrix
{
    public float x00, x10, x20, x30;
    public float x01, x11, x21, x31;
    public float x02, x12, x22, x32;

    public pure float get(in int x, in int y)
    {
        switch(x)
        {
        case 0:
            switch(y)
            {
            case 0:
                return this.x00;
            case 1:
                return this.x01;
            case 2:
                return this.x02;
            default:
                return x == y ? 1 : 0;
            }
        case 1:
            switch(y)
            {
            case 0:
                return this.x10;
            case 1:
                return this.x11;
            case 2:
                return this.x12;
            default:
                return x == y ? 1 : 0;
            }
        case 2:
            switch(y)
            {
            case 0:
                return this.x20;
            case 1:
                return this.x21;
            case 2:
                return this.x22;
            default:
                return x == y ? 1 : 0;
            }
        case 3:
            switch(y)
            {
            case 0:
                return this.x30;
            case 1:
                return this.x31;
            case 2:
                return this.x32;
            default:
                return x == y ? 1 : 0;
            }
        default:
            return x == y ? 1 : 0;
        }
    }

    public pure this(float x00,
                  float x10,
                  float x20,
                  float x30,
                  float x01,
                  float x11,
                  float x21,
                  float x31,
                  float x02,
                  float x12,
                  float x22,
                  float x32)
    {
        this.x00 = x00;
        this.x10 = x10;
        this.x20 = x20;
        this.x30 = x30;
        this.x01 = x01;
        this.x11 = x11;
        this.x21 = x21;
        this.x31 = x31;
        this.x02 = x02;
        this.x12 = x12;
        this.x22 = x22;
        this.x32 = x32;
    }

    /** creates a rotation matrix
     *
     * @param axis
     *            axis to rotate around
     * @param angle
     *            angle to rotate in radians
     * @return the new rotation matrix
     * @see #rotateX(double angle)
     * @see #rotateY(double angle)
     * @see #rotateZ(double angle) */
    public pure static Matrix rotate(in Vector axis, in double angle)
    {
        float r = abs(axis);
        if(r == 0)
            return IDENTITY;
        Vector axisv = axis / r;
        float c, s, v;
        c = cos(angle);
        s = sin(angle);
        v = 1 - c; // Versine
        float xx, xy, xz, yy, yz, zz;
        xx = axisv.x * axisv.x;
        xy = axisv.x * axisv.y;
        xz = axisv.x * axisv.z;
        yy = axisv.y * axisv.y;
        yz = axisv.y * axisv.z;
        zz = axisv.z * axisv.z;
        return Matrix(xx + (1 - xx) * c, xy * v - axisv.z * s, xz * v
                + axisv.y * s, 0, xy * v + axisv.z * s, yy + (1 - yy) * c, yz
                * v - axisv.x * s, 0, xz * v - axisv.y * s, yz * v + axisv.x
                * s, zz + (1 - zz) * c, 0);
    }

    /** creates a rotation matrix<br/>
     * the same as <code>Matrix.rotate(new Vector(1, 0, 0), angle)</code>
     *
     * @param angle
     *            angle to rotate around the x axis in radians
     * @return the new rotation matrix
     * @see #rotate(Vector axis, double angle)
     * @see #rotateY(double angle)
     * @see #rotateZ(double angle) */
    public pure static Matrix rotateX(double angle)
    {
        return rotate(Vector.X, angle);
    }

    /** creates a rotation matrix<br/>
     * the same as <code>Matrix.rotate(new Vector(0, 1, 0), angle)</code>
     *
     * @param angle
     *            angle to rotate around the y axis in radians
     * @return the new rotation matrix
     * @see #rotate(Vector axis, double angle)
     * @see #rotateX(double angle)
     * @see #rotateZ(double angle) */
    public pure static Matrix rotateY(double angle)
    {
        return rotate(Vector.Y, angle);
    }

    /** creates a rotation matrix<br/>
     * the same as <code>Matrix.rotate(new Vector(0, 0, 1), angle)</code>
     *
     * @param angle
     *            angle to rotate around the z axis in radians
     * @return the new rotation matrix
     * @see #rotate(Vector axis, double angle)
     * @see #rotateX(double angle)
     * @see #rotateY(double angle) */
    public pure static Matrix rotateZ(double angle)
    {
        return rotate(Vector.Z, angle);
    }

    /** creates a translation matrix
     *
     * @param position
     *            the position to translate (0, 0, 0) to
     * @return the new translation matrix */
    public pure static Matrix translate(Vector position)
    {
        return Matrix(1,
                          0,
                          0,
                          position.x,
                          0,
                          1,
                          0,
                          position.y,
                          0,
                          0,
                          1,
                          position.z);
    }

    /** creates a translation matrix
     *
     * @param x
     *            the x coordinate to translate (0, 0, 0) to
     * @param y
     *            the y coordinate to translate (0, 0, 0) to
     * @param z
     *            the z coordinate to translate (0, 0, 0) to
     * @return the new translation matrix */
    public pure static Matrix translate(in float x, in float y, in float z)
    {
        return Matrix(1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, z);
    }

    /** creates a scaling matrix
     *
     * @param x
     *            the amount to scale the x coordinate by
     * @param y
     *            the amount to scale the y coordinate by
     * @param z
     *            the amount to scale the z coordinate by
     * @return the new scaling matrix */
    public pure static Matrix scale(in float x, in float y, in float z)
    {
        return Matrix(x, 0, 0, 0, 0, y, 0, 0, 0, 0, z, 0);
    }

    /** creates a scaling matrix
     *
     * @param s
     *            <code>s.x</code> is the amount to scale the x coordinate by.<br/>
     *            <code>s.y</code> is the amount to scale the y coordinate by.<br/>
     *            <code>s.z</code> is the amount to scale the z coordinate by.
     * @return the new scaling matrix */
    public pure static Matrix scale(in Vector s)
    {
        return Matrix(s.x, 0, 0, 0, 0, s.y, 0, 0, 0, 0, s.z, 0);
    }

    /** creates a scaling matrix
     *
     * @param s
     *            the amount to scale by
     * @return the new scaling matrix */
    public pure static Matrix scale(in float s)
    {
        return Matrix(s, 0, 0, 0, 0, s, 0, 0, 0, 0, s, 0);
    }

    /** @return the determinant of this matrix */
    public pure @property float determinant()
    {
        return this.x00 * (this.x11 * this.x22 - this.x12 * this.x21)
                + this.x10 * (this.x02 * this.x21 - this.x01 * this.x22)
                + this.x20 * (this.x01 * this.x12 - this.x02 * this.x11);
    }

    /** @return the inverse of this matrix or the identity matrix if this matrix
     *         is singular (has a determinant of 0). */
    public pure Matrix invert()
    {
        float det = this.determinant;
        if(det == 0.0f)
            return IDENTITY;
        float factor = 1.0f / det;
        return Matrix((this.x11 * this.x22 - this.x12 * this.x21) * factor,
                          (this.x12 * this.x20 - this.x10 * this.x22) * factor,
                          (this.x10 * this.x21 - this.x11 * this.x20) * factor,
                          (-this.x10 * this.x21 * this.x32 + this.x11
                                  * this.x20 * this.x32 + this.x10 * this.x22
                                  * this.x31 - this.x12 * this.x20 * this.x31
                                  - this.x11 * this.x22 * this.x30 + this.x12
                                  * this.x21 * this.x30)
                                  * factor,
                          (this.x02 * this.x21 - this.x01 * this.x22) * factor,
                          (this.x00 * this.x22 - this.x02 * this.x20) * factor,
                          (this.x01 * this.x20 - this.x00 * this.x21) * factor,
                          (this.x00 * this.x21 * this.x32 - this.x01 * this.x20
                                  * this.x32 - this.x00 * this.x22 * this.x31
                                  + this.x02 * this.x20 * this.x31 + this.x01
                                  * this.x22 * this.x30 - this.x02 * this.x21
                                  * this.x30)
                                  * factor,
                          (this.x01 * this.x12 - this.x02 * this.x11) * factor,
                          (this.x02 * this.x10 - this.x00 * this.x12) * factor,
                          (this.x00 * this.x11 - this.x01 * this.x10) * factor,
                          (-this.x00 * this.x11 * this.x32 + this.x01
                                  * this.x10 * this.x32 + this.x00 * this.x12
                                  * this.x31 - this.x02 * this.x10 * this.x31
                                  - this.x01 * this.x12 * this.x30 + this.x02
                                  * this.x11 * this.x30)
                                  * factor);
    }

    public pure Matrix concat(Matrix rt) const
    {
        return Matrix(this.x00 * rt.x00 + this.x01 * rt.x10 + this.x02
                * rt.x20, this.x10 * rt.x00 + this.x11 * rt.x10 + this.x12
                * rt.x20, this.x20 * rt.x00 + this.x21 * rt.x10 + this.x22
                * rt.x20, this.x30 * rt.x00 + this.x31 * rt.x10 + this.x32
                * rt.x20 + rt.x30, this.x00 * rt.x01 + this.x01 * rt.x11
                + this.x02 * rt.x21, this.x10 * rt.x01 + this.x11 * rt.x11
                + this.x12 * rt.x21, this.x20 * rt.x01 + this.x21 * rt.x11
                + this.x22 * rt.x21, this.x30 * rt.x01 + this.x31 * rt.x11
                + this.x32 * rt.x21 + rt.x31, this.x00 * rt.x02 + this.x01
                * rt.x12 + this.x02 * rt.x22, this.x10 * rt.x02 + this.x11
                * rt.x12 + this.x12 * rt.x22, this.x20 * rt.x02 + this.x21
                * rt.x12 + this.x22 * rt.x22, this.x30 * rt.x02 + this.x31
                * rt.x12 + this.x32 * rt.x22 + rt.x32);
	}

    public pure Vector apply(Vector v) const
    {
        return Vector(v.x * this.x00 + v.y * this.x10 + v.z * this.x20
                + this.x30, v.x * this.x01 + v.y * this.x11 + v.z * this.x21
                + this.x31, v.x * this.x02 + v.y * this.x12 + v.z * this.x22
                + this.x32);
    }

    public pure Vector applyToNormal(Vector v) const
    {
        return normalize(Vector(v.x * this.x00 + v.y * this.x10 + v.z * this.x20, v.x
                * this.x01 + v.y * this.x11 + v.z * this.x21, v.x * this.x02
                + v.y * this.x12 + v.z * this.x22));
    }

    public pure @property Matrix removeTranslate()
    {
        return Matrix(this.x00,
                          this.x10,
                          this.x20,
                          0,
                          this.x01,
                          this.x11,
                          this.x21,
                          0,
                          this.x02,
                          this.x12,
                          this.x22,
                          0);
    }

    public static immutable Matrix IDENTITY = Matrix(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0);
    public static immutable Matrix ROTATEX_PI_2 = rotateX(PI / 2);
    public static immutable Matrix ROTATEX_PI = rotateX(PI);
    public static immutable Matrix ROTATEX_3_PI_2 = rotateX(3 * PI / 2);
    public static immutable Matrix ROTATEY_PI_2 = rotateY(PI / 2);
    public static immutable Matrix ROTATEY_PI = rotateY(PI);
    public static immutable Matrix ROTATEY_3_PI_2 = rotateY(3 * PI / 2);
    public static immutable Matrix ROTATEZ_PI_2 = rotateZ(PI / 2);
    public static immutable Matrix ROTATEZ_PI = rotateZ(PI);
    public static immutable Matrix ROTATEZ_3_PI_2 = rotateZ(3 * PI / 2);

    public pure static Matrix thetaPhi(double theta, double phi)
    {
        Matrix t = Matrix.rotateX(-phi);
        return rotateY(theta).concat(t);
    }
}

