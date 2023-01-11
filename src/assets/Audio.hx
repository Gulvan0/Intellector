package assets;

import net.shared.board.MaterializedPly;
import howler.Howl;
import howler.Howl.HowlOptions;

class Audio
{
    public static function playPlySound(ply:MaterializedPly)
    {
        var soundName:String = switch ply 
        {
            case NormalMove(_, _, _), Promotion(_, _, _), Castling(_, _): "move";
            case NormalCapture(_, _, _, _), ChameleonCapture(_, _, _, _), PromotionWithCapture(_, _, _, _): "capture";
        }

        playSound(soundName);
    }

    public static function playSound(soundName:String)
    {
        var options:HowlOptions = {};
        options.src = [Paths.sound(soundName)];

		var snd:Howl = new Howl(options);
        snd.play();
    }

}