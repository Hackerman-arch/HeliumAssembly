import core.stdc.stdlib, std.stdio, std.file, std.string, std.regex, std.algorithm, std.conv;

int[string] buffers;

void main()
{
    printf("input filename:");
    string inpf = readln().strip;
    printf("output file: ");
    string outfinp =readln().strip;
    printf("output object: ");
    string object=readln().strip;
    printf("output exec: ");
    string exec=readln().strip;
    File file = File(inpf, "r");
    File outf = File(outfinp, "w+");
    foreach (line; file.byLine())
    {
        auto stripped = line.strip;
        if(stripped.startsWith("section "))
        {
            auto rest = stripped[8..$];
            outf.write(".section ");
            if(rest=="data")
                outf.writeln(".data");
            else
            {
                write("Error: Unknown section: ");
                writeln(stripped);
            }
        }
        if(stripped.startsWith("data: "))
        {
            auto datarest = stripped[6..$];
            auto dataparts = datarest.split(" ");
            auto name = dataparts[0].strip.idup;
            outf.write(name);
            outf.write(": ");
            auto type = dataparts[1].strip.idup;
            auto val = dataparts[2].strip.idup;
            auto valstr = val.strip.to!int;
            buffers[name] = valstr;
            if(type=="ascii")
            {
                outf.write(".ascii ");
                outf.writeln(val);
            }
            if(type=="space")
            {
                outf.write(".space ");
                outf.writeln(val);
            }
        }
        if(stripped.startsWith("start:"))
        {
            outf.write(".section .text\n.global _start\n_start:\n");
        }
        if(stripped.startsWith("set "))
        {
            outf.write("mov ");
            auto setrest = stripped[4..$];
            auto setparts = setrest.split(" ");
            auto target = setparts[0].strip.idup;
            auto source = setparts[1].strip.idup;
            if(target=="fd") outf.write("x0,");
            else if(target=="source") outf.write("x1,");
            else if(target=="arg2") outf.write("x2,");
            else if(target=="arg3") outf.write("x3,");
            else {outf.write(target); outf.write(",");}
            if(source.startsWith("d_")){
                outf.write("#");
                outf.write(source[2..$]);
                outf.write("\n");
            }
        }
        if(stripped.startsWith("load "))
        {
            outf.write("ldr ");
            auto loadrest = stripped[5..$];
            auto loadparts = loadrest.split(" ");
            auto ltarget = loadparts[0].strip.idup;
            auto lsource = loadparts[1].strip.idup;
            if(ltarget=="fd") outf.write("x0,");
            else if(ltarget=="source") outf.write("x1,");
            else if(ltarget=="arg2") outf.write("x2,");
            else if(ltarget=="arg3") outf.write("x3,");
            else {outf.write(ltarget);outf.write(",");}
            if(lsource.startsWith("d_")){
                outf.write("#");
                outf.write(lsource[2..$]);
                outf.write("\n");
            }
            if(lsource.startsWith("adr_"))
            {
                outf.write("=");
                outf.write(lsource[4..$]);
                outf.write("\n");
            }
        }
        if(stripped.startsWith("sys "))
        {
            auto sysc = stripped[4..$].strip;
            if(sysc=="write")
            {
                outf.write("mov x8, #");
                outf.writeln("64");
                outf.write("svc #0\n");
            }
            else if(sysc=="read")
            {
                outf.write("mov x8, #");
                outf.writeln("63");
                outf.write("svc #0\n");
            }
            else{
                outf.write("mov x8, #");
                outf.write(stripped[4..$]);
                outf.write("\n");
                outf.write("svc #0\n");
            }
        }
        if(stripped.startsWith("label "))
        {
            outf.write(stripped[6..$]);
            outf.write(":\n");
        }
        if(stripped.startsWith("call "))
        {
            outf.write("bl ");
            outf.writeln(stripped[5..$]);
        }
        if(stripped.startsWith("ret"))
        {
            writeln("RET FOUND!");
            outf.write("ret\n");
        }
        if(stripped.startsWith("Read "))
        {
            auto rrest = stripped[5..$].strip;
            auto rparts = rrest.split(",");
            auto src = rparts[0].strip.idup;
            auto len = rparts[1].strip.idup;
            auto cmplen = len.strip.to!int;
            if(cmplen>buffers[src])
            {
                writeln("Error: Programmer attempted to write bytes into a buffer more than the buffer's capacity.");
                writeln(stripped);
                break;
            }
            else
            {
                outf.write("mov x0, #0\nldr x1,=");
                outf.write(src);
                outf.write("\nmov x2, #");
                outf.write(len);
                outf.write("\nmov x8, #63\nsvc #0\n");
            }
        }
        if(stripped.startsWith("Write "))
        {
            auto wrest = stripped[6..$].strip;
            auto wparts = wrest.split(",");
            auto src = wparts[0].strip.idup;
            auto len = wparts[1].strip.idup;
            outf.write("mov x0, #1\nldr x1,=");
            outf.write(src);
            outf.write("\nmov x2, #");
            outf.write(len);
            outf.write("\nmov x8, #64\nsvc #0\n");
        }
        if(stripped.startsWith("add "))
        {
            auto addrest = stripped[4..$].strip;
            auto addparts = addrest.split(" ");
            auto firstarg = addparts[0].strip.idup;
            auto secndarg = addparts[1].strip.idup;
            outf.write("add ");
            outf.write(firstarg);
            outf.write(", ");
            outf.writeln(secndarg);
        }
        if(stripped.startsWith("exit "))
        {
            auto rettype = stripped[5..$].strip;
            if(rettype=="0")
            {
                outf.write("mov x0, #0\n");
            }
            else
            {
                outf.write("mov x0, #");
                outf.writeln(rettype);
            }
            outf.write("mov x8, #93\n");
            outf.writeln("svc #0");
        }

    }
    file.close();
    outf.close();
    system(("as "~outfinp~" -o "~object).toStringz());
    system(("ld "~object~" -o "~exec).toStringz());
}
