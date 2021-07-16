module MasonArgParse {
  private use List;
  private use Map;
  private use IO;
  private use Sort;

  const DEBUG=false;
  // TODO: Implement required/optional flag
  // TODO: Implement default values for optional opts
  // TODO: Verify no duplicate names, flags defined by dev
  // TODO: Make sure we don't shadow Chapel flags
  // TODO: Make sure we don't shadow config vars  
  // TODO: Implement Help message and formatting
  // TODO: Add bool flags
  // TODO: Add int opts
  // TODO: Add positional arguments
  // TODO: Add public github issue when available

  if chpl_warnUnstable then
    compilerWarning("ArgumentParser is unstable.");

// A generic argument parser error
  class ArgumentError : Error {
    var msg:string;
    proc init(msg:string) {
      this.msg = msg;
    }
    override proc message() {
      return msg;
    }
  }
  
// indicates a result of argument parsing
  class Argument {
    var present: bool=false;
    var values: list(string);     
    
    proc getValue(){     
      return this.values.first();
    }
    iter getValues(){
      for val in values {
        yield val;
      }      
    }    
    proc hasValue(){
      return !this.values.isEmpty();
    }
  }

  // stores the definition of an option
  class Action {
    var name:string;
    var numOpts:int;
    var opts:[0..numOpts-1] string;
    var numArgs:range;

    // TODO: Decouple the argument from the action
    // maybe pass a list to fill by reference and have the argparser populate
    // the argument instead?
    // also need a bool by ref to indicate presence of arg or not
    proc match(args:[?argsD]string, startPos:int, ref myArg:Argument) throws {
      var high = 0;
      
      // TODO: Replace this high bound with something more reasonable
      if !this.numArgs.hasHighBound() {
        high = 10000000000;
      } else {
        high = this.numArgs.high;
      }
      writeErr("expecting between " + numArgs.low:string + " and "+high:string);
      var matched = 0;
      var pos = startPos;
      var next = pos+1;
      writeErr("starting at pos: " + pos:string);
      while matched < high && next <= argsD.high && !args[next].startsWith("-"){
        pos=next;
        next+=1;
        matched+=1;
        myArg.values.append(args[pos]);
        myArg.present=true;
        writeErr("matched val: " + args[pos] + " at pos: " + pos:string);     
      }
      if matched < this.numArgs.low {
        throw new ArgumentError("\\".join(opts) + " not enough values");
      }
      return next;
    }
 }

  record argumentParser {
    var result: map(string, shared Argument);
    var actions: map(string, owned Action);
    var options: map(string, string);

    proc parseArgs(arguments:[?argsD]string) throws {
      compilerAssert(argsD.rank==1, "parseArgs requires 1D array");
      writeErr("start parsing args");   
      var k = 0;
      // identify optionIndices where opts start
      var optionIndices : map(string, int);
      const zArgsD = {0..argsD.size-1};
      var zeroArgs = arguments.reindex(zArgsD);
      var argsList = new list(zeroArgs);
      
      for i in zArgsD {
        // look for = sign after opt, split into two elements
        if zeroArgs[i].startsWith("-") && zeroArgs[i].find("=") > 0 {
          var elems = new list(zeroArgs[i].split("=", 1));
          // replace this opt=val with opt val
          argsList.pop(i);
          argsList.insert(i, elems.toArray());
        }
      }
      
      for i in argsList.indices {        
        if options.contains(argsList.this(i)) {
          writeErr("found option " + argsList.this(i));
          // create an entry for this index and the argument name
          optionIndices.addOrSet(options.getValue(argsList.this(i)), i);
          writeErr("added option " + argsList.this(i));
        } 
      }
      // get this as an array so we can sort it, because maps are order-less
      var arrayoptionIndices = optionIndices.toArray();
      sort(arrayoptionIndices);      
      // try to match for each of the identified options
      for (name, idx) in arrayoptionIndices {
        // get a ref to the argument
        var arg = result.getReference(name);
        writeErr("got reference to argument " + name);
        // get the action to match
        var act = actions.getBorrowed(name);
        // try to match values in argstring, get the last value position
        var endPos = act.match(argsList.toArray(), idx, arg);
        writeErr("got end position " + endPos:string);
        k+=1;
        writeErr("k val = " + k:string);
        writeErr("arrayoptionIndices.size is " 
                 + arrayoptionIndices.size:string);
        writeErr("argsList.size = " + argsList.size:string);
        writeErr("zArgsD.high = " + zArgsD.high:string);
        // make sure we don't overrun the array,
        // then check that we don't have extra values
        if k < arrayoptionIndices.size {
          if endPos != arrayoptionIndices[k][1] {
            writeErr("endpos != arrayoptionIndices[k][1] :"+endPos:string+" "
                     + arrayoptionIndices[k][1]:string);
            writeErr("arrayoptionIndices " + arrayoptionIndices:string);
            throw new ArgumentError("\\".join(act.opts) + " has extra values");
          }
        // check that we consumed all the values in the input string
        }else if endPos <= argsList.size-1 {
          throw new ArgumentError("\\".join(act.opts) + " has extra values");
        }
      }
      // make sure all options defined got values if needed
      checkSatisfiedOptions();

      // check for when arguments passed but none defined
      if argsList.size > 0 && this.actions.size == 0 {
        throw new ArgumentError("unrecognized options/values encountered: " +
                                " ".join(argsList.these()));
      }
    }

    proc checkSatisfiedOptions() throws {
      // make sure we satisfied options that need at least 1 value
      for name in this.actions.keys() {
        var act = this.actions.getBorrowed(name);
        var arg = this.result.getReference(name);
        if act.numArgs.low > 0 && !arg.present {
          throw new ArgumentError("\\".join(act.opts) + " not enough values");
        }        
      }
    }

    // define a new string option with fixed number of values expected
    proc addOption(name:string,
                   opts:[]string,
                   numArgs:int) throws {
      return addOption(name=name,
                      opts=opts,
                      numArgs=numArgs..numArgs);
    }

    // define a new string option with range of values expected
    proc addOption(name:string,
                   opts:[?optsD]string,
                   numArgs:range) throws {
      
      for i in optsD {
        if !opts[i].startsWith("-") {
          throw new ArgumentError("Use '-' or '--' to indicate opt flags. " +
                                  "Positional arguments not yet supported");
        }
      }
      
      var action = new owned Action(name=name, 
                                    numOpts=opts.size,
                                    opts=opts,
                                    numArgs=numArgs);
      // collect all the option strings
      for opt in opts do options.add(opt, name);
      // store the action
      actions.add(name, action);
      //create, add, and return the shared argument
      var arg = new shared Argument();
      this.result.add(name, arg);
      return arg;
      }
  }
  
  proc writeErr(msg:string) {
    if DEBUG then try! {stderr.writeln(msg);}
  }
}