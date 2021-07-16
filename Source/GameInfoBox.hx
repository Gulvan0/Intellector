package;

import gfx.components.Shapes;
import struct.Ply;
import openings.OpeningTree;
import dict.Dictionary;
import struct.PieceType;
import struct.PieceColor;
import haxe.ui.styles.Style;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import openfl.text.TextField;
import openfl.display.Sprite;

enum Outcome
{
    Mate;
    Breakthrough;
    Resign;
    Abandon;
    DrawAgreement;
    Repetition;
    NoProgress;
}

class GameInfoBox extends Sprite
{
    private var box:Box;

    private var shortInfoTF:Label;
    private var opponentsTF:Label;
    private var openingTF:Label;

    private var timeControlText:String;
    private var openingTree:OpeningTree;
    private var playerIsWhite:Bool;

    public function changeResolution(outcome:Outcome, winner:Null<PieceColor>) 
    {
        var resolution = switch outcome 
        {
            case Mate: Dictionary.getPhrase(RESOLUTION_MATE);
            case Breakthrough: Dictionary.getPhrase(RESOLUTION_BREAKTHROUGH);
            case Resign: Dictionary.colorReferring(winner) + Dictionary.getPhrase(RESOLUTION_RESIGN);
            case Abandon: Dictionary.colorReferring(winner) + Dictionary.getPhrase(RESOLUTION_DISCONNECT);
            case DrawAgreement: Dictionary.getPhrase(RESOLUTION_AGREEMENT);
            case Repetition: Dictionary.getPhrase(RESOLUTION_REPETITON);
            case NoProgress: Dictionary.getPhrase(RESOLUTION_HUNDRED);
        }
        if (winner != null)
            resolution += ' • ${winner.getName()}' + Dictionary.getPhrase(RESOLUTION_WINNER_POSTFIX);
        shortInfoTF.text = timeControlText + resolution;
    }

    public function makeMove(ply:Ply)
    {
        if (!openingTree.currentNode.terminal)
        {
            openingTree.makeMove(ply.from.i, ply.from.j, ply.to.i, ply.to.j, ply.morphInto);
            openingTF.text = openingTree.currentNode.name;
        }
    }

    public function revertPlys(cnt:Int) 
    {
        openingTree.revertMoves(cnt);
        openingTF.text = openingTree.currentNode.name;
    }

    public function new(width:Float, height:Float, tcStartSeconds:Int, tcBonusSeconds:Int, whiteLogin:String, blackLogin:String, playerIsWhite:Bool) 
    {
        super();
        openingTree = new OpeningTree();
        this.playerIsWhite = playerIsWhite;

        addChild(Shapes.rect(width, height, 0x999999, 1, LineStyle.Square, 0xFFFFFF));
        
        var shortInfoStyle:Style = new Style();
        shortInfoStyle.fontSize = 14;
        var opponentsStyle:Style = new Style();
        opponentsStyle.fontSize = 16;
        var openingStyle:Style = new Style();
        openingStyle.fontSize = 14;
        openingStyle.fontItalic = true;

        var boxWidth = width - 10;

        shortInfoTF = new Label();
        timeControlText = '${tcStartSeconds/60}+$tcBonusSeconds • ';
        shortInfoTF.text = timeControlText + Dictionary.getPhrase(RESOLUTION_NONE);
        shortInfoTF.customStyle = shortInfoStyle;
        shortInfoTF.width = boxWidth;
        shortInfoTF.x = 5;
        shortInfoTF.y = 5;
        addChild(shortInfoTF);

        opponentsTF = new Label();
        opponentsTF.text = '$whiteLogin vs $blackLogin';
        opponentsTF.customStyle = opponentsStyle;
        opponentsTF.textAlign = 'center';
        opponentsTF.width = boxWidth;
        opponentsTF.x = 5;
        opponentsTF.y = 5 + shortInfoTF.height + 25;
        addChild(opponentsTF);

        openingTF = new Label();
        openingTF.text = Dictionary.getPhrase(OPENING_STARTING_POSITION);
        openingTF.customStyle = openingStyle;
        openingTF.width = boxWidth;
        openingTF.x = 5;
        openingTF.y = 5 + shortInfoTF.height + 25 + opponentsTF.height + 25;
        addChild(openingTF);
    }
}