package gfx.main;

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
    private var challengeOwners:Array<String> = [];

    private function appendChallenges(data:Array<String>)
    {
        for (serializedParams in data)
        {
            var params:ChallengeParams = ChallengeParams.deserialize(serializedParams);
            var bracketText:String = Dictionary.getPhrase(TABLEVIEW_BRACKET_RANKED(params.rated));
            var modeData = {color: params.acceptorColor, situation: params.customStartingSituation};
            table.dataSource.add({mode: modeData, time: params.timeControl, player: params.ownerLogin, bracket: bracketText});
            challengeOwners.push(params.ownerLogin);
        }
    }

    @:bind(table, UIEvent.CHANGE)
    private function onGameSelected(e:UIEvent)
    {
        Requests.getOpenChallenge(challengeOwners[table.selectedIndex]);
    }

    @:bind(reloadBtn, MouseEvent.CLICK)
    private function reload(?e)
    {
        reloadBtn.disabled = true;
        table.dataSource.clear();
        challengeOwners = [];
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