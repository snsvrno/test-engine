typedef Paths = {
	root: String,
	tests: String,
}

typedef Files = {
	test: String,
	hxml: String,
}

typedef Filters = {
	test: Array<EReg>,
}

typedef Options = {
	version: String,

	filter : Filters,

	verbose: Bool,
	showSymbols : Bool,
	titlesOnly: Bool,
	showPassing: Bool,

	file: Files,
	path : Paths,
}

function defaults() : Options return {
	version: "0.0.0",

	filter: { 
		test: [ ],
	},

	verbose: false,
	showSymbols: false,
	titlesOnly: false,
	showPassing: false,

	file: {
		test: "tests.json",
		hxml: "test.hxml",
	},

	path: {
		root: "",
		tests: "tests",
	}
}
