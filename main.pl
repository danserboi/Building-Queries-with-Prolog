:- use_module(tables, [table_name/2]).
:- use_module(check_predicates, [grades_and_ratings/3, movies_and_ratings/3, check_names/3, names_and_ratings_pred/3]).
​:- use_module(library(lists)).

% predicatul calculeaza numarul de cifre al unui intreg
no_digits(X, 1) :- X < 10.
no_digits(X, Y) :- X >= 10, X1 is X // 10, no_digits(X1, Y1), Y is Y1 + 1, !.

% predicatul calculeaza numarul de cifre, respectiv caractere 
% pentru un intreg, respectiv un string
el_length(El, R) :- integer(El), no_digits(El, R), !.
el_length(El, R) :- string(El), string_length(El, R), !. 
% predicatul mapeaza elementele unei liste la lungimea lor
els_lens(L, R) :- maplist(el_length, L, R).
% predicatul calculeaza lungimea maxima dintr-o lista
max_length_from_list(L, R) :- els_lens(L, L2), max_list(L2, R), !. 

head([], []).
head([H|_], H).

tail([], []).
tail([_|T], T).

% predicatul calculeaza lungimile maxime ale intrarilor de pe fiecare coloana
% valorile fiind retinute intr-o lista
max_row_len([[]|_], []).
max_row_len(Table, [R|MaxRowLen]) :- maplist(head, Table, L),
								     max_length_from_list(L, R),
								     maplist(tail, Table, Table2),
								     max_row_len(Table2, MaxRowLen), !.


% predicatul construieste sirul de formatare plecand de la lista cu lungimile maxime
make_format_str(MaxRowLen,Str) :- maplist(plus5,MaxRowLen,Rp), aux_format(Rp,Str).

plus5(X,Y):- Y is X + 5.

aux_format([H],R) :- string_concat("~t~w~t~",H,R1),string_concat(R1,"+~n",R),!.
aux_format([H|T],R) :- string_concat("~t~w~t~",H,R1),
					   string_concat(R1,"+ ",R2),
					   aux_format(T,Rp),
					   string_concat(R2,Rp,R).

% Predicatul determina MaxRowLen​ pentru tabelul in cauza, 
% calculeaza sirul de formatare folosind ​make_format_str,
% foloseste predicatul format impreuna cu sirul de formatare(mereu acelasi), 
% pentru a afisa, succesiv, fiecare rand din tabel.
print_aux(_, []).
print_aux(Table, [Row|TailTable]) :- max_row_len(Table, MaxRowLen),
								     make_format_str(MaxRowLen, Str), !,
								     format(Str, Row),
								     print_aux(Table, TailTable).

% predicatul ​afiseaza un tabel folosindu-se de functia auxiliara de afisare
print_table_op(Tbl) :- print_aux(Tbl, Tbl), !.

% predicat auxiliar pentru join
join_aux(_, [], [], []).
join_aux(Op, [Row1|T1], [Row2|T2], [ResRow|R]) :- call(Op, Row1, Row2, ResRow), 
												  join_aux(Op, T1, T2, R).

% predicatul realizeza operatia de join a tabelelor
join_op(Op, NewCols, [_|T1], [_|T2], [NewCols|R]) :-  join_aux(Op, T1, T2, R), !.


% predicatul adauga capete noi la inceputul fiecarei liste
new_heads([], [], []).
new_heads([X|Xs], [Y|Ys], [[X|Y]|Zs]) :- new_heads(Xs,Ys,Zs).

% predicatul selecteaza din tabelul ​Table, doar acele coloane din lista ​Cols​
select_op((V|[]),_,(V|[])).
select_op(Table,Cols,Res) :- maplist(head, Table, [H|Values]),
						     H \= [],
						     member(H,Cols),
						     maplist(tail, Table, Table2),
						     select_op(Table2, Cols, R),
						     new_heads([H|Values], R, Res), !.
select_op(Table,Cols,Res) :- maplist(head, Table, [H|_]),
						     H \= [],
						     not(member(H,Cols)),
						     maplist(tail, Table, Table2),
						     select_op(Table2, Cols, Res), !.
