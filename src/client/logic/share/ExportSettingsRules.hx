package client.logic.share;

import client.datatypes.share.ExportSettings;

/**
    What an export panel's values mean: their ranges, the proportions kept while the size is linked,
    and whether the panel can export. An invalid value stays as typed; the last valid one is what
    the preview shows meanwhile.
**/
class ExportSettingsRules
{
    public static inline final MIN_SIZE:Int = 64;
    public static inline final MAX_SIZE:Int = 4096;
    public static inline final MIN_INTERVAL_MS:Int = 50;
    public static inline final MAX_INTERVAL_MS:Int = 5000;
    public static inline final MAX_DIGITS:Int = 4;

    private static final DIGITS_PATTERN:EReg = ~/^[0-9]+$/;
    private static final NON_DIGIT_PATTERN:EReg = ~/[^0-9]/g;
    private static final HEX_PATTERN:EReg = ~/^#[0-9a-fA-F]{6}$/;

    /** `text` without anything but digits, cut to `MAX_DIGITS` **/
    public static function digitsOnly(text:String):String
    {
        return NON_DIGIT_PATTERN.replace(text, "").substr(0, MAX_DIGITS);
    }

    public static function parseSize(text:String):Null<Int>
    {
        return parseInRange(text, MIN_SIZE, MAX_SIZE);
    }

    public static function parseInterval(text:String):Null<Int>
    {
        return parseInRange(text, MIN_INTERVAL_MS, MAX_INTERVAL_MS);
    }

    /** `#rrggbb` in lower case, or null if `text` isn't one **/
    public static function parseBackground(text:String):Null<String>
    {
        return HEX_PATTERN.match(text) ? text.toLowerCase() : null;
    }

    /** Sets the width as typed; while linked, a valid one also sets the height **/
    public static function setWidth(settings:ExportSettings, text:String):Void
    {
        settings.widthText = text;

        var width:Null<Int> = parseSize(text);
        if (width == null)
            return;

        settings.lastValidWidth = width;

        if (settings.linked)
        {
            var height:Int = clampSize(Math.round(width * settings.ratio));
            settings.heightText = Std.string(height);
            settings.lastValidHeight = height;
        }
    }

    /** Sets the height as typed; while linked, a valid one also sets the width **/
    public static function setHeight(settings:ExportSettings, text:String):Void
    {
        settings.heightText = text;

        var height:Null<Int> = parseSize(text);
        if (height == null)
            return;

        settings.lastValidHeight = height;

        if (settings.linked)
        {
            var width:Int = clampSize(Math.round(height / settings.ratio));
            settings.widthText = Std.string(width);
            settings.lastValidWidth = width;
        }
    }

    /** Linking keeps the proportions of the current size, if both of its values are valid **/
    public static function setLinked(settings:ExportSettings, linked:Bool):Void
    {
        settings.linked = linked;

        var width:Null<Int> = parseSize(settings.widthText);
        var height:Null<Int> = parseSize(settings.heightText);

        if (linked && width != null && height != null)
            settings.ratio = height / width;
    }

    public static function setBackground(settings:ExportSettings, text:String):Void
    {
        settings.backgroundText = text;

        var background:Null<String> = parseBackground(text);
        if (background != null)
            settings.lastValidBackground = background;
    }

    /** The background to draw, `#rrggbb`; null for a transparent one **/
    public static function effectiveBackground(settings:ExportSettings):Null<String>
    {
        return settings.kind == Image && settings.transparent ? null : settings.lastValidBackground;
    }

    /** Whether the background colour is in use but invalid **/
    public static function backgroundInvalid(settings:ExportSettings):Bool
    {
        return effectiveBackground(settings) != null && parseBackground(settings.backgroundText) == null;
    }

    /** Whether the panel can export: every value in use is valid **/
    public static function isValid(settings:ExportSettings):Bool
    {
        if (parseSize(settings.widthText) == null || parseSize(settings.heightText) == null)
            return false;

        if (backgroundInvalid(settings))
            return false;

        return settings.kind == Image || parseInterval(settings.intervalText) != null;
    }

    private static function parseInRange(text:String, min:Int, max:Int):Null<Int>
    {
        if (!DIGITS_PATTERN.match(text))
            return null;

        var value:Null<Int> = Std.parseInt(text);
        return value != null && value >= min && value <= max ? value : null;
    }

    private static function clampSize(size:Int):Int
    {
        return size < MIN_SIZE ? MIN_SIZE : size > MAX_SIZE ? MAX_SIZE : size;
    }
}
