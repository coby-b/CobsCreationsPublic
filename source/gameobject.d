/** 
 *  file gameobject.d
 *  GameObject class & its component management
 */
module gameobject;

import std.stdio, std.algorithm, std.conv, std.array;
import resourcemanager, component, scripts.script, gameapplication, camera, templatemanager;
import bindbc.sdl;

/**
 *  Class GameObject
 *  A drawable, updatable entity composed of components
 */
class GameObject {
    /** Back‐reference to the application */
    GameApplication GameRef;
    /** Is the object active? */
    bool mActive;
    /** Array of attached components */
    IComponent[COMPONENTS] mComponents; 
    /** Template name */
    string mName;
    /** Unique object ID */
    int mID;
    //** Name of next animation in the loop */
    string nextAnimation = "";
    /** Script component name. */
    string mScriptName;
    /** Bitmask of flags */
    int mFlagMask;

    /**
     *  Construct a new GameObject
     *  Params:
     *      game = Application reference
     *      objID = Unique ID
     *      renderer = SDL renderer
     *      name = Template key
     *      x = X Position
     *      y = Y Position
     *      w = Width
     *      h = Height
     *      script = Script key
     *      mask = Flags bitmask.
     */
    this(GameApplication game, int objID, SDL_Renderer* renderer, string name, 
                            float x, float y, float w, float h, string script, int mask) {

        GameRef = game;
        mID = objID;
        mName = name;
        mActive = true;

        //initialize components
        mComponents[COMPONENTS.TEXTURE] = new TextureComponent(this, renderer, name);
        mComponents[COMPONENTS.TRANSFORM] = new TransformComponent(this, x, y, w, h);
        mComponents[COMPONENTS.TEXTURE_ANIMATED] = new AnimationComponent(this, renderer, name);

        mFlagMask = mask;
        mScriptName = script;
        mComponents[COMPONENTS.SCRIPT] = getScript(this, script);
    }

    /** Destructor */
    ~this() {}

    /**
     *  Handle input event for this object
     *  Params:
     *      event = SDL_Event pointer
     *      deltaTime = Seconds since last frame
     */
    void Input(SDL_Event *event, float deltaTime){
        //Run the Script componenet for input
        if (this.mComponents[COMPONENTS.SCRIPT] is null) return;
        ScriptComponent sc = cast(ScriptComponent)this.mComponents[COMPONENTS.SCRIPT];
        sc.input(event, deltaTime);
    }

    /**
     *  Update this object’s state
     *  Params:
     *       deltaTime = Seconds since last frame
     */
    void Update(float deltaTime){
        //Run the script componenet for update
        if (this.mComponents[COMPONENTS.SCRIPT] is null) return;
        ScriptComponent sc = cast(ScriptComponent)this.mComponents[COMPONENTS.SCRIPT];
        sc.update(deltaTime);
    }
    /**
     *  Render via its texture/animation component
     *  Params: 
     *      renderer = SDL_Renderer pointer
     *      deltaTime = Seconds since last frame
     *      camera = Camera for world→screen transform
     */
    void Render(SDL_Renderer* renderer, float deltaTime, Camera camera){
        TextureComponent text = (cast(TextureComponent)this.mComponents[COMPONENTS.TEXTURE]);
        AnimationComponent animator = cast(AnimationComponent) this.mComponents[COMPONENTS.TEXTURE_ANIMATED];
        if (text.mSprite.isAnimated) {
            animator.LoopAnimationSequence(nextAnimation, renderer, deltaTime, camera);
        } else {
            animator.renderNonAnimated(renderer, camera);
        }
    }
    /**
     *  Check if a named flag is set on this object
     *  Params: 
     *      flagName = Name of the flag
     *  Returns: True if set
     */
    bool hasFlag(string flagName) {
        auto flags = GameRef.tm.getObjTemp(mName).mFlags;
        int idx = -1;
        for (int i = 0; i < flags.length; i++) {
            if (flags[i] == flagName) {
                idx = i;
                break;
            }
        }
        if (idx < 0) return false;
        return (mFlagMask & (1 << idx)) != 0;
    }
}
