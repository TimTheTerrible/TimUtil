TimUtil
=======

A perl library that provides enhanced debug output and command-line argument parsing.

Features
========

Debug Output Management
Command Line Argument Parsing

Debug Output Management
=======================

TimUtil allows the coder to define custom debug output classes:

use constant DEBUG_FISH => 0x00100010;
register_debug_mode(
{
    (DEBUG_FISH)		=> {
        name	=> "fish",
        title	=> "Fish",
        comment => "Two Little Fishy",
    },
);

Calls to debugprint() specify the debug mode and the message:

debugprint(DEBUG_FISH, "The fish are swimming");

The modes to be displayed are then
specified on the command line:

./myscript.pl --debug=info,warn,trace

main::main (154): The fish are swimming!

Command Line Argument Parsing
=============================

my %ParamDefs = (
    "tuna" => {
        name	=> "Tuna",
        type	=> PARAMTYPE_STRING,
        var	=> \$Tuna,
        usage	=> "--tuna|-t",
        comment	=> "The name of the fish",
    },
);
