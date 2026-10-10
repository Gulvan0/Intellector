package client.ui.demo;

import client.datatypes.ChallengeAcceptorColor;
import client.datatypes.IncomingChallenge;
import client.datatypes.OutgoingChallenge;
import client.datatypes.TimeControl;
import client.datatypes.TimeControlKind;
import haxe.Timer;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.Label;
import haxe.ui.components.OptionBox;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;

import client.datatypes.TimeControl.TimeControlFactory;
import client.ui.demo.DemoChallengeServer.DemoReplyOutcome;

/** Fake challenges fed to the real incoming challenge notification and challenges widget **/
class ChallengesShowcase extends VBox
{
    private static inline final ARRIVAL_DELAY_MS:Int = 3000;
    private static final NICKNAMES:Array<String> = ["Kestrel", "hexmaster_77", "Morozova", "Lin Wei", "Aurelian", "tactician"];

    private var nicknameIndex:Int = 0;
    private var delayedArrival:CheckBox;

    public function new()
    {
        super();

        addRow("Incoming", [
            button("Default position", () -> receive(TimeControlFactory.constructFischer(5, 3), false, Random, null)),
            button("Custom position", () -> receive(TimeControlFactory.constructFischer(15, 10), true, White, openingPosition())),
            button("Custom endgame, play Black", () -> receive(TimeControlFactory.constructFischer(3, 2), true, Black, endgamePosition())),
            button("Correspondence", () -> receive(None, false, Random, null)),
            button("Hyperbullet", () -> receive(TimeControlFactory.constructFischer(0.25, 0), true, White, null)),
            button("Classic", () -> receive(TimeControlFactory.constructFischer(90, 30), false, Black, null)),
            button("Long nickname", () -> receive(TimeControlFactory.constructFischer(10, 5), true, Random, openingPosition(), "Constantinople_Grandmaster_2026")),
            button("Burst of 6", receiveBurst)
        ]);

        addRow("Caller withdraws", [
            button("Oldest", DemoChallengeServer.callerCancels.bind(false)),
            button("Newest", DemoChallengeServer.callerCancels.bind(true))
        ]);

        addRow("Outgoing", [
            button("Direct", () -> send(TimeControlFactory.constructFischer(5, 3), false, White, null, nextNickname())),
            button("Open", () -> send(TimeControlFactory.constructFischer(3, 0), true, Random, null, null)),
            button("Direct, custom position", () -> send(None, false, Black, endgamePosition(), nextNickname())),
            button("Open, custom position", () -> send(TimeControlFactory.constructFischer(15, 10), true, White, openingPosition(), null)),
            button("Callee rejects oldest", DemoChallengeServer.calleeRejects)
        ]);

        delayedArrival = new CheckBox();
        delayedArrival.text = 'New challenges arrive ${ARRIVAL_DELAY_MS / 1000} s later (to open the dropdown first)';

        addRow("Accept, Decline and Cancel end after 1.5 s with", [
            replyOutcomeOption("Success", Success),
            replyOutcomeOption("No connection", NoConnection),
            replyOutcomeOption("Server error", ServerError),
            replyOutcomeOption("Challenge gone", ChallengeGone)
        ]);

        addRow("Options", [
            delayedArrival,
            button("Open the dropdown", Main.challengesWidget.dropdown.open),
            button("Remove all fake challenges", DemoChallengeServer.clear)
        ]);
    }

    private function receive(timeControl:TimeControl, rated:Bool, acceptorColor:ChallengeAcceptorColor, position:Null<Position>, ?nickname:String):Void
    {
        var callerNickname:String = nickname ?? nextNickname();
        var challenge:IncomingChallenge = new IncomingChallenge(
            DemoChallengeServer.takeId(),
            callerNickname.toLowerCase(),
            callerNickname,
            timeControl,
            kindOf(timeControl),
            rated,
            acceptorColor,
            position
        );
        arrive(DemoChallengeServer.receive.bind(challenge));
    }

    private function send(timeControl:TimeControl, rated:Bool, ownColor:ChallengeAcceptorColor, position:Null<Position>, calleeNickname:Null<String>):Void
    {
        var challenge:OutgoingChallenge = new OutgoingChallenge(
            DemoChallengeServer.takeId(),
            calleeNickname != null ? calleeNickname.toLowerCase() : null,
            calleeNickname,
            timeControl,
            kindOf(timeControl),
            rated,
            ownColor,
            position
        );
        arrive(DemoChallengeServer.send.bind(challenge));
    }

    private function receiveBurst():Void
    {
        receive(TimeControlFactory.constructFischer(1, 0), false, White, null);
        receive(TimeControlFactory.constructFischer(5, 3), true, Black, openingPosition());
        receive(None, false, Random, null);
        receive(TimeControlFactory.constructFischer(15, 10), true, Random, null);
        receive(TimeControlFactory.constructFischer(3, 2), false, White, endgamePosition());
        receive(TimeControlFactory.constructFischer(30, 0), true, Black, null);
    }

    private function arrive(delivery:Void->Void):Void
    {
        if (delayedArrival.selected)
            Timer.delay(delivery, ARRIVAL_DELAY_MS);
        else
            delivery();
    }

    private function nextNickname():String
    {
        return NICKNAMES[nicknameIndex++ % NICKNAMES.length];
    }

    private static function kindOf(timeControl:TimeControl):TimeControlKind
    {
        return switch timeControl {
            case None: Correspondence;
            case Fischer(instance): instance.getKind();
        }
    }

    // the default one with a few pieces gone, so it's still recognisable
    private static function openingPosition():Position
    {
        var position:Position = Position.defaultStarting();
        for (coords in [new HexCoords(2, 1), new HexCoords(6, 1), new HexCoords(1, 5), new HexCoords(6, 6)])
            position.set(coords, Empty);
        return position;
    }

    private static function endgamePosition():Position
    {
        var position:Position = Position.empty();
        position.setPiece(new HexCoords(4, 0), Intellector, Black);
        position.setPiece(new HexCoords(3, 1), Dominator, Black);
        position.setPiece(new HexCoords(6, 2), Progressor, Black);
        position.setPiece(new HexCoords(4, 6), Intellector, White);
        position.setPiece(new HexCoords(2, 4), Aggressor, White);
        position.setPiece(new HexCoords(5, 3), Liberator, White);
        return position;
    }

    private function addRow(title:String, items:Array<Component>):Void
    {
        var label:Label = new Label();
        label.text = title;
        label.styleString = "font-bold: true;";
        addComponent(label);

        var row:HBox = new HBox();
        row.percentWidth = 100;
        row.continuous = true;
        for (item in items)
            row.addComponent(item);
        addComponent(row);
    }

    private static function replyOutcomeOption(text:String, outcome:DemoReplyOutcome):OptionBox
    {
        var option:OptionBox = new OptionBox();
        option.text = text;
        option.componentGroup = "demo-reply-outcome";
        option.selected = DemoChallengeServer.replyOutcome == outcome;
        option.onChange = _ -> {
            if (option.selected)
                DemoChallengeServer.replyOutcome = outcome;
        };
        return option;
    }

    private static function button(text:String, action:Void->Void):Button
    {
        var button:Button = new Button();
        button.text = text;
        button.onClick = _ -> action();
        return button;
    }
}
