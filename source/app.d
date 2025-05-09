/**
 *  file app.d
 *  Program entry point
 */


/// Run with: 'dub'
import gameapplication;
// Entry point to program
/** 
 * Runs the game
 * Params:
        args = Command line arguments
 */
void main(string[] args)
{
    GameApplication app = new GameApplication("Cob's Creations", args);
	app.RunLoop();
}
