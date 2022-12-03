package gfx;

import haxe.ui.components.Image;
import haxe.ui.containers.Box;
import haxe.ui.styles.Style;
import haxe.ui.core.Component;
import haxe.ui.core.Screen as HaxeUIScreen;
using net.shared.utils.MathUtils;

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
    PercentWidth;
    PercentHeight;
    StyleProp(prop:ResponsiveStyleProperty);
    IconWidth;
    IconHeight;
}

enum Dimension
{
    Exact(value:Float);
    Percent(value:Float);
    VW(value:Float);
    VH(value:Float);
    VMIN(value:Float);
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
    public static function resizeComponent(comp:Component, rules:Map<ResponsiveProperty, ResponsivenessRule>)
    {
        var newStyle:Style = comp.customStyle.clone();

        for (property => rule in rules.keyValueIterator())
        {
            switch property 
            {
                case Width: 
                    recalcWidth(comp, rule);
                case Height:
                    recalcHeight(comp, rule);
                case PercentWidth:
                    comp.percentWidth = evaluateRule(rule);
                case PercentHeight:
                    comp.percentHeight = evaluateRule(rule);
                case StyleProp(prop):
                    recalcStyle(newStyle, prop, rule);
                case IconWidth:
                    comp.findComponent(Image).width = evaluateRule(rule);
                case IconHeight:
                    comp.findComponent(Image).height = evaluateRule(rule);
            }
        }

        comp.customStyle = newStyle;
    }

    public static function fitComponent(comp:Component) 
    {
        if (comp.parentComponent == null)
            return;

        var parentRatio = comp.parentComponent.layout.usableWidth / comp.parentComponent.layout.usableHeight;
        var compRatio = comp.width / comp.height;
        
        if (parentRatio > compRatio)
        {
            comp.width = comp.parentComponent.layout.usableHeight * compRatio;
            comp.height = comp.parentComponent.layout.usableHeight;
        }
        else
        {
            comp.width = comp.parentComponent.layout.usableWidth;
            comp.height = comp.parentComponent.layout.usableWidth / compRatio;
        }
    }

    private static function recalcWidth(comp:Component, rule:ResponsivenessRule)
    {
        var parent:Null<Component> = comp.parentComponent;
        var parentWidth:Null<Float> = parent != null? parent.width : null;
        comp.width = evaluateRule(rule, parentWidth);
    }

    private static function recalcHeight(comp:Component, rule:ResponsivenessRule)
    {
        var parent:Null<Component> = comp.parentComponent;
        var parentHeight:Null<Float> = parent != null? parent.height : null;
        comp.height = evaluateRule(rule, parentHeight);
    }

    private static function recalcStyle(style:Style, prop:ResponsiveStyleProperty, rule:ResponsivenessRule)
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
            case VMIN(value): evaluateDim(VMIN(value));
            case Min(values): values.map(evaluateDim.bind(_, parentVal)).arrmin();
            case Max(values): values.map(evaluateDim.bind(_, parentVal)).arrmax();
            case Clamp(value, min, max): evaluateDim(value, parentVal).clamp(evaluateDim(min, parentVal), evaluateDim(max, parentVal));
        }
    }

    private static function evaluateDim(dim:Dimension, ?parentVal:Float):Float
    {
        if (parentVal == null && dim.match(Percent(_)))
            throw "Percent dim may only be used for Width/Height properties";

        return switch dim 
        {
            case Exact(value): value;
            case Percent(value): parentVal * value / 100;
            case VW(value): HaxeUIScreen.instance.actualWidth * value / 100;
            case VH(value): HaxeUIScreen.instance.actualHeight * value / 100;
            case VMIN(value): Math.min(HaxeUIScreen.instance.actualWidth, HaxeUIScreen.instance.actualHeight) * value / 100;
        }
    }
}