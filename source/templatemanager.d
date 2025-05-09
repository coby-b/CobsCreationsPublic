/**
 *  file templatemanager.
 *  Parses object template JSON into ObjTemplate structs
 */
module templatemanager;

import std.json, std.file, std.array, std.algorithm;
import component, gameapplication, gameobject, scripts.script;

/**
 *  Struct ObjTemplate
 *  Blueprint for spawning GameObjects
 */
struct ObjTemplate {
    /** Texture key */
    string mTexture;
    /** Size */
    int mWidth, mHeight;
    /** Script component key */
    string mScript = "";
    /** List of available flags */
    string[] mFlags = [];
}

/**
 *  Class TemplateManager
 *  Holds all object templates loaded from JSON
 */
class TemplateManager {
    /** Name→ObjTemplate map */
    private ObjTemplate[string] mTemplates;

    /**
     *  Load all templates from a JSON file.
     *  Params:
     *      filepath = Path to template JSON.
     */
    void loadTemplates(string filepath) {
        string jsonTxt = readText(filepath);
        JSONValue j = parseJSON(jsonTxt);
        assert(j.type == JSONType.object, "ObjTemplate must be a JSON object");

        //Read through each objects name, then the texture, width, height, and optionally script
        foreach (string name, JSONValue def; j.object) {
            assert(def["texture"].type == JSONType.string, name ~ " is missing a texture");
            assert(def["width"].type == JSONType.integer, name ~ " is missing a width");
            assert(def["height"].type == JSONType.integer, name ~ " is missing a height");

            ObjTemplate objT;
            objT.mTexture = def["texture"].str;
            objT.mWidth = cast(int) def["width"].integer;
            objT.mHeight = cast(int) def["height"].integer;

            if ("script" in def.object) {
                objT.mScript = def["script"].str;
            }

            if ("flags" in def.object) {
                objT.mFlags = def["flags"].array.map!(v => v.str).array;
            }

            mTemplates[name] = objT;
        }
    }

    /**
     *  Check if a template exists
     *  Params:
     *      name = Template key
     *  Returns: True if loaded
     */
    bool templateSaved(string name) {
        return cast(bool) (name in mTemplates);
    }

    /**
     *  Retrieve a template definition
     *  Params:
     *      name = Template key
     *  Returns: ObjTemplate
     */
    ObjTemplate getObjTemp(string name) {
        assert(templateSaved(name), "No template by the name '" ~ name ~ "' exists");
        return mTemplates[name];
    }

    /**
     *  List all template names
     *  Returns: Array of keys
     */
    string[] getAllTemplateNames() {
        return mTemplates.keys.array;
    }
}