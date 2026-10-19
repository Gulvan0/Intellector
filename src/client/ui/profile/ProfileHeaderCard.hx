package client.ui.profile;

import client.ServerTime;
import client.datatypes.player.MainRating;
import client.datatypes.player.PlayerProfile;
import client.datatypes.player.PlayerRelation;
import client.datatypes.player.PlayerStatus;
import client.formatters.GameFormatters;
import client.formatters.ProfileFormatters;
import client.ui.common.LoadStatus;
import client.ui.common.StatusDot;
import client.ui.common.TimeControlKindIcon;
import haxe.ui.components.Button;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;

using client.ui.ComponentExtension;

/**
    The player: nickname, main rating, title, status, when they joined, how they and the user follow
    each other, and the Friend and Watch buttons (not on the user's own profile).
**/
class ProfileHeaderCard extends Box
{
    private final loadStatus:LoadStatus;
    private final content:Box;

    private final nicknameLabel:Label;
    private final ratingRow:HBox;
    private var ratingKindIcon:Null<TimeControlKindIcon> = null;
    private final ratingLabel:Label;
    private final ratingKindLabel:Label;
    private final unratedLabel:Label;
    private final titleRow:HBox;
    private final titleLabel:Label;
    private final statusDot:StatusDot;
    private final statusLabel:Label;
    private final lastSeenSeparator:Label;
    private final lastSeenLabel:Label;
    private final joinedLabel:Label;
    private final relationRow:HBox;
    private final relationLabel:Label;

    private final actions:VBox;
    private final buttonRow:HBox;
    private final friendButton:Button;
    private final watchButton:Button;
    private final hintLabel:Label;

    private var relation:PlayerRelation = Unrelated;
    private var lastActiveMs:Float = 0;
    private var joinedAtMs:Float = 0;
    private var tier:ProfileLayoutTier = Wide;

