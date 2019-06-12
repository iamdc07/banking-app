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
-export([create_banks/0]).


create_banks () ->
  receive
    {Sender, {Name, Amount}} ->
      Entry = #{bankname => Name, balance => Amount}
%%      fwrite("~p ~p~n", [maps:get(bankname, Entry), maps:get(balance, Entry)])
  end.
