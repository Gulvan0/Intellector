package net.shared.dataobj;

import net.shared.utils.UnixTimestamp;

class TimeReservesData
{
    public var whiteSeconds:Float;
    public var blackSeconds:Float;
    public var timestamp:UnixTimestamp;

    public function secsLeftMap():Map<PieceColor, Float> 
    {
        return [White => whiteSeconds, Black => blackSeconds];
    }

    public function getSecsLeftAtTimestamp(color:PieceColor):Float
    {
        return color == White? whiteSeconds : blackSeconds;
    }

    public function setSecsLeftAtTimestamp(color:PieceColor, secs:Float)
    {
        if (color == White) 
            whiteSeconds = secs;
        else
            blackSeconds = secs;
    }

    public function addSecsLeftAtTimestamp(color:PieceColor, secs:Float)
    {
        if (color == White) 
            whiteSeconds += secs;
        else
            blackSeconds += secs;
    }

    public function getSecsLeftNow(color:PieceColor, nowTS:Float, timeRunning:Bool):Float
    {
        var secsAtTimestamp:Float = getSecsLeftAtTimestamp(color);

        if (!timeRunning)
            return secsAtTimestamp;

        var elapsedSecs:Float = timestamp.getIntervalSecsToNow();
        return secsAtTimestamp - elapsedSecs;
    }

    public function toString():String 
    {
        return 'TimeReservesData(whiteSeconds=$whiteSeconds, blackSeconds=$blackSeconds, timestamp=$timestamp)';
    }

    public function copy():TimeReservesData 
    {
        return new TimeReservesData(whiteSeconds, blackSeconds, timestamp);    
    }

    public function new(whiteSeconds:Float, blackSeconds:Float, timestamp:UnixTimestamp)
    {
        this.whiteSeconds = whiteSeconds;
        this.blackSeconds = blackSeconds;
        this.timestamp = timestamp;
    }
}