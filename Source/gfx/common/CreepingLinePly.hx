package gfx.common;

import haxe.ui.containers.Card;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/creeping_line_ply.xml"))
class CreepingLinePly extends Card 
{
    private final move:Int;

    public function select() 
    {
        var cardStyle = customStyle.clone();
        cardStyle.backgroundColor = 0x999999;
        customStyle = cardStyle;

        var labelStyle = plyLabel.customStyle.clone();
        labelStyle.color = 0xeeeeee;
        plyLabel.customStyle = labelStyle;
    }

    public function deselect() 
    {
        var cardStyle = customStyle.clone();
        cardStyle.backgroundColor = 0x666666;
        customStyle = cardStyle;

        var labelStyle = plyLabel.customStyle.clone();
        labelStyle.color = 0xdddddd;
        plyLabel.customStyle = labelStyle;
    }

    public function new(move:Int, plyStr:String, onClicked:Int->Void) 
    {
        super();
        this.move = move;
        plyLabel.text = '$move. $plyStr';
        onClick = e -> {onClicked(move);};
    }
}