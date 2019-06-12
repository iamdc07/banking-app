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
  {ok, Banks} = file:consult("banks.txt"),
%%  fwrite("~w~n", [B]),
  NewMap = #{},
  BankMap = create_bank_processes(Banks, NewMap),
%%  fwrite("~w~n", [BankMap]),
  {ok, Customers} = file:consult("customers.txt"),
%%  fwrite("~w~n", [C]),
  create_customer_processes(Customers, BankMap).

create_customer_processes(Customers, BankMap) ->
  case Customers == [] of
    false ->
      Cid = spawn(customer, create_customer_account, []),
      [TheHead | TheTail] = Customers,
      {Name, Amount} = TheHead,
      Cid ! {self(), {Name, Amount, BankMap}},
      create_customer_processes(TheTail, BankMap);
    true ->
      Customers = []
  end.

create_bank_processes(Data, NewMap) ->
  case Data == [] of
    false ->
      Bid = spawn(bank, create_banks, []),
      [TheHead | TheTail] = Data,
      {BankName, Amount} = TheHead,
      Bid ! {self(), {BankName, Amount}},
      Entry = maps:put(BankName, Bid, NewMap),
      create_bank_processes(TheTail, Entry);
    true ->
      NewMap
  end.