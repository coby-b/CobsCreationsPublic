/**
 *  file scripts/playerscript.d
 *  Handles player movement, rotation, shooting, and cooldowns based on flags
 */
module scripts.playerscript;

import resourcemanager, gameapplication, gameobject, scene;
import component, vector, scenetree, camera, configuration;
import bindbc.sdl;
import std.math, std.stdio;

/** World width limit for player boundaries */
int maxWorldWidth  = FULL_WORLD_WIDTH;
/** World height limit for player boundaries */
int maxWorldHeight = FULL_WORLD_HEIGHT;


/**
 *  Class PlayerScript
 *  Applies thrust, rotation, shooting, and flag‑driven power‑ups to the player
 */
class PlayerScript : ScriptComponent {
    /** Current velocity vector */
    vec2d velocity;
    /** Base thrust force */
    float thrust = 150.0f;
    /** Rotation speed in degrees/sec */
    float rotationSpeed = 180.0f;
    /** Current cooldown timer for shooting */
    float coolDown = 0.0f;
    /** Maximum cooldown duration */
    float maxCoolDown = 0.75f;
    /** Triple‑shot flag enabled */
    bool tripleShot = false;

    /**
     *  Construct a PlayerScript, adjusting parameters based on flags
     *  Params:
     *      owner = The GameObject this script is attached to
     */
    this(GameObject owner) {
        mOwner = owner;
        mTransformRef = cast(TransformComponent) owner.mComponents[COMPONENTS.TRANSFORM];
        velocity = vec2d(0, 0);
        if (mOwner.hasFlag("SpeedBoost")) {
            thrust = 200.0f;
            //writeln("SDF");
        }
        if (mOwner.hasFlag("TripleShot")) {
            maxCoolDown += 0.5f;
            tripleShot = true;
        }
        if (mOwner.hasFlag("QuickReload")) {
            maxCoolDown -= 0.2f;
        }
    }
    /**
     *  Handle keyboard input for rotation, thrust, and shooting
     *  Params:
     *      event = Pointer to SDL_Event
     *      deltaTime = Time elapsed since last frame, in seconds
     */
    override void input(SDL_Event* event, float deltaTime) {
        //find current keyboard state and change
        //direction and/or move forward accordiblgy
        auto keystate = SDL_GetKeyboardState(null);
        if (keystate[SDL_SCANCODE_A]) {
            //multiplying the rotation speed based on 60fps to make
            //it smoot for the user
            mTransformRef.rotationAngle -= rotationSpeed * deltaTime;

        }
        if (keystate[SDL_SCANCODE_D]) {
            mTransformRef.rotationAngle += rotationSpeed * deltaTime;
        }
        if (keystate[SDL_SCANCODE_W]) {
            /*float _x = cos(mTransformRef.rotationAngle);
            float _y = sin(mTransformRef.rotationAngle);
            velocity = velocity + vec2d(_x, _y) * thrust * 0.016f;*/
            //
            /*float _x = cos(mTransformRef.rotationAngle);
            float _y = sin(mTransformRef.rotationAngle);
            velocity = (vec2d(_x, _y) * thrust * deltaTime) + velocity;*/

            float angleRadians = (mTransformRef.rotationAngle - 90) * (PI / 180);
            float _x = cos(angleRadians);
            float _y = sin(angleRadians);
            velocity = velocity + vec2d(_x, _y) * thrust *  deltaTime;
        }
        if (keystate[SDL_SCANCODE_SPACE]) {
            if (coolDown <= 0) {
                auto game = mOwner.GameRef;
                game.CreateProjectile(mOwner, 0, mOwner.mFlagMask);
                if (tripleShot) {
                    game.CreateProjectile(mOwner, -15, mOwner.mFlagMask);
                    game.CreateProjectile(mOwner, 15, mOwner.mFlagMask);
                }
                //game.CreateProjectile(mOwner, 60);
                //game.CreateProjectile(mOwner, 120);
                //game.CreateProjectile(mOwner, 180);
                //game.CreateProjectile(mOwner, 240);
                //game.CreateProjectile(mOwner, 300);
                coolDown = maxCoolDown;
            }
        }
    }
    /**
     *  Update position, enforce world boundaries, apply friction, and reduce cooldown
     *  Params:
     *      deltaTime = Time elapsed since last frame, in seconds
     */
    override void update(float deltaTime) {
        auto keystate = SDL_GetKeyboardState(null);
        if (keystate[SDL_SCANCODE_W]) {
            /*float _x = cos(mTransformRef.rotationAngle);
            float _y = sin(mTransformRef.rotationAngle);
            velocity = (vec2d(_x, _y) * thrust * deltaTime) + velocity;*/

            float angleRadians = (mTransformRef.rotationAngle - 90) * (PI / 180);
            float _x = cos(angleRadians);
            float _y = sin(angleRadians);
            velocity = velocity + vec2d(_x, _y) * thrust *  deltaTime;
        }


        //update position based on framerate
        mTransformRef.mPos = mTransformRef.mPos + velocity * deltaTime;
        mTransformRef.mPos.x = border(mTransformRef.mPos.x, 0.0f, maxWorldWidth - mTransformRef.mSize.x);
        mTransformRef.mPos.y = border(mTransformRef.mPos.y, 0.0f, maxWorldHeight - mTransformRef.mSize.y);
        //add some friction so we slow down
        velocity = velocity * 0.99f;
        coolDown -= deltaTime;
        //writeln(mTransformRef.rotationAngle);
    }
    /**
     *  Clamp a value between minVal and maxVal
     *  Params:
     *      val    = Value to clamp
     *      minVal = Minimum allowed
     *      maxVal = Maximum allowed
     *  Returns:
     *      Clamped value
     */
    float border(float val, float minVal, float maxVal) {
        return val < minVal ? minVal : (val > maxVal ? maxVal : val);
    }
}