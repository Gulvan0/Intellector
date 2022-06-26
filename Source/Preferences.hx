package;

import js.Cookie;
import dict.Language;

enum Markup 
{
    None;
    Side;
    Over;
}

enum BranchingTabType
{
    Tree;
    Outline;
    PlainText;
}

class Preference<T>
{
    private static var FIVE_YEARS = 60 * 60 * 24 * 365 * 5;

    private var name:String;
    private var kind:String;
    private var defaultValue:T;
    private var value:T;

    public function get() 
    {
        return value;    
    }

    public function set(v:T) 
    {
        value = v;
        Cookie.set(name, Std.string(value), FIVE_YEARS);
    }

    public function resetToDefault()
    {
        set(defaultValue);
    }

    public function load():Bool
    {
        if (!Cookie.exists(name))
            return false;

        var rawValue:String = Cookie.get(name);

        if (kind == 'int')
            value = cast(Std.parseInt(rawValue))
        else if (kind == 'float')
            value = cast(Std.parseFloat(rawValue))
        else if (kind == 'str')
            value = cast(rawValue);
        else if (kind == 'enum')
            value = Type.createEnum(Type.getEnum(cast(defaultValue)), rawValue);
        else if (kind == 'bool')
            value = cast(rawValue == 'true');
        else
            throw 'Unsupported preference kind: $kind';

        return true;
    }

    public function new(name:String, defaultValue:T, ?delayLoading:Bool = false) 
    {
        this.name = name;
        this.defaultValue = defaultValue;
        this.value = defaultValue;

        if (Reflect.isEnumValue(defaultValue))
            this.kind = 'enum';
        else if (Std.isOfType(defaultValue, Bool))
            this.kind = 'bool';
        else if (Std.isOfType(defaultValue, Int))
            this.kind = 'int';
        else if (Std.isOfType(defaultValue, Float))
            this.kind = 'float';
        else if (Std.isOfType(defaultValue, String))
            this.kind = 'str';
        else
            throw 'Unsupported preference class: ' + Type.getClassName(Type.getClass(defaultValue));

        if (!delayLoading)
            this.load();
    }
}

class Preferences
{
    public static final language:Preference<Language> = new Preference("lang", EN, true);
    
    public static final markup:Preference<Markup> = new Preference("markup", Over);
    public static final premoveEnabled:Preference<Bool> = new Preference("premoveEnabled", false);
    public static final branchingTabType:Preference<BranchingTabType> = new Preference("branchingTabType", Tree);
    public static final branchingTurnColorIndicators:Preference<Bool> = new Preference("branchingTurnColorIndicators", true);
}