import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_js/flutter_js.dart';
import 'memory_provider.dart';
import 'rule_models.dart';

/// Wraps flutter_js + Tau Prolog to provide a local Prolog reasoning engine.
///
/// Usage:
///   1. await init()          — load Tau Prolog into JS runtime (once)
///   2. consult(program)      — load facts + rules into a new session
///   3. query(goal, varNames) — run queries against the session (repeatable)
class PrologService {
  JavascriptRuntime? _runtime;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Load Tau Prolog engine into the embedded JS runtime.
  Future<void> init() async {
    if (_initialized) return;

    _runtime = getJavascriptRuntime();

    // Tau Prolog expects either `module` (Node.js) or `window` (browser).
    // QuickJS/JavaScriptCore has neither, so we provide stubs.
    _runtime!.evaluate('var module = {exports: {}};');
    _runtime!.evaluate(
      'var window = typeof globalThis !== "undefined" ? globalThis : {};',
    );
    // Tau Prolog (or its loader) may call document.getElementById etc.; stub on non-web so consult succeeds.
    _runtime!.evaluate(r'''
if (typeof document === 'undefined') {
  var _noop = function() { return null; };
  var _empty = { appendChild: _noop, add: _noop, children: [] };
  var document = {
    body: _empty,
    createElement: function() { return _empty; },
    getElementById: _noop,
    getElementsByTagName: function() { return []; },
    addEventListener: _noop
  };
}
''');

    // Load Tau Prolog core
    final tauSource =
        await rootBundle.loadString('assets/js/tau-prolog-core.js');
    _runtime!.evaluate(tauSource);

    // Resolve `pl` reference regardless of export path
    _runtime!.evaluate(
      'var pl = module.exports.pl || module.exports || window.pl;',
    );

    // Verify pl is loaded
    final check = _runtime!.evaluate('typeof pl.create');
    if (check.stringResult != 'function') {
      throw StateError(
        'Tau Prolog failed to load: pl.create is ${check.stringResult}',
      );
    }

    // Install query helper (after Tau so nothing overwrites __yomemo)
    _runtime!.evaluate(_helperJs);
    _runtime!.evaluate(r'''
__yomemo.programChunks = {};
__yomemo.setProgramChunk = function(i, c) { this.programChunks[i] = c; };
__yomemo.runConsultAndQueriesFromChunks = function(rulesJsonStr) {
  try {
    var rules = JSON.parse(rulesJsonStr);
    var s = '', i = 0;
    while (this.programChunks[i] !== undefined) { s += this.programChunks[i]; i++; }
    this.programChunks = {};
    this.session = pl.create();
    var session = this.session;
    var out = null;
    session.consult(s, {
      success: function() {
        var ruleResults = [];
        for (var r = 0; r < rules.length; r++) {
          var rule = rules[r];
          var varNames = rule.varNames;
          var rows = [];
          session.query(rule.query, { success: function() {}, error: function() {} });
          var done = false, limit = 500;
          while (!done && limit-- > 0) {
            session.answer({
              success: function(ans) {
                var row = {};
                if (ans && ans.links) {
                  for (var v = 0; v < varNames.length; v++) {
                    var name = varNames[v];
                    var term = ans.links[name];
                    if (term !== undefined && term !== null) {
                      if (typeof term.value !== "undefined" && typeof term.is_float !== "undefined") row[name] = term.value;
                      else if (term.id !== undefined) row[name] = term.id;
                      else row[name] = String(term);
                    } else row[name] = null;
                  }
                }
                rows.push(row);
              },
              error: function() { done = true; },
              fail: function() { done = true; },
              limit: function() { done = true; }
            });
          }
          ruleResults.push({ id: rule.id, rows: rows });
        }
        out = JSON.stringify({ ok: true, programLength: s.length, results: ruleResults });
      },
      error: function(e) {
        out = JSON.stringify({ ok: false, error: (e && (typeof e === "object" ? JSON.stringify(e) : String(e))) || "consult failed" });
      }
    });
    return out != null ? out : JSON.stringify({ ok: false, error: "consult async (no result)" });
  } catch(e) {
    return JSON.stringify({ ok: false, error: String(e) });
  }
};
''');

    _initialized = true;
    debugPrint('[PrologService] Tau Prolog engine ready');
  }

