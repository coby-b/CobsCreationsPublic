/**
 *  file scene.d
 *  Abstract Scene interface & MainMenu, GameScene, EditorScene implementations
 */
module scene;

import bindbc.sdl, bindbc.sdl.ttf;
import gameapplication, gameobject, scenetree, camera, vector, component;
import scripts.asteroidscript, scripts.script;
import configuration, templatemanager;
import std.stdio, std.random, std.string, std.json, std.file:write;
import std.conv, std.format;
import bindbc.sdl.bind.sdlevents;

/**
 *  Class Scene
 *  Base interface for input handling, updating & rendering
 */
abstract class Scene {
	/** Game Application back‐pointer */
	GameApplication game;
	/** Shared SDL renderer */
	SDL_Renderer *mRenderer;
	/** Root of objects in this scene */
	SceneTree sceneTree = null;

	/** Construct with application reference 
	 *  Params:
     *      g = Parent GameApplication
	 */
	this (GameApplication g) {
		game = g;
		mRenderer = g.mRenderer;
	}
	/** Clean up any resources */
	void cleanup() {}
    /**
     *  Handle a single SDL_Event
     *  Params:
     *      event = Pointer to SDL_Event
     *      deltaTime = Time since last frame in seconds
     */
	abstract void handleEvent(SDL_Event* event, float deltaTime);
    /**
     *  Update scene logic
     *  Params:
     *      deltaTime = Time since last frame in seconds
     */
	abstract void update(float deltaTime);
    /**
     *  Render scene to the screen
     *  Params:
     *      deltaTime = Time since last frame in seconds
     */
	abstract void render(float deltaTime);
}
/**
 *  Class MainMenu
 *  Presents buttons: Play Default, Build Custom, Play Custom
 */
class MainMenu : Scene {
	/// TTF Font that is used in scene
	TTF_Font* font;
	/// Rectangle for the "Play" button
	SDL_Rect playDefRect;
	/// Texture for the "Play" button
	SDL_Texture* playDefTex;
	/// Rectangle for the "Play" button text
	SDL_Rect playDefText; 
	
	/// Rectangle for the "Build Custom" button
	SDL_Rect buildCustRect;
	/// Texture for the "Build Custom" button
	SDL_Texture* buildCustTex;
	/// Rectangle for the "Build Custom" button text
	SDL_Rect buildCustText; 

	/// Rectangle for the "Play Custom" button
	SDL_Rect playCustRect;
	/// Texture for the "Play Custom" button
	SDL_Texture* playCustTex;
	/// Rectangle for the "Play Custom" button text
	SDL_Rect playCustText; 

    /**
     *  Construct the main menu scene
     *  Params:
     *      g = Parent GameApplication
     */
	this (GameApplication g) {
		super(g);

		//load my font
		font = TTF_OpenFont("assets/fonts/ScoreboardTypeItalicPersonal-nRWO0.ttf".toStringz, 65);
		assert(font !is null, "font failed to open");

		//establish my buttons
		enum btnW = 600;
		enum btnH = 150;
		int btnX = (FULL_WORLD_WIDTH / 2) - (btnW / 2);
		playDefRect = SDL_Rect(btnX, 200, btnW, btnH);
		buildCustRect = SDL_Rect(btnX, 200 + btnH + 25, btnW, btnH);
		playCustRect = SDL_Rect(btnX, 200 + (2 * (btnH + 25)), btnW, btnH);

		makeBtn(playDefTex,  playDefText,  "Play Default", playDefRect);
        makeBtn(buildCustTex, buildCustText, "Build Custom", buildCustRect);
        makeBtn(playCustTex, playCustText, "Play Custom",  playCustRect);
	}

