/** file gameapplication.d
    brief Class for a game
 */
module gameapplication;
// Import D standard libraries
import std.stdio, std.string, core.atomic, std.random, std.conv, std.math, std.json, std.file;
import core.atomic;

// Third-party libraries
import bindbc.sdl;
import bindbc.sdl.mixer;
import bindbc.sdl.ttf;

//Import other modules
import sdl_abstraction, resourcemanager, component, gameobject, scripts.script;
import scripts.projectilescript, scenetree, scene, vector, templatemanager, configuration;

/** 
 * Class GameApplication
 * Manages the window setup, resource / template loading, scene switching, and the main game loop
 */
class GameApplication {
    /** Command Line Arguments */
    string[] mArgs;
    /** SDL Window */
    SDL_Window* mWindow = null;
    /** SDL Renderer */
    SDL_Renderer* mRenderer = null;
    /** Whether or not game is running */
    bool mGameIsRunning = true;
    /** SDL Window width */
    int WWidth = FULL_WORLD_WIDTH;
    /** SDL Window Height */
    int WHeight = FULL_WORLD_HEIGHT;
    /** Current active scene */
    Scene currentScene;
    /** Game Object ID */
    shared int mObjID = 0;
    /** Resource Manager */
    ResourceManager rm;
    /** Template Manager */
    TemplateManager tm;

    /** 
     *  Constructor, initializes SDL, TTF, Mixer, resources, templates, and the main menu 
     *  Params: 
     *      title = Game Title
     *      args = Command line arguments
     */
    this(string title, string[] args){
        //store our args
        mArgs = args;
        //set up mixer
        auto mixerSupport = loadSDLMixer();
        if (mixerSupport == SDLMixerSupport.noLibrary) {
            writeln("SDL_mixer library could not be loaded");
        }
        //set up ttf
        auto ttfSupport = loadSDLTTF();
        if (ttfSupport == SDLTTFSupport.noLibrary) {
            writeln("SDL_ttf library could not be loaded");
        }

        // Create an SDL window
        mWindow = SDL_CreateWindow(title.toStringz, SDL_WINDOWPOS_UNDEFINED, 
                SDL_WINDOWPOS_UNDEFINED, WWidth, WHeight, SDL_WINDOW_SHOWN);

        // Create a hardware accelerated mRenderer
        mRenderer = SDL_CreateRenderer(mWindow,-1,SDL_RENDERER_ACCELERATED);

        assert(TTF_Init() == 0, "TTF_Init failed");
        //start our resource manager
        rm = ResourceManager.getInstance(mRenderer);
        //load the files we are using
        loadResources();
        //load object templates
        tm = new TemplateManager();
        tm.loadTemplates("data/gameObjects.json");
        //start the main menu
        currentScene = new MainMenu(this);
    }   

