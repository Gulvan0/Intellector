package gfx.popups;

import haxe.ui.components.SectionHeader;
import haxe.ui.containers.ButtonBar;
import haxe.ui.components.Image;
import haxe.ui.components.Button;
import haxe.ui.core.Screen;
import haxe.Timer;
import haxe.ui.containers.dialogs.Dialog;
import Preferences.Markup;
import Preferences.BranchingTabType;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/settings_popup.xml'))
class Settings extends Dialog
{
    private function resize()
    {
        for (bar in stack3.findComponents(ButtonBar))
            bar.customStyle = {fontSize: Math.min(16, Screen.instance.width * 0.02), horizontalAlign: "center"};

        for (header in stack3.findComponents(SectionHeader))
            header.customStyle = {fontSize: Math.min(16, Screen.instance.width * 0.02)};

        for (label in stack3.findComponents('pill-label'))
            label.customStyle = {fontSize: Math.min(16, Screen.instance.width * 0.02)};
        
        for (btn in tabBar.findComponents(Button))
        {
            var icon:Image = btn.findComponent(Image);
            icon.width = Math.min(50, Screen.instance.width * 0.08);
            icon.height = Math.min(50, Screen.instance.width * 0.08);
            btn.customStyle = {width: Math.floor(Math.min(120, Screen.instance.width * 0.2)), height: Math.min(100, Screen.instance.width * 0.16), fontSize: Math.min(12, Screen.instance.width * 0.02)};
        }
    }

    public function new()
    {
        super();

        switch Preferences.language.get() 
        {
            case EN:
                langBtnEN.selected = true;
            case RU:
                langBtnRU.selected = true;
        }

        switch Preferences.markup.get() 
        {
            case None:
                markupBtnNone.selected = true;
            case Side:
                markupBtnSide.selected = true;
            case Over:
                markupBtnOver.selected = true;
        }

        premovesPill.selected = Preferences.premoveEnabled.get();
        premovesLabel.text = Dictionary.getPhrase(premovesPill.selected? SETTINGS_ENABLED_OPTION_VALUE : SETTINGS_DISABLED_OPTION_VALUE);

        silentChallengesPill.selected = Preferences.silentChallenges.get();
        silentChallengesLabel.text = Dictionary.getPhrase(silentChallengesPill.selected? SETTINGS_ENABLED_OPTION_VALUE : SETTINGS_DISABLED_OPTION_VALUE);

        switch Preferences.branchingTabType.get() 
        {
            case Tree:
                branchingBtnTree.selected = true;
            case Outline:
                branchingBtnOutline.selected = true;
            case PlainText:
                branchingBtnPlain.selected = true;
        }

        branchingTurnColorPill.selected = Preferences.branchingTurnColorIndicators.get();
        branchingTurnColorLabel.text = Dictionary.getPhrase(branchingTurnColorPill.selected? SETTINGS_ENABLED_OPTION_VALUE : SETTINGS_DISABLED_OPTION_VALUE);

        ScreenManager.addResizeHandler(resize);
        onDialogClosed = btn -> {ScreenManager.removeResizeHandler(resize);};
        Timer.delay(resize, 50);
    }
}