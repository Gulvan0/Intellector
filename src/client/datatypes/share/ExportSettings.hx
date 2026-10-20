package client.datatypes.share;

/**
    An export panel's values as typed, valid or not, plus what is derived from them as they change:
    the proportions to keep while linked, and the last valid size and colour, which the preview
    keeps showing while a field is invalid.
**/
class ExportSettings
{
    public final kind:ExportKind;
    public var widthText:String;
    public var heightText:String;
    /** Height over width, kept while `linked` **/
    public var ratio:Float;
    public var linked:Bool = true;
    public var backgroundText:String;
    public var transparent:Bool = false;
    public var labels:Bool = true;
    public var highlightLastMove:Bool = true;
    public var intervalText:String;

    public var lastValidWidth:Int;
    public var lastValidHeight:Int;
    /** `#rrggbb` **/
    public var lastValidBackground:String;

    public function new(kind:ExportKind, width:Int, height:Int, background:String, intervalMs:Int)
    {
        this.kind = kind;
        widthText = Std.string(width);
        heightText = Std.string(height);
        ratio = height / width;
        backgroundText = background;
        intervalText = Std.string(intervalMs);
        lastValidWidth = width;
        lastValidHeight = height;
        lastValidBackground = background;
    }
}
