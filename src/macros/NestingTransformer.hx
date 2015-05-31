package macros;
import haxe.macro.Context;
import haxe.macro.Expr;
import macros.NestingTransformer.NestBlock;

using tink.MacroApi;

/**
 * ...
 * @author memilian
 */
class NestingTransformer
{

	var lines : Array<String>;
	var firstExpr = true;
	var refIndent = 0;
	var prevIndent = 0;
	var parentBlocks : Array<NestBlock>;
	var rootBlock : NestBlock;
	var nestFunctionName : String;

	public function new(nestFunctionName : String)
	{
		this.nestFunctionName = nestFunctionName;
		
		var fields = Context.getBuildFields();
		var infos = getPosInfo(fields[0].pos);
		var fileContent = File.getContent(infos.path);
		lines = fileContent.split("\n");
		lines.insert(0, " \n"); //align array index with line number
		parentBlocks = new Array<NestBlock>();
		
	}
	
	public function setRoot(expr : Expr) {
		//trace("root set to "+expr);
		rootBlock = new NestBlock(expr, 0);
		parentBlocks.push(rootBlock);
	}
	
	public function doTransform(e : Expr) : Expr {
		parentBlocks = new Array<NestBlock>();
		firstExpr = true;

		return switch(e.expr) {
				case EBlock(arr):
					//trace("entered block");

					var skipFirst = false;
					if(rootBlock == null){
						setRoot(arr[0]);
						skipFirst = true;
					}

					var prevBlock = rootBlock;

					var newArr = arr.map(function(ee : Expr) {

						//trace('parsing expression : ${ee.toString()}');

						var line = lines[getPosInfo(ee.pos).line];
						var indent = countIndent(line);

						if (firstExpr) {
							refIndent = indent-1;
							rootBlock.indent = refIndent;
							prevIndent = refIndent;
							firstExpr = false;
							//trace('refIndent set to $refIndent');
							if(skipFirst){
								skipFirst = false;
								//trace("skipping rootNode");
								return null;
							}
						}

						
						//trace("   "+indent+"   "+line);

						var res = switch(ee.expr) { //TODO: Handle more expressions types here
							//case ENew(
							default:
								ee;
							//return macro $b { [macro try { $ee; } catch (ex:Dynamic) trace(ex) ] };
						}
						var block = new NestBlock(res, indent);
						var diff = indent - prevIndent;
						
						if (diff > 0){
							parentBlocks.push(prevBlock);
							block.parent = prevBlock;
							prevBlock.children.push(block);
						}else if (diff == 0) {
							var parent : NestBlock= parentBlocks[parentBlocks.length - 1];
							block.parent = parent;
							parent.children.push(block);
						}else if (diff < 0) {
							diff *= -1;
							for (i in 0...diff) {
								if(parentBlocks.length>1)
									parentBlocks.pop();
								else
									Context.warning('Not enough indentation, appending to root node : ${res.toString()}', res.pos);
							}
							var parent = parentBlocks[parentBlocks.length - 1];
							block.parent = parent;
							parent.children.push(block);
						}
						
						prevIndent = indent;
						prevBlock = block;
						return res;
					});
					//generateNesting(rootBlock);
					return generateNesting(rootBlock);//macro $b{ newArr };
				default:
					e;
		}
	}
	
	function generateNesting(block : NestBlock) : Expr {
		var expr = block.expr;
		
		if (block.children.length > 0) {
			for (child in block.children) {
				var childExpr = generateNesting(child);
				try{
					expr = expr.field(nestFunctionName).call([childExpr]);
				}catch (ex : Dynamic) {
					Context.error(Std.string(ex), expr.pos);
					trace('error while nesting expr : ${expr.toString()} \n with function $nestFunctionName');
				}
			}
		}
		//trace(expr.toString());
		return expr;
	}
	
	
	function getPosInfo(pos : Position) : ExprFileInfos {
		var spos = Std.string(pos);
		var reg = ~/([A-Z]?:?[.\\\/A-Z]+):([0-9]+):/i;
		reg.match(spos);
		var path :String;
		var line :Int;
		try{
			path = reg.matched(1);
			line = Std.parseInt(reg.matched(2));
		}catch (e : Dynamic)
			trace('could not find file in pos : $pos');

		var res : ExprFileInfos = {
			path : path,
			line : line
		}
		return res;
	}
	
	function countIndent(line : String) : Int{
		var cnt = 0;
		var idx = 0;
		while (true) {
			if (line.charAt(idx) == '\t') {
				cnt++;
				idx++;
			}else {
				return cnt;
			}
		}
	}
	
}

@:publicFields
class NestBlock {
	var indent : Int;
	var expr : Expr;
	var children : Array<NestBlock>;
	var parent : NestBlock;
	
	public function new(expr, indent) {
		this.expr = expr;
		this.parent = null;
		this.indent = indent;
		this.children = new Array<NestBlock>();
	}
}

typedef ExprFileInfos={
	var path : String;
	var line : Int;
}