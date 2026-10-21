% :- dynamic dynamic_predicates/N allows states to change during execution.
:- dynamic current_room/1.
:- dynamic inventory/1.
:- dynamic object_at/2.
:- dynamic door_locked/0.

% --- 1. Initial State Setup ---
init_state :-
    retractall(current_room(_)),
    retractall(inventory(_)),
    retractall(object_at(_, _)),
    retractall(door_locked),

    asserta(current_room(hallway)),
    asserta(object_at(key, library)),
    asserta(object_at(sword, armory)),
    asserta(door_locked).

% --- 2. Map Layout (Static Facts) ---
% connected(Room1, Direction, Room2)
connected(hallway, north, library).
connected(hallway, south, armory).
connected(hallway, east, garden).

connected(library, south, hallway).
connected(armory, north, hallway).

connected(garden, west, hallway).
connected(garden, east, freedom).

% --- 3. Descriptions ---
description(hallway, 'You are in a dimly lit hallway. To the north is the Library, to the south is the Armory, and a heavy wooden door leads east to the Garden.').
description(library, 'Rows of dusty books line the walls. It feels eerie but quiet. You can head south back to the hallway.').
description(armory, 'Rusty shields and weapons hang on the walls. A menacing shadow moves in the corner! You can head north back to the hallway.').
description(garden, 'Fresh air hits your face! You are in the garden. To the east lies your path to freedom. To the west is the hallway door.').

% --- 4. Core Game Commands ---

% Look around the current room
look :-
    current_room(Room),
    description(Room, Desc),
    writeln(Desc),
    list_items(Room).

% Helper to list items on the floor
list_items(Room) :-
    object_at(Item, Room),
    format('You see a ~w on the floor.~n', [Item]),
    fail.
list_items(_).

% Movement Logic
go(Direction) :-
    current_room(Current),
    connected(Current, Direction, Next),
    can_move(Current, Direction, Next), !,
    retract(current_room(Current)),
    asserta(current_room(Next)),
    look,
    check_hazards.

go(_) :-
    writeln('You cannot go that way.').

% Movement Restrictions (Locked Door)
can_move(hallway, east, garden) :-
    door_locked, !,
    writeln('The heavy wooden door leading east is locked tight. You need a key.'),
    fail.
can_move(_, _, _). % Default: allowed to move

% Picking up items
take(Item) :-
    current_room(Room),
    object_at(Item, Room), !,
    retract(object_at(Item, Room)),
    asserta(inventory(Item)),
    format('You picked up the ~w.~n', [Item]).
take(_) :-
    writeln('That item is not here.').

% Using items (Unlocking the door)
unlock :-
    current_room(hallway),
    inventory(key),
    door_locked, !,
    retract(door_locked),
    writeln('You turn the key in the heavy door. *CLICK*. The path east to the Garden is open!').
unlock :-
    current_room(hallway),
    door_locked, !,
    writeln('You do not have the key.').
unlock :-
    writeln('There is nothing to unlock here.').

% Check what you are carrying
inventory :-
    writeln('You are carrying:'),
    forall(inventory(Item), format('- ~w~n', [Item])).

% --- 5. Hazard & Win/Loss Conditions ---
check_hazards :-
    current_room(armory),
    \+ inventory(sword), !,
    writeln('GAME OVER: A monster jumps out from the shadows and catches you unarmed! Type "start." to try again.'),
    abort.
check_hazards :-
    current_room(armory),
    inventory(sword), !,
    writeln('A monster lunges at you, but you strike it down with your sword! The armory is now safe.').
check_hazards :-
    current_room(freedom), !,
    writeln('CONGRATULATIONS! You escaped the mansion and won the game!').
check_hazards.

% --- 6. Instructions & Start Game ---
instructions :-
    writeln('--------------------------------------------------'),
    writeln('Welcome to the Prolog Mansion Text Adventure!'),
    writeln('Commands:'),
    writeln('  start.             - Start the game'),
    writeln('  look.              - Look around your current room'),
    writeln('  go(Direction).     - Move (north, south, east, west)'),
    writeln('  take(Item).        - Pick up an object'),
    writeln('  unlock.            - Unlock a locked door'),
    writeln('  inventory.         - Check your items'),
    writeln('  instructions.      - Show this menu again'),
    writeln('--------------------------------------------------').

start :-
    init_state,
    instructions,
    look.
