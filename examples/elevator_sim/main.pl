%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SET GLOBAL PARAMETERS AND GLOBAL VARIABLES/CONSTANTS USED
%
%  These may be options to improve performance and variables/constants used
%  around the whole arquitecture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
:- dynamic controller/1.	% Stores the user decision on the controller to run


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (1) LOAD/COMPILE/IMPORT LIBRARIES, MODULES, ETC that may be required.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%:- reset_backquoted_string.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (2,3) CONSULT NECESSARY FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
:- ['../../config.pl'].


% Consult the top-level interpreter, environent manager and projector
:- dir(indigolog, F), consult(F).
:- dir(env_manager, F), consult(F).
:- dir(eval_bat, F), consult(F).

% Consult application
:- [elevator].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (4,5) ENVIRONMENTS TO LOAD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Any port available would be ok for the EM.
server_host(localhost).  % this is the default anyways...
server_port(8000).


% Load simulator, RCX and internet environments
:- dir(dev_managers, F), consult(F).

load_devices([simulator]).

% start env_sim.pl tcl/tk interaction interface
load_device(simulator, Host:Port, [pid(PID)]) :-
    root_indigolog(Dir),
    directory_file_path(Dir, 'env/env_sim.pl', File),
    ARGS = ['-e', 'swipl', File, '-t', 'start', '--host', Host, '--port', Port],
    logging(system(5, app), "Command to initialize device simulator: xterm -e ~w", [ARGS]),
    process_create(path(xterm), ARGS, [process(PID)]).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HOW TO EXECUTE ACTIONS: Environment + low-level Code
%        how_to_execute(Action, Environment, Code)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
how_to_execute(Action, simulator, Action).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   EXOGENOUS ACTION AND SENSING OUTCOME TRANSLATION
%          translateExogAction(Code, Action)
%          translateSensing(Action, Outcome, Value)
% OBS: If not present, then the translation is 1-1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
translateExogAction(CodeAction, Action) :- actionNum(Action, CodeAction).
translateSensing(_, SensorValue, SensorValue).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN PREDICATE - evaluate this to run demo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% main/0: Gets IndiGolog to evaluate a chosen mainControl procedure
main :-
    findall(C, proc(controller(C), _), L),
    repeat,
    format('Controllers available: ~w\n', [L]),
    write('Select controller: '),
	read(Ctrl), nl,
    member(S, L),
	format('Executing controller: *~w*\n', [S]), !,
    main(Ctrl).

main(C) :- assert(controller(C)), indigolog(C).


:- set_option(log_level, 5).
:- set_option(wait_step, 3).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EOF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%