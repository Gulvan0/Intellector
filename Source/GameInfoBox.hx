package;

import haxe.ui.containers.VBox;
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
    Timeout;
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
            case Mate: Dictionary.getPhrase(RESOLUTION_MATE) + ' • ' + Dictionary.getColorName(winner) + Dictionary.getPhrase(RESOLUTION_WINNER_POSTFIX);
            case Breakthrough: Dictionary.getPhrase(RESOLUTION_BREAKTHROUGH) + ' • ' + Dictionary.getColorName(winner) + Dictionary.getPhrase(RESOLUTION_WINNER_POSTFIX);
            case Resign: Dictionary.getColorName(opposite(winner)) + Dictionary.getPhrase(RESOLUTION_RESIGN);
            case Abandon: Dictionary.getColorName(opposite(winner)) + Dictionary.getPhrase(RESOLUTION_DISCONNECT);
            case DrawAgreement: Dictionary.getPhrase(RESOLUTION_AGREEMENT);
            case Repetition: Dictionary.getPhrase(RESOLUTION_REPETITON);
            case NoProgress: Dictionary.getPhrase(RESOLUTION_HUNDRED);
            case Timeout: Dictionary.getPhrase(RESOLUTION_TIMEOUT) + ' • ' + Dictionary.getColorName(winner) + Dictionary.getPhrase(RESOLUTION_WINNER_POSTFIX);
        }
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
        
        var shortInfoStyle:Style = {fontSize: 14};
        var opponentsStyle:Style = {fontSize: 16};
        var openingStyle:Style = {fontSize: 14, fontItalic: true};

        var boxWidth = width - 10;

        var vbox:VBox = new VBox();
        vbox.width = boxWidth;
        vbox.y = 5;

        shortInfoTF = new Label();
        timeControlText = '${tcStartSeconds/60}+$tcBonusSeconds • ';
        shortInfoTF.text = timeControlText + Dictionary.getPhrase(RESOLUTION_NONE);
        shortInfoTF.customStyle = shortInfoStyle;
        shortInfoTF.width = boxWidth;
        shortInfoTF.horizontalAlign = 'center';
        vbox.addComponent(shortInfoTF);

        opponentsTF = new Label();
        opponentsTF.text = '$whiteLogin vs $blackLogin';
        opponentsTF.customStyle = opponentsStyle;
        opponentsTF.textAlign = 'center';
        opponentsTF.width = boxWidth;
        opponentsTF.horizontalAlign = 'center';
        vbox.addComponent(opponentsTF);

        openingTF = new Label();
        openingTF.text = Dictionary.getPhrase(OPENING_STARTING_POSITION);
        openingTF.customStyle = openingStyle;
        openingTF.width = boxWidth;
        openingTF.horizontalAlign = 'center';
        vbox.addComponent(openingTF);

        addChild(vbox);
    }
}