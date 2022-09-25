package gfx.profile.simple_components;

import net.Requests;
import gfx.basic_components.utils.DimValue;
import haxe.ui.events.MouseEvent;
import net.shared.EloValue;
import net.shared.TimeControlType;
import haxe.ui.containers.HBox;

@:xml('
    <hbox>
        <autosizing-label id="lbl" height="100%" />
    </hbox>
')
class PlayerLabel extends HBox
{
    public var username(default, null):String;

    @:bind(lbl, MouseEvent.MOUSE_OVER)
    private function onHover(e)
    {
        lbl.setFontBold(true);
    }

    @:bind(lbl, MouseEvent.MOUSE_OUT)
    private function onOut(e)
    {
        lbl.setFontBold(false);
    }

    @:bind(lbl, MouseEvent.CLICK)
    private function onClicked(e)
    {
        Requests.getMiniProfile(username);
    }

    public function new(height:DimValue, username:String, displayedELO:EloValue, interactive:Bool)
    {
        super();
        this.username = username;
        
        assignHeight(this, height);

        var displayedELOStr:String = eloToStr(displayedELO);
        lbl.text = '$username ($displayedELOStr)';
        if (interactive)
            lbl.enablePointerEvents();
    }
}