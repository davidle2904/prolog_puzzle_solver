/** Fill-in Puzzle Solver

This program supply a predicate alongside with its support
predicates for solving a puzzle. Assuming the Puzzle and
WordList are proper.
Example of use: puzzle_solution(Puzzle, WordList).

For Project 1 - COMP30020 Declarative Programming.

@author Tran Dao Le
@id trandaol
@student id 1133601
*/


% load the clpfd library for working with matrices.
:- ensure_loaded(library(clpfd)).


% puzzle_solution(+Puzzle, +WordList)
% Solve the puzzle by getting all the slots in the puzzle, for
% each slot, take the list of its unifiable words, make it a
% pair, then bind the words to the slot until we get the answer.
puzzle_solution(Puzzle, WordList) :-
    slots_in_puzzle(Puzzle, Slots),
    get_unifiable_words(Slots, WordList, Pairs),
    bind_words(Pairs).


% slots_in_puzzle(+Puzzle, -Slots)
% Find all the slots in the puzzle by take them in the rows,
% and then transpose it to get from the columns. Just include
% slots that have more than 2 squares
slots_in_puzzle(Puzzle, Slots) :-
    slots_in_all_rows(Puzzle, VerticalSlots),
    transpose(Puzzle, PuzzleT),
    slots_in_all_rows(PuzzleT, HorizontalSlots),
    append(VerticalSlots, HorizontalSlots, AllSlots),
    include(more_than_1, AllSlots, Slots).


% slots_in_all_rows(+Rows, -Slots)
% Gathering the slots from each row and make it into a list
% for the whole.
slots_in_all_rows(Rows, Slots) :-
    slots_in_all_rows(Rows, [], Slots).

slots_in_all_rows([], Acc, Slots) :-
    Slots = Acc.

slots_in_all_rows([Row|Rows], Acc, Slots) :-
    slots_in_row(Row, Slots1),
    append(Acc, Slots1, Acc1),
    slots_in_all_rows(Rows, Acc1, Slots).


% slots_in_row(+Row, -Slots)
% Get the slot in each row by get the adjacent fillable squares
% and go through the unfillable squares ('#').
slots_in_row(Row, Slots) :-
    slots_in_row(Row, [], Slots).

slots_in_row([], Acc, Slots) :-
    Slots = Acc.

slots_in_row([Square|Row], Acc, Slots) :-
    ( Square == '#' ->
        slots_in_row(Row, Acc, Slots)
    ;   adjacent_place([Square|Row], Slot, Suffix),
        Acc1 = [Slot|Acc],
        slots_in_row(Suffix, Acc1, Slots)
    ).


% adjacent_place(+Row, -Slot, -Suffix)
% Take a slot in a row by getting the adjacent squares (fillable
% squares) until we meet a solid square. Also return the
% remainder of the row for further slots searching.
adjacent_place(Row, Slot, Suffix) :-
    adjacent_place(Row, [], Slot, Suffix).

adjacent_place([], Acc, Slot, []) :-
    Slot = Acc.

adjacent_place([Square|Row], Acc, Slot, Suffix) :-
    ( Square == '#' ->
        Slot = Acc,
        Suffix = Row
    ;   append(Acc, [Square], Acc1),
        adjacent_place(Row, Acc1, Slot, Suffix)
    ).


% more_than_1(+List)
% The predicate holds when the slot is more than 1 square long
more_than_1(Squares) :-
    length(Squares, X),
    X>1.


% get_unifiable_words(+Squares, +WordList, -Pairs)
% Pair is a composition of Slot and its unifiable words, represent
% by the Slot-[Words] type.
% For each Slot, gather the words that can be unify with it from
% the list of all words, and map them to a Pair in the output list.
get_unifiable_words([], _, []).

get_unifiable_words([Slot|Slots], WordList, [Slot-WordForSlot|Rest]) :-
    include(unifiable_word(Slot), WordList, WordForSlot),
    get_unifiable_words(Slots, WordList, Rest).


% unifiable_word(+Slot, +Word)
% Check whether Slot and Word can be unify by checking each
% corresponding square and character if they are unifiable.
unifiable_word([], []).