  static const String _runConsultAndQueriesFromChunksJs = r'''
function(rulesJsonStr) {
  try {
    var rules = JSON.parse(rulesJsonStr);
    var s = '', i = 0;
    while (this.programChunks[i] !== undefined) { s += this.programChunks[i]; i++; }
    this.programChunks = {};
    this.session = pl.create();
    var session = this.session;
    var out = null;
    session.consult(s, {
      success: function() {
        var ruleResults = [];
        for (var r = 0; r < rules.length; r++) {
          var rule = rules[r];
          var varNames = rule.varNames;
          var rows = [];
          session.query(rule.query, { success: function() {}, error: function() {} });
          var done = false, limit = 500;
          while (!done && limit-- > 0) {
            session.answer({
              success: function(ans) {
                var row = {};
                if (ans && ans.links) {
                  for (var v = 0; v < varNames.length; v++) {
                    var name = varNames[v];
                    var term = ans.links[name];
                    if (term !== undefined && term !== null) {
                      if (typeof term.value !== "undefined" && typeof term.is_float !== "undefined") row[name] = term.value;
                      else if (term.id !== undefined) row[name] = term.id;
                      else row[name] = String(term);
                    } else row[name] = null;
                  }
                }
                rows.push(row);
              },
              error: function() { done = true; },
              fail: function() { done = true; },
              limit: function() { done = true; }
            });
          }
          ruleResults.push({ id: rule.id, rows: rows });
        }
        out = JSON.stringify({ ok: true, programLength: s.length, results: ruleResults });
      },
      error: function(e) {
        out = JSON.stringify({ ok: false, error: (e && (typeof e === "object" ? JSON.stringify(e) : String(e))) || "consult failed" });
      }
    });
    return out != null ? out : JSON.stringify({ ok: false, error: "consult async (no result)" });
  } catch(e) {
    return JSON.stringify({ ok: false, error: String(e) });
  }
}
''';

  void _ensureRunConsultAndQueriesFromChunks() {
    _runtime!.evaluate('__yomemo.runConsultAndQueriesFromChunks = $_runConsultAndQueriesFromChunksJs');
  }

  /// Escape [s] for embedding inside a JS double-quoted string literal.
  static String _escapeForJs(String s) {
    return s
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r');
  }

