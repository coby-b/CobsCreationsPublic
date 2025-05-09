/**
 *  file vector.d
 *  2D vector struct with basic arithmetic and normalization
 */
module vector;

import std.math;

/**
 *  Struct vec2d
 *  Represents a two-dimensional vector of floats
 */
struct vec2d {
    /** X component of the vector */
    float x;
    /** Y component of the vector */
    float y;

    /**
     *  Construct a vec2d
     *  Params:
     *      _x = Initial X component
     *      _y = Initial Y component
     */
    this (float _x, float _y) {
        this.x = _x;
        this.y = _y;
    }

    /**
     *  Add two vectors
     *  Params:
     *      b = Vector to add
     *  Returns: The sum
     */
    vec2d opBinary(string op)(vec2d b) if (op == "+") {
        return vec2d(x + b.x, y + b.y);
    }
    
    /**
     *  Scale a vector by a scalar
     *  Params:
     *      scale = Scaling factor
     *  Returns: The scaled vector
     */
    vec2d opBinary(string op)(float scale) if (op == "*") {
        return vec2d(x * scale, y * scale);
    }
    
    /**
     *  Subtract one vector from another
     *  Params:
     *      b = Vector to subtract
     *  Returns: The difference
     */
    vec2d opBinary(string op)(vec2d b) if (op == "-") {
        return vec2d(x - b.x, y - b.y);
    }

    /**
     *  Compute the length of the vector
     *  Returns: sqrt(x*x + y*y)
     */
    float distance() {
        return sqrt((x * x) + (y * y));
    }

    /**
     *  Normalize the vector to unit length
     *  Returns: Unit vector in same direction, or (0,0) if zero-length
     */
    vec2d normalize() {
        float dist = distance();
        if (dist == 0) {
            return vec2d(0, 0);
        } else {
            return vec2d(x / dist, y / dist);
        }
    }
}