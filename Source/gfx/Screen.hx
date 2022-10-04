package gfx;

import haxe.Timer;
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
    private var fittedComponents:Array<Component> = [];
    private var customEnterHandler:Null<Void->Void> = null;
    private var customCloseHandler:Null<Void->Void> = null;

    public function onEntered()
    {
        if (!responsiveComponents.empty() || !fittedComponents.empty())
        {
            resize();
            SceneManager.addResizeHandler(resize);
        }

        if (customEnterHandler != null)
            customEnterHandler();
    }

    public function onClosed()
    {
        SceneManager.removeResizeHandler(resize);

        if (customCloseHandler != null)
            customCloseHandler();
    }

    private function resize()
    {
        for (comp => rules in responsiveComponents.keyValueIterator())
            ResponsiveToolbox.resizeComponent(comp, rules);

        Timer.delay(() -> {
            for (comp in fittedComponents)
                ResponsiveToolbox.fitComponent(comp);
        }, 50);
    }
    
    public static function build(type:ScreenType):Screen
    {
        return switch type 
        {
            case MainMenu:
                new MainMenu();
            case Analysis(initialVariantStr, selectedMainlineMove, _, _):
                new Analysis(initialVariantStr, selectedMainlineMove);
            case LanguageSelectIntro(languageReadyCallback):
                new LanguageSelectIntro(languageReadyCallback);
            case LiveGame(id, constructor):
                new LiveGame(id, constructor);
            case PlayerProfile(ownerLogin, data):
                new Profile(ownerLogin, data);
            case ChallengeJoining(data):
                new OpenChallengeJoining(data);
        };
    }
    
    public function new(?menuHidden:Bool = false) 
    {
        super();
        this.menuHidden = menuHidden;
    }

}