%%%-------------------------------------------------------------------
%% @doc erlang_and_otp_in_action public API
%% @end
%%%-------------------------------------------------------------------

-module(erlang_and_otp_in_action_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
    erlang_and_otp_in_action_sup:start_link().

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================