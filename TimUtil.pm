#BEGIN{ open(STDERR, ">/tmp/TimUtil_output.err") or die("Can't open STDERR!"); }
package TimUtil;

#
# This module provides the following services:
# - A system for generating and managing debug output
# - A system for generating and managing error messages
# - A system for parsing command line options with Getopt::Long
#
# Debugging
# =========
# Functions provided:
# - debugprint(DEBUG_FLAG, "print format string", (args))
# debugrint() will print the formatted args to STDERR if the specified flag is set in $TimUtil::Debug
#
# - debugdump(DEBUG_FLAG, "variable name", \reference)
# debugdump() uses Data::Dumper to print a nicely-formatted dump of the supplied reference to STDERR
# if the specified flag is set in $TimUtil::Debug.
#
# - register_debug_mode({debug mode spec}) and register_debug_modes([{mode_spec},{mode_spec},...])
# These functions add the specified mode specifier(s) to the internal table. The mode specifier is a
# hash containing a single element, named for the bitmask flag corresponding to the new mode. The
# contents of the element are the name of the mode, used in getting and setting the debug modes, and
# the title of the new mode, used in formatted output.
#
# In order to add a debug mode, you must first define a constant that specifies the flag value, which
# must be unique:
#
# use contant DEBUG_TUNA	=> 0x00000010;
#
# Then, you define the name and title of the new mode:
#
# my %debug_modes = (
#     (DEBUG_TUNA)	=> {
#         name	=> "tuna",
#         title	=> "DEBUG_TUNA",
#     },
# );
#
# Finally, register the new mode:
#
# register_debug_modes(\%debug_modes);
#
# Now, when you call
#
#   debugprint(DEBUG_TUNA, "Sorry Charlie");
#
# The message will only be printed if
#
#   $TimUtil::Debug & DEBUG_TUNA == DEBUG_TUNA;
#
# Error Messages
# ==============
# Functions Provided:
# - register_error_message([$hashref,$hashref,...])
# register_error_messages() works just like register_debug_modes(), in that it takes a list of error
# message specifiers and adds the described messages to the internal table.
#
# - error_message($errno)
# error_message() will return the error message which corresponds to the given error number, if such
# exists in the internal table.
#
# In order to use error_message(), you must first define a constant the specifies the error number, which
# must be unique:
#
# use constant E_STINKY_TUNA	=> 100;
#
# Then, you define the name and text of the new message:
#
# my %error_messages = (
#     (E_STINKY_TUNA)	=> {
#         title	=> "E_STINKY_TUNA",
#         message	=> "The Tuna is Ripe",
#     },
# );
#
# Now, your functions can return E_STINKY_TUNA and the caller can let you know what went wrong by
# calling error_message(), supplying the error number returned and printing the result.
#
# Or, tie the two systems together:
#   debugprint(DEBUG_TUNA, "Sorry, Charlie: %s (%d)", error_message($errno), $errno);
#
# Argument Parsing
# ================
# Functions Provided:
# - register_param($paramname,$paramdef), register_params({paramname => { paramdef}, ...})
# register_param() works just like register_debug_modes() and register_error_message(), in that it takes
# a list of parameter definitions and adds them to the internal table.
#
# - parse_args()
# parse_args() calls Getopt::Long::GetOptions() to pre-parse the command line arguments, then conducts
# further processing based on the prameter definitions supplied to register_param().
#
# In order to use the argument parsing functionality, you must provide a hash or a list of hashes
# containing the parameter specifier(s) for the command line argument(s) you wish to parse. A parameter specifier
# is a hash element whose key is the text name of the option to parse, and whose value is a hash of options
# defining the option.
#
# For example:
# my %param = (
#     "test"	=> {				# The actual parameter name used to match the argument list
#         name		=> "Test",		# A fancy text name used to describe the parameter (not used)
#         type		=> PARAMTYPE_BOOL,	# A flag specifying how to to process the argument
#         var		=> \$Test,		# A reference to the variable to receive the parsed argument
#         usage		=> "--test|-t",		# A sample invocation of the option and any arguments
#         comment	=> "Set the TEST flag",	# A brief comment about the option
#     },
# );
#
# Register this parameter specifier like so:
#     register_param(\%param);
#
# At some point (hopefully fairly early) your program must call parse_args() to actually read in and process
# the command line arguments. When this happens, parse_args() will parse the command line using Getopt::Long,
# treating the values returned according to the registered parameter specifiers.
#
# NOTE: TimUtil defines various default options. Please read the code for details.
#
# TODO: These things would make TimUtil even cooler.
#
# Paramter Management
#  - Add an optional "required" flag to parameters
#  - Add support for incrementable parameters (-vvv)
#  - Add support for list and multiple values (--libs=/usr/lib,/lib and --libs /usr/lib /lib)
#
# Debugging
#  - Meta-flags such as DEBUG_TEST == DEBUG_ERROR & DEBUG_TRACE & DEBUG_DB; DEBUG_MOST == DEBUG_ALL ^ DEBUG_DUMP
#
# Error Message Management
#

