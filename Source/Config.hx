package;

import utils.FileLoader;
import utils.PlainYamlParser;

class Config 
{
    public static var dict:PlainYamlDict;
    
    public static function init() 
    {
        FileLoader.loadText('config.yaml', s -> {
            dict = PlainYamlParser.parse(s);
        });
    }
}