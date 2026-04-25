package lib.std;

import js.lib.Set;

@:forward(keys, clear)
abstract StringSetMap<V>(Map<String, Set<V>>)
{
    public function new()
    {
        this = [];
    }

    public function hasValues(key: String):Bool
    {
        return this.exists(key) && this[key].size > 0;
    }

    public function add(key:String, value:V)
    {
        if (this.exists(key))
            this[key].add(value);
        else
            this[key] = new Set([value]);
    }

    public function remove(key:String, value:V)
    {
        if (!this.exists(key))
            return;

        this[key].delete(value);
        if (this[key].size == 0)
            this.remove(key);
    }

    public function get(key:String):Iterator<V>
    {
        if (!this.exists(key))
            return [].iterator();
        return this[key].iterator();
    }

    public function removeAll(key:String)
    {
        this.remove(key);
    }
}
