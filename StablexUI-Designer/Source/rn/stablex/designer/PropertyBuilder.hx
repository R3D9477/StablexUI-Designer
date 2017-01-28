package rn.stablex.designer;

import ru.stablex.ui.skins.*;
import ru.stablex.ui.widgets.*;

using rn.typext.ext.IterExtender;
using rn.typext.ext.ClassExtender;
using rn.typext.ext.StringExtender;

class PropertyBuilder {
	public static var simpleTypes:Array<String> = ["Int", "Float", "Bool", "String"];
	
	public static var tmpPpRootCls:Class<Dynamic>;
	public static var tmpPpCurrCls:Class<Dynamic>;
	
	public static var tmpPpBuf:String;
	public static var tmpPpBufRmType:Bool;
	public static var tmpPpBufRmName:Bool;
	
	public static var propTypesList:Array<Array<String>>;
	
	public static function init (objCls:Class<Dynamic>) : Void {
		PropertyBuilder.tmpPpRootCls = objCls;
		PropertyBuilder.tmpPpCurrCls = objCls;
		
		PropertyBuilder.tmpPpBuf = "";
		PropertyBuilder.tmpPpBufRmType = true;
		PropertyBuilder.tmpPpBufRmName = true;
		
		PropertyBuilder.propTypesList = new Array<Array<String>>();
	}
	
	public static function rebuildPropTypesList () : Void {
		var props:Array<Array<String>> = [ [ "Not Selected", null ] ];
		
		for (propsMap in [System.wgtPropsMap, System.wgtSkinsMap, System.extClsMap])
			props = props
				.concat(propsMap.keys().array()
					.filter(function (propClass:String) : Bool return PropertyBuilder.tmpPpCurrCls.is(StablexUIMod.resolveClass(propClass)))
					.map(function (propClass) : Array<String> return [ propsMap.get(propClass).name, propClass ])
				);
		
		PropertyBuilder.propTypesList = props;
	}
	
	public static function removeLastType (prototype:String) : String {
		var buf:Array<String> = prototype.split("-");
		
		if (buf.length > 0) {
			var lastProp:String = buf.pop();
			
			if (lastProp.indexOf(":") >= 0) {
				lastProp = lastProp.split(":")[0];
				buf.push(lastProp);
				
				prototype = buf.join("-");
			}
		}
		
		return prototype;
	}
	
	public static function rebuildPropNamesList (typeName:String) : Array<Array<String>> {
		if (!StringExtender.isNullOrEmpty(typeName))
			PropertyBuilder.tmpPpCurrCls = StablexUIMod.resolveClass(typeName);
		
		if (PropertyBuilder.tmpPpBufRmType)
			PropertyBuilder.tmpPpBuf = PropertyBuilder.removeLastType(PropertyBuilder.tmpPpBuf);
		
		PropertyBuilder.tmpPpBufRmType = true;
		PropertyBuilder.tmpPpBufRmName = false;
		
		var props:Array<Array<String>> = [ [ "Not Selected", null ] ];
		
		if (!StringExtender.isNullOrEmpty(typeName)) {
			if (!StringExtender.isNullOrEmpty(PropertyBuilder.tmpPpBuf))
				PropertyBuilder.tmpPpBuf += ":" + typeName.split(".").pop();
			
			var nullToEmptyArr:WgtPropInfo->Dynamic = function (data:WgtPropInfo) : Dynamic return data == null ? { properties: new Array<String>() } : data;
			
			for (propsMap in [System.wgtPropsMap, System.wgtSkinsMap, System.extClsMap])
				props = props
					.concat(nullToEmptyArr(propsMap.get(typeName)).properties
						.filter(function (propClass:String) : Bool return !System.selWgtProps.exists(propClass))
						.map(function (propClass:String) : Array<String> return [ System.propNameMap(propClass), propClass ])
					);
		}
		
		return props;
	}
	
	public static function rebuildPrototype (selPropName:String) : Bool {
		if (PropertyBuilder.tmpPpBufRmName)
			PropertyBuilder.tmpPpBuf = PropertyBuilder.tmpPpBuf.split("-").slice(0, -1).join("-");
		
		PropertyBuilder.tmpPpBufRmName = true;
		
		if (!StringExtender.isNullOrEmpty(selPropName)) {
			if (!StringExtender.isNullOrEmpty(PropertyBuilder.tmpPpBuf))
				PropertyBuilder.tmpPpBuf += "-";
			
			PropertyBuilder.tmpPpBuf += selPropName;
			
			if (!StringExtender.isNullOrEmpty(PropertyBuilder.tmpPpBuf) && !StringExtender.isNullOrEmpty(selPropName)) {
				var propCls:Class<Dynamic> = System.rttiGetPropertyType(PropertyBuilder.tmpPpCurrCls, PropertyBuilder.tmpPpBuf); // must be used RTTI, becuse property can be null (without Class)
				
				var propClsName:String = Type.getClassName(propCls);
				
				if (!StringExtender.isNullOrEmpty(propClsName) && PropertyBuilder.simpleTypes.indexOf(propClsName) < 0) {
					PropertyBuilder.tmpPpCurrCls = propCls;
					PropertyBuilder.rebuildPropTypesList();
					
					return true;
				}
			}
		}
		
		return false;
	}
	
	public static function refreshPrototype (newPrototype:String) : Void {
		PropertyBuilder.tmpPpBuf = newPrototype;
		
		if (!StringExtender.isNullOrEmpty(PropertyBuilder.tmpPpBuf))
			PropertyBuilder.tmpPpCurrCls = System.rttiGetPropertyType(PropertyBuilder.tmpPpRootCls, PropertyBuilder.tmpPpBuf); // must be used RTTI, becuse property can be null (without Class)
		else
			PropertyBuilder.tmpPpCurrCls = PropertyBuilder.tmpPpRootCls;
		
		PropertyBuilder.rebuildPropTypesList();
	}
	
	public static function backPrototype () : Void {
		PropertyBuilder.tmpPpBufRmType = false;
		PropertyBuilder.tmpPpBufRmName = false;
		
		PropertyBuilder.refreshPrototype(PropertyBuilder.removeLastType(PropertyBuilder.tmpPpBuf.split("-").slice(0, -1).join("-")));
	}
}
