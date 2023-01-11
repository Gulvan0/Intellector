package tests.ui.utils.data;

import haxe.rtti.Meta;
import utils.StringUtils;

enum MaterializedEndpoint
{
    Action(fieldName:String, displayName:String, splitterValues:Null<Array<String>>, prompts:Array<ActionEndpointPrompt>);
    Sequence(fieldName:String, displayName:String, iterations:Int);
}