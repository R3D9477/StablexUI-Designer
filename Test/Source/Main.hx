package;

import openfl.Lib;
import openfl.display.Sprite;

class Main extends Sprite {
	public function new () {
		super ();
		
		TestInstance.load();
		
		TestInstance.blah123.show();
	}
}
