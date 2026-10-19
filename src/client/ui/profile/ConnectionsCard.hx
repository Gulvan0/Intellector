package client.ui.profile;

import client.datatypes.player.Connection;
import client.datatypes.player.ConnectionKind;
import client.datatypes.player.Connections;
import client.datatypes.player.PlayerStatus;
import client.formatters.GameFormatters;
import client.formatters.ProfileFormatters;
import client.ui.common.LoadStatus;
import client.ui.common.StatusDot;
import client.ui.common.TimeControlKindIcon;
import client.ui.common.UnderlineTabs;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import haxefolio.LocaleUtils;
import haxefolio.structure.ScrollArea;

using client.ui.ComponentExtension;

/** The player's friends, the players they follow and their followers, as tabs of one list **/
class ConnectionsCard extends AsideCard
{
    private static final KINDS:Array<ConnectionKind> = [Friends, Following, Followers];

    private final onPlayerClicked:String->Void;

    private final tabs:UnderlineTabs;
    private final loadStatus:LoadStatus;
    private final listFrame:Box;
    private final list:VBox;
    private final emptyLabel:Label;

    private var connections:Null<Connections> = null;
    private var shownKind:ConnectionKind = Friends;
    private final statuses:Map<String, PlayerStatus> = []; // by login, kept live
    private final shownDots:Map<String, StatusDot> = []; // by login

    /** `onPlayerClicked` gets the clicked player's login **/
    public function new(onPlayerClicked:String->Void)
    {
        super(LocaleUtils.localeBinding("intellector.profile.connections.title"));
        this.onPlayerClicked = onPlayerClicked;

        tabs = new UnderlineTabs([for (kind in KINDS) LocaleUtils.localeBinding('intellector.profile.connections.${kind.getName().toLowerCase()}')], false, index -> {
            shownKind = KINDS[index];
            renderList();
        });
        tabs.addClass(StyleClass.PROFILE_ASIDE_TABS);
        tabs.selectedIndex = 0;
        body.addComponent(tabs);

        loadStatus = new LoadStatus();
        loadStatus.addClass(StyleClass.PROFILE_CONNECTIONS_STATUS);
        body.addComponent(loadStatus);

        listFrame = new Box();
        listFrame.percentWidth = 100;
        listFrame.addClass(StyleClass.PROFILE_CONNECTIONS_FRAME);
        listFrame.hidden = true;
        body.addComponent(listFrame);

        list = new VBox();
        list.percentWidth = 100;
        list.addClass(StyleClass.PROFILE_CONNECTIONS_LIST);
        var scrollArea:ScrollArea = new ScrollArea(list);
        scrollArea.percentHeight = 100;
        listFrame.addComponent(scrollArea);

        emptyLabel = new Label();
        emptyLabel.text = LocaleUtils.localeBinding("intellector.profile.connections.empty");
        emptyLabel.addClass(StyleClass.PROFILE_MUTED);
        emptyLabel.horizontalAlign = "center";
        emptyLabel.verticalAlign = "center";
        emptyLabel.hidden = true;
        listFrame.addComponent(emptyLabel);
    }

    public function showLoading():Void
    {
        loadStatus.showLoading();
        loadStatus.hidden = false;
        listFrame.hidden = true;
    }

    public function showFailure(timedOut:Bool, onRetry:Void->Void):Void
    {
        loadStatus.showFailure(timedOut, onRetry);
        loadStatus.hidden = false;
        listFrame.hidden = true;
    }

    public function setConnections(connections:Connections):Void
    {
        this.connections = connections;
        statuses.clear();
        for (kind in KINDS)
            for (connection in connections.get(kind))
                statuses.set(connection.login, connection.status);
        loadStatus.hidden = true;
        listFrame.hidden = false;
        for (i in 0...KINDS.length)
            tabs.setCount(i, connections.get(KINDS[i]).length);
        renderList();
    }

    /** Updates the player's dot in place; the list is re-sorted by status on its next render **/
    public function setStatus(login:String, status:PlayerStatus):Void
    {
        if (!statuses.exists(login))
            return;

        statuses.set(login, status);
        var dot:Null<StatusDot> = shownDots.get(login);
        if (dot != null)
        {
            dot.setStatus(status);
            dot.tooltip = ProfileFormatters.status(status);
        }
    }

    private function renderList():Void
    {
        if (connections == null)
            return;

        var shown:Array<Connection> = connections.get(shownKind).copy();
        shown.sort(compare);

        list.removeAllComponents();
        shownDots.clear();
        for (connection in shown)
            list.addComponent(createRow(connection));
        emptyLabel.hidden = shown.length > 0;
    }

    private function createRow(connection:Connection):HBox
    {
        var row:HBox = new HBox();
        row.percentWidth = 100;
        row.addClass(StyleClass.PROFILE_CONNECTION_ROW);
        row.trackHover();
        row.registerEvent(MouseEvent.CLICK, _ -> onPlayerClicked(connection.login));

        var status:PlayerStatus = statuses.get(connection.login);
        var dot:StatusDot = new StatusDot(status);
        dot.tooltip = ProfileFormatters.status(status);
        shownDots.set(connection.login, dot);
        row.addComponent(dot);

        var nicknameLabel:Label = new Label();
        nicknameLabel.text = connection.nickname;
        nicknameLabel.percentWidth = 100;
        nicknameLabel.addClass(StyleClass.PROFILE_TEXT);
        nicknameLabel.verticalAlign = "center";
        row.addComponent(nicknameLabel);

        if (connection.mainRating != null)
        {
            row.addComponent(new TimeControlKindIcon(connection.mainRating.kind));

            var ratingLabel:Label = new Label();
            ratingLabel.text = GameFormatters.bareRating(connection.mainRating.rating);
            ratingLabel.addClass(StyleClass.PROFILE_CONNECTION_RATING);
            ratingLabel.verticalAlign = "center";
            row.addComponent(ratingLabel);
        }

        return row;
    }

    private function compare(a:Connection, b:Connection):Int
    {
        var aStatus:PlayerStatus = statuses.get(a.login);
        var bStatus:PlayerStatus = statuses.get(b.login);
        if (aStatus != bStatus)
            return aStatus.getIndex() - bStatus.getIndex();
        return Reflect.compare(a.nickname.toLowerCase(), b.nickname.toLowerCase());
    }
}
