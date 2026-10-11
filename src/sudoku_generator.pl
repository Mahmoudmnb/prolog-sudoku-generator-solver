% Sudoku generator.
%
% Generation flow:
%   1. Build a complete grid square by square using random values.
%   2. Validate every generated value against its row, column, and square.
%   3. Remove cells one by one.
%   4. After each removal, call the original solver to ensure the puzzle
%      remains solvable by the same educational strategies.
%
% The generator intentionally uses the solver's dynamic cell/4 database and
% does not change the original randomization or difficulty behavior.

:- ensure_loaded('sudoku_solver.pl').
:- dynamic cell/4.

% Generate a new cell or overwrite an old one.
generateCell(X,Y,[V]):-retract(cell(X,Y,_,_)),random(1,10,V),assert(cell(X,Y,[V],0)).
generateCell(X,Y,[V]):-random(1,10,V),assert(cell(X,Y,[V],0)).
% Validate a generated value against its 3x3 square.
% X/Y identify the cell, MX is the horizontal square boundary, and SX/SY
% are the current scan coordinates.
validateSquare(X,Y,_,X,Y):-!.
validateSquare(X,Y,MX,SX,SY):- SX=<MX,cell(X,Y,V,_),cell(SX,SY,V1,_),not(isEqual(V,V1)), NX is SX+1,validateSquare(X,Y,MX,NX,SY),!.
validateSquare(X,Y,MX,SX,SY):- SX=:=MX+1, NY is SY+1, NX is SX-3,validateSquare(X,Y,MX,NX,NY),!.
% Validate a generated value against its column.
validateColumn(_,_,10):-!.
validateColumn(X,Y,I):- I=:=Y,NI is I+1,validateColumn(X,Y,NI),!.
validateColumn(X,Y,I):- not(cell(X,I,_,_)),NI is I+1,validateColumn(X,Y,NI),!.
validateColumn(X,Y,I):- cell(X,I,[H|_],_),cell(X,Y,[H1|_],_),H=\=H1,NI is I+1,validateColumn(X,Y,NI),!.
% Validate a generated value against its row.
validateRow(_,_,10):-!.
validateRow(X,Y,I):- I=:=X,NI is I+1,validateRow(X,Y,NI),!.
validateRow(X,Y,I):- not(cell(I,Y,_,_)),NI is I+1,validateRow(X,Y,NI),!.
validateRow(X,Y,I):- cell(I,Y,[H|_],_),cell(X,Y,[H1|_],_),H=\=H1,NI is I+1,validateRow(X,Y,NI),!.
% Fill a square with unique numbers.
% X/Y are the current coordinates; MX/MY are the square end coordinates.
% I counts retry attempts for the current cell, and J counts rebuild attempts
% for the current square. The original retry limits are preserved.
fillSquare(_,_,MX,MY,_,10):-MX>3,NSX is MX -5,NSY is MY-2,NMX is MX-3,clearSquare(NSX,NMX,NSY,MY),SX is MX -5,SY is MY-2,NNMX is MX-3,fillSquare(SX,SY,NNMX,MY,0,0),
                            TSX is MX -2,TSY is MY -2,clearSquare(TSX,MX,TSY,MY),TNSX is MX-2,TNSY is MY-2,fillSquare(TNSX,TNSY,MX,MY,0,0).  
fillSquare(_,_,MX,MY,_,10):-MY>3,NSX is MX -2,NSY is MY-5,NMY is MY-3,clearSquare(NSX,MX,NSY,NMY),SX is MX -2,SY is MY-5,NNMY is MY-3,fillSquare(SX,SY,MX,NNMY,0,0),
                            TSX is MX -2,TSY is MY -2,clearSquare(TSX,MX,TSY,MY),TNSX is MX-2,TNSY is MY-2,fillSquare(TNSX,TNSY,MX,MY,0,0).
