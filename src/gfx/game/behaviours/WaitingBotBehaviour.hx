package gfx.game.behaviours;

import net.shared.board.Situation;
import dict.Dictionary;
import dict.Phrase;
import gfx.game.behaviours.util.GameboardEventHandler;
import gfx.game.models.MatchVersusBotModel;
import net.shared.PieceColor;

abstract class WaitingBotBehaviour extends VersusBotBehaviour 
{
    private abstract function updateBehaviourDueToPremovePreferenceUpdate():Void;    

    private function updateBehaviourDueToTurnColorUpdate()
    {
        var turnColor:PieceColor = versusBotModel.getMostRecentSituation().turnColor;

        if (versusBotModel.getPlayerColor() == turnColor)
            screenRef.changeBehaviour(new MoveSelectVsBot(versusBotModel));
    }

    private function onBotResponse(response:Phrase)
    {
        var messageText:String = Dictionary.getPhrase(response);
        writeChatEntry(PlayerMessage(versusBotModel.opponentBot.name, messageText));
        Networker.emitEvent(BotMessage(messageText));
    }

    private function onCustomInitEnded():Void
    {
        var actualSituation:Situation = versusBotModel.getMostRecentSituation();
        versusBotModel.opponentBot.playMove(actualSituation, versusBotModel.getBotTimeData(), onBotResponse, performPly);
    }

    public function new(versusBotModel:MatchVersusBotModel, gameboardEventHandler:GameboardEventHandler)
    {
        super(versusBotModel, false, gameboardEventHandler);
    }
}