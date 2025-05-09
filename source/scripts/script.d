/**
 *  file scripts/script.d
 *  Maps script names to ScriptComponent implementations
 */
module scripts.script;

import gameobject, gameapplication, sdl_abstraction, resourcemanager, component;
import scripts.asteroidscript, scripts.playerscript, scripts.projectilescript;
import bindbc.sdl;

//This will serve as the connector between indivudal scripts
//and the main applications accessing of them. Here objects can 
//request a script componenet based on their type


/**
 *  Retrieve a ScriptComponent instance by name
 *  Params:
 *      owner = GameObject this script will control
 *      name  = Key of the script
 *  Returns:
 *      A new ScriptComponent matching the name, or null if unknown
 */
ScriptComponent getScript(GameObject owner, string name) {
    switch (name) {
        case "playerscript": return (new PlayerScript(owner));
        case "asteroidscript": return (new AsteroidScript(owner));
        case "projectilescript": return (new ProjectileScript(owner));
        default: return null;
    }
}

/**
 *  List all available script names
 *  Returns:
 *      An array of valid script name strings
 */
string[] getAllScriptNames() {
    return ["playerscript", "asteroidscript", "projectilescript"];
}