  /// Load a Prolog program (facts + rules) into a new session.
  /// Returns null on success, error message on failure.
  /// Uses chunked transfer so long programs are not truncated by the JS bridge.
  String? consult(String program) {
    if (!_initialized) return 'PrologService not initialized';

    // Ensure chunk storage exists (Tau or other code may have overwritten __yomemo)
    _runtime!.evaluate(r'''__yomemo.programChunks={}; __yomemo.setProgramChunk=function(i,c){this.programChunks[i]=c;};''');

    const int chunkSize = 6000;
    int start = 0;
    int i = 0;
    while (start < program.length) {
      final end = (start + chunkSize) < program.length ? start + chunkSize : program.length;
      final rawChunk = program.substring(start, end);
      start = end;
      // Escape for JS string literal so stored value has real newlines (not literal \n)
      final chunkForEval = rawChunk
          .replaceAll(r'\', r'\\')
          .replaceAll('"', r'\"')
          .replaceAll('\n', r'\n')
          .replaceAll('\r', r'\r');
      final res = _runtime!.evaluate('__yomemo.setProgramChunk($i, "$chunkForEval")');
      if (res.stringResult.isEmpty && res.rawResult != null) {
        debugPrint('[PrologService] setProgramChunk($i) may have failed');
      }
      i++;
    }
    // Inline build + init in one eval (avoids relying on buildProgram method)
    final result = _runtime!.evaluate(r'''
(function(){
  var s='', i=0;
  while(__yomemo.programChunks[i]!==undefined){ s+=__yomemo.programChunks[i]; i++; }
  __yomemo.programChunks={};
  return __yomemo.init(s);
})()
''');

    try {
      final json = jsonDecode(result.stringResult) as Map<String, dynamic>;
      if (json['ok'] == true) {
        final len = json['programLength'];
        debugPrint('[PrologService] consult OK, programLength in JS: $len (chunks=$i)');
        return null;
      }
      return json['error']?.toString() ?? 'Unknown consult error';
    } catch (e) {
      return 'Consult parse error: ${result.stringResult}';
    }
  }

  /// Consult program (via chunks) and run all [rules] in the same JS execution; returns results or error.
  /// Use this so the session is not lost between consult and query.
  ({String? error, List<RuleResult>? results}) consultAndQueryAll(String program, List<Rule> rules) {
    if (!_initialized) {
      return (error: 'PrologService not initialized', results: null);
    }
    if (rules.isEmpty) {
      return (error: null, results: <RuleResult>[]);
    }
    _ensureRunConsultAndQueriesFromChunks();
    _runtime!.evaluate(r'''__yomemo.programChunks={}; __yomemo.setProgramChunk=function(i,c){this.programChunks[i]=c;};''');
    const int chunkSize = 6000;
    int start = 0;
    int i = 0;
    while (start < program.length) {
      final end = (start + chunkSize) < program.length ? start + chunkSize : program.length;
      final rawChunk = program.substring(start, end);
      start = end;
      final chunkForEval = rawChunk
          .replaceAll(r'\', r'\\')
          .replaceAll('"', r'\"')
          .replaceAll('\n', r'\n')
          .replaceAll('\r', r'\r');
      _runtime!.evaluate('__yomemo.setProgramChunk($i, "$chunkForEval")');
      i++;
    }
    final rulesPayload = rules.map((r) => {
      'id': r.id,
      'query': r.query,
      'varNames': r.resultVars.map((v) => v.name).toList(),
    }).toList();
    final rulesJson = jsonEncode(rulesPayload);
    final rulesForEval = rulesJson.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n').replaceAll('\r', r'\r');
    final result = _runtime!.evaluate('__yomemo.runConsultAndQueriesFromChunks("$rulesForEval")');
    try {
      final json = jsonDecode(result.stringResult) as Map<String, dynamic>;
      if (json['ok'] != true) {
        return (error: json['error']?.toString() ?? 'consult/query failed', results: null);
      }
      final ruleMap = {for (final r in rules) r.id: r};
      final results = <RuleResult>[];
      for (final item in (json['results'] as List)) {
        final m = Map<String, dynamic>.from(item as Map);
        final id = m['id'] as String?;
        final rule = id != null ? ruleMap[id] : null;
        if (rule == null) continue;
        final rows = (m['rows'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
        results.add(RuleResult(rule: rule, rows: rows, executedAt: DateTime.now()));
      }
      debugPrint('[PrologService] consultAndQueryAll OK, programLength=${json['programLength']}, ${results.length} rule(s)');
      return (error: null, results: results);
    } catch (e) {
      return (error: 'parse error: ${result.stringResult}', results: null);
    }
  }

  /// Execute a Prolog query and return all answer rows.
  /// Each row maps variable names (from [varNames]) to their bound values.
  List<Map<String, dynamic>> query(String goal, List<String> varNames) {
    if (!_initialized) return [];

    final jsGoal = _escapeForJs(goal);
    final encodedVars = jsonEncode(varNames);
    final result =
        _runtime!.evaluate('__yomemo.query("$jsGoal", $encodedVars)');

    try {
      final json = jsonDecode(result.stringResult) as Map<String, dynamic>;
      if (json['error'] != null) {
        debugPrint('[PrologService] Query error: ${json['error']}');
        return [];
      }
      final results = json['results'] as List;
      return results
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
    } catch (e) {
      debugPrint('[PrologService] Query parse error: $e');
      return [];
    }
  }

  // ────────── Fact Generation ──────────

  /// Convert a list of MemoryItems into Prolog fact clauses.
  static String memoriesToProlog(List<MemoryItem> memories) {
    final buf = StringBuffer();
    for (final m in memories) {
      final id = _atom(m.id);
      final handle = _atom(m.handle);
      final desc = _atom(m.description);
      buf.writeln('memory($id, $handle, $desc).');

      if (!m.hasFingerprint) continue;

      buf.writeln(
        'elap($id, ${m.elapE}, ${m.elapL}, ${m.elapA}, ${m.elapP}).',
      );

      if (m.layer.isNotEmpty) {
        buf.writeln('classification($id, ${_atom(m.layer)}).');
      }

      for (final tag in m.tags) {
        buf.writeln('tag($id, ${_atom(tag)}).');
      }

      if (m.ontologyMode.isNotEmpty) {
        buf.writeln(
          'ontology($id, ${_atom(m.ontologyMode)}, ${_atom(m.ontologyDep)}).',
        );
      }

      // Always emit vcs when hasFingerprint so rules like coding_project_score can succeed
      buf.writeln(
        'vcs($id, ${_atom(m.vcsStack)}, ${_atom(m.vcsStatus)}, ${_atom('')}).',
      );
    }
    return buf.toString();
  }

  /// Escape and single-quote a string as a Prolog atom.
  static String _atom(String s) {
    final escaped = s
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', ' ')
        .replaceAll('\r', '');
    return "'$escaped'";
  }

  void dispose() {
    _runtime?.dispose();
    _runtime = null;
    _initialized = false;
  }

  // ────────── JS Helper (embedded in runtime) ──────────

  static const String _helperJs = r'''
var __yomemo = {
  session: null,

  init: function(program) {
    try {
      var programLen = (program && typeof program === 'string') ? program.length : 0;
      this.session = pl.create();
      var ok = false;
      var errMsg = null;
      this.session.consult(program, {
        success: function() { ok = true; },
        error: function(e) {
          errMsg = e ? (typeof e === 'object' ? JSON.stringify(e) : String(e)) : 'consult error';
        }
      });
      if (!ok) return JSON.stringify({ok: false, error: errMsg || 'consult failed', programLength: programLen});
      return JSON.stringify({ok: true, programLength: programLen});
    } catch(e) {
      return JSON.stringify({ok: false, error: String(e)});
    }
  },

  query: function(goal, varNames) {
    try {
      if (!this.session) return JSON.stringify({error: 'no session'});

      var ok = false;
      var errMsg = null;
      this.session.query(goal, {
        success: function() { ok = true; },
        error: function(e) {
          errMsg = e ? (typeof e === 'object' ? JSON.stringify(e) : String(e)) : 'query error';
        }
      });

      if (!ok) {
        return JSON.stringify({error: errMsg || 'query failed'});
      }

      var results = [];
      var done = false;
      var safetyLimit = 500;

      while (!done && safetyLimit > 0) {
        safetyLimit--;
        this.session.answer({
          success: function(answer) {
            var row = {};
            if (answer && answer.links) {
              for (var i = 0; i < varNames.length; i++) {
                var name = varNames[i];
                var term = answer.links[name];
                if (term !== undefined && term !== null) {
                  // Num term (has value + is_float)
                  if (typeof term.value !== 'undefined' &&
                      typeof term.is_float !== 'undefined') {
                    row[name] = term.value;
                  }
                  // Atom / compound term
                  else if (term.id !== undefined) {
                    row[name] = term.id;
                  }
                  // Fallback
                  else {
                    row[name] = String(term);
                  }
                } else {
                  row[name] = null;
                }
              }
            }
            results.push(row);
          },
          error: function() { done = true; },
          fail: function() { done = true; },
          limit: function() { done = true; }
        });
      }

      return JSON.stringify({results: results});
    } catch(e) {
      return JSON.stringify({error: String(e)});
    }
  }
};
''';
}
