// Runtime test framework for the instrumented game (oNovaTests, Create event).
// A suite groups the test cases for one feature and names the game context it needs.
// A test case checks one behaviour; each Check inside it is one expectation.
// Test functions run with oNovaTests as self, so tests share state through instance
// variables, never through locals of another test.
persistent = true;
Stage = "title";
Ticks = 0;
Suites = [];
ReportSuites = [];
CurrentSuite = undefined;
CurrentTest = undefined;
Complete = false;
Capture = "";
CRTBenchmark = {};
AsyncQueue = [];
AsyncIndex = -1;
global.NovaTestInput = "";
global.NovaTestHeld = [];
global.NovaTestHUDDraws = 0;
global.NovaTestStatusDraws = 0;

// The device runner may limit a run to suites whose names contain one of these words.
Filter = [];
if (file_exists("nova-test-filter.txt")) {
    var filter_file = file_text_open_read("nova-test-filter.txt");
    while (!file_text_eof(filter_file)) {
        var word = string_lower(string_trim(file_text_readln(filter_file)));
        if (word != "") array_push(Filter, word);
    }
    file_text_close(filter_file);
}

function Flush() {
    var file = file_text_open_write("nova-test-report.json");
    file_text_write_string(file, json_stringify({complete: Complete, capture: Capture, crt_benchmark: CRTBenchmark, suites: ReportSuites}));
    file_text_close(file);
}

// Phases: "title", "menu" and "gameplay" run synchronously once their room is ready;
// "travel" runs multi-frame tests after gameplay. Navigation tests are required and
// run even when a filter excludes their suite, because later phases depend on them.
function Suite(name, phase, register, required = false) {
    CurrentSuite = {name: name, phase: phase, required: required, tests: [], before: undefined};
    array_push(Suites, CurrentSuite);
    register();
    CurrentSuite = undefined;
}
function Test(name, run) {
    array_push(CurrentSuite.tests, {name: name, run: run, step: undefined});
}
// Arranges state that every test of the suite needs; it runs once before the first test.
function BeforeAll(setup) {
    CurrentSuite.before = setup;
}
// start runs once; step runs every frame until it returns true.
function AsyncTest(name, start, step) {
    array_push(CurrentSuite.tests, {name: name, run: start, step: step});
}

function SuiteSelected(suite) {
    if (suite.required || array_length(Filter) == 0) return true;
    var name = string_lower(suite.name);
    for (var i = 0; i < array_length(Filter); i++) if (string_pos(Filter[i], name) > 0) return true;
    return false;
}
function ReportSuite(name) {
    for (var i = 0; i < array_length(ReportSuites); i++) if (ReportSuites[i].name == name) return ReportSuites[i];
    var entry = {name: name, tests: []};
    array_push(ReportSuites, entry);
    return entry;
}
function BeginTest(suite_name, test_name) {
    CurrentTest = {name: test_name, passed: true, checks: 0, failures: []};
    array_push(ReportSuite(suite_name).tests, CurrentTest);
}
function EndTest(require_checks = true) {
    if (CurrentTest == undefined) return;
    if (require_checks && CurrentTest.checks == 0) Fail("the test made no checks");
    CurrentTest = undefined;
    Flush();
}
function Fail(description) {
    CurrentTest.passed = false;
    array_push(CurrentTest.failures, description);
}
function Check(description, passed) {
    // Checks outside a test case (screenshot fixtures) are reported under their own suite.
    if (CurrentTest == undefined) BeginTest("Screenshots", "capture fixtures");
    CurrentTest.checks++;
    if (!passed) Fail(description);
}

// Runs every synchronous test of a phase and queues its multi-frame tests.
function RunPhase(phase) {
    AsyncQueue = [];
    AsyncIndex = -1;
    for (var s = 0; s < array_length(Suites); s++) {
        var suite = Suites[s];
        if (suite.phase != phase || !SuiteSelected(suite)) continue;
        if (suite.before != undefined) {
            try { suite.before(); } catch (error) {
                BeginTest(suite.name, "suite setup");
                Fail("exception: " + string(error));
                CurrentTest.checks++;
                EndTest();
                continue;
            }
        }
        for (var t = 0; t < array_length(suite.tests); t++) {
            var test = suite.tests[t];
            if (test.step != undefined) {
                array_push(AsyncQueue, {suite: suite.name, test: test});
                continue;
            }
            BeginTest(suite.name, test.name);
            try { test.run(); } catch (error) { Fail("exception: " + string(error)); }
            EndTest();
        }
    }
    return AsyncNext();
}
// Returns true once every queued multi-frame test has finished.
function AsyncNext() {
    AsyncIndex++;
    if (AsyncIndex >= array_length(AsyncQueue)) return true;
    var entry = AsyncQueue[AsyncIndex];
    BeginTest(entry.suite, entry.test.name);
    try { entry.test.run(); } catch (error) { Fail("exception: " + string(error)); EndTest(); return AsyncNext(); }
    Flush();
    return false;
}
function AsyncStep() {
    if (AsyncIndex >= array_length(AsyncQueue)) return true;
    var done = false;
    try { done = AsyncQueue[AsyncIndex].test.step(); } catch (error) { Fail("exception: " + string(error)); done = true; }
    if (!done) return false;
    EndTest();
    return AsyncNext();
}

// Screenshot modes run when the runner enables one of their flag files. Each mode reports
// as a test in the Screenshots suite; its start function sets Capture and its step
// function returns true once its last screenshot is taken.
function CapturePlan(modes, first_only) {
    CaptureModes = [];
    for (var i = 0; i < array_length(modes); i++) {
        var enabled = false;
        for (var f = 0; f < array_length(modes[i].flags); f++) enabled = enabled || file_exists(modes[i].flags[f]);
        if (!enabled) continue;
        array_push(CaptureModes, modes[i]);
        if (first_only) break;
    }
    CaptureModeIndex = -1;
    return CaptureNextMode();
}
function CaptureNextMode() {
    EndTest(false);
    Capture = "";
    CaptureModeIndex++;
    if (CaptureModeIndex >= array_length(CaptureModes)) { Flush(); return true; }
    BeginTest("Screenshots", CaptureModes[CaptureModeIndex].name);
    CaptureModes[CaptureModeIndex].start();
    Flush();
    return false;
}
function CaptureModeStep() {
    if (!CaptureModes[CaptureModeIndex].step()) return false;
    return CaptureNextMode();
}

// Input substitution: the instrumented build reads global.NovaTestInput at the input boundary.
function PressEvent(target, verb, object, kind, number) {
    input_clear_momentary(false);
    global.NovaTestInput = verb;
    // Each simulated press starts a fresh frame, including after a profile change.
    var verbs = is_array(verb) ? verb : [verb];
    for (var i = 0; i < array_length(verbs); i++) {
        var state = variable_struct_get(__input_global().__players[0].__verb_state_dict, verbs[i]);
        if (is_struct(state)) state.__inactive = false;
    }
    with (target) event_perform_object(object, kind, number);
    global.NovaTestInput = "";
}
