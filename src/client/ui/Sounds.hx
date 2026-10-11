package client.ui;

import intellectorboard.plyapplication.MaterializedPly;
import intellectorboard.plyapplication.PlyMaterializer;
import intellectorboard.position.Position;
import intellectorboard.primitives.ply.RawPly;
import js.html.Audio;

enum abstract Sound(String) to String
{
    var MOVE = "move";
    var CAPTURE = "capture";
    var NOTIFY = "notify";
    var LOW_TIME = "lowtime";
}

class Sounds
{
    public static function play(sound:Sound):Void
    {
        var audio:Audio = new Audio('assets/sounds/$sound.mp3');
        audio.play().catchError(_ -> {}); // refused until the user has interacted with the page
    }

    /** A capture's sound or a plain move's, for `ply` played from `position` **/
    public static function playPly(ply:RawPly, position:Position):Void
    {
        var materialized:MaterializedPly = PlyMaterializer.materialize(ply, position.pieces);
        play(materialized.isCapture() ? CAPTURE : MOVE);
    }
}
