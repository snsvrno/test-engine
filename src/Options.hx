typedef Options = {
	testsPath : String,
	rootPath : String,

	showall : Bool,

	runTests : Array<EReg>,
	runGroups : Array<EReg>,
	ignoreTests : Array<EReg>,
	ignoreGroups : Array<EReg>,
}

function defaults() : Options return {
	testsPath : "tests",
	rootPath: "",

	showall: false,

	runTests: [],
	runGroups: [],
	ignoreTests: [],
	ignoreGroups: [],
}
