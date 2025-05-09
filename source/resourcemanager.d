/**
 *  file resourcemanager.d
 *  Loads and caches Sprites (textures + frame data)
 */
module resourcemanager;

import std.stdio, std.string, std.json, std.file, std.algorithm, std.array;
import bindbc.sdl;
import sdl_abstraction;

/*
    General parametes regarding resource loading
    - When attempting to access a certain image we will call loadTexture
        - Input:
            - name: the name for a given image (eg. a pic of mario may be called mario 
                (or something else bc of copyirght :) ))
            - image: a file path to the bitmap image
            - data a file path to the json file with the images metadata
    - Sprite Struct:
        - mTexture: the actual texture for our image
        - width ... columns: meta data for the image from json file
    - When creating texture componenets we will get a sprite from the RM, 
        use the sprite.texture to get a pointer to the actual texture, 
        and then likely copy over the relevant meta data
    -JSON Formatting Guidelines:
        - "format":
            - Required fields:
                - width
                - height
            - Required fields if animating:
                - all of the above
                - tileWidth
                - tileHeight
                - baseAnimation
        - "frames" (if animating):
            - "[animation name]" : array of ints corresponding to frames in animation sequence

*/

/**
 *  Class Sprite
 *  Wraps an SDL_Texture and its animation frames
 */
class Sprite {
    /** Underlying SDL texture */
    SDL_Texture* mTexture;  
    /** Full image size */
    int width, height;
    /** Frame size */
    int tile_width, tile_height;
    /** Frames per row */
    int columns; 
    /** True if multi–frame */
    bool isAnimated;
    /** Frame sequences by name */
    long [][string] mFrameSequences;
    /** All frame rectangles */
    SDL_Rect[] mFrames;
    /** Default animation name */
    string baseAnimation = "";

    /**
     *  Load a texture and its JSON metadata
     *  Params: 
     *      renderer = SDL renderer
     *      image = Path to BMP
     *      data = Path to JSON metadata
     */
    this(SDL_Renderer* renderer, string image, string data) {
        //Load in the texture
        SDL_Surface* surface = SDL_LoadBMP(image.toStringz);
        this.mTexture  = SDL_CreateTextureFromSurface(renderer, surface);
        SDL_FreeSurface(surface);

        //Load in the metadata
        //Initialize to a json object
        string fileData = readText(data);
        JSONValue j = parseJSON(fileData);
        if (j.type != JSONType.object) {
            writeln("Failed to open json file");
            return;
        }
		this.width = cast(int) j["format"]["width"].integer;
		this.height = cast(int) j["format"]["height"].integer;
        //These just check if user only gave us height and width
        //useful for non-animated objects
        if ("tileWidth" in j["format"].object && "tileHeight" in j["format"].object) {
            tile_width = cast(int) j["format"]["tileWidth"].integer;
		    tile_height = cast(int) j["format"]["tileHeight"].integer;
            columns = width / tile_width;
            isAnimated = true;
        } else {
            tile_width = width;
            tile_height = height;
            columns = 1;
            isAnimated = false;
        }

        
        if(isAnimated) {
            //loop through the json animation lists
		    foreach (key, value; j["frames"].object) {
			    mFrameSequences[key] = value.array.map!(v => v.integer).array;
		    }
            if ("baseAnimation" in j["format"].object) {
                baseAnimation = j["format"]["baseAnimation"].str;
            } else {
                writeln("baseAnimation not in JSON for");
                if (j["frames"].object.keys.length > 0)
                    baseAnimation = j["frames"].object.keys.array[0];
                else
                    baseAnimation = "";
            }
            if (baseAnimation !in mFrameSequences) {
                writeln("baseAnimation '", baseAnimation, "' not in animation sequences");
            }
            loadAnimations();
        }
    }
     /** Destructor */
    ~this() {
        SDL_DestroyTexture(mTexture);
    }

    /**
     *  Compute the source rectangle for a given frame index
     *  Params:
     *      frameIndex = Index in the frame array
     *  Returns: Corresponding SDL_Rect
     */
    SDL_Rect getFrameRect(int frameIndex) {
        int x = (frameIndex % columns) * tile_width;
        int y = (frameIndex / columns) * tile_height;
        return SDL_Rect(x, y, tile_width, tile_height);
    }
    /** Build the full mFrames array */
    void loadAnimations() {
        int _w = this.width;
        int _h = this.height;
        int tw = this.tile_width;
        int th = this.tile_height;

        int row = 0;
        int column = 0;
        //Loop through a given row, move down and repeat
		while (row < _h) {
			while (column < _w) {
				SDL_Rect new_frame;
				new_frame.x = column;
				new_frame.y = row;
				new_frame.h = th;
				new_frame.w = tw;
				mFrames ~= new_frame;
				column += tw;
			}
			column = 0;
			row += th;
		}
    }
}

/**
 *  Class ResourceManager
 *  Singleton that caches Sprites by name
 */
class ResourceManager {
    //** Singleton instance */
    private static ResourceManager _instance;
    /** Renderer used to create textures */
    private SDL_Renderer* rmRenderer;
    /** Name→Sprite cache */
    private Sprite[string] mSprites;

    /**
     *  Private Constructor
     *  Params:
     *      renderer = SDL renderer
     */
    this(SDL_Renderer* renderer) {
        this.rmRenderer = renderer;
    }

    ~this() {}

    /**
     *  Get or create the singleton
     *  Params:
     *      renderer = SDL renderer
     *  Returns: ResourceManager instance
     */
    static ResourceManager getInstance(SDL_Renderer* renderer) {
        if (_instance is null) {
            _instance = new ResourceManager(renderer);
        }
        return _instance;
    }
    /**
     *  Retrieve an already loaded Sprite
     *  Params:
     *      name = Template name
     *  Returns: Sprite or null
     */
    Sprite getTexture(string name) {
        if (name in mSprites)
            return mSprites[name];
        else
            return null;
    }
    /**
     *  Load a new Sprite if needed
     *  Params:
     *      name = Template name
     *      image = Bitmap path
     *      data = JSON metadata path
     *  Returns: The loaded Sprite
     */
    Sprite loadTexture(string name, string image, string data) {
        //Check if we have already loaded this texture
        if (name in mSprites) {
            return mSprites[name];
        }
        //Else we have to load it up
        mSprites[name] = new Sprite(rmRenderer, image, data);
        return mSprites[name];
    }

}