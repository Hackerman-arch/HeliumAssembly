import core.stdc.stdlib, std.stdio, std.file, std.string, std.regex, std.algorithm, std.conv;

int[string] buffers;
string[string] asciis;
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
            {
                outf.writeln(".data");
                writeln("data section has been defined.");
            }
            else
            {
                write("Error: Unknown section: ");
                writeln(stripped);
            }
        }
        if(stripped.startsWith("data: "))
        {
            writeln("data found:");
            auto datarest = stripped[6..$];
            auto dataparts = datarest.split(", ");
            auto name = dataparts[0].strip.idup;
            outf.write(name);
            outf.write(": ");
            auto type = dataparts[1].strip.idup;
            auto val = dataparts[2].strip.idup;
            write("name: ");
            writeln(name);
            write("type: ");
            writeln(type);
            write("value: ");
            writeln(val);
            if(type=="ascii")
            {
                auto valascii = val.strip.idup;
                asciis[name]=valascii;
                outf.write(".ascii ");
                outf.writeln(val);
            }
            if(type=="space")
            {
                auto valstr = val.strip.to!int;
                buffers[name] = valstr;
                outf.write(".space ");
                outf.writeln(val);
            }
        }
        if(stripped.startsWith("start:"))
        {
            writeln("start found");
            outf.write(".section .text\n.global _start\n_start:\n");
        }
        if(stripped.startsWith("set "))
        {
            writeln("set found with arguments: ");
            outf.write("mov ");
            auto setrest = stripped[4..$];
            auto setparts = setrest.split(" ");
            auto target = setparts[0].strip.idup;
            auto source = setparts[1].strip.idup;
            write("target: ");
            writeln(target);
            write("source: ");
            writeln(source);
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
            else if(source.startsWith("r_"))
            {
                outf.writeln(source[2..$]);
            }
            else
            {
                writeln("Error: Unknown source type.");
                writeln(stripped);
            }
        }
        if(stripped.startsWith("load "))
        {
            writeln("load found with arguments: ");
            outf.write("ldr ");
            auto loadrest = stripped[5..$];
            auto loadparts = loadrest.split(" ");
            auto ltarget = loadparts[0].strip.idup;
            auto lsource = loadparts[1].strip.idup;
            write("target: ");
            writeln(ltarget);
            write("source: ");
            writeln(lsource);
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
            write("sys found with number: ");
            writeln(stripped[4..$]);
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
            write("label found with name: ");
            writeln(stripped[6..$]);
            outf.write(stripped[6..$]);
            outf.write(":\n");
        }
        if(stripped.startsWith("call "))
        {
            write("call found for: ");
            writeln(stripped[5..$]);
            outf.write("bl ");
            outf.writeln(stripped[5..$]);
        }
        if(stripped.startsWith("ret"))
        {
            writeln("ret found.");
            outf.write("ret\n");
        }
        if(stripped.startsWith("Read "))
        {
            writeln("Read found with arguments: ");
            auto rrest = stripped[5..$].strip;
            auto rparts = rrest.split(",");
            auto src = rparts[0].strip.idup;
            auto len = rparts[1].strip.idup;
            write("source: ");
            writeln(src);
            write("length: ");
            writeln(len);
            auto cmplen = len.strip.to!int;
            auto cmpname = src.strip.idup;
            if(!(src in asciis))
            {
                writeln("Error: Address not found.");
                writeln(stripped);
                break;
            }
            else if(cmplen>buffers[src])
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
            writeln("Write found with arguments: ");
            auto wrest = stripped[6..$].strip;
            auto wparts = wrest.split(",");
            auto src = wparts[0].strip.idup;
            auto len = wparts[1].strip.idup;
            write("source: ");
            writeln(src);
            write("length: ");
            writeln(len);
            outf.write("mov x0, #1\nldr x1,=");
            outf.write(src);
            outf.write("\nmov x2, #");
            outf.write(len);
            outf.write("\nmov x8, #64\nsvc #0\n");
        }
        if(stripped.startsWith("add "))
        {
            writeln("add found with arguments: ");
            auto addrest = stripped[4..$].strip;
            auto addparts = addrest.split(" ");
            auto firstarg = addparts[0].strip.idup;
            auto secndarg = addparts[1].strip.idup;
            auto rdarg = addparts[2].strip.idup;
            write("save to: ");
            writeln(firstarg);
            write("this plus: ");
            writeln(secndarg);
            write("this: ");
            writeln(rdarg);
            outf.write("add ");
            outf.write(firstarg);
            outf.write(", ");
            outf.write(secndarg);
            outf.write(", ");
            outf.writeln(rdarg);
        }
        if(stripped.startsWith("exit "))
        {
            write("exit found with return type: ");
            auto rettype = stripped[5..$].strip;
            writeln(rettype);
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
        if(stripped.startsWith("if "))
        {
            write("'if' found with comparison of: ");
            auto ifrest = stripped[3..$].strip;
            auto ifparts = ifrest.split(" ");
            auto firstarg = ifparts[0].strip.idup;
            auto op = ifparts[1].strip.idup;
            auto secondarg = ifparts[2].strip.idup;
            auto label = ifparts[3].strip.idup;
            write(firstarg);
            write(op);
            writeln(secondarg);
            outf.write("cmp ");
            outf.write(firstarg);
            outf.write(",");
            outf.writeln(secondarg);
            if(op=="==")
            {
                outf.write("beq ");
                outf.writeln(label);
            }
            else if(op=="!=")
            {
                outf.write("bne ");
                outf.writeln(label);
            }
            else if(op==">=")
            {
                outf.write("bgt ");
                outf.writeln(label);
            }
            else if(op=="<=")
            {
                outf.write("blt ");
                outf.writeln(label);
            }
        }

    }
    writeln("ASSEMBLY OUTPUT");
    file.close();
    outf.close();
    system(("as "~outfinp~" -o "~object).toStringz());
    system(("ld "~object~" -o "~exec).toStringz());
    system(("cat "~outfinp).toStringz());
}
