%%%-------------------------------------------------------------------
%%% @author dc
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. Jun 2019 23:38
%%%-------------------------------------------------------------------
-module(test).
-author("dc").

%% API
-export([start/0]).

%%-record(person, {age}).
-record(element, {name = myname,age }).

start() ->
  tuple_fun(),
  list_fun(),
  record_fun(),
  map_fun().

tuple_fun () ->
  io:fwrite("Hello world\n"),
  P = {person, "Dc", 24},
  {person, _ , Age} = P,
  io:fwrite("~w", [Age]).

list_fun () ->
  io:fwrite("List function\n"),
  List1 = [14 , 12],
  io:fwrite("~w", [List1]),
  [TheHead | TheRest] = List1,
  io:fwrite("~w~n", [TheRest]).

record_fun () ->
%%  R1 = #element{},
  R2 = #element{age = 99},
  Age = R2#element.age,
  io:fwrite("~w~n", [R2]).

map_fun () ->
  M1 = #{man => "joe", woman => "sue"},
  io:fwrite("~w", [M1]).

%% erlc test.erl
%% erl -noshell -s test -s init stop