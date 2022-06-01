package tests.ui.utils.components;

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
        for (value in valueLabels)
            paramValuesDropdown.dataSource.add({text: value});
    }    
}