    /**
     *  Helper to create a button texture & text rectangle
     *  Params:
     *      btnTex   = Output texture pointer
     *      txtRect  = Output text SDL_Rect
     *      label    = Button label string
     *      btnRect  = Button bounding SDL_Rect
     */
	void makeBtn (ref SDL_Texture* btnTex, ref SDL_Rect txtRect, string label, SDL_Rect btnRect) {
		auto surf = TTF_RenderText_Solid(font, label.toStringz, SDL_Color(255,255,255,255));
		btnTex = SDL_CreateTextureFromSurface(mRenderer, surf);
		int tw, th;
		SDL_QueryTexture(btnTex, null, null, &tw, &th);
		txtRect = SDL_Rect(
			btnRect.x + (btnRect.w - tw) / 2,
			btnRect.y + (btnRect.h - th) / 2,
			tw, th
		);
		SDL_FreeSurface(surf);
	}
	/** Destroy button textures and font */
	override void cleanup() {
		foreach (t; [playDefTex, buildCustTex, playCustTex])
            if (t !is null) SDL_DestroyTexture(t);
		if (font !is null) {
			TTF_CloseFont(font);
			font = null;
		}
	}
	/** Destructor */
	~this() {
		
	}
    /**
     *  Handle input events on menu
     *  Selects and transitions to the corresponding scene
     */
	override void handleEvent(SDL_Event* event, float deltaTime) {
		//handle quit
		if (event.type == SDL_QUIT) {
			game.mGameIsRunning = false;
			return;
		}

		if (event.type == SDL_MOUSEBUTTONDOWN && event.button.button == SDL_BUTTON_LEFT) {
			//Check if the mous click was on the "Play" button
			int mx = event.button.x;
			int my = event.button.y;
			if (mx >= playDefRect.x && mx <  playDefRect.x + playDefRect.w &&
					my >= playDefRect.y && my <  playDefRect.y + playDefRect.h) {
				// Advance to Level 1
				auto newGame = new GameScene(game, "data/scenes/level1.json", 1);
				//auto newGame = new EditorScene(game);
				game.switchScene(newGame);
				newGame.setupScene();
			}
			// check for build custom
			if (mx >= buildCustRect.x && mx <  buildCustRect.x + buildCustRect.w &&
            		my >= buildCustRect.y && my <  buildCustRect.y + buildCustRect.h) {

            	auto newGame = new EditorScene(game);
            	game.switchScene(newGame);
            	newGame.setupScene();
            	return;
        	}
			// check for play custom
			if (mx >= playCustRect.x && mx <  playCustRect.x + playCustRect.w &&
            		my >= playCustRect.y && my <  playCustRect.y + playCustRect.h) {

				auto newGame = new GameScene(game, "data/scenes/custom_level.json", -1);
				game.switchScene(newGame);
				newGame.setupScene();
				return;
			}
		}
	}
    /** No per-frame logic needed for menu */
	override void update(float deltaTime) {
		
	}
    /** Render the menu buttons */
	override void render(float deltaTime) {
		SDL_SetRenderDrawColor(mRenderer, 0, 10, 5, 255);
        SDL_RenderClear(mRenderer);

        // draw buttons
        //default
		SDL_SetRenderDrawColor(mRenderer, 30,144,255,255);
		SDL_RenderFillRect(mRenderer, &playDefRect);
		SDL_SetRenderDrawColor(mRenderer, 255,255,255,255);
		SDL_RenderDrawRect(mRenderer, &playDefRect);
		SDL_RenderCopy(mRenderer, playDefTex,  null, &playDefText);

		//build custom
		SDL_SetRenderDrawColor(mRenderer, 30,144,255,255);
		SDL_RenderFillRect(mRenderer, &buildCustRect);
		SDL_SetRenderDrawColor(mRenderer, 255,255,255,255);
		SDL_RenderDrawRect(mRenderer, &buildCustRect);
		SDL_RenderCopy(mRenderer, buildCustTex, null, &buildCustText);

		//play cstom
		SDL_SetRenderDrawColor(mRenderer, 30,144,255,255);
		SDL_RenderFillRect(mRenderer, &playCustRect);
		SDL_SetRenderDrawColor(mRenderer, 255,255,255,255);
		SDL_RenderDrawRect(mRenderer, &playCustRect);
		SDL_RenderCopy(mRenderer, playCustTex,  null, &playCustText);

        SDL_RenderPresent(mRenderer);
    }
}

