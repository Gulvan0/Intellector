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
    private var challengeData:Array<ChallengeData> = [];

    public function appendChallenges(challenges:Array<ChallengeData>)
    {
        for (data in challenges)
        {
            var params:ChallengeParams = ChallengeParams.deserialize(data.serializedParams);
            var bracketText:String = Dictionary.getPhrase(TABLEVIEW_BRACKET_RANKED(params.rated));
            var modeData = {color: params.acceptorColor, situation: params.customStartingSituation};
            table.dataSource.add({mode: modeData, timeControl: params.timeControl, player: '${data.ownerLogin} (${eloToStr(data.ownerELO)})', bracket: bracketText});
            challengeData.push(data);
        }
    }

    public function removeChallenge(id:Int) 
    {
        var index:Null<Int> = Lambda.findIndex(challengeData, x -> x.id == id);

        if (index == null)
            return;

        challengeData.splice(index, 1);
        table.dataSource.removeAt(index);
    }

    @:bind(table, UIEvent.CHANGE)
    private function onGameSelected(e:UIEvent)
    {
        var data:ChallengeData = challengeData[table.selectedIndex];
        table.selectedIndex = -1;
        if (!LoginManager.isPlayer(data.ownerLogin))
            Requests.getOpenChallenge(data.id);
    }

    @:bind(reloadBtn, MouseEvent.CLICK)
    private function reload(?e)
    {
        reloadBtn.disabled = true;
        table.dataSource.clear();
        challengeData = [];
        loadChallenges();
        Timer.delay(() -> {
            if (reloadBtn != null)
                reloadBtn.disabled = false;
        }, 5000);
    }

    private function loadChallenges()
    {
        Requests.getOpenChallenges(appendChallenges);
    }

    public function new()
    {
        super();
        table.selectionMode = ONE_ITEM;
    }
}