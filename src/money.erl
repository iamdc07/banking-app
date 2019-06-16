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
-export([start/0, listen/5]).

start() ->
  read_file().

read_file() ->
  {ok, Banks} = file:consult("banks.txt"),
  {ok, Customers} = file:consult("customers.txt"),
  fwrite("------------- Banks and Financial Objectives ------------~n"),
  show_data(Banks),
  fwrite("------------- Customers and Loan Objectives -------------~n"),
  show_data(Customers),
  fwrite("~n"),

  BankMap = create_bank_processes(Banks, #{}),
  create_customer_processes(Customers, Banks, BankMap),
  BankDataMap = create_bank_data_map(Banks, #{}),
  CustomerDataMap = create_data_map(Customers, #{}),

  timer:sleep(3000),
  listen(0, BankDataMap, CustomerDataMap, Customers, []).

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

create_bank_data_map(Data, DataMap) ->
  case Data == [] of
    false ->
      [TheHead | TheTail] = Data,
      {BankName, Amount} = TheHead,
      Entry = maps:put(BankName, Amount, DataMap),
      create_bank_data_map(TheTail, Entry);
    true ->
      DataMap
  end.

create_data_map(Data, DataMap) ->
  case Data == [] of
    false ->
      [TheHead | TheTail] = Data,
      {BankName, Amount} = TheHead,
      Entry = maps:put(BankName, 0, DataMap),
      create_data_map(TheTail, Entry);
    true ->
      DataMap
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

listen(Flag, BankDataMap, CustomerDataMap, CustomerData, CustomerResults) ->
  Size = maps:size(CustomerDataMap),
  if
    Flag == Size ->
      timer:sleep(2000),
      fwrite("~n"),
      display_customer_data(CustomerResults),
      display_bank_data(maps:to_list(BankDataMap));
    true ->
      []
  end,

  receive
    {Sender, {display_bank, BankName, Amount, Status, CustomerName, NewBankBalance}} ->
      fwrite("~w ~s loan of ~w dollar(s) from ~w~n", [BankName, Status, Amount, CustomerName]),
      if
        Status == "Approves" ->
          CustomerBalance = maps:get(CustomerName, CustomerDataMap),
          NewCustomerBalance = CustomerBalance + Amount,
          NewBankMap = maps:put(BankName, NewBankBalance, BankDataMap),
          NewCustomerMap = maps:put(CustomerName, NewCustomerBalance, CustomerDataMap),
          listen(Flag, NewBankMap, NewCustomerMap, CustomerData, CustomerResults);
        true ->
          listen(Flag, BankDataMap, CustomerDataMap, CustomerData, CustomerResults)
      end;

    {Sender, {display_customer, BankName, Amount, CustomerName}} ->
      fwrite("~w requests a loan of ~w dollar(s) from ~w~n", [CustomerName, Amount, BankName]),
      listen(Flag, BankDataMap, CustomerDataMap, CustomerData, CustomerResults);

    {Sender, {customer_error, Message}} ->
      fwrite("~s~n", [Message]),
      listen(Flag, BankDataMap, CustomerDataMap, CustomerData, CustomerResults);

    {Sender, {customer_signal, CustomerName, Amount, Message}} ->
      if
        Message == "No more Banks left to request" ->
%%          fwrite("~w WAS ABLE TO BORROW ~w DOLLAR(s)~n", [CustomerName, maps:get(CustomerName, CustomerDataMap)]),
          Result = maps:put(CustomerName, maps:get(CustomerName, CustomerDataMap), #{}),
          NewCustomerResults = lists:append([{"borrow", Result}], CustomerResults);
        Message == "All loan amount is requested" ->
%%          fwrite("~w HAS REACHED THE OBJECTIVE OF ~w DOLLAR(s)~n", [CustomerName, maps:get(CustomerName, CustomerDataMap)]),
          Result = maps:put(CustomerName, maps:get(CustomerName, CustomerDataMap), #{}),
          NewCustomerResults = lists:append([{"reached", Result}], CustomerResults);
%%          fwrite("~p~n", [NewCustomerResults]);
        true ->
%%          fwrite("~w WAS ABLE TO BORROW ~w DOLLAR(s)~n", [CustomerName, maps:get(CustomerName, CustomerDataMap)]),
          Result = maps:put(CustomerName, maps:get(CustomerName, CustomerDataMap), #{}),
          NewCustomerResults = lists:append([{"borrow", Result}], CustomerResults)
      end,
      listen(Flag + 1, BankDataMap, CustomerDataMap, CustomerData, NewCustomerResults);

    {Sender, {bank_signal, BankName, Amount, Message}} ->
      if
        Message == "No Bank Balance" ->
          fwrite("~w has ~w dollar(s) remaining~n", [BankName, maps:get(BankName, BankDataMap)]);
        true ->
          fwrite("~w has ~w dollar(s) remaining~n", [BankName, maps:get(BankName, BankDataMap)])
      end,
      listen(Flag, BankDataMap, CustomerDataMap, CustomerData, CustomerResults)

  end.

display_customer_data(Data) ->
  case Data == [] of
    false ->
      [Head | Tail] = Data,
      {Message, DataMap} = Head,
      [TheHead | TheTail] = maps:to_list(DataMap),
      {CustomerName, Amount} = TheHead,
      if
        Message == "reached" ->
          fwrite("~w HAS REACHED THE OBJECTIVE OF ~w DOLLAR(s)~n", [CustomerName, Amount]);
        true ->
          fwrite("~w WAS ABLE TO BORROW ~w DOLLAR(s)~n", [CustomerName, Amount])
      end,
      display_customer_data(Tail);
    true ->
      Data = []
  end.

display_bank_data(Data) ->
  case Data == [] of
    false ->
      [TheHead | TheTail] = Data,
      {BankName, Amount} = TheHead,
      fwrite("~w has ~w dollar(s) remaining~n", [BankName, Amount]),
      display_bank_data(TheTail);
    true ->
      Data = []
  end.