/**
 *  Class GameScene
 *  Runs the actual gameplay: loads a JSON scene and handles collisions
 */
class GameScene : Scene {
	/// Camera for game
	Camera mCamera;
	/// Denotes the player
	GameObject player;
	/// Track of the current score
	int score = 0;
	/// Path to our scene's JSON file
	string sceneFile;
	/// Current level in the game 
	int level;

    /**
     *  Construct a GameScene
     *  Params:
     *      g      = Parent GameApplication
     *      scfile = Path to JSON scene file
     *      lvl    = Level index or -1 for custom
     */
	this (GameApplication g, string scfile, int lvl) {
		super(g);
		level = lvl;
		sceneFile = scfile;
	}
	/** Initialize scene tree, camera, and player object */
	void setupScene() {
		//initialize scene tree, camera, player, and some asteroids
		sceneTree = new SceneTree();
		mCamera = new Camera(vec2d(FULL_WORLD_WIDTH/2.0f, FULL_WORLD_HEIGHT/2.0f), game.WWidth, game.WHeight);
		game.loadScene(sceneFile);

		sceneTree.traverseTree((GameObject obj) {
			if (obj.mName == "player") {
				player = obj;
			}
		});
	}
    /**
     *  Handle input events within game:
     *  - ESC to return to MainMenu
     *  - Pass to GameObject scripts
     */
	override void handleEvent(SDL_Event* event, float deltaTime) {
		//TO DO: HANDLE EVENTS
			//SHIP CONTROLS
			//PROJECTILE CREATION
			//??????????
		if (event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_ESCAPE) {
            auto newGame = new MainMenu(game);
            game.switchScene(newGame);
            return;
        }

		sceneTree.traverseTree((GameObject obj) {
		if(obj !is null && obj.mActive)
			obj.Input(event, deltaTime);
		});

		
	}
	/** Update all GameObjects and camera, then check collisions */
	override void update(float deltaTime) {
		sceneTree.traverseTree((GameObject obj) {
			if(obj !is null && obj.mActive)
				obj.Update(deltaTime);
		});
		//update camera (1:1 following player)
		auto tr = cast(TransformComponent)player.mComponents[COMPONENTS.TRANSFORM];
		mCamera.update(tr.mPos);
		checkCollisions();
	}
	/** Render all GameObjects */
	override void render(float deltaTime) {
		SDL_SetRenderDrawColor(mRenderer, 0, 0, 0, 255);
		SDL_RenderClear(mRenderer);
		//render the tree
		sceneTree.traverseTree((GameObject obj) {
			if(obj !is null && obj.mActive) {
				obj.Render(mRenderer, deltaTime, mCamera);
			}
		});
		SDL_RenderPresent(mRenderer);
	}
	/** Axis-aligned bounding box test */
	bool intersects(vec2d pos1, vec2d size1, vec2d pos2, vec2d size2) {
		return !(pos1.x > pos2.x + size2.x || pos1.x + size1.x < pos2.x ||
			pos1.y > pos2.y + size2.y || pos1.y + size1.y < pos2.y);
	}
    /**
     *  Check collisions between projectiles, asteroids, and player.
     *  Advances levels or resets on win/lose.
     */
	void checkCollisions() {
		GameObject[] objects;
		sceneTree.traverseTree((GameObject obj) {
			objects ~= obj;
		});
		
		foreach (i, obj1; objects) {
			foreach (j, obj2; objects) {
				if (i >= j) continue;
				if (!obj1.mActive || !obj2.mActive) continue;
				
				bool obj1isProj = (obj1.mName == "projectile");
				bool obj2isProj = (obj2.mName == "projectile");
				bool obj1isAst = (obj1.mName == "aliens");
				bool obj2isAst = (obj2.mName == "aliens");

				if ((obj1isProj && obj2isAst) || (obj2isProj && obj1isAst)) {
					auto t1 = cast(TransformComponent)obj1.mComponents[COMPONENTS.TRANSFORM];
					auto t2 = cast(TransformComponent)obj2.mComponents[COMPONENTS.TRANSFORM];
					if (intersects(t1.mPos, t1.mSize, t2.mPos, t2.mSize)) {
						if (obj1isProj) {
							obj1.mActive = false;
							auto astScript = cast(scripts.asteroidscript.AsteroidScript) obj2.mComponents[COMPONENTS.SCRIPT];
							astScript.respawnAsteroid();
						} else {
							obj2.mActive = false;
							auto astScript = cast(scripts.asteroidscript.AsteroidScript) obj1.mComponents[COMPONENTS.SCRIPT];
							astScript.respawnAsteroid();
						}
						score++;
						if (score > 15) {
							writeln("Level Complete");
							if (level == -1 || level == 3) {
								game.switchScene(new MainMenu(game));
							} else if (level == 1) {
								auto newGame = new GameScene(game, "data/scenes/level2.json", 2);
								game.switchScene(newGame);
								newGame.setupScene();
							} else if (level == 2) {
								auto newGame = new GameScene(game, "data/scenes/level3.json", 3);
								game.switchScene(newGame);
								newGame.setupScene();
							}
							
						}
					}
				}

				bool isPlayer = (obj1.mName == "player" || obj2.mName == "player");
				bool isAsteroid = (obj1.mName == "aliens" || obj2.mName == "aliens");
				if (isPlayer && isAsteroid) {
					auto t1 = cast(TransformComponent)obj1.mComponents[COMPONENTS.TRANSFORM];
					auto t2 = cast(TransformComponent)obj2.mComponents[COMPONENTS.TRANSFORM];
					if (intersects(t1.mPos, t1.mSize, t2.mPos, t2.mSize)) {
						obj1.mActive = false;
						obj2.mActive = false;
						game.switchScene(new MainMenu(game));
					}
				}
			}
		}
	}
}

