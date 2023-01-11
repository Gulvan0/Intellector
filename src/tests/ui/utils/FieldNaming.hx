package tests.ui.utils;


class FieldNaming
{
    public static function initParamField(paramOwnName:String):String
    {
        return '_initparam_' + paramOwnName;    
    }

    public static function initParamValuesField(paramOwnName:String):String
    {
        return '_paramvalues_' + paramOwnName;    
    }

    public static function initParamLabelsField(paramOwnName:String):String
    {
        return '_paramlabels_' + paramOwnName;    
    }

    public static function fieldPrefixByType(type:FieldType):String 
    {
        return switch type 
        {
            case ActionEndpoint: "_act_";
            case SequenceEndpoint: "_seq_";
            case Provision: "_provide_";
            case InitParameter: "_initparam_";
            case InitParameterValues: "_paramvalues_";
            case InitParameterLabels: "_paramlabels_";
        }
    }

    public static function fieldTypeByPrefix(namePrefix:String):Null<FieldType> 
    {
        return switch namePrefix
        {
            case "_act_": ActionEndpoint;
            case "_seq_": SequenceEndpoint;
            case "_provide_": Provision;
            case "_initparam_": InitParameter;
            case "_paramvalues_": InitParameterValues;
            case "_paramlabels_": InitParameterLabels;
            default: null;
        }
    }

    public static function getFieldPrefix(name:String):String
    {
        return "_" + name.split("_")[1] + "_";
    }
}