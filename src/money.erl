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
-export([start/0, listen/4]).

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
%%  fwrite("BankMap: ~w~n", [BankMap]),
  create_customer_processes(Customers, Banks, BankMap),
  BankDataMap = create_bank_data_map(Banks, #{}),
  CustomerDataMap = create_data_map(Customers, #{}),
%%  fwrite("BankDataMap: ~w~n", [BankDataMap]),
%%  fwrite("CustomerDataMap: ~w~n", [CustomerDataMap]),
  timer:sleep(3000),
  NoOfBanks = maps:size(BankDataMap),
  NoOfCustomers = maps:size(CustomerDataMap),
%%  fwrite("CHECK ~w~n", [Customers]),
  listen(0, BankDataMap, CustomerDataMap, Customers).

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
%%      fwrite("avc~w~n", [TheHead]),
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

listen(Flag, BankDataMap, CustomerDataMap, CustomerData) ->
  Size = maps:size(CustomerDataMap),
  if
    Flag == Size ->
      timer:sleep(2000),
      fwrite("~n"),
      display_bank_data(maps:to_list(BankDataMap));
    true ->
      []
  end,
%%  fwrite("BANKDATAMAP: ~w~n", [BankDataList]),
%%  fwrite("CUSTOMERDATAMAP: ~w~n", [CustomerDataList]),
%%%%  List1 = maps:values(BankDataMap),
%%%%  Sum = lists:sum(List1),
%%%%  List2 = maps:values(CustomerDataMap),
%%%%  Sum2 = lists:sum(List2),
%%  Size3 = maps:size(BankDataMap),
%%  Size4 = maps:size(CustomerDataMap),
%%  Size1 = length(BankDataList),
%%  Size2 = length(CustomerDataList),
%%
%%  if
%%    Size1 == Size3 ->
%%      io:fwrite("BANKZERO~n"),
%%%%      show_data(BankDataList),
%%%%      show_data(CustomerDataList);
%%%%      fwrite("~w~n", [BankDataList]);
%%%%      fwrite("MAP: ~w~n", [BankDataMap]),
%%      List1 = maps:to_list(BankDataMap),
%%      show_data(List1),
%%%%      fwrite("MAP: ~w~n", [CustomerDataMap]);
%%      List2 = maps:to_list(CustomerDataMap),
%%      show_data(List2);
%%    Size2 == Size4 ->
%%      io:fwrite("CUSTOMERZERO~n"),
%%%%      show_data(BankDataList),
%%%%      show_data(CustomerDataList);
%%%%      fwrite("~w~n", [CustomerDataList]);
%%%%      fwrite("Amount: ~w~n", [maps:values(CustomerDataMap)]);
%%%%      fwrite("MAP: ~w~n", [BankDataMap]),
%%%%      fwrite("MAP: ~w~n", [CustomerDataMap])
%%      List1 = maps:to_list(BankDataMap),
%%      show_data(List1),
%%      List2 = maps:to_list(CustomerDataMap),
%%      show_data(List2),
%%      display_customer_data(List2, CustomerData);
%%    true ->
%%      io:fwrite("False~n")
%%  end,

  receive
    {Sender, {display_bank, BankName, Amount, Status, CustomerName, NewBankBalance}} ->
      fwrite("~w ~s loan of ~w dollar(s) from ~w~n", [BankName, Status, Amount, CustomerName]),
%%      listen(BankDataList, CustomerDataList, BankDataMap, CustomerDataMap),
      if
        Status == "Approves" ->
          CustomerBalance = maps:get(CustomerName, CustomerDataMap),
          NewCustomerBalance = CustomerBalance + Amount,
          NewBankMap = maps:put(BankName, NewBankBalance, BankDataMap),
          NewCustomerMap = maps:put(CustomerName, NewCustomerBalance, CustomerDataMap),
          listen(Flag, NewBankMap, NewCustomerMap, CustomerData);
        true ->
          listen(Flag, BankDataMap, CustomerDataMap, CustomerData)
      end;

    {Sender, {display_customer, BankName, Amount, CustomerName}} ->
      fwrite("~w requests a loan of ~w dollar(s) from ~w~n", [CustomerName, Amount, BankName]),
      listen(Flag, BankDataMap, CustomerDataMap, CustomerData);

    {Sender, {customer_error, Message}} ->
      fwrite("~s~n", [Message]),
      listen(Flag, BankDataMap, CustomerDataMap, CustomerData);

    {Sender, {customer_signal, CustomerName, Amount, Message}} ->
      DataTuple = {CustomerName, Amount},
%%      NewList = lists:append(CustomerDataList, [DataTuple]),
      if
        Message == "No more Banks left to request" ->
          fwrite("~w WAS ABLE TO BORROW ~w DOLLAR(s)~n", [CustomerName, maps:get(CustomerName, CustomerDataMap)]);
        Message == "All loan amount is requested" ->
          fwrite("~w HAS REACHED THE OBJECTIVE OF ~w DOLLAR(s)~n", [CustomerName, maps:get(CustomerName, CustomerDataMap)]);
        true ->
          fwrite("~w WAS ABLE TO BORROW ~w DOLLAR(s)~n", [CustomerName, maps:get(CustomerName, CustomerDataMap)])
      end,
%%      display_bank_data(maps:to_list(BankDataMap)),
      listen(Flag + 1, BankDataMap, CustomerDataMap, CustomerData);

    {Sender, {bank_signal, BankName, Amount, Message}} ->
      DataTuple = {BankName, Amount},
%%      NewList = lists:append(BankDataList, [DataTuple]),
      if
        Message == "No Bank Balance" ->
          fwrite("~w has ~w dollar(s) remaining~n", [BankName, maps:get(BankName, BankDataMap)]);
        true ->
          fwrite("~w has ~w dollar(s) remaining~n", [BankName, maps:get(BankName, BankDataMap)])
      end,
      listen(Flag, BankDataMap, CustomerDataMap, CustomerData)

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

display_customer_data(List1, List2) ->
  case List1 == [] of
    false ->
      fwrite("L1: ~w~n", [List1]),
      fwrite("L2: ~w~n", [List2]),
      Last1 = lists:last(List1),
      Last2 = lists:last(List2),
      fwrite("L1 ~w~n", [Last1]),
      fwrite("L2 ~w~n", [Last2]),
%%      {BankName, Amount} = TheHead,
%%      fwrite("~w ~w~n", [BankName, Amount]),
      display_customer_data(lists:delete(Last1, List1), lists:delete(Last2, List2));
    true ->
      List1 = []
  end.