    /// Destructor
    ~this(){
        if (currentScene !is null) {
            currentScene.cleanup();
        }
        TTF_Quit();
        // Destroy our renderer
        SDL_DestroyRenderer(mRenderer);
        // Destroy our window
        SDL_DestroyWindow(mWindow);
    }
    /** Preload our texture assets */
    void loadResources() {
        rm.loadTexture("player", "assets/images/player.bmp", "assets/images/player.json");
        rm.loadTexture("projectile", "assets/images/projectile.bmp", "assets/images/projectile.json");
        rm.loadTexture("aliens", "assets/images/aliens.bmp", "assets/images/aliens.json");
        rm.loadTexture("background", "assets/images/background.bmp", "assets/images/background.json");
    }
    /** 
     *  Deserialize a scene's JSON file and spawn all game objects
     *  Params:
     *       sceneFilePath = A path to a JSON file
     */
    void loadScene(string sceneFilePath) {
        string jsonTxt = readText(sceneFilePath);
        JSONValue j = parseJSON(jsonTxt);
        assert(j.type == JSONType.object, "Scene has to be a json obj");

        //not sure if im using this but might as well save it
        string sceneName = j["sceneName"].str;

        //loop through the entities and initialize the objects
        foreach (entity; j["entities"].array) {
            string name = entity["template"].str;
            int x = cast(int) entity["x"].integer;
            int y = cast(int) entity["y"].integer;
            float rotation = 0.0f;
            if ("rotation" in entity.object) {
                rotation = cast(float) entity["rotation"].integer;
            }
            int mask = 0;
            if ("flags" in entity.object) {
                mask = cast(int) entity["flags"].integer;
            }

            //get objects template
            ObjTemplate t = tm.getObjTemp(name);
            //initialize object based on scene data and template
            auto obj = InitializeObject(name, x, y, t.mWidth, t.mHeight, t.mScript, mask);
            //set the rotation angle based on scene data
            auto trans = cast(TransformComponent) obj.mComponents[COMPONENTS.TRANSFORM];
            trans.rotationAngle = rotation;
        }
    }
    /**
     *  Create an instance of a game object and save it to the scene tree
     *  Params:
     *      name = Template Name
     *      _x = X Position
     *      _y = Y Position
     *      _w = Width
     *      _h = Height
     *      script = Script name
     *      mask = Bitmask of flags
     *  Returns: The created object
     */
    GameObject InitializeObject(string name, int _x, int _y, int _w, int _h, string script, int mask) {
        GameObject newObj = new GameObject(this, mObjID, mRenderer, name,
                                                _x, _y, _w, _h, script, mask);

        if (currentScene.sceneTree !is null) {
            currentScene.sceneTree.addObject(newObj);
        } else {
            writeln("Attempted to add object to scene with no scene tree");
        }
        
        mObjID.atomicOp!"+="(1);
        return newObj;
    }
    /** 
     *  Create and instance of a projectile
     *  Params:
     *      creator = Object which is shooting the projectile
     *      change = Degree of difference between creator's rotation angle and the projectile spawn
     *      mask = Bitmask of flags for the projectile
     *  Returns: The created projectile
     */
    GameObject CreateProjectile(GameObject creator, int change, int mask) {
        TransformComponent tr = cast(TransformComponent) creator.mComponents[COMPONENTS.TRANSFORM];
        vec2d start = tr.mPos;
        //vec2d objW = tr.mSize;
        GameObject pj = InitializeObject("projectile", cast(int)(start.x + 12), cast(int)(start.y), 
                                                25, 25, "projectilescript", mask);
        //set the direction
        vec2d direction = vec2d(cos((tr.rotationAngle - 90+change)* (PI / 180)),
                                 sin((tr.rotationAngle - 90+change)* (PI / 180)));

        //set the velocity
        auto pScript = cast(scripts.projectilescript.ProjectileScript) pj.mComponents[COMPONENTS.SCRIPT];
        pScript.velocity = direction * 300.0f;

        return pj;
    }

    /** 
     *  Poll SDL events and pass them to the current scene 
     *  Params:
     *      deltaTime = Change of time between scenes
    */
    void Input(float deltaTime){
        SDL_Event event;
        // Start our event loop
        while(SDL_PollEvent(&event)){
            // Handle each specific event
            switch (event.type) {
                case SDL_QUIT:
                    mGameIsRunning = false;
                    break;
                default:
                    currentScene.handleEvent(&event, deltaTime);
            }
        }

    }
    /** 
     *  Update game and objects
     *  Params:
     *      deltaTime = Change of time between scenes
     */
    void Update(float deltaTime) {
        currentScene.update(deltaTime);
    }
    /** 
     *  Render the current scene
     *  Params:
     *      deltaTime = Change of time between scenes
    */
    void Render(float deltaTime) {
        // Set the render draw color 
        SDL_SetRenderDrawColor(mRenderer,100,190,255,SDL_ALPHA_OPAQUE);
        // Clear the renderer each time we render
        SDL_RenderClear(mRenderer);

        currentScene.render(deltaTime);
        // Final step is to present what we have copied into
        // video memory
        SDL_RenderPresent(mRenderer);
    }

    /** Advance world one frame at a time */
    void AdvanceFrame(float deltaTime){
        Input(deltaTime);
        Update(deltaTime);
        Render(deltaTime);
    }
    /** Run the main loop at 60 fps */
    void RunLoop(){
        const uint frameDelay = 1000/60;
        uint previousTicks = SDL_GetTicks();

        while (mGameIsRunning) {
            uint currentTicks = SDL_GetTicks();
            float deltaTime = (currentTicks - previousTicks) / 1000.0f;
            previousTicks = currentTicks;

            AdvanceFrame(deltaTime);

            uint frameTime = SDL_GetTicks() - currentTicks;
            if (frameDelay > frameTime) {
                SDL_Delay(frameDelay - frameTime);
            }
        }
    }
    /**
     *  Switch to new scene
     *  Params:
     *      newScene = New scene to switch to
     */
    void switchScene(Scene newScene) {
        currentScene = newScene;
    }
}

