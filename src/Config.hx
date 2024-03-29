package;

import utils.FileLoader;
import utils.PlainYamlParser;

class Config 
{
    public static var dict:PlainYamlDict;
    
    public static function init(onInitFinished:Void->Void) 
    {
        FileLoader.loadText('./config.yaml', s -> {
            dict = PlainYamlParser.parse(s);
            onInitFinished();
        });
    }
}