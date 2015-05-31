# JadeNesting

  This is a build macro that help you to work with nested structures. 
  It was originally written to facilitate HTML declaration with [hxdom](https://github.com/Blank101/haxe-dom) but is generic enough to work in any case you need to chain expressions with one function (xml, graphs...)
  
  For example, to create this HTML with hxdom :
  ````html
  <html>
    <head></head>
    <body>
    <h2>A Nested List</h2>
    <ul>
      <li>Coffee</li>
      <li>Tea
        <ul>
          <li>Black tea</li>
          <li>Green tea</li>
        </ul>
      </li>
      <li>Milk</li>
    </ul>
    </body>
    </html>
  ````
  
  You could write something like :
  
  ````haxe
  class MyView extends EHtml{
  
    public function new(){
      this
        .append(new EHead())
        .append(new EBody()
          .append(new EHeader2().addText("A Nested List"))
          .append(new EUnorderedList()
            .append(new EListItem().addText("Coffee"))
            .append(new EListItem().addText("Tea")
              .append(new EUnorderedList()
                .append(new EListItem().addText("Black tea"))
                .append(new EListItem().addText("Green tea"))))
            .append(new EListItem().addText("Milk"))));
    }
  }
  ````
  It is a bit tedious having to write append for each element and keeping track of parenthesis. The macro allow you to define your structure with indentation, like in a [jade template](http://jade-lang.com/) :
  
  ````haxe
  @:build(macros.JadeNesting.build("append")) //The parameter is the name of the chaining function
  class MyView extends EHtml{
  
    public function new(){
      @jade(this){
    		new EHead();
    		new EBody();
    			new EHeader2().addText("My shop list");
    			new EUnorderedList();
    				new EListItem().addText("Coffee");
    				new EListItem().addText("Tea");
    					new EUnorderedList();
    						new EListItem().addText("Black tea");
    						new EListItem().addText("Green tea");
    		    new EListItem().addText("Milk");
  	  }
    }
  }
  ````
  
  Every expression within the @jade block will be chained with the function whose name you pass in the build function.
  The parameter in the jade block define the root expression from which the chain start. It is optional :
  
  ````haxe
  @jade{
    new EHtml();  //The first expression will be root
      new EBody();
  }
  ````
  
  As long as it return a type compatible with the chaining function, any expression can be in the block :
  
   ````haxe
  var html : EHtml;
  var body : EBody;
  var shopList : EUnorderedList;
  
  public function new(){
    var html = @jade{
      new EHtml();
        body = new EBody();
          createShopList();
    }
  }
  
  function createShopList(){
    return @jade{
      new EUnorderedList();
  			new EListItem().addText("Coffee");
  			new EListItem().addText("Tea");
  				new EUnorderedList();
  					new EListItem().addText("Black tea");
  					new EListItem().addText("Green tea");
  			new EListItem().addText("Milk");
    }
  }
  ````
  
