package;

import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		Figure.initFigures();
		var s = new Field();
		s.x = 200;
		s.y = 100;
		addChild(s);
	}
}
