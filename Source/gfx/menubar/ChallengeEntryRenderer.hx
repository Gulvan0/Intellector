package gfx.menubar;

import net.shared.TimeControlType;
import browser.URLEditor;
import struct.PieceColor;
import utils.TimeControl;
import gfx.common.SituationTooltipRenderer;
import haxe.ui.tooltips.ToolTipManager;
import utils.AssetManager;
import haxe.ui.events.MouseEvent;
import haxe.ui.core.ItemRenderer;
import dict.Dictionary;
import struct.ChallengeParams;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/menubar/challenge_entry.xml"))
class ChallengeEntryRenderer extends ItemRenderer
{
    private static inline final arrowImageFolder:String = "Assets/symbols/upper_menu/challenges/item_arrow_img";

    private var challengeID:Int;

    @:bind(acceptBtn, MouseEvent.CLICK)
    private function onAccepted(e)
    {
        Networker.emitEvent(AcceptDirectChallenge(challengeID));
    }

    @:bind(declineBtn, MouseEvent.CLICK)
    private function onDeclined(e)
    {
        Networker.emitEvent(DeclineDirectChallenge(challengeID));
    }

    @:bind(cancelBtn, MouseEvent.CLICK)
    private function onCancelled(e)
    {
        Networker.emitEvent(CancelChallenge(challengeID));
    }

    private static function getArrowIconPath(isIncoming:Bool)
    {
        var fileName:String = isIncoming? "incoming" : "outgoing";
        return arrowImageFolder + fileName + ".svg";
    }

    private override function onDataChanged(data:Dynamic) 
    {
        if (data == null)
            return;

        var isOutgoing:Bool = true;
        var params:ChallengeParams = data.params;
        challengeID = data.id;

        switch params.type 
        {
            case Public, ByLink:
                incomingIcon.resource = getArrowIconPath(false);

                headerLabel.text = Dictionary.getPhrase(MENUBAR_CHALLENGES_HEADER_OUTGOING_CHALLENGE);

                opponentOrLinkStack.selectedIndex = 1;
                linkText.text = URLEditor.getChallengeLink(data.id);

                acceptBtn.hidden = true;
                declineBtn.hidden = true;
                cancelBtn.onClick = e -> {Networker.emitEvent(CancelChallenge(data.id));};
            case Direct(calleeLogin):
                isOutgoing = LoginManager.isPlayer(params.ownerLogin);

                incomingIcon.resource = getArrowIconPath(!isOutgoing);
                opponentOrLinkStack.selectedIndex = 0;

                acceptBtn.hidden = isOutgoing;
                declineBtn.hidden = isOutgoing;
                cancelBtn.hidden = !isOutgoing;

                if (isOutgoing)
                {
                    headerLabel.text = Dictionary.getPhrase(MENUBAR_CHALLENGES_HEADER_OUTGOING_CHALLENGE);
                    opponentLabel.text = Dictionary.getPhrase(MENUBAR_CHALLENGES_TO_LINE_TEXT, [calleeLogin]);
                }
                else
                {
                    headerLabel.text = Dictionary.getPhrase(MENUBAR_CHALLENGES_HEADER_INCOMING_CHALLENGE);
                    opponentLabel.text = Dictionary.getPhrase(MENUBAR_CHALLENGES_FROM_LINE_TEXT, [params.ownerLogin]);
                }
        }

        var timeControl:TimeControl = params.timeControl;
        var timeControlType:TimeControlType = timeControl.getType();
        var color:Null<PieceColor> = switch params.acceptorColor {
            case null: null;
            case White: isOutgoing? Black : White;
            case Black: isOutgoing? White : Black;
        };

        timeControlIcon.resource = AssetManager.timeControlPath(timeControlType);
        timeControlIcon.tooltip = timeControlType == Correspondence? Dictionary.getPhrase(CORRESPONDENCE_TIME_CONTROL_NAME) : timeControlType.getName();
        paramsLabel.text = timeControl.toString() + ' • ' + Dictionary.getPhrase(TABLEVIEW_BRACKET_RANKED(params.rated)) + ' • ';
        colorIcon.resource = AssetManager.challengeColorPath(color);
        colorIcon.tooltip = Dictionary.getPhrase(CHALLENGE_COLOR_ICON_TOOLTIP(color));

        if (params.customStartingSituation != null)
        {
            var renderer:SituationTooltipRenderer = new SituationTooltipRenderer(params.customStartingSituation);
            ToolTipManager.instance.registerTooltip(customStartPosIcon, {renderer: renderer});
            customStartPosIcon.hidden = false;
        }
        else
            customStartPosIcon.hidden = true;
    }
}