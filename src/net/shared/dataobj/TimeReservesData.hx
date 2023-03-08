package net.shared.dataobj;

class TimeReservesData
{
    public var whiteSeconds:Float;
    public var blackSeconds:Float;
    public var timestamp:Float;

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

        var elapsedSecs:Float = (nowTS - timestamp) / 1000;
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

    public function new(whiteSeconds:Float, blackSeconds:Float, timestamp:Float)
    {
        this.whiteSeconds = whiteSeconds;
        this.blackSeconds = blackSeconds;
        this.timestamp = timestamp;
    }
}