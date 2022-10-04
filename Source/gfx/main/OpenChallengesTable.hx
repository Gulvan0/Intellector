package gfx.main;

import utils.StringUtils.eloToStr;
import net.shared.ChallengeData;
import haxe.ui.events.UIEvent;
import struct.ChallengeParams;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import dict.Dictionary;
import haxe.Timer;
import net.Requests;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/main_menu/open_challenges_table.xml"))
class OpenChallengesTable extends VBox
{
    private var challengeIDs:Array<Int> = [];

    private function appendChallenges(challenges:Array<ChallengeData>)
    {
        for (data in challenges)
        {
            var params:ChallengeParams = ChallengeParams.deserialize(data.serializedParams);
            var bracketText:String = Dictionary.getPhrase(TABLEVIEW_BRACKET_RANKED(params.rated));
            var modeData = {color: params.acceptorColor, situation: params.customStartingSituation};
            table.dataSource.add({mode: modeData, time: params.timeControl, player: '${data.ownerLogin} (${eloToStr(data.ownerELO)})}', bracket: bracketText});
            challengeIDs.push(data.id);
        }
    }

    @:bind(table, UIEvent.CHANGE)
    private function onGameSelected(e:UIEvent)
    {
        Requests.getOpenChallenge(challengeIDs[table.selectedIndex]);
    }

    @:bind(reloadBtn, MouseEvent.CLICK)
    private function reload(?e)
    {
        reloadBtn.disabled = true;
        table.dataSource.clear();
        challengeIDs = [];
        loadChallenges();
        Timer.delay(() -> {
            if (reloadBtn != null)
                reloadBtn.disabled = false;
        }, 5000);
    }

    public function loadChallenges()
    {
        Requests.getOpenChallenges(appendChallenges);
    }
}