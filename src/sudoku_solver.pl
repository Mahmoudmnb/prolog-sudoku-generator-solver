% Sudoku solver.
%
% Board representation:
%   cell(X, Y, Candidates, State)
%   X and Y are 1-based coordinates. Candidates is either a solved value
%   as a one-item list, or the remaining possible values for the cell.
%   State is 0 for unsolved/unprocessed and 1 after a solved value has
%   already been propagated to its row, column, and 3x3 square.
%
% The solver intentionally keeps the original educational strategy:
% candidate elimination, single-candidate propagation, pair elimination,
% uniqueness checks, and repeated scans until no more progress is made.

:- dynamic cell/4.

% Merge two lists into one. This intentionally preserves the original
% project-local append/3 definition.
append([],L2,L2).
append([H|T],L2,[H|L3]):-append(T,L2,L3).
% Remove one element from a list. L is the accumulator and should be []
% in normal calls; F is the list after deletion.
removeElement(_,L,[],F):- append(L,[],F),!.
removeElement(V,L,[H|T],F):-H =\= V ,append(L,[H],NL), removeElement(V,NL,T,F).
removeElement(_,L,[_|T],F):- append(L,T,F),!.
% Remove a list of values from another list.
removeElements([],R,F):-append(R,[],F).
removeElements([H],R,F):-removeElement(H,[],R,F).
removeElements([H|T],R,F):-removeElement(H,[],R,F1),removeElements(T,F1,F).
% Check whether two numeric lists are equal.
isEqual([],[]).
isEqual([H|T],[H1|T1]):-H=:=H1,isEqual(T,T1).
% Check whether a list contains V.
contain(V,[H]):-H=:=V.
contain(V,[H|_]):-H=:=V.
contain(V,[_|T]):-contain(V,T).
% True when any value from the first list appears in the second list.
containList([],_):-1=:=2.
containList([H|_],L):-contain(H,L).
containList([_|T],L):-containList(T,L).
% Count matching positions between two lists.
countOfMatching([],_,R,R):-!.
countOfMatching(_,[],R,R):-!.
countOfMatching([H|T],[H1|T1],R,F):-H1=:=H,NR is R+1,countOfMatching(T,T1,NR,F),!.
countOfMatching([_|T],[_|T1],R,F):-countOfMatching(T,T1,R,F),!.
% Candidate initialization: fill an empty cell with candidates 1 through 9.
fillProb(X,Y,10,L):-assert(cell(X,Y,L,0)).
fillProb(X,Y,N,L) :- append(L,[N],R), NN is N+1, fillProb(X,Y,NN,R).
% Fill every missing cell with all candidates.
fillPuzzleProb(_,10).
fillPuzzleProb(X,Y):- cell(X,Y,_,_),NX is X+1, fillPuzzleProb(NX,Y).
fillPuzzleProb(X,Y):- X<10, fillProb(X,Y,1,[]),NX is X+1, fillPuzzleProb(NX,Y).
fillPuzzleProb(_,Y):- NY is Y+1, fillPuzzleProb(1,NY).

