package net.shared;

class TimeReservesData
{
    public var whiteSeconds:Float;
    public var blackSeconds:Float;
    public var timestamp:Float;

    public function secsLeftMap():Map<PieceColor, Float> 
    {
        return [White => whiteSeconds, Black => blackSeconds];
    }

    public function new(whiteSeconds:Float, blackSeconds:Float, timestamp:Float)
    {
        this.whiteSeconds = whiteSeconds;
        this.blackSeconds = blackSeconds;
        this.timestamp = timestamp;
    }
}