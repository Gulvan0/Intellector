package gfx.popups;

import net.shared.TimeControlType;
import haxe.ui.locale.LocaleManager;
import haxe.ui.components.Image;
import haxe.Timer;
import haxe.ui.components.Button;
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
import haxe.ui.core.Screen as HaxeUIScreen;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/popups/challenge_params_popup.xml'))
class ChallengeParamsDialog extends Dialog
{
    private static inline final MAX_START_SECS_ALLOWED:Int = 60 * 60 * 6;
    private static inline final MAX_BONUS_SECS_ALLOWED:Int = 120;

    private var approvedTimeControl:TimeControl;
    private var approvedStartPos:Situation;

    private var dontCacheParams:Bool;

    private var startPosBoard:Board;

    private function resize()
    {
        width = Math.min(500, 0.95 * HaxeUIScreen.instance.actualWidth);

        var compact:Bool = width < 500;

        recommendedTCsGrid.columns = compact? 4 : 5;

        fastBlitzBtn.hidden = compact;
        rapidIncBtn.hidden = compact;

        bulletBtn.percentWidth = 100 / recommendedTCsGrid.columns;
        bulletIncBtn.percentWidth = 100 / recommendedTCsGrid.columns;
        standardBlitzBtn.percentWidth = 100 / recommendedTCsGrid.columns;
        longBlitzBtn.percentWidth = 100 / recommendedTCsGrid.columns;
        rapidBtn.percentWidth = 100 / recommendedTCsGrid.columns;
        longRapidBtn.percentWidth = 100 / recommendedTCsGrid.columns;
        halfhourBtn.percentWidth = 100 / recommendedTCsGrid.columns;
        hourBtn.percentWidth = 100 / recommendedTCsGrid.columns;

        if (compact)
        {
            for (btn in [bulletBtn, bulletIncBtn, standardBlitzBtn, longBlitzBtn])
                btn.customStyle = {paddingLeft: 3, paddingRight: 3};
            for (btn in [rapidBtn, longRapidBtn, halfhourBtn, hourBtn])
                btn.customStyle = {paddingLeft: 2, paddingRight: 2};
        }
        else
            for (btn in [rapidBtn, rapidIncBtn, longRapidBtn, halfhourBtn, hourBtn])
                btn.customStyle = {paddingLeft: 3, paddingRight: 3};
    }

    public function onClose(?e)
    {
        SceneManager.removeResizeHandler(resize);
    }

    @:bind(typeStepper, UIEvent.CHANGE)
    private function onTypeChanged(e)
    {
        typeSpecificStack.selectedIndex = typeStepper.selectedIndex;
        Dialogs.updatePosition(this);
    }

    @:bind(rankedCheck, UIEvent.CHANGE)
    private function onBracketChanged(e)
    {
        if (rankedCheck.selected)
            unrankedParamsBox.fadeOut(Dialogs.updatePosition.bind(this));
        else
            unrankedParamsBox.fadeIn(Dialogs.updatePosition.bind(this));
    }

    @:bind(startposDropdown, UIEvent.CHANGE)
    private function onStartPosTypeChanged(e)
    {
        if (startposDropdown.selectedIndex == 0)
            customStartposBox.fadeOut(Dialogs.updatePosition.bind(this));
        else
            customStartposBox.fadeIn(Dialogs.updatePosition.bind(this));
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

    @:bind(editTCBtn, MouseEvent.CLICK)
    private function toggleTimeControlEditor(e)
    {
        if (tcParamsBox.hidden)
            tcParamsBox.fadeIn(Dialogs.updatePosition.bind(this));
        else
        {
            restoreTimeControlInputValues();
            tcParamsBox.fadeOut(Dialogs.updatePosition.bind(this));
        }
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
                tcParamsBox.fadeOut(Dialogs.updatePosition.bind(this));
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
                tcParamsBox.fadeOut(Dialogs.updatePosition.bind(this));
                return;
            }

            var finalStartSecs:Int = MathUtils.minInt(startMins * 60 + startSecs, MAX_START_SECS_ALLOWED);
            var finalBonusSecs:Int = MathUtils.minInt(bonusSecs, MAX_BONUS_SECS_ALLOWED);

            approvedTimeControl = new TimeControl(finalStartSecs, finalBonusSecs);
        }

        tcIcon.resource = AssetManager.timeControlPath(approvedTimeControl.getType());
        tcLabel.text = approvedTimeControl.toString();

        tcParamsBox.fadeOut(Dialogs.updatePosition.bind(this));
    }

    private function restoreTimeControlInputValues(?customTimeControl:TimeControl)
    {
        var timeControl:TimeControl = customTimeControl == null? approvedTimeControl : customTimeControl;
        startMinsTF.text = "" + Math.floor(timeControl.startSecs / 60);
        startSecsTF.text = "" + timeControl.startSecs % 60;
        bonusSecsTF.text = "" + timeControl.bonusSecs;
    }

    @:bind(confirmBtn, MouseEvent.CLICK)
    private function createChallenge(e)
    {
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

        var params:ChallengeParams = new ChallengeParams(timeControl, challengeType, acceptorColor, customStartingSituation, rated);
        if (!dontCacheParams)
            params.saveToCookies();
        Networker.emitEvent(CreateChallenge(params.serialize()));
        hideDialog(DialogButton.OK);
    }

    public function new(initialParams:ChallengeParams, ?dontCacheParams:Bool = false)
    {
        super();
        this.dontCacheParams = dontCacheParams;

        var commonTimeControls:Map<Button, TimeControl> = [
            bulletBtn => TimeControl.normal(1, 0),
            bulletIncBtn => TimeControl.normal(1, 1),
            fastBlitzBtn => TimeControl.normal(3, 0),
            standardBlitzBtn => TimeControl.normal(3, 2),
            longBlitzBtn => TimeControl.normal(5, 0),
            rapidBtn => TimeControl.normal(10, 0),
            rapidIncBtn => TimeControl.normal(10, 5),
            longRapidBtn => TimeControl.normal(15, 10),
            halfhourBtn => TimeControl.normal(30, 0),
            hourBtn => TimeControl.normal(60, 0)
        ];

        for (btn => tc in commonTimeControls)
        {
            btn.text = tc.toString();
            btn.icon = AssetManager.timeControlPath(tc.getType());
            btn.onClick = e -> {
                tcValuesBox.disabled = false;
                correspondenceCheck.selected = false;
                restoreTimeControlInputValues(tc);
            };
            Timer.delay(() -> {
                var icon:Image = btn.findComponent(Image);
                icon.height = 18;
                icon.width = icon.originalWidth * icon.height / icon.originalHeight;
            }, 40);
        }

        var timeControlType:TimeControlType = initialParams.timeControl.getType();
        var isCorrespondence:Bool = timeControlType == Correspondence;

        approvedTimeControl = initialParams.timeControl;

        var hasCustomStartPos:Bool = initialParams.customStartingSituation != null && !initialParams.customStartingSituation.isDefaultStarting() && initialParams.customStartingSituation.isValidStarting();

        if (hasCustomStartPos)
            approvedStartPos = initialParams.customStartingSituation; 
        else
            approvedStartPos = Situation.starting();

        startPosBoard = new Board(approvedStartPos, White, 40, None);

        var boardWrapper:BoardWrapper = new BoardWrapper(startPosBoard);
        boardWrapper.percentWidth = 100;

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

        SceneManager.addResizeHandler(resize);
        resize();
    }
}