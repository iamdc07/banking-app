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
-export([create_customer_account/0]).

create_customer_account() ->
  receive
    {Sender, {Name, Amount, Banks}} ->
%%      fwrite("~w~n", [Banks]),
%%      rand:uniform()
%%      NoOfBanks = length(Banks),
      fwrite("~w~n", [Banks]),
%%      io:format("~p Length is ~p~n", [Banks, length(Banks)]),
      Entry = #{name => Name, balance => Amount},
      fwrite("~p ~p~n", [maps:get(name, Entry), maps:get(balance, Entry)])
  end.

%%request_loan (Entry, Banks) ->
%%  case Data == [] of
%%    false ->
%%      Cid = spawn(bank, create_banks, []),
%%      [TheHead | TheTail] = Entry,
%%      {BankName, Amount} = TheHead,
%%      Cid ! {self(), {BankName, Amount}},
%%      request_loan(TheTail, Banks);
%%    true ->
%%      Data = []
%%  end.