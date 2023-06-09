package gfx.profile.complex_components;

import net.shared.dataobj.GameModelData;
import net.Requests;
import dict.Dictionary;
import haxe.ui.components.Button;
import haxe.ui.containers.VBox;

class OngoingGamesTab extends VBox
{
    private var reloadBtn:Button;
    private var list:GamesList;

    private var profileOwnerLogin:String;

    private function onGameClicked(data:GameModelData)
    {
        Requests.getGame(data.gameID, profileOwnerLogin);
    }

    private function onGamesLoaded(games:Array<GameModelData>, hasNext:Bool)
    {
        reloadBtn.disabled = false;
        list.clear();
        list.appendGames(games);
    }

    private function onReloadPressed(e)
    {
        reloadBtn.disabled = true;
        Requests.getPlayerOngoingGames(profileOwnerLogin, onGamesLoaded);
    }

    public function new(profileOwnerLogin:String, gamesInProgress:Array<GameModelData>)
    {
        super();
        this.percentWidth = 100;
        this.text = Dictionary.getPhrase(PROFILE_ONGOING_MATCHES_TAB_TITLE);
        this.profileOwnerLogin = profileOwnerLogin;

        reloadBtn = new Button();
        reloadBtn.text = Dictionary.getPhrase(PROFILE_ONGOING_RELOAD_BTN_TEXT);
        reloadBtn.customStyle = {fontSize: 14};
        reloadBtn.horizontalAlign = 'center';
        reloadBtn.onClick = onReloadPressed;
        addComponent(reloadBtn);

        list = new GamesList(profileOwnerLogin, gamesInProgress, onGameClicked);
        list.percentWidth = 100;
        addComponent(list);
    }
}