package gfx.popups;

import gfx.live.board.util.Marking;
import gfx.basic_components.BaseDialog;
import dict.Language;
import js.Browser;
import haxe.ui.components.SectionHeader;
import haxe.ui.containers.ButtonBar;
import haxe.ui.components.Image;
import haxe.ui.components.Button;
import haxe.ui.core.Screen;
import haxe.Timer;
import haxe.ui.containers.dialogs.Dialog;
import Preferences.BranchingTabType;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build('assets/layouts/popups/settings_popup.xml'))
class Settings extends BaseDialog
{
    private var oldLanguage:Language;

    private function resize()
    {
        width = Math.min(800, Screen.instance.actualWidth * 0.98);

        for (bar in stack3.findComponents(ButtonBar))
            bar.customStyle = {fontSize: Math.min(14, Screen.instance.actualWidth * 0.02), horizontalAlign: "center"};

        for (header in stack3.findComponents(SectionHeader))
            header.customStyle = {fontSize: Math.min(16, Screen.instance.actualWidth * 0.02)};

        for (label in stack3.findComponents('pill-label'))
            label.customStyle = {fontSize: Math.min(14, Screen.instance.actualWidth * 0.02)};
        
        for (btn in tabBar.findComponents(Button))
        {
            var icon:Image = btn.findComponent(Image);
            icon.width = Math.min(50, Screen.instance.actualWidth * 0.08);
            icon.height = Math.min(50, Screen.instance.actualWidth * 0.08);
            btn.customStyle = {width: Math.floor(Math.min(120, Screen.instance.actualWidth * 0.2)), height: Math.min(100, Screen.instance.actualWidth * 0.16), fontSize: Math.min(12, Screen.instance.actualWidth * 0.02)};
        }
    }

    private function onClose(button)
    {
        if (Preferences.language.get() != oldLanguage)
            Browser.location.reload();
    }

    public function new()
    {
        super(null, false);

        oldLanguage = Preferences.language.get();
        switch oldLanguage
        {
            case EN:
                langBar.selectedButton = langBtnEN;
            case RU:
                langBar.selectedButton = langBtnRU;
        }

        switch Preferences.marking.get() 
        {
            case None:
                markingBar.selectedButton = markingBtnNone;
            case Side:
                markingBar.selectedButton = markingBtnSide;
            case Over:
                markingBar.selectedButton = markingBtnOver;
        }

        premovesPill.selected = Preferences.premoveEnabled.get();
        premovesLabel.text = Dictionary.getPhrase(premovesPill.selected? SETTINGS_ENABLED_OPTION_VALUE : SETTINGS_DISABLED_OPTION_VALUE);

        silentChallengesPill.selected = Preferences.silentChallenges.get();
        silentChallengesLabel.text = Dictionary.getPhrase(silentChallengesPill.selected? SETTINGS_ENABLED_OPTION_VALUE : SETTINGS_DISABLED_OPTION_VALUE);

        switch Preferences.branchingTabType.get() 
        {
            case Tree:
                branchingBar.selectedButton = branchingBtnTree;
            case Outline:
                branchingBar.selectedButton = branchingBtnOutline;
            case PlainText:
                branchingBar.selectedButton = branchingBtnPlain;
        }

        branchingTurnColorPill.selected = Preferences.branchingTurnColorIndicators.get();
        branchingTurnColorLabel.text = Dictionary.getPhrase(branchingTurnColorPill.selected? SETTINGS_ENABLED_OPTION_VALUE : SETTINGS_DISABLED_OPTION_VALUE);

        switch Preferences.autoScrollOnMove.get() 
        {
            case Always:
                autoScrollBar.selectedButton = autoScrollBtnAlways;
            case OwnGameOnly:
                autoScrollBar.selectedButton = autoScrollBtnOwn;
            case Never:
                autoScrollBar.selectedButton = autoScrollBtnNever;
        }
    }
}