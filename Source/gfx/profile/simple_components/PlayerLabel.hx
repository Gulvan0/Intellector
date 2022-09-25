package gfx.profile.simple_components;

import gfx.basic_components.utils.DimValue;
import haxe.ui.events.MouseEvent;
import gfx.profile.data.MiniProfileData;
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
    private var username:String;
    private var miniProfileData:MiniProfileData;

    private function findMainELO(gamesCntByTimeControl:Map<TimeControlType, Int>, eloMap:Map<TimeControlType, EloValue>):EloValue
    {
        var argmax:TimeControlType = null;
        var max:Int = -1;

        for (tc => gamesCnt in gamesCntByTimeControl.keyValueIterator())
            if (gamesCnt > max || (gamesCnt == max && isSecondLongerThanFirst(argmax, tc)))
            {
                argmax = tc;
                max = gamesCnt;
            }
            
        return eloMap.get(argmax);
    }

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
        Dialogs.miniProfile(username, miniProfileData);
    }

    public function new(height:DimValue, username:String, miniProfileData:MiniProfileData)
    {
        super();
        this.username = username;
        this.miniProfileData = miniProfileData;
        
        assignHeight(this, height);

        var mainElo:EloValue = findMainELO(miniProfileData.gamesCntByTimeControl, miniProfileData.elo);
        var mainEloStr:String = eloToStr(mainElo);
        lbl.text = '$username ($mainEloStr)';
        lbl.enablePointerEvents();
    }
}