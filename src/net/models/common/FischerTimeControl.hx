package net.models.common;

class FischerTimeControl
{
	public var start_seconds:Int;
	public var increment_seconds:Int;

	public function new(start_seconds:Int, increment_seconds:Int)
	{
		this.start_seconds = start_seconds;
		this.increment_seconds = increment_seconds;
	}
}