% Single-candidate propagation removes a solved value from peers.
% Row elimination.
clearRowProb(_,_,_,10,0,0).
clearRowProb(_,_,_,10,1,1).
clearRowProb(V,X,Y,I,S,C):- I =:= X,NI is I+1,clearRowProb(V,X,Y,NI,S,C).
clearRowProb(V,X,Y,I,_,C):- cell(I,Y,R,_),contain(V,R),removeElement(V,[],R,Res),retract(cell(I,Y,_,_)),assert(cell(I,Y,Res,0)),NI is I+1,clearRowProb(V,X,Y,NI,1,C).
clearRowProb(V,X,Y,I,S,C):- NI is I+1,clearRowProb(V,X,Y,NI,S,C).
% Column elimination.
clearColumnProb(_,_,_,10,1,1).
clearColumnProb(_,_,_,10,0,0).
clearColumnProb(V,X,Y,I,S,C):- I =:=Y,NI is I+1,clearColumnProb(V,X,Y,NI,S,C).
clearColumnProb(V,X,Y,I,_,C):- cell(X,I,R,_),contain(V,R),removeElement(V,[],R,Res),retract(cell(X,I,_,_)),assert(cell(X,I,Res,0)),NI is I+1,clearColumnProb(V,X,Y,NI,1,C).
clearColumnProb(V,X,Y,I,S,C):- NI is I+1,clearColumnProb(V,X,Y,NI,S,C).
% 3x3 square elimination. [SX, EX, SY, EY] gives the square boundaries.
clearSquareProb(_,_,_,_,_,SY,EY,1,1):-SY>EY.
clearSquareProb(_,_,_,_,_,SY,EY,0,0):-SY>EY.
clearSquareProb(V,X,Y,SX,EX,SY,EY,S,C):-SX=<EX,SX=:=X,SY=:=Y,NSX is SX + 1 ,clearSquareProb(V,X,Y,NSX,EX,SY,EY,S,C).
clearSquareProb(V,X,Y,SX,EX,SY,EY,_,C):-SX=<EX,cell(SX,SY,R,_),contain(V,R),removeElement(V,[],R,Res),retract(cell(SX,SY,_,_)),assert(cell(SX,SY,Res,0)),
                                        NSX is SX+1,clearSquareProb(V,X,Y,NSX,EX,SY,EY,1,C).
clearSquareProb(V,X,Y,SX,EX,SY,EY,S,C):-SX=<EX,NSX is SX + 1 ,clearSquareProb(V,X,Y,NSX,EX,SY,EY,S,C).
clearSquareProb(V,X,Y,SX,EX,SY,EY ,S,C):-SX>EX, NSX is EX-2,NSY is SY+1,clearSquareProb(V,X,Y,NSX,EX,NSY,EY,S,C). 
% Propagate a solved single-candidate cell through its row, column, and square.
% The selected cell should contain exactly one candidate.
clearOneProbCell(X,Y,SX,EX,SY,EY,C):-cell(X,Y,[H|_],0),clearColumnProb(H,X,Y,1,0,CC),clearRowProb(H,X,Y,1,0,CR),clearSquareProb(H,X,Y,SX,EX,SY,EY,0,CS),
                                   retract(cell(X,Y,_,_)),assert(cell(X,Y,[H],1)),C is CC+CR+CS.
clearOneProbCell(X,Y,_,_,_,_,0):-cell(X,Y,_,1).

% Pair strategy: when two cells in a unit share the same two candidates,
% remove those candidates from the rest of that unit.
% Row pair elimination.
clearRowTwoProb(_,_,_,_,10,0,0).
clearRowTwoProb(_,_,_,_,10,1,1).
clearRowTwoProb(L,X1,X2,Y,I,S,C):- (I =:= X1;I =:= X2),NI is I+1,clearRowTwoProb(L,X1,X2,Y,NI,S,C).
clearRowTwoProb(L,X1,X2,Y,I,_,C):- cell(I,Y,R,_),containList(L,R),removeElements(L,R,Res),retract(cell(I,Y,_,_)),
                                   assert(cell(I,Y,Res,0)),NI is I+1,clearRowTwoProb(L,X1,X2,Y,NI,1,C).
clearRowTwoProb(L,X1,X2,Y,I,S,C):- NI is I+1,clearRowTwoProb(L,X1,X2,Y,NI,S,C).
% Column pair elimination.
clearColumnTwoProb(_,_,_,_,10,0,0).
clearColumnTwoProb(_,_,_,_,10,1,1).
clearColumnTwoProb(L,Y1,Y2,X,I,S,C):- (I =:= Y1;I =:= Y2),NI is I+1,clearColumnTwoProb(L,Y1,Y2,X,NI,S,C).
clearColumnTwoProb(L,Y1,Y2,X,I,_,C):- cell(X,I,R,_),containList(L,R),removeElements(L,R,Res),retract(cell(X,I,_,_)),
                                      assert(cell(X,I,Res,0)),NI is I+1,clearColumnTwoProb(L,Y1,Y2,X,NI,1,C).
