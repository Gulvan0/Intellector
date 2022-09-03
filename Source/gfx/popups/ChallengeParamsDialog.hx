package gfx.popups;

import gfx.basic_components.BoardWrapper;
import gameboard.Board;
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
    private var approvedStartPos:Situation;

    private var startPosBoard:Board;

    @:bind(typeStepper, UIEvent.CHANGE)
    private function onTypeChanged(e)
    {
        typeSpecificStack.selectedIndex = typeStepper.selectedIndex;
    }

    @:bind(rankedCheck, UIEvent.CHANGE)
    private function onBracketChanged(e)
    {
        unrankedParamsBox.hidden = rankedCheck.selected;
    }

    @:bind(startposDropdown, UIEvent.CHANGE)
    private function onStartPosTypeChanged(e)
    {
        customStartposBox.hidden = startposDropdown.selectedIndex == 0;
    }

    @:bind(applySIPBtn, MouseEvent.CLICK)
    private function onSIPApplied(e)
    {
        var deserializedSituation:Null<Situation> = Situation.fromSIP(sipTF.text);

        if (deserializedSituation == null)
            Dialogs.alert(CHALLENGE_PARAMS_INVALID_SIP_WARNING_TEXT, CHALLENGE_PARAMS_INVALID_SIP_WARNING_TITLE);
        else if (!deserializedSituation.isValidStarting())
            Dialogs.alert(CHALLENGE_PARAMS_INVALID_STARTPOS_WARNING_TEXT, CHALLENGE_PARAMS_INVALID_STARTPOS_WARNING_TITLE);
        else
        {
            approvedStartPos = deserializedSituation;
            startPosBoard.setShownSituation(approvedStartPos);
            customStartposTurnColorLabel.text = Dictionary.getPhrase(TURN_COLOR(approvedStartPos.turnColor));
        }
    }

    //TODO: Common time controls btn bindings and init

    @:bind(editTCBtn, MouseEvent.CLICK)
    private function toggleTimeControlEditor(e)
    {
        if (tcParamsBox.hidden)
            tcParamsBox.hidden = false;
        else
            restoreTimeControlInputValues();
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
        tcParamsBox.hidden = true;
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

            if (startposDropdown.selectedIndex == 1 && !approvedStartPos.isDefaultStarting())
                customStartingSituation = approvedStartPos;
                
        }

        var params:ChallengeParams = new ChallengeParams(timeControl, challengeType, ownerLogin, acceptorColor, customStartingSituation, rated);
        params.saveToCookies();
        Networker.emitEvent(CreateChallenge(params.serialize()));
    }

    public function new(initialParams:ChallengeParams)
    {
        super();

        var timeControlType:TimeControlType = initialParams.timeControl.getType();
        var isCorrespondence:Bool = timeControlType == Correspondence;

        approvedTimeControl = initialParams.timeControl;

        var hasCustomStartPos:Bool = initialParams.customStartingSituation != null && !approvedStartPos.isDefaultStarting() && approvedStartPos.isValidStarting();

        if (hasCustomStartPos)
            approvedStartPos = initialParams.customStartingSituation; 
        else
            approvedStartPos = Situation.starting();

        startPosBoard = new Board(approvedStartPos, White, 40, None);

        var boardWrapper:BoardWrapper = new BoardWrapper(startPosBoard);
        boardWrapper.percentHeight = 100;
        boardWrapper.maxPercentWidth = 100;

        customStartposBoardContainer.addComponent(boardWrapper);

        customStartposTurnColorLabel.text = Dictionary.getPhrase(TURN_COLOR(approvedStartPos.turnColor));
        sipTF.text = approvedStartPos.serialize();
        customStartposBox.hidden = !hasCustomStartPos;
        startposDropdown.selectedIndex = hasCustomStartPos? 1 : 0;

        colorDropdown.selectedIndex = switch initialParams.acceptorColor {
            case null: 0;
            case White: 2;
            case Black: 1;
        }

        unrankedParamsBox.hidden = initialParams.rated;
        rankedCheck.selected = initialParams.rated;

        correspondenceCheck.selected = isCorrespondence;
        tcValuesBox.disabled = isCorrespondence;
        restoreTimeControlInputValues();

        tcIcon.resource = AssetManager.timeControlPath(timeControlType);
        tcLabel.text = approvedTimeControl.toString();

        switch initialParams.type 
        {
            case Public:
                typeSpecificStack.selectedIndex = 1;
                typeStepper.selectedIndex = 1;
                visibilityDropdown.selectedIndex = 0;
            case ByLink:
                typeSpecificStack.selectedIndex = 1;
                typeStepper.selectedIndex = 1;
                visibilityDropdown.selectedIndex = 1;
            case Direct(calleeLogin):
                typeSpecificStack.selectedIndex = 0;
                typeStepper.selectedIndex = 0;
                usernameTF.text = calleeLogin;
        }
    }
}