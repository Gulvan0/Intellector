package net.shared.variation;

class VariationMapKVIterator<T>
{
    private var underlyingIterator:KeyValueIterator<String, T>;
  
    public function new(underlyingMap:Map<String, T>) 
    {
        this.underlyingIterator = underlyingMap.keyValueIterator();
    }

    public function hasNext()
    {
        return underlyingIterator.hasNext();
    }

    public function next()
    {
        var nextVal = underlyingIterator.next();
        return {key: VariationPath.deserialize(nextVal.key), value: nextVal.value};
    }
}