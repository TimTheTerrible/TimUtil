#!/usr/bin/perl -w

use strict;

use TimUtil;

# Custom error messages
use constant E_INVALID_TUNA => 100;

my %ErrorMessages = (
    (E_INVALID_TUNA)            => {
        title   => "E_INVALID_TUNA",
        message => "Sorry, Charlie!",
    },  
);


# Custom debug modes
use constant DEBUG_FISH => 0x00100010;

my %DebugModes = (
    (DEBUG_FISH)                => {
        name    => "fish",
        title   => "Fish",
        comment => "Fish-handling messages",
    },
);

# Command line arguments
our $Tuna = "Charlie";

my %ParamDefs = ( 
    "tuna" => {
        name    => "Tuna",
        type    => PARAMTYPE_STRING,
        var     => \$Tuna,
        usage   => "--tuna|-t",
        comment => "The name of the fish",
    },
);

# Example
register_error_messages(\%ErrorMessages);
register_debug_modes(\%DebugModes);
register_params(\%ParamDefs);

parse_args();

debugprint(DEBUG_FISH, "The tuna's name is %s", $Tuna);

if ( $Tuna ne "Charlie" ) {
    debugprint(DEBUG_ERROR, error_message(E_INVALID_TUNA));
}
