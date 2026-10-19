package client.ui.common.overlays.playersearch;

import client.datatypes.player.FoundPlayer;
import client.formatters.GameFormatters;
import client.formatters.PlayerSearchFormatters;
import client.formatters.ProfileFormatters;
import client.ui.common.StatusDot;
import client.ui.common.TimeControlKindIcon;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;

using StringTools;
using client.ui.ComponentExtension;

/** A found player as a card: status, nickname with the matched part highlighted, role, relation, main rating **/
class PlayerSearchRow extends HBox
{
    /** `query`: what the player was found by **/
    public function new(player:FoundPlayer, query:String, onClick:FoundPlayer->Void)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.PLAYER_SEARCH_ROW);
        this.trackHover();
        registerEvent(MouseEvent.CLICK, _ -> onClick(player));

        var statusSlot:Box = new Box();
        statusSlot.addClass(StyleClass.PLAYER_SEARCH_STATUS_SLOT);
        statusSlot.verticalAlign = "center";
        var dot:StatusDot = new StatusDot(player.status);
        dot.horizontalAlign = "center";
        dot.tooltip = ProfileFormatters.status(player.status);
        statusSlot.addComponent(dot);
        addComponent(statusSlot);

        var text:VBox = new VBox();
        text.percentWidth = 100;
        text.verticalAlign = "center";
        text.addClass(StyleClass.PLAYER_SEARCH_ROW_TEXT);
        addComponent(text);

        var firstLine:HBox = new HBox();
        firstLine.addClass(StyleClass.PLAYER_SEARCH_ROW_HEADLINE);
        text.addComponent(firstLine);

        var nicknameLabel:Label = new Label();
        nicknameLabel.htmlText = highlightedNickname(player.nickname, query);
        nicknameLabel.verticalAlign = "bottom";
        nicknameLabel.addClass(StyleClass.PLAYER_SEARCH_NICKNAME);
        firstLine.addComponent(nicknameLabel);

        if (player.role != null)
            firstLine.addComponent(detailLabel(ProfileFormatters.role(player.role)));

        var relation:Null<String> = PlayerSearchFormatters.relation(player.relation);
        if (relation != null)
            text.addComponent(detailLabel(relation));

        if (player.mainRating != null)
        {
            var ratingGroup:HBox = new HBox();
            ratingGroup.verticalAlign = "center";
            ratingGroup.addClass(StyleClass.PLAYER_SEARCH_RATING_GROUP);
            ratingGroup.addComponent(new TimeControlKindIcon(player.mainRating.kind));
            addComponent(ratingGroup);

            var ratingLabel:Label = new Label();
            ratingLabel.text = GameFormatters.bareRating(player.mainRating.rating);
            ratingLabel.verticalAlign = "center";
            ratingLabel.addClass(StyleClass.PLAYER_SEARCH_RATING);
            ratingGroup.addComponent(ratingLabel);
        }
    }

    private static function detailLabel(text:String):Label
    {
        var label:Label = new Label();
        label.text = text;
        label.verticalAlign = "bottom";
        label.addClass(StyleClass.PLAYER_SEARCH_ROW_DETAIL);
        return label;
    }

    private static function highlightedNickname(nickname:String, query:String):String
    {
        var start:Int = nickname.toLowerCase().indexOf(query.toLowerCase());
        if (query == "" || start < 0)
            return nickname.htmlEscape();

        var end:Int = start + query.length;
        var before:String = nickname.substring(0, start).htmlEscape();
        var match:String = nickname.substring(start, end).htmlEscape();
        var after:String = nickname.substring(end).htmlEscape();
        return '$before<span style="background-color: ${StyleVars.PLAYER_SEARCH_MATCH_HIGHLIGHT};">$match</span>$after';
    }
}
