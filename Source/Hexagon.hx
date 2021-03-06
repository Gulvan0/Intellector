package;

import openfl.display.Sprite;

class Hexagon extends Sprite
{
        private var unselectedHex:Sprite;
        private var selectedHex:Sprite;
        private var dot:Sprite;
        private var round:Sprite;

        public function new(a:Float, dark:Bool)
        {
                super();
                unselectedHex = drawHex(a, dark? Colors.darkHex : Colors.lightHex);
                selectedHex = drawHex(a, dark? Colors.selectedDark : Colors.selectedLight);
                dot = new Sprite();
                dot.graphics.beginFill(0x333333);
                dot.graphics.drawCircle(0, 0, 8);
                dot.graphics.endFill();
                selectedHex.visible = false;
                round = new Sprite();
                round.graphics.lineStyle(4, 0x333333);
                round.graphics.drawCircle(0, 0, 0.8 * a);
                round.visible = false;
                dot.visible = false;
                addChild(unselectedHex);
                addChild(selectedHex);
                addChild(dot);
                addChild(round);
        }

        public function select()
        {
                selectedHex.visible = true;
                unselectedHex.visible = false;
        }

        public function deselect()
        {
                unselectedHex.visible = true;
                selectedHex.visible = false;
        }

        public function addDot()
        {
                round.visible = false;  
                dot.visible = true;
        }
        
        public function addRound()
        {
                dot.visible = false;
                round.visible = true;  
        }

        public function removeMarkers() 
        {
                dot.visible = false;
                round.visible = false;        
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
