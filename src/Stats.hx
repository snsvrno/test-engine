abstract Stats(haxe.ds.Vector<Int>) {

	public var groupPassed(get, never) : Int;
	inline private function get_groupPassed() : Int return this[0];

	public var groupTotal(get, never) : Int;
	inline private function get_groupTotal() : Int return this[1];

	public var totalPassed(get, never) : Int;
	inline private function get_totalPassed() : Int return this[2];

	public var total(get, never) : Int;
	inline private function get_total() : Int return this[3];

	public function new() {
		this = new haxe.ds.Vector<Int>(4);
		this[0] = 0;
		this[1] = 0;
		this[2] = 0;
		this[3] = 0;
	}

	inline public function newGroup() {
		this[0] = 0;
		this[1] = 0;
	}

	inline public function passed() {
		this[0] += 1;
		this[1] += 1;
		this[2] += 1;
		this[3] += 1;
	}

	inline public function failed() {
		this[1] += 1;
		this[3] += 1;
	}
}