select_op(Table,_,Table) :- maplist(head, Table, [H|_]),
						    H == [], !.

% predicat auxiliar pentru filter_op
filter_aux([],_,_,[]).
filter_aux([HT|TT],Vars,Pred,R) :- not((Vars=HT, Pred)), filter_aux(TT,Vars,Pred,R), !.
filter_aux([HT|TT],Vars,Pred,[HT|R]) :- filter_aux(TT,Vars,Pred,R).
% predicatul filtreaza intrarile unui tabel pe baza unui predicat Pred
% Vars este o lista de ​variabile ​neinstantiate​, 
% pozitia unui variabile in lista desemneaza coloana aferenta acesteia.
filter_op([HT|TT],Vars,Pred,[HT|R]) :- filter_aux(TT,Vars,Pred,R), !.

% predicatul evalueaza toate tipurile de query-uri
eval(table(Str), ResTbl) :- table_name(Str, ResTbl).
eval(tfilter(Schema,Goal,Query), ResTbl) :- eval(Query, Tbl), 
											filter_op(Tbl, Schema, Goal, ResTbl).
eval(select(Columns, Query), ResTbl) :- eval(Query, Tbl),
										select_op(Tbl,Columns,ResTbl).
eval(join(Pred, Cols, Q1, Q2), ResTbl) :- eval(Q1, Tbl1), eval(Q2, Tbl2),
										  join_op(Pred, Cols, Tbl1, Tbl2, ResTbl).
eval(tprint(Q), ResTbl) :- eval(Q, ResTbl), print_table_op(ResTbl).
eval(complex_query2(G, MinR, MaxR), R) :- complex_query2_op(G, MinR, MaxR, table(movies), R).
eval(complex_query1(Q), R) :-complex_query1_op(Q,R).

% predicatul selecteaza studentii ce au media notelor la AA si PP mai mare ca 6,
% media tuturor notelor mai mare ca 5 si care au prefixul „-escu” in numele de familie.
complex_query1_op(Q,ResTbl) :- eval(Q, Tbl),
   filter_op(Tbl, [_,_,AA,PP,_,_,_],((AA + PP)//2 >= 6), FiltTbl),
   filter_op(FiltTbl, [_,_,N1,N2,N3,N4,N5],((N1 + N2 + N3 + N4 + N5)//5 >= 5), Filt2Tbl),
   filter_op(Filt2Tbl, [_,LN,_,_,_,_,_], string_concat(_,"escu",LN), ResTbl).

% predicatul verifica daca un rating se incadreaza intre 2 rating-uri
rat_in(Min, Max, Rat) :- Max >= Rat, Rat >= Min.

% predicatul roteste la dreapta o lista(ultimul element devine primul)
rotate_right([],[]) .
rotate_right([H|T], [LastEl|Prefix]) :- append(Prefix,[LastEl],[H|T]), !.

% predicatul selecteaza filmele ce se incadreaza intr-un anumit gen
% si care au rating-ul aflat intre doua limite specificate.
% intai vom selecta coloanele movie_id si rating din tabelul ratings
% apoi vom sorta dupa movie_id pentru a avea aceeasi ordine a filmelor ca in tabelul movies
% dupa sortare, vom selecta coloana cu rating-urile
% si vom alipi acea coloana la tabelul cu movies
% pentru ca in final sa filtram dupa cele 2 conditii.
complex_query2_op(G, MinR, MaxR, Q, ResTbl) :- eval(Q, MovTbl),
	eval(table(ratings), RatTbl),
	select_op(RatTbl, ["movie_id", "rating"], SelRatTbl),
	sort(SelRatTbl, SortedRatTbl),
	rotate_right(SortedRatTbl, SRatTbl),
	select_op(SRatTbl, ["rating"], OnlyRatTbl),
	join_op(append, ["movie_id","title","genres","rating"],MovTbl, OnlyRatTbl, JoinTbl),
	filter_op(JoinTbl,[_,_,Genres,_], sub_string(Genres, _, _, _, G), FilTbl),
	filter_op(FilTbl,[_,_,_,CurrRat],  rat_in(MinR, MaxR, CurrRat), ResTbl).