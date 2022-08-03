package gfx;

import gfx.ResponsiveToolbox.ResponsivenessRule;
import gfx.ResponsiveToolbox.ResponsiveProperty;
import haxe.ui.core.Component;
import haxe.ui.styles.Style;
import gfx.screens.*;
using Lambda;

class Screen extends Component
{
    public final menuHidden:Bool;
    private var responsiveComponents:Map<Component, Map<ResponsiveProperty, ResponsivenessRule>> = [];
    private var customEnterHandler:Null<Void->Void> = null;
    private var customCloseHandler:Null<Void->Void> = null;

    public function onEntered()
    {
        if (!responsiveComponents.empty())
        {
            resize();
            ScreenManager.addResizeHandler(resize);
        }

        if (customEnterHandler != null)
            customEnterHandler();
    }

    public function onClosed()
    {
        ScreenManager.removeResizeHandler(resize);

        if (customCloseHandler != null)
            customCloseHandler();
    }

    private function resize()
    {
        for (comp => rules in responsiveComponents.keyValueIterator())
        {
            var newStyle:Style = comp.customStyle.clone();

            for (property => rule in rules.keyValueIterator())
            {
                switch property 
                {
                    case Width: 
                        ResponsiveToolbox.recalcWidth(comp, rule);
                    case Height:
                        ResponsiveToolbox.recalcHeight(comp, rule);
                    case StyleProp(prop):
                        ResponsiveToolbox.recalcStyle(newStyle, prop, rule);
                }
            }

            comp.customStyle = newStyle;
        }
    }
    
    public static function build(type:ScreenType):Screen
    {
        return switch type 
        {
            case MainMenu:
                new MainMenu();
            case Analysis(initialVariantStr, _, _):
                new Analysis(initialVariantStr);
            case LanguageSelectIntro(languageReadyCallback):
                new LanguageSelectIntro(languageReadyCallback);
            case StartedPlayableGame(_, whiteLogin, blackLogin, timeControl, playerColor):
                LiveGame.constructFromParams(whiteLogin, blackLogin, playerColor, timeControl, playerColor);
            case ReconnectedPlayableGame(_, actualizationData):
                LiveGame.constructFromActualizationData(actualizationData);
            case SpectatedGame(_, watchedColor, actualizationData):
                LiveGame.constructFromActualizationData(actualizationData, watchedColor);
            case RevisitedGame(_, watchedColor, data):
                LiveGame.constructFromActualizationData(data, watchedColor);
            case PlayerProfile(ownerLogin):
                new PlayerProfile(ownerLogin);
            case ChallengeJoining(challengeOwner, timeControl, color):
                new OpenChallengeJoining(challengeOwner, timeControl, color);
        };
    }
    
    public function new(?menuHidden:Bool = false) 
    {
        super();
        this.menuHidden = menuHidden;
    }

}