package client.openings;

import haxe.Json;
import sys.io.File;
import haxe.macro.Context;
import haxe.macro.Expr;

class OpeningTreeBuilder
{
    public static macro function build(rawJsonPath:String):Array<Field>
    {
        var fields:Array<Field> = Context.getBuildFields();
        var map:Array<Expr> = [];

        var raw:Dynamic = Json.parse(File.getContent(rawJsonPath));
        for (sip in Reflect.fields(raw))
        {
            var entry:Dynamic = Reflect.field(raw, sip);
            var code:String = Reflect.field(entry, "code");
            var prefix:String = code != "" ? code + ". " : "";
            var name:String = prefix + Reflect.field(entry, "name_en");
            map.push(macro $v{sip} => new client.openings.OpeningEntry($v{name}));
        }

        fields.push({
            pos: Context.currentPos(),
            name: "openings",
            meta: null,
            kind: FieldType.FVar(macro : Map<String, client.openings.OpeningEntry>, macro $a{map}),
            doc: null,
            access: [Access.APublic, Access.AStatic]
        });

        return fields;
    }
}
