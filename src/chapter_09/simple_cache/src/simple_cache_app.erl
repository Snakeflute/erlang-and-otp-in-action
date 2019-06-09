%%%-------------------------------------------------------------------
%% @doc simple_cache public API
%% @end
%%%-------------------------------------------------------------------

-module(simple_cache_app).

-behaviour(application).

-define(WAIT_FOR_RESOURCES, 2500).

%% Application callbacks
-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
    ok = ensure_contract(),
    resource_discovery:add_local_resource(simple_cache, node()),
    resource_discovery:add_target_resource_type(simple_cache),
    resource_discovery:trade_resources(),
    timer:sleep(?WAIT_FOR_RESOURCES),
    simple_cache_store:init(),
    case simple_cache_sup:start_link() of
        {ok, Pid} ->
            simple_cache_event_logger:add_handler(),
            {ok, Pid};
        Other ->
            {error, Other}
    end.

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================

ensure_contract() ->
    DefaultNodes = ['contract1@localhost', 'contract2@localhost'],
    case get_env(simple_cache, contract_nodes, DefaultNodes) of
        [] ->
            {error, no_contract_nodes};
        ContractNodes ->
            ensure_contract(ContractNodes)
    end.

ensure_contract(ContactNodes) ->
    Answering = [N || N <- ContactNodes, net_adm:ping(N) =:= pong],
    case Answering of
        [] ->
            {error, no_contact_nodes_reachable};
        _ ->
            DefaultTime = 6000,
            WaitTime = get_env(simple_cache, wait_time, DefaultTime),
            wait_for_nodes(length(Answering), WaitTime)
    end.

wait_for_nodes(MinNodes, WaitTime) ->
    Slices = 10,
    SliceTime = round(WaitTime / Slices),
    wait_for_nodes(MinNodes, SliceTime, Slices).

wait_for_nodes(_MinNodes, _SliceTime, 0) ->
    ok;
wait_for_nodes(MinNodes, SliceTime, Iterations) ->
    case length(nodes()) > MinNodes of
        true ->
            ok;
        false ->
            timer:sleep(SliceTime),
            wait_for_nodes(MinNodes, SliceTime, Iterations - 1)
    end.

get_env(AppName, Key, Default) ->
    case application:get_env(AppName, Key) of
        undefined ->
            Default;
        {ok, Value} ->
            Value
    end.