/**
 *  Class EditorScene
 *  Allows placement of GameObject templates with selectable flags
 */
class EditorScene : Scene {
	/** Font for UI text */
    TTF_Font* font;
    /** "Save" button rect & texture */
    SDL_Rect saveBtnRect;
    SDL_Texture* saveBtnTex; ///ditto
    SDL_Rect saveTextRect; ///ditto

    /** Available template names */
    string[] templates;
    /** Currently highlighted template index */
    size_t selTemplate;
    /** Mode: 0 = picking, 1 = placing */
    int popupStage;

    /** Flags for current template */
    string[] currentFlags;
    /** Which flags are active bitmask selection */
    bool[] flagsSelected;
    /** Currently highlighted flag index */
    size_t selFlag;

    /**
     *  Construct the editor scene
     *  Params:
     *      g = Parent GameApplication
     */
    this(GameApplication g) {
        super(g);

		//add the background by default
		//auto bgTpl = game.tm.getObjTemp("background");
        //game.InitializeObject("background", 0, 0, bgTpl.mWidth, bgTpl.mHeight, "");

        font = TTF_OpenFont("assets/fonts/Text.ttf".toStringz, 24);
        assert(font !is null, "Failed to load editor font");

        int btnWidth = 100;
		int btnHeight = 40;
        saveBtnRect = SDL_Rect(game.WWidth - btnWidth - 10, 10, btnWidth, btnHeight);
        
		auto surf = TTF_RenderText_Solid(font, "Save".toStringz, SDL_Color(255,255,255,255));
		saveBtnTex = SDL_CreateTextureFromSurface(mRenderer, surf);
		int tw, th;
		SDL_QueryTexture(saveBtnTex, null, null, &tw, &th);
		saveTextRect = SDL_Rect(
			saveBtnRect.x + (btnWidth - tw) / 2,
			saveBtnRect.y + (btnHeight - th) / 2,
			tw, th
		);
		SDL_FreeSurface(surf);
        

        templates = ["player", "aliens"];//game.tm.getAllTemplateNames();
        selTemplate = 0;
        popupStage  = 0;
		selFlag = 0;
		setCurrentFlags();
    }