use strict;
use Getopt::Long;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
    TRUE
    FALSE
    SUCCESS
    FAILURE
    register_debug_modes
    register_debug_mode
    debug_flags
    debug_names
    debugprint
    debugdump
    DEBUG_NONE
    DEBUG_ERROR
    DEBUG_WARN
    DEBUG_TRACE
    DEBUG_DUMP
    DEBUG_INFO
    DEBUG_ALL
    $Debug
    $TestOnly
    register_error_messages
    register_error_message
    error_message
    E_NO_ERROR
    E_INVALID_ARGS
    E_HOST_UNAVAIL
    E_HOST_UNAVAILABLE
    @ErrorLog
    PARAMTYPE_STRING
    PARAMTYPE_INT
    PARAMTYPE_FLOAT
    PARAMTYPE_FUNC
    PARAMTYPE_BOOL
    PARAMTYPE_ENUM
    register_params
    register_param
    parse_args
    usage
    mkhash
    $Environment
);

#
# Constants
#

use constant TRUE		=> 1;
use constant FALSE		=> 0;

use constant SUCCESS		=> 1;
use constant FAILURE		=> 0;

#
# Global Variables
#

our @ErrorLog;

#
# Debug Mode Definitions
#
# Reservation Map
# Columns 0..1 are reserved for user applications
# Column 2 is reserved for TimCGI
# Column 3 is reserved for TimApp
# Column 4 is reserved for TimObj
# Column 5 is reserved for TimDB
# Columns 6 & 7 are reserved for TimUtil itself

use constant DEBUG_NONE		=> 0x00000000;
use constant DEBUG_ERROR	=> 0x10000000;
use constant DEBUG_WARN 	=> 0x20000000;
use constant DEBUG_TRACE	=> 0x40000000;
use constant DEBUG_DUMP		=> 0x80000000;
use constant DEBUG_INFO		=> 0x01000000;
use constant DEBUG_RESERVED	=> 0xFFFFFF00;
use constant DEBUG_ALL		=> 0xFFFFFFFF;
use constant DEBUG_EXPLICIT	=> 1;

my %DebugFlags = ();
my %DebugNames = ();

my %DefaultDebugModes = (
    (DEBUG_NONE)	=> {
        name	=> "none",
        title	=> "DEBUG_NONE",
    },
    (DEBUG_ERROR)	=> {
        name	=> "error",
        title	=> "DEBUG_ERROR",
    },
    (DEBUG_WARN)	=> {
        name	=> "warn",
        title	=> "DEBUG_WARN",
    },
    (DEBUG_TRACE)	=> {
        name	=> "trace",
        title	=> "DEBUG_TRACE",
    },
    (DEBUG_DUMP)	=> {
        name	=> "dump",
        title	=> "DEBUG_DUMP",
    },
    (DEBUG_INFO)	=> {
        name	=> "info",
        title	=> "DEBUG_INFO",
    },
    (DEBUG_ALL)	=> {
        name	=> "all",
        title	=> "DEBUG_ALL",
    },
);

# Default Debug Mode...
our $Debug = DEBUG_ERROR | DEBUG_WARN;
#$Debug = DEBUG_ALL ^ DEBUG_DUMP;
$Debug = DEBUG_ALL if $ENV{DEBUG_ALL};