clearColumnTwoProb(L,Y1,Y2,X,I,S,C):- NI is I+1,clearColumnTwoProb(L,Y1,Y2,X,NI,S,C).
% 3x3 square pair elimination.
clearSquareTwoProb(_,_,_,_,_,_,_,SY,EY,0,0)      :- SY > EY.
clearSquareTwoProb(_,_,_,_,_,_,_,SY,EY,1,1)      :- SY > EY.
clearSquareTwoProb(L,X1,Y1,X2,Y2,SX,EX,SY,EY,S,C):- (SX=:=X1,SY=:=Y1;SX=:=X2,SY=:=Y2),NSX is SX+1,clearSquareTwoProb(L,X1,Y1,X2,Y2,NSX,EX,SY,EY,S,C).
clearSquareTwoProb(L,X1,Y1,X2,Y2,SX,EX,SY,EY,_,C):- SX=<EX,cell(SX,SY,R,_),containList(L,R),removeElements(L,R,Res),retract(cell(SX,SY,_,_)),
                                                   assert(cell(SX,SY,Res,0)),NSX is SX+1,clearSquareTwoProb(L,X1,Y1,X2,Y2,NSX,EX,SY,EY,1,C).
clearSquareTwoProb(L,X1,Y1,X2,Y2,SX,EX,SY,EY,S,C):- SX=<EX,NSX is SX+1,clearSquareTwoProb(L,X1,Y1,X2,Y2,NSX,EX,SY,EY,S,C).
clearSquareTwoProb(L,X1,Y1,X2,Y2,SX,EX,SY,EY,S,C):- SX>EX,NSX is SX-3,NSY is SY+1,clearSquareTwoProb(L,X1,Y1,X2,Y2,NSX,EX,NSY,EY,S,C).
% Scan row/column/square for another cell with the same two candidates.
% The selected cell should contain exactly two candidates.
scanHorizontallyForTwoProbCell(_,_,10,0).
scanHorizontallyForTwoProbCell(X,Y,I,C):-I=\=X,cell(X,Y,R,_),cell(I,Y,TR,_),isEqual(R,TR),clearRowTwoProb(R,X,I,Y,1,0,C).
scanHorizontallyForTwoProbCell(X,Y,I,C):-NI is I+1,scanHorizontallyForTwoProbCell(X,Y,NI,C).
scanVerticallyForTwoProbCell(_,_,10,0).
scanVerticallyForTwoProbCell(X,Y,I,C):- I=\=Y,cell(X,Y,R,_),cell(X,I,TR,_),isEqual(R,TR),clearColumnTwoProb(R,Y,I,X,1,0,C).
scanVerticallyForTwoProbCell(X,Y,I,C):-NI is I+1,scanVerticallyForTwoProbCell(X,Y,NI,C).
scanSquarelyForTwoProbCell(_,_,_,_,SY,EY,0):-SY>EY.
scanSquarelyForTwoProbCell(X,Y,SX,EX,SY,EY,C):-SX=<EX,SX=:=X,SY=:=Y,NSX is SX+1,scanSquarelyForTwoProbCell(X,Y,NSX,EX,SY,EY,C).
scanSquarelyForTwoProbCell(X,Y,SX,EX,SY,EY,C):-SX=<EX,cell(X,Y,R,_),cell(SX,SY,TR,_),isEqual(R,TR),TSX is EX-2,TSY is EY-2,
                                           clearSquareTwoProb(R,X,Y,SX,SY,TSX,EX,TSY,EY,0,C).
