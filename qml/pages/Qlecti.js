/*
 Copyright (c) 2016, Amilcar Santos
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 
 * Neither the name of 'Qlecti' nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

.pragma library

var VERSION = '0.0.1';

// TODO:
//   - first(key, cb) ???
//   - .reduce() ????
//   - .expand() ????
// importar nomes da QList / QVector
//	- eachBack  -- each backwards / reverse
//	- mid(N, func()) e mid(N, C, func()) ---
//	- count(XXX,func()) ou ret().count(XXX) ?? --
//	- at(i, func1(), v|func2())) -- chama func1() se i valido ou 'v', chama func2() se invalido e 'v'=>func
//	- op().. append e prepend  -- inserir elementos
//	- ret().joinStrng(CC)   --- converte valores array para uma string, CC como separador


var on = function(qlection) {

	var _q;

	function _val() {
		return qlection;
	}
	function _next() {
		return _q;
	}

	function _filterCallback(f) {
		if (f instanceof RegExp) {
			return function(element) {
				return f.exec(element);
			}
		}
		if (f instanceof Function) {
//XXX			return function(v, k, e) {return f(k, v, e)};
			return f;
		}
		return function(element) {
			return f === element;
		}
	}
	function _compactCallback(word) {
		return [false, null, 0, ""].indexOf(word) < 0;
	}
	function _is(obj, typ) {
		if (typ instanceof RegExp) {
			return typ.exec(obj.toString());
		}
		return obj.toString().indexOf(typ) >= 0;
	}

	// process 'undefined'
	if (!qlection) {
		_q = {
			each: _next,
			empty: function(callback) {
				callback.call();
				return _q;
			},
			first: _next,
			last: _next,
			one: _next,
			op: function() {
				var __q = {
					each: _next,
					empty: _q.empty,
					first: _next,
					last: _next,
					one: _next,
					compact: _next,
					filter: _next
				};
				return __q;
			},
			ret: function() {
				return {
					val: _val
				}
			}
		}
		return _q;
	}

	// process 'QListModel'
	if (Qt.isQtObject(qlection)) {
		if (_is(qlection, "QQmlListModel")) {
			_q = {
				at: function(i, callback) {
					if (i >= 0 && qlection.count > i) {
						callback.call(_q, qlection.get(i), i);
					}
					return _q;
				},
				each: function(callback) {
					for (var idx = 0, t = qlection.count; idx < t; idx++) {
						if (callback.call(_q, qlection.get(idx), idx) === false) return _q;
					}
					return _q;
				},
				empty: function(callback) {
					if (qlection.count === 0) {
						callback.call();
					}
					return _q;
				},
				first: function(callback) {
					if (qlection.count > 0) {
						callback.call(_q, qlection.get(0), 0);
					}
					return _q;
				},
				last: function(callback) {
					var li = qlection.count - 1;
					if (li > 0) {
						callback.call(_q, qlection.get(li), li);
					}
					return _q;
				},
				one: function(callback) {
					if (qlection.count === 1) {
						callback.call(_q, qlection.get(0), 0);
					}
					return _q;
				},
				op: function(stats) {
					// operations...
					var p_q = _q;
					var __q = {
						each: p_q.each,
						empty: p_q.empty,
						first: p_q.first,
						last: p_q.last,
						one: p_q.one,
						compact: function(key) {
							if (!key) {
								key = 'name';
							}
							var word, arr = [];
							for (var idx = qlection.count - 1; idx >= 0; --idx) {
								word = qlection.get(idx)[key];
								if (word !== undefined && _compactCallback(word)) {
									arr.push(qlection.get(idx));
								}
							}
							return on(arr).op();
						},
						filter: function(callback) {
							var obj, arr = [];
							for (var idx = qlection.count - 1; idx >= 0; --idx) {
								obj = qlection.get(idx);
								if (callback(obj, idx, qlection) !== false) {
									arr.push(obj);
								}
							}
							return on(arr).op();
						},
						ret: p_q.ret
					};
					return __q;
				},
				ret: function() {
					return {
						val: _val
					}
				}
			}
			return _q;
		}
		if (_is(qlection, /QQml.*ItemModel.*|ModelObject/)) {
			_q = {
				each: function(callback) {
					var nhop = !qlection.hasOwnProperty;
					for (var key in qlection) {
						if (['objectName','model','hasModelChildren'].indexOf(key) < 0
								&& (nhop || qlection.hasOwnProperty(key))) {
							var v = qlection[key];
							if (!(typeof v === 'function' || (nhop && v === undefined))
								&& callback.call(_q, v, key) === false) return _q;
						}
					}
					return _q;
				}
			}
			return _q;
		}
		throw "Unsuported object";
	}

	// process 'arrays'
	if (qlection instanceof Array || (qlection.hasOwnProperty("length") && _is(qlection, "Arguments"))) {
		function _statsArray(currentCol, previousCol) {
			return {
				count: currentCol.length
			}
		}

		_q = {
			at: function(p, callback, defVal) {
				if (p < qlection.length) {
					callback.call(_q, qlection[p]);
				} else {
					if (defVal instanceof Function) {
						defVal.call(_q);
					} else {
						callback.call(_q, defVal);
					}
				}
				return _q;
			},
			each: function(callback) {
				for (var idx = 0, t = qlection.length; idx < t; idx++) {
					if (callback.call(_q, qlection[idx], idx) === false) return _q;
				}
				return _q;
			},
			empty: function(callback) {
				if (qlection.length === 0) {
					callback.call(_q);
				}
				return _q;
			},
			first: function(callback) {
				if (qlection.length > 0) {
					callback.call(_q, qlection[0], 0);
				}
				return _q;
			},
			last: function(callback) {
				var li = qlection.length - 1;
				if (li > 0) {
					callback.call(_q, qlection[li], li);
				}
				return _q;
			},
			one: function(callback) {
				if (qlection.length === 1) {
					callback.call(_q, qlection[0], 0);
				}
				return _q;
			},
			op: function (stats) {
				// operations...
				var _isArr = qlection instanceof Array;
				var p_q = _q;
				var __q = {
					each: p_q.each,
					empty: p_q.empty,
					first: p_q.first,
					last: p_q.last,
					one: p_q.one,
					val: p_q.val,
					compact: function() {
						var _qlection;
						if (_isArr) {
							_qlection = qlection.filter(_compactCallback);
						} else {
							var word;
							_qlection = []
							for (var idx = 0, t = qlection.length; idx < t; idx++) {
								word = qlection[idx];
								if (word !== undefined && _compactCallback(word)) {
									_qlection.push(word);
								}
							}
						}
						return on(_qlection).op(_statsArray(_qlection, qlection));
					},
					filter: function(filterCallback) {
						var _qlection = qlection.filter(_filterCallback(filterCallback));
						return on(_qlection).op(_statsArray(_qlection, qlection));
					},
					stats: function(callback) {
						if (stats) callback.call(__q, stats);
						return __q;
					},
					ret: p_q.ret
				}
				return __q;
			},
			ret: function() {
				return {
					val: _val
				}
			}
		};
		return _q;
	}

	// process 'string' or 'dates'
	if (qlection instanceof String || qlection instanceof Date) {
		_q = {
			each: function(callback) {
				if (qlection.toString() !== "") {
					callback.call(_q, 0, qlection);
				}
				return _q;
			},
			empty: function(callback) {
				if (qlection.toString() === "") {
					callback.call();
				}
				return _q;
			},
			first: function(callback) {
				callback.call(_q, 0, qlection);
				return _q;
			},
			last: _next,
			one: function(callback) {
				callback.call(_q, undefined, qlection);
				return _q;
			},
			op: function() {
				// modifier...
				throw "UNDER CONSTRUCTION";
			},
			ret: function() {
				return {
					val: _val
				}
			}
		}
		return _q;
	}

	// process 'map/object'
	_q = {
		each: function(callback) {
			for (var key in qlection) {
				if (callback.call(_q, qlection[key], key) === false) return _q;
			}
			return _q;
		},
		empty: function(callback) {
			if (qlection === {}) {
				callback.call();
			}
			return _q;
		},
		first: function() {
			throw "UNDER CONSTRUCTION";
		},
		last: function() {
			throw "UNDER CONSTRUCTION";
		},
		one: function(callback) {
			var key = Object.keys(qlection);
			if (key.length === 1) {
				callback.call(_q, key, qlection[key]);
			}
			return _q;
		},
		op: function (stats) {
			var __q = {
				filter: function(filterCallback) {
				// modifier...
			  //  var _qlection = qlection.filter(_filterCallback(filterCallback));
			 //   return on(_qlection);
				throw "UNDER CONSTRUCTION";
				},
				ret: _q.ret
			}
			return __q;
		},
		ret: function() {
			return {
				val: _val
			}
		}
	};
	return _q;
}


var ng = function() {

	var _g;

	function _initCurve() {
		var globalProp = "__qlecti_ng_easingObj";

		var easingObj = Qt.applicaton[globalProp];
		if (!easingObj) {
			var qml = 'import "easing.js" as Easing;'
			+ ' QtObject {'
			+ ' property var easingDef;'
			+ ' Component.onCompleted: easingDef = Easing.easing} ';
			easingObj = Qt.createQmlObject(qml, Qt.applicaton, 'qlecti.dynamic');
			Qt.applicaton[globalProp] = easingObj;
		}
	};

	_g = {
		easing: function(curve) {
			var _c = initCurve(curve);
			return {
				at: function(p, callback, defVal) {
					if (p <= _c.count) {
						callback.call(_g, _c.easingFunc((p / _c.count) * _c.last));
					} else {
						if (defVal instanceof Function) {
							defVal.call(_g);
						} else {
							callback.call(_g, defVal);
						}
					}
				},
				ret: function() {
					throw "TODO easing.ret...";
				}
			}
		},
		loop: function(m, c, callback) {
			if (!callback && (c instanceof Function)) {
				callback = c;
				c = m;
				m = 0;
			}
			for (var i = m, n = m + c, p = 1; i < n; i++, p++) {
				if (callback.call(_g, i, p) === false) return _g;
			}
			return _g;
		},
		loopBack: function(m, c, callback) {
			// FIXME
			if (!callback && (c instanceof Function)) {
				callback = n;
				n = m;
				m = 0;
			}
			for (var i = m, n = m + c; i > n; i--) {
				if (callback.call(_g, i) === false) return _g;
			}
			return _g;
		},
		range: function(m, n, callback) {
			if (!callback && (n instanceof Function)) {
				callback = n;
				n = m;
				m = 0;
			}
			for (var i = m; i < n; i++) {
				if (callback.call(_g, i) === false) return _g;
			}
			return _g;
		},
		rangeBack: function(m, n, callback) {
			// FIXME
			if (!callback && (n instanceof Function)) {
				callback = n;
				n = m;
				m = 0;
			}
			for (var i = m; i > n; i--) {
				if (callback.call(_g, i) === false) return _g;
			}
			return _g;
		}
	};
	return _g;
}

