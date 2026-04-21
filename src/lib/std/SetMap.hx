package lib.std;

import js.lib.Set;

@:forward(keys, clear)
abstract SetMap<K, V>(Map<K, Set<V>>) from Map<K, Set<V>> to Map<K, Set<V>>
{
    public function new()
    {
        this = [];
    }

    public function hasValues(key: K):Bool
    {
        return this.exists(key) && this[key].size > 0;
    }

    public function add(key:K, value:V)
    {
        if (this.exists(key))
            this[key].add(value);
        else
            this[key] = new Set([value]);
    }

    public function remove(key:K, value:V)
    {
        if (!this.exists(key))
            return;

        this[key].delete(value);
        if (this[key].size == 0)
            this.remove(key);
    }

    public function get(key:K):Iterator<V>
    {
        if (!this.exists(key))
            return [].iterator();
        return this[key].iterator();
    }

    public function removeAll(key:K)
    {
        this.remove(key);
    }
}
