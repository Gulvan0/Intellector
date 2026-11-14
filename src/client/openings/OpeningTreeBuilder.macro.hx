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
        var byId:Array<Expr> = [];
        var seenIds:Array<Int> = [];

        var raw:Dynamic = Json.parse(File.getContent(rawJsonPath));
        for (sip in Reflect.fields(raw))
        {
            var entry:Dynamic = Reflect.field(raw, sip);
            var code:String = Reflect.field(entry, "code");
            var prefix:String = code != "" ? code + ". " : "";
            var name:String = prefix + Reflect.field(entry, "name_en");
            var id:Int = Reflect.field(entry, "id");
            var entryExpr:Expr = macro new client.openings.OpeningEntry($v{id}, $v{code}, $v{name});
            map.push(macro $v{sip} => $entryExpr);
            if (!seenIds.contains(id))
            {
                seenIds.push(id);
                byId.push(macro $v{id} => $entryExpr);
            }
        }

        fields.push({
            pos: Context.currentPos(),
            name: "openings",
            meta: null,
            kind: FieldType.FVar(macro : Map<String, client.openings.OpeningEntry>, macro $a{map}),
            doc: null,
            access: [Access.APublic, Access.AStatic]
        });

        fields.push({
            pos: Context.currentPos(),
            name: "byId",
            meta: null,
            kind: FieldType.FVar(macro : Map<Int, client.openings.OpeningEntry>, macro $a{byId}),
            doc: null,
            access: [Access.APublic, Access.AStatic]
        });

        return fields;
    }
}
