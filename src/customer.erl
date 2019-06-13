%%%-------------------------------------------------------------------
%%% @author dc
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. Jun 2019 13:12
%%%-------------------------------------------------------------------
-module(customer).
-author("dc").

% Imports
-import(io, [fwrite/1, fwrite/2]).

%% API
-export([create_customer_account/0, request_loan/4, listen/0]).

create_customer_account() ->
  receive
    {Sender, {Name, Amount, Banks, BankMap}} ->
      fwrite("~w~n", [Banks]),
%%      rand:uniform()
%%      NoOfBanks = length(Banks),
%%      fwrite("~w~n", [Banks]),
%%      io:format("~p Length is ~p~n", [Banks, length(Banks)]),
      Entry = #{name => Name, balance => Amount},
      timer:sleep(4000),
      fwrite("~p ~p~n", [maps:get(name, Entry), maps:get(balance, Entry)]),
      request_loan(Entry, Banks, BankMap, Sender)
  end.

request_loan(Entry, Banks, BankMap, MainId) ->
  case maps:size(BankMap) == 0 of
    false ->
%%  fwrite("Bank Map: ~w~n", [BankMap]),
      RandomAmount = rand:uniform(50),
      RandomSleepTime = rand:uniform(100),
      timer:sleep(RandomSleepTime),
      NoOfBanks = length(Banks),
      RandomBankNumber = rand:uniform(NoOfBanks),
      EachBank = lists:nth(RandomBankNumber, Banks),
      {BankName, Amount} = EachBank,
      io:format("Length is ~p~n", [NoOfBanks]),
      fwrite("Map size: ~w~n", [maps:size(BankMap)]),
%%  fwrite("Random Amount: ~w~n", [RandomAmount]),
%%      fwrite("Random Bank: ~w~n", [BankName]),
      Bid = maps:get(BankName, BankMap),
%%  fwrite("Id: ~w~n", [Bid]),
%%  fwrite("Customer id: ~w~n", [self()]),
%%      fwrite("~w requests a loan of ~w dollar(s) from ~w~n", [maps:get(name, Entry), RandomAmount, BankName]),
      MainId ! {self(), {display_customer, BankName, RandomAmount, maps:get(name, Entry)}},
      Bid ! {self(), {message, RandomAmount, maps:get(name, Entry)}},
      Status = listen(),
      fwrite("Status: ~p~n", [Status]),

      case Status == "Approves" of
        false ->
          NewMap = maps:remove(BankName, BankMap),
          NewList = lists:delete(EachBank, Banks),
%%          fwrite("Banks: ~w~n", [NewList]),
%%          fwrite("Map: ~w~n", [NewMap]),
          request_loan(Entry, NewList, NewMap, MainId);
        true ->
%%          fwrite("Approves~n"),
          Balance = maps:get(balance, Entry),
          NewBalance = Balance - RandomAmount,
          fwrite("Apna balance: ~w~n", [NewBalance]),

          case NewBalance > 0 of
            false ->
              case NewBalance == 0 of
                false ->
                  request_loan(Entry, Banks, BankMap, MainId);
                true ->
%%                  fwrite("All loan amount is requested")
                  MainId ! {self(), {customer_error, "All loan amount is requested"}}
              end;
            true ->
              NewMap = #{name => maps:get(name, Entry), balance => NewBalance},
              fwrite("New entry: ~w~n", [NewMap]),
              request_loan(NewMap, Banks, BankMap, MainId)
          end
      end;
    true ->
      MainId ! {self(), {customer_error, "No more Banks left to request"}}
%%      fwrite("No more Banks left to request")
  end.

listen() ->
  receive
    {Sender, {Name, Status}} ->
%%      fwrite("Received response from ~w, Status: ~p~n", [Name, Status]),
      Status
  end.