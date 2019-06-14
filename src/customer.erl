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
      Entry = #{name => Name, balance => Amount},
      timer:sleep(4000),
      request_loan(Entry, Banks, BankMap, Sender)
  end.

request_loan(Entry, Banks, BankMap, MainId) ->
  case maps:size(BankMap) == 0 of
    false ->
      RandomAmount = rand:uniform(50),
      RandomSleepTime = rand:uniform(100),
      timer:sleep(RandomSleepTime),
      NoOfBanks = length(Banks),
      RandomBankNumber = rand:uniform(NoOfBanks),
      EachBank = lists:nth(RandomBankNumber, Banks),
      {BankName, Amount} = EachBank,

      Bid = maps:get(BankName, BankMap),
      Balance = maps:get(balance, Entry),
      NewBalance = Balance - RandomAmount,

      case NewBalance > 0 of
        false ->
          case NewBalance == 0 of
            false ->
              request_loan(Entry, Banks, BankMap, MainId);
            true ->
              MainId ! {self(), {display_customer, BankName, RandomAmount, maps:get(name, Entry)}},
              Bid ! {self(), {request, RandomAmount, maps:get(name, Entry)}},

              Status = listen(),

              case Status == "Approves" of
                false ->
                  NewMap = maps:remove(BankName, BankMap),
                  NewList = lists:delete(EachBank, Banks),
                  request_loan(Entry, NewList, NewMap, MainId);
                true ->
                  NewMap = #{name => maps:get(name, Entry), balance => NewBalance},
                  timer:sleep(4000),
                  MainId ! {self(), {customer_signal, maps:get(name, Entry), maps:get(balance, Entry), "All loan amount is requested"}}
              end
          end;
        true ->
          MainId ! {self(), {display_customer, BankName, RandomAmount, maps:get(name, Entry)}},
          Bid ! {self(), {request, RandomAmount, maps:get(name, Entry)}},
          Status = listen(),

          case Status == "Approves" of
            false ->
              NewMap = maps:remove(BankName, BankMap),
              NewList = lists:delete(EachBank, Banks),
              request_loan(Entry, NewList, NewMap, MainId);
            true ->
              NewMap = #{name => maps:get(name, Entry), balance => NewBalance},
              request_loan(NewMap, Banks, BankMap, MainId)
          end
      end;
    true ->
      timer:sleep(4000),
      MainId ! {self(), {customer_signal, maps:get(name, Entry), maps:get(balance, Entry), "No more Banks left to request"}}
  end.

listen() ->
  receive
    {Sender, {Status}} ->
      Status
  end.