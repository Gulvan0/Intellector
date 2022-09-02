package gfx.popups;

import utils.MathUtils;
import haxe.ui.events.UIEvent;
import utils.AssetManager;
import struct.Situation;
import struct.PieceColor;
import utils.TimeControl;
import haxe.ui.events.MouseEvent;
import struct.ChallengeParams;
import haxe.ui.containers.dialogs.Dialog;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/menubar/popups/challenge_params_popup.xml'))
class ChallengeParamsDialog extends Dialog
{
    private static inline final MAX_START_SECS_ALLOWED:Int = 60 * 60 * 6;
    private static inline final MAX_BONUS_SECS_ALLOWED:Int = 120;

    private var approvedTimeControl:TimeControl;

    @:bind(editTCBtn, MouseEvent.CLICK)
    private function editTimeControl(e)
    {
        tcParamsBox.hidden = false;
    }

    @:bind(correspondenceCheck, UIEvent.CHANGE)
    private function onCorrespondenceCheckChange(e)
    {
        tcValuesBox.disabled = correspondenceCheck.selected;
    }

    @:bind(applyTcParamsBtn, MouseEvent.CLICK)
    private function approveTimeControl(e)
    {
        if (correspondenceCheck.selected)
            approvedTimeControl = TimeControl.correspondence();
        else
        {
            if (startMinsTF.text == "" && startSecsTF.text == "")
            {
                restoreTimeControlInputValues();
                return;
            }
            else if (startMinsTF.text == "")
                startMinsTF.text = "0";
            else if (startSecsTF.text == "")
                startSecsTF.text = "0";

            if (bonusSecsTF.text == "")
                bonusSecsTF.text = "0";

            var startMins:Null<Int> = Std.parseInt(startMinsTF.text);
            var startSecs:Null<Int> = Std.parseInt(startSecsTF.text);
            var bonusSecs:Null<Int> = Std.parseInt(bonusSecsTF.text);

            if (startMins == null || startSecs == null || bonusSecs == null || startMins < 0 || startSecs < 0 || bonusSecs < 0 || startMins + startSecs == 0)
            {
                restoreTimeControlInputValues();
                return;
            }

            var finalStartSecs:Int = MathUtils.minInt(startMins * 60 + startSecs, MAX_START_SECS_ALLOWED);
            var finalBonusSecs:Int = MathUtils.minInt(bonusSecs, MAX_BONUS_SECS_ALLOWED);

            approvedTimeControl = new TimeControl(finalStartSecs, finalBonusSecs);
        }

        tcIcon.resource = AssetManager.timeControlPath(approvedTimeControl.getType());
        tcLabel.text = approvedTimeControl.toString();

        tcParamsBox.hidden = true;
    }

    private function restoreTimeControlInputValues()
    {
        startMinsTF.text = "" + Math.floor(approvedTimeControl.startSecs / 60);
        startSecsTF.text = "" + approvedTimeControl.startSecs % 60;
        bonusSecsTF.text = "" + approvedTimeControl.bonusSecs;
    }

    @:bind(confirmBtn, MouseEvent.CLICK)
    private function createChallenge(e)
    {
        var ownerLogin:String = LoginManager.getLogin();

        var challengeType:ChallengeType = typeStepper.selectedIndex == 0? Direct(usernameTF.text) : visibilityDropdown.selectedIndex == 0? Public : ByLink;
        var timeControl:TimeControl = approvedTimeControl;
        var rated:Bool = rankedCheck.selected;
        
        var acceptorColor:Null<PieceColor> = null;
        var customStartingSituation:Null<Situation> = null;

        if (!rated)
        {
            if (colorDropdown.selectedIndex == 1)
                acceptorColor = Black;
            else if (colorDropdown.selectedIndex == 2)
                acceptorColor = White;

            if (startposDropdown.selectedIndex == 1)
            {
                var deserializedSituation:Null<Situation> = Situation.fromSIP(sipTF.text);

                if (deserializedSituation != null && !deserializedSituation.isDefaultStarting() && deserializedSituation.isValidStarting())
                    customStartingSituation = deserializedSituation;
            }
                
        }

        var params:ChallengeParams = new ChallengeParams(timeControl, challengeType, ownerLogin, acceptorColor, customStartingSituation, rated);
        params.saveToCookies();
        Networker.emitEvent(CreateChallenge(params.serialize()));
    }

    public function new(initialParams:ChallengeParams)
    {
        super();

        //TODO: Fill init and add more bindings
    }
}