package gfx.utils;

class SpecialControlSettings
{
    public final fastPromotion:Bool;
    public final lmbArrowDrawingMode:LMBArrowDrawingMode;

    public static function normal():SpecialControlSettings
    {
        return new SpecialControlSettings(false, Disabled);
    }

    public function new(fastPromotion:Bool, lmbArrowDrawingMode:LMBArrowDrawingMode)
    {
        this.fastPromotion = fastPromotion;
        this.lmbArrowDrawingMode = lmbArrowDrawingMode;
    }
}