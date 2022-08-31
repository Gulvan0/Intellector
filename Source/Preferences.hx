package;

import utils.StringUtils;
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

private class Preference<T>
{
    private static var FIVE_YEARS = 60 * 60 * 24 * 365 * 5;

    private var name:PreferenceName;
    private var cookieName:String;
    private var kind:String;
    private var defaultValue:T;
    private var value:T;

    public function get() 
    {
        return value;    
    }

    public function set(v:T, ?suppressBroadcasting:Bool = false) 
    {
        value = v;
        Cookie.set(cookieName, Std.string(value), FIVE_YEARS);
        if (!suppressBroadcasting)
            GlobalBroadcaster.broadcast(PreferenceUpdated(name));
    }

    public function resetToDefault()
    {
        set(defaultValue);
    }

    public function load():Bool
    {
        if (!Cookie.exists(cookieName))
            return false;

        var rawValue:String = Cookie.get(cookieName);

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

    public function new(name:PreferenceName, defaultValue:T, ?delayLoading:Bool = false) 
    {
        this.name = name;
        this.cookieName = switch name {
            case Language: "lang";
            case Markup: "markup";
            default: name.getName();
        }
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

enum PreferenceName
{
    Language;
    Markup;
    Premoves;
    BranchingType;
    BranchingShowTurnColor;
    SilentChallenges;
}

class Preferences
{
    public static final language:Preference<Language> = new Preference(Language, EN, true);
    
    public static final markup:Preference<Markup> = new Preference(Markup, Over);
    public static final premoveEnabled:Preference<Bool> = new Preference(Premoves, false);
    public static final branchingTabType:Preference<BranchingTabType> = new Preference(BranchingType, Tree);
    public static final branchingTurnColorIndicators:Preference<Bool> = new Preference(BranchingShowTurnColor, true);
    public static final silentChallenges:Preference<Bool> = new Preference(SilentChallenges, false);
}