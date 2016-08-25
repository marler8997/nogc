import std.stdio  : writeln, writefln;
import std.process: spawnShell, wait;
import std.string : format;
import std.getopt : getopt;

int tryRun(string command)
{
  writefln("Executing: %s", command);
  auto pid = spawnShell(command);
  return wait(pid);
}
void run(string command)
{
  auto exitCode = tryRun(command);
  if(exitCode) {
    throw new Exception(format("last command failed (exit code %s)", exitCode));
  }
}

int main(string[] args)
{
  bool test = false;
  bool debugFlag = false;
  bool dmdFlagG = false;
  bool dmdFlagGs = false;
  getopt(args,
	 "t|test", &test,
         "debug", &debugFlag,
         "g", &dmdFlagG,
         "gs", &dmdFlagGs);
  
  run("cl -c clib.c");

  string extraDargs = "";
  if(test) {
    extraDargs ~= " -unittest";
  }
  if(debugFlag) {
    extraDargs ~= " -debug";
  }
  if(dmdFlagG) {
    extraDargs ~= " -g";
  }
  if(dmdFlagGs) {
    extraDargs ~= " -gs";
  }
  
  run(format("dmd%s -c -I. pns/errorHandling.d", extraDargs));
  run(format("dmd%s -c -I. pns/refcount.d", extraDargs));
  run(format("dmd%s -c -I. refcount.obj pns/std.d", extraDargs));
  run(format("dmd%s -c -I. pns/io.d", extraDargs));
  run(format("dmd%s -c -I. pns/format.d", extraDargs));
  run(format("dmd%s -c -I. pns/file.d", extraDargs));
  run(format("dmd%s -c -I. pns/utf8.d", extraDargs));

  //run("dmd -c -m32mscoff -betterC example.d");
  //run("cl example.obj test.c");
  
  if(test) {
    run("dmd -I. test.d errorHandling.obj refcount.obj std.obj file.obj format.obj io.obj utf8.obj");
  }

  return 0;
}
