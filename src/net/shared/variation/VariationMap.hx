package net.shared.variation;

class VariationMap<T>
{
    private var mapping:Map<String, T> = [];

    public function get(path:VariationPath) 
    {
        return mapping.get(path.serialize());
    }

    public function set(path:VariationPath, node:T)
    {
        mapping.set(path.serialize(), node);
    }

    public function remove(path:VariationPath)
    {
        mapping.remove(path.serialize());
    }

    public function update(anotherMap:VariationMap<T>)
    {
        for (key => value in anotherMap.keyValueIterator())
            set(key, value);
    }

    public function keyValueIterator():VariationMapKVIterator<T>
    {
        return new VariationMapKVIterator(mapping);
    }

    public function asStringMap():Map<String, T>
    {
        return mapping;
    }

    public function map<S>(func:T->S):VariationMap<S>
    {
        return new VariationMap<S>([for (k => v in mapping.keyValueIterator()) k => func(v)]);
    }

    public function copy():VariationMap<T>
    {
        return new VariationMap<T>(mapping.copy());
    }

    public function new(?mapping:Map<String, T>) 
    {
        if (mapping != null)
            this.mapping = mapping;
    }
}