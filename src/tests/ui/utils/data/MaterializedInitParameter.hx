package tests.ui.utils.data;

import utils.StringUtils;

class MaterializedInitParameter<T>
{
    public final identifier:String;
    public final fieldName:String;
    public final displayName:String;
    public final possibleValues:Array<T>;
    public final labels:Array<String>;

    public function new(fieldName:String, identifier:String, displayName:String, possibleValues:Array<T>, labels:Array<String>)
    {
        this.fieldName = fieldName;
        this.displayName = displayName;
        this.identifier = identifier;
        this.possibleValues = possibleValues;
        this.labels = labels;
    }
}