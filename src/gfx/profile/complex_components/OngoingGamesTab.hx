package gfx.profile.complex_components;

import net.shared.dataobj.GameInfo;
import net.Requests;
import dict.Dictionary;
import haxe.ui.components.Button;
import haxe.ui.containers.VBox;

class OngoingGamesTab extends VBox
{
    private var reloadBtn:Button;
    private var list:GamesList;

    private var profileOwnerLogin:String;

    private function onGameClicked(info:GameInfo)
    {
        Requests.getGame(info.id);
    }

    private function onGamesLoaded(games:Array<GameInfo>, hasNext:Bool)
    {
        reloadBtn.disabled = false;
        list.dataSource.clear();
        list.appendGames(games);
    }

    private function onReloadPressed(e)
    {
        reloadBtn.disabled = true;
        Requests.getPlayerOngoingGames(profileOwnerLogin, onGamesLoaded);
    }

    public function new(profileOwnerLogin:String, gamesInProgress:Array<GameInfo>)
    {
        super();
        this.percentWidth = 100;
        this.percentHeight = 100;
        this.text = Dictionary.getPhrase(PROFILE_ONGOING_MATCHES_TAB_TITLE);
        this.profileOwnerLogin = profileOwnerLogin;

        reloadBtn = new Button();
        reloadBtn.text = Dictionary.getPhrase(PROFILE_ONGOING_RELOAD_BTN_TEXT);
        reloadBtn.horizontalAlign = 'center';
        reloadBtn.onClick = onReloadPressed;
        addComponent(reloadBtn);

        list = new GamesList(profileOwnerLogin, gamesInProgress, onGameClicked);
        addComponent(list);
    }
}