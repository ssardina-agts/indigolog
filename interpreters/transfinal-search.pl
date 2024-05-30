%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* Transition System for INDIGOLOG search opertors

    Part of the INDIGOLOG system

    Refer to root directory for license, documentation, and information
*/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CLASSICAL SEARCH CONSTRUCCT
%%
%%		[De Giacomo & Levesque 1999])
%%		[De Giacomo, Levesque, Sardina 2001]}
%%		[De Giacomo, Lesperance, Levesque, Sardina 2009]}
%%
%% Linear plans, ignores sensing: akin to classical planning
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Search with a message
final(search(E, M), H) :- var(M), final(search(E, E), H).
trans(search(E, M), H, E1, H1) :-
	ground(M),
	logging(program(3), "Start search on: ~w", [M]),
	trans(search(E), H, E1, H1), !,
	logging(program(3), "Search finished! PLAN FOUND: ~w", [M]).
trans(search(_, M), _, _, _) :-
	ground(M),
	logging(program(3), "Search finished! PLAN NOT FOUND: ~w", [M]),
	fail.

% Search without a message (classical search)
% exception abort_search is used to abort the search wrt commit (cut)
final(search(E), H) :- final(E, H).
trans(search(E), H, followpath(E1, L), H1) :-
        catch((trans(E, H, E1, H1), findpath(E1, H1, L)), abort_search, fail).

% findpath(E, H, L): find a solution L for E at H;
%		   L is the list [E1, H1, E2, H2, ..., EN, HN] encoding
%		   each step evolution (Ei, Hi) where final(EN, HN)
%
% commit action in programs act as cut ! in Prolog: commit
findpath(E, [commit|H], L) :- !,
	(	findpath(E, H, L)
	-> 	true 
	; 	throw(abort_search)
	).
findpath(E, H, [E, H]) :- final(E, H).
findpath(E, H, [E, H|L]) :-
	trans(E, H, E1, H1),
	findpath(E1, H1, L).


% followpath(E, L):
%	execute program E wrt expected sequence of configs L
%	if current history H does not match the next expected one
% 	in L (i.e., H\=HEx), then redo the search for E from H
final(followpath(E, [E, H]), H) :- !.	% all as expected! :-)
final(followpath(E, _), H) :- final(E, H).  % off path; check again

trans(followpath(E, [E, H, E1, H1|L]), H, followpath(E1, [E1, H1|L]), H1) :- !.
trans(followpath(E, _), H, E1, H1) :- trans(search(E), H, E1, H1). % replan



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONDITIONAL SEARCH: Conditional plans with sensing
%%
%% From [Sardina LPAR-01] and based on sGolog [Lakemeyer 99]
%%
%% After a step, the program looks for special "marks" generated by the
%% program when searched:
%%
%% branch(P): CPP should branch w.r.t. rel fluent P
%% commit   : no backtracking on the already found partial CPP
%% sim(A)   : A is a simulated exogenous action, don't add it to the CPP
%% test(P)  : a test ?(P) should be left in the CPP (from ??(P))
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
final(searchc(E, _), H) :- final(searchc(E), H).
final(searchc(E), H) :- final(E, H).

trans(searchc(E, M), H, E1, H1) :-
	logging(program(3), "Start conditional search: ~w", [M]),
	trans(searchc(E), H, E1, H1), !,
	logging(program(4), "Finish succesfully conditional search: ~w", [M]).
trans(searchc(_, M), _, _, _) :-
	logging(program, "Failed conditonal search: ~w", [M]),
	fail.

% if calcCPP/3 wants to abort everything it has to throw exception searchc
trans(searchc(E), S, CPP, S) :-
	catch(calcCPP(E, S, CPP), abort_searchc, fail).

trans(branch(P), S, [], [branch(P)|S]).	/* branching step always succeeds */

calcCPP(E, S, []) :- final(E, S).
calcCPP([E1|E2], S, C) :- E2 \= [], !, calcCPP(E1, S, C1), /* program is a sequence */
                        extendCPP(E2, S, C1, C).

%calcCPP(branch(P), S, []) :- holds(know(P), S), !. /* no branching */
%calcCPP(branch(P), S, [if(P, [], [])]) :- holds(kwhether(P), S), !. /* branching */
calcCPP(branch(P), _, [if(P, [], [])]) :- !. /* branching, do not check */

calcCPP(E, S, C) :- trans(E, S, E1, S1),    /* program is not a sequence */
   (S1=[branch(P)|S] -> calcCPP([branch(P)|E1], S, C) ;     /* branch now wrt P*/
%    S1=[commit|S]    -> (calcCPP(E1, S, C) -> /* commit here */
%	                       true
%		       ;
%	                 throw(abort_searchc))  ; /* abort if no plan found for E1 */
    S1=S             -> calcCPP(E1, S1, C) ;                /* normal test     */
    S1=[test(P)|S]   -> (calcCPP(E1, S, C1), C=[?(P)|C1]) ; /* perdurable test */
    S1=[A|S]         -> (calcCPP(E1, S1, C1), C=[A|C1]) ).  /* normal action   */

/* extendCPP(E, S, C, C1) recursively descends the CAT C (first two clauses). */
/* Once a leaf of the CAT is reached (third clauses), "calcCPP" is called  */
/* which then extends this branch accordingly to E 		           */
extendCPP(E, S, [sim(A)|C], [sim(A)|C2]) :- exog_action(A), !,
                                         extendCPP(E, [sim(A)|S], C, C2).
extendCPP(E, S, [if(P, C1, C2)], [if(P, C3, C4)]) :- !,
                assume(P, true, S, S1),  extendCPP(E, S1, C1, C3),
                assume(P, false, S, S2), extendCPP(E, S2, C2, C4).
extendCPP(E, S, [commit|C], C2) :- !, (extendCPP(E, S, C, C2) ; throw(abort_searchc)).
extendCPP(E, S, [A|C], [A|C2]) :- prim_action(A), !, extendCPP(E, [A|S], C, C2).
extendCPP(E, S, [], C) :- calcCPP(E, S, C).	/* We are on a leaf of the CPP */


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONDITIONAL PLANNER WSCP: conditional planner (Hector Levesque)
%%
%% Requires loading the library for WSCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
:- ensure_loaded(wscplan).  % Load the WSCP Planner

% Transitions for the case(A, CondPlan) construct
trans(case(A, [if(V, Plan)|_]), H, Plan, H) :- sensed(A, V, H), !.
trans(case(A, [if(_, _)|BL]), H, case(A, BL), H).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EOF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%