package gfx;

import haxe.Timer;
import gfx.ResponsiveToolbox.ResponsivenessRule;
import gfx.ResponsiveToolbox.ResponsiveProperty;
import haxe.ui.core.Component;
import haxe.ui.styles.Style;
import gfx.screens.*;
using Lambda;

abstract class Screen extends Component
{
    public final menuHidden:Bool;

    public abstract function getTitle():Null<Phrase>;
    public abstract function getURLPath():Null<String>;
    public abstract function getPage():ViewedScreen;

    private abstract function onEnter():Void;
    private abstract function onClose():Void;

    private abstract function getResponsiveComponents():Map<Component, Map<ResponsiveProperty, ResponsivenessRule>>;

    public function onEntered()
    {
        if (!getResponsiveComponents().empty())
        {
            resize();
            SceneManager.addResizeHandler(resize);
        }

        onEnter();
    }

    public function onClosed()
    {
        SceneManager.removeResizeHandler(resize);

        onClose();
    }

    private function resize()
    {
        for (comp => rules in getResponsiveComponents().keyValueIterator())
            ResponsiveToolbox.resizeComponent(comp, rules);
    }
    
    public static function build(initializer:ScreenInitializer):Screen
    {
        return switch initializer 
        {
            case LanguageSelectIntro(languageReadyCallback):
                new LanguageSelectIntro(languageReadyCallback);
            case MainMenu:
                new MainMenu();
            case GameFromModelData(data, orientationPariticipantLogin):
                //TODO: Fill
            case StartedGameVersusBot(params):
                //TODO: Fill
            case NewAnalysisBoard:
                //TODO: Fill
            case Study(info):
                //TODO: Fill
            case AnalysisForLine(startingSituation, plys, viewedMovePointer):
                //TODO: Fill
            case PlayerProfile(ownerLogin, data):
                new Profile(ownerLogin, data);
            case ChallengeJoining(data):
                new OpenChallengeJoining(data);
        }
    }
    
    public function new(?menuHidden:Bool = false) 
    {
        super();
        this.menuHidden = menuHidden;
    }

}