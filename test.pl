#!/usr/bin/perl

use strict;

use TimUtil;

#
# Test Debug Stuff...
#

#use constant DEBUG_FISH		=> 0x00000010;
use constant DEBUG_FISH		=> 0x00100010;
use constant DEBUG_PARSE	=> 0x00000020;

my $modes = {
    (DEBUG_FISH)		=> {
        name	=> "fish",
        title	=> "Fish",
        comment => "Two Little Fishy",
    },
    (DEBUG_PARSE)	=> {
        name	=> "parse",
        title	=> "Parse",
        comment => "Parsing Messages",
    },
};

register_debug_modes($modes);

$Debug = DEBUG_TRACE | DEBUG_ERROR | DEBUG_WARN | DEBUG_FISH | DEBUG_PARSE | DEBUG_DUMP;
debugprint(DEBUG_TRACE, "New Debug Names: %s", debug_names($Debug));
debugprint(DEBUG_TRACE, "New Debug Flags: 0x%8.8x", debug_flags(debug_names($Debug)));

#
# Test Error Message Stuff...
#

use constant E_INVALID_TUNA		=> 100;
use constant E_ERRONEOUS_APOTHEGEM	=> 101;

my $messages = {
    (E_INVALID_TUNA)		=> {
        title	=> "E_INVALID_TUNA",
        message	=> "The mayonaise is yellow",
    },
    (E_ERRONEOUS_APOTHEGEM)	=> {
        title	=> "E_ERRONEOUS_APOTHEGEM",
        message	=> "Bullshit",
    },
};

register_error_messages($messages);

my $hash = mkhash(["huey","dewey","louie"], [10,"twenty",{top => "me", bottom => [0,3,9,27]}]);

debugdump(DEBUG_DUMP, "hash", $hash);

#
# Test arg parsing stuff...
#

my $Tuna = "Charley";
my $Int = 0;
my $Float = 0.0;
my $Bool = TRUE;
our $Extra;
our $Enum;

my %ParamDefs = (
    "tuna" => {
        name	=> "Tuna",
        type	=> PARAMTYPE_STRING,
        var	=> \$Tuna,
        usage	=> "--tuna|-t",
        comment	=> "The name of the fish",
    },
    "int" => {
        name	=> "Integer",
        type	=> PARAMTYPE_INT,
        var	=> \$Int,
        usage	=> "--int|-i",
        comment	=> "An integer argument",
    },
    "float" => {
        name	=> "Float",
        type	=> PARAMTYPE_FLOAT,
        var	=> \$Float,
        usage	=> "--float|-f",
        comment	=> "A floating-point argument",
    },
    "bool" => {
        name	=> "Bool",
        type	=> PARAMTYPE_BOOL,
        var	=> \$Bool,
        usage	=> "--bool|-b",
        comment	=> "A boolean argument",
    },
    "enum" => {
        name	=> "Enum",
        type	=> PARAMTYPE_ENUM,
        var	=> \$Enum,
        selectors	=> {
            "bottlenose" => 1,
            "yangtze"	 => 2,
            "blue"	 => 3,
        },
        usage	=> "--enum|-e",
        comment	=> "An enumerated argument",
    },
);

debugprint(DEBUG_TRACE, "Debug: %s (%s)", debug_names($Debug), $Debug);
debugprint(DEBUG_TRACE, "Tuna: %s", $Tuna);
debugprint(DEBUG_TRACE, "Int: %s", $Int);
debugprint(DEBUG_TRACE, "Float: %s", $Float);
debugprint(DEBUG_TRACE, "Bool: %s", $Bool ? "TRUE" : "FALSE");

register_params(\%ParamDefs);
if ( parse_args($ARGV) == E_NO_ERROR ) {
    debugprint(DEBUG_TRACE, "Arguments successfully parsed");
}
else {
    debugprint(DEBUG_ERROR, "Failed to parse arguments");
}

debugprint(DEBUG_TRACE, "Debug: %s (%s)", debug_names($Debug), $Debug);
debugprint(DEBUG_TRACE, "Tuna: %s", $Tuna);
debugprint(DEBUG_TRACE, "Int: %s", $Int);
debugprint(DEBUG_TRACE, "Float: %s", $Float);
debugprint(DEBUG_TRACE, "Bool: %s", $Bool ? "TRUE" : "FALSE");

debugprint(DEBUG_TRACE, "Add another param?");

my %ExtraParamDef = (
    extra	=> {
        name	=> "Extra",
        type	=> PARAMTYPE_BOOL,
        var	=> \$Extra,
        usage	=> "--extra|-e",
        comment	=> "An extra argument",
    },
);

register_params(\%ExtraParamDef);

debugdump(DEBUG_DUMP, "before", \@ARGV);
parse_args();
debugdump(DEBUG_DUMP, "after", \@ARGV);

my $options = { already => TRUE, };
parse_args($options);
debugdump(DEBUG_DUMP, "options", $options);
