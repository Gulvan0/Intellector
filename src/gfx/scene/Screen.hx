package gfx.scene;

import haxe.ui.containers.Box;
import net.shared.dataobj.ViewedScreen;
import dict.Phrase;
import haxe.Timer;
import gfx.ResponsiveToolbox.ResponsivenessRule;
import gfx.ResponsiveToolbox.ResponsiveProperty;
import haxe.ui.core.Component;
import haxe.ui.styles.Style;
import gfx.screens.*;
using Lambda;

abstract class Screen extends Box
{
    public final menuHidden:Bool;

    public abstract function getTitle():Null<Phrase>;
    public abstract function getURLPath():Null<String>;
    public abstract function getPage():ViewedScreen;

    private abstract function onEnter():Void;
    private abstract function onClose():Void;

    private abstract function getResponsiveComponents():Map<Component, Map<ResponsiveProperty, ResponsivenessRule>>;

    public function isUserParticipatingInOngoingFiniteGame():Bool
    {
        return false; //* To be overriden where needed
    }

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
                new MainMenu();//TODO: Change
            case StartedGameVersusBot(params):
                new MainMenu();//TODO: Change
            case NewAnalysisBoard:
                new MainMenu();//TODO: Change
            case Study(info):
                new MainMenu();//TODO: Change
            case AnalysisForLine(startingSituation, plys, viewedMovePointer):
                new MainMenu();//TODO: Change
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