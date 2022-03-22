package utils;

import openfl.geom.Point;

class Geometry 
{
    public static function rotated(point:Point, radians:Float):Point
    {
        var cos = Math.cos(radians);
        var sin = Math.sin(radians);
        return new Point(cos * point.x - sin * point.y, sin * point.x + cos * point.y);
    }

    public static function normalized(point:Point, length:Float):Point
    {
        var clone = point.clone();
        clone.normalize(length);
        return clone;
    }

    public static function reversed(point:Point):Point
    {
        return new Point(-point.x, -point.y);
    }

    public static function orthogonalCW(point:Point):Point
    {
        return new Point(point.y, -point.x);
    }
}