scanSquarelyForTwoProbCell(X,Y,SX,EX,SY,EY,C):-SX=<EX,NSX is SX+1,scanSquarelyForTwoProbCell(X,Y,NSX,EX,SY,EY,C).
scanSquarelyForTwoProbCell(X,Y,SX,EX,SY,EY,C):-SX>EX,NSX is EX-2,NSY is SY+1,scanSquarelyForTwoProbCell(X,Y,NSX,EX,NSY,EY,C).
% Apply pair elimination to all units containing the selected cell.
clearTwoCellProb(X,Y,SX,EX,SY,EY,C):-scanVerticallyForTwoProbCell(X,Y,1,CV),scanHorizontallyForTwoProbCell(X,Y,1,CH),scanSquarelyForTwoProbCell(X,Y,SX,EX,SY,EY,CS),C is CV+CH+CS.

% Uniqueness strategy: if a candidate appears nowhere else in a unit,
% keep only that candidate in the current cell.
% Row uniqueness.
checkIfValueIsUniqHorizontally(_,_,_,10).
checkIfValueIsUniqHorizontally(X,Y,V,I):-I=:=X,NI is I+1,checkIfValueIsUniqHorizontally(X,Y,V,NI).
checkIfValueIsUniqHorizontally(_,Y,V,I):-cell(I,Y,R,_),contain(V,R),1=:=2.
checkIfValueIsUniqHorizontally(X,Y,V,I):-cell(I,Y,R,_),not(contain(V,R)),NI is I+1,checkIfValueIsUniqHorizontally(X,Y,V,NI).
% Column uniqueness.
checkIfValueIsUniqVertically(_,_,_,10).
checkIfValueIsUniqVertically(X,Y,V,I):-I=:=Y,NI is I+1,checkIfValueIsUniqVertically(X,Y,V,NI).
checkIfValueIsUniqVertically(X,_,V,I):-cell(X,I,R,_),contain(V,R),1=:=2.
checkIfValueIsUniqVertically(X,Y,V,I):-cell(X,I,R,_),not(contain(V,R)),NI is I+1,checkIfValueIsUniqVertically(X,Y,V,NI).
% 3x3 square uniqueness.
checkIfValueIsUniqSquarely(_,_,_,_,_,SY,EY):-SY>EY.
checkIfValueIsUniqSquarely(X,Y,V,SX,EX,SY,EY):-SX=<EX,X=:=SX,Y=:=SY,NSX is SX+1,checkIfValueIsUniqSquarely(X,Y,V,NSX,EX,SY,EY).
checkIfValueIsUniqSquarely(_,_,V,SX,EX,SY,_):-SX=<EX,cell(SX,SY,R,_),contain(V,R),1=:=2.
checkIfValueIsUniqSquarely(X,Y,V,SX,EX,SY,EY):-SX=<EX,cell(SX,SY,R,_),not(contain(V,R)),NSX is SX+1,checkIfValueIsUniqSquarely(X,Y,V,NSX,EX,SY,EY).
checkIfValueIsUniqSquarely(X,Y,V,SX,EX,SY,EY):-SX>EX,NSY is SY+1,NSX is EX-2,checkIfValueIsUniqSquarely(X,Y,V,NSX,EX,NSY,EY).
% Scan a cell's candidates and keep a candidate if it is unique in a unit.
scanForUniqCell(_,_,_,_,_,_,[],0).                       
scanForUniqCell(X,Y,SX,EX,SY,EY,[V|_],1):-checkIfValueIsUniqSquarely(X,Y,V,SX,EX,SY,EY),retract(cell(X,Y,_,_)),assert(cell(X,Y,[V],0)).
scanForUniqCell(X,Y,_,_,_,_,[V|_],1):-checkIfValueIsUniqVertically(X,Y,V,1),retract(cell(X,Y,_,_)),assert(cell(X,Y,[V],0)).
scanForUniqCell(X,Y,_,_,_,_,[V|_],1):-checkIfValueIsUniqHorizontally(X,Y,V,1),retract(cell(X,Y,_,_)),assert(cell(X,Y,[V],0)).
scanForUniqCell(X,Y,SX,EX,SY,EY,[_|T],S):-scanForUniqCell(X,Y,SX,EX,SY,EY,T,S).
% Solve cells that contain a unique candidate.
solveUniqCellProb(X,Y,SX,EX,SY,EY,C):- cell(X,Y,R,_),scanForUniqCell(X,Y,SX,EX,SY,EY,R,C).
% Scan a 3x3 square and apply the available solving passes.
solveSquareInPuzzle(_,_,SY,EY,0,0):-SY>EY.
solveSquareInPuzzle(_,_,SY,EY,S,1):-SY>EY,S>0.
solveSquareInPuzzle(SX,EX,SY,EY,S,C):-SX=<EX,cell(SX,SY,_,1),NSX is SX+1,solveSquareInPuzzle(NSX,EX,SY,EY,S,C).
solveSquareInPuzzle(SX,EX,SY,EY,_,C):-SX=<EX,cell(SX,SY,R,0),length(R,L),L=:=1,TSX is EX-2,TSY is EY-2,
                                  clearOneProbCell(SX,SY,TSX,EX,TSY,EY,CO),NSX is SX+1,solveSquareInPuzzle(NSX,EX,SY,EY,CO,C).
