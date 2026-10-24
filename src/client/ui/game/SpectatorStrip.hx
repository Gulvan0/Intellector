package client.ui.game;

import client.formatters.Plurals;
import client.utils.PagePaths;
import haxe.ui.components.Label;
import haxe.ui.containers.ContinuousHBox;
import haxefolio.LocaleUtils;
import haxefolio.PageLink;
import net.models.common.UserRefWithNickname;

using client.ui.ComponentExtension;

/**
    The line above the chat messages telling who is spectating: the first few nicknames, then a
    button expanding the rest in place. Guests are known only by count and are listed last.
**/
class SpectatorStrip extends ContinuousHBox
{
    private static inline final COLLAPSED_NAME_COUNT:Int = 3;

    private var spectators:Array<UserRefWithNickname> = [];
    private var guestCount:Int = 0;
    private var expanded:Bool = false;

    public function new()
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.GAME_SPECTATORS);
        refresh();
    }

    public function setSpectators(spectators:Array<UserRefWithNickname>, guestCount:Int):Void
    {
        this.spectators = spectators;
        this.guestCount = guestCount;
        refresh();
    }

    private function refresh():Void
    {
        removeAllComponents();

        var total:Int = spectators.length + guestCount;
        var collapsible:Bool = total > COLLAPSED_NAME_COUNT;
        var hiddenCount:Int = collapsible && !expanded ? total - COLLAPSED_NAME_COUNT : 0;
        var shownNames:Array<UserRefWithNickname> = hiddenCount > 0 ? spectators.slice(0, COLLAPSED_NAME_COUNT) : spectators;
        var showGuests:Bool = guestCount > 0 && hiddenCount == 0;
        var itemCount:Int = shownNames.length + (showGuests ? 1 : 0);
        // English reads "a, b, +5 more"; Russian "a, b и ещё 5"
        var commaBeforeButton:Bool = hiddenCount > 0 && Preferences.language.get() != "ru";

        addComponent(createLabel(LocaleUtils.localeBinding("intellector.live_game.spectators.title"), StyleClass.GAME_SPECTATORS_TEXT));

        if (total == 0)
            addComponent(createLabel(LocaleUtils.localeBinding("intellector.live_game.spectators.none"), StyleClass.GAME_SPECTATORS_TEXT));

        for (i in 0...shownNames.length)
            addComponent(createNameLabel(shownNames[i], i < itemCount - 1 || commaBeforeButton));

        if (showGuests)
            addComponent(createGuestsLabel(commaBeforeButton));

        if (collapsible)
        {
            var key:String = expanded ? "intellector.live_game.spectators.less" : "intellector.live_game.spectators.more";
            var button:Label = createLabel(LocaleUtils.resolveText(LocaleUtils.localeBinding(key), hiddenCount), StyleClass.GAME_SPECTATORS_NAME);
            button.addClass(StyleClass.GAME_SPECTATORS_TOGGLE);
            button.trackHover();
            button.onClick = _ -> toggle();
            addComponent(button);
        }
    }

    private function createNameLabel(spectator:UserRefWithNickname, withComma:Bool):Label
    {
        var nameLabel:Label = createLabel(withComma ? '${spectator.nickname},' : spectator.nickname, StyleClass.GAME_SPECTATORS_NAME);
        nameLabel.setClass(StyleClass.GAME_NICKNAME_LINK, !StringTools.startsWith(spectator.user_ref, "_"));
        PageLink.attach(nameLabel, PagePaths.playerProfile(spectator.user_ref));
        return nameLabel;
    }

    private function createGuestsLabel(withComma:Bool):Label
    {
        var key:String = Plurals.key("intellector.live_game.spectators.guests", guestCount, Preferences.language.get());
        var text:String = LocaleUtils.resolveText(LocaleUtils.localeBinding(key), guestCount);
        return createLabel(withComma ? '$text,' : text, StyleClass.GAME_SPECTATORS_TEXT);
    }

    private function createLabel(text:String, styleClass:StyleClass):Label
    {
        var label:Label = new Label();
        label.text = text;
        label.addClass(styleClass);
        return label;
    }

    private function toggle():Void
    {
        expanded = !expanded;
        refresh();
    }
}
