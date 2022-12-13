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

    public function toString():String 
    {
        return 'TimeReservesData(whiteSeconds=$whiteSeconds, blackSeconds=$blackSeconds, timestamp=$timestamp)';
    }

    public function new(whiteSeconds:Float, blackSeconds:Float, timestamp:Float)
    {
        this.whiteSeconds = whiteSeconds;
        this.blackSeconds = blackSeconds;
        this.timestamp = timestamp;
    }
}