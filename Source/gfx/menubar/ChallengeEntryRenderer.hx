package gfx.menubar;

import browser.Clipboard;
import js.Browser;
import net.shared.ChallengeData;
import gfx.basic_components.AutosizingLabel;
import gfx.basic_components.CopyableText;
import dict.Utils;
import net.shared.TimeControlType;
import browser.URLEditor;
import net.shared.PieceColor;
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
    private var challengeID:Int;
    private var list:ChallengeList;

    @:bind(acceptBtn, MouseEvent.CLICK)
    private function onAccepted(e)
    {
        list.removeEntryByID(challengeID);
        Networker.emitEvent(AcceptChallenge(challengeID));
    }

    @:bind(declineBtn, MouseEvent.CLICK)
    private function onDeclined(e)
    {
        list.removeEntryByID(challengeID);
        Networker.emitEvent(DeclineDirectChallenge(challengeID));
    }

    @:bind(cancelBtn, MouseEvent.CLICK)
    private function onCancelled(e)
    {
        list.removeEntryByID(challengeID);
        Networker.emitEvent(CancelChallenge(challengeID));
    }

    private function onCopyRequested(e)
    {
        Clipboard.copy(URLEditor.getChallengeLink(challengeID));
    }

    private override function onDataChanged(data:Dynamic) 
    {
        if (data == null || data.id == null || data.id == challengeID)
            return;

        var isIncoming:Bool;
        var challengeData:ChallengeEntryData = data;
        var params:ChallengeParams = challengeData.params;

        challengeID = challengeData.id;
        list = challengeData.list;

        switch params.type 
        {
            case Public, ByLink:
                isIncoming = false;

                secondRow.selectedIndex = 1;
                headerLabel.text = Dictionary.getPhrase(MENUBAR_CHALLENGES_HEADER_OUTGOING_CHALLENGE);
                link.onClick = onCopyRequested;

                acceptBtn.hidden = true;
                declineBtn.hidden = true;

            case Direct(calleeLogin):
                isIncoming = LoginManager.isPlayer(calleeLogin);

                secondRow.selectedIndex = 0;

                if (isIncoming)
                {
                    headerLabel.text = Dictionary.getPhrase(MENUBAR_CHALLENGES_HEADER_INCOMING_CHALLENGE);
                    fromToLabel.text = Dictionary.getPhrase(MENUBAR_CHALLENGES_FROM_LINE_TEXT, [challengeData.ownerLogin]);
                }
                else
                {
                    headerLabel.text = Dictionary.getPhrase(MENUBAR_CHALLENGES_HEADER_OUTGOING_CHALLENGE);
                    fromToLabel.text = Dictionary.getPhrase(MENUBAR_CHALLENGES_TO_LINE_TEXT, [calleeLogin]);
                }

                acceptBtn.hidden = !isIncoming;
                declineBtn.hidden = !isIncoming;
                cancelBtn.hidden = isIncoming;
        }

        incomingIcon.resource = AssetManager.challengesMenuItemArrowPath(isIncoming);

        var timeControl:TimeControl = params.timeControl;
        var timeControlType:TimeControlType = timeControl.getType();
        var color:Null<PieceColor> = switch params.acceptorColor 
        {
            case null: null;
            case White: isIncoming? White : Black;
            case Black: isIncoming? Black : White;
        };

        timeControlIcon.resource = AssetManager.timeControlPath(timeControlType);
        timeControlIcon.tooltip = Utils.getTimeControlName(timeControlType);
        paramsLabel.text = timeControl.toString() + ' • ' + Dictionary.getPhrase(TABLEVIEW_BRACKET_RANKED(params.rated)) + ' • ';
        colorIcon.resource = AssetManager.challengeColorPath(color);
        colorIcon.tooltip = Dictionary.getPhrase(CHALLENGE_COLOR_ICON_TOOLTIP(color));

        if (params.customStartingSituation != null)
        {
            var renderer:SituationTooltipRenderer = new SituationTooltipRenderer(params.customStartingSituation);
            ToolTipManager.instance.registerTooltip(customStartPosIcon, {renderer: renderer});
        }
        else
        {
            modeIconsSpacer.hidden = true;
            customStartPosIcon.hidden = true;
        }
    }
}