solveSquareInPuzzle(SX,EX,SY,EY,_,C):-SX=<EX,cell(SX,SY,R,0),length(R,L),L=:=2,TSX is EX-2,TSY is EY-2,NSX is SX+1,
                                  clearTwoCellProb(SX,SY,TSX,EX,TSY,EY,CT),TTSX is EX-2,TTSY is EY-2,solveUniqCellProb(SX,SY,TTSX,EX,TTSY,EY,CU),NS is CT+CU,solveSquareInPuzzle(NSX,EX,SY,EY,NS,C).
solveSquareInPuzzle(SX,EX,SY,EY,_,C):-SX=<EX,NSX is SX+1,TTSX is EX-2,TTSY is EY-2,solveUniqCellProb(SX,SY,TTSX,EX,TTSY,EY,SU),solveSquareInPuzzle(NSX,EX,SY,EY,SU,C).
solveSquareInPuzzle(SX,EX,SY,EY,S,C):-SX>EX,NSX is EX-2,NSY is SY+1,solveSquareInPuzzle(NSX,EX,NSY,EY,S,C).
% Check whether every cell has exactly one candidate.
isSolved(_,10).
isSolved(X,Y):- X=<9,cell(X,Y,R,_),length(R,L),L=:=1,NX is X+1,isSolved(NX,Y).
isSolved(X,Y):- X>9,NX is 1, NY is Y+1,isSolved(NX,NY).
% Repeatedly scan the puzzle until no pass makes progress.
scan(0,R):-        isSolved(1,1),R is 1,!.
scan(0,0).
scan(_,R):-        solveSquareInPuzzle(1,3,1,3,0,C1),solveSquareInPuzzle(4,6,1,3,0,C2),solveSquareInPuzzle(7,9,1,3,0,C3),
                   solveSquareInPuzzle(1,3,4,6,0,C4),solveSquareInPuzzle(4,6,4,6,0,C5),solveSquareInPuzzle(7,9,4,6,0,C6),
                   solveSquareInPuzzle(1,3,7,9,0,C7),solveSquareInPuzzle(4,6,7,9,0,C8),solveSquareInPuzzle(7,9,7,9,0,C9),
                   NC is (C1+C2+C3+C4+C5+C6+C7+C8+C9),scan(NC,R),!.
% Public entry point: initialize candidates and run solving passes.
solvePuzzle(R):-fillPuzzleProb(1,1),scan(1,R),!.