	/** Setup the scene tree and background for the scene */
	void setupScene() {
        sceneTree = new SceneTree();

        //add the bg
        auto bgTpl = game.tm.getObjTemp("background");
        game.InitializeObject("background", 0, 0,
            		bgTpl.mWidth, bgTpl.mHeight, "", 0);

    }


    /** Initialize flags for the selected template */
	void setCurrentFlags() {
		auto templateName = templates[selTemplate];
		currentFlags = game.tm.getObjTemp(templateName).mFlags;
		flagsSelected.length = currentFlags.length;
		flagsSelected[] = false;
	}
	/** Cleanup textures and font */
    override void cleanup() {
        if (saveBtnTex !is null) SDL_DestroyTexture(saveBtnTex);
        if (font !is null) TTF_CloseFont(font);
    }
    /**
     *  Handle input for template/flag selection and placement
     */
    override void handleEvent(SDL_Event* e, float deltaTime) {
        if (e.type == SDL_QUIT) {
            game.mGameIsRunning = false;
            return;
        }

		if (e.type == SDL_KEYDOWN && e.key.keysym.sym == SDLK_ESCAPE) {
            auto newGame = new MainMenu(game);
            game.switchScene(newGame);
            return;
        }
		
        //if in the template picker
        if (popupStage == 0 && e.type == SDL_KEYDOWN) {
            switch(e.key.keysym.sym) {
				//Template change
                case SDLK_UP:
                    if (selTemplate > 0) {
						selTemplate--;
						selFlag = 0;
						setCurrentFlags();
					}
                    break;
                case SDLK_DOWN:
                    if (selTemplate + 1 < templates.length) {
						selTemplate++;
						selFlag = 0;
						setCurrentFlags();
					}
                    break;
				//Flag change
				case SDLK_LEFT:
					if (selFlag > 0) selFlag--;
					break;
				case SDLK_RIGHT:
					if (selFlag + 1 < currentFlags.length) selFlag++;
					break;
				//Flag Use
				case SDLK_SPACE: 
					flagsSelected[selFlag] = !flagsSelected[selFlag];
					break;
				//Switch to placer
				case SDLK_RETURN:
					popupStage = 1;
					break;
				default:
            }
            return;
        }

        //if in the placement screen
        if (popupStage == 1 && e.type == SDL_MOUSEBUTTONDOWN &&
            	e.button.button == SDL_BUTTON_LEFT) {
            int mx = e.button.x;
            int my = e.button.y;

            //saving?
            if (mx >= saveBtnRect.x && mx < saveBtnRect.x + saveBtnRect.w &&
                	my >= saveBtnRect.y && my < saveBtnRect.y + saveBtnRect.h) {
                saveScene();
                return;
            }

            //else add the template
            auto tpl = game.tm.getObjTemp(templates[selTemplate]);
			int mask = 0;
			foreach (i, on; flagsSelected) {
				if (on) mask |= 1 << i;
			}
            game.InitializeObject(templates[selTemplate], 
					mx, my, tpl.mWidth, tpl.mHeight, tpl.mScript, mask);
        }
		//escaping to template picker
		if (popupStage == 1 && e.type == SDL_KEYDOWN && e.key.keysym.sym == SDLK_TAB) {
        	popupStage = 0;
        	return;
    	}

    }
    /** No per-frame logic */
    override void update(float deltaTime) {
        
    }
    /** Render editor UI and flag picker */
    override void render(float deltaTime) {
        SDL_SetRenderDrawColor(mRenderer, 50,50,50,255);
        SDL_RenderClear(mRenderer);

        //draw the existing objects
		auto Cam = new Camera(vec2d(game.WWidth/2.0f, game.WHeight/2.0f),
                           game.WWidth, game.WHeight);
        sceneTree.traverseTree((GameObject o) {
            if (o.mActive)
                
				o.Render(mRenderer, deltaTime, Cam);
        });

        //save button
        SDL_SetRenderDrawColor(mRenderer, 80,80,80,255);
        SDL_RenderFillRect(mRenderer, &saveBtnRect);
        SDL_SetRenderDrawColor(mRenderer,255,255,255,255);
        SDL_RenderDrawRect(mRenderer, &saveBtnRect);
        SDL_RenderCopy(mRenderer, saveBtnTex, null, &saveTextRect);

        //show a list of templates
		if (popupStage == 0) {
            SDL_SetRenderDrawColor(mRenderer, 0,0,0,180);
            SDL_Rect full = SDL_Rect(0,0,game.WWidth,game.WHeight);
            SDL_RenderFillRect(mRenderer, &full);

            SDL_Color highlight = SDL_Color(255,215,0,255);
            SDL_Color normal = SDL_Color(255,255,255,255);
            int yInit = 100;
            foreach (i, name; templates) {
                auto color = (i == selTemplate) ? highlight : normal;
                auto surf = TTF_RenderText_Solid(font, name.toStringz, color);
                auto tex = SDL_CreateTextureFromSurface(mRenderer, surf);
                int tw, th;
                SDL_QueryTexture(tex, null, null, &tw, &th);
                SDL_Rect dst = SDL_Rect(50, yInit + (th + 10) * cast(int)i, tw, th);
                SDL_RenderCopy(mRenderer, tex, null, &dst);
                SDL_DestroyTexture(tex);
                SDL_FreeSurface(surf);
            }

			//draw the flags for the current tempalte
			//drawing on right side of the screen
			int flagX = FULL_WORLD_WIDTH - 300;
			int flagY = 100;
			foreach (i, flag; currentFlags) {
				SDL_Color color = flagsSelected[i] ? 
					SDL_Color(0, 255, 0, 255) : //green if its on
					SDL_Color(200, 200, 200, 255);	//white if not

				auto surf = TTF_RenderText_Solid(font, flag.toStringz, color);
				auto tex = SDL_CreateTextureFromSurface(mRenderer, surf);
				int tw, th;
				SDL_QueryTexture(tex, null, null, &tw, &th);
				SDL_Rect dst = SDL_Rect(flagX, flagY + cast(int)i * (th + 10), tw, th);
				SDL_RenderCopy(mRenderer, tex, null, &dst);

				if (i == selFlag) {
					// make a slightly padded rect so the border clears the text nicely
					SDL_Rect border = dst;
					int padX = 8;
					int padY = 4;
					border.x -= padX / 2;
					border.y -= padY / 2;
					border.w  += padX;
					border.h += padY;

					// choose whatever highlight color you like
					SDL_SetRenderDrawColor(mRenderer, 255, 215, 0, 255);  // gold
					SDL_RenderDrawRect(mRenderer, &border);
				}



				SDL_DestroyTexture(tex);
				SDL_FreeSurface(surf);
			}
        }

        SDL_RenderPresent(mRenderer);
    }

    /** Serialize placed objects & flags to JSON file */
   	void saveScene() {
		// Start the JSON
		string json = `{"sceneName":"customLevel","entities":[`;
		bool first = true;

		// Walk every active object in the sceneTree…
		sceneTree.traverseTree((GameObject o) {
			if (!o.mActive) return;
			if (!first) json ~= ",";
			first = false;

			auto tr = cast(TransformComponent)o.mComponents[COMPONENTS.TRANSFORM];
			// Append this entity’s JSON
			json ~= format(
				`{"template":"%s","x":%s,"y":%s,"rotation":%s`,
				o.mName,
				to!int(tr.mPos.x),
				to!int(tr.mPos.y),
				to!int(tr.rotationAngle)
			);
			// Optional flags field
			if (o.mFlagMask != 0)
				json ~= format(`,"flags":%d`, o.mFlagMask);
			json ~= `}`;
		});

		// Close off the array and object
		json ~= `]}`;

		// Write it out
		enum path = "data/scenes/custom_level.json";
		write(path, json);
		writeln("Scene saved to ", path);
	}
}