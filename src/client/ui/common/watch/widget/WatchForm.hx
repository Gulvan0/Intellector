package client.ui.common.watch.widget;

import client.auth.IdentityKeeper;
import client.datatypes.player.FoundPlayer;
import client.datatypes.watch.WatchedPlayer;
import client.logic.watch.WatchedNicknameParsing;
import client.ui.common.notifications.RequestFailureNotice;
import client.ui.common.overlays.playersearch.PlayerSearchOverlay;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import haxefolio.form.TextInputField;
import haxefolio.structure.ActionButton;
import http.HttpError;
import net.rest.Rest;
import net.rest.RestOperationRegistry;

using StringTools;
using client.ui.ComponentExtension;

/**
    The watch widget's content while watching no one: a nickname, typed or picked in the player
    search, and Start watching. A typed nickname is looked up on Start watching; an unknown one is
    marked until the next edit.
**/
class WatchForm extends VBox
{
    private static inline final FIND_PLAYER_GLYPH:String = '<circle cx="7" cy="7" r="4.5"/><path d="M10.5 10.5L14 14"/>';

    private final onWatched:WatchedPlayer->Void;
    private final onPickedInSearch:Void->Void;
    private final field:TextInputField;
    private final hintLabel:Label;
    private final startButton:ActionButton;

    private var picked:Null<WatchedPlayer> = null; // the player search's pick, while the field holds their nickname
    private var notFoundLogin:Null<String> = null;
    private var lookingUp:Bool = false;

    /** `onPickedInSearch`: a player was picked in the player search, which closed the dropdown **/
    public function new(onWatched:WatchedPlayer->Void, onPickedInSearch:Void->Void)
    {
        super();

        this.onWatched = onWatched;
        this.onPickedInSearch = onPickedInSearch;
        percentWidth = 100;
        addClass(StyleClass.WATCH_FORM);

        field = new TextInputField(LocaleUtils.localeBinding("intellector.watch_widget.field"), onEdited, start);
        field.placeholder = LocaleUtils.localeBinding("intellector.watch_widget.placeholder");
        field.setAction(FIND_PLAYER_GLYPH, LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.watch_widget.find_player")), openPlayerSearch);

        // under the field, not in its header: beside the label, a long nickname in the error wouldn't fit
        hintLabel = new Label();
        hintLabel.percentWidth = 100;
        hintLabel.addClass(StyleClass.WATCH_HINT);

        var fieldGroup:VBox = new VBox();
        fieldGroup.percentWidth = 100;
        fieldGroup.addClass(StyleClass.WATCH_FIELD_GROUP);
        fieldGroup.addComponent(field);
        fieldGroup.addComponent(hintLabel);
        addComponent(fieldGroup);

        startButton = new ActionButton(LocaleUtils.localeBinding("intellector.watch_widget.start"), start, true);
        startButton.percentWidth = 100;
        addComponent(startButton);

        render();
    }

    /** Empties the field **/
    public function reset():Void
    {
        field.currentText = "";
        picked = null;
        notFoundLogin = null;
        render();
    }

    public function dispose():Void
    {
        field.dispose();
    }

    private function onEdited(_:String):Void
    {
        render();
    }

    private function openPlayerSearch():Void
    {
        PlayerSearchOverlay.present(LocaleUtils.localeBinding("intellector.watch_widget.choose_player"), true, onPicked, field.currentText);
    }

    private function onPicked(player:FoundPlayer):Void
    {
        picked = new WatchedPlayer(player.login, player.nickname);
        field.currentText = player.nickname;
        render();
        onPickedInSearch();
    }

    private function start():Void
    {
        var login:Null<String> = validLogin();
        if (login == null || lookingUp)
            return;

        if (picked != null && picked.login == login)
        {
            onWatched(picked);
            return;
        }

        lookingUp = true;
        render();
        Rest.client().execute(
            RestOperationRegistry.GET_PLAYER,
            player -> {
                lookingUp = false;
                render();
                onWatched(new WatchedPlayer(player.login, player.nickname));
            },
            onLookupFailed.bind(login),
            ["login" => login]
        );
    }

    private function onLookupFailed(login:String, error:HttpError):Void
    {
        lookingUp = false;

        if (error.httpStatus == 404)
            notFoundLogin = login;
        else
            RequestFailureNotice.showHttpError(WATCH_PLAYER, error);

        render();
    }

    // null while the field holds no one that can be watched
    private function validLogin():Null<String>
    {
        var nickname:String = field.currentText.trim();
        var login:Null<String> = WatchedNicknameParsing.login(nickname);
        if (nickname == "" || login == null || login == notFoundLogin || login == IdentityKeeper.currentIdentity.getUserRef())
            return null;
        return login;
    }

    private function render():Void
    {
        var nickname:String = field.currentText.trim();
        var login:Null<String> = WatchedNicknameParsing.login(nickname);
        var error:Null<String> = null;

        if (nickname == "")
            error = null;
        else if (login == null || login == notFoundLogin)
            error = LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.watch_widget.not_found"), nickname);
        else if (login == IdentityKeeper.currentIdentity.getUserRef())
            error = LocaleUtils.localeBinding("intellector.watch_widget.self");

        field.invalid = error != null;
        hintLabel.text = error ?? LocaleUtils.localeBinding("intellector.watch_widget.hint");
        hintLabel.setClass(StyleClass.WATCH_HINT_ERROR, error != null);
        startButton.enabled = !lookingUp && validLogin() != null;
    }
}
