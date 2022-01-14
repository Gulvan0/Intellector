package;

import dict.Dictionary;

typedef Entry = 
{
    var date:String;
    var text:String;
}

class Changes
{
    private static var changelog:Array<Entry>;

    public static function initChangelog() 
    {
        if (Preferences.instance.language == EN)
            changelog = [
                {date: "04.11.2021", text:"Low-on-time alerts"},
                {date: "29.10.2021", text:"Some QoL additions"},
                {date: "26.10.2021", text:"Bugfixes"},
                {date: "25.10.2021", text:"Analysis board 2.0, Studies, Explore position"},
                {date: "11.09.2021", text:"Bugfixes"},
                {date: "11.08.2021", text:"Player profile page"},
                {date: "08.08.2021", text:"Revisiting games, Spectation enhancements, Chat history"},
                {date: "05.08.2021", text:"Color selection"},
                {date: "03.08.2021", text:"Bugfixes"},
                {date: "27.07.2021", text:"Now you can scroll the game after it has ended. Also bugfixes"},
                {date: "25.07.2021", text:"Sodium α"},
                {date: "18.07.2021", text:"Bugfixes"},
                {date: "16.07.2021", text:"Extended side box functionality"},
                {date: "19.06.2021", text:"Bugfixes & Notation update"},
                {date: "08.06.2021", text:"Bugfixes"},
                {date: "01.06.2021", text:"Text display bug fixed"},
                {date: "19.05.2021/2", text:"Language select and Russian translation"},
                {date: "19.05.2021/1", text:"Secure websocket connection"},
                {date: "04.04.2021/2", text:"Reconnect to a game, Spectate by link, Disconnection handling"},
                {date: "04.04.2021/1", text:"RMB actions (hex selection & arrow drawing)"},
                {date: "27.03.2021", text:"Marks & Settings menu"},
                {date: "25.03.2021", text:"Spectation"},
                {date: "23.03.2021", text:"Threefold repetition & 100 move rule"},
                {date: "22.03.2021", text:"Additional functionality and bugfixes for analysis board. New openings"},
                {date: "21.03.2021/2", text:"Added simple analysis board"},
                {date: "21.03.2021/1", text:"Added 'Remember me' option and logout button"},
                {date: "20.03.2021", text:"Added game info and opening database"},
                {date: "19.03.2021", text:"Added in-game chat, open challenges and arbitrary time control"},
                {date: "17.03.2021", text:"Added changelog"}
            ];
        else if (Preferences.instance.language == RU)
            changelog = [
                {date: "04.11.2021", text:"Предупреждение при цейтноте"},
                {date: "29.10.2021", text:"QoL-нововведения"},
                {date: "26.10.2021", text:"Исправления багов"},
                {date: "25.10.2021", text:"Доска анализа 2.0, Студии, Анализ в наблюдении"},
                {date: "11.09.2021", text:"Исправления багов"},
                {date: "11.08.2021", text:"Профиль игрока"},
                {date: "08.08.2021", text:"Просмотр прошедших игр, история чата, улучшения наблюдения"},
                {date: "05.08.2021", text:"Выбор цвета"},
                {date: "03.08.2021", text:"Исправления багов"},
                {date: "27.07.2021", text:"Просмотр партии после окончания и исправления багов"},
                {date: "25.07.2021", text:"Sodium α"},
                {date: "18.07.2021", text:"Исправления багов"},
                {date: "16.07.2021", text:"Новые функции боковой панели"},
                {date: "19.06.2021", text:"Исправления багов и обновление нотации"},
                {date: "08.06.2021", text:"Исправления багов"},
                {date: "01.06.2021", text:"Исправлена ошибка отображения текста"},
                {date: "19.05.2021/2", text:"Выбор языка и русский перевод"},
                {date: "19.05.2021/1", text:"Соединение по протоколу wss://"},
                {date: "04.04.2021/2", text:"Переподключение к игре, наблюдение по ссылке, обработка ошибок соединения"},
                {date: "04.04.2021/1", text:"Выделение гексов и стрелочки"},
                {date: "27.03.2021", text:"Метки и меню настроек"},
                {date: "25.03.2021", text:"Наблюдение"},
                {date: "23.03.2021", text:"Троекратное повторение и правило 100 ходов"},
                {date: "22.03.2021", text:"Новые фичи и багфиксы для доски анализа. Новые дебюты"},
                {date: "21.03.2021/2", text:"Упрощенная доска анализа"},
                {date: "21.03.2021/1", text:"Опция 'Запомнить меня' и выход из аккаунта"},
                {date: "20.03.2021", text:"Сводка об игре и база дебютов"},
                {date: "19.03.2021", text:"Внутриигровой чат, открытые вызовы и произвольный контроль времени"},
                {date: "17.03.2021", text:"Добавлен список изменений"}
            ];
    }

    public static function getFormatted():String
    {
        var result:String = '<font size="16">';
        for (entry in changelog)
            result += '<b>${entry.date}.</b> ${entry.text}\n';
        result += '</font>';
        return result;
    }
}