/**
 *  file component.d
 *  Component system for GameObjects:
 *  - TransformComponent
 *  - TextureComponent
 *  - AnimationComponent
 *  - ScriptComponent
 */
module component;

//This will be where our componenet system is handled,
//will rely very heavily on the resource manager for texture componenets
import resourcemanager, gameapplication, gameobject, vector, camera;

import std.stdio, std.string, std.algorithm, std.conv,std.array, std.file, std.json;
import bindbc.sdl;

/**
 *  Enum COMPONENTS
 *  Indices for GameObject component array
 */
enum COMPONENTS {TEXTURE, TRANSFORM, TEXTURE_ANIMATED, SCRIPT};

/**
 *  Abstract class IComponent
 *  Base for all components, holds owner reference
 */
abstract class IComponent{
    GameObject mOwner;
}

/**
 *  Class TransformComponent
 *  Stores world position, size, and rotation of an object
 */
class TransformComponent : IComponent{
    /** World position */
    vec2d mPos;
    /** World size */
    vec2d mSize;
    /** Rotation angle in degrees */
    float rotationAngle;

    /**
     *  Construct a TransformComponent
     *  Params:
     *      owner = GameObject owner
     *      x     = Initial X position
     *      y     = Initial Y position
     *      w     = Width
     *      h     = Height
     */
    this(GameObject owner, float x, float y, float w, float h){
        mOwner = owner;
        rotationAngle = 0.0f;

        mPos = vec2d(x,y);
        mSize = vec2d(w,h);
        // Initial rectangle position 
        //mRectangle.x = _x;
        //mRectangle.y = _y;

        //auto rm = ResourceManager.getInstance(mRendererRef);
        //mSprite = rm.getTexture(name);
        //mRectangle.w = _w;
        //mRectangle.h = _h;
    }
}

/**
 *  Class TextureComponent
 *  Wraps a Sprite resource for rendering static textures
 */
class TextureComponent : IComponent{
    /** Underlying sprite data */
    Sprite mSprite;
    /** Alias to allow direct sprite access */
    alias mSprite this;


    /**
     *  Construct a TextureComponent
     *  Params:
     *      owner    = GameObject owner
     *      renderer = SDL_Renderer pointer
     *      name     = Resource key for sprite lookup
     */
    this(GameObject owner, SDL_Renderer* renderer, string name) {
        mOwner = owner;

        auto rm = ResourceManager.getInstance(renderer);
        this.mSprite = rm.getTexture(name);

        if (this.mSprite is null) {
            writeln("Failed to retrieve sprite from resource manager");
            writeln("Requested Image: ", name);
            //writeln("Given Bitmap Filepath: ", image);
            //writeln("Given JSON Filepath: ", data);
        }
    }
    /** Destructor cleans up if needed (handled by Sprite) */
    ~this(){
        //Should be handled by the destructor in sprite as
        //the only thing that needs destructing is the texture
    }
}

/**
 *  Class AnimationComponent
 *  Handles animated sprite playback using frame sequences
 */
class AnimationComponent : IComponent {
    /** Sprite containing frames and sequences */
    Sprite mSprite;
    /** Current animation sequence name */
    string mAnimationName;

    /** SDL_Renderer reference for drawing */
    SDL_Renderer* mRendererRef;
    /** Reference to texture component */
    TextureComponent mTextureRef;
    /** Reference to transform component */
    TransformComponent mTransformRef;

    /** Current frame index in sequence */
    int currentIdx;
    /** Whether animation is active */
    bool animating;
    /** Timer accumulating deltaTime */
    float frameTimer = 0.0f;
    /** Seconds between frames */
    float frameDuration = 0.2f;


    /**
     *  Construct an AnimationComponent
     *  Params:
     *      owner = GameObject owner
     *      r     = SDL_Renderer pointer
     *      name  = Resource key for sprite lookup
     */
    this (GameObject owner, SDL_Renderer *r, string name) {
        
        mOwner = owner;
        mRendererRef = r;
        mTextureRef = cast(TextureComponent)mOwner.mComponents[COMPONENTS.TEXTURE];
        mTransformRef = cast(TransformComponent)mOwner.mComponents[COMPONENTS.TRANSFORM];
		animating = false;
        auto rm = ResourceManager.getInstance(mRendererRef);
        mSprite = rm.getTexture(name);
        
        
        if (mSprite.isAnimated) {
            animating = true;
            currentIdx = 0;
            mAnimationName = mSprite.baseAnimation;
        }
        
        //loadAnimations();
    }

