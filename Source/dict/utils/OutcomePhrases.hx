package dict.utils;

import utils.StringUtils;
import net.shared.EloValue;
import net.shared.PieceColor;
import net.shared.Outcome;
import utils.SpecialChar;

class OutcomePhrases
{
    private static function getWinningGameOverDialogMessageTL(outcomeType:DecisiveOutcomeType):Array<String>
    {
        return switch outcomeType 
        {
            case Mate:
                ["Your opponent's Intellector has been captured. You won!", "Интеллектор противника пал. Вы победили!"];
            case Breakthrough:
                ["Your Intellector has reached the last rank. You won!", "Ваш Интеллектор достиг последней горизонтали. Вы победили!"];
            case Timeout:
                ["Your opponent has run out of time. You won!", "У вашего противника закончилось время. Вы победили!"];
            case Resign:
                ["Your opponent has resigned. You won!", "Ваш противник сдался. Вы победили!"];
            case Abandon:
                ["Your opponent has abandoned the game. You won!", "Ваш противник покинул партию. Вы победили!"];
        }
    }

    private static function getLosingGameOverDialogMessageTL(outcomeType:DecisiveOutcomeType):Array<String>
    {
        return switch outcomeType 
        {
            case Mate:
                ["Your Intellector has been captured. You lost.", "Ваш Интеллектор пал. Вы проиграли."];
            case Breakthrough:
                ["Your opponent's Intellector has reached the last rank. You lost.", "Вражеский Интеллектор достиг последней горизонтали. Вы проиграли."];
            case Timeout:
                ["You lost on time.", "У вас закончилось время. Вы проиграли."];
            case Resign:
                ["You lost by resignation.", "Вы сдались; в игре засчитано поражение"];
            case Abandon:
                ["You lost (game abandoned).", "Игра покинута. Вы проиграли."];
        }
    }

    private static function getDecisiveSpectatorGameOverDialogMessageTL(outcomeType:DecisiveOutcomeType, winner:String, loser:String):Array<String>
    {
        return switch outcomeType 
        {
            case Mate:
                ['$loser\'s Intellector has been captured. $winner won.', 'Интеллектор игрока $loser повержен. Победитель: $winner.'];
            case Breakthrough:
                ['$winner\'s Intellector has reached the last rank. $winner won.', 'Интеллектор игрока $winner достиг последней горизонтали. Победитель: $winner.'];
            case Timeout:
                ['$loser has lost on time. $winner won.', 'Игрок $loser просрочил время. Победитель: $winner.'];
            case Resign:
                ['$loser has resigned. $winner won.', 'Игрок $loser сдался. Победитель: $winner.'];
            case Abandon:
                ['$loser has left the game. $winner won.', 'Игрок $loser покинул партию. Победитель: $winner.'];
        }
    }

    private static function getDrawishGameOverDialogMessageTL(outcomeType:DrawishOutcomeType):Array<String>
    {
        return switch outcomeType 
        {
            case DrawAgreement:
                ["Game has ended up in a draw. Reason: mutual agreement.", "Игра завершена вничью. Причина: взаимное согласие"];
            case Repetition:
                ["Game has ended up in a draw. Reason: threefold repetition.", "Игра завершена вничью. Причина: троекратное повторение"];
            case NoProgress:
                ["Game has ended up in a draw. Reason: sixty-move rule.", "Игра завершена вничью. Причина: правило 60 ходов"];
            case Abort:
                ["Game aborted.", "Игра прервана."];
        }
    }

    public static function getSpectatorGameOverDialogMessage(outcome:Outcome, whitePlayer:String, blackPlayer:String)
    {
        var translations:Array<String>;
        
        switch outcome 
        {
            case Decisive(type, winnerColor):
                var winner:String = winnerColor == White? whitePlayer : blackPlayer;
                var loser:String = winnerColor == Black? whitePlayer : blackPlayer;

                translations = getDecisiveSpectatorGameOverDialogMessageTL(type, winner, loser);
            case Drawish(type):
                translations = getDrawishGameOverDialogMessageTL(type);
        }

        return Dictionary.chooseTranslation(translations);
    }

