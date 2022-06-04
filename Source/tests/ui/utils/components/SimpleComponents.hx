package tests.ui.utils.components;

import haxe.ui.components.Button;
import tests.ui.utils.data.TestCaseInfo;
import haxe.ui.components.CheckBox;

class SimpleComponents
{
    public static function checkbox(moduleName:String, checkText:String, storedData:TestCaseInfo):CheckBox
    {
        var checkbox:CheckBox = new CheckBox();
        checkbox.text = checkText;
        checkbox.selected = storedData.getCheck(moduleName, checkText);
        checkbox.onChange = e -> {
            storedData.setCheck(moduleName, checkText, checkbox.selected);
        };
        return checkbox;
    }

    public static function fullActionBtn(text:String, callback:Void->Void):Button
    {
        var btn:Button = new Button();
        btn.percentWidth = 100;
        btn.text = text;
        btn.onClick = e -> {callback();};
        return btn;
    }

    public static function splittedActionBtn(splitterValue:String, totalSplitters:Int, callback:String->Void):Button
    {
        var btn:Button = new Button();
        btn.percentWidth = 100 / totalSplitters;
        btn.text = splitterValue;
        btn.onClick = e -> {callback(splitterValue);};
        return btn;
    }
}