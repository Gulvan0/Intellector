package tests.ui.utils.components;

import haxe.ui.data.ArrayDataSource;
import utils.StringUtils;
import haxe.ui.containers.HBox;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/testenv/initparam.xml"))
class InitParameterEntry extends HBox
{
    public function getSelected():Int
    {
        return paramValuesDropdown.selectedIndex;
    }

    public function new(nameLabel:String, valueLabels:Array<String>) 
    {
        super();
        paramName.text = nameLabel + ":";
        paramValuesDropdown.dataSource = ArrayDataSource.fromArray(valueLabels);
    }    
}