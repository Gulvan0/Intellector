package client.ui.game.controllers;

import client.ui.game.BoardStage;
import client.ui.game.ChatCard;
import client.ui.game.GameInfoCard;
import easypubsub.Subscription;
import intellectorboard.primitives.piece.PieceColor;
import net.models.common.UserRefWithNickname;
import net.models.other.SubscriberListChannelStateRefresh;
import net.ws.PubSub;
import net.ws.channels.Game as GameChannel;
import net.ws.channels.SubscriberList;
import net.ws.events.NewSubscriber as NewSubscriberEvent;
import net.ws.events.SubscriberLeft as SubscriberLeftEvent;
import net.ws.events.SubscriberListRefresh as SubscriberListRefreshEvent;

/** Who has the game open: the players' presence marks and the spectators. Follows them from the start, shows them once given a view by `attach` **/
class GamePresenceController
{
    private final subscription:Subscription<SubscriberList<Dynamic>>;

    private var subscribers:Array<UserRefWithNickname> = [];
    private var guestCount:Int = 0;

    private var session:Null<LiveGameSession> = null;
    private var stage:Null<BoardStage> = null;
    private var infoCard:Null<GameInfoCard> = null;
    private var chatCard:Null<ChatCard> = null;

    public function new(channel:GameChannel)
    {
        subscription = PubSub.sub(new SubscriberList<Dynamic>(channel))
            .onEventLight(SubscriberListRefreshEvent, onRefresh)
            .onEventLight(NewSubscriberEvent, subscriber -> {
                setPresent(subscriber, true);
            })
            .onEventLight(SubscriberLeftEvent, subscriber -> {
                setPresent(subscriber, false);
            });
    }

    public function attach(session:LiveGameSession, stage:BoardStage, infoCard:GameInfoCard, chatCard:ChatCard):Void
    {
        this.session = session;
        this.stage = stage;
        this.infoCard = infoCard;
        this.chatCard = chatCard;
    }

    public function dispose():Void
    {
        subscription.detach();
    }

    public function refresh():Void
    {
        if (session == null)
            return;

        var participantRefs:Array<String> = [];
        for (color in [White, Black])
        {
            var participantRef:String = session.state.info.participant(color).ref;
            participantRefs.push(participantRef);
            var present:Bool = Lambda.exists(subscribers, subscriber -> subscriber.user_ref == participantRef);
            infoCard.setPresent(color, present);
            stage.barOf(color, session.orientation).setPresent(present);
        }

        if (session.state.isOver())
        {
            chatCard.setSpectators(null, 0);
            return;
        }

        var spectators:Array<UserRefWithNickname> = subscribers.filter(subscriber -> !participantRefs.contains(subscriber.user_ref));
        var signedInSpectators:Array<UserRefWithNickname> = spectators.filter(subscriber -> !StringTools.startsWith(subscriber.user_ref, "_"));
        chatCard.setSpectators(signedInSpectators, guestCount + spectators.length - signedInSpectators.length);
    }

    private function onRefresh(refresh:SubscriberListChannelStateRefresh):Void
    {
        subscribers = refresh.subscribers.copy();
        guestCount = refresh.unauthenticated_subs_count;
        this.refresh();
    }

    /** A null `subscriber` is an unauthenticated one **/
    private function setPresent(subscriber:Null<UserRefWithNickname>, present:Bool):Void
    {
        if (subscriber == null)
            guestCount = Std.int(Math.max(0, guestCount + (present ? 1 : -1)));
        else
        {
            subscribers = subscribers.filter(known -> known.user_ref != subscriber.user_ref);
            if (present)
                subscribers.push(subscriber);
        }
        refresh();
    }
}
