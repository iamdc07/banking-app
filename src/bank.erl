%%%-------------------------------------------------------------------
%%% @author dc
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. Jun 2019 13:12
%%%-------------------------------------------------------------------
-module(bank).
-author("dc").

% Imports
-import(io, [fwrite/1, fwrite/2]).

%% API
-export([create_banks/0, receive_request/2]).


create_banks() ->
  receive
    {Sender, {Name, Amount}} ->
      Entry = #{bankname => Name, balance => Amount},
      timer:sleep(3000),
      receive_request(Entry, Sender)
  end.

receive_request(Entry, MainId) ->
  receive
    {Sender, {request, Amount, CustomerName}} ->
      Balance = maps:get(balance, Entry),
      NewBalance = Balance - Amount,

      case NewBalance > 0 of
        false ->
          case NewBalance == 0 of
            false ->
              Sender ! {self(), {"Declines"}},
              MainId ! {self(), {display_bank, maps:get(bankname, Entry), Amount, "Declines", CustomerName, NewBalance}},
              receive_request(Entry, MainId);
            true ->
              Sender ! {self(), {"Declines"}},
              MainId ! {self(), {display_bank, maps:get(bankname, Entry), Amount, "Declines", CustomerName, NewBalance}},
              MainId ! {self(), {bank_signal, maps:get(bankname, Entry), maps:get(balance, Entry), "No Bank Balance"}},
              receive_request(Entry, MainId)
          end;
        true ->
          NewMap = #{bankname => maps:get(bankname, Entry), balance => NewBalance},
          Sender ! {self(), {"Approves"}},
          MainId ! {self(), {display_bank, maps:get(bankname, Entry), Amount, "Approves", CustomerName, NewBalance}},
          receive_request(NewMap, MainId)
      end
  end.