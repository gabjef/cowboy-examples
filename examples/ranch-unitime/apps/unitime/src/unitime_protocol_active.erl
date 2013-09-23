-module(unitime_protocol_active).
-behaviour(ranch_protocol).

-export([start_link/4, init/4]).

start_link(Ref, Socket, Transport, Opts) ->
    Pid = spawn_link(?MODULE, init, [Ref, Socket, Transport, Opts]),
    {ok, Pid}.

init(Ref, Socket, Transport, _Opts) ->
    ok = ranch:accept_ack(Ref),
    Transport:setopts(Socket, [{active, once}]),
    loop(Socket, Transport).

loop(Socket, Transport) ->
    receive
        {tcp, Socket, Data} ->
            Transport:send(Socket, Data),
            ok = Transport:setopts(Socket, [{active, once}]),
            loop(Socket, Transport);
        {tcp_closed, Socket} ->
            ok;
        {tcp_error, Socket, Reason} ->
            error_logger:error_msg("TCP error ~p", Reason)
    end.
