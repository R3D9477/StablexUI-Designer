package rn.stablex.designer;

typedef WgtInfo = {
	var wgtDir:String;
	var title:String;
	var xml:String;
	var src:String;
	var bin: {
		neko:String,
		cpp:String
	};
	var ico:String;
	var className:String;
	var properties:Array<Array<String>>;
}