#
# Debug Mode Functions
#

sub register_debug_modes
{
    my ($modes) = @_;

    foreach my $mode ( keys(%$modes) ) {
        register_debug_mode($mode, $$modes{$mode});
    }
}

sub register_debug_mode
{
    my ($mode,$definition) = @_;

    debugprint(DEBUG_TRACE, "Mode: 0x%8.8x", $mode);

    # No duplicate flags allowed...
    debugdump(DEBUG_DUMP, "DebugNames", \%DebugNames);
    die("Attempt to register duplicate debug flag " . sprintf("0x%8.8x", $mode))
        if exists($DebugNames{$mode});

    # Clamp to DEBUG_ALL...
    die("Attempt to register debug mode > DEBUG_ALL")
        if $mode > DEBUG_ALL;

# TODO: Fix this...
#    # Don't use the reserved bits...
#    my $overlap = $mode & DEBUG_RESERVED;
#    debugprint(DEBUG_TRACE, "mode mask overlap: 0x%8.8x", $overlap);
#    if ( ($mode != DEBUG_ALL) and ($mode & DEBUG_RESERVED != $mode ^ DEBUG_RESERVED) ) {
#        debugprint(DEBUG_TRACE, "mode overlaps");
#        die(sprintf("Attempt to register reserved debug mode: 0x%8.8x", $mode));
#    }
#    else {
#        debugprint(DEBUG_TRACE, "mode does not overlap");
#    }

    # Qualify the definiton...

    # No duplicate names allowed...
    die("Attempt to register duplicate debug name '" . $$definition{name} . "'")
        if exists($DebugFlags{$$definition{name}});

    # No null names or titles allowed...
    die("Attempt to register null debug name or title for mode " . sprintf("0x%8.8x", $mode))
        if ( $$definition{name} eq "" or $$definition{title} eq "" );

    debugprint(DEBUG_TRACE, "Registered New Mode: '%s' => '%s' (%s)",
        $$definition{title}, $$definition{name}, $$definition{comment});

    # Save the definition...
    $DebugNames{$mode} = $definition;

    # Map the name back to the mode...
    $DebugFlags{$$definition{name}} = $mode;
}

sub debug_flags
{
    my ($names) = @_;
    my $result = DEBUG_NONE;

    # Iterate over a list of names...
    foreach my $name ( split(',',$names) ) {

        # If it's a valid registered debug mode...
        if ( exists($DebugFlags{$name}) ) {

            # OR it's flag onto the result...
            $result = $result | $DebugFlags{$name};
        }
        else {
            debugprint(DEBUG_ERROR, "Invalid debug mode: '%s'", $name);
        }
    }

    return $result;
}

sub debug_names
{
    my ($flags,$explicit) = @_;
    my $result;

    # If it's all just say all...
    if ( ($flags & DEBUG_ALL) == DEBUG_ALL and ($explicit != DEBUG_EXPLICIT) ) {
        return "all";
    }

    # Iterate over all registered modes...
    foreach my $mode ( keys(%DebugNames) ) {

        # Don't detect DEBUG_NONE...
        next if $mode == 0;

        # If the mode's flag is set...
        if ( ($flags & $mode) == $mode ) {

            # Add a comma if we've already added a mode name...
            $result .= "," if $result;

            # ...and add the mode name...
            $result .= $DebugNames{$mode}{name}
        }
    }

    # This shouldn't be necessary, but chop off any trailing comma...
    #$result =~ s/,$//g while $result =~ /,$/;

    return $result;
}

sub debugprint
{
    my ($flag, $fmt, @args) = @_;

    my ($package,$filename,$line) = caller;
    my ($blah1,$blah2,$blah6,$subroutine,$hasargs,$wantarray) = caller(1);

    if ( $Debug & $flag ) {

        # STFU, Perl!!!
        # Added to supress "Use of uninitialized value in sprintf" warnings.
        no warnings;
        my $output = sprintf("%s%s (%s): %s\n",
            (DEBUG_ERROR & $flag) ? "**ERROR** ":"",
            $subroutine ne "" ? $subroutine : "main::main",
            $line,
            sprintf($fmt, @args),
        );
        printf(STDERR $output);
        use warnings;

        if ( DEBUG_ERROR & $flag ) {
            push(@ErrorLog, $output);
        }
    }
}

