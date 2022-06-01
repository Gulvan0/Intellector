package tests.ui.utils;

import tests.ui.utils.data.MaterializedInitParameter;

class FieldNaming
{
    public static function initParamField<T>(param:MaterializedInitParameter<T>):String
    {
        return '_initparam_' + param.paramName;    
    }

    public static function initParamValuesField<T>(param:MaterializedInitParameter<T>):String
    {
        return '_paramvalues_' + param.paramName;    
    }
}