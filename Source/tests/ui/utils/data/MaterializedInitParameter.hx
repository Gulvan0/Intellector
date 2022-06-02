package tests.ui.utils.data;

import utils.StringUtils;

class MaterializedInitParameter<T>
{
	public final identifier:String;
	public final displayName:String;
	public final paramName:String;
	public final possibleValues:Array<T>;

	public function new(paramName:String, possibleValues:Array<T>)
	{
		this.paramName = paramName;
		this.displayName = StringUtils.asPhrase(paramName);
		this.identifier = StringUtils.asFrankenstein(paramName);
		this.possibleValues = possibleValues;
	}
}