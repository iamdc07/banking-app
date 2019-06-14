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
-export([start/0, listen/2]).

start() ->
  read_file().

read_file() ->
  {ok, Banks} = file:consult("banks.txt"),
  {ok, Customers} = file:consult("customers.txt"),
  fwrite("------------- Banks and Financial Objectives ------------~n"),
  show_data(Banks),
  fwrite("------------- Customers and Loan Objectives -------------~n"),
  show_data(Customers),
  BankMap = create_bank_processes(Banks, #{}),
%%  fwrite("BankMap: ~w~n", [BankMap]),
  create_customer_processes(Customers, Banks, BankMap),
  BankDataMap = create_data_map(Banks, #{}),
  CustomerDataMap = create_data_map(Customers, #{}),
  fwrite("BankDataMap: ~w~n", [BankDataMap]),
  fwrite("CustomerDataMap: ~w~n", [CustomerDataMap]),
  timer:sleep(3000),
  listen(BankDataMap, CustomerDataMap).

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

create_data_map (Data, DataMap) ->
  case Data == [] of
    false ->
      [TheHead | TheTail] = Data,
      {BankName, Amount} = TheHead,
      Entry = maps:put(BankName, Amount, DataMap),
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

listen(BankDataMap, CustomerDataMap) ->
  fwrite("BANKDATAMAP: ~w~n", [BankDataMap]),
  fwrite("CUSTOMERDATAMAP: ~w~n", [CustomerDataMap]),
  receive
    {Sender, {display_bank, BankName, Amount, Status, CustomerName, NewBankBalance}} ->
      fwrite("~w ~s loan of ~w dollars from ~w~n", [BankName, Status, Amount, CustomerName]),

      if
        Status == "Approves" ->
          CustomerBalance = maps:get(CustomerName, CustomerDataMap),
          NewCustomerBalance = CustomerBalance - Amount,
          NewBankMap = maps:put(BankName, NewBankBalance, BankDataMap),
          NewCustomerMap = maps:put(CustomerName, NewCustomerBalance, CustomerDataMap),
          listen(NewBankMap, NewCustomerMap);
        true ->
          listen(BankDataMap, CustomerDataMap)
      end;

    {Sender, {display_customer, BankName, Amount, CustomerName}} ->
      fwrite("~w requests a loan of ~w dollar(s) from ~w~n", [CustomerName, Amount, BankName]),
      listen(BankDataMap, CustomerDataMap);

    {Sender, {customer_error, Message}} ->
      fwrite("~s~n", [Message]),
      listen(BankDataMap, CustomerDataMap)
  end.
