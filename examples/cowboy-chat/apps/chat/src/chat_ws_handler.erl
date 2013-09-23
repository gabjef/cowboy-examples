-module(chat_ws_handler).
-behaviour(cowboy_websocket_handler).

-export([init/3]).
-export([websocket_init/3,
         websocket_handle/3,
         websocket_info/3,
         websocket_terminate/3]).

-record(state, {
          nick = ""
         }).

%% cowboy_http_handler
init({tcp, http}, Req, Opts) ->
    {upgrade, protocol, cowboy_websocket}.

websocket_init(TransportName, Req, _Opts) ->
    {ok, Req, #state{}}.

%% join <nick>
%% say <msg>
websocket_handle({text, Msg}, Req, State) ->
    [Cmd, Param] = string:tokens(binary_to_list(Msg), "\n"),
    case Cmd of
        "join" ->
            chat_room:join(Param, self()),
            {ok, Req, State#state{nick = Param}};
        "say" ->
            chat_room:say(State#state.nick, Param),
            {ok, Req, State}
    end.

websocket_info({joined, Nick}, Req, State) ->
    {reply, {text, said(Nick, "I am here")}, Req, State};
websocket_info({said, Nick, Msg}, Req, State) ->
    {reply, {text, said(Nick, Msg)}, Req, State};
websocket_info(_Info, Req, State) ->
    {ok, Req, State}.

websocket_terminate(_Reason, _Req, State) ->
    chat_room:leave(State#state.nick),
    ok.

said(Nick, Msg) ->
    << (list_to_binary(Nick))/binary, $\n, (list_to_binary(Msg))/binary>>.
