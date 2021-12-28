typedef Options = {
	testsPath : String,
	rootPath : String,

	showsymbols : Bool,
	showall : Bool,
	listonly : Bool,

	runTests : Array<EReg>,
	runGroups : Array<EReg>,
	ignoreTests : Array<EReg>,
	ignoreGroups : Array<EReg>,
}

function defaults() : Options return {
	testsPath : "tests",
	rootPath: "",

	showsymbols: false,
	showall: false,
	listonly: false,

	runTests: [],
	runGroups: [],
	ignoreTests: [],
	ignoreGroups: [],
}
