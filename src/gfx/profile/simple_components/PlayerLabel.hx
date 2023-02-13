package gfx.profile.simple_components;

import net.shared.utils.PlayerRef;
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

    private function onHover(e)
    {
        lbl.setFontBold(true);
    }

    private function onOut(e)
    {
        lbl.setFontBold(false);
    }

    private function onClicked(e)
    {
        Requests.getMiniProfile(playerRef);
    }

    public function new(height:DimValue, playerRef:PlayerRef, displayedELO:Null<EloValue>, interactive:Bool)
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
        
        if (interactive && playerRef.concretize().match(Normal(_)))
        {
            lbl.enablePointerEvents();
            lbl.registerEvent(MouseEvent.CLICK, onClicked);
            lbl.registerEvent(MouseEvent.MOUSE_OVER, onHover);
            lbl.registerEvent(MouseEvent.MOUSE_OUT, onOut);
        }
    }
}