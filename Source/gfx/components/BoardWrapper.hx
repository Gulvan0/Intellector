package gfx.components;

import utils.MathUtils;
import gameboard.Hexagon;
import gameboard.Board;
import haxe.ui.core.Component;

class BoardWrapper extends Component 
{
    private var board:Board;
    private var widthBased:Bool = false;

    /** height/width **/
    public function inverseAspectRatio()
    {
        /*
        Regarding the aspect ratio modification:

        Without letters, board's height is basically the height of a column consisting of the 7 hexes
        Or, equivalently, 7 * hex's height
        However, when we add letters, the board's height increases by a half of a hex's height
        Thus, it becomes (7 + 0.5)/7 = 15/14 of its normal value (while width stays the same)
        _
        Regarding the normal aspect ratio:

        It is trivial to prove that board's width equals 14 * hex's side
        And since our hexes are indeed hexagons, it is true that height = sqrt(3) * side
        Recall that when there are no letters, the board's height is seven times hex's height
        The rest is obvious (just substitute all of the above)
        */
        return board.lettersEnabled? MathUtils.HALF_SQRT3 * (15/14) : MathUtils.HALF_SQRT3;
    }

    private override function get_componentWidth():Null<Float>
    {
        return widthBased? super.get_componentWidth() : super.get_componentHeight() / inverseAspectRatio();
    }

    private override function get_componentHeight():Null<Float>
    {
        return widthBased? super.get_componentWidth() * inverseAspectRatio() : super.get_componentHeight();
    }

    private override function set_width(value:Float):Float
    {
        widthBased = true;  
        return super.set_width(value);
    }

    private override function set_height(value:Float):Float
    {
        widthBased = false; 
        return super.set_height(value);
    }

    private override function set_percentWidth(value:Null<Float>):Null<Float>
    {
        widthBased = true;  
        return super.set_percentWidth(value);
    }

    private override function set_percentHeight(value:Null<Float>):Null<Float>
    {
        widthBased = false;    
        return super.set_percentHeight(value);
    }

    private override function validateComponentLayout():Bool 
    {
        var b = super.validateComponentLayout();
        board.resize(componentWidth / 14);
        return b;
    }

    public function new(board:Board) 
    {
        super();
        this.board = board;
        this.width = board.width;
        this.height = board.height;
        addChild(board);
    }
    
}