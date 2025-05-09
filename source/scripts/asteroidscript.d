/**
 *  file scripts/asteroidscript.d
 *  Handles asteroid movement, bouncing off world bounds, and respawning
 */
module scripts.asteroidscript;

import resourcemanager, gameapplication, gameobject, scene;
import component, vector, scenetree, camera, configuration;
import bindbc.sdl;
import std.math, std.random;

/** World width constant for boundary checks */
int fullWorldWidth  = FULL_WORLD_WIDTH;
/** World height constant for boundary checks */
int fullWorldHeight = FULL_WORLD_HEIGHT;

/**
 *  Class AsteroidScript
 *  Applies randomized velocity to asteroids, handles boundary bouncing,
 *  and respawns upon destruction
 */
class AsteroidScript : ScriptComponent {
    /** Current velocity vector of the asteroid */
    vec2d velocity;

    /**
     *  Construct an AsteroidScript with random initial velocity modified by flags
     *  Params:
     *      owner = The GameObject this script is attached to
     */
    this(GameObject owner) {
        mOwner = owner;
        mTransformRef = cast(TransformComponent) mOwner.mComponents[COMPONENTS.TRANSFORM];

        float _x = uniform(-50.0f, 50.0f);
        float _y = uniform(-50.0f, 50.0f);
        velocity = vec2d(_x, _y);

        if (mOwner.hasFlag("SpeedBoost")) {
            velocity.x += 10;
            velocity.y += 10;
        }
        if (mOwner.hasFlag("Small")) {
            mTransformRef.mSize.x -= 10;
            mTransformRef.mSize.y -= 10;
            velocity.x -= 5;
            velocity.y -= 5;
        }
        if (mOwner.hasFlag("Large")) {
            mTransformRef.mSize.x += 10;
            mTransformRef.mSize.y += 10;
            velocity.x += 5;
            velocity.y += 5;
        }
        if (mOwner.hasFlag("SideToSide")) {
            velocity.y = 0.0f;
        }
        if (mOwner.hasFlag("UpDown")) {
            velocity.x = 0.0f;
        }
    }

    /**
     *  Update asteroid position and bounce off edges of the world bounds
     *  Params:
     *      deltaTime = Time elapsed since last frame, in seconds
     */
    override void update(float deltaTime) {
        mTransformRef.mPos = mTransformRef.mPos + (velocity * deltaTime);

        auto tr = mTransformRef.mPos;
        auto sz = mTransformRef.mSize;

        if (tr.x <= 0 || tr.x + sz.x >= fullWorldWidth) {
            velocity.x = -velocity.x;
        }
        if (tr.y <= 0 || tr.y + sz.y >= fullWorldHeight) {
            velocity.y = -velocity.y;
        }
    }

    /**
     *  Input handler (unused for asteroids)
     */
    override void input(SDL_Event* event, float deltaTime) {}

    /**
     *  Respawn the asteroid at a random position within the world bounds
     *  and reactivate it
     */
    void respawnAsteroid() {
        int p_x = cast(int) uniform(0, fullWorldWidth - 40);
        int p_y = cast(int) uniform(0, fullWorldHeight - 40);
        this.mTransformRef.mPos = vec2d(p_x, p_y);
        this.mOwner.mActive = true;
    }
}