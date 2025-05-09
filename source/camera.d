/**
 *  file camera.d
 *  Camera for converting between world and screen coordinates
 */
module camera;

import gameapplication, gameobject, vector;
import bindbc.sdl;

/**
 *  Class Camera
 *  Represents a viewport that maps world space to screen space
 */
class Camera {
    /** Center position of the camera in world coordinates */
    vec2d position;
    /** Width of the screen */
    int screenW;
    /** Height of the screen */
    int screenH;

    /**
     *  Construct a Camera
     *  Params:
     *      _position = World coordinate at the center of the screen
     *      w         = Screen width in pixels
     *      h         = Screen height in pixels
     */
    this(vec2d _position, int w, int h) {
        position = _position;
        screenW = w;
        screenH = h;
    }

    /**
     *  Convert world coordinates to screen coordinates
     *  Params:
     *      world = Position in world space
     *  Returns Screen-space position
     */
    vec2d wToS(vec2d world) {
        return vec2d(
            world.x - position.x + (screenW  / 2.0f),
            world.y - position.y + (screenH / 2.0f)
        );
    }

    /**
     *  Convert screen coordinates to world coordinates
     *  Params:
     *      screen = Position in screen space
     *  Returns World-space position
     */
    vec2d sToW(vec2d screen) {
        return vec2d(
            screen.x + position.x - (screenW  / 2.0f),
            screen.y + position.y - (screenH / 2.0f)
        );
    }

    /**
     *  Update the camera center
     *  Params:
     *      newPos = New center position in world coordinates
     */
    void update(vec2d newPos) {
        // Uncomment to follow a player
        // position = newPos;
    }
}