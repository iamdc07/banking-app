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
%%-import(maps, [get/2]).

%% API
-export([create_customer_account/0]).

create_customer_account() ->
  receive
    {Sender, {Name, Amount}} ->
      Entry = #{name => Name, balance => Amount},
      fwrite("~p ~p~n", [maps:get(name, Entry), maps:get(balance, Entry)])
  end.
