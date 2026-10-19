package client.datatypes;

class FischerTimeControl
{
	public var startSeconds:Int;
	public var incrementSeconds:Int;

    public function getKind():TimeControlKind
    {
        var determinant:Int = startSeconds + 40 * incrementSeconds;
        if (determinant < 1 * 60)
            return Hyperbullet;
        else if (determinant < 3 * 60)
            return Bullet;
        else if (determinant < 10 * 60)
            return Blitz;
        else if (determinant < 60 * 60)
            return Rapid;
        else
            return Classic;
    }

    public function new(startSeconds:Int, incrementSeconds:Int)
    {
        this.startSeconds = startSeconds;
        this.incrementSeconds = incrementSeconds;
    }
}
