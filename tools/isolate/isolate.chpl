use DateTime, FileSystem, Spawn;

config const compopts: string;
config const execopts: string;
config const startTestOpts: string;
config const linear = false;
config const help = false;

config var year, month, day: int;
config const testName: string;

if help {
  writeln("Usage: isolate [--compopts=<opts>] [--execopts=<opts>] [--startTestOpts=<opts>] [--linear=<true|false>] [--year=<year>] [--month=<month>] [--day=<day>] --testName=<path to test>");
  writeln("  * Make sure CHPL_HOME is correctly set and your shell is sitting in $CHPL_HOME");
  writeln("  * Default (year, month, day) is yesterday");
  writeln("  * If --linear is false (default) a binary search is used.");
  writeln("  * If --linear is true, a linear search is used. The linear search is more robust to potential errors, but slower.");
  writeln("  * --compopts and --execopts specify options to pass to start_test using the -compopts or -execopts options");
  writeln("  * --startTestOpts specifies options to pass directly to start_test");
  exit(0);
}

var chplhome: c_string;
sys_getenv(c"CHPL_HOME", chplhome);

if here.cwd() != chplhome:string {
  writeln("This program must be run from $CHPL_HOME");
  writeln("$CHPL_HOME=", chplhome:string);
  writeln("$CWD=", here.cwd());
  exit(1);
}

if testName == "" {
  writeln("The config constant testName must be set on the command line");
  writeln("using the option --testName=...");
  exit(1);
}

const oneDay = new timedelta(days=1);
const nowDay = date.today();

if year == 0 then
  year = (nowDay - oneDay).year;
if month == 0 then
  month = (nowDay - oneDay).month;
if day == 0 then
  day = (nowDay - oneDay).day;

var testdate = new date(year, month, day);

var logCommand = ["git", "log", "--first-parent", "--oneline",
                  "--after='" + testdate.isoformat() + " 00:00:00'",
                  "--before='" + (testdate+oneDay).isoformat() + " 00:00:00'"];

var sub = spawn(logCommand, stdout=PIPE);

var line: string;
var hashes: [0..-1] string;
var PRs: [0..-1] string;

while sub.stdout.readline(line) {
  // lines look like:
  // #hash## Merge pull request #PR# from user/branch
  // or (for Preston's squash+merges):
  // #hash## some text from commit message (#PR#)

  var splitLine: [0..-1] string;
  for word in line.split() {
    splitLine.push_back(word);
  }
  if splitLine[1] == "Merge" &&
     splitLine[2] == "pull" &&
     splitLine[3] == "request" {
    hashes.push_front(splitLine[0]);
    PRs.push_front(splitLine[4]);
  } else {
    var PR = splitLine[splitLine.numElements-1];
    hashes.push_front(splitLine[0]);
    PRs.push_front(PR[2..(PR.length-1)]);
  }
}

sub.wait();

writeln("Looking at hashes/PRs:");
for (hash, pr) in zip(hashes, PRs) {
  writeln("  ", hash, " ", pr);
}

if linear {
  linearSearch(hashes, PRs);
} else {
  binarySearch(hashes, PRs);
}

proc linearSearch(hashes, PRs) {
  for (hash, pr) in zip(hashes, PRs) {
    const checkout = ["git", "checkout", hash];
    var sub = spawn(checkout, stdout=PIPE, stderr=PIPE);
    sub.wait();

    if sub.exit_status != 0 {
      writeln("git checkout ", hash, " failed");
      exit(1);
    }

    if !exists(testName) {
      writeln(testName, " doesn't exist in PR ", pr, " - ", hash);
      checkoutMaster();
      continue;
    }

    const make = ["make", "-j3"];
    sub = spawn(make, stdout=PIPE, stderr=PIPE);
    sub.wait();

    if sub.exit_status != 0 {
      writeln("make failed for PR ", pr, " - ", hash);
      checkoutMaster();
      continue;
    }

    // run the test command
    var testCmd = ["start_test", testName];
    addCompExecOpts(testCmd);

    sub = spawn(testCmd, stdout=PIPE, stderr=PIPE);
    sub.wait();

    if sub.exit_status != 0 {
      writeln("start_test: PR ", pr, " - ", hash, " failed.");
    } else {
      writeln("start_test: PR ", pr, " - ", hash, " passed.");
    }

    checkoutMaster();
  }
}


proc binarySearch(hashes, PRs) {
  var results: [hashes.domain] string = "untested";
  var lo = hashes.domain.low,
      hi = hashes.domain.high;
  results[lo] = testHash(hashes[lo], PRs[lo]);
  results[hi] = testHash(hashes[hi], PRs[hi]);
  assert(results[lo] != results[hi], "low and high PRs had the same failure status: " + results[lo]);

  binarySearchHelper(results);

  writeln();

  for (hash, pr, result) in zip(hashes, PRs, results) {
    writeln(hash, " ", pr, " ", result);
  }

  proc binarySearchHelper(results) {
    var lo = results.domain.low,
        hi = results.domain.high,
        mid = (hi-lo)/2 + lo;

    if results[mid] != "untested" then
      return;

    results[mid] = testHash(hashes[mid], PRs[mid]);

    if results[mid] == results[lo] {
      binarySearchHelper(results[mid..hi]);
    } else {
      binarySearchHelper(results[lo..mid]);
    }
  }

  proc testHash(hash, pr) {
    const checkout = ["git", "checkout", hash];
    var sub = spawn(checkout, stdout=PIPE, stderr=PIPE);
    sub.wait();

    if sub.exit_status != 0 {
      writeln("git checkout ", hash, " failed");
      exit(1);
    }

    if !exists(testName) {
      writeln(testName, " doesn't exist in PR ", pr, " - ", hash);
      checkoutMaster();
      exit(1);
    }

    const make = ["make", "-j3"];
    sub = spawn(make, stdout=PIPE, stderr=PIPE);
    sub.wait();

    if sub.exit_status != 0 {
      writeln("make failed for PR ", pr, " - ", hash);
      checkoutMaster();
      exit(1);
    }

    // run the test command
    var testCmd = ["start_test", testName];
    addCompExecOpts(testCmd);

    sub = spawn(testCmd, stdout=PIPE, stderr=PIPE);
    sub.wait();

    var ret: string;
    if sub.exit_status != 0 {
      writeln("start_test: PR ", pr, " - ", hash, " failed");
      ret = "failed";
    } else {
      writeln("start_test: PR ", pr, " - ", hash, " passed");
      ret = "passed";
    }

    checkoutMaster();
    return ret;
  }
}


proc addCompExecOpts(testCmd: [] string) {
  if compopts != "" {
    for opt in compopts.split(" ") {
      testCmd.push_back("-compopts");
      testCmd.push_back(opt);
    }
  }
  if execopts != "" {
    for opt in execopts.split(" ") {
      testCmd.push_back("-execopts");
      testCmd.push_back(opt);
    }
  }
  if startTestOpts != "" {
    for opt in startTestOpts.split(" ") {
      testCmd.push_back(opt);
    }
  }
}

proc checkoutMaster() {
  const getMaster = ["git", "checkout", "master"];
  var sub = spawn(getMaster, stdout=PIPE, stderr=PIPE);
  sub.wait();
}