sub debugdump
{
    my ($flag,$name,$ref) = @_;

    my $caller_name = (caller(1))[3];
    my $line = (caller(0))[2];

    if ( ($Debug & $flag) == $flag ) {
        use Data::Dumper;
        $Data::Dumper::Terse = FALSE;
        printf(STDERR "%s (%s): %s",
            $caller_name ? $caller_name : "main::main",
            $line, Data::Dumper->Dump([$ref],[$name]));
        no Data::Dumper;
    }
}

#
# Error Message Definitions
#

use constant E_NO_ERROR		=> 0;
use constant E_INVALID_ARGS	=> 1;
use constant E_HOST_UNAVAIL	=> 2;
use constant E_HOST_UNAVAILABLE	=> 2;

my %ErrorMessages = ();
my %ErrorNumbers = ();

my %DefaultErrorMessages = (
    (E_NO_ERROR)	=> {
        title	=> "E_NO_ERROR",
        message	=> "No Error",
    },
    (E_INVALID_ARGS)	=> {
        title	=> "E_INVALID_ARGS",
        message	=> "Invalid Args",
    },
    (E_HOST_UNAVAILABLE)	=> {
        title	=> "E_HOST_UNAVAILABLE",
        message	=> "Host is unreachable",
    },
);

#
# Error Message Functions
#

sub register_error_messages
{
    my ($messages) = @_;

    foreach my $errno ( keys(%$messages) ) {
        register_error_message($errno, $$messages{$errno});
    }
}

sub register_error_message
{
    my ($errno,$definition) = @_;

    debugprint(DEBUG_TRACE, "Error Number: %d", $errno);

    # No duplicate error numbers allowed...
    die("Attempt to register duplicate debug error number: " . $errno)
        if ( exists($ErrorMessages{$errno} ) and ( $errno != 0 ) );

    # Qualify the definiton...

    # No duplicate error messages allowed...
    die("Attempt to register duplicate error message: '" . $$definition{message} . "'")
        if exists($ErrorNumbers{$$definition{message}});

    # No null messages allowed...
    die("Attempt to register null message for errno " . $errno)
        if $$definition{message} eq "";

    debugprint(DEBUG_TRACE, "Registered New Message: %s => '%s'", $$definition{title}, $$definition{message});

    # Save the definition...
    $ErrorMessages{$errno} = $definition;
    $ErrorNumbers{$$definition{message}} = $errno;
}

sub error_message
{
    my ($errno) = @_;

    my $result = "Unknown Error Number: '" . $errno . "'";

    if ( $ErrorMessages{$errno} ne "" ) {
        $result = $ErrorMessages{$errno}{message};
    }

    return $result;
}

#
# Parameter  Definitions
#

# Parameter Types
use constant PARAMTYPE_STRING	=> 1;
use constant PARAMTYPE_INT	=> 2;
use constant PARAMTYPE_FLOAT	=> 3;
use constant PARAMTYPE_FUNC	=> 4;
use constant PARAMTYPE_BOOL	=> 5;
use constant PARAMTYPE_ENUM	=> 6;

my %ParamTypes = (
    (PARAMTYPE_STRING) => {
        typespec	=> "s",
        help		=> "<string>",
    },
    (PARAMTYPE_INT) => {
        typespec	=> "i",
        help		=> "<int>",
    },
    (PARAMTYPE_FLOAT) => {
        typespec	=> "f",
        help		=> "<float>",
    },
    (PARAMTYPE_FUNC) => {
        typespec	=> "s",
        help		=> "<argument>",
    },
    (PARAMTYPE_BOOL) => {
        typespec	=> "!",
        help		=> "[TRUE|FALSE]",
    },
    (PARAMTYPE_ENUM) => {
        typespec	=> "s",
        help		=> "[ENUM1|ENUM2|...]",
    },
);

# Parameters
my @Params;
my %ParamDefs = ();

our $TestOnly = FALSE;

