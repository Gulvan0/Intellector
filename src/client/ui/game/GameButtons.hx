package client.ui.game;

import client.datatypes.game.PlyNavigationType;
import haxe.ui.components.Button;
import haxefolio.LocaleUtils;

class GameButtons
{
    public static function icon(name:String):String
    {
        return 'assets/images/game/$name.svg';
    }

    /** An icon button labelled `captionKey`'s text, with no click handler if `onPress` is null; `showCaption` false keeps the caption for the tooltip only **/
    public static function action(iconName:String, captionKey:String, onPress:Void->Void, showCaption:Bool = true):Button
    {
        return actionWithIcon(icon(iconName), captionKey, onPress, showCaption);
    }

    /** `action` with an icon from anywhere, `iconPath` being its path **/
    public static function actionWithIcon(iconPath:String, captionKey:String, onPress:Void->Void, showCaption:Bool = true):Button
    {
        var button:Button = new Button();
        button.icon = iconPath;
        button.addClass(StyleClass.GAME_BUTTON);
        if (onPress != null)
            button.onClick = _ -> onPress();
        setCaption(button, captionKey, showCaption);
        return button;
    }

    public static function setCaption(button:Button, captionKey:String, showCaption:Bool):Void
    {
        var caption:String = LocaleUtils.localeBinding(captionKey);
        button.text = showCaption ? caption : null; // an empty caption would still take the icon's centre
        button.tooltip = caption;
    }

    public static function navigation(type:PlyNavigationType, onNavigate:PlyNavigationType->Void):Button
    {
        var name:String = switch type {
            case Start: "first";
            case Previous: "previous";
            case Next: "next";
            default: "last";
        }
        return action(name, 'intellector.live_game.navigation.$name', () -> onNavigate(type), false);
    }
}
