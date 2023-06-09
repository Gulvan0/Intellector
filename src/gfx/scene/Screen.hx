package gfx.scene;

import gfx.game.models.Model;
import gfx.game.models.ModelBuilder;
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
        switch initializer 
        {
            case LanguageSelectIntro(languageReadyCallback):
                return new LanguageSelectIntro(languageReadyCallback);
            case MainMenu:
                return new MainMenu();
            case GameFromModelData(data, orientationPariticipant):
                var model:Model = ModelBuilder.fromGameModelData(data, orientationPariticipant);
                switch model 
                {
                    case MatchVersusPlayer(model):
                        return new MatchVersusPlayer(model);
                    case MatchVersusBot(model):
                        return new MatchVersusBot(model);
                    case Spectation(model):
                        return new Spectation(model);
                    case AnalysisBoard(model):
                        throw "Expected game model returned by ModelBuilder.fromGameModelData(), but got AnalysisBoard instead";
                }
            case NewAnalysisBoard:
                return new Analysis(ModelBuilder.cleanAnalysis());
            case Study(info):
                return new Analysis(ModelBuilder.fromStudyInfo(info));
            case AnalysisForLine(startingSituation, plys, viewedMovePointer):
                return new Analysis(ModelBuilder.fromExploredLine(startingSituation, plys, viewedMovePointer));
            case PlayerProfile(ownerLogin, data):
                return new Profile(ownerLogin, data);
            case ChallengeJoining(data):
                return new OpenChallengeJoining(data);
        }
    }
    
    public function new(?menuHidden:Bool = false) 
    {
        super();
        this.menuHidden = menuHidden;
    }

}