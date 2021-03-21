package;

typedef Entry = 
{
    var date:String;
    var text:String;
}

class Changes
{
    private static var changelog:Array<Entry> = [
        {date: "21.03.2021", text:"Added 'Remember me' option and logout button"},
        {date: "20.03.2021", text:"Added game info and opening database"},
        {date: "19.03.2021", text:"Added in-game chat, open challenges and arbitrary time control"},
        {date: "17.03.2021", text:"Added changelog"}
    ];

    public static function getFormatted():String
    {
        var result:String = '<font size="16">';
        for (entry in changelog)
            result += '<b>${entry.date}.</b> ${entry.text}\n';
        result += '</font>';
        return result;
    }
}