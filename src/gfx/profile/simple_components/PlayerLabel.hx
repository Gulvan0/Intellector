package gfx.profile.simple_components;

import net.Requests;
import gfx.basic_components.utils.DimValue;
import haxe.ui.events.MouseEvent;
import net.shared.EloValue;
import utils.StringUtils.eloToStr;
import net.shared.TimeControlType;
import haxe.ui.containers.HBox;

@:xml('
    <hbox>
        <autosizing-label id="lbl" height="100%" />
    </hbox>
')
class PlayerLabel extends HBox
{
    public final playerRef:String;

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
        Requests.getMiniProfile(playerRef);
    }

    public function new(height:DimValue, playerRef:String, displayedELO:Null<EloValue>, interactive:Bool)
    {
        super();
        this.playerRef = playerRef; 
        
        assignHeight(this, height);

        var displayedName:String = dict.Utils.playerRef(playerRef);

        if (displayedELO != null)
        {
            var displayedELOStr:String = eloToStr(displayedELO);
            lbl.text = '$displayedName ($displayedELOStr)';
        }
        else
            lbl.text = '$displayedName';

        if (interactive && playerRef.charAt(0) != "_")
            lbl.enablePointerEvents();
    }
}