    public static function getPlayerGameOverDialogMessage(outcome:Outcome, playerColor:PieceColor, newPersonalElo:Null<EloValue>)
    {
        var personalOutcome:PersonalOutcome = toPersonal(outcome, playerColor);

        var translations:Array<String> = switch personalOutcome 
        {
            case Win(type):
                getWinningGameOverDialogMessageTL(type);
            case Loss(type):
                getLosingGameOverDialogMessageTL(type);
            case Draw(type):
                getDrawishGameOverDialogMessageTL(type);
        }

        if (newPersonalElo != null)
        {
            var eloStr:String = StringUtils.eloToStr(newPersonalElo);
            translations[0] += ' Your new rating: $eloStr';
            translations[1] += ' Ваш новый рейтинг: $eloStr';
        }

        return Dictionary.chooseTranslation(translations);
    }

    private static function getDecisiveResolution(outcomeType:DecisiveOutcomeType, winnerColor:PieceColor):String
    {
        var winnerStr:String = Utils.getColorName(winnerColor);
        var loserStr:String = Utils.getColorName(opposite(winnerColor));
        var dot:String = SpecialChar.Dot;

        var halfBakedTranslations:Array<String> = switch outcomeType 
        {
            case Mate:
                ['Fatum $dot $winnerStr is victorious', 'Фатум $dot $winnerStr победили'];
            case Breakthrough:
                ['Breakthrough $dot $winnerStr is victorious', 'Прорыв $dot $winnerStr победили'];
            case Timeout:
                ['$loserStr lost on time $dot $winnerStr is victorious', '$loserStr просрочили время $dot $winnerStr победили'];
            case Resign:
                ['$loserStr resigned $dot $winnerStr is victorious', '$loserStr сдались $dot $winnerStr победили'];
            case Abandon:
                ['$loserStr left the game $dot $winnerStr is victorious', '$loserStr покинули игру $dot $winnerStr победили'];
        }

        return Dictionary.chooseTranslation(halfBakedTranslations);
    }

    private static function getDrawishResolution(outcomeType:DrawishOutcomeType):String
    {
        var translations:Array<String> = switch outcomeType 
        {
            case DrawAgreement: 
                ["Draw by agreement", "Ничья по согласию"];
            case Repetition: 
                ["Draw by repetition", "Ничья по троекратному повторению"];
            case NoProgress: 
                ["Draw by sixty-move rule", "Ничья по правилу 60 ходов"];
            case Abort: 
                ["Game aborted", "Игра прервана"];
        }

        return Dictionary.chooseTranslation(translations);
    }

    public static function getResolution(outcome:Null<Outcome>):String
    {
        switch outcome 
        {
            case null:
                return Dictionary.chooseTranslation(["Game is in progress", "Идет игра"]);
            case Drawish(type): 
                return getDrawishResolution(type);
            case Decisive(type, winnerColor):
                return getDecisiveResolution(type, winnerColor);
        }
    }

    private static function getDecisiveChatboxGameOverMessageTL(outcomeType:DecisiveOutcomeType, winnerColor:PieceColor):Array<String>
    {
        var winnerStr:String = Utils.getColorName(winnerColor);
        var loserStr:String = Utils.getColorName(opposite(winnerColor));

        return switch outcomeType 
        {
            case Mate:
                ['$winnerStr won', '$winnerStr победили'];
            case Breakthrough:
                ['$winnerStr won', '$winnerStr победили'];
            case Timeout:
                ['$loserStr lost on time', '$loserStr просрочили время'];
            case Resign:
                ['$loserStr resigned', '$loserStr сдались'];
            case Abandon:
                ['$loserStr left the game', '$loserStr покинули игру'];
        }
    }

    private static function getDrawishChatboxGameOverMessageTL(outcomeType:DrawishOutcomeType):Array<String>
    {
        return switch outcomeType 
        {
            case DrawAgreement:
                ['Game ended with a draw (mutual agreement)', 'Игра окончена вничью (по договоренности)'];
            case Repetition:
                ['Game ended with a draw (threefold repetition)', 'Игра окончена вничью (по троекратному повторению)'];
            case NoProgress:
                ['Game ended with a draw (sixty-move rule)', 'Игра окончена вничью (по правилу 60 ходов)'];
            case Abort:
                ['Game aborted', 'Игра прервана'];
        } 
    }

    public static function chatboxGameOverMessage(outcome:Outcome):String
    {
        var translations:Array<String> = switch outcome 
        {
            case Decisive(type, winnerColor):
                getDecisiveChatboxGameOverMessageTL(type, winnerColor);
            case Drawish(type):
                getDrawishChatboxGameOverMessageTL(type);
        }

        return Dictionary.chooseTranslation(translations);
    }
}