    /**
     *  Loop and render an animation sequence
     *  Params:
     *      name      = Sequence name (empty = current)
     *      r         = SDL_Renderer pointer
     *      deltaTime = Time since last frame in seconds
     *      camera    = Camera for world→screen transform
     */
    void LoopAnimationSequence(string name, SDL_Renderer *r, float deltaTime, Camera camera){
        if (name.length == 0) {
            name = mAnimationName;
        }
        if (name !in mSprite.mFrameSequences) {
            writeln("Invalid animation sequence: ", name);
            return;
        }

        if (name != mAnimationName) {
            mAnimationName = name;
            currentIdx = 0;
        }
        
        frameTimer += deltaTime;
        if (frameTimer >= frameDuration) {
            frameTimer -= frameDuration;
            currentIdx = cast (int) ((currentIdx + 1) % mSprite.mFrameSequences[name].length);
        }
        
        int frameNumber = cast (int) (mSprite.mFrameSequences[name][currentIdx]);
        SDL_Rect srcRect = mSprite.mFrames[frameNumber];

        vec2d screenPos = camera.wToS(mTransformRef.mPos);
        SDL_Rect destRect;
        destRect.x = cast(int)screenPos.x;
        destRect.y = cast(int)screenPos.y;


        destRect.w = cast(int) mTransformRef.mSize.x;
        destRect.h = cast(int) mTransformRef.mSize.y;
        //destRect.w = srcRect.w;
        //destRect.h = srcRect.h;
        SDL_Point pivot;
        pivot.x = cast(int)(mTransformRef.mSize.x / 2);
        pivot.y = cast(int)(mTransformRef.mSize.y / 2);
        //SDL_RenderCopy(r, mTextureRef.mTexture, &srcRect, &destRect);
        SDL_RenderCopyEx(r, mTextureRef.mTexture, &srcRect, &destRect, 
                                mTransformRef.rotationAngle, &pivot, SDL_FLIP_NONE);

    }
    /**
     *  Render a static, non‑animated sprite
     *  Params:
     *      r      = SDL_Renderer pointer
     *      camera = Camera for world→screen transform
     */
    void renderNonAnimated(SDL_Renderer *r, Camera camera) {
        SDL_Rect destRect;// = SDL_Rect(mTransformRef.mRectangle.x, mTransformRef.mRectangle.y, 
                                            //mTransformRef.mRectangle.w, mTransformRef.mRectangle.h);
        vec2d screenPos = camera.wToS(mTransformRef.mPos);

        destRect.x = cast(int) screenPos.x;
        destRect.y = cast(int) screenPos.y;
        destRect.w = cast(int) mTransformRef.mSize.x;
        destRect.h = cast(int) mTransformRef.mSize.y;
        SDL_Point pivot;
        pivot.x = cast(int)(mTransformRef.mSize.x / 2);
        pivot.y = cast(int)(mTransformRef.mSize.y / 2);
        //SDL_RenderCopy(r, mTextureRef.mSprite.mTexture, null, &destRect);
        SDL_RenderCopyEx(r, mTextureRef.mTexture, null, &destRect, 
                                mTransformRef.rotationAngle, &pivot, SDL_FLIP_NONE);
    }
}

/**
 *  Abstract class ScriptComponent
 *  Base for GameObject behavior scripts
 */
abstract class ScriptComponent : IComponent {
    /** Reference to transform component */
    TransformComponent mTransformRef;

    /**
     *  Update behavior each frame
     *  Params:
     *      deltaTime = Time since last frame in seconds
     */
    void update(float deltaTime) {}

    /**
     *  Handle per-event input
     *  Params:
     *      event     = SDL_Event pointer
     *      deltaTime = Time since last frame in seconds
     */
    void input(SDL_Event* event, float deltaTime) {}
}