package;

import openfl.display.Sprite;

class Hexagon extends Sprite
{
        private var unselectedHex:Sprite;
        private var selectedHex:Sprite;

        public function new(a:Float, dark:Bool)
        {
                super();
                unselectedHex = drawHex(a, dark? Colors.darkHex : Colors.lightHex);
                selectedHex = drawHex(a, dark? Colors.selectedDark : Colors.selectedLight);
                selectedHex.visible = false;
                addChild(unselectedHex);
                addChild(selectedHex);
        }

        public function select(?e)
        {
                selectedHex.visible = true;
                unselectedHex.visible = false;
        }

        public function deselect(?e)
        {
                unselectedHex.visible = true;
                selectedHex.visible = false;
        }

        private function drawHex(a:Float, color:Int):Sprite
        {
                var sprite:Sprite = new Sprite();
                var rationalStep = a/2;
                var irrationalStep = rationalStep * Math.sqrt(3);

                sprite.graphics.lineStyle(3, Colors.border);
                sprite.graphics.beginFill(color);
                sprite.graphics.moveTo(-rationalStep, -irrationalStep);
                sprite.graphics.lineTo(rationalStep, -irrationalStep);
                sprite.graphics.lineTo(a, 0);
                sprite.graphics.lineTo(rationalStep, irrationalStep);
                sprite.graphics.lineTo(-rationalStep, irrationalStep);
                sprite.graphics.lineTo(-a, 0);
                sprite.graphics.lineTo(-rationalStep, -irrationalStep);
                sprite.graphics.endFill();

                return sprite;
        }
}