my %DefaultParamDefs = (
    "debug"	=> {
        name	=> "Debug",
        type	=> PARAMTYPE_FUNC,
        funpack	=> \&debug_flags,
        var	=> \$Debug,
        usage	=> "--debug|-d",
        comment	=> "Set debug flags - others may be available; check your docs.",
    },
    "help"	=> {
        name	=> "Help",
        type	=> PARAMTYPE_FUNC,
        funpack	=> \&help,
        usage	=> "--help|-h",
        comment	=> "Display this help",
    },
    "test"	=> {
        name	=> "TestOnly",
        type	=> PARAMTYPE_BOOL,
        var	=> \$TestOnly,
        usage	=> "--test|-t",
        comment	=> "Invoke Test Mode. TestOnly is defined but unused by TimUtil.",
    },
);

#
# Parameter Functions
#

sub register_params
{
    my ($params) = @_;

    my ($package,$filename,$line) = caller;

    foreach my $param ( keys(%{$params}) ) {
        register_param($param, $$params{$param},$package);
    }
}

sub register_param
{
    my ($param,$paramdef,$package) = @_;

    $$paramdef{package} = $package unless $$paramdef{package};
    debugdump(DEBUG_DUMP, $param, $paramdef);

    # No duplicate parameter names allowed...
    debugdump(DEBUG_DUMP, "ParamDefs", \%ParamDefs);
    die("Attempt to register duplicate param " . $param)
        if exists($ParamDefs{$param});

    debugprint(DEBUG_TRACE, "Registered New Parameter '%s'", $param);

    # Save the definition...
    $ParamDefs{$param} = $paramdef;

    # TODO: This whole thing belongs somewhere else...
    # Build the GetOptions() paramspec...

    my $paramspec = $param;

    if ( $$paramdef{type} != PARAMTYPE_BOOL ) {
        if ( $$paramdef{required} ) {
            $paramspec .= "=";
        }
        else {
            $paramspec .= ":";
        }
    }

    $paramspec .= $ParamTypes{$$paramdef{type}}{typespec};

    debugprint(DEBUG_TRACE, "paramspec: %s", $paramspec);
    push(@Params, $paramspec);
}

sub parse_args
{
    my $returnval = E_NO_ERROR;
    my ($options) = @_;

    debugprint(DEBUG_TRACE, "Entering...");

    debugdump(DEBUG_DUMP, "Params", \@Params);

    my $args = {};
    GetOptions($args, @Params);

    debugdump(DEBUG_DUMP, "args", $args);

    # TODO: Doing this on $args deprives us of the opportunity to set default values...
    foreach my $arg ( keys(%{$args}) ) {

        debugprint(DEBUG_TRACE, "Checking arg '%s'...", $arg);

        if ( exists($ParamDefs{$arg}) ){

            debugprint(DEBUG_TRACE, "Got a matching param '%s'", $ParamDefs{$arg}{name});

            # Set the var to the default value if no matching argument was found...
            #if ( not defined(${$ParamDefs{$arg}{var}}) and exists($ParamDefs{$arg}{default}) ) {
            #    debugprint(DEBUG_TRACE, "Setting '%s' to the supplied default value of '%s'...",
            #        $ParamDefs{$arg}{name}, $ParamDefs{$arg}{default});
            #    ${$ParamDefs{$arg}{var}} = $ParamDefs{$arg}{default};
            #}

            if ( $ParamDefs{$arg}{type} == PARAMTYPE_FUNC ) {
                ${$ParamDefs{$arg}{var}} = &{$ParamDefs{$arg}{funpack}}($$args{$arg});
            }
            elsif ( $ParamDefs{$arg}{type} == PARAMTYPE_ENUM ) {
                debugprint(DEBUG_TRACE, "\$\$args{\$arg} = '%s'", $$args{$arg});

                debugprint(DEBUG_TRACE, "%s = %s",
                    $ParamDefs{$arg}{name},
                    $ParamDefs{$arg}{selectors}{$$args{$arg}},
                );

                ${$ParamDefs{$arg}{var}} = $ParamDefs{$arg}{selectors}{$$args{$arg}};
            }
            else {
                ${$ParamDefs{$arg}{var}} = $$args{$arg};
            }
        }
        else {
            debugprint(DEBUG_ERROR, "Invalid argument: '%s'", $arg);
        }
    }

    # My Perl is moar awsom then urs:
    map({$$options{$_} = $ParamDefs{$_}{var} ? ${$ParamDefs{$_}{var}} : undef; } keys(%ParamDefs));

    debugprint(DEBUG_TRACE, "Debug = %s (%s)", debug_names($Debug), $Debug);

    debugprint(DEBUG_TRACE, "Returning %s", error_message($returnval));

    return $returnval;
}