unifiable_word([Square|Squares], [Char|Chars]) :-
    unifiable_char(Square, Char),
    unifiable_word(Squares, Chars).


% unifiable_char(+Square, +Char)
% Check whether the square can be unify with a character, if
% the square holds a character already, they must be the same.
unifiable_char(Square, Char) :-
    ( var(Square) ->
        true
    ; Square == Char
    ).


% bind_words(+Pairs)
% Sort the pair list by the number of empty squares in slot,
% then by number of words can be unify with the slot for a
% faster searching speed and avoid to much searching words.
% After that, bind a word to a slot, unify the squares, then
% refresh the list. Recursively do this, if we can bind 
% all of the words, that is a solution for the puzzle.
bind_words([]).

bind_words(Pairs) :-
    give_key_and_sort(empt_squares_key, Pairs, SortedByEmpt),
    give_key_and_sort(num_words_key, SortedByEmpt, SortedPairs),
    SortedPairs = [Slot-Words|Rest],
    unify(Slot-Words, Word),
    maplist(refresh_slot(Word), Rest, RestRemovedWord),
    bind_words(RestRemovedWord).



% give_key_and_sort(+Func, +Pairs, -SortedPairs)
% Give the key generate by Func to each pair, sort the pairs
% then delete the given key,
give_key_and_sort(Func, Pairs, SortedPairs) :-
    maplist(Func, Pairs, PairsWithKey),
    keysort(PairsWithKey, SortedPairsWithKey),
    maplist(delete_key, SortedPairsWithKey, SortedPairs).


% num_word_key(+Pair, -PairWithKey)
% Give each Slot-[Word] pair a Key of length of the list Words
% for the purpose of sorting.
num_words_key(Slot-Words, Length-Slot-Words) :-
    length(Words, Length).


% delete_key(+PairWithKey, -Pair)
% Delete the Key that we generate and return the sorted 
% list of Slot-[Words] pair.
delete_key(_-Slot-Words, Slot-Words).


% empt_squares_key(+Pair, -PairWithKey)
% Give each Slot-[Word] pair a Key of the number of empty squares
% in the Slot for the purpose of sorting.
empt_squares_key(Slot-Word, Num-Slot-Word) :-
	num_empty_squares(Slot, Num).


% num_empty_squares(+Slot, -Num)
% Calculate the number of empty squares in each Slot
num_empty_squares(Slot, Num) :-
    num_empty_squares(Slot, 0, Num).

num_empty_squares([], Acc, Num) :-
    Num = Acc.

num_empty_squares([Square|Squares], Acc, Num) :-
	( var(Square) -> 
        Acc1 is Acc + 1,
		num_empty_squares(Squares, Acc1, Num)
	;	num_empty_squares(Squares, Acc, Num)
	).


% unify(+Slot-Words, -Word)
% Unify the slot with a member in the list of unifiable words.
unify(Slot-Words, Word) :-
    member(Word, Words),
    Slot = Word.


% refresh_slot(+Word, +Pair, -RefreshedPair)
% Refresh the list of Words in the pair by deleting the unified Word
% and excluding all the elements that cannot be unfied with Slot.
refresh_slot(Word, Slot-Words, Slot-WordsRefreshed) :-
    delete_unified_word(Words, Word, WordsDeleted),
    include(unifiable_word(Slot), WordsDeleted, WordsRefreshed).


% delete_unified_word(+List, +DelWord, -ListRemovedWord)
% Delete only the first occurance of the Word we recently unified
% from the list of words for a slot.
delete_unified_word(Words, DelWord, ListDeletedWord) :-
    delete_unified_word(Words, DelWord, [], ListDeletedWord).

delete_unified_word([], _, Acc, ListDeletedWord) :-
    ListDeletedWord = Acc.

delete_unified_word([Word|Words], DelWord, Acc , ListDeletedWord) :-
    ( Word == DelWord ->
        append(Acc, Words, ListDeletedWord)
    ;   Acc1 = [Word|Acc],
        delete_unified_word(Words, DelWord, Acc1, ListDeletedWord)
    ).
    