fillSquare(_,_,MX,MY,20,J):- SX is MX -2,SY is MY -2,clearSquare(SX,MX,SY,MY),NSX is MX-2,NSY is MY-2,NJ is J+1,fillSquare(NSX,NSY,MX,MY,0,NJ).
fillSquare(_,Y,_,MY,_,_) :- Y > MY.
fillSquare(X,Y,MX,MY,_,J):-X=<MX,generateCell(X,Y,_),SX is (MX-2),SY is (MY-2),validateSquare(X,Y,MX,SX,SY),
                            validateRow(X,Y,1),validateColumn(X,Y,1),NX is X+1,fillSquare(NX,Y,MX,MY,0,J).
fillSquare(X,Y,MX,MY,I,J):-X=<MX,retract(cell(X,Y,_,_)),NI is I+1,fillSquare(X,Y,MX,MY,NI,J).
fillSquare(X,Y,MX,MY,_,J):-X>MX, NY is Y+1, NX is MX-2,fillSquare(NX,NY,MX,MY,0,J).
% Clear all cells in a square.
clearSquare(_,_,SY,EY):-SY>EY.
clearSquare(SX,EX,SY,EY):-SX=<EX,retract(cell(SX,SY,_,_)),NX is SX +1 ,clearSquare(NX,EX,SY,EY).
clearSquare(SX,EX,SY,EY):-SX=<EX,NX is SX +1 ,clearSquare(NX,EX,SY,EY).
clearSquare(SX,EX,SY,EY):- SX>EX,NY is SY +1,NX is EX -2,clearSquare(NX,EX,NY,EY).
% Build a solved puzzle by filling each 3x3 square.
fillPuzzle():-  fillSquare(1,1,3,3,0,0),fillSquare(4,1,6,3,0,0),fillSquare(7,1,9,3,0,0),
                fillSquare(1,4,3,6,0,0),fillSquare(4,4,6,6,0,0),fillSquare(7,4,9,6,0,0),
                fillSquare(1,7,3,9,0,0),fillSquare(4,7,6,9,0,0),fillSquare(7,7,9,9,0,0).
% Reset every existing cell to unprocessed state.
resetCell(_,10):-!.
resetCell(X,Y):-X<10,cell(X,Y,R,_),retract(cell(X,Y,_,_)),assert(cell(X,Y,R,0)),NX is X+1,resetCell(NX,Y),!.
resetCell(X,Y):-X<10,NX is X+1,resetCell(NX,Y),!.
resetCell(X,Y):-X>9,NY is Y+1,NX is 1,resetCell(NX,NY),!.
% Remove cells from the puzzle according to coordinate lists.
removeCells([],[]):-!.
removeCells([H1|T1],[H2|T2]):-retract(cell(H1,H2,_,_)),removeCells(T1,T2),!.
removeCells([_|T1],[_|T2]):-removeCells(T1,T2),!.
% Remove numbers while preserving solvability under solvePuzzle/1.
clearProb(_,10,_,_).
clearProb(X,Y,LX,LY):-X<10,cell(X,Y,R,_),assert(cell(-1,-1,R,0)),retract(cell(X,Y,_,_)),solvePuzzle(Res),Res=:=1,append([X],LX,NLX),append([Y],LY,NLY),
                      retract(cell(-1,-1,_,_)),resetCell(1,1),removeCells(NLX,NLY),NX is X+1,clearProb(NX,Y,NLX,NLY).
clearProb(X,Y,LX,LY):-X<10,cell(-1,-1,R,_),retract(cell(X,Y,_,_)),assert(cell(X,Y,R,0)),retract(cell(-1,-1,_,_)),resetCell(1,1),removeCells(LX,LY),NX is X+1,clearProb(NX,Y,LX,LY).
clearProb(X,Y,LX,LY):-X<10,cell(-1,-1,R,_),assert(cell(X,Y,R,0)),retract(cell(-1,-1,_,_)),resetCell(1,1),removeCells(LX,LY),NX is X+1,clearProb(NX,Y,LX,LY).
clearProb(X,Y,LX,LY):-X>9,NY is Y+1,NX is 1,clearProb(NX,NY,LX,LY).
% Public entry point: create a complete grid, then remove cells.
createPuzzle():-fillPuzzle(),clearProb(1,1,[],[]).
