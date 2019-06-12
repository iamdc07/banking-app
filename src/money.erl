%%%-------------------------------------------------------------------
%%% @author dc
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. Jun 2019 13:12
%%%-------------------------------------------------------------------
-module(money).
-author("dc").

%% Imports
-import(io, [fwrite/1, fwrite/2]).
-import(lists, [last/1, nth/2]).

%% API
-export([start/0]).

start() ->
  read_file().

read_file() ->
  {ok, L} = file:consult("customers.txt"),
  fwrite("~w~n", [L]),
  create_processes(L).

create_processes(Data) ->
  case Data == [] of
    false ->
      Cid = spawn(customer, create_customer_account, []),
      [TheHead | TheTail] = Data,
      {Name, Amount} = TheHead,
      Cid ! {self(), {Name, Amount}},
      create_processes(TheTail);
    true ->
      Data = []
  end.