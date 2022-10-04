package gfx.menubar;

import net.shared.ChallengeData;
import gfx.basic_components.AutosizingLabel;
import gfx.basic_components.CopyableText;
import dict.Utils;
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

    private override function onDataChanged(data:Dynamic) 
    {
        if (data == null)
            return;

        var isIncoming:Bool;
        var challengeData:ChallengeData = data;
        var params:ChallengeParams = ChallengeParams.deserialize(challengeData.serializedParams);
        challengeID = challengeData.id;

        switch params.type 
        {
            case Public, ByLink:
                isIncoming = false;

                headerLabel.text = Dictionary.getPhrase(MENUBAR_CHALLENGES_HEADER_OUTGOING_CHALLENGE);

                var linkText:CopyableText = new CopyableText();
                var s = linkText.tf.customStyle.clone();
                s.fontSize = 8;
                linkText.tf.customStyle = s;

                linkText.percentWidth = 90;
                linkText.percentHeight = 100;
                linkText.horizontalAlign = "center";
                linkText.copiedText = URLEditor.getChallengeLink(challengeData.id);
                secondRow.addComponent(linkText);

                acceptBtn.hidden = true;
                declineBtn.hidden = true;
                cancelBtn.onClick = e -> {Networker.emitEvent(CancelChallenge(challengeData.id));};

            case Direct(calleeLogin):
                isIncoming = LoginManager.isPlayer(calleeLogin);

                var opponentLabelText:String;

                acceptBtn.hidden = !isIncoming;
                declineBtn.hidden = !isIncoming;
                cancelBtn.hidden = isIncoming;

                if (isIncoming)
                {
                    headerLabel.text = Dictionary.getPhrase(MENUBAR_CHALLENGES_HEADER_INCOMING_CHALLENGE);
                    opponentLabelText = Dictionary.getPhrase(MENUBAR_CHALLENGES_FROM_LINE_TEXT, [challengeData.ownerLogin]);
                }
                else
                {
                    headerLabel.text = Dictionary.getPhrase(MENUBAR_CHALLENGES_HEADER_OUTGOING_CHALLENGE);
                    opponentLabelText = Dictionary.getPhrase(MENUBAR_CHALLENGES_TO_LINE_TEXT, [calleeLogin]);
                }

                var opponentLabel:AutosizingLabel = new AutosizingLabel();
                opponentLabel.text = opponentLabelText;
                opponentLabel.percentWidth = 100;
                opponentLabel.percentHeight = 100;
                opponentLabel.align = Center;
                secondRow.addComponent(opponentLabel);
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