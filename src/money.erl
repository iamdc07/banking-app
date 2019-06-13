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
-export([start/0, display/0, listen/0]).

start() ->
  read_file().

read_file() ->
  {ok, Banks} = file:consult("banks.txt"),
  {ok, Customers} = file:consult("customers.txt"),
  fwrite("------------- Banks and Financial Objectives ------------~n"),
  show_data(Banks),
  fwrite("------------- Customers and Loan Objectives -------------~n"),
  show_data(Customers),
  NewMap = #{},
  BankMap = create_bank_processes(Banks, NewMap),
%%  fwrite("~w~n", [BankMap]),
  create_customer_processes(Customers, Banks, BankMap),
  timer:sleep(3000),
  listen().

create_customer_processes(Customers, Banks, BankMap) ->
  case Customers == [] of
    false ->
      Cid = spawn(customer, create_customer_account, []),
      [TheHead | TheTail] = Customers,
      {Name, Amount} = TheHead,
      Cid ! {self(), {Name, Amount, Banks, BankMap}},
      create_customer_processes(TheTail, Banks, BankMap);
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

show_data(Data) ->
  case Data == [] of
    false ->
      [TheHead | TheTail] = Data,
      {BankName, Amount} = TheHead,
      fwrite("~w ~w~n", [BankName, Amount]),
      show_data(TheTail);
    true ->
      Data = []
  end.

display() ->
  receive
    {Sender, {bank, Message}} ->
      fwrite("BANK: ~w~n", [Message]),
      display();
    {Sender, {customer, Message}} ->
      fwrite("CUSTOMER: ~w~n", [Message])
  end.

listen() ->
  receive
    {Sender, {display_bank, BankName, Amount, Status, CustomerName}} ->
      fwrite("~w ~s loan of ~w dollars from ~w~n", [BankName, Status, Amount, CustomerName]),
      listen();

    {Sender, {display_customer, BankName, Amount, CustomerName}} ->
      fwrite("~w requests a loan of ~w dollar(s) from ~w~n", [CustomerName, Amount, BankName]),
      listen();

    {Sender, {customer_error, Message}} ->
      fwrite("~s~n", [Message]),
      listen()
  end.
