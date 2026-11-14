package client.logic.games;

import client.datatypes.bot.BotKind;
import client.datatypes.game.Outcome.DecisiveOutcomeKind;
import client.datatypes.game.Outcome.DrawishOutcomeKind;
import client.datatypes.games.BotFilter;
import client.datatypes.games.Condition;
import client.datatypes.games.ConditionGroup;
import client.datatypes.games.ConditionOperator;
import client.datatypes.games.ConditionParameter;
import client.datatypes.games.EqualityValue;
import client.datatypes.games.FormulaNode;
import client.datatypes.games.GameProperty;
import client.datatypes.games.GroupKind;
import client.datatypes.games.LocalDateTime;
import client.datatypes.games.Operand;
import client.datatypes.games.OperandType;
import client.datatypes.games.ParameterType;
import client.datatypes.games.PlayerValue;
import client.datatypes.games.ResultKind;
import client.datatypes.games.TimeOfDay;
import client.datatypes.timecontrol.TimeControlKind;
import client.logic.bot.BotStrengthRules;
import client.logic.games.OperandResolver.LocalClock;
import client.logic.games.OperandResolver.ResolvedInstant;
import client.openings.OpeningTree;
import haxe.Exception;
import haxe.Json;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import intellectorboard.primitives.piece.PieceColor;

using StringTools;

private typedef DateTimeWriter = (LocalDateTime, ConditionOperator, Int)->String;

/** Thrown for a formula that doesn't follow the format, or exceeds a cap **/
class FormulaDecodingException extends Exception {}

/**
    The formula format of `knowledge/game_archive.md` ("Formula format"): the JSON stored in saved
    filters, its base64url form in URL fragments, and the request form, whose `DateTime` operands
    are resolved into UTC instants.
**/
class FormulaCodec
{
    public static inline final VERSION:Int = 1;

