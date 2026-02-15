package lib.json;

import hxjsonast.Json;

enum UnserializerInput
{
    Str(json:String);
    Ast(json:Json);
}
