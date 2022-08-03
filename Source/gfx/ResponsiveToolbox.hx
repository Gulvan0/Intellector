package gfx;

import haxe.ui.styles.Style;
import haxe.ui.core.Component;
import haxe.ui.core.Screen as HaxeUIScreen;
using utils.MathUtils;

enum ResponsiveStyleProperty
{
    VerticalSpacing;
    HorizontalSpacing;
    FontSize;
    PaddingTop;
    PaddingLeft;
    PaddingRight;
    PaddingBottom;
}

enum ResponsiveProperty
{
    Width;
    Height;
    StyleProp(prop:ResponsiveStyleProperty);
}

enum Dimension
{
    Exact(value:Float);
    Percent(value:Float);
    VW(value:Float);
    VH(value:Float);
}

enum ResponsivenessRule
{
    VW(value:Float);
    VH(value:Float);
    VMIN(value:Float);
    Min(values:Array<Dimension>);
    Max(values:Array<Dimension>);
    Clamp(value:Dimension, min:Dimension, max:Dimension);
}

class ResponsiveToolbox
{
    public static function recalcWidth(comp:Component, rule:ResponsivenessRule)
    {
        var parent:Null<Component> = comp.parentComponent;
        var parentWidth:Null<Float> = parent != null? parent.width : null;
        comp.width = evaluateRule(rule, parentWidth);
    }

    public static function recalcHeight(comp:Component, rule:ResponsivenessRule)
    {
        var parent:Null<Component> = comp.parentComponent;
        var parentHeight:Null<Float> = parent != null? parent.height : null;
        comp.height = evaluateRule(rule, parentHeight);
    }

    public static function recalcStyle(style:Style, prop:ResponsiveStyleProperty, rule:ResponsivenessRule)
    {
        switch prop 
        {
            case VerticalSpacing:
                style.verticalSpacing = evaluateRule(rule);
            case HorizontalSpacing:
                style.horizontalSpacing = evaluateRule(rule);
            case FontSize:
                style.fontSize = evaluateRule(rule);
            case PaddingTop:
                style.paddingTop = evaluateRule(rule);
            case PaddingLeft:
                style.paddingLeft = evaluateRule(rule);
            case PaddingRight:
                style.paddingRight = evaluateRule(rule);
            case PaddingBottom:
                style.paddingBottom = evaluateRule(rule);
        }
    }

    private static function evaluateRule(rule:ResponsivenessRule, ?parentVal:Float):Float
    {
        return switch rule 
        {
            case VW(value): evaluateDim(VW(value));
            case VH(value): evaluateDim(VH(value));
            case VMIN(value): evaluateRule(Min([VW(value), VH(value)]));
            case Min(values): values.map(evaluateDim.bind(_, parentVal)).arrmin();
            case Max(values): values.map(evaluateDim.bind(_, parentVal)).arrmax();
            case Clamp(value, min, max): evaluateDim(value, parentVal).clamp(evaluateDim(min, parentVal), evaluateDim(max, parentVal));
        }
    }

    private static function evaluateDim(dim:Dimension, ?parentVal:Float)
    {
        return switch dim 
        {
            case Exact(value): value;
            case Percent(value): parentVal * value / 100;
            case VW(value): HaxeUIScreen.instance.width * value / 100;
            case VH(value): HaxeUIScreen.instance.height * value / 100;
        }
    }
}