    private static final LOGIN_PATTERN:EReg = ~/^[a-z][a-z0-9_]{1,31}$/;
    private static final DATE_PATTERN:EReg = ~/^(\d{4})-(\d{2})-(\d{2})$/;
    private static final DATE_TIME_PATTERN:EReg = ~/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})$/;
    private static inline final MAX_SIP_LENGTH:Int = 127;
    private static inline final ANACONDA_FAMILY:String = "anaconda";

    /** The stored form. `root` must be finalized: every condition complete **/
    public static function encode(root:ConditionGroup):String
    {
        return document(root, null);
    }

    /** The form search and export requests carry. `root` must be finalized **/
    public static function encodeForRequest(root:ConditionGroup, ?clock:LocalClock):String
    {
        return document(root, (value, conditionOperator, index) -> instantJson(OperandResolver.resolve(value, conditionOperator, index, clock)));
    }

    /** The stored form, base64url-encoded without padding. `root` must be finalized **/
    public static function toFragment(root:ConditionGroup):String
    {
        return Base64.urlEncode(Bytes.ofString(encode(root)));
    }

    /** Throws `FormulaDecodingException` **/
    public static function fromFragment(fragment:String):ConditionGroup
    {
        var json:String = try Base64.urlDecode(fragment).toString() catch (e:Dynamic) fail("The fragment is not base64url");
        return decode(json);
    }

    /** Parses the stored form, upgrading an older version. Throws `FormulaDecodingException` **/
    public static function decode(json:String):ConditionGroup
    {
        if (json.length > FormulaCaps.MAX_FORMULA_LENGTH)
            fail("The formula is too long");

        var parsed:Dynamic = try Json.parse(json) catch (e:Dynamic) fail("The formula is not JSON");

        var document:Dynamic = upgrade(expectObject(parsed, "A formula"));
        expectFields(document, ["version", "root"], "A formula");
        var root:ConditionGroup = switch parseNode(Reflect.field(document, "root"), null) {
            case Group(group) if (group.kind == AND): group;
            default: fail("The root is not an AND");
        }

        if (!FormulaCaps.fits(root))
            fail("The formula exceeds a cap");
        return root;
    }

    private static function upgrade(document:Dynamic):Dynamic
    {
        var version:Dynamic = Reflect.field(document, "version");
        if (version == VERSION)
            return document;
        return fail('Unsupported formula version $version');
    }

    // JSON is written by hand: the field order stays as written on every target, so equal formulas serialize equally
    private static function document(root:ConditionGroup, resolveDateTime:Null<DateTimeWriter>):String
    {
        return object(["version" => Std.string(VERSION), "root" => nodeJson(Group(root), resolveDateTime)], ["version", "root"]);
    }

    private static function nodeJson(node:FormulaNode, resolveDateTime:Null<DateTimeWriter>):String
    {
        switch node
        {
            case Group(group):
                if (group.kind == NOT)
                    return object([NOT => nodeJson(group.children[0], resolveDateTime)], [NOT]);
                return object([group.kind => array(group.children.map(child -> nodeJson(child, resolveDateTime)))], [group.kind]);
            case Leaf(condition):
                var fields:Map<String, String> = ["property" => quote(condition.property)];
                if (condition.parameter != null)
                    fields.set("parameter", parameterJson(condition.parameter));
                if (condition.conditionOperator != null)
                {
                    var conditionOperator:ConditionOperator = condition.conditionOperator;
                    fields.set("operator", quote(conditionOperator));
                    fields.set("operands", array([for (i in 0...condition.operands.length) operandJson(condition.operands[i], conditionOperator, i, resolveDateTime)]));
                }
                else
                    fields.set("values", array(condition.values.map(valueJson)));
                return object(fields, ["property", "parameter", "operator", "operands", "values"]);
        }
    }

    private static function parameterJson(parameter:ConditionParameter):String
    {
        return switch parameter {
            case EitherColor: quote("any");
            case OfColor(color): quote(color == White ? "white" : "black");
            case OfPlayer(player): playerJson(player);
        }
    }

    private static function playerJson(player:PlayerValue):String
    {
        return switch player {
            case User(login): '{"user":${quote(login)}}';
            case Guest(id): '{"guest":$id}';
            case Bot(AnyBot): '{"bot":{}}';
            case Bot(Anaconda): '{"bot":{"family":${quote(ANACONDA_FAMILY)}}}';
            case Bot(AnyLevel(kind)): '{"bot":{"family":${quote(familyName(kind))}}}';
            case Bot(Level(kind, level)): '{"bot":{"family":${quote(familyName(kind))},"level":$level}}';
        }
    }

    private static function operandJson(operand:Operand, conditionOperator:ConditionOperator, index:Int, resolveDateTime:Null<DateTimeWriter>):String
    {
        return switch operand {
            case DateTimeValue(value): resolveDateTime != null ? resolveDateTime(value, conditionOperator, index) : quote(localDateTimeJson(value));
            case DurationValue(ms): wholeNumber(ms);
            case IntValue(value): Std.string(value);
        }
    }

    private static function instantJson(instant:ResolvedInstant):String
    {
        return '{"at":${quote(instant.at)},"inclusive":${instant.inclusive}}';
    }

    public static function localDateTimeJson(value:LocalDateTime):String
    {
        var date:String = '${Std.string(value.year).lpad("0", 4)}-${pad(value.month)}-${pad(value.day)}';
        if (value.time == null)
            return date;
        return '${date}T${pad(value.time.hours)}:${pad(value.time.minutes)}:${pad(value.time.seconds)}';
    }

    private static function valueJson(value:EqualityValue):String
    {
        return switch value {
            case IsPlayer(player): playerJson(player);
            case IsOngoing: quote("ongoing");
            case IsDraw: quote("draw");
            case IsTimeControlKind(kind): quote(kind.getName().toUpperCase());
            case IsBool(flag): Std.string(flag);
            case IsDecisiveOutcome(kind): quote(decisiveOutcomeName(kind));
            case IsDrawishOutcome(kind): quote(drawishOutcomeName(kind));
            case IsDefaultPosition: quote("default");
            case IsCustomPosition(sip): '{"sip":${quote(sip)}}';
            case IsOpening(id): Std.string(id);
            case IsResult(result): quote(result);
        }
    }

    /** The fields present in `fields`, in `order` **/
    private static function object(fields:Map<String, String>, order:Array<String>):String
    {
        return "{" + [for (key in order) if (fields.exists(key)) '${quote(key)}:${fields.get(key)}'].join(",") + "}";
    }

    private static function array(items:Array<String>):String
    {
        return "[" + items.join(",") + "]";
    }

    private static function quote(text:String):String
    {
        return Json.stringify(text);
    }

    private static function wholeNumber(value:Float):String
    {
        var text:String = Std.string(Math.ffloor(value));
        var point:Int = text.indexOf(".");
        return point >= 0 ? text.substr(0, point) : text;
    }

    private static function parseNode(raw:Dynamic, parentKind:Null<GroupKind>):FormulaNode
    {
        var object:Dynamic = expectObject(raw, "A condition");

        for (kind in [AND, OR, NOT])
        {
            if (!Reflect.hasField(object, kind))
                continue;

            expectFields(object, [kind], 'A `$kind` condition');
            if (kind == parentKind)
                fail("Nested groups must alternate");

            var content:Dynamic = Reflect.field(object, kind);
            if (kind == NOT)
                return Group(new ConditionGroup(NOT, [parseNode(content, NOT)]));

            if (!Std.isOfType(content, Array))
                fail('`$kind` takes a list');
            var rawChildren:Array<Dynamic> = content;
            return Group(new ConditionGroup(kind, [for (child in rawChildren) parseNode(child, kind)]));
        }

        return Leaf(parseLeaf(object));
    }

    private static function parseLeaf(object:Dynamic):Condition
    {
        var property:GameProperty = expectString(Reflect.field(object, "property"), "A property");
        if (!PropertyCatalog.ALL.contains(property))
            fail('Unknown property $property');

        var operatorProperty:Bool = PropertyCatalog.isOperatorProperty(property);
        expectFieldsAmong(object, operatorProperty ? ["property", "parameter", "operator", "operands"] : ["property", "parameter", "values"], 'A $property condition');

        var parameter:Null<ConditionParameter> = null;
        var parameterType:Null<ParameterType> = PropertyCatalog.parameterType(property);
        if (parameterType != null)
        {
            if (!Reflect.hasField(object, "parameter"))
                fail('$property needs a parameter');
            parameter = parseParameter(Reflect.field(object, "parameter"), parameterType);
        }
        else if (Reflect.hasField(object, "parameter"))
            fail('$property takes no parameter');

        if (operatorProperty)
        {
            var conditionOperator:ConditionOperator = expectString(Reflect.field(object, "operator"), "An operator");
            if (!PropertyCatalog.operators(property).contains(conditionOperator))
                fail('$conditionOperator is not allowed for $property');

            var rawOperands:Array<Dynamic> = expectArray(Reflect.field(object, "operands") ?? [], "Operands");
            if (rawOperands.length != PropertyCatalog.operandCount(conditionOperator))
                fail('$conditionOperator takes ${PropertyCatalog.operandCount(conditionOperator)} operands');

            var operandType:OperandType = PropertyCatalog.operandType(property);
            return new Condition(property, parameter, conditionOperator, rawOperands.map(raw -> parseOperand(raw, operandType)));
        }

        var rawValues:Array<Dynamic> = expectArray(Reflect.field(object, "values"), "Values");
        if (rawValues.length == 0)
            fail('$property needs a non-empty list of values');
        if (PropertyCatalog.isSingleValued(property) && rawValues.length != 1)
            fail('$property takes exactly one value');
        return new Condition(property, parameter, null, null, rawValues.map(raw -> parseValue(raw, property)));
    }

    private static function parseParameter(raw:Dynamic, type:ParameterType):ConditionParameter
    {
        if (type == OptionalColor && raw == "any")
            return EitherColor;
        if (Std.isOfType(raw, String))
            return OfColor(parseColor(raw));
        if (type == OptionalColor)
            fail("Expected a color");

        var player:PlayerValue = parsePlayer(raw);
        if (type == UserOrColor && !player.match(User(_)))
            fail("Only a user or a color is allowed here");
        return OfPlayer(player);
    }

    private static function parseColor(raw:Dynamic):PieceColor
    {
        return switch raw {
            case "white": White;
            case "black": Black;
            default: fail('Unknown color $raw');
        }
    }

    private static function parsePlayer(raw:Dynamic):PlayerValue
    {
        var object:Dynamic = expectObject(raw, "A player");
        var fields:Array<String> = Reflect.fields(object);
        if (fields.length != 1)
            fail("A player has exactly one of `user`, `guest`, `bot`");

        switch fields[0]
        {
            case "user":
                var login:String = expectString(Reflect.field(object, "user"), "A login");
                if (!LOGIN_PATTERN.match(login))
                    fail('Invalid login $login');
                return User(login);
            case "guest":
                var id:Int = expectInt(Reflect.field(object, "guest"), "A guest id");
                if (id < 0)
                    fail("A guest id can't be negative");
                return Guest(id);
            case "bot":
                return Bot(parseBot(expectObject(Reflect.field(object, "bot"), "A bot")));
            default:
                return fail("A player has exactly one of `user`, `guest`, `bot`");
        }
    }

    private static function parseBot(object:Dynamic):BotFilter
    {
        expectFieldsAmong(object, ["family", "level"], "A bot");
        var rawFamily:Dynamic = Reflect.field(object, "family");
        var rawLevel:Dynamic = Reflect.field(object, "level");

        if (rawFamily == null)
        {
            if (rawLevel != null)
                fail("A bot level needs a family");
            return AnyBot;
        }

        var family:String = expectString(rawFamily, "A bot family");
        if (family == ANACONDA_FAMILY)
        {
            if (rawLevel != null)
                fail("Anaconda has no levels");
            return Anaconda;
        }

        var kind:Null<BotKind> = kindOfFamily(family);
        if (kind == null)
            fail('Unknown bot family $family');
        if (rawLevel == null)
            return AnyLevel(kind);

        var level:Int = expectInt(rawLevel, "A bot level");
        if (!BotStrengthRules.isAvailable(kind, level))
            fail('Level $level is out of range for $family');
        return Level(kind, level);
    }

    private static function parseOperand(raw:Dynamic, type:OperandType):Operand
    {
        return switch type {
            case DateTimeOperand:
                DateTimeValue(parseLocalDateTime(expectString(raw, "A DateTime operand")));
            case DurationOperand:
                var ms:Float = expectWholeNumber(raw, "A duration");
                if (ms < 0)
                    fail("A duration can't be negative");
                DurationValue(ms);
            case IntOperand:
                IntValue(expectInt(raw, "An integer operand"));
        }
    }

    public static function parseLocalDateTime(text:String):LocalDateTime
    {
        var withTime:Bool = DATE_TIME_PATTERN.match(text);
        var pattern:EReg = withTime ? DATE_TIME_PATTERN : DATE_PATTERN;
        if (!withTime && !DATE_PATTERN.match(text))
            fail('Invalid DateTime operand $text');

        var year:Int = Std.parseInt(pattern.matched(1));
        var month:Int = Std.parseInt(pattern.matched(2));
        var day:Int = Std.parseInt(pattern.matched(3));
        if (year < 1 || month < 1 || month > 12 || day < 1 || day > OperandResolver.daysInMonth(year, month))
            fail('Invalid DateTime operand $text');
        if (!withTime)
            return new LocalDateTime(year, month, day);

        var hours:Int = Std.parseInt(pattern.matched(4));
        var minutes:Int = Std.parseInt(pattern.matched(5));
        var seconds:Int = Std.parseInt(pattern.matched(6));
        if (hours > 23 || minutes > 59 || seconds > 59)
            fail('Invalid DateTime operand $text');
        return new LocalDateTime(year, month, day, new TimeOfDay(hours, minutes, seconds));
    }

    private static function parseValue(raw:Dynamic, property:GameProperty):EqualityValue
    {
        switch property
        {
            case PLAYER:
                return IsPlayer(parsePlayer(raw));
            case WINNER:
                if (raw == "ongoing")
                    return IsOngoing;
                if (raw == "draw")
                    return IsDraw;
                return IsPlayer(parsePlayer(raw));
            case TIME_CONTROL_KIND:
                var name:String = expectString(raw, "A time control kind");
                for (kind in TimeControlKind.createAll())
                    if (kind.getName().toUpperCase() == name)
                        return IsTimeControlKind(kind);
                return fail('Unknown time control kind $name');
            case RATED | ELO_PROVISIONAL:
                if (!Std.isOfType(raw, Bool))
                    fail("A boolean value is expected");
                return IsBool(raw);
            case OUTCOME:
                var name:String = expectString(raw, "An outcome");
                for (kind in DecisiveOutcomeKind.createAll())
                    if (decisiveOutcomeName(kind) == name)
                        return IsDecisiveOutcome(kind);
                for (kind in DrawishOutcomeKind.createAll())
                    if (drawishOutcomeName(kind) == name)
                        return IsDrawishOutcome(kind);
                return fail('Unknown outcome $name');
            case STARTING_POSITION:
                if (raw == "default")
                    return IsDefaultPosition;
                var object:Dynamic = expectObject(raw, "A starting position");
                expectFields(object, ["sip"], "A starting position");
                var sip:String = expectString(Reflect.field(object, "sip"), "A SIP");
                if (sip.length == 0 || sip.length > MAX_SIP_LENGTH)
                    fail("Invalid SIP length");
                return IsCustomPosition(sip);
            case OPENING:
                var id:Int = expectInt(raw, "An opening id");
                if (!OpeningTree.byId.exists(id))
                    fail('Unknown opening $id');
                return IsOpening(id);
            case RESULT:
                var result:ResultKind = expectString(raw, "A result");
                if (![ONGOING, WHITE_WON, BLACK_WON, DRAW].contains(result))
                    fail('Unknown result $result');
                return IsResult(result);
            default:
                return fail('$property is not a sole equality property');
        }
    }

    private static function familyName(kind:BotKind):String
    {
        return switch kind {
            case STANDARD: "haxaconda_standard";
            case TRAILBLAZER: "haxaconda_trailblazer";
            case VREZH: "haxaconda_vrezh";
            case FORTRESS: "haxaconda_fortress";
            case UNCHAINED: "haxaconda_unchained";
        }
    }

    private static function kindOfFamily(family:String):Null<BotKind>
    {
        for (kind in [STANDARD, TRAILBLAZER, VREZH, FORTRESS, UNCHAINED])
            if (familyName(kind) == family)
                return kind;
        return null;
    }

    private static function decisiveOutcomeName(kind:DecisiveOutcomeKind):String
    {
        return switch kind {
            case Mate: "FATUM";
            case Breakthrough: "BREAKTHROUGH";
            case Stalemate: "STALEMATE";
            case Timeout: "TIMEOUT";
            case Resign: "RESIGN";
            case Abandon: "ABANDON";
            case CheatingAbort: "CHEATING_ABORT";
        }
    }

    private static function drawishOutcomeName(kind:DrawishOutcomeKind):String
    {
        return switch kind {
            case DrawAgreement: "DRAW_AGREEMENT";
            case Repetition: "REPETITION";
            case NoProgress: "NO_PROGRESS";
            case Abort: "ABORT";
        }
    }

    private static function expectObject(raw:Dynamic, what:String):Dynamic
    {
        if (raw == null || Reflect.isFunction(raw) || Std.isOfType(raw, String) || Std.isOfType(raw, Array) || Std.isOfType(raw, Float) || Std.isOfType(raw, Bool) || !Reflect.isObject(raw))
            fail('$what must be an object');
        return raw;
    }

    private static function expectArray(raw:Dynamic, what:String):Array<Dynamic>
    {
        if (!Std.isOfType(raw, Array))
            fail('$what must be a list');
        return raw;
    }

    private static function expectString(raw:Dynamic, what:String):String
    {
        if (!Std.isOfType(raw, String))
            fail('$what must be a string');
        return raw;
    }

    private static function expectWholeNumber(raw:Dynamic, what:String):Float
    {
        if (Std.isOfType(raw, Bool) || !Std.isOfType(raw, Float))
            fail('$what must be an integer');
        var number:Float = raw;
        if (Math.isNaN(number) || !Math.isFinite(number) || Math.ffloor(number) != number)
            fail('$what must be an integer');
        return number;
    }

    private static function expectInt(raw:Dynamic, what:String):Int
    {
        var number:Float = expectWholeNumber(raw, what);
        if (Math.abs(number) > 2147483647)
            fail('$what is out of range');
        return Std.int(number);
    }

    /** Exactly `fields`, all present **/
    private static function expectFields(object:Dynamic, fields:Array<String>, what:String):Void
    {
        var present:Array<String> = Reflect.fields(object);
        if (present.length != fields.length || !Lambda.foreach(fields, field -> present.contains(field)))
            fail('$what has the fields ${fields.join(", ")}');
    }

    /** No fields besides `fields` **/
    private static function expectFieldsAmong(object:Dynamic, fields:Array<String>, what:String):Void
    {
        for (field in Reflect.fields(object))
            if (!fields.contains(field))
                fail('Unexpected field $field in $what');
    }

    private static function pad(value:Int):String
    {
        return Std.string(value).lpad("0", 2);
    }

    private static function fail<T>(message:String):T
    {
        throw new FormulaDecodingException(message);
    }
}