sub help
{
    printf("Usage: %s [options]\n", $0);

    # Sort arguments by package...
    my %params_by_package;
    map( { $params_by_package{$ParamDefs{$_}{package}}{$_} = $ParamDefs{$_}; } keys(%ParamDefs) );
    debugdump(DEBUG_DUMP, "params_by_package", \%params_by_package);

    foreach my $package ( keys(%params_by_package) ) {

        printf("\tParameters from %s:\n", $package);

        foreach my $key ( keys($params_by_package{$package}) ) {
            my $param = $params_by_package{$package}{$key};
            debugdump(DEBUG_DUMP, "param", $param);
        
            # Make up a default usage if none is provided...
            $$param{usage} = sprintf("--%s | -%s", $key, substr($key, 0, 1)) if $$param{usage} eq "";

            # Use the provided usage instructions...
            my $help = $ParamTypes{$$param{type}}{help};

            # Or provide argument type-specific usage instructions...
            if ( $$param{type} == PARAMTYPE_ENUM ) {
                $help = sprintf("<enum> [ %s ]", join(" | ", keys($$param{selectors})));
            }
            elsif ( $$param{name} eq "Debug" ) {
                $help = sprintf("<flags> [ %s ]", debug_names(DEBUG_ALL, DEBUG_EXPLICIT));
            }

            printf("\t%s %s\n", $$param{usage}, $help);

            # Print the comment, if one is provided...
            printf("\t\t%s\n", $$param{comment}) if $$param{comment} ne "";
        }
        printf("\n");
    }

    exit(0);
}

# TODO: Fix this shitty, shitty, stinky farty mess...
# Enumerate the defined parameters.
# If a CODE ref is provided, it is used as a callback to allow
# the user app to evaluate each parameter. After all parameters
# have been offered, the function returns the total number of
# registered parameters.
# If no CODE ref is provided, the entire list is returned.
sub enum_params
{
    debugprint(DEBUG_TRACE, "Entering...");
    debugdump(DEBUG_DUMP, "@", \@_);
    my ($callback) = @_;
    debugdump(DEBUG_DUMP, "callback", $callback);

    if ( *callback{CODE} ) {
        printf(STDERR "hi!\n");
        foreach my $param ( keys(%ParamDefs) ) {
            &{$_}($ParamDefs{$param});
        }
        return scalar(%ParamDefs);
    }
    else {
        return \%ParamDefs;
    }
}

#
# Array to Hash converter
#

sub mkhash
{
    my ($keys,$values) = @_;
    my $hash;

    debugdump(DEBUG_DUMP, "keys", $keys);
    debugdump(DEBUG_DUMP, "values", $values);

    return undef if scalar(@$keys) != scalar(@$values);

# WRONG! Doing it this way destroys the source values list...
#    foreach my $key ( @$keys ) {
#        $$hash{$key} = shift(@$values); # <--- shift() eats the list
#    }

     # Iterate over the list and create a hash element for each pair...
     for ( my $i = 0; $i < scalar(@$keys); $i++ ) {
         $$hash{$$keys[$i]} = $$values[$i];
     }

    debugdump(DEBUG_DUMP, "hash", $hash);

    return $hash;
}

#
# Module initilization...
#

debugprint(DEBUG_TRACE, "Beginning intiailization...");

# Register default debug modes...
register_debug_modes(\%DefaultDebugModes);

# Register default error messages...
register_error_messages(\%DefaultErrorMessages);

# Register default parameters...
register_params(\%DefaultParamDefs);

debugprint(DEBUG_TRACE, "Intiailization Complete!");

# All done!
return SUCCESS;

#END { close(STDERR); }

