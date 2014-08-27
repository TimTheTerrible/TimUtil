= TimUtil

A perl library that provides enhanced debug output and command-line argument parsing.

== Features
* Debug Output Management
* Command Line Argument Parsing

== Custom Error Messages

```perl
use constant E_INVALID_TUNA => 100;

my %ErrorMessages = (
    (E_INVALID_TUNA)            => {
        title   => "E_INVALID_TUNA",
        message => "Sorry, Charlie!",
    },  
);
```

== Debug Output Management

TimUtil allows the coder to define custom debug output classes:

```perl
use constant DEBUG_FISH => 0x00100010;

my %DebugModes = (
    (DEBUG_FISH)                => {
        name    => "fish",
        title   => "Fish",
        comment => "Two Little Fishy",
    },
);
```

== Command Line Argument Parsing

Custom arguments are verbosely defined:

```perl
our $Tuna = "";

my %ParamDefs = ( 
    "tuna" => {
        name    => "Tuna",
        type    => PARAMTYPE_STRING,
        var     => \$Tuna,
        usage   => "--tuna|-t",
        comment => "The name of the fish",
    },
);
```

== Put it all Together

New debug modes, error messages, and parameters are registered:
```perl
register_error_messages(\%ErrorMessages);
register_debug_modes(\%DebugModes);
register_params(\%ParamDefs);
```

The debug modes to be displayed are specified on the command line, along
with named arguments:

```bash
[tcurrie@heimdall TimUtil]$ ./test.pl --debug=all
TimUtil::parse_args (696): Debug = all (4294967295)
TimUtil::parse_args (698): Returning No Error
main::main (49): the fish are swimming!
**ERROR** main::main (50): Sorry, Charlie!
```

