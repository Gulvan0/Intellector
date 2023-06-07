package tests.ui.utils.components;

import haxe.ui.data.ArrayDataSource;
import utils.StringUtils;
import haxe.ui.containers.HBox;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/testenv/initparam.xml"))
class InitParameterEntry extends HBox
{
    public function getSelected():Int
    {
        return paramValuesDropdown.selectedIndex;
    }

    public function setSelected(index:Int)
    {
        return paramValuesDropdown.selectedIndex = index;
    }

    public function new(nameLabel:String, valueLabels:Array<String>) 
    {
        super();
        paramName.text = nameLabel + ":";
        paramValuesDropdown.dataSource = ArrayDataSource.fromArray(valueLabels);
    }    
}