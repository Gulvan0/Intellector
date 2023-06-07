package gfx.game.common.ply_history_view;

import haxe.ui.containers.Card;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/game/common/ply_history_view/creeping_line_ply.xml"))
class CreepingLinePly extends Card 
{
    private final pointerPos:Int;

    public function select() 
    {
        var cardStyle = customStyle.clone();
        cardStyle.backgroundColor = 0xdddddd;
        customStyle = cardStyle;

        var labelStyle = plyLabel.customStyle.clone();
        labelStyle.color = 0x333333;
        plyLabel.customStyle = labelStyle;
    }

    public function deselect() 
    {
        var cardStyle = customStyle.clone();
        cardStyle.backgroundColor = 0xffffff;
        customStyle = cardStyle;

        var labelStyle = plyLabel.customStyle.clone();
        labelStyle.color = 0x666666;
        plyLabel.customStyle = labelStyle;
    }

    public function new(pointerPos:Int, plyStr:String, onClicked:Int->Void) 
    {
        super();
        this.pointerPos = pointerPos;
        plyLabel.text = '$pointerPos. $plyStr';
        onClick = e -> {onClicked(pointerPos);};
        deselect();
    }
}