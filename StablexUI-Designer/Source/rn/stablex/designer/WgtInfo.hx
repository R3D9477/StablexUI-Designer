package rn.stablex.designer;

typedef WgtInfo = {
	var dir:String;
	var title:String;
	var xml:String;
	var src:String;
	var bin: {
		parentClassName:String,
		neko:String,
		cpp:String
	};
	var ico:String;
	var className:String;
	var properties:Array<Array<String>>;
}
