package gfx.profile.simple_components;

import assets.Paths;
import assets.StandaloneAssetPath;
import haxe.ui.core.ItemRenderer;
import net.shared.EloValue;
import dict.Dictionary;
import haxe.ui.events.UIEvent;
import net.shared.TimeControlType;
import haxe.ui.components.DropDown;

@:xml('
    <item-renderer layoutName="horizontal" width="100%" height="71px">
        <image width="71px" height="71px" id="img" />
        <vbox verticalAlign="center" style="spacing:0px">
            <label id="tc" style="font-size: 20px;" />
            <label id="games" style="font-size: 16px;color: #888888;" />
            <label id="elo" style="font-size: 16px;color: #888888;" />
        </vbox>
    </item-renderer>16
')
private class TimeControlFilterRenderer extends ItemRenderer {}

class TimeControlFilterDropdown extends DropDown
{
    private var onFilterSelected:Null<TimeControlType>->Void;
    private var activated:Bool = false;

    @:bind(this, UIEvent.CHANGE)
    private function onSelectedItemChanged(e)
    {
        if (!activated)
            activated = true;         //We should ignore the first event as it is fired when the first item gets added
        else if (selectedIndex == 0)
            onFilterSelected(null);
        else
            onFilterSelected(TimeControlType.createByIndex(selectedIndex - 1));
    }

    public function new(elo:Map<TimeControlType, EloValue>, gamesCntByTimeControl:Map<TimeControlType, Int>, totalPastGames:Int, onFilterSelected:Null<TimeControlType>->Void)
    {
        super();
        this.width = 250;
        this.onFilterSelected = onFilterSelected;

        addComponent(new TimeControlFilterRenderer());

        dataSource.add({
            tc: Dictionary.getPhrase(PROFILE_GAMES_TCFILTER_ALL_GAMES_OPTION_NAME),
            games: Dictionary.getPhrase(PROFILE_GAMES_TCFILTER_GAMECNT_LABEL_TEXT(totalPastGames)),
            elo: "",
            img: AllGamesTimeControlFilterIcon
        });

        for (timeControlType in TimeControlType.createAll())
            dataSource.add({
                tc: dict.Utils.getTimeControlName(timeControlType),
                games: Dictionary.getPhrase(PROFILE_GAMES_TCFILTER_GAMECNT_LABEL_TEXT(gamesCntByTimeControl.get(timeControlType))),
                elo: Dictionary.getPhrase(PROFILE_GAMES_TCFILTER_ELO_LABEL_TEXT(elo.get(timeControlType))),
                img: Paths.timeControl(timeControlType)
            });
    }
}