;(function(){
  //==================================================
  // file: modjewel-require.js
  //==================================================
  var require
  var modjewel
  (function(){
   var PROGRAM = "modjewel"
   var VERSION = "1.1.0"
   if (modjewel) {
   log("modjewel global variable already defined")
   return
   }
   var OriginalRequire = require
   var NoConflict      = false
   var ModuleStore
   var ModulePreloadStore
   var MainModule
   var WarnOnRecursiveRequire = false
   function get_require(currentModule) {
   var result = function require(moduleId) {
   if (moduleId.match(/^\.{1,2}\//)) {
                      moduleId = normalize(currentModule, moduleId)
                      }
                      if (hop(ModuleStore, moduleId)) {
                      var module = ModuleStore[moduleId]
                      if (module.__isLoading) {
                      if (WarnOnRecursiveRequire) {
                      var fromModule = currentModule ? currentModule.id : "<root>" 
                      console.log("module '" + moduleId + "' recursively require()d from '" + fromModule + "', problem?")
                      }
                      }
                      currentModule.moduleIdsRequired.push(moduleId)
                      return module.exports
                      }
                      if (!hop(ModulePreloadStore, moduleId)) {
                      var fromModule = currentModule ? currentModule.id : "<root>" 
                      error("module '" + moduleId + "' not found from '" + fromModule + "', must be preloaded")
                      }
                      var moduleDefFunction = ModulePreloadStore[moduleId]
                      var module = create_module(moduleId)
                      var newRequire = get_require(module) 
                      ModuleStore[moduleId] = module
                      module.__isLoading = true
                      try {
                      currentModule.moduleIdsRequired.push(moduleId)
                      moduleDefFunction.call(null, newRequire, module.exports, module)
                      }
                      finally {
                      module.__isLoading = false
                      }
                      return module.exports
                      }
                      result.define         = require_define
                      result.implementation = PROGRAM
                      result.version        = VERSION
                      return result
                      }
                      function hop(object, name) {
                      return Object.prototype.hasOwnProperty.call(object, name)
                      }
                      function create_module(id) {
                      return { 
                      id:                id, 
                      uri:               id, 
                      exports:           {},
                      moduleIdsRequired: []
                      }
                      }
                      function require_reset() {
                      ModuleStore        = {}
                      ModulePreloadStore = {}
                      MainModule         = create_module(null)
                      require = get_require(MainModule)
                      require.define({modjewel: modjewel_module})
                      modjewel = require("modjewel")
                      }
                      function require_define(moduleSet) {
                      for (var moduleName in moduleSet) {
                      if (!hop(moduleSet, moduleName)) continue
                      if (moduleName.match(/^\./)) {
                      console.log("require.define(): moduleName in moduleSet must not start with '.': '" + moduleName + "'")
                      return
                      }
                      var moduleDefFunction = moduleSet[moduleName]
                      if (typeof moduleDefFunction != "function") {
                      console.log("require.define(): expecting a function as value of '" + moduleName + "' in moduleSet")
                      return
                      }
                      if (hop(ModulePreloadStore, moduleName)) {
                      console.log("require.define(): module '" + moduleName + "' has already been preloaded")
                      return
                      }
                      ModulePreloadStore[moduleName] = moduleDefFunction
                      }
                      }
                      function getModulePath(module) {
                      if (!module || !module.id) return ""
                      var parts = module.id.split("/")
                      return parts.slice(0, parts.length-1).join("/")
                      }
                      function normalize(module, file) {
                      var modulePath = getModulePath(module)
                      var dirParts   = ("" == modulePath) ? [] : modulePath.split("/")
                      var fileParts  = file.split("/")
                      for (var i=0; i<fileParts.length; i++) {
                      var filePart = fileParts[i]
                      if (filePart == ".") {
                      }
                      else if (filePart == "..") {
                      if (dirParts.length > 0) {
                      dirParts.pop()
                      }
                      else {
                      }
                      }
                      else {
                      dirParts.push(filePart)
                      }
                      }
                      return dirParts.join("/")
                      }
                      function error(message) {
                      throw new Error(PROGRAM + ": " + message)
                      }
                      function modjewel_getLoadedModuleIds() {
                      var result = []
                      for (moduleId in ModuleStore) {
                      result.push(moduleId)
                      }
                      return result
                      }
                      function modjewel_getPreloadedModuleIds() {
                      var result = []
                      for (moduleId in ModulePreloadStore) {
                      result.push(moduleId)
                      }
                      return result
                      }
                      function modjewel_getModule(moduleId) {
                      if (null == moduleId) return MainModule
                      return ModuleStore[moduleId]
                      }
                      function modjewel_getModuleIdsRequired(moduleId) {
                      var module = modjewel_getModule(moduleId)
                      if (null == module) return null
                      return module.moduleIdsRequired.slice()
                      }
                      function modjewel_warnOnRecursiveRequire(value) {
                      if (arguments.length == 0) return WarnOnRecursiveRequire
                      WarnOnRecursiveRequire = !!value
                      }
                      function modjewel_noConflict() {
                      NoConflict = true
                      require = OriginalRequire
                      }
                      function modjewel_module(require, exports, module) {
                      exports.VERSION                = VERSION
                      exports.require                = require
                      exports.define                 = require.define
                      exports.getLoadedModuleIds     = modjewel_getLoadedModuleIds
                      exports.getPreloadedModuleIds  = modjewel_getPreloadedModuleIds
                      exports.getModule              = modjewel_getModule
                      exports.getModuleIdsRequired   = modjewel_getModuleIdsRequired
                      exports.warnOnRecursiveRequire = modjewel_warnOnRecursiveRequire
                      exports.noConflict             = modjewel_noConflict
                      }
                      function log(message) {
                      console.log("modjewel: " + message)
                      }
                      require_reset()
                      })();
       
       ;
       
       //==================================================
       // file: json2.js
       //==================================================
       var JSON;
       if (!JSON) {
       JSON = {};
       }
       (function () {
        "use strict";
        function f(n) {
        return n < 10 ? '0' + n : n;
        }
        if (typeof Date.prototype.toJSON !== 'function') {
        Date.prototype.toJSON = function (key) {
        return isFinite(this.valueOf()) ?
        this.getUTCFullYear()     + '-' +
        f(this.getUTCMonth() + 1) + '-' +
        f(this.getUTCDate())      + 'T' +
        f(this.getUTCHours())     + ':' +
        f(this.getUTCMinutes())   + ':' +
        f(this.getUTCSeconds())   + 'Z' : null;
        };
        String.prototype.toJSON      =
        Number.prototype.toJSON  =
        Boolean.prototype.toJSON = function (key) {
        return this.valueOf();
        };
        }
        var cx = /[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,
        escapable = /[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,
                      gap,
                      indent,
                      meta = {    
                      '\b': '\\b',
                      '\t': '\\t',
                      '\n': '\\n',
                      '\f': '\\f',
                      '\r': '\\r',
                      '"' : '\\"',
                      '\\': '\\\\'
                      },
                      rep;
                      function quote(string) {
                      escapable.lastIndex = 0;
                      return escapable.test(string) ? '"' + string.replace(escapable, function (a) {
                                                                           var c = meta[a];
                                                                           return typeof c === 'string' ? c :
                                                                           '\\u' + ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
                                                                           }) + '"' : '"' + string + '"';
                      }
                      function str(key, holder) {
                      var i,          
                      k,          
                      v,          
                      length,
                      mind = gap,
                      partial,
                      value = holder[key];
                      if (value && typeof value === 'object' &&
                          typeof value.toJSON === 'function') {
                      value = value.toJSON(key);
                      }
                      if (typeof rep === 'function') {
                      value = rep.call(holder, key, value);
                      }
                      switch (typeof value) {
                      case 'string':
                      return quote(value);
                      case 'number':
                      return isFinite(value) ? String(value) : 'null';
                      case 'boolean':
                      case 'null':
                      return String(value);
                      case 'object':
                      if (!value) {
                      return 'null';
                      }
                      gap += indent;
                      partial = [];
                      if (Object.prototype.toString.apply(value) === '[object Array]') {
                      length = value.length;
                      for (i = 0; i < length; i += 1) {
                      partial[i] = str(i, value) || 'null';
                      }
                      v = partial.length === 0 ? '[]' : gap ?
                      '[\n' + gap + partial.join(',\n' + gap) + '\n' + mind + ']' :
                      '[' + partial.join(',') + ']';
                      gap = mind;
                      return v;
                      }
                      if (rep && typeof rep === 'object') {
                      length = rep.length;
                      for (i = 0; i < length; i += 1) {
                      if (typeof rep[i] === 'string') {
                      k = rep[i];
                      v = str(k, value);
                      if (v) {
                      partial.push(quote(k) + (gap ? ': ' : ':') + v);
                      }
                      }
                      }
                      } else {
                      for (k in value) {
                      if (Object.prototype.hasOwnProperty.call(value, k)) {
                      v = str(k, value);
                      if (v) {
                      partial.push(quote(k) + (gap ? ': ' : ':') + v);
                      }
                      }
                      }
                      }
                      v = partial.length === 0 ? '{}' : gap ?
                      '{\n' + gap + partial.join(',\n' + gap) + '\n' + mind + '}' :
                      '{' + partial.join(',') + '}';
                      gap = mind;
                      return v;
                      }
                      }
                      if (typeof JSON.stringify !== 'function') {
                      JSON.stringify = function (value, replacer, space) {
                      var i;
                      gap = '';
                      indent = '';
                      if (typeof space === 'number') {
                      for (i = 0; i < space; i += 1) {
                      indent += ' ';
                      }
                      } else if (typeof space === 'string') {
                      indent = space;
                      }
                      rep = replacer;
                      if (replacer && typeof replacer !== 'function' &&
                          (typeof replacer !== 'object' ||
                           typeof replacer.length !== 'number')) {
                      throw new Error('JSON.stringify');
                      }
                      return str('', {'': value});
                      };
                      }
                      if (typeof JSON.parse !== 'function') {
                      JSON.parse = function (text, reviver) {
                      var j;
                      function walk(holder, key) {
                      var k, v, value = holder[key];
                      if (value && typeof value === 'object') {
                      for (k in value) {
                      if (Object.prototype.hasOwnProperty.call(value, k)) {
                      v = walk(value, k);
                      if (v !== undefined) {
                      value[k] = v;
                      } else {
                      delete value[k];
                      }
                      }
                      }
                      }
                      return reviver.call(holder, key, value);
                      }
                      text = String(text);
                      cx.lastIndex = 0;
                      if (cx.test(text)) {
                      text = text.replace(cx, function (a) {
                                          return '\\u' +
                                          ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
                                          });
                      }
                      if (/^[\],:{}\s]*$/
                          .test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@')
                                                    .replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']')
                                                             .replace(/(?:^|:|,)(?:\s*\[)+/g, ''))) {
                                                                                        j = eval('(' + text + ')');
                                                                                        return typeof reviver === 'function' ?
                                                                                        walk({'': j}, '') : j;
                                                                                        }
                                                                                        throw new SyntaxError('JSON.parse');
                                                                                        };
                                                                                        }
                                                                                        }());
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: scooj.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"scooj": function(require, exports, module) { 
                                                                                                        if (typeof exports == "undefined") {
                                                                                                        throw new Error("exports undefined; not running in a CommonJS environment?")
                                                                                                        }
                                                                                                        var scooj = {}
                                                                                                        scooj.version         = "1.1.0"
                                                                                                        scooj._global         = getGlobalObject(this)
                                                                                                        scooj._classes        = {}
                                                                                                        scooj._currentClass   = {}
                                                                                                        addExport(function defClass(module, superclass, func) {
                                                                                                                  if (null == module) {
                                                                                                                  throw new Error("must pass a module as the first parameter")
                                                                                                                  }
                                                                                                                  if (null == module.id) {
                                                                                                                  throw new Error("module parameter has no id")
                                                                                                                  }
                                                                                                                  if (null == func) {
                                                                                                                  func = superclass
                                                                                                                  superclass = null
                                                                                                                  }
                                                                                                                  var funcName = ensureNamedFunction(func)
                                                                                                                  var fullClassName = module.id + "::" + funcName
                                                                                                                  if (scooj._classes.hasOwnProperty(fullClassName)) {
                                                                                                                  throw new Error("class is already defined: " + fullClassName)
                                                                                                                  }
                                                                                                                  func.signature = module.id + "." + funcName + "()"
                                                                                                                  func._scooj = {}
                                                                                                                  func._scooj.isClass       = true
                                                                                                                  func._scooj.owningClass   = func
                                                                                                                  func._scooj.superclass    = superclass
                                                                                                                  func._scooj.subclasses    = {}
                                                                                                                  func._scooj.name          = funcName
                                                                                                                  func._scooj.moduleId      = module.id
                                                                                                                  func._scooj.fullClassName = fullClassName
                                                                                                                  func._scooj.mixins        = []
                                                                                                                  func._scooj.methods       = {}
                                                                                                                  func._scooj.staticMethods = {}
                                                                                                                  func._scooj.getters       = {}
                                                                                                                  func._scooj.setters       = {}
                                                                                                                  func._scooj.staticGetters = {}
                                                                                                                  func._scooj.staticSetters = {}
                                                                                                                  scooj._classes[fullClassName] = func
                                                                                                                  scooj._currentClass[module.id] = func
                                                                                                                  if (superclass) {
                                                                                                                  var T = function() {}
                                                                                                                  T.prototype = superclass.prototype
                                                                                                                  func.prototype = new T()
                                                                                                                  func.prototype.constructor = func
                                                                                                                  }
                                                                                                                  func.$super = getSuperMethod(func)
                                                                                                                  if (typeof(module.exports.getClass) != "function") {
                                                                                                                  func.signature = module.id + "()"
                                                                                                                  module.exports.getClass = function getClass() {
                                                                                                                  return func
                                                                                                                  }
                                                                                                                  }
                                                                                                                  return func
                                                                                                                  })
                                                                                                        addExport(function useMixin(module, mixinObject) {
                                                                                                                  var klass = ensureClassCurrentlyDefined(module)
                                                                                                                  klass._scooj.mixins.push(mixinObject)
                                                                                                                  var methodBag = mixinObject
                                                                                                                  if (methodBag._scooj) {
                                                                                                                  methodBag = methodBag._scooj.methods
                                                                                                                  }
                                                                                                                  for (var funcName in methodBag) {
                                                                                                                  var func = methodBag[funcName]
                                                                                                                  if (typeof func != "function") continue
                                                                                                                  if (!func.name) {
                                                                                                                  if (!func.displayName) {
                                                                                                                  func.displayName = funcName
                                                                                                                  }
                                                                                                                  }
                                                                                                                  var funcName2 = func.name || func.displayName
                                                                                                                  if (funcName != funcName2) {
                                                                                                                  throw new Error("function name doesn't match key it was stored under: " + valName)
                                                                                                                  }
                                                                                                                  this.defMethod(module, func)
                                                                                                                  }
                                                                                                                  })
                                                                                                        addExport(function defMethod(module, func)       {return addMethod(module, func, false, false, false)})
                                                                                                        addExport(function defStaticMethod(module, func) {return addMethod(module, func, true,  false, false)})
                                                                                                        addExport(function defGetter(module, func)       {return addMethod(module, func, false, true,  false)})
                                                                                                        addExport(function defSetter(module, func)       {return addMethod(module, func, false, false, true)})
                                                                                                        addExport(function defStaticGetter(module, func) {return addMethod(module, func, true,  true,  false)})
                                                                                                        addExport(function defStaticSetter(module, func) {return addMethod(module, func, true,  false, true)})
                                                                                                        addExport(function defSuper(module) {
                                                                                                                  var klass = ensureClassCurrentlyDefined(module)
                                                                                                                  return getSuperMethod(klass)
                                                                                                                  })
                                                                                                        var globalsInstalled = false
                                                                                                        addExport(function installGlobals() {
                                                                                                                  var globalNames = [
                                                                                                                                     "defClass",
                                                                                                                                     "defMethod",
                                                                                                                                     "defStaticMethod",
                                                                                                                                     "defGetter",
                                                                                                                                     "defSetter",
                                                                                                                                     "defStaticGetter",
                                                                                                                                     "defStaticSetter",
                                                                                                                                     "defSuper"
                                                                                                                                     ]
                                                                                                                  if (globalsInstalled) return
                                                                                                                  globalsInstalled = true
                                                                                                                  if (!scooj._global) {
                                                                                                                  throw new Error("unable to determine global object")
                                                                                                                  }
                                                                                                                  for (var i=0; i<globalNames.length; i++) {
                                                                                                                  var name = globalNames[i]
                                                                                                                  var func = module.exports[name]
                                                                                                                  scooj._global[name] = func
                                                                                                                  }
                                                                                                                  })
                                                                                                        function getSuperMethod(owningClass) {
                                                                                                        var superclass = owningClass._scooj.superclass
                                                                                                        return function $super(thisp, methodName) {
                                                                                                        var superFunc
                                                                                                        if (methodName == null) {
                                                                                                        superFunc = superclass
                                                                                                        }
                                                                                                        else {
                                                                                                        superFunc = superclass.prototype[methodName]
                                                                                                        }
                                                                                                        return superFunc.apply(thisp, Array.prototype.splice.call(arguments, 2))
                                                                                                        }
                                                                                                        }
                                                                                                        function addMethod(module, func, isStatic, isGetter, isSetter) {
                                                                                                        var funcName = ensureNamedFunction(func)
                                                                                                        var klass = ensureClassCurrentlyDefined(module)
                                                                                                        var methodContainer
                                                                                                        if (isGetter) {
                                                                                                        if (isStatic) 
                                                                                                        methodContainer = klass._scooj.staticGetters
                                                                                                        else
                                                                                                        methodContainer = klass._scooj.getters
                                                                                                        }
                                                                                                        else if (isSetter) {
                                                                                                        if (isStatic) 
                                                                                                        methodContainer = klass._scooj.staticSetters
                                                                                                        else
                                                                                                        methodContainer = klass._scooj.setters
                                                                                                        }
                                                                                                        else {
                                                                                                        if (isStatic) 
                                                                                                        methodContainer = klass._scooj.staticMethods
                                                                                                        else
                                                                                                        methodContainer = klass._scooj.methods
                                                                                                        }
                                                                                                        if (methodContainer.hasOwnProperty(func.name)) {
                                                                                                        throw new Error("method is already defined in class: " + klass.name + "." + func.name)
                                                                                                        }
                                                                                                        func._scooj = {}
                                                                                                        func._scooj.owningClass = klass
                                                                                                        func._scooj.isMethod    = true
                                                                                                        func._scooj.isStatic    = isStatic
                                                                                                        func._scooj.isGetter    = isGetter
                                                                                                        func._scooj.isSetter    = isSetter
                                                                                                        func.signature   = module.id + "." + funcName + "()"
                                                                                                        func.displayName = func._scooj.signature
                                                                                                        methodContainer[funcName] = func
                                                                                                        if (isStatic) {
                                                                                                        if (isGetter)
                                                                                                        klass.__defineGetter__(funcName, func)
                                                                                                        else if (isSetter)
                                                                                                        klass.__defineSetter__(funcName, func)
                                                                                                        else 
                                                                                                        klass[funcName] = func
                                                                                                        }
                                                                                                        else {
                                                                                                        if (isGetter)
                                                                                                        klass.prototype.__defineGetter__(funcName, func)
                                                                                                        else if (isSetter)
                                                                                                        klass.prototype.__defineSetter__(funcName, func)
                                                                                                        else 
                                                                                                        klass.prototype[funcName] = func
                                                                                                        }
                                                                                                        return func
                                                                                                        }
                                                                                                        function ensureNamedFunction(func) {
                                                                                                        if (typeof func != "function") throw new Error("expecting a function: " + func)
                                                                                                        if (!func.name) {
                                                                                                        if (!func.displayName) {
                                                                                                        throw new Error("function must not be anonymous: " + func)
                                                                                                        }
                                                                                                        }
                                                                                                        return func.name || func.displayName
                                                                                                        }
                                                                                                        function ensureClassCurrentlyDefined(module) {
                                                                                                        if (!scooj._currentClass[module.id]) throw new Error("no class currently defined")
                                                                                                        return scooj._currentClass[module.id]
                                                                                                        }
                                                                                                        function addExport(func) {
                                                                                                        var funcName = ensureNamedFunction(func)
                                                                                                        exports[funcName] = func
                                                                                                        }
                                                                                                        function getGlobalObject(theGlobal) {
                                                                                                        if (typeof window != "undefined") {
                                                                                                        theGlobal = window
                                                                                                        }
                                                                                                        else if (typeof global != "undefined") {
                                                                                                        theGlobal = global
                                                                                                        }
                                                                                                        return theGlobal
                                                                                                        }
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/common/Ex.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/common/Ex": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var StackTrace = require('./StackTrace').getClass(); if (typeof StackTrace != 'function') throw Error('module ./StackTrace did not export a class');
                                                                                                        var Ex = scooj.defClass(module, function Ex(args, message) {
                                                                                                                                if (!args || !args.callee) {
                                                                                                                                throw Ex(arguments, "first parameter must be an Arguments object") 
                                                                                                                                }
                                                                                                                                StackTrace.dump(args)
                                                                                                                                if (message instanceof Error) {
                                                                                                                                message = "threw error: " + message
                                                                                                                                }
                                                                                                                                return new Error(prefix(args, message))
                                                                                                                                }); function prefix(args, string) {
                                                                                                        if (args.callee.signature)   return args.callee.signature +   ": " + string
                                                                                                        if (args.callee.displayName) return args.callee.displayName + ": " + string
                                                                                                        if (args.callee.name)        return args.callee.name +        ": " + string
                                                                                                        return "<anonymous>" +                                        ": " + string
                                                                                                        }; 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/common/StackTrace.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/common/StackTrace": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var StackTrace = scooj.defClass(module, function StackTrace(args) {
                                                                                                                                                                       if (!args || !args.callee) {
                                                                                                                                                                       throw Error("first parameter to " + arguments.callee.signature + " must be an Arguments object") 
                                                                                                                                                                       }
                                                                                                                                                                       this.trace = getTrace(args)
                                                                                                                                                                       }); scooj.defStaticMethod(module, function dump(args) {
                                                                                                                                                                                                 args = args || arguments
                                                                                                                                                                                                 var stackTrace = new StackTrace(args)
                                                                                                                                                                                                 stackTrace.dump()
                                                                                                                                                                                                 }); scooj.defMethod(module, function dump() {
                                                                                                                                                                                                                     console.log("StackTrace:")
                                                                                                                                                                                                                     this.trace.forEach(function(frame) {
                                                                                                                                                                                                                                        console.log("    " + frame)
                                                                                                                                                                                                                                        })
                                                                                                                                                                                                                     }); function getTrace(args) {
                                                                                                        var result = []
                                                                                                        var visitedFuncs = []
                                                                                                        var func = args.callee
                                                                                                        while (func) {
                                                                                                        if      (func.signature)   result.push(func.signature)
                                                                                                        else if (func.displayName) result.push(func.displayName)
                                                                                                        else if (func.name)        result.push(func.name)
                                                                                                        else result.push("<anonymous>")
                                                                                                        if (-1 != visitedFuncs.indexOf(func)) {
                                                                                                        result.push("... recursion")
                                                                                                        return result
                                                                                                        }
                                                                                                        visitedFuncs.push(func)
                                                                                                        func = func.caller
                                                                                                        }
                                                                                                        return result
                                                                                                        }; 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/common/Weinre.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/common/Weinre": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Ex = require('./Ex').getClass(); if (typeof Ex != 'function') throw Error('module ./Ex did not export a class');
                                                                                                        var IDLTools = require('./IDLTools').getClass(); if (typeof IDLTools != 'function') throw Error('module ./IDLTools did not export a class');
                                                                                                        var StackTrace = require('./StackTrace').getClass(); if (typeof StackTrace != 'function') throw Error('module ./StackTrace did not export a class');
                                                                                                        var Weinre = scooj.defClass(module, function Weinre() {
                                                                                                                                    throw new Ex(arguments, "this class is not intended to be instantiated")
                                                                                                                                    }); 
                                                                                                        var _notImplemented     = {}
                                                                                                        var _showNotImplemented = false
                                                                                                        var CSSProperties       = []
                                                                                                        var logger              = null
                                                                                                        scooj.defStaticMethod(module, function addIDLs(idls) {
                                                                                                                              IDLTools.addIDLs(idls)
                                                                                                                              }); scooj.defStaticMethod(module, function addCSSProperties(cssProperties) {
                                                                                                                                                        CSSProperties = cssProperties
                                                                                                                                                        }); scooj.defStaticMethod(module, function getCSSProperties() {
                                                                                                                                                                                  return CSSProperties
                                                                                                                                                                                  }); scooj.defStaticMethod(module, function deprecated() {
                                                                                                                                                                                                            StackTrace.dump(arguments)
                                                                                                                                                                                                            }); scooj.defStaticMethod(module, function notImplemented(thing) {
                                                                                                                                                                                                                                      if (_notImplemented[thing]) return
                                                                                                                                                                                                                                      _notImplemented[thing] = true
                                                                                                                                                                                                                                      if (!_showNotImplemented) return
                                                                                                                                                                                                                                      Weinre.logWarning(thing + " not implemented")
                                                                                                                                                                                                                                      }); scooj.defStaticMethod(module, function showNotImplemented() {
                                                                                                                                                                                                                                                                _showNotImplemented = true
                                                                                                                                                                                                                                                                for (var key in _notImplemented) {
                                                                                                                                                                                                                                                                Weinre.logWarning(key + " not implemented")
                                                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                                                }); scooj.defStaticMethod(module, function logError(message) {
                                                                                                                                                                                                                                                                                          getLogger().logError(message)
                                                                                                                                                                                                                                                                                          }); scooj.defStaticMethod(module, function logWarning(message) {
                                                                                                                                                                                                                                                                                                                    getLogger().logWarning(message)
                                                                                                                                                                                                                                                                                                                    }); scooj.defStaticMethod(module, function logInfo(message) {
                                                                                                                                                                                                                                                                                                                                              getLogger().logInfo(message)
                                                                                                                                                                                                                                                                                                                                              }); scooj.defStaticMethod(module, function logDebug(message) {
                                                                                                                                                                                                                                                                                                                                                                        getLogger().logDebug(message)
                                                                                                                                                                                                                                                                                                                                                                        }); function getLogger() {
                                                                                                        if (logger) return logger
                                                                                                        if      (Weinre.client) logger = Weinre.WeinreClientCommands
                                                                                                        else if (Weinre.target) logger = Weinre.WeinreTargetCommands
                                                                                                        return logger
                                                                                                        }; 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/common/IDLTools.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/common/IDLTools": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Ex = require('./Ex').getClass(); if (typeof Ex != 'function') throw Error('module ./Ex did not export a class');
                                                                                                        var Callback = require('./Callback').getClass(); if (typeof Callback != 'function') throw Error('module ./Callback did not export a class');
                                                                                                        var IDLTools = scooj.defClass(module, function IDLTools() {
                                                                                                                                      throw new Ex(arguments, "this class is not intended to be instantiated")
                                                                                                                                      }); 
                                                                                                        var IDLs = {}
                                                                                                        IDLTools._idls = IDLs
                                                                                                        scooj.defStaticMethod(module, function addIDLs(idls) {
                                                                                                                              idls.forEach(function(idl){
                                                                                                                                           idl.interfaces.forEach(function(intf){
                                                                                                                                                                  IDLs[intf.name] = intf
                                                                                                                                                                  intf.module = idl.name
                                                                                                                                                                  })
                                                                                                                                           })
                                                                                                                              }); scooj.defStaticMethod(module, function getIDL(name) {
                                                                                                                                                        return IDLs[name]
                                                                                                                                                        }); scooj.defStaticMethod(module, function getIDLsMatching(regex) {
                                                                                                                                                                                  var results = []
                                                                                                                                                                                  for (var intfName in IDLs) {
                                                                                                                                                                                  var intf = IDLs[intfName]
                                                                                                                                                                                  if (intfName.match(regex)) {
                                                                                                                                                                                  results.push(intf)
                                                                                                                                                                                  }
                                                                                                                                                                                  }
                                                                                                                                                                                  return results
                                                                                                                                                                                  }); scooj.defStaticMethod(module, function validateAgainstIDL(klass, interfaceName) {
                                                                                                                                                                                                            var intf = IDLTools.getIDL(interfaceName)
                                                                                                                                                                                                            var messagePrefix = "IDL validation for " + interfaceName + ": "
                                                                                                                                                                                                            if (null == intf) throw new Ex(arguments, messagePrefix + "idl not found: '" + interfaceName + "'")
                                                                                                                                                                                                            var errors = []
                                                                                                                                                                                                            intf.methods.forEach(function(intfMethod) {
                                                                                                                                                                                                                                 var classMethod  = klass.prototype[intfMethod.name]
                                                                                                                                                                                                                                 var printName    = klass.name + "::" + intfMethod.name
                                                                                                                                                                                                                                 if (null == classMethod) {
                                                                                                                                                                                                                                 errors.push(messagePrefix + "method not implemented: '" + printName + "'")
                                                                                                                                                                                                                                 return
                                                                                                                                                                                                                                 }
                                                                                                                                                                                                                                 if (classMethod.length != intfMethod.parameters.length) {
                                                                                                                                                                                                                                 if (classMethod.length != intfMethod.parameters.length + 1) {
                                                                                                                                                                                                                                 errors.push(messagePrefix + "wrong number of parameters: '" + printName + "'")
                                                                                                                                                                                                                                 return
                                                                                                                                                                                                                                 }
                                                                                                                                                                                                                                 }
                                                                                                                                                                                                                                 })
                                                                                                                                                                                                            for (var propertyName in klass.prototype) {
                                                                                                                                                                                                            if (klass.prototype.hasOwnProperty(propertyName)) continue
                                                                                                                                                                                                            if (propertyName.match(/^_.*/)) continue
                                                                                                                                                                                                            var printName = klass.name + "::" + propertyName
                                                                                                                                                                                                            if (!intf.methods[propertyName]) {
                                                                                                                                                                                                            errors.push(messagePrefix + "method should not be implemented: '" + printName + "'")
                                                                                                                                                                                                            continue
                                                                                                                                                                                                            }
                                                                                                                                                                                                            }
                                                                                                                                                                                                            if (!errors.length) return
                                                                                                                                                                                                            errors.forEach(function(error){
                                                                                                                                                                                                                           require("./Weinre").getClass().logError(error)
                                                                                                                                                                                                                           })
                                                                                                                                                                                                            }); scooj.defStaticMethod(module, function buildProxyForIDL(proxyObject, interfaceName) {
                                                                                                                                                                                                                                      var intf = IDLTools.getIDL(interfaceName)
                                                                                                                                                                                                                                      var messagePrefix = "building proxy for IDL " + interfaceName + ": "
                                                                                                                                                                                                                                      if (null == intf) throw new Ex(arguments, messagePrefix + "idl not found: '" + interfaceName + "'")
                                                                                                                                                                                                                                      intf.methods.forEach(function(intfMethod) {
                                                                                                                                                                                                                                                           proxyObject[intfMethod.name] = getProxyMethod(intf, intfMethod)
                                                                                                                                                                                                                                                           })
                                                                                                                                                                                                                                      }); function getProxyMethod(intf, method) {
                                                                                                        var result = function proxyMethod() {
                                                                                                        var callbackId = null
                                                                                                        var args       = [].slice.call(arguments)
                                                                                                        if (args.length > 0) {
                                                                                                        if (typeof args[args.length-1] == "function") {
                                                                                                        callbackId   = Callback.register(args[args.length-1])
                                                                                                        args         = args.slice(0, args.length-1)
                                                                                                        }
                                                                                                        }
                                                                                                        while (args.length < method.parameters.length) {
                                                                                                        args.push(null)
                                                                                                        }
                                                                                                        args.push(callbackId)
                                                                                                        this.__invoke(intf.name, method.name, args)
                                                                                                        }
                                                                                                        result.displayName = intf.name + "__" + method.name
                                                                                                        return result
                                                                                                        }; 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/common/MessageDispatcher.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/common/MessageDispatcher": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Weinre = require('./Weinre').getClass(); if (typeof Weinre != 'function') throw Error('module ./Weinre did not export a class');
                                                                                                        var WebSocketXhr = require('./WebSocketXhr').getClass(); if (typeof WebSocketXhr != 'function') throw Error('module ./WebSocketXhr did not export a class');
                                                                                                        var IDLTools = require('./IDLTools').getClass(); if (typeof IDLTools != 'function') throw Error('module ./IDLTools did not export a class');
                                                                                                        var Binding = require('./Binding').getClass(); if (typeof Binding != 'function') throw Error('module ./Binding did not export a class');
                                                                                                        var Ex = require('./Ex').getClass(); if (typeof Ex != 'function') throw Error('module ./Ex did not export a class');
                                                                                                        var Callback = require('./Callback').getClass(); if (typeof Callback != 'function') throw Error('module ./Callback did not export a class');
                                                                                                        var MessageDispatcher = scooj.defClass(module, function MessageDispatcher(url, id) {
                                                                                                                                               if (!id) {
                                                                                                                                               id = "anonymous"
                                                                                                                                               }
                                                                                                                                               this._url        = url
                                                                                                                                               this._id         = id
                                                                                                                                               this.error       = null
                                                                                                                                               this._opening    = false
                                                                                                                                               this._opened     = false
                                                                                                                                               this._closed     = false
                                                                                                                                               this._interfaces = {}
                                                                                                                                               this._open()
                                                                                                                                               }); 
                                                                                                        var Verbose = false
                                                                                                        var InspectorBackend
                                                                                                        scooj.defStaticMethod(module, function setInspectorBackend(inspectorBackend) {
                                                                                                                              InspectorBackend = inspectorBackend
                                                                                                                              }); scooj.defStaticMethod(module, function verbose(value) {
                                                                                                                                                        if (arguments.length >= 1) {
                                                                                                                                                        Verbose = !!value
                                                                                                                                                        }
                                                                                                                                                        return Verbose
                                                                                                                                                        }); scooj.defMethod(module, function _open() {
                                                                                                                                                                            if (this._opened || this._opening) return
                                                                                                                                                                            if (this._closed) throw new Ex(arguments, "socket has already been closed")
                                                                                                                                                                            this._opening = true 
                                                                                                                                                                            this._socket = new WebSocketXhr(this._url, this._id)
                                                                                                                                                                            this._socket.addEventListener("open",    Binding(this, "_handleOpen"))
                                                                                                                                                                            this._socket.addEventListener("error",   Binding(this, "_handleError"))
                                                                                                                                                                            this._socket.addEventListener("message", Binding(this, "_handleMessage"))
                                                                                                                                                                            this._socket.addEventListener("close",   Binding(this, "_handleClose"))
                                                                                                                                                                            }); scooj.defMethod(module, function close() {
                                                                                                                                                                                                if (this._closed) return
                                                                                                                                                                                                this._opened = false
                                                                                                                                                                                                this._closed = true
                                                                                                                                                                                                this._socket.close()
                                                                                                                                                                                                }); scooj.defMethod(module, function send(data) {
                                                                                                                                                                                                                    this._socket.send(data)
                                                                                                                                                                                                                    }); scooj.defMethod(module, function getWebSocket() {
                                                                                                                                                                                                                                        return this._socket
                                                                                                                                                                                                                                        }); scooj.defMethod(module, function registerInterface(intfName, intf, validate) {
                                                                                                                                                                                                                                                            if (validate) IDLTools.validateAgainstIDL(intf.constructor, intfName)
                                                                                                                                                                                                                                                            if (this._interfaces[intfName]) throw new Ex(arguments, "interface " + intfName + " has already been registered")
                                                                                                                                                                                                                                                            this._interfaces[intfName] = intf
                                                                                                                                                                                                                                                            }); scooj.defMethod(module, function createProxy(intfName) {
                                                                                                                                                                                                                                                                                var proxy = {}
                                                                                                                                                                                                                                                                                IDLTools.buildProxyForIDL(proxy, intfName)
                                                                                                                                                                                                                                                                                var self = this
                                                                                                                                                                                                                                                                                proxy.__invoke = function __invoke(intfName, methodName, args) {
                                                                                                                                                                                                                                                                                self._sendMethodInvocation(intfName, methodName, args)
                                                                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                                                                return proxy
                                                                                                                                                                                                                                                                                }); scooj.defMethod(module, function _sendMethodInvocation(intfName, methodName, args) {
                                                                                                                                                                                                                                                                                                    if (typeof intfName   != "string") throw new Ex(arguments, "expecting intf parameter to be a string")
                                                                                                                                                                                                                                                                                                    if (typeof methodName != "string") throw new Ex(arguments, "expecting method parameter to be a string")
                                                                                                                                                                                                                                                                                                    var data = {
                                                                                                                                                                                                                                                                                                    "interface": intfName,
                                                                                                                                                                                                                                                                                                    "method":    methodName,
                                                                                                                                                                                                                                                                                                    "args":      args
                                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                                    data = JSON.stringify(data)
                                                                                                                                                                                                                                                                                                    this._socket.send(data)
                                                                                                                                                                                                                                                                                                    if (Verbose) {
                                                                                                                                                                                                                                                                                                    Weinre.logDebug(this.constructor.name + "[" + this._url + "]: send " + intfName + "." + methodName + "(" + JSON.stringify(args) + ")")
                                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                                    }); scooj.defMethod(module, function getState() {
                                                                                                                                                                                                                                                                                                                        if (this._opening) return "opening"
                                                                                                                                                                                                                                                                                                                        if (this._opened)  return "opened"
                                                                                                                                                                                                                                                                                                                        if (this._closed)  return "closed"
                                                                                                                                                                                                                                                                                                                        return "unknown"
                                                                                                                                                                                                                                                                                                                        }); scooj.defMethod(module, function isOpen() {
                                                                                                                                                                                                                                                                                                                                            return this._opened == true
                                                                                                                                                                                                                                                                                                                                            }); scooj.defMethod(module, function _handleOpen(event) {
                                                                                                                                                                                                                                                                                                                                                                this._opening = false
                                                                                                                                                                                                                                                                                                                                                                this._opened  = true
                                                                                                                                                                                                                                                                                                                                                                this.channel  = event.channel
                                                                                                                                                                                                                                                                                                                                                                Callback.setConnectorChannel(this.channel)
                                                                                                                                                                                                                                                                                                                                                                if (Verbose) {
                                                                                                                                                                                                                                                                                                                                                                Weinre.logDebug(this.constructor.name + "[" + this._url + "]: opened")
                                                                                                                                                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                                                                                                                                                }); scooj.defMethod(module, function _handleError(message) {
                                                                                                                                                                                                                                                                                                                                                                                    this.error = message
                                                                                                                                                                                                                                                                                                                                                                                    this.close()
                                                                                                                                                                                                                                                                                                                                                                                    if (Verbose) {
                                                                                                                                                                                                                                                                                                                                                                                    Weinre.logDebug(this.constructor.name + "[" + this._url + "]: error: " + message)
                                                                                                                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                                                                                                                    }); scooj.defMethod(module, function _handleMessage(message) {
                                                                                                                                                                                                                                                                                                                                                                                                        var data
                                                                                                                                                                                                                                                                                                                                                                                                        try {
                                                                                                                                                                                                                                                                                                                                                                                                        data = JSON.parse(message.data)
                                                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                                                                                                        catch (e) {
                                                                                                                                                                                                                                                                                                                                                                                                        throw new Ex(arguments, "invalid JSON data received: " + e + ": '" + message.data + "'")
                                                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                                                                                                        var intfName   = data["interface"]
                                                                                                                                                                                                                                                                                                                                                                                                        var methodName = data.method
                                                                                                                                                                                                                                                                                                                                                                                                        var args       = data.args
                                                                                                                                                                                                                                                                                                                                                                                                        var methodSignature = intfName + "." + methodName + "()"
                                                                                                                                                                                                                                                                                                                                                                                                        var intf = this._interfaces.hasOwnProperty(intfName) && this._interfaces[intfName]
                                                                                                                                                                                                                                                                                                                                                                                                        if (!intf && InspectorBackend && intfName.match(/.*Notify/)) {
                                                                                                                                                                                                                                                                                                                                                                                                        intf = InspectorBackend.getRegisteredDomainDispatcher(intfName.substr(0,intfName.length-6))
                                                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                                                                                                        if (!intf) {
                                                                                                                                                                                                                                                                                                                                                                                                        Weinre.logWarning("weinre: request for non-registered interface:" + methodSignature)
                                                                                                                                                                                                                                                                                                                                                                                                        return
                                                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                                                                                                        methodSignature = intf.constructor.name + "." + methodName + "()"
                                                                                                                                                                                                                                                                                                                                                                                                        var method = intf[methodName]
                                                                                                                                                                                                                                                                                                                                                                                                        if (typeof method != "function") {
                                                                                                                                                                                                                                                                                                                                                                                                        Weinre.notImplemented(methodSignature)
                                                                                                                                                                                                                                                                                                                                                                                                        return
                                                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                                                                                                        try {
                                                                                                                                                                                                                                                                                                                                                                                                        method.apply(intf, args)
                                                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                                                                                                        catch (e) {
                                                                                                                                                                                                                                                                                                                                                                                                        Weinre.logError("weinre: invocation exception on " + methodSignature + ": " + e)
                                                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                                                                                                        if (Verbose) {
                                                                                                                                                                                                                                                                                                                                                                                                        Weinre.logDebug(this.constructor.name + "[" + this._url + "]: recv " + intfName + "." + methodName + "(" + JSON.stringify(args) + ")")
                                                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                                                                                                        }); scooj.defMethod(module, function _handleClose() {
                                                                                                                                                                                                                                                                                                                                                                                                                            this._reallyClosed = true
                                                                                                                                                                                                                                                                                                                                                                                                                            if (Verbose) {
                                                                                                                                                                                                                                                                                                                                                                                                                            Weinre.logDebug(this.constructor.name + "[" + this._url + "]: closed")
                                                                                                                                                                                                                                                                                                                                                                                                                            }
                                                                                                                                                                                                                                                                                                                                                                                                                            }); 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/common/WebSocketXhr.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/common/WebSocketXhr": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Ex = require('./Ex').getClass(); if (typeof Ex != 'function') throw Error('module ./Ex did not export a class');
                                                                                                        var Weinre = require('./Weinre').getClass(); if (typeof Weinre != 'function') throw Error('module ./Weinre did not export a class');
                                                                                                        var EventListeners = require('./EventListeners').getClass(); if (typeof EventListeners != 'function') throw Error('module ./EventListeners did not export a class');
                                                                                                        var Native = require('./Native').getClass(); if (typeof Native != 'function') throw Error('module ./Native did not export a class');
                                                                                                        var WebSocketXhr = scooj.defClass(module, function WebSocketXhr(url, id) {
                                                                                                                                          this.initialize(url, id)
                                                                                                                                          }); 
                                                                                                        var XMLHttpRequest = Native.XMLHttpRequest
                                                                                                        WebSocketXhr.CONNECTING = 0
                                                                                                        WebSocketXhr.OPEN       = 1
                                                                                                        WebSocketXhr.CLOSING    = 2
                                                                                                        WebSocketXhr.CLOSED     = 3
                                                                                                        scooj.defMethod(module, function initialize(url, id) {
                                                                                                                        if (!id) {
                                                                                                                        id = "anonymous"
                                                                                                                        }
                                                                                                                        this.readyState      = WebSocketXhr.CONNECTING 
                                                                                                                        this._url            = url
                                                                                                                        this._id             = id
                                                                                                                        this._urlChannel     = null
                                                                                                                        this._queuedSends    = []
                                                                                                                        this._sendInProgress = true
                                                                                                                        this._listeners = {
                                                                                                                        open:    new EventListeners(),
                                                                                                                        message: new EventListeners(),
                                                                                                                        error:   new EventListeners(),
                                                                                                                        close:   new EventListeners()
                                                                                                                        }
                                                                                                                        this._getChannel()
                                                                                                                        }); scooj.defMethod(module, function _getChannel() {
                                                                                                                                            var body = JSON.stringify({ id: this._id})
                                                                                                                                            this._xhr(this._url, "POST", body, this._handleXhrResponseGetChannel)
                                                                                                                                            }); scooj.defMethod(module, function _handleXhrResponseGetChannel(xhr) {
                                                                                                                                                                if (xhr.status != 200) return this._handleXhrResponseError(xhr)
                                                                                                                                                                try {
                                                                                                                                                                var object = JSON.parse(xhr.responseText)
                                                                                                                                                                }
                                                                                                                                                                catch (e) {
                                                                                                                                                                this._fireEventListeners("error", {message: "non-JSON response from channel open request"})
                                                                                                                                                                this.close()
                                                                                                                                                                return
                                                                                                                                                                }
                                                                                                                                                                if (!object.channel) {
                                                                                                                                                                this._fireEventListeners("error", {message: "channel open request did not include a channel"})
                                                                                                                                                                this.close()
                                                                                                                                                                return
                                                                                                                                                                }
                                                                                                                                                                this._urlChannel = this._url + "/" + object.channel
                                                                                                                                                                this.readyState = WebSocketXhr.OPEN
                                                                                                                                                                this._fireEventListeners("open", { message: "open", channel: object.channel })
                                                                                                                                                                this._sendInProgress = false
                                                                                                                                                                this._sendQueued()
                                                                                                                                                                this._readLoop()
                                                                                                                                                                }); scooj.defMethod(module, function _readLoop() {
                                                                                                                                                                                    if (this.readyState == WebSocketXhr.CLOSED) return
                                                                                                                                                                                    if (this.readyState == WebSocketXhr.CLOSING) return
                                                                                                                                                                                    this._xhr(this._urlChannel, "GET", "", this._handleXhrResponseGet)
                                                                                                                                                                                    }); scooj.defMethod(module, function _handleXhrResponseGet(xhr) {
                                                                                                                                                                                                        var self = this
                                                                                                                                                                                                        if (xhr.status != 200) return this._handleXhrResponseError(xhr)
                                                                                                                                                                                                        try {
                                                                                                                                                                                                        var datum = JSON.parse(xhr.responseText)
                                                                                                                                                                                                        }
                                                                                                                                                                                                        catch (e) {
                                                                                                                                                                                                        this.readyState = WebSocketXhr.CLOSED
                                                                                                                                                                                                        this._fireEventListeners("error", {
                                                                                                                                                                                                                                 message: "non-JSON response from read request"
                                                                                                                                                                                                                                 })
                                                                                                                                                                                                        return
                                                                                                                                                                                                        }
                                                                                                                                                                                                        Native.setTimeout(function() {self._readLoop()}, 0)
                                                                                                                                                                                                        datum.forEach(function(data) {
                                                                                                                                                                                                                      self._fireEventListeners("message", {data: data})
                                                                                                                                                                                                                      })
                                                                                                                                                                                                        }); scooj.defMethod(module, function send(data) {
                                                                                                                                                                                                                            if (typeof data != "string") throw new Ex(arguments, this.constructor.name + "." + this.caller)
                                                                                                                                                                                                                            this._queuedSends.push(data)
                                                                                                                                                                                                                            if (this._sendInProgress) return
                                                                                                                                                                                                                            this._sendQueued();
                                                                                                                                                                                                                            }); scooj.defMethod(module, function _sendQueued() {
                                                                                                                                                                                                                                                if (this._queuedSends.length == 0) return
                                                                                                                                                                                                                                                if (this.readyState == WebSocketXhr.CLOSED) return
                                                                                                                                                                                                                                                if (this.readyState == WebSocketXhr.CLOSING) return
                                                                                                                                                                                                                                                datum = JSON.stringify(this._queuedSends)
                                                                                                                                                                                                                                                this._queuedSends = []
                                                                                                                                                                                                                                                this._sendInProgress = true
                                                                                                                                                                                                                                                this._xhr(this._urlChannel, "POST", datum, this._handleXhrResponseSend)
                                                                                                                                                                                                                                                }); scooj.defMethod(module, function _handleXhrResponseSend(xhr) {
                                                                                                                                                                                                                                                                    var httpSocket = this
                                                                                                                                                                                                                                                                    if (xhr.status != 200) return this._handleXhrResponseError(xhr)
                                                                                                                                                                                                                                                                    this._sendInProgress = false
                                                                                                                                                                                                                                                                    Native.setTimeout(function() {httpSocket._sendQueued()}, 0)
                                                                                                                                                                                                                                                                    }); scooj.defMethod(module, function close() {
                                                                                                                                                                                                                                                                                        this._sendInProgress = true
                                                                                                                                                                                                                                                                                        this.readyState = WebSocketXhr.CLOSING
                                                                                                                                                                                                                                                                                        this._fireEventListeners("close", {
                                                                                                                                                                                                                                                                                                                 message: "closing",
                                                                                                                                                                                                                                                                                                                 wasClean: true
                                                                                                                                                                                                                                                                                                                 })
                                                                                                                                                                                                                                                                                        this.readyState = WebSocketXhr.CLOSED
                                                                                                                                                                                                                                                                                        }); scooj.defMethod(module, function addEventListener(type, listener, useCapture) {
                                                                                                                                                                                                                                                                                                            this._getListeners(type).add(listener, useCapture)
                                                                                                                                                                                                                                                                                                            }); scooj.defMethod(module, function removeEventListener(type, listener, useCapture) {
                                                                                                                                                                                                                                                                                                                                this._getListeners(type).remove(listener, useCapture)
                                                                                                                                                                                                                                                                                                                                }); scooj.defMethod(module, function _fireEventListeners(type, event) {
                                                                                                                                                                                                                                                                                                                                                    if (this.readyState == WebSocketXhr.CLOSED) return
                                                                                                                                                                                                                                                                                                                                                    event.target = this
                                                                                                                                                                                                                                                                                                                                                    this._getListeners(type).fire(event)
                                                                                                                                                                                                                                                                                                                                                    }); scooj.defMethod(module, function _getListeners(type) {
                                                                                                                                                                                                                                                                                                                                                                        var listeners = this._listeners[type]
                                                                                                                                                                                                                                                                                                                                                                        if (null == listeners) throw new Ex(arguments, "invalid event listener type: '" + type + "'")
                                                                                                                                                                                                                                                                                                                                                                        return listeners
                                                                                                                                                                                                                                                                                                                                                                        }); scooj.defMethod(module, function _handleXhrResponseError(xhr) {
                                                                                                                                                                                                                                                                                                                                                                                            if (xhr.status == 404) {
                                                                                                                                                                                                                                                                                                                                                                                            this.close()
                                                                                                                                                                                                                                                                                                                                                                                            return
                                                                                                                                                                                                                                                                                                                                                                                            }
                                                                                                                                                                                                                                                                                                                                                                                            this._fireEventListeners("error", {
                                                                                                                                                                                                                                                                                                                                                                                                                     target: this,
                                                                                                                                                                                                                                                                                                                                                                                                                     status: xhr.status,
                                                                                                                                                                                                                                                                                                                                                                                                                     message: "error from XHR invocation: " + xhr.statusText
                                                                                                                                                                                                                                                                                                                                                                                                                     })
                                                                                                                                                                                                                                                                                                                                                                                            Weinre.logError("error from XHR invocation: " + xhr.status + ": " + xhr.statusText)
                                                                                                                                                                                                                                                                                                                                                                                            }); scooj.defMethod(module, function _xhr(url, method, data, handler) {
                                                                                                                                                                                                                                                                                                                                                                                                                if (null == handler) throw new Ex(arguments, "handler must not be null")
                                                                                                                                                                                                                                                                                                                                                                                                                var xhr = new XMLHttpRequest()
                                                                                                                                                                                                                                                                                                                                                                                                                xhr.httpSocket         = this
                                                                                                                                                                                                                                                                                                                                                                                                                xhr.httpSocketHandler  = handler
                                                                                                                                                                                                                                                                                                                                                                                                                xhr.onreadystatechange = _xhrEventHandler
                                                                                                                                                                                                                                                                                                                                                                                                                xhr.open(method, url, true)
                                                                                                                                                                                                                                                                                                                                                                                                                xhr.setRequestHeader("Content-Type", "text/plain")
                                                                                                                                                                                                                                                                                                                                                                                                                xhr.send(data)
                                                                                                                                                                                                                                                                                                                                                                                                                }); function _xhrEventHandler(event) {
                                                                                                        var xhr = event.target
                                                                                                        if (xhr.readyState != 4) return
                                                                                                        xhr.httpSocketHandler.call(xhr.httpSocket, xhr) 
                                                                                                        }; 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/common/Binding.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/common/Binding": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Ex = require('./Ex').getClass(); if (typeof Ex != 'function') throw Error('module ./Ex did not export a class');
                                                                                                        var Binding = scooj.defClass(module, function Binding(receiver, method) {
                                                                                                                                     if (receiver == null) throw new Ex(arguments, "receiver argument for Binding constructor was null")
                                                                                                                                     if (typeof(method) == "string") method = receiver[method]
                                                                                                                                     if (typeof(method) != "function") throw new Ex(arguments, "method argument didn't specify a function")
                                                                                                                                     return function() {
                                                                                                                                     return method.apply(receiver, [].slice.call(arguments))
                                                                                                                                     }
                                                                                                                                     }); 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/common/Callback.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/common/Callback": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Ex = require('./Ex').getClass(); if (typeof Ex != 'function') throw Error('module ./Ex did not export a class');
                                                                                                        var Callback = scooj.defClass(module, function Callback() {
                                                                                                                                      throw new Ex(arguments, "this class is not intended to be instantiated")
                                                                                                                                      }); 
                                                                                                        var CallbackTable    = {}
                                                                                                        var CallbackIndex    = 1
                                                                                                        var ConnectorChannel = "???"
                                                                                                        scooj.defStaticMethod(module, function setConnectorChannel(connectorChannel) {
                                                                                                                              ConnectorChannel = ""  + connectorChannel
                                                                                                                              }); scooj.defStaticMethod(module, function register(callback) {
                                                                                                                                                        if (typeof callback == "function") callback = [null, callback]
                                                                                                                                                        if (typeof callback.slice != "function") throw new Ex(arguments, "callback must be an array or function")
                                                                                                                                                        var receiver = callback[0]
                                                                                                                                                        var func     = callback[1]
                                                                                                                                                        var data     = callback.slice(2)
                                                                                                                                                        if (typeof func == "string") func = receiver.func
                                                                                                                                                        if (typeof func != "function") throw new Ex(arguments, "callback function was null or not found")
                                                                                                                                                        var index = ConnectorChannel + "::" + CallbackIndex
                                                                                                                                                        CallbackIndex++
                                                                                                                                                        if (CallbackIndex >= 65536 * 65536) CallbackIndex = 1
                                                                                                                                                        CallbackTable[index] = [receiver, func, data]
                                                                                                                                                        return index
                                                                                                                                                        }); scooj.defStaticMethod(module, function deregister(index) {
                                                                                                                                                                                  delete CallbackTable[index]
                                                                                                                                                                                  }); scooj.defStaticMethod(module, function invoke(index, args) {
                                                                                                                                                                                                            var callback = CallbackTable[index]
                                                                                                                                                                                                            if (!callback) throw new Ex(arguments, "callback " + index + " not registered or already invoked")
                                                                                                                                                                                                            var receiver = callback[0]
                                                                                                                                                                                                            var func     = callback[1]
                                                                                                                                                                                                            var args     = callback[2].concat(args)
                                                                                                                                                                                                            try {
                                                                                                                                                                                                            func.apply(receiver,args)
                                                                                                                                                                                                            }
                                                                                                                                                                                                            catch (e) {
                                                                                                                                                                                                            var funcName = func.name
                                                                                                                                                                                                            if (!funcName) funcName = "<unnamed>"
                                                                                                                                                                                                            require("./Weinre").getClass().logError(arguments.callee.signature + " exception invoking callback: " + funcName + "(" + args.join(",") + "): " + e)
                                                                                                                                                                                                            }
                                                                                                                                                                                                            finally {
                                                                                                                                                                                                            Callback.deregister(index)
                                                                                                                                                                                                            }
                                                                                                                                                                                                            }); 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/common/EventListeners.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/common/EventListeners": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Ex = require('./Ex').getClass(); if (typeof Ex != 'function') throw Error('module ./Ex did not export a class');
                                                                                                        var Weinre = require('./Weinre').getClass(); if (typeof Weinre != 'function') throw Error('module ./Weinre did not export a class');
                                                                                                        var EventListeners = scooj.defClass(module, function EventListeners() {
                                                                                                                                            this._listeners = []
                                                                                                                                            }); scooj.defMethod(module, function add(listener, useCapture) {
                                                                                                                                                                this._listeners.push([listener, useCapture])
                                                                                                                                                                }); scooj.defMethod(module, function remove(listener, useCapture) {
                                                                                                                                                                                    for (var i=0; i<this._listeners.length; i++) {
                                                                                                                                                                                    var listener = this._listeners[i]
                                                                                                                                                                                    if (listener[0] != listener) continue;
                                                                                                                                                                                    if (listener[1] != useCapture) continue;
                                                                                                                                                                                    this._listeners.splice(i,1)
                                                                                                                                                                                    return
                                                                                                                                                                                    }
                                                                                                                                                                                    }); scooj.defMethod(module, function fire(event) {
                                                                                                                                                                                                        this._listeners.slice().forEach(function(listener) {
                                                                                                                                                                                                                                        var listener = listener[0]
                                                                                                                                                                                                                                        if (typeof listener == "function") {
                                                                                                                                                                                                                                        try {
                                                                                                                                                                                                                                        listener.call(null, event)
                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                        catch(e) {
                                                                                                                                                                                                                                        Weinre.logError(arguments.callee.signature + " invocation exception: " + e)
                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                        return
                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                        if (typeof listener.handleEvent != "function") {
                                                                                                                                                                                                                                        throw new Ex(arguments, "listener does not implement the handleEvent() method")
                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                        try {
                                                                                                                                                                                                                                        listener.handleEvent.call(listener, event)
                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                        catch(e) {
                                                                                                                                                                                                                                        Weinre.logError(arguments.callee.signature + " invocation exception: " + e)
                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                        })
                                                                                                                                                                                                        }); 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/common/Native.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/common/Native": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Native = scooj.defClass(module, function Native() {
                                                                                                                                                                   }); 
                                                                                                        Native.original = {}
                                                                                                        Native.original.clearInterval             = window.clearInterval
                                                                                                        Native.original.clearTimeout              = window.clearTimeout
                                                                                                        Native.original.setTimeout                = window.setTimeout
                                                                                                        Native.original.setInterval               = window.setInterval
                                                                                                        Native.original.XMLHttpRequest            = window.XMLHttpRequest
                                                                                                        Native.original.XMLHttpRequest_open       = window.XMLHttpRequest.prototype.open
                                                                                                        Native.original.LocalStorage_setItem      = window.localStorage   ? window.localStorage.setItem      : null
                                                                                                        Native.original.LocalStorage_removeItem   = window.localStorage   ? window.localStorage.removeItem   : null
                                                                                                        Native.original.LocalStorage_clear        = window.localStorage   ? window.localStorage.clear        : null
                                                                                                        Native.original.SessionStorage_setItem    = window.sessionStorage ? window.sessionStorage.setItem    : null
                                                                                                        Native.original.SessionStorage_removeItem = window.sessionStorage ? window.sessionStorage.removeItem : null
                                                                                                        Native.original.SessionStorage_clear      = window.sessionStorage ? window.sessionStorage.clear      : null
                                                                                                        Native.clearInterval             = function() { return Native.original.clearInterval.apply( window, [].slice.call(arguments))}
                                                                                                        Native.clearTimeout              = function() { return Native.original.clearTimeout.apply(  window, [].slice.call(arguments))}
                                                                                                        Native.setInterval               = function() { return Native.original.setInterval.apply(   window, [].slice.call(arguments))}
                                                                                                        Native.setTimeout                = function() { return Native.original.setTimeout.apply(    window, [].slice.call(arguments))}
                                                                                                        Native.XMLHttpRequest            = function() { return new Native.original.XMLHttpRequest()}
                                                                                                        Native.XMLHttpRequest_open       = function() { return Native.original.XMLHttpRequest_open.apply(this, [].slice.call(arguments))}
                                                                                                        Native.LocalStorage_setItem      = function() { return Native.original.LocalStorage_setItem.apply(      window.localStorage,   [].slice.call(arguments))}
                                                                                                        Native.LocalStorage_removeItem   = function() { return Native.original.LocalStorage_removeItem.apply(   window.localStorage,   [].slice.call(arguments))}
                                                                                                        Native.LocalStorage_clear        = function() { return Native.original.LocalStorage_clear.apply(        window.localStorage,   [].slice.call(arguments))}
                                                                                                        Native.SessionStorage_setItem    = function() { return Native.original.SessionStorage_setItem.apply(    window.sessionStorage, [].slice.call(arguments))}
                                                                                                        Native.SessionStorage_removeItem = function() { return Native.original.SessionStorage_removeItem.apply( window.sessionStorage, [].slice.call(arguments))}
                                                                                                        Native.SessionStorage_clear      = function() { return Native.original.SessionStorage_clear.apply(      window.sessionStorage, [].slice.call(arguments))}
                                                                                                        ;
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/common/IDGenerator.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/common/IDGenerator": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var IDGenerator = scooj.defClass(module, function IDGenerator() {
                                                                                                                                                                        }); 
                                                                                                        var nextIdValue = 1
                                                                                                        var idName      = "__weinre__id"
                                                                                                        scooj.defStaticMethod(module, function checkId(object) {
                                                                                                                              return object[idName]
                                                                                                                              }); scooj.defStaticMethod(module, function getId(object, map) {
                                                                                                                                                        var id = IDGenerator.checkId(object)
                                                                                                                                                        if (!id) {
                                                                                                                                                        id = nextId()
                                                                                                                                                        object[idName] = id
                                                                                                                                                        }
                                                                                                                                                        if (map) {
                                                                                                                                                        if (map[id] != object) {
                                                                                                                                                        map[id] = object
                                                                                                                                                        }
                                                                                                                                                        }
                                                                                                                                                        return id
                                                                                                                                                        }); scooj.defStaticMethod(module, function next() {
                                                                                                                                                                                  return nextId()
                                                                                                                                                                                  }); function nextId() {
                                                                                                        var result = nextIdValue
                                                                                                        nextIdValue += 1
                                                                                                        return result
                                                                                                        }; 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/target/Console.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/target/Console": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Weinre = require('../common/Weinre').getClass(); if (typeof Weinre != 'function') throw Error('module ../common/Weinre did not export a class');
                                                                                                        var Timeline = require('../target/Timeline').getClass(); if (typeof Timeline != 'function') throw Error('module ../target/Timeline did not export a class');
                                                                                                        var Console = scooj.defClass(module, function Console() {
                                                                                                                                     }); 
                                                                                                        var UsingRemote = false
                                                                                                        var RemoteConsole   = new Console()
                                                                                                        var OriginalConsole = window.console
                                                                                                        RemoteConsole.__original   = OriginalConsole
                                                                                                        OriginalConsole.__original = OriginalConsole
                                                                                                        var MessageSource = {
                                                                                                        HTML: 0,
                                                                                                        WML: 1,
                                                                                                        XML: 2,
                                                                                                        JS: 3,
                                                                                                        CSS: 4,
                                                                                                        Other: 5
                                                                                                        }
                                                                                                        var MessageType = {
                                                                                                        Log: 0,
                                                                                                        Object: 1,
                                                                                                        Trace: 2,
                                                                                                        StartGroup: 3,
                                                                                                        StartGroupCollapsed: 4,
                                                                                                        EndGroup: 5,
                                                                                                        Assert: 6,
                                                                                                        UncaughtException: 7,
                                                                                                        Result: 8
                                                                                                        }
                                                                                                        var MessageLevel = {
                                                                                                        Tip: 0,
                                                                                                        Log: 1,
                                                                                                        Warning: 2,
                                                                                                        Error: 3,
                                                                                                        Debug: 4
                                                                                                        }
                                                                                                        scooj.defStaticGetter(module, function original() {
                                                                                                                              return OriginalConsole
                                                                                                                              }); scooj.defStaticMethod(module, function useRemote(value) {
                                                                                                                                                        if (arguments.length == 0) return UsingRemote
                                                                                                                                                        var oldValue = UsingRemote
                                                                                                                                                        UsingRemote = !!value
                                                                                                                                                        if (UsingRemote) 
                                                                                                                                                        window.console = RemoteConsole
                                                                                                                                                        else
                                                                                                                                                        window.console = OriginalConsole
                                                                                                                                                        return oldValue
                                                                                                                                                        }); scooj.defMethod(module, function _generic(level, messageParts) {
                                                                                                                                                                            var message = messageParts[0]
                                                                                                                                                                            var parameters = []
                                                                                                                                                                            for (var i=0; i<messageParts.length; i++) {
                                                                                                                                                                            parameters.push(
                                                                                                                                                                                            Weinre.injectedScript.wrapObjectForConsole(messageParts[i], true)
                                                                                                                                                                                            )
                                                                                                                                                                            }
                                                                                                                                                                            var payload = {
                                                                                                                                                                            source:      MessageSource.JS,
                                                                                                                                                                            type:        MessageType.Log,
                                                                                                                                                                            level:       level,
                                                                                                                                                                            message:     message,
                                                                                                                                                                            parameters:  parameters
                                                                                                                                                                            }
                                                                                                                                                                            Weinre.wi.ConsoleNotify.addConsoleMessage(payload)
                                                                                                                                                                            }); scooj.defMethod(module, function log() {
                                                                                                                                                                                                this._generic(MessageLevel.Log, [].slice.call(arguments)) 
                                                                                                                                                                                                }); scooj.defMethod(module, function debug() {
                                                                                                                                                                                                                    this._generic(MessageLevel.Debug, [].slice.call(arguments)) 
                                                                                                                                                                                                                    }); scooj.defMethod(module, function error() {
                                                                                                                                                                                                                                        this._generic(MessageLevel.Error, [].slice.call(arguments)) 
                                                                                                                                                                                                                                        }); scooj.defMethod(module, function info() {
                                                                                                                                                                                                                                                            this._generic(MessageLevel.Log, [].slice.call(arguments)) 
                                                                                                                                                                                                                                                            }); scooj.defMethod(module, function warn() {
                                                                                                                                                                                                                                                                                this._generic(MessageLevel.Warning, [].slice.call(arguments)) 
                                                                                                                                                                                                                                                                                }); scooj.defMethod(module, function dir() {
                                                                                                                                                                                                                                                                                                    Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                    }); scooj.defMethod(module, function dirxml() {
                                                                                                                                                                                                                                                                                                                        Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                                        }); scooj.defMethod(module, function trace() {
                                                                                                                                                                                                                                                                                                                                            Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                                                            }); scooj.defMethod(module, function assert(condition) {
                                                                                                                                                                                                                                                                                                                                                                Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                                                                                }); scooj.defMethod(module, function count() {
                                                                                                                                                                                                                                                                                                                                                                                    Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                                                                                                    }); scooj.defMethod(module, function markTimeline(message) {
                                                                                                                                                                                                                                                                                                                                                                                                        Timeline.addRecord_Mark(message)
                                                                                                                                                                                                                                                                                                                                                                                                        }); scooj.defMethod(module, function lastWMLErrorMessage() {
                                                                                                                                                                                                                                                                                                                                                                                                                            Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                                                                                                                                            }); scooj.defMethod(module, function profile(title) {
                                                                                                                                                                                                                                                                                                                                                                                                                                                Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                                                                                                                                                                }); scooj.defMethod(module, function profileEnd(title) {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                    Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                    }); scooj.defMethod(module, function time(title) {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        }); scooj.defMethod(module, function timeEnd(title) {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            }); scooj.defMethod(module, function group() {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                }); scooj.defMethod(module, function groupCollapsed() {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    }); scooj.defMethod(module, function groupEnd() {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        }); 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: add-css-properties.js
                                                                                        //==================================================
                                                                                        require("weinre/common/Weinre").getClass().addCSSProperties([
                                                                                                                                                     "-webkit-animation", 
                                                                                                                                                     "-webkit-animation-delay", 
                                                                                                                                                     "-webkit-animation-direction", 
                                                                                                                                                     "-webkit-animation-duration", 
                                                                                                                                                     "-webkit-animation-fill-mode", 
                                                                                                                                                     "-webkit-animation-iteration-count", 
                                                                                                                                                     "-webkit-animation-name", 
                                                                                                                                                     "-webkit-animation-play-state", 
                                                                                                                                                     "-webkit-animation-timing-function", 
                                                                                                                                                     "-webkit-appearance", 
                                                                                                                                                     "-webkit-backface-visibility", 
                                                                                                                                                     "-webkit-background-clip", 
                                                                                                                                                     "-webkit-background-composite", 
                                                                                                                                                     "-webkit-background-origin", 
                                                                                                                                                     "-webkit-background-size", 
                                                                                                                                                     "-webkit-border-after", 
                                                                                                                                                     "-webkit-border-after-color", 
                                                                                                                                                     "-webkit-border-after-style", 
                                                                                                                                                     "-webkit-border-after-width", 
                                                                                                                                                     "-webkit-border-before", 
                                                                                                                                                     "-webkit-border-before-color", 
                                                                                                                                                     "-webkit-border-before-style", 
                                                                                                                                                     "-webkit-border-before-width", 
                                                                                                                                                     "-webkit-border-end", 
                                                                                                                                                     "-webkit-border-end-color", 
                                                                                                                                                     "-webkit-border-end-style", 
                                                                                                                                                     "-webkit-border-end-width", 
                                                                                                                                                     "-webkit-border-fit", 
                                                                                                                                                     "-webkit-border-horizontal-spacing", 
                                                                                                                                                     "-webkit-border-image", 
                                                                                                                                                     "-webkit-border-radius", 
                                                                                                                                                     "-webkit-border-start", 
                                                                                                                                                     "-webkit-border-start-color", 
                                                                                                                                                     "-webkit-border-start-style", 
                                                                                                                                                     "-webkit-border-start-width", 
                                                                                                                                                     "-webkit-border-vertical-spacing", 
                                                                                                                                                     "-webkit-box-align", 
                                                                                                                                                     "-webkit-box-direction", 
                                                                                                                                                     "-webkit-box-flex", 
                                                                                                                                                     "-webkit-box-flex-group", 
                                                                                                                                                     "-webkit-box-lines", 
                                                                                                                                                     "-webkit-box-ordinal-group", 
                                                                                                                                                     "-webkit-box-orient", 
                                                                                                                                                     "-webkit-box-pack", 
                                                                                                                                                     "-webkit-box-reflect", 
                                                                                                                                                     "-webkit-box-shadow", 
                                                                                                                                                     "-webkit-color-correction", 
                                                                                                                                                     "-webkit-column-break-after", 
                                                                                                                                                     "-webkit-column-break-before", 
                                                                                                                                                     "-webkit-column-break-inside", 
                                                                                                                                                     "-webkit-column-count", 
                                                                                                                                                     "-webkit-column-gap", 
                                                                                                                                                     "-webkit-column-rule", 
                                                                                                                                                     "-webkit-column-rule-color", 
                                                                                                                                                     "-webkit-column-rule-style", 
                                                                                                                                                     "-webkit-column-rule-width", 
                                                                                                                                                     "-webkit-column-span", 
                                                                                                                                                     "-webkit-column-width", 
                                                                                                                                                     "-webkit-columns", 
                                                                                                                                                     "-webkit-font-size-delta", 
                                                                                                                                                     "-webkit-font-smoothing", 
                                                                                                                                                     "-webkit-highlight", 
                                                                                                                                                     "-webkit-hyphenate-character", 
                                                                                                                                                     "-webkit-hyphenate-locale", 
                                                                                                                                                     "-webkit-hyphens", 
                                                                                                                                                     "-webkit-line-break", 
                                                                                                                                                     "-webkit-line-clamp", 
                                                                                                                                                     "-webkit-logical-height", 
                                                                                                                                                     "-webkit-logical-width", 
                                                                                                                                                     "-webkit-margin-after", 
                                                                                                                                                     "-webkit-margin-after-collapse", 
                                                                                                                                                     "-webkit-margin-before", 
                                                                                                                                                     "-webkit-margin-before-collapse", 
                                                                                                                                                     "-webkit-margin-bottom-collapse", 
                                                                                                                                                     "-webkit-margin-collapse", 
                                                                                                                                                     "-webkit-margin-end", 
                                                                                                                                                     "-webkit-margin-start", 
                                                                                                                                                     "-webkit-margin-top-collapse", 
                                                                                                                                                     "-webkit-marquee", 
                                                                                                                                                     "-webkit-marquee-direction", 
                                                                                                                                                     "-webkit-marquee-increment", 
                                                                                                                                                     "-webkit-marquee-repetition", 
                                                                                                                                                     "-webkit-marquee-speed", 
                                                                                                                                                     "-webkit-marquee-style", 
                                                                                                                                                     "-webkit-mask", 
                                                                                                                                                     "-webkit-mask-attachment", 
                                                                                                                                                     "-webkit-mask-box-image", 
                                                                                                                                                     "-webkit-mask-clip", 
                                                                                                                                                     "-webkit-mask-composite", 
                                                                                                                                                     "-webkit-mask-image", 
                                                                                                                                                     "-webkit-mask-origin", 
                                                                                                                                                     "-webkit-mask-position", 
                                                                                                                                                     "-webkit-mask-position-x", 
                                                                                                                                                     "-webkit-mask-position-y", 
                                                                                                                                                     "-webkit-mask-repeat", 
                                                                                                                                                     "-webkit-mask-repeat-x", 
                                                                                                                                                     "-webkit-mask-repeat-y", 
                                                                                                                                                     "-webkit-mask-size", 
                                                                                                                                                     "-webkit-match-nearest-mail-blockquote-color", 
                                                                                                                                                     "-webkit-max-logical-height", 
                                                                                                                                                     "-webkit-max-logical-width", 
                                                                                                                                                     "-webkit-min-logical-height", 
                                                                                                                                                     "-webkit-min-logical-width", 
                                                                                                                                                     "-webkit-nbsp-mode", 
                                                                                                                                                     "-webkit-padding-after", 
                                                                                                                                                     "-webkit-padding-before", 
                                                                                                                                                     "-webkit-padding-end", 
                                                                                                                                                     "-webkit-padding-start", 
                                                                                                                                                     "-webkit-perspective", 
                                                                                                                                                     "-webkit-perspective-origin", 
                                                                                                                                                     "-webkit-perspective-origin-x", 
                                                                                                                                                     "-webkit-perspective-origin-y", 
                                                                                                                                                     "-webkit-rtl-ordering", 
                                                                                                                                                     "-webkit-text-combine", 
                                                                                                                                                     "-webkit-text-decorations-in-effect", 
                                                                                                                                                     "-webkit-text-emphasis", 
                                                                                                                                                     "-webkit-text-emphasis-color", 
                                                                                                                                                     "-webkit-text-emphasis-position", 
                                                                                                                                                     "-webkit-text-emphasis-style", 
                                                                                                                                                     "-webkit-text-fill-color", 
                                                                                                                                                     "-webkit-text-security", 
                                                                                                                                                     "-webkit-text-size-adjust", 
                                                                                                                                                     "-webkit-text-stroke", 
                                                                                                                                                     "-webkit-text-stroke-color", 
                                                                                                                                                     "-webkit-text-stroke-width", 
                                                                                                                                                     "-webkit-transform", 
                                                                                                                                                     "-webkit-transform-origin", 
                                                                                                                                                     "-webkit-transform-origin-x", 
                                                                                                                                                     "-webkit-transform-origin-y", 
                                                                                                                                                     "-webkit-transform-origin-z", 
                                                                                                                                                     "-webkit-transform-style", 
                                                                                                                                                     "-webkit-transition", 
                                                                                                                                                     "-webkit-transition-delay", 
                                                                                                                                                     "-webkit-transition-duration", 
                                                                                                                                                     "-webkit-transition-property", 
                                                                                                                                                     "-webkit-transition-timing-function", 
                                                                                                                                                     "-webkit-user-drag", 
                                                                                                                                                     "-webkit-user-modify", 
                                                                                                                                                     "-webkit-user-select", 
                                                                                                                                                     "-webkit-writing-mode", 
                                                                                                                                                     "background", 
                                                                                                                                                     "background-attachment", 
                                                                                                                                                     "background-clip", 
                                                                                                                                                     "background-color", 
                                                                                                                                                     "background-image", 
                                                                                                                                                     "background-origin", 
                                                                                                                                                     "background-position", 
                                                                                                                                                     "background-position-x", 
                                                                                                                                                     "background-position-y", 
                                                                                                                                                     "background-repeat", 
                                                                                                                                                     "background-repeat-x", 
                                                                                                                                                     "background-repeat-y", 
                                                                                                                                                     "background-size", 
                                                                                                                                                     "border", 
                                                                                                                                                     "border-bottom", 
                                                                                                                                                     "border-bottom-color", 
                                                                                                                                                     "border-bottom-left-radius", 
                                                                                                                                                     "border-bottom-right-radius", 
                                                                                                                                                     "border-bottom-style", 
                                                                                                                                                     "border-bottom-width", 
                                                                                                                                                     "border-collapse", 
                                                                                                                                                     "border-color", 
                                                                                                                                                     "border-left", 
                                                                                                                                                     "border-left-color", 
                                                                                                                                                     "border-left-style", 
                                                                                                                                                     "border-left-width", 
                                                                                                                                                     "border-radius", 
                                                                                                                                                     "border-right", 
                                                                                                                                                     "border-right-color", 
                                                                                                                                                     "border-right-style", 
                                                                                                                                                     "border-right-width", 
                                                                                                                                                     "border-spacing", 
                                                                                                                                                     "border-style", 
                                                                                                                                                     "border-top", 
                                                                                                                                                     "border-top-color", 
                                                                                                                                                     "border-top-left-radius", 
                                                                                                                                                     "border-top-right-radius", 
                                                                                                                                                     "border-top-style", 
                                                                                                                                                     "border-top-width", 
                                                                                                                                                     "border-width", 
                                                                                                                                                     "bottom", 
                                                                                                                                                     "box-shadow", 
                                                                                                                                                     "box-sizing", 
                                                                                                                                                     "caption-side", 
                                                                                                                                                     "clear", 
                                                                                                                                                     "clip", 
                                                                                                                                                     "color", 
                                                                                                                                                     "content", 
                                                                                                                                                     "counter-increment", 
                                                                                                                                                     "counter-reset", 
                                                                                                                                                     "cursor", 
                                                                                                                                                     "direction", 
                                                                                                                                                     "display", 
                                                                                                                                                     "empty-cells", 
                                                                                                                                                     "float", 
                                                                                                                                                     "font", 
                                                                                                                                                     "font-family", 
                                                                                                                                                     "font-size", 
                                                                                                                                                     "font-stretch", 
                                                                                                                                                     "font-style", 
                                                                                                                                                     "font-variant", 
                                                                                                                                                     "font-weight", 
                                                                                                                                                     "height", 
                                                                                                                                                     "left", 
                                                                                                                                                     "letter-spacing", 
                                                                                                                                                     "line-height", 
                                                                                                                                                     "list-style", 
                                                                                                                                                     "list-style-image", 
                                                                                                                                                     "list-style-position", 
                                                                                                                                                     "list-style-type", 
                                                                                                                                                     "margin", 
                                                                                                                                                     "margin-bottom", 
                                                                                                                                                     "margin-left", 
                                                                                                                                                     "margin-right", 
                                                                                                                                                     "margin-top", 
                                                                                                                                                     "max-height", 
                                                                                                                                                     "max-width", 
                                                                                                                                                     "min-height", 
                                                                                                                                                     "min-width", 
                                                                                                                                                     "opacity", 
                                                                                                                                                     "orphans", 
                                                                                                                                                     "outline", 
                                                                                                                                                     "outline-color", 
                                                                                                                                                     "outline-offset", 
                                                                                                                                                     "outline-style", 
                                                                                                                                                     "outline-width", 
                                                                                                                                                     "overflow", 
                                                                                                                                                     "overflow-x", 
                                                                                                                                                     "overflow-y", 
                                                                                                                                                     "padding", 
                                                                                                                                                     "padding-bottom", 
                                                                                                                                                     "padding-left", 
                                                                                                                                                     "padding-right", 
                                                                                                                                                     "padding-top", 
                                                                                                                                                     "page", 
                                                                                                                                                     "page-break-after", 
                                                                                                                                                     "page-break-before", 
                                                                                                                                                     "page-break-inside", 
                                                                                                                                                     "pointer-events", 
                                                                                                                                                     "position", 
                                                                                                                                                     "quotes", 
                                                                                                                                                     "resize", 
                                                                                                                                                     "right", 
                                                                                                                                                     "size", 
                                                                                                                                                     "speak", 
                                                                                                                                                     "src", 
                                                                                                                                                     "table-layout", 
                                                                                                                                                     "text-align", 
                                                                                                                                                     "text-decoration", 
                                                                                                                                                     "text-indent", 
                                                                                                                                                     "text-line-through", 
                                                                                                                                                     "text-line-through-color", 
                                                                                                                                                     "text-line-through-mode", 
                                                                                                                                                     "text-line-through-style", 
                                                                                                                                                     "text-line-through-width", 
                                                                                                                                                     "text-overflow", 
                                                                                                                                                     "text-overline", 
                                                                                                                                                     "text-overline-color", 
                                                                                                                                                     "text-overline-mode", 
                                                                                                                                                     "text-overline-style", 
                                                                                                                                                     "text-overline-width", 
                                                                                                                                                     "text-rendering", 
                                                                                                                                                     "text-shadow", 
                                                                                                                                                     "text-transform", 
                                                                                                                                                     "text-underline", 
                                                                                                                                                     "text-underline-color", 
                                                                                                                                                     "text-underline-mode", 
                                                                                                                                                     "text-underline-style", 
                                                                                                                                                     "text-underline-width", 
                                                                                                                                                     "top", 
                                                                                                                                                     "unicode-bidi", 
                                                                                                                                                     "unicode-range", 
                                                                                                                                                     "vertical-align", 
                                                                                                                                                     "visibility", 
                                                                                                                                                     "white-space", 
                                                                                                                                                     "widows", 
                                                                                                                                                     "width", 
                                                                                                                                                     "word-break", 
                                                                                                                                                     "word-spacing", 
                                                                                                                                                     "word-wrap", 
                                                                                                                                                     "z-index", 
                                                                                                                                                     "zoom"
                                                                                                                                                     ])
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/target/CheckForProblems.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/target/CheckForProblems": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var CheckForProblems = scooj.defClass(module, function CheckForProblems() {
                                                                                                                                                                             }); scooj.defStaticMethod(module, function check() {
                                                                                                                                                                                                       checkForOldPrototypeVersion()
                                                                                                                                                                                                       }); function checkForOldPrototypeVersion() {
                                                                                                        var badVersion = false
                                                                                                        if (typeof Prototype == "undefined") return
                                                                                                        if (!Prototype.Version) return
                                                                                                        if (Prototype.Version.match(/^1\.5.*/)) badVersion = true
                                                                                                        if (Prototype.Version.match(/^1\.6.*/)) badVersion = true
                                                                                                        if (badVersion) {
                                                                                                        alert("Sorry, weinre is not support in versions of Prototype earlier than 1.7")
                                                                                                        }
                                                                                                        }; 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/target/WiConsoleImpl.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/target/WiConsoleImpl": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Weinre = require('../common/Weinre').getClass(); if (typeof Weinre != 'function') throw Error('module ../common/Weinre did not export a class');
                                                                                                        var WiConsoleImpl = scooj.defClass(module, function WiConsoleImpl() {
                                                                                                                                           this.messagesEnabled = true
                                                                                                                                           }); scooj.defMethod(module, function setConsoleMessagesEnabled( enabled, callback) {
                                                                                                                                                               var oldValue = this.messagesEnabled
                                                                                                                                                               this.messagesEnabled = enabled
                                                                                                                                                               if (callback) {
                                                                                                                                                               Weinre.WeinreTargetCommands.sendClientCallback(callback, [oldValue])
                                                                                                                                                               }
                                                                                                                                                               }); scooj.defMethod(module, function clearConsoleMessages(callback) {
                                                                                                                                                                                   Weinre.wi.ConsoleNotify.consoleMessagesCleared()
                                                                                                                                                                                   if (callback) {
                                                                                                                                                                                   Weinre.WeinreTargetCommands.sendClientCallback(callback, [])
                                                                                                                                                                                   }
                                                                                                                                                                                   }); scooj.defMethod(module, function setMonitoringXHREnabled( enabled, callback) {
                                                                                                                                                                                                       if (callback) {
                                                                                                                                                                                                       Weinre.WeinreTargetCommands.sendClientCallback(callback, [])
                                                                                                                                                                                                       }
                                                                                                                                                                                                       }); 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/target/WiCSSImpl.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/target/WiCSSImpl": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Weinre = require('../common/Weinre').getClass(); if (typeof Weinre != 'function') throw Error('module ../common/Weinre did not export a class');
                                                                                                        var WiCSSImpl = scooj.defClass(module, function WiCSSImpl() {
                                                                                                                                       this.dummyComputedStyle = false
                                                                                                                                       }); scooj.defMethod(module, function getStylesForNode( nodeId, callback) {
                                                                                                                                                           var result = {}
                                                                                                                                                           var node = Weinre.nodeStore.getNode(nodeId)
                                                                                                                                                           if (!node) {
                                                                                                                                                           Weinre.logWarning(arguments.callee.signature + " passed an invalid nodeId: " + nodeId)
                                                                                                                                                           return
                                                                                                                                                           }
                                                                                                                                                           var computedStyle
                                                                                                                                                           if (this.dummyComputedStyle) {
                                                                                                                                                           computedStyle = {
                                                                                                                                                           styleId:            null,
                                                                                                                                                           properties:         [],
                                                                                                                                                           shorthandValues:    [],
                                                                                                                                                           cssProperties:      []
                                                                                                                                                           }
                                                                                                                                                           }
                                                                                                                                                           else {
                                                                                                                                                           computedStyle =  Weinre.cssStore.getComputedStyle(node)
                                                                                                                                                           }
                                                                                                                                                           var result = {
                                                                                                                                                           inlineStyle:     Weinre.cssStore.getInlineStyle(node),
                                                                                                                                                           computedStyle:   computedStyle,
                                                                                                                                                           matchedCSSRules: Weinre.cssStore.getMatchedCSSRules(node),
                                                                                                                                                           styleAttributes: Weinre.cssStore.getStyleAttributes(node),
                                                                                                                                                           pseudoElements:  Weinre.cssStore.getPseudoElements(node),
                                                                                                                                                           inherited:       []
                                                                                                                                                           }
                                                                                                                                                           var parentNode = node.parentNode
                                                                                                                                                           while (parentNode) {
                                                                                                                                                           var parentStyle = {
                                                                                                                                                           inlineStyle:     Weinre.cssStore.getInlineStyle(parentNode),
                                                                                                                                                           matchedCSSRules: Weinre.cssStore.getMatchedCSSRules(parentNode),
                                                                                                                                                           }
                                                                                                                                                           result.inherited.push(parentStyle)
                                                                                                                                                           parentNode = parentNode.parentNode
                                                                                                                                                           }
                                                                                                                                                           if (callback) {
                                                                                                                                                           Weinre.WeinreTargetCommands.sendClientCallback(callback, [result])
                                                                                                                                                           }
                                                                                                                                                           }); scooj.defMethod(module, function getComputedStyleForNode( nodeId, callback) {
                                                                                                                                                                               var node = Weinre.nodeStore.getNode(nodeId)
                                                                                                                                                                               if (!node) {
                                                                                                                                                                               Weinre.logWarning(arguments.callee.signature + " passed an invalid nodeId: " + nodeId)
                                                                                                                                                                               return
                                                                                                                                                                               }
                                                                                                                                                                               var result = Weinre.cssStore.getComputedStyle(node) 
                                                                                                                                                                               if (callback) {
                                                                                                                                                                               Weinre.WeinreTargetCommands.sendClientCallback(callback, [result])
                                                                                                                                                                               }
                                                                                                                                                                               }); scooj.defMethod(module, function getInlineStyleForNode( nodeId, callback) {
                                                                                                                                                                                                   var node = Weinre.nodeStore.getNode(nodeId)
                                                                                                                                                                                                   if (!node) {
                                                                                                                                                                                                   Weinre.logWarning(arguments.callee.signature + " passed an invalid nodeId: " + nodeId)
                                                                                                                                                                                                   return
                                                                                                                                                                                                   }
                                                                                                                                                                                                   var result = Weinre.cssStore.getInlineStyle(node)
                                                                                                                                                                                                   if (callback) {
                                                                                                                                                                                                   Weinre.WeinreTargetCommands.sendClientCallback(callback, [result])
                                                                                                                                                                                                   }
                                                                                                                                                                                                   }); scooj.defMethod(module, function getAllStyles(callback) {
                                                                                                                                                                                                                       Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                       }); scooj.defMethod(module, function getStyleSheet( styleSheetId, callback) {
                                                                                                                                                                                                                                           Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                           }); scooj.defMethod(module, function getStyleSheetText( styleSheetId, callback) {
                                                                                                                                                                                                                                                               Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                               }); scooj.defMethod(module, function setStyleSheetText( styleSheetId,  text, callback) {
                                                                                                                                                                                                                                                                                   Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                   }); scooj.defMethod(module, function setPropertyText( styleId,  propertyIndex,  text,  overwrite, callback) {
                                                                                                                                                                                                                                                                                                       var result = Weinre.cssStore.setPropertyText(styleId, propertyIndex, text, overwrite)
                                                                                                                                                                                                                                                                                                       if (callback) {
                                                                                                                                                                                                                                                                                                       Weinre.WeinreTargetCommands.sendClientCallback(callback, [result])
                                                                                                                                                                                                                                                                                                       }
                                                                                                                                                                                                                                                                                                       }); scooj.defMethod(module, function toggleProperty( styleId,  propertyIndex,  disable, callback) {
                                                                                                                                                                                                                                                                                                                           var result = Weinre.cssStore.toggleProperty(styleId, propertyIndex, disable)
                                                                                                                                                                                                                                                                                                                           if (callback) {
                                                                                                                                                                                                                                                                                                                           Weinre.WeinreTargetCommands.sendClientCallback(callback, [result])
                                                                                                                                                                                                                                                                                                                           }
                                                                                                                                                                                                                                                                                                                           }); scooj.defMethod(module, function setRuleSelector( ruleId,  selector, callback) {
                                                                                                                                                                                                                                                                                                                                               Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                                                               }); scooj.defMethod(module, function addRule( contextNodeId,  selector, callback) {
                                                                                                                                                                                                                                                                                                                                                                   Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                                                                                   }); scooj.defMethod(module, function getSupportedCSSProperties(callback) {
                                                                                                                                                                                                                                                                                                                                                                                       return Weinre.getCSSProperties()
                                                                                                                                                                                                                                                                                                                                                                                       }); scooj.defMethod(module, function querySelectorAll( documentId,  selector, callback) {
                                                                                                                                                                                                                                                                                                                                                                                                           Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                                                                                                                           }); 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/target/WiDatabaseImpl.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/target/WiDatabaseImpl": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Weinre = require('../common/Weinre').getClass(); if (typeof Weinre != 'function') throw Error('module ../common/Weinre did not export a class');
                                                                                                        var WiDatabaseImpl = scooj.defClass(module, function WiDatabaseImpl() {
                                                                                                                                            }); scooj.defMethod(module, function getDatabaseTableNames( databaseId, callback) {
                                                                                                                                                                Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                }); scooj.defMethod(module, function executeSQL( databaseId,  query, callback) {
                                                                                                                                                                                    Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                    }); 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/target/WiDOMImpl.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/target/WiDOMImpl": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Weinre = require('../common/Weinre').getClass(); if (typeof Weinre != 'function') throw Error('module ../common/Weinre did not export a class');
                                                                                                        var WiDOMImpl = scooj.defClass(module, function WiDOMImpl() {
                                                                                                                                       }); scooj.defMethod(module, function getChildNodes( nodeId, callback) {
                                                                                                                                                           var node = Weinre.nodeStore.getNode(nodeId)
                                                                                                                                                           if (!node) {
                                                                                                                                                           Weinre.logWarning(arguments.callee.signature  + " passed an invalid nodeId: " + nodeId)
                                                                                                                                                           return
                                                                                                                                                           }
                                                                                                                                                           var children = Weinre.nodeStore.serializeNodeChildren(node, 1)
                                                                                                                                                           Weinre.wi.DOMNotify.setChildNodes(nodeId, children)
                                                                                                                                                           if (callback) {
                                                                                                                                                           Weinre.WeinreTargetCommands.sendClientCallback(callback)
                                                                                                                                                           }
                                                                                                                                                           }); scooj.defMethod(module, function setAttribute( elementId,  name,  value, callback) {
                                                                                                                                                                               var element = Weinre.nodeStore.getNode(elementId)
                                                                                                                                                                               if (!element) {
                                                                                                                                                                               Weinre.logWarning(arguments.callee.signature + " passed an invalid elementId: " + elementId)
                                                                                                                                                                               return
                                                                                                                                                                               }
                                                                                                                                                                               element.setAttribute(name, value)
                                                                                                                                                                               if (callback) {
                                                                                                                                                                               Weinre.WeinreTargetCommands.sendClientCallback(callback)
                                                                                                                                                                               }
                                                                                                                                                                               }); scooj.defMethod(module, function removeAttribute( elementId,  name, callback) {
                                                                                                                                                                                                   var element = Weinre.nodeStore.getNode(elementId)
                                                                                                                                                                                                   if (!element) {
                                                                                                                                                                                                   Weinre.logWarning(arguments.callee.signature + " passed an invalid elementId: " + elementId)
                                                                                                                                                                                                   return
                                                                                                                                                                                                   }
                                                                                                                                                                                                   element.removeAttribute(name)
                                                                                                                                                                                                   if (callback) {
                                                                                                                                                                                                   Weinre.WeinreTargetCommands.sendClientCallback(callback)
                                                                                                                                                                                                   }
                                                                                                                                                                                                   }); scooj.defMethod(module, function setTextNodeValue( nodeId,  value, callback) {
                                                                                                                                                                                                                       var node = Weinre.nodeStore.getNode(nodeId)
                                                                                                                                                                                                                       if (!node) {
                                                                                                                                                                                                                       Weinre.logWarning(arguments.callee.signature + " passed an invalid nodeId: " + nodeId)
                                                                                                                                                                                                                       return
                                                                                                                                                                                                                       }
                                                                                                                                                                                                                       node.nodeValue = value
                                                                                                                                                                                                                       if (callback) {
                                                                                                                                                                                                                       Weinre.WeinreTargetCommands.sendClientCallback(callback)
                                                                                                                                                                                                                       }
                                                                                                                                                                                                                       }); scooj.defMethod(module, function getEventListenersForNode( nodeId, callback) {
                                                                                                                                                                                                                                           Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                           }); scooj.defMethod(module, function copyNode( nodeId, callback) {
                                                                                                                                                                                                                                                               Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                               }); scooj.defMethod(module, function removeNode( nodeId, callback) {
                                                                                                                                                                                                                                                                                   var node = Weinre.nodeStore.getNode(nodeId)
                                                                                                                                                                                                                                                                                   if (!node) {
                                                                                                                                                                                                                                                                                   Weinre.logWarning(arguments.callee.signature + " passed an invalid nodeId: " + nodeId)
                                                                                                                                                                                                                                                                                   return
                                                                                                                                                                                                                                                                                   }
                                                                                                                                                                                                                                                                                   if (!node.parentNode) {
                                                                                                                                                                                                                                                                                   Weinre.logWarning(arguments.callee.signature + " passed a parentless node: " + node)
                                                                                                                                                                                                                                                                                   return
                                                                                                                                                                                                                                                                                   }
                                                                                                                                                                                                                                                                                   node.parentNode.removeChild(node)
                                                                                                                                                                                                                                                                                   if (callback) {
                                                                                                                                                                                                                                                                                   Weinre.WeinreTargetCommands.sendClientCallback(callback)
                                                                                                                                                                                                                                                                                   }
                                                                                                                                                                                                                                                                                   }); scooj.defMethod(module, function changeTagName( nodeId,  newTagName, callback) {
                                                                                                                                                                                                                                                                                                       Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                       }); scooj.defMethod(module, function getOuterHTML( nodeId, callback) {
                                                                                                                                                                                                                                                                                                                           var node = Weinre.nodeStore.getNode(nodeId)
                                                                                                                                                                                                                                                                                                                           if (!node) {
                                                                                                                                                                                                                                                                                                                           Weinre.logWarning(arguments.callee.signature + " passed an invalid nodeId: " + nodeId)
                                                                                                                                                                                                                                                                                                                           return
                                                                                                                                                                                                                                                                                                                           }
                                                                                                                                                                                                                                                                                                                           value = node.outerHTML
                                                                                                                                                                                                                                                                                                                           if (callback) {
                                                                                                                                                                                                                                                                                                                           Weinre.WeinreTargetCommands.sendClientCallback(callback, [value])
                                                                                                                                                                                                                                                                                                                           }
                                                                                                                                                                                                                                                                                                                           }); scooj.defMethod(module, function setOuterHTML( nodeId,  outerHTML, callback) {
                                                                                                                                                                                                                                                                                                                                               var node = Weinre.nodeStore.getNode(nodeId)
                                                                                                                                                                                                                                                                                                                                               if (!node) {
                                                                                                                                                                                                                                                                                                                                               Weinre.logWarning(arguments.callee.signature + " passed an invalid nodeId: " + nodeId)
                                                                                                                                                                                                                                                                                                                                               return
                                                                                                                                                                                                                                                                                                                                               }
                                                                                                                                                                                                                                                                                                                                               node.outerHTML = outerHTML
                                                                                                                                                                                                                                                                                                                                               if (callback) {
                                                                                                                                                                                                                                                                                                                                               Weinre.WeinreTargetCommands.sendClientCallback(callback)
                                                                                                                                                                                                                                                                                                                                               }
                                                                                                                                                                                                                                                                                                                                               }); scooj.defMethod(module, function addInspectedNode( nodeId, callback) {
                                                                                                                                                                                                                                                                                                                                                                   Weinre.nodeStore.addInspectedNode(nodeId)
                                                                                                                                                                                                                                                                                                                                                                   if (callback) {
                                                                                                                                                                                                                                                                                                                                                                   Weinre.WeinreTargetCommands.sendClientCallback(callback)
                                                                                                                                                                                                                                                                                                                                                                   }
                                                                                                                                                                                                                                                                                                                                                                   }); scooj.defMethod(module, function performSearch( query,  runSynchronously, callback) {
                                                                                                                                                                                                                                                                                                                                                                                       Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                                                                                                       }); scooj.defMethod(module, function searchCanceled(callback) {
                                                                                                                                                                                                                                                                                                                                                                                                           Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                                                                                                                           }); scooj.defMethod(module, function pushNodeByPathToFrontend( path, callback) {
                                                                                                                                                                                                                                                                                                                                                                                                                               Weinre.notImplemented(arguments.callee.signature)
                                                                                                                                                                                                                                                                                                                                                                                                                               }); scooj.defMethod(module, function resolveNode( nodeId, callback) {
                                                                                                                                                                                                                                                                                                                                                                                                                                                   var result = Weinre.injectedScript.resolveNode(nodeId)
                                                                                                                                                                                                                                                                                                                                                                                                                                                   if (callback) {
                                                                                                                                                                                                                                                                                                                                                                                                                                                   Weinre.WeinreTargetCommands.sendClientCallback(callback, [result])
                                                                                                                                                                                                                                                                                                                                                                                                                                                   }
                                                                                                                                                                                                                                                                                                                                                                                                                                                   }); scooj.defMethod(module, function getNodeProperties( nodeId,  propertiesArray, callback) {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       var propertiesArray = JSON.stringify(propertiesArray)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       var result = Weinre.injectedScript.getNodeProperties(nodeId, propertiesArray)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       if (callback) {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       Weinre.WeinreTargetCommands.sendClientCallback(callback, [result])
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       }
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       }); scooj.defMethod(module, function getNodePrototypes( nodeId, callback) {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           var result = Weinre.injectedScript.getNodePrototypes(nodeId)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           if (callback) {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           Weinre.WeinreTargetCommands.sendClientCallback(callback, [result])
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           }
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           }); scooj.defMethod(module, function pushNodeToFrontend( objectId, callback) {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               var objectId = JSON.stringify(objectId)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               var result = Weinre.injectedScript.pushNodeToFrontend(objectId)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               if (callback) {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               Weinre.WeinreTargetCommands.sendClientCallback(callback, [result])
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               }
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               }); 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/target/WiDOMStorageImpl.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/target/WiDOMStorageImpl": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Weinre = require('../common/Weinre').getClass(); if (typeof Weinre != 'function') throw Error('module ../common/Weinre did not export a class');
                                                                                                        var Native = require('../common/Native').getClass(); if (typeof Native != 'function') throw Error('module ../common/Native did not export a class');
                                                                                                        var WiDOMStorageImpl = scooj.defClass(module, function WiDOMStorageImpl() {
                                                                                                                                              }); scooj.defMethod(module, function getDOMStorageEntries( storageId, callback) {
                                                                                                                                                                  var storageArea = _getStorageArea(storageId)
                                                                                                                                                                  if (!storageArea) {
                                                                                                                                                                  Weinre.logWarning(arguments.callee.signature + " passed an invalid storageId: " + storageId)
                                                                                                                                                                  return
                                                                                                                                                                  }
                                                                                                                                                                  var result = []
                                                                                                                                                                  var length = storageArea.length
                                                                                                                                                                  for (var i=0; i<length; i++) {
                                                                                                                                                                  var key = storageArea.key(i)
                                                                                                                                                                  var val = storageArea.getItem(key)
                                                                                                                                                                  result.push([key, val])    
                                                                                                                                                                  }
                                                                                                                                                                  if (callback) {
                                                                                                                                                                  Weinre.WeinreTargetCommands.sendClientCallback(callback, [result])
                                                                                                                                                                  }
                                                                                                                                                                  }); scooj.defMethod(module, function setDOMStorageItem( storageId,  key,  value, callback) {
                                                                                                                                                                                      var storageArea = _getStorageArea(storageId)
                                                                                                                                                                                      if (!storageArea) {
                                                                                                                                                                                      Weinre.logWarning(arguments.callee.signature + " passed an invalid storageId: " + storageId)
                                                                                                                                                                                      return
                                                                                                                                                                                      }
                                                                                                                                                                                      var result = true
                                                                                                                                                                                      try {
                                                                                                                                                                                      if (storageArea == window.localStorage) {
                                                                                                                                                                                      Native.LocalStorage_setItem(key, value)
                                                                                                                                                                                      }
                                                                                                                                                                                      else if (storageArea == window.sessionStorage) {
                                                                                                                                                                                      Native.SessionStorage_setItem(key, value)
                                                                                                                                                                                      }
                                                                                                                                                                                      }
                                                                                                                                                                                      catch (e) {
                                                                                                                                                                                      result = false
                                                                                                                                                                                      }
                                                                                                                                                                                      if (callback) {
                                                                                                                                                                                      Weinre.WeinreTargetCommands.sendClientCallback(callback, [result])
                                                                                                                                                                                      }
                                                                                                                                                                                      }); scooj.defMethod(module, function removeDOMStorageItem( storageId,  key, callback) {
                                                                                                                                                                                                          var storageArea = _getStorageArea(storageId)
                                                                                                                                                                                                          if (!storageArea) {
                                                                                                                                                                                                          Weinre.logWarning(arguments.callee.signature + " passed an invalid storageId: " + storageId)
                                                                                                                                                                                                          return
                                                                                                                                                                                                          }
                                                                                                                                                                                                          var result = true
                                                                                                                                                                                                          try {
                                                                                                                                                                                                          if (storageArea == window.localStorage) {
                                                                                                                                                                                                          Native.LocalStorage_removeItem(key)
                                                                                                                                                                                                          }
                                                                                                                                                                                                          else if (storageArea == window.sessionStorage) {
                                                                                                                                                                                                          Native.SessionStorage_removeItem(key)
                                                                                                                                                                                                          }
                                                                                                                                                                                                          }
                                                                                                                                                                                                          catch (e) {
                                                                                                                                                                                                          result = false
                                                                                                                                                                                                          }
                                                                                                                                                                                                          if (callback) {
                                                                                                                                                                                                          Weinre.WeinreTargetCommands.sendClientCallback(callback, [result])
                                                                                                                                                                                                          }
                                                                                                                                                                                                          }); function _getStorageArea(storageId) {
                                                                                                        if (storageId == 1) {
                                                                                                        return window.localStorage
                                                                                                        }
                                                                                                        else if (storageId == 2) {
                                                                                                        return window.sessionStorage
                                                                                                        }
                                                                                                        return null
                                                                                                        }; scooj.defMethod(module, function initialize() {
                                                                                                                           if (window.localStorage) {
                                                                                                                           Weinre.wi.DOMStorageNotify.addDOMStorage({
                                                                                                                                                                    id:             1,
                                                                                                                                                                    host:           window.location.host,
                                                                                                                                                                    isLocalStorage: true
                                                                                                                                                                    })
                                                                                                                           window.localStorage.setItem = function(key, value) {
                                                                                                                           Native.LocalStorage_setItem(key, value)
                                                                                                                           _storageEventHandler({storageArea: window.localStorage})
                                                                                                                           }
                                                                                                                           window.localStorage.removeItem = function(key) {
                                                                                                                           Native.LocalStorage_removeItem(key)
                                                                                                                           _storageEventHandler({storageArea: window.localStorage})
                                                                                                                           }
                                                                                                                           window.localStorage.clear = function() {
                                                                                                                           Native.LocalStorage_clear()
                                                                                                                           _storageEventHandler({storageArea: window.localStorage})
                                                                                                                           }
                                                                                                                           }
                                                                                                                           if (window.sessionStorage) {
                                                                                                                           Weinre.wi.DOMStorageNotify.addDOMStorage({
                                                                                                                                                                    id:             2,
                                                                                                                                                                    host:           window.location.host,
                                                                                                                                                                    isLocalStorage: false
                                                                                                                                                                    })
                                                                                                                           window.sessionStorage.setItem = function(key, value) {
                                                                                                                           Native.SessionStorage_setItem(key, value)
                                                                                                                           _storageEventHandler({storageArea: window.sessionStorage})
                                                                                                                           }
                                                                                                                           window.sessionStorage.removeItem = function(key) {
                                                                                                                           Native.SessionStorage_removeItem(key)
                                                                                                                           _storageEventHandler({storageArea: window.sessionStorage})
                                                                                                                           }
                                                                                                                           window.sessionStorage.clear = function() {
                                                                                                                           Native.SessionStorage_clear()
                                                                                                                           _storageEventHandler({storageArea: window.sessionStorage})
                                                                                                                           }
                                                                                                                           }
                                                                                                                           document.addEventListener("storage", _storageEventHandler, false)
                                                                                                                           }); function _storageEventHandler(event) {
                                                                                                        var storageId
                                                                                                        if (event.storageArea == window.localStorage) {
                                                                                                        storageId = 1
                                                                                                        }
                                                                                                        else if (event.storageArea == window.sessionStorage) {
                                                                                                        storageId = 2
                                                                                                        }
                                                                                                        else {
                                                                                                        return
                                                                                                        }
                                                                                                        Weinre.wi.DOMStorageNotify.updateDOMStorage(storageId)
                                                                                                        }; 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/target/WiInspectorImpl.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/target/WiInspectorImpl": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Weinre = require('../common/Weinre').getClass(); if (typeof Weinre != 'function') throw Error('module ../common/Weinre did not export a class');
                                                                                                        var Timeline = require('../target/Timeline').getClass(); if (typeof Timeline != 'function') throw Error('module ../target/Timeline did not export a class');
                                                                                                        var WiInspectorImpl = scooj.defClass(module, function WiInspectorImpl() {
                                                                                                                                             }); scooj.defMethod(module, function reloadPage(callback) {
                                                                                                                                                                 if (callback) {
                                                                                                                                                                 Weinre.WeinreTargetCommands.sendClientCallback(callback)
                                                                                                                                                                 }
                                                                                                                                                                 window.location.reload()
                                                                                                                                                                 }); scooj.defMethod(module, function highlightDOMNode( nodeId, callback) {
                                                                                                                                                                                     var node = Weinre.nodeStore.getNode(nodeId)
                                                                                                                                                                                     if (!node) {
                                                                                                                                                                                     Weinre.logWarning(arguments.callee.signature + " passed an invalid nodeId: " + nodeId)
                                                                                                                                                                                     return
                                                                                                                                                                                     }
                                                                                                                                                                                     Weinre.elementHighlighter.on(node)
                                                                                                                                                                                     if (callback) {
                                                                                                                                                                                     Weinre.WeinreTargetCommands.sendClientCallback(callback)
                                                                                                                                                                                     }
                                                                                                                                                                                     }); scooj.defMethod(module, function hideDOMNodeHighlight(callback) {
                                                                                                                                                                                                         Weinre.elementHighlighter.off()
                                                                                                                                                                                                         if (callback) {
                                                                                                                                                                                                         Weinre.WeinreTargetCommands.sendClientCallback(callback)
                                                                                                                                                                                                         }
                                                                                                                                                                                                         }); scooj.defMethod(module, function startTimelineProfiler(callback) {
                                                                                                                                                                                                                             Timeline.start()
                                                                                                                                                                                                                             Weinre.wi.TimelineNotify.timelineProfilerWasStarted()
                                                                                                                                                                                                                             if (callback) {
                                                                                                                                                                                                                             Weinre.WeinreTargetCommands.sendClientCallback(callback)
                                                                                                                                                                                                                             }
                                                                                                                                                                                                                             }); scooj.defMethod(module, function stopTimelineProfiler(callback) {
                                                                                                                                                                                                                                                 Timeline.stop()
                                                                                                                                                                                                                                                 Weinre.wi.TimelineNotify.timelineProfilerWasStopped()
                                                                                                                                                                                                                                                 if (callback) {
                                                                                                                                                                                                                                                 Weinre.WeinreTargetCommands.sendClientCallback(callback)
                                                                                                                                                                                                                                                 }
                                                                                                                                                                                                                                                 }); 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/target/WiRuntimeImpl.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/target/WiRuntimeImpl": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Weinre = require('../common/Weinre').getClass(); if (typeof Weinre != 'function') throw Error('module ../common/Weinre did not export a class');
                                                                                                        var WiRuntimeImpl = scooj.defClass(module, function WiRuntimeImpl() {
                                                                                                                                           }); scooj.defMethod(module, function evaluate( expression,  objectGroup,  includeCommandLineAPI, callback) {
                                                                                                                                                               var result = Weinre.injectedScript.evaluate(expression, objectGroup, includeCommandLineAPI)
                                                                                                                                                               if (callback) {
                                                                                                                                                               Weinre.WeinreTargetCommands.sendClientCallback(callback, [result])
                                                                                                                                                               }
                                                                                                                                                               }); scooj.defMethod(module, function getCompletions( expression,  includeCommandLineAPI, callback) {
                                                                                                                                                                                   var result = Weinre.injectedScript.getCompletions(expression, includeCommandLineAPI)
                                                                                                                                                                                   if (callback) {
                                                                                                                                                                                   Weinre.WeinreTargetCommands.sendClientCallback(callback, [result])
                                                                                                                                                                                   }
                                                                                                                                                                                   }); scooj.defMethod(module, function getProperties( objectId,  ignoreHasOwnProperty,  abbreviate, callback) {
                                                                                                                                                                                                       var objectId = JSON.stringify(objectId)
                                                                                                                                                                                                       var result = Weinre.injectedScript.getProperties(objectId, ignoreHasOwnProperty, abbreviate)
                                                                                                                                                                                                       if (callback) {
                                                                                                                                                                                                       Weinre.WeinreTargetCommands.sendClientCallback(callback, [result])
                                                                                                                                                                                                       }
                                                                                                                                                                                                       }); scooj.defMethod(module, function setPropertyValue( objectId,  propertyName,  expression, callback) {
                                                                                                                                                                                                                           var objectId = JSON.stringify(objectId)
                                                                                                                                                                                                                           var result = Weinre.injectedScript.setPropertyValue(objectId, propertyName, expression)
                                                                                                                                                                                                                           if (callback) {
                                                                                                                                                                                                                           Weinre.WeinreTargetCommands.sendClientCallback(callback, [result])
                                                                                                                                                                                                                           }
                                                                                                                                                                                                                           }); scooj.defMethod(module, function releaseWrapperObjectGroup( injectedScriptId,  objectGroup, callback) {
                                                                                                                                                                                                                                               var result = Weinre.injectedScript.releaseWrapperObjectGroup(objectGroupName)
                                                                                                                                                                                                                                               if (callback) {
                                                                                                                                                                                                                                               Weinre.WeinreTargetCommands.sendClientCallback(callback, [result])
                                                                                                                                                                                                                                               }
                                                                                                                                                                                                                                               }); 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/target/WeinreTargetEventsImpl.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/target/WeinreTargetEventsImpl": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Weinre = require('../common/Weinre').getClass(); if (typeof Weinre != 'function') throw Error('module ../common/Weinre did not export a class');
                                                                                                        var Callback = require('../common/Callback').getClass(); if (typeof Callback != 'function') throw Error('module ../common/Callback did not export a class');
                                                                                                        var Console = require('./Console').getClass(); if (typeof Console != 'function') throw Error('module ./Console did not export a class');
                                                                                                        var WeinreTargetEventsImpl = scooj.defClass(module, function WeinreTargetEventsImpl() {
                                                                                                                                                    }); scooj.defMethod(module, function connectionCreated( clientChannel,  targetChannel) {
                                                                                                                                                                        var message = "weinre: target " + targetChannel + " connected to client " + clientChannel
                                                                                                                                                                        Weinre.logInfo(message)
                                                                                                                                                                        var oldValue = Console.useRemote(true)
                                                                                                                                                                        Weinre.target.setDocument()
                                                                                                                                                                        Weinre.wi.TimelineNotify.timelineProfilerWasStopped()
                                                                                                                                                                        Weinre.wi.DOMStorage.initialize()
                                                                                                                                                                        }); scooj.defMethod(module, function connectionDestroyed( clientChannel,  targetChannel) {
                                                                                                                                                                                            var message = "weinre: target " + targetChannel + " disconnected from client " + clientChannel
                                                                                                                                                                                            Weinre.logInfo(message)
                                                                                                                                                                                            var oldValue = Console.useRemote(false)
                                                                                                                                                                                            }); scooj.defMethod(module, function sendCallback( callbackId,  result) {
                                                                                                                                                                                                                Callback.invoke(callbackId, result)
                                                                                                                                                                                                                }); 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/target/NodeStore.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/target/NodeStore": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Weinre = require('../common/Weinre').getClass(); if (typeof Weinre != 'function') throw Error('module ../common/Weinre did not export a class');
                                                                                                        var IDGenerator = require('../common/IDGenerator').getClass(); if (typeof IDGenerator != 'function') throw Error('module ../common/IDGenerator did not export a class');
                                                                                                        var NodeStore = scooj.defClass(module, function NodeStore() {
                                                                                                                                       this.__nodeMap      = {}
                                                                                                                                       this.__nodeDataMap  = {}
                                                                                                                                       this.inspectedNodes = []
                                                                                                                                       document.addEventListener("DOMSubtreeModified",       handleDOMSubtreeModified, false)
                                                                                                                                       document.addEventListener("DOMNodeInserted",          handleDOMNodeInserted, false)
                                                                                                                                       document.addEventListener("DOMNodeRemoved",           handleDOMNodeRemoved, false)
                                                                                                                                       document.addEventListener("DOMAttrModified",          handleDOMAttrModified, false)
                                                                                                                                       document.addEventListener("DOMCharacterDataModified", handleDOMCharacterDataModified, false)
                                                                                                                                       }); scooj.defMethod(module, function addInspectedNode(nodeId) {
                                                                                                                                                           this.inspectedNodes.unshift(nodeId)
                                                                                                                                                           if (this.inspectedNodes.length > 5) {
                                                                                                                                                           this.inspectedNodes = this.inspectedNodes.slice(0,5)
                                                                                                                                                           }
                                                                                                                                                           }); scooj.defMethod(module, function getInspectedNode(index) {
                                                                                                                                                                               return this.inspectedNodes[index]
                                                                                                                                                                               }); scooj.defMethod(module, function getNode(nodeId) {
                                                                                                                                                                                                   return this.__nodeMap[nodeId]
                                                                                                                                                                                                   }); scooj.defMethod(module, function checkNodeId(node) {
                                                                                                                                                                                                                       return IDGenerator.checkId(node)
                                                                                                                                                                                                                       }); scooj.defMethod(module, function getNodeId(node) {
                                                                                                                                                                                                                                           var id = this.checkNodeId(node)
                                                                                                                                                                                                                                           if (id) {
                                                                                                                                                                                                                                           return id
                                                                                                                                                                                                                                           }
                                                                                                                                                                                                                                           return IDGenerator.getId(node, this.__nodeMap)    
                                                                                                                                                                                                                                           }); scooj.defMethod(module, function getNodeData(nodeId, depth) {
                                                                                                                                                                                                                                                               return this.serializeNode(this.getNode(nodeId), depth)
                                                                                                                                                                                                                                                               }); scooj.defMethod(module, function getPreviousSiblingId(node) {
                                                                                                                                                                                                                                                                                   while (true) {
                                                                                                                                                                                                                                                                                   var sib = node.previousSibling
                                                                                                                                                                                                                                                                                   if (!sib) return 0
                                                                                                                                                                                                                                                                                   var id = this.checkNodeId(sib)
                                                                                                                                                                                                                                                                                   if (id) return id
                                                                                                                                                                                                                                                                                   node = sib
                                                                                                                                                                                                                                                                                   }
                                                                                                                                                                                                                                                                                   }); scooj.defMethod(module, function nextNodeId() {
                                                                                                                                                                                                                                                                                                       return "" + IDGenerator.next()
                                                                                                                                                                                                                                                                                                       }); scooj.defMethod(module, function serializeNode(node, depth) {
                                                                                                                                                                                                                                                                                                                           var nodeName  = ""
                                                                                                                                                                                                                                                                                                                           var nodeValue = null
                                                                                                                                                                                                                                                                                                                           var localName = null
                                                                                                                                                                                                                                                                                                                           var id = this.getNodeId(node) 
                                                                                                                                                                                                                                                                                                                           switch(node.nodeType) {
                                                                                                                                                                                                                                                                                                                           case Node.TEXT_NODE:    
                                                                                                                                                                                                                                                                                                                           case Node.COMMENT_NODE:
                                                                                                                                                                                                                                                                                                                           case Node.CDATA_SECTION_NODE:
                                                                                                                                                                                                                                                                                                                           nodeValue = node.nodeValue
                                                                                                                                                                                                                                                                                                                           break
                                                                                                                                                                                                                                                                                                                           case Node.ATTRIBUTE_NODE:
                                                                                                                                                                                                                                                                                                                           localName = node.localName
                                                                                                                                                                                                                                                                                                                           break
                                                                                                                                                                                                                                                                                                                           case Node.DOCUMENT_FRAGMENT_NODE:
                                                                                                                                                                                                                                                                                                                           break
                                                                                                                                                                                                                                                                                                                           case Node.DOCUMENT_NODE:
                                                                                                                                                                                                                                                                                                                           case Node.ELEMENT_NODE:
                                                                                                                                                                                                                                                                                                                           default:
                                                                                                                                                                                                                                                                                                                           nodeName  = node.nodeName
                                                                                                                                                                                                                                                                                                                           localName = node.localName
                                                                                                                                                                                                                                                                                                                           break
                                                                                                                                                                                                                                                                                                                           }
                                                                                                                                                                                                                                                                                                                           var nodeData = {
                                                                                                                                                                                                                                                                                                                           id:        id,
                                                                                                                                                                                                                                                                                                                           nodeType:  node.nodeType,
                                                                                                                                                                                                                                                                                                                           nodeName:  nodeName,
                                                                                                                                                                                                                                                                                                                           localName: localName,
                                                                                                                                                                                                                                                                                                                           nodeValue: nodeValue
                                                                                                                                                                                                                                                                                                                           }
                                                                                                                                                                                                                                                                                                                           if (node.nodeType == Node.ELEMENT_NODE || node.nodeType == Node.DOCUMENT_NODE || node.nodeType == Node.DOCUMENT_FRAGMENT_NODE) {
                                                                                                                                                                                                                                                                                                                           nodeData.childNodeCount = this.childNodeCount(node)
                                                                                                                                                                                                                                                                                                                           var children = this.serializeNodeChildren(node, depth)
                                                                                                                                                                                                                                                                                                                           if (children.length) {
                                                                                                                                                                                                                                                                                                                           nodeData.children = children
                                                                                                                                                                                                                                                                                                                           }
                                                                                                                                                                                                                                                                                                                           if (node.nodeType == Node.ELEMENT_NODE) {
                                                                                                                                                                                                                                                                                                                           nodeData.attributes = []
                                                                                                                                                                                                                                                                                                                           for (var i=0; i<node.attributes.length; i++) {
                                                                                                                                                                                                                                                                                                                           nodeData.attributes.push(node.attributes[i].nodeName)
                                                                                                                                                                                                                                                                                                                           nodeData.attributes.push(node.attributes[i].nodeValue)
                                                                                                                                                                                                                                                                                                                           }
                                                                                                                                                                                                                                                                                                                           } 
                                                                                                                                                                                                                                                                                                                           else if (node.nodeType == Node.DOCUMENT_NODE) {
                                                                                                                                                                                                                                                                                                                           nodeData.documentURL = window.location.href
                                                                                                                                                                                                                                                                                                                           }
                                                                                                                                                                                                                                                                                                                           } 
                                                                                                                                                                                                                                                                                                                           else if (node.nodeType == Node.DOCUMENT_TYPE_NODE) {
                                                                                                                                                                                                                                                                                                                           nodeData.publicId       = node.publicId
                                                                                                                                                                                                                                                                                                                           nodeData.systemId       = node.systemId
                                                                                                                                                                                                                                                                                                                           nodeData.internalSubset = node.internalSubset
                                                                                                                                                                                                                                                                                                                           } 
                                                                                                                                                                                                                                                                                                                           else if (node.nodeType == Node.ATTRIBUTE_NODE) {
                                                                                                                                                                                                                                                                                                                           nodeData.name  = node.nodeName
                                                                                                                                                                                                                                                                                                                           nodeData.value = node.nodeValue
                                                                                                                                                                                                                                                                                                                           }
                                                                                                                                                                                                                                                                                                                           return nodeData
                                                                                                                                                                                                                                                                                                                           }); scooj.defMethod(module, function serializeNodeChildren(node, depth) {
                                                                                                                                                                                                                                                                                                                                               var result   = []
                                                                                                                                                                                                                                                                                                                                               var childIds = this.childNodeIds(node)
                                                                                                                                                                                                                                                                                                                                               if (depth == 0) {
                                                                                                                                                                                                                                                                                                                                               if (childIds.length == 1) {
                                                                                                                                                                                                                                                                                                                                               var childNode = this.getNode(childIds[0])
                                                                                                                                                                                                                                                                                                                                               if (childNode.nodeType == Node.TEXT_NODE) {
                                                                                                                                                                                                                                                                                                                                               result.push(this.serializeNode(childNode))
                                                                                                                                                                                                                                                                                                                                               }
                                                                                                                                                                                                                                                                                                                                               }
                                                                                                                                                                                                                                                                                                                                               return result
                                                                                                                                                                                                                                                                                                                                               }
                                                                                                                                                                                                                                                                                                                                               depth--;
                                                                                                                                                                                                                                                                                                                                               for (var i=0; i<childIds.length; i++) {
                                                                                                                                                                                                                                                                                                                                               result.push(this.serializeNode(this.getNode(childIds[i]), depth))
                                                                                                                                                                                                                                                                                                                                               }
                                                                                                                                                                                                                                                                                                                                               return result
                                                                                                                                                                                                                                                                                                                                               }); scooj.defMethod(module, function childNodeCount(node) {
                                                                                                                                                                                                                                                                                                                                                                   return this.childNodeIds(node).length
                                                                                                                                                                                                                                                                                                                                                                   }); scooj.defMethod(module, function childNodeIds(node) {
                                                                                                                                                                                                                                                                                                                                                                                       var ids = []
                                                                                                                                                                                                                                                                                                                                                                                       for (var i=0; i<node.childNodes.length; i++) {
                                                                                                                                                                                                                                                                                                                                                                                       if (this.isToBeSkipped(node.childNodes[i])) continue
                                                                                                                                                                                                                                                                                                                                                                                       ids.push(this.getNodeId(node.childNodes[i]))
                                                                                                                                                                                                                                                                                                                                                                                       }
                                                                                                                                                                                                                                                                                                                                                                                       return ids
                                                                                                                                                                                                                                                                                                                                                                                       }); scooj.defMethod(module, function isToBeSkipped(node) {
                                                                                                                                                                                                                                                                                                                                                                                                           if (!node) return true
                                                                                                                                                                                                                                                                                                                                                                                                           if (node.__weinreHighlighter) return true 
                                                                                                                                                                                                                                                                                                                                                                                                           if (node.nodeType != Node.TEXT_NODE) return false
                                                                                                                                                                                                                                                                                                                                                                                                           return !!node.nodeValue.match(/^\s*$/) 
                                                                                                                                                                                                                                                                                                                                                                                                           }); function handleDOMSubtreeModified(event) {
                                                                                                        if (!event.attrChange) return
                                                                                                        NodeStore.handleDOMAttrModified(event)
                                                                                                        }; function handleDOMNodeInserted(event) {
                                                                                                        var targetId = Weinre.nodeStore.checkNodeId(event.target)
                                                                                                        var parentId = Weinre.nodeStore.checkNodeId(event.relatedNode)
                                                                                                        if (!parentId) return
                                                                                                        var child = Weinre.nodeStore.serializeNode(event.target, 0)
                                                                                                        var previous = Weinre.nodeStore.getPreviousSiblingId(event.target)
                                                                                                        Weinre.wi.DOMNotify.childNodeInserted(parentId, previous, child)
                                                                                                        }; function handleDOMNodeRemoved(event) {
                                                                                                        var targetId = Weinre.nodeStore.checkNodeId(event.target)
                                                                                                        var parentId = Weinre.nodeStore.checkNodeId(event.relatedNode)
                                                                                                        if (!parentId) return
                                                                                                        if (targetId) {
                                                                                                        Weinre.wi.DOMNotify.childNodeRemoved(parentId, targetId)
                                                                                                        }
                                                                                                        else {
                                                                                                        var childCount = Weinre.nodeStore.childNodeCount(event.relatedNode)
                                                                                                        Weinre.wi.DOMNotify.childNodeCountUpdated(parentId, childCount)
                                                                                                        }
                                                                                                        }; function handleDOMAttrModified(event) {
                                                                                                        var targetId = Weinre.nodeStore.checkNodeId(event.target)
                                                                                                        if (!targetId) return
                                                                                                        attrs = []
                                                                                                        for (var i=0; i<event.target.attributes.length; i++) {
                                                                                                        attrs.push(event.target.attributes[i].name)
                                                                                                        attrs.push(event.target.attributes[i].value)
                                                                                                        }
                                                                                                        Weinre.wi.DOMNotify.attributesUpdated(targetId, attrs)
                                                                                                        }; function handleDOMCharacterDataModified(event) {
                                                                                                        var targetId = Weinre.nodeStore.checkNodeId(event.target)
                                                                                                        if (!targetId) return
                                                                                                        Weinre.wi.DOMNotify.characterDataModified(targetId, event.newValue)
                                                                                                        }; 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/target/CSSStore.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/target/CSSStore": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var IDGenerator = require('../common/IDGenerator').getClass(); if (typeof IDGenerator != 'function') throw Error('module ../common/IDGenerator did not export a class');
                                                                                                        var Weinre = require('../common/Weinre').getClass(); if (typeof Weinre != 'function') throw Error('module ../common/Weinre did not export a class');
                                                                                                        var CSSStore = scooj.defClass(module, function CSSStore() {
                                                                                                                                      this.styleSheetMap = {}
                                                                                                                                      this.styleRuleMap  = {}
                                                                                                                                      this.styleDeclMap  = {}
                                                                                                                                      this.testElement = document.createElement("div")
                                                                                                                                      }); 
                                                                                                        var Properties = []
                                                                                                        scooj.defStaticMethod(module, function addCSSProperties(properties) {
                                                                                                                              Properties = properties
                                                                                                                              }); scooj.defMethod(module, function getInlineStyle(node) {
                                                                                                                                                  var styleObject = this._buildMirrorForStyle(node.style, true)
                                                                                                                                                  for (var i=0; i<styleObject.cssProperties.length; i++) {
                                                                                                                                                  styleObject.cssProperties[i].status = "style"
                                                                                                                                                  }
                                                                                                                                                  return styleObject
                                                                                                                                                  }); scooj.defMethod(module, function getComputedStyle(node) {
                                                                                                                                                                      if (!node) return {}
                                                                                                                                                                      if (node.nodeType != Node.ELEMENT_NODE) return {}
                                                                                                                                                                      var styleObject = this._buildMirrorForStyle(window.getComputedStyle(node), false)
                                                                                                                                                                      return styleObject
                                                                                                                                                                      }); scooj.defMethod(module, function getMatchedCSSRules(node) {
                                                                                                                                                                                          var result = []
                                                                                                                                                                                          for (var i=0; i<document.styleSheets.length; i++) {
                                                                                                                                                                                          var styleSheet = document.styleSheets[i]
                                                                                                                                                                                          if (!styleSheet.cssRules) continue
                                                                                                                                                                                          for (var j=0; j<styleSheet.cssRules.length; j++) {
                                                                                                                                                                                          var cssRule = styleSheet.cssRules[j]
                                                                                                                                                                                          if (!_elementMatchesSelector(node, cssRule.selectorText)) continue
                                                                                                                                                                                          var object = {}
                                                                                                                                                                                          object.ruleId = this._getStyleRuleId(cssRule)
                                                                                                                                                                                          object.selectorText = cssRule.selectorText
                                                                                                                                                                                          object.style = this._buildMirrorForStyle(cssRule.style, true)
                                                                                                                                                                                          result.push(object)
                                                                                                                                                                                          }
                                                                                                                                                                                          }
                                                                                                                                                                                          return result
                                                                                                                                                                                          }); scooj.defMethod(module, function getStyleAttributes(node) {
                                                                                                                                                                                                              var result = {}
                                                                                                                                                                                                              return result
                                                                                                                                                                                                              }); scooj.defMethod(module, function getPseudoElements(node) {
                                                                                                                                                                                                                                  var result = []
                                                                                                                                                                                                                                  return result
                                                                                                                                                                                                                                  }); scooj.defMethod(module, function setPropertyText(styleId, propertyIndex, text, overwrite) {
                                                                                                                                                                                                                                                      var styleDecl = Weinre.cssStore._getStyleDecl(styleId)
                                                                                                                                                                                                                                                      if (!styleDecl) {
                                                                                                                                                                                                                                                      Weinre.logWarning("requested style not available: " + styleId)
                                                                                                                                                                                                                                                      return null
                                                                                                                                                                                                                                                      }
                                                                                                                                                                                                                                                      var mirror = styleDecl.__weinre__mirror
                                                                                                                                                                                                                                                      if (!mirror) {
                                                                                                                                                                                                                                                      Weinre.logWarning("requested mirror not available: " + styleId)
                                                                                                                                                                                                                                                      return null
                                                                                                                                                                                                                                                      }
                                                                                                                                                                                                                                                      var properties = mirror.cssProperties
                                                                                                                                                                                                                                                      var propertyMirror = this._parseProperty(text)
                                                                                                                                                                                                                                                      if (null == propertyMirror) {
                                                                                                                                                                                                                                                      this._removePropertyFromMirror(mirror, propertyIndex)
                                                                                                                                                                                                                                                      properties = mirror.cssProperties
                                                                                                                                                                                                                                                      }
                                                                                                                                                                                                                                                      else {
                                                                                                                                                                                                                                                      this._removePropertyFromMirror(mirror, propertyIndex)
                                                                                                                                                                                                                                                      properties = mirror.cssProperties
                                                                                                                                                                                                                                                      var propertyIndices = {}
                                                                                                                                                                                                                                                      for (var i=0; i<properties.length; i++) {
                                                                                                                                                                                                                                                      propertyIndices[properties[i].name] = i
                                                                                                                                                                                                                                                      }
                                                                                                                                                                                                                                                      for (var i=0; i<propertyMirror.cssProperties.length; i++) {
                                                                                                                                                                                                                                                      if (propertyIndices[propertyMirror.cssProperties[i].name] != null) {
                                                                                                                                                                                                                                                      properties[propertyIndices[propertyMirror.cssProperties[i].name]] = propertyMirror.cssProperties[i]
                                                                                                                                                                                                                                                      }
                                                                                                                                                                                                                                                      else {
                                                                                                                                                                                                                                                      properties.push(propertyMirror.cssProperties[i])
                                                                                                                                                                                                                                                      }
                                                                                                                                                                                                                                                      }
                                                                                                                                                                                                                                                      for (var key in propertyMirror.shorthandValues) {
                                                                                                                                                                                                                                                      mirror.shorthandValues[key] = propertyMirror.shorthandValues[key]
                                                                                                                                                                                                                                                      }
                                                                                                                                                                                                                                                      }
                                                                                                                                                                                                                                                      properties.sort(function(p1,p2) {
                                                                                                                                                                                                                                                                      if      (p1.name < p2.name) return -1
                                                                                                                                                                                                                                                                      else if (p1.name > p2.name) return  1
                                                                                                                                                                                                                                                                      else return 0
                                                                                                                                                                                                                                                                      })
                                                                                                                                                                                                                                                      this._setStyleFromMirror(styleDecl)
                                                                                                                                                                                                                                                      return mirror
                                                                                                                                                                                                                                                      }); scooj.defMethod(module, function _removePropertyFromMirror(mirror, index) {
                                                                                                                                                                                                                                                                          var properties = mirror.cssProperties
                                                                                                                                                                                                                                                                          if (index >= properties.length) return
                                                                                                                                                                                                                                                                          var property = properties[index]
                                                                                                                                                                                                                                                                          properties[index] = null
                                                                                                                                                                                                                                                                          if (mirror.shorthandValues[property.name]) {
                                                                                                                                                                                                                                                                          delete mirror.shorthandValues[property.name]
                                                                                                                                                                                                                                                                          for (var i=0; i<properties.length; i++) {
                                                                                                                                                                                                                                                                          if (properties[i]) {
                                                                                                                                                                                                                                                                          if (properties[i].shorthandName == property.name) {
                                                                                                                                                                                                                                                                          properties[i] = null
                                                                                                                                                                                                                                                                          }
                                                                                                                                                                                                                                                                          }
                                                                                                                                                                                                                                                                          }
                                                                                                                                                                                                                                                                          }
                                                                                                                                                                                                                                                                          var newProperties = []
                                                                                                                                                                                                                                                                          for (var i=0; i<properties.length; i++) {
                                                                                                                                                                                                                                                                          if (properties[i]) newProperties.push(properties[i])
                                                                                                                                                                                                                                                                          }
                                                                                                                                                                                                                                                                          mirror.cssProperties = newProperties
                                                                                                                                                                                                                                                                          }); scooj.defMethod(module, function toggleProperty(styleId, propertyIndex, disable) {
                                                                                                                                                                                                                                                                                              var styleDecl = Weinre.cssStore._getStyleDecl(styleId)
                                                                                                                                                                                                                                                                                              if (!styleDecl) {
                                                                                                                                                                                                                                                                                              Weinre.logWarning("requested style not available: " + styleId)
                                                                                                                                                                                                                                                                                              return null
                                                                                                                                                                                                                                                                                              }
                                                                                                                                                                                                                                                                                              var mirror = styleDecl.__weinre__mirror
                                                                                                                                                                                                                                                                                              if (!mirror) {
                                                                                                                                                                                                                                                                                              Weinre.logWarning("requested mirror not available: " + styleId)
                                                                                                                                                                                                                                                                                              return null
                                                                                                                                                                                                                                                                                              }
                                                                                                                                                                                                                                                                                              var cssProperty = mirror.cssProperties[propertyIndex]
                                                                                                                                                                                                                                                                                              if (!cssProperty) {
                                                                                                                                                                                                                                                                                              Weinre.logWarning("requested property not available: " + styleId + ": " + propertyIndex)
                                                                                                                                                                                                                                                                                              return null
                                                                                                                                                                                                                                                                                              }
                                                                                                                                                                                                                                                                                              if (disable) {
                                                                                                                                                                                                                                                                                              cssProperty.status = "disabled"
                                                                                                                                                                                                                                                                                              }
                                                                                                                                                                                                                                                                                              else {
                                                                                                                                                                                                                                                                                              cssProperty.status = "active"
                                                                                                                                                                                                                                                                                              }
                                                                                                                                                                                                                                                                                              this._setStyleFromMirror(styleDecl)
                                                                                                                                                                                                                                                                                              return mirror
                                                                                                                                                                                                                                                                                              }); scooj.defMethod(module, function _setStyleFromMirror(styleDecl) {
                                                                                                                                                                                                                                                                                                                  var cssText = []
                                                                                                                                                                                                                                                                                                                  var cssProperties = styleDecl.__weinre__mirror.cssProperties
                                                                                                                                                                                                                                                                                                                  var cssText = ""
                                                                                                                                                                                                                                                                                                                  for (var i=0; i<cssProperties.length; i++) {
                                                                                                                                                                                                                                                                                                                  var property = cssProperties[i]
                                                                                                                                                                                                                                                                                                                  if (!property.parsedOk) continue
                                                                                                                                                                                                                                                                                                                  if (property.status == "disabled") continue
                                                                                                                                                                                                                                                                                                                  if (property.shorthandName) continue
                                                                                                                                                                                                                                                                                                                  cssText += property.name + ": " + property.value
                                                                                                                                                                                                                                                                                                                  if (property.priority == "important") {
                                                                                                                                                                                                                                                                                                                  cssText += " !important; "
                                                                                                                                                                                                                                                                                                                  }
                                                                                                                                                                                                                                                                                                                  else {
                                                                                                                                                                                                                                                                                                                  cssText += "; "
                                                                                                                                                                                                                                                                                                                  }
                                                                                                                                                                                                                                                                                                                  }
                                                                                                                                                                                                                                                                                                                  styleDecl.cssText = cssText
                                                                                                                                                                                                                                                                                                                  }); scooj.defMethod(module, function _buildMirrorForStyle(styleDecl, bind) {
                                                                                                                                                                                                                                                                                                                                      var result = {
                                                                                                                                                                                                                                                                                                                                      properties:    {},
                                                                                                                                                                                                                                                                                                                                      cssProperties: []
                                                                                                                                                                                                                                                                                                                                      }
                                                                                                                                                                                                                                                                                                                                      if (!styleDecl) return result
                                                                                                                                                                                                                                                                                                                                      if (bind) {
                                                                                                                                                                                                                                                                                                                                      result.styleId = this._getStyleDeclId(styleDecl)
                                                                                                                                                                                                                                                                                                                                      styleDecl.__weinre__mirror = result
                                                                                                                                                                                                                                                                                                                                      }
                                                                                                                                                                                                                                                                                                                                      result.properties.width  = styleDecl.getPropertyValue("width")  || ""
                                                                                                                                                                                                                                                                                                                                      result.properties.height = styleDecl.getPropertyValue("height") || ""
                                                                                                                                                                                                                                                                                                                                      result.cssText           = styleDecl.cssText 
                                                                                                                                                                                                                                                                                                                                      result.shorthandValues = {}
                                                                                                                                                                                                                                                                                                                                      var properties = []
                                                                                                                                                                                                                                                                                                                                      if (styleDecl) {
                                                                                                                                                                                                                                                                                                                                      for (var i=0; i < styleDecl.length; i++) {
                                                                                                                                                                                                                                                                                                                                      var property = {}
                                                                                                                                                                                                                                                                                                                                      var name = styleDecl.item(i)
                                                                                                                                                                                                                                                                                                                                      property.name          = name
                                                                                                                                                                                                                                                                                                                                      property.priority      = styleDecl.getPropertyPriority(name)
                                                                                                                                                                                                                                                                                                                                      property.implicit      = styleDecl.isPropertyImplicit(name)
                                                                                                                                                                                                                                                                                                                                      property.shorthandName = styleDecl.getPropertyShorthand(name) || ""
                                                                                                                                                                                                                                                                                                                                      property.status        = property.shorthandName ? "style" : "active"
                                                                                                                                                                                                                                                                                                                                      property.parsedOk      = true
                                                                                                                                                                                                                                                                                                                                      property.value         = styleDecl.getPropertyValue(name)
                                                                                                                                                                                                                                                                                                                                      properties.push(property);
                                                                                                                                                                                                                                                                                                                                      if (property.shorthandName) {
                                                                                                                                                                                                                                                                                                                                      var shorthandName = property.shorthandName
                                                                                                                                                                                                                                                                                                                                      if (!result.shorthandValues[shorthandName]) {
                                                                                                                                                                                                                                                                                                                                      result.shorthandValues[shorthandName] = styleDecl.getPropertyValue(shorthandName)
                                                                                                                                                                                                                                                                                                                                      property = {}
                                                                                                                                                                                                                                                                                                                                      property.name          = shorthandName
                                                                                                                                                                                                                                                                                                                                      property.priority      = styleDecl.getPropertyPriority(shorthandName)
                                                                                                                                                                                                                                                                                                                                      property.implicit      = styleDecl.isPropertyImplicit(shorthandName)
                                                                                                                                                                                                                                                                                                                                      property.shorthandName = ""
                                                                                                                                                                                                                                                                                                                                      property.status        = "active"
                                                                                                                                                                                                                                                                                                                                      property.parsedOk      = true
                                                                                                                                                                                                                                                                                                                                      property.value         = styleDecl.getPropertyValue(name)
                                                                                                                                                                                                                                                                                                                                      properties.push(property);
                                                                                                                                                                                                                                                                                                                                      }
                                                                                                                                                                                                                                                                                                                                      }
                                                                                                                                                                                                                                                                                                                                      }
                                                                                                                                                                                                                                                                                                                                      }
                                                                                                                                                                                                                                                                                                                                      properties.sort(function(p1,p2) {
                                                                                                                                                                                                                                                                                                                                                      if      (p1.name < p2.name) return -1
                                                                                                                                                                                                                                                                                                                                                      else if (p1.name > p2.name) return  1
                                                                                                                                                                                                                                                                                                                                                      else return 0
                                                                                                                                                                                                                                                                                                                                                      })
                                                                                                                                                                                                                                                                                                                                      result.cssProperties   = properties
                                                                                                                                                                                                                                                                                                                                      return result
                                                                                                                                                                                                                                                                                                                                      }); scooj.defMethod(module, function _parseProperty(string) {
                                                                                                                                                                                                                                                                                                                                                          var testStyleDecl = this.testElement.style
                                                                                                                                                                                                                                                                                                                                                          try {
                                                                                                                                                                                                                                                                                                                                                          testStyleDecl.cssText = string
                                                                                                                                                                                                                                                                                                                                                          if (testStyleDecl.cssText != "") {
                                                                                                                                                                                                                                                                                                                                                          return this._buildMirrorForStyle(testStyleDecl, false)
                                                                                                                                                                                                                                                                                                                                                          }
                                                                                                                                                                                                                                                                                                                                                          }
                                                                                                                                                                                                                                                                                                                                                          catch(e) {
                                                                                                                                                                                                                                                                                                                                                          }
                                                                                                                                                                                                                                                                                                                                                          var propertyPattern = /\s*(.+)\s*:\s*(.+)\s*(!important)?\s*;/
                                                                                                                                                                                                                                                                                                                                                          var match = propertyPattern.exec(string)
                                                                                                                                                                                                                                                                                                                                                          if (!match) return null
                                                                                                                                                                                                                                                                                                                                                          match[3] = (match[3] == "!important") ? "important" : ""
                                                                                                                                                                                                                                                                                                                                                          var property = {}
                                                                                                                                                                                                                                                                                                                                                          property.name          = match[1]
                                                                                                                                                                                                                                                                                                                                                          property.priority      = match[3]
                                                                                                                                                                                                                                                                                                                                                          property.implicit      = true
                                                                                                                                                                                                                                                                                                                                                          property.shorthandName = ""
                                                                                                                                                                                                                                                                                                                                                          property.status        = "inactive"
                                                                                                                                                                                                                                                                                                                                                          property.parsedOk      = false
                                                                                                                                                                                                                                                                                                                                                          property.value         = match[2]
                                                                                                                                                                                                                                                                                                                                                          var result = {}
                                                                                                                                                                                                                                                                                                                                                          result.width           = 0
                                                                                                                                                                                                                                                                                                                                                          result.height          = 0
                                                                                                                                                                                                                                                                                                                                                          result.shorthandValues = 0
                                                                                                                                                                                                                                                                                                                                                          result.cssProperties   = [ property ]
                                                                                                                                                                                                                                                                                                                                                          return result
                                                                                                                                                                                                                                                                                                                                                          }); scooj.defMethod(module, function _getStyleSheet(id) {
                                                                                                                                                                                                                                                                                                                                                                              return _getMappableObject(id, this.styleSheetMap)
                                                                                                                                                                                                                                                                                                                                                                              }); scooj.defMethod(module, function _getStyleSheetId(styleSheet) {
                                                                                                                                                                                                                                                                                                                                                                                                  return _getMappableId(styleSheet, this.styleSheetMap)
                                                                                                                                                                                                                                                                                                                                                                                                  }); scooj.defMethod(module, function _getStyleRule(id) {
                                                                                                                                                                                                                                                                                                                                                                                                                      return _getMappableObject(id, this.styleRuleMap)
                                                                                                                                                                                                                                                                                                                                                                                                                      }); scooj.defMethod(module, function _getStyleRuleId(styleRule) {
                                                                                                                                                                                                                                                                                                                                                                                                                                          return _getMappableId(styleRule, this.styleRuleMap)
                                                                                                                                                                                                                                                                                                                                                                                                                                          }); scooj.defMethod(module, function _getStyleDecl(id) {
                                                                                                                                                                                                                                                                                                                                                                                                                                                              return _getMappableObject(id, this.styleDeclMap)
                                                                                                                                                                                                                                                                                                                                                                                                                                                              }); scooj.defMethod(module, function _getStyleDeclId(styleDecl) {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  return _getMappableId(styleDecl, this.styleDeclMap)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  }); function _getMappableObject(id, map) {
                                                                                                        return map[id]
                                                                                                        }; function _getMappableId(object, map) {
                                                                                                        return IDGenerator.getId(object, map)
                                                                                                        }; function _mozMatchesSelector(element, selector) {
                                                                                                        if (!element.mozMatchesSelector) return false
                                                                                                        return element.mozMatchesSelector(selector)
                                                                                                        }; function _webkitMatchesSelector(element, selector) {
                                                                                                        if (!element.webkitMatchesSelector) return false
                                                                                                        return element.webkitMatchesSelector(selector)
                                                                                                        }; function _fallbackMatchesSelector(element, selector) {
                                                                                                        return false
                                                                                                        }; 
                                                                                                        var _elementMatchesSelector
                                                                                                        if      (Element.prototype.webkitMatchesSelector) _elementMatchesSelector = _webkitMatchesSelector 
                                                                                                        else if (Element.prototype.mozMatchesSelector)    _elementMatchesSelector = _mozMatchesSelector
                                                                                                        else                                              _elementMatchesSelector = _fallbackMatchesSelector
                                                                                                        ;
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/target/InjectedScriptHostImpl.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/target/InjectedScriptHostImpl": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Weinre = require('../common/Weinre').getClass(); if (typeof Weinre != 'function') throw Error('module ../common/Weinre did not export a class');
                                                                                                        var InjectedScriptHostImpl = scooj.defClass(module, function InjectedScriptHostImpl() {
                                                                                                                                                    }); scooj.defMethod(module, function clearConsoleMessages(callback) {
                                                                                                                                                                        if (callback) {
                                                                                                                                                                        Weinre.WeinreTargetCommands.sendClientCallback(callback)
                                                                                                                                                                        }
                                                                                                                                                                        }); scooj.defMethod(module, function nodeForId( nodeId, callback) {
                                                                                                                                                                                            return Weinre.nodeStore.getNode(nodeId)
                                                                                                                                                                                            }); scooj.defMethod(module, function pushNodePathToFrontend( node,  withChildren,  selectInUI, callback) {
                                                                                                                                                                                                                var nodeId = Weinre.nodeStore.getNodeId(node)
                                                                                                                                                                                                                var children = Weinre.nodeStore.serializeNode(node, 1)
                                                                                                                                                                                                                Weinre.wi.DOMNotify.setChildNodes(nodeId, children)
                                                                                                                                                                                                                if (callback) {
                                                                                                                                                                                                                Weinre.WeinreTargetCommands.sendClientCallback(callback)
                                                                                                                                                                                                                }
                                                                                                                                                                                                                }); scooj.defMethod(module, function inspectedNode( num, callback) {
                                                                                                                                                                                                                                    var nodeId = Weinre.nodeStore.getInspectedNode(num)
                                                                                                                                                                                                                                    return nodeId
                                                                                                                                                                                                                                    }); scooj.defMethod(module, function internalConstructorName(object) {
                                                                                                                                                                                                                                                        var ctor = object.constructor
                                                                                                                                                                                                                                                        var ctorName = ctor.fullClassName || ctor.displayName || ctor.name
                                                                                                                                                                                                                                                        if (ctorName && (ctorName != "Object")) return ctorName
                                                                                                                                                                                                                                                        var pattern = /\[object (.*)\]/
                                                                                                                                                                                                                                                        var match = pattern.exec(ctor.toString())
                                                                                                                                                                                                                                                        if (match) return match[1]
                                                                                                                                                                                                                                                        return "Object"
                                                                                                                                                                                                                                                        }); 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/target/Target.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/target/Target": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Native = require('../common/Native').getClass(); if (typeof Native != 'function') throw Error('module ../common/Native did not export a class');
                                                                                                        var Ex = require('../common/Ex').getClass(); if (typeof Ex != 'function') throw Error('module ../common/Ex did not export a class');
                                                                                                        var Binding = require('../common/Binding').getClass(); if (typeof Binding != 'function') throw Error('module ../common/Binding did not export a class');
                                                                                                        var Callback = require('../common/Callback').getClass(); if (typeof Callback != 'function') throw Error('module ../common/Callback did not export a class');
                                                                                                        var MessageDispatcher = require('../common/MessageDispatcher').getClass(); if (typeof MessageDispatcher != 'function') throw Error('module ../common/MessageDispatcher did not export a class');
                                                                                                        var Weinre = require('../common/Weinre').getClass(); if (typeof Weinre != 'function') throw Error('module ../common/Weinre did not export a class');
                                                                                                        var CheckForProblems = require('./CheckForProblems').getClass(); if (typeof CheckForProblems != 'function') throw Error('module ./CheckForProblems did not export a class');
                                                                                                        var NodeStore = require('./NodeStore').getClass(); if (typeof NodeStore != 'function') throw Error('module ./NodeStore did not export a class');
                                                                                                        var CSSStore = require('./CSSStore').getClass(); if (typeof CSSStore != 'function') throw Error('module ./CSSStore did not export a class');
                                                                                                        var ElementHighlighter = require('./ElementHighlighter').getClass(); if (typeof ElementHighlighter != 'function') throw Error('module ./ElementHighlighter did not export a class');
                                                                                                        var InjectedScriptHostImpl = require('./InjectedScriptHostImpl').getClass(); if (typeof InjectedScriptHostImpl != 'function') throw Error('module ./InjectedScriptHostImpl did not export a class');
                                                                                                        var WeinreTargetEventsImpl = require('./WeinreTargetEventsImpl').getClass(); if (typeof WeinreTargetEventsImpl != 'function') throw Error('module ./WeinreTargetEventsImpl did not export a class');
                                                                                                        var WiConsoleImpl = require('./WiConsoleImpl').getClass(); if (typeof WiConsoleImpl != 'function') throw Error('module ./WiConsoleImpl did not export a class');
                                                                                                        var WiCSSImpl = require('./WiCSSImpl').getClass(); if (typeof WiCSSImpl != 'function') throw Error('module ./WiCSSImpl did not export a class');
                                                                                                        var WiDatabaseImpl = require('./WiDatabaseImpl').getClass(); if (typeof WiDatabaseImpl != 'function') throw Error('module ./WiDatabaseImpl did not export a class');
                                                                                                        var WiDOMImpl = require('./WiDOMImpl').getClass(); if (typeof WiDOMImpl != 'function') throw Error('module ./WiDOMImpl did not export a class');
                                                                                                        var WiDOMStorageImpl = require('./WiDOMStorageImpl').getClass(); if (typeof WiDOMStorageImpl != 'function') throw Error('module ./WiDOMStorageImpl did not export a class');
                                                                                                        var WiInspectorImpl = require('./WiInspectorImpl').getClass(); if (typeof WiInspectorImpl != 'function') throw Error('module ./WiInspectorImpl did not export a class');
                                                                                                        var WiRuntimeImpl = require('./WiRuntimeImpl').getClass(); if (typeof WiRuntimeImpl != 'function') throw Error('module ./WiRuntimeImpl did not export a class');
                                                                                                        var Target = scooj.defClass(module, function Target() {
                                                                                                                                    }); scooj.defStaticMethod(module, function main() {
                                                                                                                                                              CheckForProblems.check()
                                                                                                                                                              Weinre.target = new Target()
                                                                                                                                                              Weinre.target.initialize()
                                                                                                                                                              Weinre.addCSSProperties = function addCSSProperties(properties) {
                                                                                                                                                              CSSStore.addCSSProperties(properties)
                                                                                                                                                              }
                                                                                                                                                              }); scooj.defMethod(module, function setWeinreServerURLFromScriptSrc() {
                                                                                                                                                                                  if (window.WeinreServerURL) return
                                                                                                                                                                                  var element = this.getTargetScriptElement()
                                                                                                                                                                                  var pattern = /(http:\/\/(.*?)\/)/
                                                                                                                                                                                  var match   = pattern.exec(element.src)
                                                                                                                                                                                  if (match) {
                                                                                                                                                                                  window.WeinreServerURL = match[1]
                                                                                                                                                                                  return 
                                                                                                                                                                                  }
                                                                                                                                                                                  var message = "unable to calculate the weinre server url; explicity set the variable window.WeinreServerURL instead" 
                                                                                                                                                                                  alert(message)
                                                                                                                                                                                  throw new Ex(arguments, message)
                                                                                                                                                                                  }); scooj.defMethod(module, function setWeinreServerIdFromScriptSrc() {
                                                                                                                                                                                                      if (window.WeinreServerId) return
                                                                                                                                                                                                      var element = this.getTargetScriptElement()
                                                                                                                                                                                                      var hash = element.src.split("#")[1]
                                                                                                                                                                                                      if (!hash) hash = "anonymous"
                                                                                                                                                                                                      window.WeinreServerId = hash
                                                                                                                                                                                                      }); scooj.defMethod(module, function getTargetScriptElement() {
                                                                                                                                                                                                                          var elements = document.getElementsByTagName("script")
                                                                                                                                                                                                                          var scripts = ["Target.", "target-script.", "target-script-min."]
                                                                                                                                                                                                                          for (var i=0; i<elements.length; i++) {
                                                                                                                                                                                                                          var element = elements[i]
                                                                                                                                                                                                                          for (j=0; j<scripts.length; j++) {
                                                                                                                                                                                                                          if (-1 != element.src.indexOf("/" + scripts[j])) {
                                                                                                                                                                                                                          return element
                                                                                                                                                                                                                          }
                                                                                                                                                                                                                          }
                                                                                                                                                                                                                          }
                                                                                                                                                                                                                          }); scooj.defMethod(module, function initialize() {
                                                                                                                                                                                                                                              var self = this
                                                                                                                                                                                                                                              this.setWeinreServerURLFromScriptSrc()
                                                                                                                                                                                                                                              this.setWeinreServerIdFromScriptSrc()
                                                                                                                                                                                                                                              if (window.WeinreServerURL[window.WeinreServerURL.length-1] != "/") {
                                                                                                                                                                                                                                              window.WeinreServerURL += "/"
                                                                                                                                                                                                                                              }   
                                                                                                                                                                                                                                              var injectedScriptHost = new InjectedScriptHostImpl()
                                                                                                                                                                                                                                              Weinre.injectedScript = injectedScriptConstructor(injectedScriptHost, window, 0, "?")
                                                                                                                                                                                                                                              window.addEventListener("load", Binding(this, "onLoaded"), false)
                                                                                                                                                                                                                                              document.addEventListener("DOMContentLoaded", Binding(this, "onDOMContent"), false)
                                                                                                                                                                                                                                              this._startTime = currentTime()
                                                                                                                                                                                                                                              if (document.readyState == "loaded") {
                                                                                                                                                                                                                                              setTimeout(function() { self.onDOMContent() }, 10)
                                                                                                                                                                                                                                              }
                                                                                                                                                                                                                                              if (document.readyState == "complete") {
                                                                                                                                                                                                                                              setTimeout(function() { self.onDOMContent() }, 10)
                                                                                                                                                                                                                                              setTimeout(function() { self.onLoaded() }, 20)
                                                                                                                                                                                                                                              }
                                                                                                                                                                                                                                              var messageDispatcher = new MessageDispatcher(window.WeinreServerURL + "ws/target", window.WeinreServerId)
                                                                                                                                                                                                                                              Weinre.messageDispatcher = messageDispatcher
                                                                                                                                                                                                                                              Weinre.wi = {}
                                                                                                                                                                                                                                              Weinre.wi.Console          = new WiConsoleImpl()
                                                                                                                                                                                                                                              Weinre.wi.CSS              = new WiCSSImpl()
                                                                                                                                                                                                                                              Weinre.wi.Database         = new WiDatabaseImpl()
                                                                                                                                                                                                                                              Weinre.wi.DOM              = new WiDOMImpl()
                                                                                                                                                                                                                                              Weinre.wi.DOMStorage       = new WiDOMStorageImpl()
                                                                                                                                                                                                                                              Weinre.wi.Inspector        = new WiInspectorImpl()
                                                                                                                                                                                                                                              Weinre.wi.Runtime          = new WiRuntimeImpl()
                                                                                                                                                                                                                                              messageDispatcher.registerInterface("Console",          Weinre.wi.Console          , false)
                                                                                                                                                                                                                                              messageDispatcher.registerInterface("CSS",              Weinre.wi.CSS              , false)
                                                                                                                                                                                                                                              messageDispatcher.registerInterface("Database",         Weinre.wi.Database         , false)
                                                                                                                                                                                                                                              messageDispatcher.registerInterface("DOM",              Weinre.wi.DOM              , false)
                                                                                                                                                                                                                                              messageDispatcher.registerInterface("DOMStorage",       Weinre.wi.DOMStorage       , false)
                                                                                                                                                                                                                                              messageDispatcher.registerInterface("Inspector",        Weinre.wi.Inspector        , false)
                                                                                                                                                                                                                                              messageDispatcher.registerInterface("Runtime",          Weinre.wi.Runtime          , false)
                                                                                                                                                                                                                                              messageDispatcher.registerInterface("WeinreTargetEvents", new WeinreTargetEventsImpl(), true)
                                                                                                                                                                                                                                              Weinre.wi.ApplicationCacheNotify = messageDispatcher.createProxy("ApplicationCacheNotify")
                                                                                                                                                                                                                                              Weinre.wi.ConsoleNotify          = messageDispatcher.createProxy("ConsoleNotify")
                                                                                                                                                                                                                                              Weinre.wi.DOMNotify              = messageDispatcher.createProxy("DOMNotify")
                                                                                                                                                                                                                                              Weinre.wi.DOMStorageNotify       = messageDispatcher.createProxy("DOMStorageNotify")
                                                                                                                                                                                                                                              Weinre.wi.DatabaseNotify         = messageDispatcher.createProxy("DatabaseNotify")
                                                                                                                                                                                                                                              Weinre.wi.InspectorNotify        = messageDispatcher.createProxy("InspectorNotify")
                                                                                                                                                                                                                                              Weinre.wi.TimelineNotify         = messageDispatcher.createProxy("TimelineNotify")
                                                                                                                                                                                                                                              Weinre.WeinreTargetCommands  = messageDispatcher.createProxy("WeinreTargetCommands")
                                                                                                                                                                                                                                              messageDispatcher.getWebSocket().addEventListener("open", Binding(this, this.cb_webSocketOpened))
                                                                                                                                                                                                                                              Weinre.nodeStore = new NodeStore()
                                                                                                                                                                                                                                              Weinre.cssStore  = new CSSStore()
                                                                                                                                                                                                                                              window.addEventListener("error", function(e) {Target.handleError(e)}, false)
                                                                                                                                                                                                                                              }); scooj.defStaticMethod(module, function handleError(event) {
                                                                                                                                                                                                                                                                        var filename = event.filename || "[unknown filename]"
                                                                                                                                                                                                                                                                        var lineno   = event.lineno   || "[unknown lineno]"
                                                                                                                                                                                                                                                                        var message  = event.message  || "[unknown message]"
                                                                                                                                                                                                                                                                        Weinre.logError("error occurred: " + filename + ":" + lineno + ": " + message)
                                                                                                                                                                                                                                                                        }); scooj.defMethod(module, function cb_webSocketOpened() {
                                                                                                                                                                                                                                                                                            Weinre.WeinreTargetCommands.registerTarget(window.location.href, Binding(this, this.cb_registerTarget))
                                                                                                                                                                                                                                                                                            }); scooj.defMethod(module, function cb_registerTarget(targetDescription) {
                                                                                                                                                                                                                                                                                                                Weinre.targetDescription    = targetDescription
                                                                                                                                                                                                                                                                                                                }); scooj.defMethod(module, function onLoaded() {
                                                                                                                                                                                                                                                                                                                                    Weinre.wi.InspectorNotify.loadEventFired(currentTime() - this._startTime)
                                                                                                                                                                                                                                                                                                                                    }); scooj.defMethod(module, function onDOMContent() {
                                                                                                                                                                                                                                                                                                                                                        Weinre.wi.InspectorNotify.domContentEventFired(currentTime() - this._startTime)
                                                                                                                                                                                                                                                                                                                                                        }); scooj.defMethod(module, function setDocument() {
                                                                                                                                                                                                                                                                                                                                                                            Weinre.elementHighlighter = new ElementHighlighter()
                                                                                                                                                                                                                                                                                                                                                                            var nodeId = Weinre.nodeStore.getNodeId(document)
                                                                                                                                                                                                                                                                                                                                                                            var nodeData = Weinre.nodeStore.getNodeData(nodeId, 2)
                                                                                                                                                                                                                                                                                                                                                                            Weinre.wi.DOMNotify.setDocument(nodeData)
                                                                                                                                                                                                                                                                                                                                                                            }); function currentTime() {
                                                                                                        return (new Date().getMilliseconds()) / 1000.0
                                                                                                        }; 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/target/ElementHighlighter.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/target/ElementHighlighter": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Binding = require('../common/Binding').getClass(); if (typeof Binding != 'function') throw Error('module ../common/Binding did not export a class');
                                                                                                        var Weinre = require('../common/Weinre').getClass(); if (typeof Weinre != 'function') throw Error('module ../common/Weinre did not export a class');
                                                                                                        var ElementHighlighter = scooj.defClass(module, function ElementHighlighter() {
                                                                                                                                                this.boxMargin  = document.createElement("div")
                                                                                                                                                this.boxBorder  = document.createElement("div")
                                                                                                                                                this.boxPadding = document.createElement("div")
                                                                                                                                                this.boxContent = document.createElement("div")
                                                                                                                                                this.boxMargin.appendChild(this.boxBorder)
                                                                                                                                                this.boxBorder.appendChild(this.boxPadding)
                                                                                                                                                this.boxPadding.appendChild(this.boxContent)
                                                                                                                                                this.boxMargin.style.backgroundColor  = "#FCC"
                                                                                                                                                this.boxBorder.style.backgroundColor  = "#000"
                                                                                                                                                this.boxPadding.style.backgroundColor = "#CFC"
                                                                                                                                                this.boxContent.style.backgroundColor = "#CCF"
                                                                                                                                                this.boxMargin.style.opacity =
                                                                                                                                                this.boxBorder.style.opacity =
                                                                                                                                                this.boxPadding.style.opacity =
                                                                                                                                                this.boxContent.style.opacity = 0.6
                                                                                                                                                this.boxMargin.style.position =
                                                                                                                                                this.boxBorder.style.position =
                                                                                                                                                this.boxPadding.style.position =
                                                                                                                                                this.boxContent.style.position = "absolute"
                                                                                                                                                this.boxMargin.style.borderWidth =
                                                                                                                                                this.boxBorder.style.borderWidth =
                                                                                                                                                this.boxPadding.style.borderWidth =
                                                                                                                                                this.boxContent.style.borderWidth = "thin"
                                                                                                                                                this.boxMargin.style.borderStyle =
                                                                                                                                                this.boxBorder.style.borderStyle =
                                                                                                                                                this.boxPadding.style.borderStyle =
                                                                                                                                                this.boxContent.style.borderStyle = "solid"
                                                                                                                                                this.boxMargin.__weinreHighlighter =
                                                                                                                                                this.boxBorder.__weinreHighlighter =
                                                                                                                                                this.boxPadding.__weinreHighlighter =
                                                                                                                                                this.boxContent.__weinreHighlighter = true
                                                                                                                                                this.boxMargin.style.display = "none"
                                                                                                                                                document.body.appendChild(this.boxMargin)
                                                                                                                                                }); scooj.defMethod(module, function on(element) {
                                                                                                                                                                    if (null == element) return
                                                                                                                                                                    if (element.nodeType != Node.ELEMENT_NODE) return
                                                                                                                                                                    this.calculateMetrics(element)
                                                                                                                                                                    this.boxMargin.style.display = "block"
                                                                                                                                                                    }); scooj.defMethod(module, function off() {
                                                                                                                                                                                        this.boxMargin.style.display = "none"
                                                                                                                                                                                        }); scooj.defGetter(module, function element() {
                                                                                                                                                                                                            return this.boxMargin
                                                                                                                                                                                                            }); scooj.defMethod(module, function calculateMetrics(element) {
                                                                                                                                                                                                                                var metrics = getMetrics(element), 
                                                                                                                                                                                                                                bm = this.boxMargin.style,
                                                                                                                                                                                                                                bb = this.boxBorder.style,
                                                                                                                                                                                                                                bp = this.boxPadding.style,
                                                                                                                                                                                                                                bc = this.boxContent.style
                                                                                                                                                                                                                                bm.top     = metrics.y      + "px"
                                                                                                                                                                                                                                bm.left    = metrics.x      + "px"
                                                                                                                                                                                                                                bm.height  = metrics.height + "px"
                                                                                                                                                                                                                                bm.width   = metrics.width  + "px"
                                                                                                                                                                                                                                bb.top     = metrics.marginTop    + "px"
                                                                                                                                                                                                                                bb.left    = metrics.marginLeft   + "px"
                                                                                                                                                                                                                                bb.bottom  = metrics.marginBottom + "px"
                                                                                                                                                                                                                                bb.right   = metrics.marginRight  + "px"
                                                                                                                                                                                                                                bp.top    = metrics.borderTop    + "px"
                                                                                                                                                                                                                                bp.left   = metrics.borderLeft   + "px"
                                                                                                                                                                                                                                bp.bottom = metrics.borderBottom + "px"
                                                                                                                                                                                                                                bp.right  = metrics.borderRight  + "px"
                                                                                                                                                                                                                                bc.top    = metrics.paddingTop    + "px"
                                                                                                                                                                                                                                bc.left   = metrics.paddingLeft   + "px"
                                                                                                                                                                                                                                bc.bottom = metrics.paddingBottom + "px"
                                                                                                                                                                                                                                bc.right  = metrics.paddingRight  + "px"
                                                                                                                                                                                                                                }); function getMetrics(element) {
                                                                                                        var result = {}
                                                                                                        var rect = element.getBoundingClientRect();
                                                                                                        result.x = rect.left
                                                                                                        result.y = rect.top
                                                                                                        var cStyle = document.defaultView.getComputedStyle(element)
                                                                                                        result.width  = parseInt(cStyle["width"])
                                                                                                        result.height = parseInt(cStyle["height"])
                                                                                                        result.marginLeft    = parseInt(cStyle["margin-left"])
                                                                                                        result.marginRight   = parseInt(cStyle["margin-right"])
                                                                                                        result.marginTop     = parseInt(cStyle["margin-top"])
                                                                                                        result.marginBottom  = parseInt(cStyle["margin-bottom"])
                                                                                                        result.borderLeft    = parseInt(cStyle["border-left-width"])
                                                                                                        result.borderRight   = parseInt(cStyle["border-right-width"])
                                                                                                        result.borderTop     = parseInt(cStyle["border-top-width"])
                                                                                                        result.borderBottom  = parseInt(cStyle["border-bottom-width"])
                                                                                                        result.paddingLeft   = parseInt(cStyle["padding-left"])
                                                                                                        result.paddingRight  = parseInt(cStyle["padding-right"])
                                                                                                        result.paddingTop    = parseInt(cStyle["padding-top"])
                                                                                                        result.paddingBottom = parseInt(cStyle["padding-bottom"])
                                                                                                        result.width += 
                                                                                                        result.marginLeft  + result.marginRight +
                                                                                                        result.borderRight  +
                                                                                                        result.paddingLeft + result.paddingRight
                                                                                                        result.height += 
                                                                                                        result.marginTop  + result.marginBottom +
                                                                                                        result.borderBottom  +
                                                                                                        result.paddingTop + result.paddingBottom
                                                                                                        result.x -= 
                                                                                                        result.marginLeft
                                                                                                        result.y -= 
                                                                                                        result.marginTop
                                                                                                        return result
                                                                                                        }; function fromPx(string) {
                                                                                                        return parseInt(string.replace(/px$/,""))
                                                                                                        }; 
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/target/InjectedScript.js
                                                                                        //==================================================
                                                                                        var injectedScriptConstructor = 
                                                                                        (function (InjectedScriptHost, inspectedWindow, injectedScriptId) {
                                                                                         function bind(thisObject, memberFunction)
                                                                                         {
                                                                                         var func = memberFunction;
                                                                                         var args = Array.prototype.slice.call(arguments, 2);
                                                                                         function bound()
                                                                                         {
                                                                                         return func.apply(thisObject, args.concat(Array.prototype.slice.call(arguments, 0)));
                                                                                         }
                                                                                         bound.toString = function() {
                                                                                         return "bound: " + func;
                                                                                         };
                                                                                         return bound;
                                                                                         }
                                                                                         var InjectedScript = function()
                                                                                         {
                                                                                         this._lastBoundObjectId = 1;
                                                                                         this._idToWrappedObject = {};
                                                                                         this._objectGroups = {};
                                                                                         }
                                                                                         InjectedScript.prototype = {
                                                                                         wrapObjectForConsole: function(object, canAccessInspectedWindow)
                                                                                         {
                                                                                         if (canAccessInspectedWindow)
                                                                                         return this._wrapObject(object, "console");
                                                                                         var result = {};
                                                                                         result.type = typeof object;
                                                                                         result.description = this._toString(object);
                                                                                         return result;
                                                                                         },
                                                                                         _wrapObject: function(object, objectGroupName, abbreviate)
                                                                                         {
                                                                                         try {
                                                                                         var objectId;
                                                                                         if (typeof object === "object" || typeof object === "function" || this._isHTMLAllCollection(object)) {
                                                                                         var id = this._lastBoundObjectId++;
                                                                                         this._idToWrappedObject[id] = object;
                                                                                         var group = this._objectGroups[objectGroupName];
                                                                                         if (!group) {
                                                                                         group = [];
                                                                                         this._objectGroups[objectGroupName] = group;
                                                                                         }
                                                                                         group.push(id);
                                                                                         objectId = { injectedScriptId: injectedScriptId,
                                                                                         id: id,
                                                                                         groupName: objectGroupName };
                                                                                         }
                                                                                         return InjectedScript.RemoteObject.fromObject(object, objectId, abbreviate);
                                                                                         } catch (e) {
                                                                                         return InjectedScript.RemoteObject.fromObject("[ Exception: " + e.toString() + " ]");
                                                                                         }
                                                                                         },
                                                                                         _parseObjectId: function(objectId)
                                                                                         {
                                                                                         return eval("(" + objectId + ")");
                                                                                         },
                                                                                         releaseWrapperObjectGroup: function(objectGroupName)
                                                                                         {
                                                                                         var group = this._objectGroups[objectGroupName];
                                                                                         if (!group)
                                                                                         return;
                                                                                         for (var i = 0; i < group.length; i++)
                                                                                         delete this._idToWrappedObject[group[i]];
                                                                                         delete this._objectGroups[objectGroupName];
                                                                                         },
                                                                                         dispatch: function(methodName, args)
                                                                                         {
                                                                                         var argsArray = eval("(" + args + ")");
                                                                                         var result = this[methodName].apply(this, argsArray);
                                                                                         if (typeof result === "undefined") {
                                                                                         inspectedWindow.console.error("Web Inspector error: InjectedScript.%s returns undefined", methodName);
                                                                                         result = null;
                                                                                         }
                                                                                         return result;
                                                                                         },
                                                                                         getProperties: function(objectId, ignoreHasOwnProperty, abbreviate)
                                                                                         {
                                                                                         var parsedObjectId = this._parseObjectId(objectId);
                                                                                         var object = this._objectForId(parsedObjectId);
                                                                                         if (!this._isDefined(object))
                                                                                         return false;
                                                                                         var properties = [];
                                                                                         var propertyNames = ignoreHasOwnProperty ? this._getPropertyNames(object) : Object.getOwnPropertyNames(object);
                                                                                         if (!ignoreHasOwnProperty && object.__proto__)
                                                                                         propertyNames.push("__proto__");
                                                                                         for (var i = 0; i < propertyNames.length; ++i) {
                                                                                         var propertyName = propertyNames[i];
                                                                                         var property = {};
                                                                                         property.name = propertyName + "";
                                                                                         var isGetter = object["__lookupGetter__"] && object.__lookupGetter__(propertyName);
                                                                                         if (!isGetter) {
                                                                                         try {
                                                                                         property.value = this._wrapObject(object[propertyName], parsedObjectId.groupName, abbreviate);
                                                                                         } catch(e) {
                                                                                         property.value = new InjectedScript.RemoteObject.fromException(e);
                                                                                         }
                                                                                         } else {
                                                                                         property.value = new InjectedScript.RemoteObject.fromObject("\u2014"); 
                                                                                         property.isGetter = true;
                                                                                         }
                                                                                         properties.push(property);
                                                                                         }
                                                                                         return properties;
                                                                                         },
                                                                                         setPropertyValue: function(objectId, propertyName, expression)
                                                                                         {
                                                                                         var parsedObjectId = this._parseObjectId(objectId);
                                                                                         var object = this._objectForId(parsedObjectId);
                                                                                         if (!this._isDefined(object))
                                                                                         return false;
                                                                                         var expressionLength = expression.length;
                                                                                         if (!expressionLength) {
                                                                                         delete object[propertyName];
                                                                                         return !(propertyName in object);
                                                                                         }
                                                                                         try {
                                                                                         var result = inspectedWindow.eval("(" + expression + ")");
                                                                                         object[propertyName] = result;
                                                                                         return true;
                                                                                         } catch(e) {
                                                                                         try {
                                                                                         var result = inspectedWindow.eval("\"" + expression.replace(/"/g, "\\\"") + "\"");
                                                                                         object[propertyName] = result;
                                                                                         return true;
                                                                                         } catch(e) {
                                                                                         return false;
                                                                                         }
                                                                                         }
                                                                                         },
                                                                                         _populatePropertyNames: function(object, resultSet)
                                                                                         {
                                                                                         for (var o = object; o; o = o.__proto__) {
                                                                                         try {
                                                                                         var names = Object.getOwnPropertyNames(o);
                                                                                         for (var i = 0; i < names.length; ++i)
                                                                                         resultSet[names[i]] = true;
                                                                                         } catch (e) {
                                                                                         }
                                                                                         }
                                                                                         },
                                                                                         _getPropertyNames: function(object, resultSet)
                                                                                         {
                                                                                         var propertyNameSet = {};
                                                                                         this._populatePropertyNames(object, propertyNameSet);
                                                                                         return Object.keys(propertyNameSet);
                                                                                         },
                                                                                         getCompletions: function(expression, includeCommandLineAPI)
                                                                                         {
                                                                                         var props = {};
                                                                                         try {
                                                                                         if (!expression)
                                                                                         expression = "this";
                                                                                         var expressionResult = this._evaluateOn(inspectedWindow.eval, inspectedWindow, expression, false, false);
                                                                                         if (typeof expressionResult === "object")
                                                                                         this._populatePropertyNames(expressionResult, props);
                                                                                         if (includeCommandLineAPI) {
                                                                                         for (var prop in CommandLineAPI.members_)
                                                                                         props[CommandLineAPI.members_[prop]] = true;
                                                                                         }
                                                                                         } catch(e) {
                                                                                         }
                                                                                         return props;
                                                                                         },
                                                                                         getCompletionsOnCallFrame: function(callFrameId, expression, includeCommandLineAPI)
                                                                                         {
                                                                                         var props = {};
                                                                                         try {
                                                                                         var callFrame = this._callFrameForId(callFrameId);
                                                                                         if (!callFrame)
                                                                                         return props;
                                                                                         if (expression) {
                                                                                         var expressionResult = this._evaluateOn(callFrame.evaluate, callFrame, expression, true, false);
                                                                                         if (typeof expressionResult === "object")
                                                                                         this._populatePropertyNames(expressionResult, props);
                                                                                         } else {
                                                                                         var scopeChain = callFrame.scopeChain;
                                                                                         for (var i = 0; i < scopeChain.length; ++i)
                                                                                         this._populatePropertyNames(scopeChain[i], props);
                                                                                         }
                                                                                         if (includeCommandLineAPI) {
                                                                                         for (var prop in CommandLineAPI.members_)
                                                                                         props[CommandLineAPI.members_[prop]] = true;
                                                                                         }
                                                                                         } catch(e) {
                                                                                         }
                                                                                         return props;
                                                                                         },
                                                                                         evaluate: function(expression, objectGroup, injectCommandLineAPI)
                                                                                         {
                                                                                         return this._evaluateAndWrap(inspectedWindow.eval, inspectedWindow, expression, objectGroup, false, injectCommandLineAPI);
                                                                                         },
                                                                                         _evaluateAndWrap: function(evalFunction, object, expression, objectGroup, isEvalOnCallFrame, injectCommandLineAPI)
                                                                                         {
                                                                                         try {
                                                                                         return this._wrapObject(this._evaluateOn(evalFunction, object, expression, isEvalOnCallFrame, injectCommandLineAPI), objectGroup);
                                                                                         } catch (e) {
                                                                                         return InjectedScript.RemoteObject.fromException(e);
                                                                                         }
                                                                                         },
                                                                                         _evaluateOn: function(evalFunction, object, expression, isEvalOnCallFrame, injectCommandLineAPI)
                                                                                         {
                                                                                         try {
                                                                                         if (injectCommandLineAPI && inspectedWindow.console) {
                                                                                         inspectedWindow.console._commandLineAPI = new CommandLineAPI(this._commandLineAPIImpl, isEvalOnCallFrame ? object : null);
                                                                                         expression = "with ((window && window.console && window.console._commandLineAPI) || {}) {\n" + expression + "\n}";
                                                                                         }
                                                                                         var value = evalFunction.call(object, expression);
                                                                                         if (this._type(value) === "error")
                                                                                         throw value.toString();
                                                                                         return value;
                                                                                         } finally {
                                                                                         if (injectCommandLineAPI && inspectedWindow.console)
                                                                                         delete inspectedWindow.console._commandLineAPI;
                                                                                         }
                                                                                         },
                                                                                         getNodeId: function(node)
                                                                                         {
                                                                                         return InjectedScriptHost.pushNodePathToFrontend(node, false, false);
                                                                                         },
                                                                                         callFrames: function()
                                                                                         {
                                                                                         var callFrame = InjectedScriptHost.currentCallFrame();
                                                                                         if (!callFrame)
                                                                                         return false;
                                                                                         injectedScript.releaseWrapperObjectGroup("backtrace");
                                                                                         var result = [];
                                                                                         var depth = 0;
                                                                                         do {
                                                                                         result.push(new InjectedScript.CallFrameProxy(depth++, callFrame));
                                                                                         callFrame = callFrame.caller;
                                                                                         } while (callFrame);
                                                                                         return result;
                                                                                         },
                                                                                         evaluateOnCallFrame: function(callFrameId, expression, objectGroup, injectCommandLineAPI)
                                                                                         {
                                                                                         var callFrame = this._callFrameForId(callFrameId);
                                                                                         if (!callFrame)
                                                                                         return false;
                                                                                         return this._evaluateAndWrap(callFrame.evaluate, callFrame, expression, objectGroup, true, injectCommandLineAPI);
                                                                                         },
                                                                                         _callFrameForId: function(callFrameId)
                                                                                         {
                                                                                         var parsedCallFrameId = eval("(" + callFrameId + ")");
                                                                                         var ordinal = parsedCallFrameId.ordinal;
                                                                                         var callFrame = InjectedScriptHost.currentCallFrame();
                                                                                         while (--ordinal >= 0 && callFrame)
                                                                                         callFrame = callFrame.caller;
                                                                                         return callFrame;
                                                                                         },
                                                                                         _nodeForId: function(nodeId)
                                                                                         {
                                                                                         if (!nodeId)
                                                                                         return null;
                                                                                         return InjectedScriptHost.nodeForId(nodeId);
                                                                                         },
                                                                                         _objectForId: function(objectId)
                                                                                         {
                                                                                         return this._idToWrappedObject[objectId.id];
                                                                                         },
                                                                                         resolveNode: function(nodeId)
                                                                                         {
                                                                                         var node = this._nodeForId(nodeId);
                                                                                         if (!node)
                                                                                         return false;
                                                                                         return this._wrapObject(node, "prototype");
                                                                                         },
                                                                                         getNodeProperties: function(nodeId, properties)
                                                                                         {
                                                                                         var node = this._nodeForId(nodeId);
                                                                                         if (!node)
                                                                                         return false;
                                                                                         properties = eval("(" + properties + ")");
                                                                                         var result = {};
                                                                                         for (var i = 0; i < properties.length; ++i)
                                                                                         result[properties[i]] = node[properties[i]];
                                                                                         return result;
                                                                                         },
                                                                                         getNodePrototypes: function(nodeId)
                                                                                         {
                                                                                         this.releaseWrapperObjectGroup("prototypes");
                                                                                         var node = this._nodeForId(nodeId);
                                                                                         if (!node)
                                                                                         return false;
                                                                                         var result = [];
                                                                                         var prototype = node;
                                                                                         do {
                                                                                         result.push(this._wrapObject(prototype, "prototypes"));
                                                                                         prototype = prototype.__proto__;
                                                                                         } while (prototype)
                                                                                         return result;
                                                                                         },
                                                                                         pushNodeToFrontend: function(objectId)
                                                                                         {
                                                                                         var parsedObjectId = this._parseObjectId(objectId);
                                                                                         var object = this._objectForId(parsedObjectId);
                                                                                         if (!object || this._type(object) !== "node")
                                                                                         return false;
                                                                                         return InjectedScriptHost.pushNodePathToFrontend(object, false, false);
                                                                                         },
                                                                                         evaluateOnSelf: function(funcBody, args)
                                                                                         {
                                                                                         var func = eval("(" + funcBody + ")");
                                                                                         return func.apply(this, eval("(" + args + ")") || []);
                                                                                         },
                                                                                         _isDefined: function(object)
                                                                                         {
                                                                                         return object || this._isHTMLAllCollection(object);
                                                                                         },
                                                                                         _isHTMLAllCollection: function(object)
                                                                                         {
                                                                                         return (typeof object === "undefined") && inspectedWindow.HTMLAllCollection && object instanceof inspectedWindow.HTMLAllCollection;
                                                                                         },
                                                                                         _type: function(obj)
                                                                                         {
                                                                                         if (obj === null)
                                                                                         return "null";
                                                                                         var type = typeof obj;
                                                                                         if (type !== "object" && type !== "function") {
                                                                                         if (this._isHTMLAllCollection(obj))
                                                                                         return "array";
                                                                                         return type;
                                                                                         }
                                                                                         if (!inspectedWindow.document)
                                                                                         return type;
                                                                                         if (obj instanceof inspectedWindow.Node)
                                                                                         return (obj.nodeType === undefined ? type : "node");
                                                                                         if (obj instanceof inspectedWindow.String)
                                                                                         return "string";
                                                                                         if (obj instanceof inspectedWindow.Array)
                                                                                         return "array";
                                                                                         if (obj instanceof inspectedWindow.Boolean)
                                                                                         return "boolean";
                                                                                         if (obj instanceof inspectedWindow.Number)
                                                                                         return "number";
                                                                                         if (obj instanceof inspectedWindow.Date)
                                                                                         return "date";
                                                                                         if (obj instanceof inspectedWindow.RegExp)
                                                                                         return "regexp";
                                                                                         if (isFinite(obj.length) && typeof obj.splice === "function")
                                                                                         return "array";
                                                                                         if (isFinite(obj.length) && typeof obj.callee === "function") 
                                                                                         return "array";
                                                                                         if (obj instanceof inspectedWindow.NodeList)
                                                                                         return "array";
                                                                                         if (obj instanceof inspectedWindow.HTMLCollection)
                                                                                         return "array";
                                                                                         if (obj instanceof inspectedWindow.Error)
                                                                                         return "error";
                                                                                         return type;
                                                                                         },
                                                                                         _describe: function(obj, abbreviated)
                                                                                         {
                                                                                         var type = this._type(obj);
                                                                                         switch (type) {
                                                                                         case "object":
                                                                                         case "node":
                                                                                         var result = InjectedScriptHost.internalConstructorName(obj);
                                                                                         if (result === "Object") {
                                                                                         var constructorName = obj.constructor && obj.constructor.name;
                                                                                         if (constructorName)
                                                                                         return constructorName;
                                                                                         }
                                                                                         return result;
                                                                                         case "array":
                                                                                         var className = InjectedScriptHost.internalConstructorName(obj);
                                                                                         if (typeof obj.length === "number")
                                                                                         className += "[" + obj.length + "]";
                                                                                         return className;
                                                                                         case "string":
                                                                                         if (!abbreviated)
                                                                                         return obj;
                                                                                         if (obj.length > 100)
                                                                                         return "\"" + obj.substring(0, 100) + "\u2026\"";
                                                                                         return "\"" + obj + "\"";
                                                                                         case "function":
                                                                                         var objectText = this._toString(obj);
                                                                                         if (abbreviated)
                                                                                         objectText = /.*/.exec(objectText)[0].replace(/ +$/g, "");
                                                                                         return objectText;
                                                                                         default:
                                                                                         return this._toString(obj);
                                                                                         }
                                                                                         },
                                                                                         _toString: function(obj)
                                                                                         {
                                                                                         return "" + obj;
                                                                                         }
                                                                                         }
                                                                                         var injectedScript = new InjectedScript();
                                                                                         InjectedScript.RemoteObject = function(objectId, type, description, hasChildren)
                                                                                         {
                                                                                         this.objectId = objectId;
                                                                                         this.type = type;
                                                                                         this.description = description;
                                                                                         this.hasChildren = hasChildren;
                                                                                         }
                                                                                         InjectedScript.RemoteObject.fromException = function(e)
                                                                                         {
                                                                                         return new InjectedScript.RemoteObject(null, "error", e.toString());
                                                                                         }
                                                                                         InjectedScript.RemoteObject.fromObject = function(object, objectId, abbreviate)
                                                                                         {
                                                                                         var type = injectedScript._type(object);
                                                                                         var rawType = typeof object;
                                                                                         var hasChildren = (rawType === "object" && object !== null && (Object.getOwnPropertyNames(object).length || !!object.__proto__)) || rawType === "function";
                                                                                         var description = "";
                                                                                         try {
                                                                                         var description = injectedScript._describe(object, abbreviate);
                                                                                         return new InjectedScript.RemoteObject(objectId, type, description, hasChildren);
                                                                                         } catch (e) {
                                                                                         return InjectedScript.RemoteObject.fromException(e);
                                                                                         }
                                                                                         }
                                                                                         InjectedScript.CallFrameProxy = function(ordinal, callFrame)
                                                                                         {
                                                                                         this.id = { ordinal: ordinal, injectedScriptId: injectedScriptId };
                                                                                         this.type = callFrame.type;
                                                                                         this.functionName = (this.type === "function" ? callFrame.functionName : "");
                                                                                         this.sourceID = callFrame.sourceID;
                                                                                         this.line = callFrame.line;
                                                                                         this.column = callFrame.column;
                                                                                         this.scopeChain = this._wrapScopeChain(callFrame);
                                                                                         }
                                                                                         InjectedScript.CallFrameProxy.prototype = {
                                                                                         _wrapScopeChain: function(callFrame)
                                                                                         {
                                                                                         const GLOBAL_SCOPE = 0;
                                                                                         const LOCAL_SCOPE = 1;
                                                                                         const WITH_SCOPE = 2;
                                                                                         const CLOSURE_SCOPE = 3;
                                                                                         const CATCH_SCOPE = 4;
                                                                                         var scopeChain = callFrame.scopeChain;
                                                                                         var scopeChainProxy = [];
                                                                                         var foundLocalScope = false;
                                                                                         for (var i = 0; i < scopeChain.length; i++) {
                                                                                         var scopeType = callFrame.scopeType(i);
                                                                                         var scopeObject = scopeChain[i];
                                                                                         var scopeObjectProxy = injectedScript._wrapObject(scopeObject, "backtrace", true);
                                                                                         switch(scopeType) {
                                                                                         case LOCAL_SCOPE: {
                                                                                         foundLocalScope = true;
                                                                                         scopeObjectProxy.isLocal = true;
                                                                                         scopeObjectProxy.thisObject = injectedScript._wrapObject(callFrame.thisObject, "backtrace", true);
                                                                                         break;
                                                                                         }
                                                                                         case CLOSURE_SCOPE: {
                                                                                         scopeObjectProxy.isClosure = true;
                                                                                         break;
                                                                                         }
                                                                                         case WITH_SCOPE:
                                                                                         case CATCH_SCOPE: {
                                                                                         if (foundLocalScope && scopeObject instanceof inspectedWindow.Element)
                                                                                         scopeObjectProxy.isElement = true;
                                                                                         else if (foundLocalScope && scopeObject instanceof inspectedWindow.Document)
                                                                                         scopeObjectProxy.isDocument = true;
                                                                                         else
                                                                                         scopeObjectProxy.isWithBlock = true;
                                                                                         break;
                                                                                         }
                                                                                         }
                                                                                         scopeChainProxy.push(scopeObjectProxy);
                                                                                         }
                                                                                         return scopeChainProxy;
                                                                                         }
                                                                                         }
                                                                                         function CommandLineAPI(commandLineAPIImpl, callFrame)
                                                                                         {
                                                                                         function inScopeVariables(member)
                                                                                         {
                                                                                         if (!callFrame)
                                                                                         return false;
                                                                                         var scopeChain = callFrame.scopeChain;
                                                                                         for (var i = 0; i < scopeChain.length; ++i) {
                                                                                         if (member in scopeChain[i])
                                                                                         return true;
                                                                                         }
                                                                                         return false;
                                                                                         }
                                                                                         for (var i = 0; i < CommandLineAPI.members_.length; ++i) {
                                                                                         var member = CommandLineAPI.members_[i];
                                                                                         if (member in inspectedWindow || inScopeVariables(member))
                                                                                         continue;
                                                                                         this[member] = bind(commandLineAPIImpl, commandLineAPIImpl[member]);
                                                                                         }
                                                                                         for (var i = 0; i < 5; ++i) {
                                                                                         var member = "$" + i;
                                                                                         if (member in inspectedWindow || inScopeVariables(member))
                                                                                         continue;
                                                                                         this.__defineGetter__("$" + i, bind(commandLineAPIImpl, commandLineAPIImpl._inspectedNode, i));
                                                                                         }
                                                                                         }
                                                                                         CommandLineAPI.members_ = [
                                                                                                                    "$", "$$", "$x", "dir", "dirxml", "keys", "values", "profile", "profileEnd",
                                                                                                                    "monitorEvents", "unmonitorEvents", "inspect", "copy", "clear"
                                                                                                                    ];
                                                                                         function CommandLineAPIImpl()
                                                                                         {
                                                                                         }
                                                                                         CommandLineAPIImpl.prototype = {
                                                                                         $: function()
                                                                                         {
                                                                                         return document.getElementById.apply(document, arguments)
                                                                                         },
                                                                                         $$: function()
                                                                                         {
                                                                                         return document.querySelectorAll.apply(document, arguments)
                                                                                         },
                                                                                         $x: function(xpath, context)
                                                                                         {
                                                                                         var nodes = [];
                                                                                         try {
                                                                                         var doc = (context && context.ownerDocument) || inspectedWindow.document;
                                                                                         var results = doc.evaluate(xpath, context || doc, null, XPathResult.ANY_TYPE, null);
                                                                                         var node;
                                                                                         while (node = results.iterateNext())
                                                                                         nodes.push(node);
                                                                                         } catch (e) {
                                                                                         }
                                                                                         return nodes;
                                                                                         },
                                                                                         dir: function()
                                                                                         {
                                                                                         return console.dir.apply(console, arguments)
                                                                                         },
                                                                                         dirxml: function()
                                                                                         {
                                                                                         return console.dirxml.apply(console, arguments)
                                                                                         },
                                                                                         keys: function(object)
                                                                                         {
                                                                                         return Object.keys(object);
                                                                                         },
                                                                                         values: function(object)
                                                                                         {
                                                                                         var result = [];
                                                                                         for (var key in object)
                                                                                         result.push(object[key]);
                                                                                         return result;
                                                                                         },
                                                                                         profile: function()
                                                                                         {
                                                                                         return console.profile.apply(console, arguments)
                                                                                         },
                                                                                         profileEnd: function()
                                                                                         {
                                                                                         return console.profileEnd.apply(console, arguments)
                                                                                         },
                                                                                         monitorEvents: function(object, types)
                                                                                         {
                                                                                         if (!object || !object.addEventListener || !object.removeEventListener)
                                                                                         return;
                                                                                         types = this._normalizeEventTypes(types);
                                                                                         for (var i = 0; i < types.length; ++i) {
                                                                                         object.removeEventListener(types[i], this._logEvent, false);
                                                                                         object.addEventListener(types[i], this._logEvent, false);
                                                                                         }
                                                                                         },
                                                                                         unmonitorEvents: function(object, types)
                                                                                         {
                                                                                         if (!object || !object.addEventListener || !object.removeEventListener)
                                                                                         return;
                                                                                         types = this._normalizeEventTypes(types);
                                                                                         for (var i = 0; i < types.length; ++i)
                                                                                         object.removeEventListener(types[i], this._logEvent, false);
                                                                                         },
                                                                                         inspect: function(object)
                                                                                         {
                                                                                         if (arguments.length === 0)
                                                                                         return;
                                                                                         inspectedWindow.console.log(object);
                                                                                         if (injectedScript._type(object) === "node")
                                                                                         InjectedScriptHost.pushNodePathToFrontend(object, false, true);
                                                                                         else {
                                                                                         switch (injectedScript._describe(object)) {
                                                                                         case "Database":
                                                                                         InjectedScriptHost.selectDatabase(object);
                                                                                         break;
                                                                                         case "Storage":
                                                                                         InjectedScriptHost.selectDOMStorage(object);
                                                                                         break;
                                                                                         }
                                                                                         }
                                                                                         },
                                                                                         copy: function(object)
                                                                                         {
                                                                                         if (injectedScript._type(object) === "node")
                                                                                         object = object.outerHTML;
                                                                                         InjectedScriptHost.copyText(object);
                                                                                         },
                                                                                         clear: function()
                                                                                         {
                                                                                         InjectedScriptHost.clearConsoleMessages();
                                                                                         },
                                                                                         _inspectedNode: function(num)
                                                                                         {
                                                                                         var nodeId = InjectedScriptHost.inspectedNode(num);
                                                                                         return injectedScript._nodeForId(nodeId);
                                                                                         },
                                                                                         _normalizeEventTypes: function(types)
                                                                                         {
                                                                                         if (typeof types === "undefined")
                                                                                         types = [ "mouse", "key", "load", "unload", "abort", "error", "select", "change", "submit", "reset", "focus", "blur", "resize", "scroll" ];
                                                                                         else if (typeof types === "string")
                                                                                         types = [ types ];
                                                                                         var result = [];
                                                                                         for (var i = 0; i < types.length; i++) {
                                                                                         if (types[i] === "mouse")
                                                                                         result.splice(0, 0, "mousedown", "mouseup", "click", "dblclick", "mousemove", "mouseover", "mouseout");
                                                                                         else if (types[i] === "key")
                                                                                         result.splice(0, 0, "keydown", "keyup", "keypress");
                                                                                         else
                                                                                         result.push(types[i]);
                                                                                         }
                                                                                         return result;
                                                                                         },
                                                                                         _logEvent: function(event)
                                                                                         {
                                                                                         console.log(event.type, event);
                                                                                         }
                                                                                         }
                                                                                         injectedScript._commandLineAPIImpl = new CommandLineAPIImpl();
                                                                                         return injectedScript;
                                                                                         })
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: weinre/target/Timeline.transportd.js
                                                                                        //==================================================
                                                                                        ;require.define({"weinre/target/Timeline": function(require, exports, module) { 
                                                                                                        ;var scooj = require('scooj'); var Ex = require('../common/Ex').getClass(); if (typeof Ex != 'function') throw Error('module ../common/Ex did not export a class');
                                                                                                        var Weinre = require('../common/Weinre').getClass(); if (typeof Weinre != 'function') throw Error('module ../common/Weinre did not export a class');
                                                                                                        var IDGenerator = require('../common/IDGenerator').getClass(); if (typeof IDGenerator != 'function') throw Error('module ../common/IDGenerator did not export a class');
                                                                                                        var StackTrace = require('../common/StackTrace').getClass(); if (typeof StackTrace != 'function') throw Error('module ../common/StackTrace did not export a class');
                                                                                                        var Native = require('../common/Native').getClass(); if (typeof Native != 'function') throw Error('module ../common/Native did not export a class');
                                                                                                        var Timeline = scooj.defClass(module, function Timeline() {
                                                                                                                                      }); scooj.defStaticMethod(module, function start() {
                                                                                                                                                                Running = true
                                                                                                                                                                }); scooj.defStaticMethod(module, function stop() {
                                                                                                                                                                                          Running = false
                                                                                                                                                                                          }); scooj.defStaticMethod(module, function isRunning() {
                                                                                                                                                                                                                    return Running
                                                                                                                                                                                                                    }); scooj.defStaticMethod(module, function addRecord_Mark(message) {
                                                                                                                                                                                                                                              if (!Timeline.isRunning()) return
                                                                                                                                                                                                                                              var record = {}
                                                                                                                                                                                                                                              record.type      = TimelineRecordType.Mark
                                                                                                                                                                                                                                              record.category  = { name: "scripting" }
                                                                                                                                                                                                                                              record.startTime = Date.now()
                                                                                                                                                                                                                                              record.data      = { message: message }
                                                                                                                                                                                                                                              addStackTrace(record, 3)
                                                                                                                                                                                                                                              Weinre.wi.TimelineNotify.addRecordToTimeline(record)
                                                                                                                                                                                                                                              }); scooj.defStaticMethod(module, function addRecord_EventDispatch(event, name, category) {
                                                                                                                                                                                                                                                                        if (!Timeline.isRunning()) return
                                                                                                                                                                                                                                                                        if (!category) category = "scripting"
                                                                                                                                                                                                                                                                        var record = {}
                                                                                                                                                                                                                                                                        record.type      = TimelineRecordType.EventDispatch
                                                                                                                                                                                                                                                                        record.category  = { name: category }
                                                                                                                                                                                                                                                                        record.startTime = Date.now()
                                                                                                                                                                                                                                                                        record.data      = { type: event.type }
                                                                                                                                                                                                                                                                        Weinre.wi.TimelineNotify.addRecordToTimeline(record)
                                                                                                                                                                                                                                                                        }); scooj.defStaticMethod(module, function addRecord_TimerInstall(id, timeout, singleShot) {
                                                                                                                                                                                                                                                                                                  if (!Timeline.isRunning()) return
                                                                                                                                                                                                                                                                                                  var record = {}
                                                                                                                                                                                                                                                                                                  record.type      = TimelineRecordType.TimerInstall
                                                                                                                                                                                                                                                                                                  record.category  = { name: "scripting" }
                                                                                                                                                                                                                                                                                                  record.startTime = Date.now()
                                                                                                                                                                                                                                                                                                  record.data      = { timerId: id, timeout: timeout, singleShot: singleShot }
                                                                                                                                                                                                                                                                                                  addStackTrace(record, 4)
                                                                                                                                                                                                                                                                                                  Weinre.wi.TimelineNotify.addRecordToTimeline(record)
                                                                                                                                                                                                                                                                                                  }); scooj.defStaticMethod(module, function addRecord_TimerRemove(id, timeout, singleShot) {
                                                                                                                                                                                                                                                                                                                            if (!Timeline.isRunning()) return
                                                                                                                                                                                                                                                                                                                            var record = {}
                                                                                                                                                                                                                                                                                                                            record.type      = TimelineRecordType.TimerRemove
                                                                                                                                                                                                                                                                                                                            record.category  = { name: "scripting" }
                                                                                                                                                                                                                                                                                                                            record.startTime = Date.now()
                                                                                                                                                                                                                                                                                                                            record.data      = { timerId: id, timeout: timeout, singleShot: singleShot }
                                                                                                                                                                                                                                                                                                                            addStackTrace(record, 4)
                                                                                                                                                                                                                                                                                                                            Weinre.wi.TimelineNotify.addRecordToTimeline(record)
                                                                                                                                                                                                                                                                                                                            }); scooj.defStaticMethod(module, function addRecord_TimerFire(id, timeout, singleShot) {
                                                                                                                                                                                                                                                                                                                                                      if (!Timeline.isRunning()) return
                                                                                                                                                                                                                                                                                                                                                      var record = {}
                                                                                                                                                                                                                                                                                                                                                      record.type      = TimelineRecordType.TimerFire
                                                                                                                                                                                                                                                                                                                                                      record.category  = { name: "scripting" }
                                                                                                                                                                                                                                                                                                                                                      record.startTime = Date.now()
                                                                                                                                                                                                                                                                                                                                                      record.data      = { timerId: id, timeout: timeout, singleShot: singleShot }
                                                                                                                                                                                                                                                                                                                                                      Weinre.wi.TimelineNotify.addRecordToTimeline(record)
                                                                                                                                                                                                                                                                                                                                                      }); scooj.defStaticMethod(module, function addRecord_XHRReadyStateChange(method, url, id, xhr) {
                                                                                                                                                                                                                                                                                                                                                                                if (!Timeline.isRunning()) return
                                                                                                                                                                                                                                                                                                                                                                                var record
                                                                                                                                                                                                                                                                                                                                                                                if (xhr.readyState == XMLHttpRequest.OPENED) {
                                                                                                                                                                                                                                                                                                                                                                                record = {
                                                                                                                                                                                                                                                                                                                                                                                type:      TimelineRecordType.ResourceSendRequest,
                                                                                                                                                                                                                                                                                                                                                                                category:  { name: "loading" },
                                                                                                                                                                                                                                                                                                                                                                                startTime: Date.now(),
                                                                                                                                                                                                                                                                                                                                                                                data: { 
                                                                                                                                                                                                                                                                                                                                                                                identifier:     id,
                                                                                                                                                                                                                                                                                                                                                                                url:            url,
                                                                                                                                                                                                                                                                                                                                                                                requestMethod:  method
                                                                                                                                                                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                                                                                                                                                                else if (xhr.readyState == XMLHttpRequest.DONE) {
                                                                                                                                                                                                                                                                                                                                                                                record = {
                                                                                                                                                                                                                                                                                                                                                                                type:      TimelineRecordType.ResourceReceiveResponse,
                                                                                                                                                                                                                                                                                                                                                                                category:  { name: "loading" },
                                                                                                                                                                                                                                                                                                                                                                                startTime: Date.now(),
                                                                                                                                                                                                                                                                                                                                                                                data: {
                                                                                                                                                                                                                                                                                                                                                                                identifier:            id,
                                                                                                                                                                                                                                                                                                                                                                                statusCode:            xhr.status,
                                                                                                                                                                                                                                                                                                                                                                                mimeType:              xhr.getResponseHeader("Content-Type"),
                                                                                                                                                                                                                                                                                                                                                                                expectedContentLength: xhr.getResponseHeader("Content-Length"),
                                                                                                                                                                                                                                                                                                                                                                                url:                   url
                                                                                                                                                                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                                                                                                                                                                else 
                                                                                                                                                                                                                                                                                                                                                                                return
                                                                                                                                                                                                                                                                                                                                                                                Weinre.wi.TimelineNotify.addRecordToTimeline(record)
                                                                                                                                                                                                                                                                                                                                                                                }); scooj.defStaticMethod(module, function installGlobalListeners() {
                                                                                                                                                                                                                                                                                                                                                                                                          if (applicationCache) {
                                                                                                                                                                                                                                                                                                                                                                                                          applicationCache.addEventListener("checking",    function(e) {Timeline.addRecord_EventDispatch(e, "applicationCache.checking",    "loading")}, false)
                                                                                                                                                                                                                                                                                                                                                                                                          applicationCache.addEventListener("error",       function(e) {Timeline.addRecord_EventDispatch(e, "applicationCache.error",       "loading")}, false)
                                                                                                                                                                                                                                                                                                                                                                                                          applicationCache.addEventListener("noupdate",    function(e) {Timeline.addRecord_EventDispatch(e, "applicationCache.noupdate",    "loading")}, false)
                                                                                                                                                                                                                                                                                                                                                                                                          applicationCache.addEventListener("downloading", function(e) {Timeline.addRecord_EventDispatch(e, "applicationCache.downloading", "loading")}, false)
                                                                                                                                                                                                                                                                                                                                                                                                          applicationCache.addEventListener("progress",    function(e) {Timeline.addRecord_EventDispatch(e, "applicationCache.progress",    "loading")}, false)
                                                                                                                                                                                                                                                                                                                                                                                                          applicationCache.addEventListener("updateready", function(e) {Timeline.addRecord_EventDispatch(e, "applicationCache.updateready", "loading")}, false)
                                                                                                                                                                                                                                                                                                                                                                                                          applicationCache.addEventListener("cached",      function(e) {Timeline.addRecord_EventDispatch(e, "applicationCache.cached",      "loading")}, false)
                                                                                                                                                                                                                                                                                                                                                                                                          applicationCache.addEventListener("obsolete",    function(e) {Timeline.addRecord_EventDispatch(e, "applicationCache.obsolete",    "loading")}, false)
                                                                                                                                                                                                                                                                                                                                                                                                          }
                                                                                                                                                                                                                                                                                                                                                                                                          window.addEventListener("error",             function(e) {Timeline.addRecord_EventDispatch(e, "window.error")},             false)
                                                                                                                                                                                                                                                                                                                                                                                                          window.addEventListener("hashchange",        function(e) {Timeline.addRecord_EventDispatch(e, "window.hashchange")},        false)
                                                                                                                                                                                                                                                                                                                                                                                                          window.addEventListener("message",           function(e) {Timeline.addRecord_EventDispatch(e, "window.message")},           false)
                                                                                                                                                                                                                                                                                                                                                                                                          window.addEventListener("offline",           function(e) {Timeline.addRecord_EventDispatch(e, "window.offline")},           false)
                                                                                                                                                                                                                                                                                                                                                                                                          window.addEventListener("online",            function(e) {Timeline.addRecord_EventDispatch(e, "window.online")},            false)
                                                                                                                                                                                                                                                                                                                                                                                                          window.addEventListener("scroll",            function(e) {Timeline.addRecord_EventDispatch(e, "window.scroll")},            false)
                                                                                                                                                                                                                                                                                                                                                                                                          }); scooj.defStaticMethod(module, function installFunctionWrappers() {
                                                                                                                                                                                                                                                                                                                                                                                                                                    window.clearInterval  = wrapped_clearInterval
                                                                                                                                                                                                                                                                                                                                                                                                                                    window.clearTimeout   = wrapped_clearTimeout
                                                                                                                                                                                                                                                                                                                                                                                                                                    window.setTimeout     = wrapped_setTimeout
                                                                                                                                                                                                                                                                                                                                                                                                                                    window.setInterval    = wrapped_setInterval
                                                                                                                                                                                                                                                                                                                                                                                                                                    window.XMLHttpRequest.prototype.open = wrapped_XMLHttpRequest_open
                                                                                                                                                                                                                                                                                                                                                                                                                                    window.XMLHttpRequest                = wrapped_XMLHttpRequest
                                                                                                                                                                                                                                                                                                                                                                                                                                    }); function addStackTrace(record, skip) {
                                                                                                        if (!skip) skip = 1
                                                                                                        var trace = new StackTrace(arguments).trace
                                                                                                        record.stackTrace = []
                                                                                                        for (var i=skip; i<trace.length; i++) {
                                                                                                        record.stackTrace.push({
                                                                                                                               functionName: trace[i],
                                                                                                                               scriptName:   "",
                                                                                                                               lineNumber:   ""
                                                                                                                               })
                                                                                                        }
                                                                                                        }; function wrapped_setInterval(code, interval) {
                                                                                                        var code = instrumentedTimerCode(code, interval, false)
                                                                                                        var id = Native.setInterval(code, interval)
                                                                                                        code.__timerId = id
                                                                                                        addTimer(id, interval, false)
                                                                                                        return id
                                                                                                        }; function wrapped_setTimeout(code, delay) {
                                                                                                        var code = instrumentedTimerCode(code, delay, true)
                                                                                                        var id   = Native.setTimeout(code, delay)
                                                                                                        code.__timerId = id
                                                                                                        addTimer(id, delay, true)
                                                                                                        return id
                                                                                                        }; function wrapped_clearInterval(id) {
                                                                                                        var result = Native.clearInterval(id)
                                                                                                        removeTimer(id, false)
                                                                                                        return result
                                                                                                        }; function wrapped_clearTimeout(id) {
                                                                                                        var result = Native.clearTimeout(id)
                                                                                                        removeTimer(id, true)
                                                                                                        return result
                                                                                                        }; function addTimer(id, timeout, singleShot) {
                                                                                                        var timerSet = singleShot ? TimerTimeouts : TimerIntervals
                                                                                                        timerSet[id] = {
                                                                                                        id:          id,
                                                                                                        timeout:     timeout,
                                                                                                        singleShot: singleShot
                                                                                                        }
                                                                                                        Timeline.addRecord_TimerInstall(id, timeout, singleShot)
                                                                                                        }; function removeTimer(id, singleShot) {
                                                                                                        var timerSet = singleShot ? TimerTimeouts : TimerIntervals
                                                                                                        var timer = timerSet[id]
                                                                                                        if (!timer) return
                                                                                                        Timeline.addRecord_TimerRemove(id, timer.timeout, singleShot)
                                                                                                        delete timerSet[id]
                                                                                                        }; function instrumentedTimerCode(code, timeout, singleShot) {
                                                                                                        if (typeof(code) != "function") return code
                                                                                                        var instrumentedCode = function() {
                                                                                                        var result = code()
                                                                                                        var id     = arguments.callee.__timerId
                                                                                                        Timeline.addRecord_TimerFire(id, timeout, singleShot)
                                                                                                        return result
                                                                                                        }
                                                                                                        return instrumentedCode 
                                                                                                        }; function wrapped_XMLHttpRequest() {
                                                                                                        var xhr = new Native.XMLHttpRequest()
                                                                                                        IDGenerator.getId(xhr)
                                                                                                        xhr.addEventListener("readystatechange", getXhrEventHandler(xhr), false)
                                                                                                        return xhr
                                                                                                        }; 
                                                                                                        wrapped_XMLHttpRequest.UNSENT           = 0
                                                                                                        wrapped_XMLHttpRequest.OPENED           = 1
                                                                                                        wrapped_XMLHttpRequest.HEADERS_RECEIVED = 2
                                                                                                        wrapped_XMLHttpRequest.LOADING          = 3
                                                                                                        wrapped_XMLHttpRequest.DONE             = 4    
                                                                                                        function wrapped_XMLHttpRequest_open() {
                                                                                                        var xhr = this
                                                                                                        xhr.__weinre_method  = arguments[0]
                                                                                                        xhr.__weinre_url     = arguments[1]
                                                                                                        var result = Native.XMLHttpRequest_open.apply(xhr, [].slice.call(arguments))
                                                                                                        return result
                                                                                                        }; function getXhrEventHandler(xhr) {
                                                                                                        return function(event) {
                                                                                                        Timeline.addRecord_XHRReadyStateChange(xhr.__weinre_method, xhr.__weinre_url, IDGenerator.getId(xhr), xhr)
                                                                                                        }
                                                                                                        }; 
                                                                                                        var Running = false
                                                                                                        var TimerTimeouts  = {}
                                                                                                        var TimerIntervals = {}
                                                                                                        var TimelineRecordType = {
                                                                                                        EventDispatch:            0,
                                                                                                        Layout:                   1,
                                                                                                        RecalculateStyles:        2,
                                                                                                        Paint:                    3,
                                                                                                        ParseHTML:                4,
                                                                                                        TimerInstall:             5,
                                                                                                        TimerRemove:              6,
                                                                                                        TimerFire:                7,
                                                                                                        XHRReadyStateChange:      8,
                                                                                                        XHRLoad:                  9,
                                                                                                        EvaluateScript:          10,
                                                                                                        Mark:                    11,
                                                                                                        ResourceSendRequest:     12,
                                                                                                        ResourceReceiveResponse: 13,
                                                                                                        ResourceFinish:          14,
                                                                                                        FunctionCall:            15,
                                                                                                        ReceiveResourceData:     16,
                                                                                                        GCEvent:                 17,
                                                                                                        MarkDOMContent:          18,
                                                                                                        MarkLoad:                19,
                                                                                                        ScheduleResourceRequest: 20
                                                                                                        }
                                                                                                        Timeline.installGlobalListeners()
                                                                                                        Timeline.installFunctionWrappers()
                                                                                                        ;
                                                                                                        }});
                                                                                        
                                                                                        ;
                                                                                        
                                                                                        //==================================================
                                                                                        // file: interfaces/all-json-idls-min.js
                                                                                        //==================================================
                                                                                        require('weinre/common/Weinre').getClass().addIDLs([{"interfaces": [{"name": "InjectedScriptHost", "methods": [{"name": "clearConsoleMessages", "parameters": []}, {"name": "copyText", "parameters": [{"name": "text"}]}, {"parameters": [{"name": "nodeId"}], "name": "nodeForId"}, {"parameters": [{"name": "node"}, {"name": "withChildren"}, {"name": "selectInUI"}], "name": "pushNodePathToFrontend"}, {"name": "inspectedNode", "parameters": [{"name": "num"}]}, {"parameters": [{"name": "object"}], "name": "internalConstructorName"}, {"parameters": [], "name": "currentCallFrame"}, {"parameters": [{"name": "database"}], "name": "selectDatabase"}, {"parameters": [{"name": "storage"}], "name": "selectDOMStorage"}, {"name": "didCreateWorker", "parameters": [{"name": "id"}, {"name": "url"}, {"name": "isFakeWorker"}]}, {"name": "didDestroyWorker", "parameters": [{"name": "id"}]}, {"name": "nextWorkerId", "parameters": []}]}], "name": "core"}, {"interfaces": [{"name": "Inspector", "methods": [{"name": "addScriptToEvaluateOnLoad", "parameters": [{"name": "scriptSource"}]}, {"name": "removeAllScriptsToEvaluateOnLoad", "parameters": []}, {"name": "reloadPage", "parameters": [{"name": "ignoreCache"}]}, {"name": "populateScriptObjects", "parameters": []}, {"name": "openInInspectedWindow", "parameters": [{"name": "url"}]}, {"name": "setSearchingForNode", "parameters": [{"name": "enabled"}]}, {"name": "didEvaluateForTestInFrontend", "parameters": [{"name": "testCallId"}, {"name": "jsonResult"}]}, {"name": "highlightDOMNode", "parameters": [{"name": "nodeId"}]}, {"name": "hideDOMNodeHighlight", "parameters": []}, {"name": "highlightFrame", "parameters": [{"name": "frameId"}]}, {"name": "hideFrameHighlight", "parameters": []}, {"name": "setUserAgentOverride", "parameters": [{"name": "userAgent"}]}, {"name": "getCookies", "parameters": []}, {"name": "deleteCookie", "parameters": [{"name": "cookieName"}, {"name": "domain"}]}, {"name": "startTimelineProfiler", "parameters": []}, {"name": "stopTimelineProfiler", "parameters": []}, {"name": "enableDebugger", "parameters": []}, {"name": "disableDebugger", "parameters": []}, {"name": "enableProfiler", "parameters": []}, {"name": "disableProfiler", "parameters": []}, {"name": "startProfiling", "parameters": []}, {"name": "stopProfiling", "parameters": []}]}, {"name": "Runtime", "methods": [{"name": "evaluate", "parameters": [{"name": "expression"}, {"name": "objectGroup"}, {"name": "includeCommandLineAPI"}]}, {"name": "getCompletions", "parameters": [{"name": "expression"}, {"name": "includeCommandLineAPI"}]}, {"name": "getProperties", "parameters": [{"name": "objectId"}, {"name": "ignoreHasOwnProperty"}, {"name": "abbreviate"}]}, {"name": "setPropertyValue", "parameters": [{"name": "objectId"}, {"name": "propertyName"}, {"name": "expression"}]}, {"name": "releaseWrapperObjectGroup", "parameters": [{"name": "injectedScriptId"}, {"name": "objectGroup"}]}]}, {"name": "InjectedScript", "methods": [{"name": "evaluateOnSelf", "parameters": [{"name": "functionBody"}, {"name": "argumentsArray"}]}]}, {"name": "Console", "methods": [{"name": "setConsoleMessagesEnabled", "parameters": [{"name": "enabled"}]}, {"name": "clearConsoleMessages", "parameters": []}, {"name": "setMonitoringXHREnabled", "parameters": [{"name": "enabled"}]}]}, {"name": "Network", "methods": [{"name": "cachedResources", "parameters": []}, {"name": "resourceContent", "parameters": [{"name": "frameId"}, {"name": "url"}, {"name": "base64Encode"}]}, {"name": "setExtraHeaders", "parameters": [{"name": "headers"}]}]}, {"name": "Database", "methods": [{"name": "getDatabaseTableNames", "parameters": [{"name": "databaseId"}]}, {"name": "executeSQL", "parameters": [{"name": "databaseId"}, {"name": "query"}]}]}, {"name": "DOMStorage", "methods": [{"name": "getDOMStorageEntries", "parameters": [{"name": "storageId"}]}, {"name": "setDOMStorageItem", "parameters": [{"name": "storageId"}, {"name": "key"}, {"name": "value"}]}, {"name": "removeDOMStorageItem", "parameters": [{"name": "storageId"}, {"name": "key"}]}]}, {"name": "ApplicationCache", "methods": [{"name": "getApplicationCaches", "parameters": []}]}, {"name": "DOM", "methods": [{"name": "getChildNodes", "parameters": [{"name": "nodeId"}]}, {"name": "setAttribute", "parameters": [{"name": "elementId"}, {"name": "name"}, {"name": "value"}]}, {"name": "removeAttribute", "parameters": [{"name": "elementId"}, {"name": "name"}]}, {"name": "setTextNodeValue", "parameters": [{"name": "nodeId"}, {"name": "value"}]}, {"name": "getEventListenersForNode", "parameters": [{"name": "nodeId"}]}, {"name": "copyNode", "parameters": [{"name": "nodeId"}]}, {"name": "removeNode", "parameters": [{"name": "nodeId"}]}, {"name": "changeTagName", "parameters": [{"name": "nodeId"}, {"name": "newTagName"}]}, {"name": "getOuterHTML", "parameters": [{"name": "nodeId"}]}, {"name": "setOuterHTML", "parameters": [{"name": "nodeId"}, {"name": "outerHTML"}]}, {"name": "addInspectedNode", "parameters": [{"name": "nodeId"}]}, {"name": "performSearch", "parameters": [{"name": "query"}, {"name": "runSynchronously"}]}, {"name": "searchCanceled", "parameters": []}, {"name": "pushNodeByPathToFrontend", "parameters": [{"name": "path"}]}, {"name": "resolveNode", "parameters": [{"name": "nodeId"}]}, {"name": "getNodeProperties", "parameters": [{"name": "nodeId"}, {"name": "propertiesArray"}]}, {"name": "getNodePrototypes", "parameters": [{"name": "nodeId"}]}, {"name": "pushNodeToFrontend", "parameters": [{"name": "objectId"}]}]}, {"name": "CSS", "methods": [{"name": "getStylesForNode", "parameters": [{"name": "nodeId"}]}, {"name": "getComputedStyleForNode", "parameters": [{"name": "nodeId"}]}, {"name": "getInlineStyleForNode", "parameters": [{"name": "nodeId"}]}, {"name": "getAllStyles", "parameters": []}, {"name": "getStyleSheet", "parameters": [{"name": "styleSheetId"}]}, {"name": "getStyleSheetText", "parameters": [{"name": "styleSheetId"}]}, {"name": "setStyleSheetText", "parameters": [{"name": "styleSheetId"}, {"name": "text"}]}, {"name": "setPropertyText", "parameters": [{"name": "styleId"}, {"name": "propertyIndex"}, {"name": "text"}, {"name": "overwrite"}]}, {"name": "toggleProperty", "parameters": [{"name": "styleId"}, {"name": "propertyIndex"}, {"name": "disable"}]}, {"name": "setRuleSelector", "parameters": [{"name": "ruleId"}, {"name": "selector"}]}, {"name": "addRule", "parameters": [{"name": "contextNodeId"}, {"name": "selector"}]}, {"name": "getSupportedCSSProperties", "parameters": []}, {"name": "querySelectorAll", "parameters": [{"name": "documentId"}, {"name": "selector"}]}]}, {"name": "Timeline", "methods": []}, {"name": "Debugger", "methods": [{"name": "activateBreakpoints", "parameters": []}, {"name": "deactivateBreakpoints", "parameters": []}, {"name": "setJavaScriptBreakpoint", "parameters": [{"name": "url"}, {"name": "lineNumber"}, {"name": "columnNumber"}, {"name": "condition"}, {"name": "enabled"}]}, {"name": "setJavaScriptBreakpointBySourceId", "parameters": [{"name": "sourceId"}, {"name": "lineNumber"}, {"name": "columnNumber"}, {"name": "condition"}, {"name": "enabled"}]}, {"name": "removeJavaScriptBreakpoint", "parameters": [{"name": "breakpointId"}]}, {"name": "continueToLocation", "parameters": [{"name": "sourceId"}, {"name": "lineNumber"}, {"name": "columnNumber"}]}, {"name": "stepOver", "parameters": []}, {"name": "stepInto", "parameters": []}, {"name": "stepOut", "parameters": []}, {"name": "pause", "parameters": []}, {"name": "resume", "parameters": []}, {"name": "editScriptSource", "parameters": [{"name": "sourceID"}, {"name": "newContent"}]}, {"name": "getScriptSource", "parameters": [{"name": "sourceID"}]}, {"name": "setPauseOnExceptionsState", "parameters": [{"name": "pauseOnExceptionsState"}]}, {"name": "evaluateOnCallFrame", "parameters": [{"name": "callFrameId"}, {"name": "expression"}, {"name": "objectGroup"}, {"name": "includeCommandLineAPI"}]}, {"name": "getCompletionsOnCallFrame", "parameters": [{"name": "callFrameId"}, {"name": "expression"}, {"name": "includeCommandLineAPI"}]}]}, {"name": "BrowserDebugger", "methods": [{"name": "setAllBrowserBreakpoints", "parameters": [{"name": "breakpoints"}]}, {"name": "setDOMBreakpoint", "parameters": [{"name": "nodeId"}, {"name": "type"}]}, {"name": "removeDOMBreakpoint", "parameters": [{"name": "nodeId"}, {"name": "type"}]}, {"name": "setEventListenerBreakpoint", "parameters": [{"name": "eventName"}]}, {"name": "removeEventListenerBreakpoint", "parameters": [{"name": "eventName"}]}, {"name": "setXHRBreakpoint", "parameters": [{"name": "url"}]}, {"name": "removeXHRBreakpoint", "parameters": [{"name": "url"}]}]}, {"name": "Profiler", "methods": [{"name": "getProfileHeaders", "parameters": []}, {"name": "getProfile", "parameters": [{"name": "type"}, {"name": "uid"}]}, {"name": "removeProfile", "parameters": [{"name": "type"}, {"name": "uid"}]}, {"name": "clearProfiles", "parameters": []}, {"name": "takeHeapSnapshot", "parameters": [{"name": "detailed"}]}]}, {"name": "InspectorNotify", "methods": [{"parameters": [], "name": "frontendReused"}, {"parameters": [{"name": "nodeIds"}], "name": "addNodesToSearchResult"}, {"parameters": [], "name": "bringToFront"}, {"parameters": [], "name": "disconnectFromBackend"}, {"parameters": [{"name": "url"}], "name": "inspectedURLChanged"}, {"parameters": [{"name": "time"}], "name": "domContentEventFired"}, {"parameters": [{"name": "time"}], "name": "loadEventFired"}, {"parameters": [], "name": "reset"}, {"parameters": [{"name": "panel"}], "name": "showPanel"}, {"parameters": [{"name": "testCallId"}, {"name": "script"}], "name": "evaluateForTestInFrontend"}, {"parameters": [{"name": "nodeId"}], "name": "updateFocusedNode"}]}, {"name": "ConsoleNotify", "methods": [{"parameters": [{"name": "messageObj"}], "name": "addConsoleMessage"}, {"parameters": [{"name": "count"}], "name": "updateConsoleMessageExpiredCount"}, {"parameters": [{"name": "count"}], "name": "updateConsoleMessageRepeatCount"}, {"parameters": [], "name": "consoleMessagesCleared"}]}, {"name": "NetworkNotify", "methods": [{"parameters": [{"name": "frameId"}], "name": "frameDetachedFromParent"}, {"parameters": [{"name": "identifier"}, {"name": "url"}, {"name": "loader"}, {"name": "callStack"}], "name": "identifierForInitialRequest"}, {"parameters": [{"name": "identifier"}, {"name": "time"}, {"name": "request"}, {"name": "redirectResponse"}], "name": "willSendRequest"}, {"parameters": [{"name": "identifier"}], "name": "markResourceAsCached"}, {"parameters": [{"name": "identifier"}, {"name": "time"}, {"name": "resourceType"}, {"name": "response"}], "name": "didReceiveResponse"}, {"parameters": [{"name": "identifier"}, {"name": "time"}, {"name": "lengthReceived"}], "name": "didReceiveContentLength"}, {"parameters": [{"name": "identifier"}, {"name": "finishTime"}], "name": "didFinishLoading"}, {"parameters": [{"name": "identifier"}, {"name": "time"}, {"name": "localizedDescription"}], "name": "didFailLoading"}, {"parameters": [{"name": "time"}, {"name": "resource"}], "name": "didLoadResourceFromMemoryCache"}, {"parameters": [{"name": "identifier"}, {"name": "sourceString"}, {"name": "type"}], "name": "setInitialContent"}, {"parameters": [{"name": "frame"}, {"name": "loader"}], "name": "didCommitLoadForFrame"}, {"parameters": [{"name": "identifier"}, {"name": "requestURL"}], "name": "didCreateWebSocket"}, {"parameters": [{"name": "identifier"}, {"name": "time"}, {"name": "request"}], "name": "willSendWebSocketHandshakeRequest"}, {"parameters": [{"name": "identifier"}, {"name": "time"}, {"name": "response"}], "name": "didReceiveWebSocketHandshakeResponse"}, {"parameters": [{"name": "identifier"}, {"name": "time"}], "name": "didCloseWebSocket"}]}, {"name": "DatabaseNotify", "methods": [{"parameters": [{"name": "database"}], "name": "addDatabase"}, {"parameters": [{"name": "databaseId"}], "name": "selectDatabase"}, {"parameters": [{"name": "transactionId"}, {"name": "columnNames"}, {"name": "values"}], "name": "sqlTransactionSucceeded"}, {"parameters": [{"name": "transactionId"}, {"name": "sqlError"}], "name": "sqlTransactionFailed"}]}, {"name": "DOMStorageNotify", "methods": [{"parameters": [{"name": "storage"}], "name": "addDOMStorage"}, {"parameters": [{"name": "storageId"}], "name": "updateDOMStorage"}, {"parameters": [{"name": "storageId"}], "name": "selectDOMStorage"}]}, {"name": "ApplicationCacheNotify", "methods": [{"parameters": [{"name": "status"}], "name": "updateApplicationCacheStatus"}, {"parameters": [{"name": "isNowOnline"}], "name": "updateNetworkState"}]}, {"name": "DOMNotify", "methods": [{"parameters": [{"name": "root"}], "name": "setDocument"}, {"parameters": [{"name": "id"}, {"name": "attributes"}], "name": "attributesUpdated"}, {"parameters": [{"name": "id"}, {"name": "newValue"}], "name": "characterDataModified"}, {"parameters": [{"name": "parentId"}, {"name": "nodes"}], "name": "setChildNodes"}, {"parameters": [{"name": "root"}], "name": "setDetachedRoot"}, {"parameters": [{"name": "id"}, {"name": "newValue"}], "name": "childNodeCountUpdated"}, {"parameters": [{"name": "parentId"}, {"name": "prevId"}, {"name": "node"}], "name": "childNodeInserted"}, {"parameters": [{"name": "parentId"}, {"name": "id"}], "name": "childNodeRemoved"}]}, {"name": "TimelineNotify", "methods": [{"parameters": [], "name": "timelineProfilerWasStarted"}, {"parameters": [], "name": "timelineProfilerWasStopped"}, {"parameters": [{"name": "record"}], "name": "addRecordToTimeline"}]}, {"name": "DebuggerNotify", "methods": [{"parameters": [], "name": "debuggerWasEnabled"}, {"parameters": [], "name": "debuggerWasDisabled"}, {"parameters": [{"name": "sourceID"}, {"name": "url"}, {"name": "lineOffset"}, {"name": "columnOffset"}, {"name": "length"}, {"name": "scriptWorldType"}], "name": "parsedScriptSource"}, {"parameters": [{"name": "url"}, {"name": "data"}, {"name": "firstLine"}, {"name": "errorLine"}, {"name": "errorMessage"}], "name": "failedToParseScriptSource"}, {"parameters": [{"name": "breakpointId"}, {"name": "sourceId"}, {"name": "lineNumber"}, {"name": "columnNumber"}], "name": "breakpointResolved"}, {"parameters": [{"name": "details"}], "name": "pausedScript"}, {"parameters": [], "name": "resumedScript"}, {"parameters": [{"name": "id"}, {"name": "url"}, {"name": "isShared"}], "name": "didCreateWorker"}, {"parameters": [{"name": "id"}], "name": "didDestroyWorker"}]}, {"name": "ProfilerNotify", "methods": [{"parameters": [], "name": "profilerWasEnabled"}, {"parameters": [], "name": "profilerWasDisabled"}, {"parameters": [{"name": "header"}], "name": "addProfileHeader"}, {"parameters": [{"name": "uid"}, {"name": "chunk"}], "name": "addHeapSnapshotChunk"}, {"parameters": [{"name": "uid"}], "name": "finishHeapSnapshot"}, {"parameters": [{"name": "isProfiling"}], "name": "setRecordingProfile"}, {"parameters": [], "name": "resetProfiles"}, {"parameters": [{"name": "done"}, {"name": "total"}], "name": "reportHeapSnapshotProgress"}]}], "name": "core"}, {"interfaces": [{"name": "InspectorFrontendHost", "methods": [{"name": "loaded", "parameters": []}, {"name": "closeWindow", "parameters": []}, {"name": "disconnectFromBackend", "parameters": []}, {"name": "bringToFront", "parameters": []}, {"name": "inspectedURLChanged", "parameters": [{"name": "newURL"}]}, {"name": "requestAttachWindow", "parameters": []}, {"name": "requestDetachWindow", "parameters": []}, {"name": "setAttachedWindowHeight", "parameters": [{"name": "height"}]}, {"name": "moveWindowBy", "parameters": [{"name": "x"}, {"name": "y"}]}, {"name": "setExtensionAPI", "parameters": [{"name": "script"}]}, {"name": "localizedStringsURL", "parameters": []}, {"name": "hiddenPanels", "parameters": []}, {"name": "copyText", "parameters": [{"name": "text"}]}, {"parameters": [], "name": "platform"}, {"parameters": [], "name": "port"}, {"parameters": [{"name": "event"}, {"name": "items"}], "name": "showContextMenu"}, {"name": "sendMessageToBackend", "parameters": [{"name": "message"}]}]}], "name": "core"}, {"interfaces": [{"name": "WeinreClientCommands", "methods": [{"name": "registerClient", "parameters": []}, {"name": "getTargets", "parameters": []}, {"name": "getClients", "parameters": []}, {"name": "connectTarget", "parameters": [{"name": "clientId"}, {"name": "targetId"}]}, {"name": "disconnectTarget", "parameters": [{"name": "clientId"}]}, {"name": "getExtensions", "parameters": []}, {"name": "logDebug", "parameters": [{"name": "message"}]}, {"name": "logInfo", "parameters": [{"name": "message"}]}, {"name": "logWarning", "parameters": [{"name": "message"}]}, {"name": "logError", "parameters": [{"name": "message"}]}]}], "name": "weinre"}, {"interfaces": [{"name": "WeinreClientEvents", "methods": [{"name": "clientRegistered", "parameters": [{"name": "client"}]}, {"name": "targetRegistered", "parameters": [{"name": "target"}]}, {"name": "clientUnregistered", "parameters": [{"name": "clientId"}]}, {"name": "targetUnregistered", "parameters": [{"name": "targetId"}]}, {"name": "connectionCreated", "parameters": [{"name": "clientId"}, {"name": "targetId"}]}, {"name": "connectionDestroyed", "parameters": [{"name": "clientId"}, {"name": "targetId"}]}, {"name": "sendCallback", "parameters": [{"name": "callbackId"}, {"name": "result"}]}, {"name": "serverProperties", "parameters": [{"name": "properties"}]}]}], "name": "weinre"}, {"interfaces": [{"name": "WeinreTargetCommands", "methods": [{"name": "registerTarget", "parameters": [{"name": "url"}]}, {"name": "sendClientCallback", "parameters": [{"name": "callbackId"}, {"name": "args"}]}, {"name": "logDebug", "parameters": [{"name": "message"}]}, {"name": "logInfo", "parameters": [{"name": "message"}]}, {"name": "logWarning", "parameters": [{"name": "message"}]}, {"name": "logError", "parameters": [{"name": "message"}]}]}], "name": "weinre"}, {"interfaces": [{"name": "WeinreTargetEvents", "methods": [{"name": "connectionCreated", "parameters": [{"name": "clientId"}, {"name": "targetId"}]}, {"name": "connectionDestroyed", "parameters": [{"name": "clientId"}, {"name": "targetId"}]}, {"name": "sendCallback", "parameters": [{"name": "callbackId"}, {"name": "result"}]}]}], "name": "weinre"}])
                                                                                        ;
                                                                                        
                                                                                        require('weinre/target/Target').getClass().main()
                                                                                        })();