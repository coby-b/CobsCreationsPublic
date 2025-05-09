/**
 *  file scripts/projectilescript.d
 *  Manages projectile behavior: movement, lifetime, growth, and bouncing
 */
module scripts.projectilescript;

import resourcemanager, gameapplication, gameobject, scene;
import component, vector, scenetree, camera, configuration;
import bindbc.sdl;
import std.math;


/** World width for bounce boundaries */
int fullWorldWidth  = FULL_WORLD_WIDTH;
/** World height for bounce boundaries */
int fullWorldHeight = FULL_WORLD_HEIGHT;

/**
 *  Class ProjectileScript
 *  Controls a projectile's velocity, lifespan, growth, and bouncing
 */
class ProjectileScript : ScriptComponent {
    /** Current velocity vector */
    vec2d velocity;
    /** Remaining life time in seconds */
    float life = 2.0f;
    /** Grow in size over time if true */
    bool grow = false;
    /** Bounce off world edges if true */
    bool bounce = false;

    /**
     *  Construct a ProjectileScript, adjusting behavior based on flags
     *  Params:
     *      owner = The GameObject this script is attached to
     */
    this(GameObject owner) {
        mOwner = owner;
        mTransformRef = cast(TransformComponent) owner.mComponents[COMPONENTS.TRANSFORM];
        velocity = vec2d(0, 0);
        if (mOwner.hasFlag("BulletGrow")) grow = true;
        if (mOwner.hasFlag("BulletSustain")) life += 0.6f;
        if (mOwner.hasFlag("BulletBounce")) bounce = true;
    }

    /**
     *  Update projectile position, handle growth, bouncing, and expiration
     *  Params:
     *      deltaTime = Time elapsed since last frame
     */
    override void update(float deltaTime) {
        mTransformRef.mPos = mTransformRef.mPos + velocity * deltaTime;
        //decrement life
        life -= deltaTime;
        if (life <= 0) mOwner.mActive = false;
        if (grow) {
            mTransformRef.mSize.x += 0.2f;
            mTransformRef.mSize.y += 0.3f;
        }
        if (bounce) {
            auto tr = mTransformRef.mPos;
            auto sz = mTransformRef.mSize;
            //auto txt = mTextureRef.
            if (tr.x <= 0 || tr.x + sz.x >= fullWorldWidth) {
                velocity.x = velocity.x * -1;
            }
            if (tr.y <= 0 || tr.y + sz.y >= fullWorldHeight) {
                velocity.y = velocity.y * -1;
            }
        }
    }
    /**
     *  Input is not used for projectiles
     *  Params:
     *      event     = Pointer to SDL_Event
     *      deltaTime = Time since last frame
     */
    override void input(SDL_Event* event, float deltaTime) {
        
    }
}