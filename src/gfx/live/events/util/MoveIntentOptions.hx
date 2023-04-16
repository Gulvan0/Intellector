package gfx.live.events.util;

@:structInit class MoveIntentOptions 
{
    public final fastPromotion:FastPromotionOption;
    public final fastChameleon:FastChameleonOption;

    public function new(fastPromotion:FastPromotionOption, fastChameleon:FastChameleonOption)
    {
        this.fastPromotion = fastPromotion;
        this.fastChameleon = fastChameleon;
    }
}