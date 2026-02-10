import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_js/flutter_js.dart';
import 'memory_provider.dart';

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

    // Install query helper
    _runtime!.evaluate(_helperJs);

    _initialized = true;
    debugPrint('[PrologService] Tau Prolog engine ready');
  }

  /// Load a Prolog program (facts + rules) into a new session.
  /// Returns null on success, error message on failure.
  String? consult(String program) {
    if (!_initialized) return 'PrologService not initialized';

    final encoded = jsonEncode(program);
    final result = _runtime!.evaluate('__yomemo.init($encoded)');

    try {
      final json = jsonDecode(result.stringResult) as Map<String, dynamic>;
      if (json['ok'] == true) return null;
      return json['error']?.toString() ?? 'Unknown consult error';
    } catch (e) {
      return 'Consult parse error: ${result.stringResult}';
    }
  }

  /// Execute a Prolog query and return all answer rows.
  /// Each row maps variable names (from [varNames]) to their bound values.
  List<Map<String, dynamic>> query(String goal, List<String> varNames) {
    if (!_initialized) return [];

    final encodedGoal = jsonEncode(goal);
    final encodedVars = jsonEncode(varNames);
    final result =
        _runtime!.evaluate('__yomemo.query($encodedGoal, $encodedVars)');

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

      if (m.vcsStatus.isNotEmpty) {
        buf.writeln(
          'vcs($id, ${_atom(m.vcsStack)}, ${_atom(m.vcsStatus)}, ${_atom('')}).',
        );
      }
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
      this.session = pl.create();
      var ok = false;
      var errMsg = null;
      this.session.consult(program, {
        success: function() { ok = true; },
        error: function(e) {
          errMsg = e ? (typeof e === 'object' ? JSON.stringify(e) : String(e)) : 'consult error';
        }
      });
      if (ok) return JSON.stringify({ok: true});
      return JSON.stringify({ok: false, error: errMsg || 'consult failed'});
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