    public function new(onFriendPressed:PlayerRelation->Void, onWatchPressed:Void->Void)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.PROFILE_CARD);
        addClass(StyleClass.PROFILE_HEADER);

        loadStatus = new LoadStatus();
        addComponent(loadStatus);

        content = new Box();
        content.percentWidth = 100;
        content.addClass(StyleClass.PROFILE_HEADER_CONTENT);
        content.hidden = true;
        addComponent(content);

        var identity:VBox = new VBox();
        identity.percentWidth = 100;
        identity.addClass(StyleClass.PROFILE_HEADER_IDENTITY);
        content.addComponent(identity);

        var nameRow:HBox = new HBox();
        nameRow.addClass(StyleClass.PROFILE_HEADER_NAME_ROW);
        identity.addComponent(nameRow);

        nicknameLabel = new Label();
        nicknameLabel.addClass(StyleClass.PROFILE_NICKNAME);
        nicknameLabel.verticalAlign = "center";
        nameRow.addComponent(nicknameLabel);

        ratingRow = new HBox();
        ratingRow.addClass(StyleClass.PROFILE_HEADER_ROW);
        ratingRow.verticalAlign = "center";
        ratingRow.hidden = true;
        nameRow.addComponent(ratingRow);

        ratingLabel = new Label();
        ratingLabel.addClass(StyleClass.PROFILE_MONO);
        ratingLabel.verticalAlign = "center";
        ratingRow.addComponent(ratingLabel);

        ratingKindLabel = new Label();
        ratingKindLabel.addClass(StyleClass.PROFILE_MUTED);
        ratingKindLabel.verticalAlign = "center";
        ratingRow.addComponent(ratingKindLabel);

        unratedLabel = new Label();
        unratedLabel.text = LocaleUtils.localeBinding("intellector.profile.no_rating");
        unratedLabel.addClass(StyleClass.PROFILE_MUTED);
        unratedLabel.verticalAlign = "center";
        unratedLabel.hidden = true;
        nameRow.addComponent(unratedLabel);

        titleRow = new HBox();
        titleRow.addClass(StyleClass.PROFILE_HEADER_ROW);
        titleRow.hidden = true;
        identity.addComponent(titleRow);

        var titleIcon:Image = new Image();
        titleIcon.resource = Assets.profileIcon("title");
        titleIcon.width = 14;
        titleIcon.height = 16;
        titleIcon.verticalAlign = "center";
        titleRow.addComponent(titleIcon);

        titleLabel = new Label();
        titleLabel.addClass(StyleClass.PROFILE_TITLE);
        titleLabel.verticalAlign = "center";
        titleRow.addComponent(titleLabel);

        var statusRow:HBox = new HBox();
        statusRow.percentWidth = 100;
        statusRow.continuous = true;
        statusRow.addClass(StyleClass.PROFILE_HEADER_ROW);
        statusRow.addClass(StyleClass.PROFILE_STATUS_ROW);
        identity.addComponent(statusRow);

        statusDot = new StatusDot(Offline);
        statusRow.addComponent(statusDot);

        statusLabel = new Label();
        statusLabel.addClass(StyleClass.PROFILE_MUTED);
        statusLabel.verticalAlign = "center";
        statusRow.addComponent(statusLabel);

        lastSeenSeparator = createSeparator();
        statusRow.addComponent(lastSeenSeparator);

        lastSeenLabel = new Label();
        lastSeenLabel.addClass(StyleClass.PROFILE_MUTED);
        lastSeenLabel.verticalAlign = "center";
        statusRow.addComponent(lastSeenLabel);

        statusRow.addComponent(createSeparator());

        joinedLabel = new Label();
        joinedLabel.addClass(StyleClass.PROFILE_MUTED);
        joinedLabel.verticalAlign = "center";
        statusRow.addComponent(joinedLabel);

        relationRow = new HBox();
        relationRow.addClass(StyleClass.PROFILE_HEADER_ROW);
        relationRow.hidden = true;
        identity.addComponent(relationRow);

        var relationIcon:Image = new Image();
        relationIcon.resource = Assets.profileIcon("relation");
        relationIcon.width = 14;
        relationIcon.height = 14;
        relationIcon.verticalAlign = "center";
        relationRow.addComponent(relationIcon);

        relationLabel = new Label();
        relationLabel.addClass(StyleClass.PROFILE_MUTED);
        relationLabel.verticalAlign = "center";
        relationRow.addComponent(relationLabel);

        actions = new VBox();
        actions.addClass(StyleClass.PROFILE_HEADER_ACTIONS);
        actions.hidden = true;
        content.addComponent(actions);

        buttonRow = new HBox();
        buttonRow.addClass(StyleClass.PROFILE_HEADER_BUTTONS);
        buttonRow.horizontalAlign = "right";
        actions.addComponent(buttonRow);

        friendButton = new Button();
        friendButton.addClass(StyleClass.GAME_BUTTON);
        friendButton.addClass(StyleClass.PROFILE_ACTION_BUTTON);
        friendButton.onClick = _ -> onFriendPressed(relation);
        buttonRow.addComponent(friendButton);

        watchButton = new Button();
        watchButton.addClass(StyleClass.GAME_BUTTON);
        watchButton.addClass(StyleClass.PROFILE_ACTION_BUTTON);
        watchButton.icon = Assets.profileIcon("watch");
        watchButton.onClick = _ -> onWatchPressed();
        buttonRow.addComponent(watchButton);

        hintLabel = new Label();
        hintLabel.text = LocaleUtils.localeBinding("intellector.profile.watch_hint");
        hintLabel.addClass(StyleClass.PROFILE_HEADER_HINT);
        hintLabel.horizontalAlign = "right";
        actions.addComponent(hintLabel);

        renderButtons();
        setTier(tier);
    }

    public function showLoading():Void
    {
        loadStatus.showLoading();
        loadStatus.hidden = false;
        content.hidden = true;
    }

    public function showFailure(timedOut:Bool, onRetry:Void->Void):Void
    {
        loadStatus.showFailure(timedOut, onRetry);
        loadStatus.hidden = false;
        content.hidden = true;
    }

    public function setProfile(profile:PlayerProfile):Void
    {
        loadStatus.hidden = true;
        content.hidden = false;

        nicknameLabel.text = profile.nickname;
        titleRow.hidden = profile.role == null;
        if (profile.role != null)
            titleLabel.text = ProfileFormatters.role(profile.role);
        joinedAtMs = profile.joinedAtMs;
        setStatus(profile.status, profile.lastActiveMs);
    }

    /** `lastActiveMs`: Unix time of the player's latest activity, in milliseconds; null keeps the one known **/
    public function setStatus(status:PlayerStatus, lastActiveMs:Null<Float>):Void
    {
        if (lastActiveMs != null)
            this.lastActiveMs = lastActiveMs;

        statusDot.setStatus(status);
        statusLabel.text = ProfileFormatters.status(status);
        var offline:Bool = status == Offline;
        lastSeenSeparator.hidden = !offline;
        lastSeenLabel.hidden = !offline;
        refreshTimes();
    }

    /** Re-renders "last seen" and "joined" against the current time **/
    public function refreshTimes():Void
    {
        var shownLastActiveMs:Float = lastActiveMs;
        var shownJoinedAtMs:Float = joinedAtMs;
        LocaleManager.instance.registerComponent(lastSeenLabel, "text", () -> ProfileFormatters.lastSeen(shownLastActiveMs, ServerTime.now()));
        LocaleManager.instance.registerComponent(joinedLabel, "text", () -> ProfileFormatters.joined(shownJoinedAtMs, ServerTime.now()));
    }

    /** The main rating, or that there is none yet; null hides both until known **/
    public function setMainRating(known:Bool, mainRating:Null<MainRating>):Void
    {
        ratingRow.hidden = !known || mainRating == null;
        unratedLabel.hidden = !known || mainRating != null;
        if (mainRating == null)
            return;

        // a new icon each time: swapping an Image's resource before the old one has loaded can leave the old one shown
        if (ratingKindIcon != null)
            ratingRow.removeComponent(ratingKindIcon);
        ratingKindIcon = new TimeControlKindIcon(mainRating.kind);
        ratingRow.addComponentAt(ratingKindIcon, 0);
        ratingLabel.text = GameFormatters.bareRating(mainRating.rating);
        ratingKindLabel.text = LocaleUtils.localeBinding('intellector.common.time_control_kind.${mainRating.kind.getName().toLowerCase()}');
    }

    /** `actionsShown`: whether the Friend and Watch buttons are there at all **/
    public function setRelation(relation:PlayerRelation, actionsShown:Bool):Void
    {
        this.relation = relation;
        actions.hidden = !actionsShown;
        relationRow.hidden = ProfileFormatters.relation(relation) == null;
        LocaleManager.instance.registerComponent(relationLabel, "text", () -> ProfileFormatters.relation(relation) ?? "");
        renderButtons();
    }

    /** While a follow or unfollow is under way **/
    public function setFriendBusy(busy:Bool):Void
    {
        friendButton.disabled = busy;
    }

    public function setTier(tier:ProfileLayoutTier):Void
    {
        this.tier = tier;
        var stacked:Bool = tier == Narrow;
        content.layoutName = stacked ? "vertical" : "horizontal";
        var parts:Array<Component> = [actions, buttonRow, friendButton, watchButton];
        for (part in parts)
        {
            var share:Float = part == friendButton || part == watchButton ? 50 : 100;
            part.percentWidth = stacked ? share : null;
            if (!stacked)
            {
                part.width = null;
                part.invalidateComponentLayout(); // a null size alone doesn't make HaxeUI re-measure
            }
        }
        invalidateComponentLayout();
        renderButtons();
    }

    private function renderButtons():Void
    {
        var short:Bool = tier == Narrow;
        var friendKey:String = switch relation {
            case Unrelated | FollowsYou: "add_friend";
            case YouFollow(_): "unfollow";
            case Friends(_): "unfriend";
        };
        friendButton.text = LocaleUtils.localeBinding('intellector.profile.action.$friendKey');
        friendButton.icon = Assets.profileIcon(relation.match(Unrelated | FollowsYou) ? "add_friend" : "remove_friend");
        watchButton.text = LocaleUtils.localeBinding(short ? "intellector.profile.action.watch_short" : "intellector.profile.action.watch");
    }

    private static function createSeparator():Label
    {
        var separator:Label = new Label();
        separator.text = "·";
        separator.addClass(StyleClass.PROFILE_MUTED);
        separator.verticalAlign = "center";
        return separator;
    }
}
