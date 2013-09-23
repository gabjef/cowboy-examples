-module(unitime_protocol).
-behaviour(ranch_protocol).

-export([start_link/4, init/4]).
-export([handle_request/1]).

start_link(Ref, Socket, Transport, Opts) ->
    Pid = spawn_link(?MODULE, init, [Ref, Socket, Transport, Opts]),
    {ok, Pid}.

init(Ref, Socket, Transport, _Opts = []) ->
    ok = ranch:accept_ack(Ref),
    loop(Socket, Transport).

loop(Socket, Transport) ->
    case Transport:recv(Socket, 0, 5000) of
        {ok, Data} ->
            Request = unitime_lib:chomp(Data),
            Response = handle_request(Request),
            Transport:send(Socket, <<Response/binary, $\n>>),
            loop(Socket, Transport);
        _ ->
            ok = Transport:close(Socket)
    end.

handle_request(<<"get">>) ->
    unitime_lib:format_date(calendar:universal_time());
handle_request(<<"get ", TimeZone/binary>>) ->
    Offset =
        case TimeZone of
            <<"bst">> ->
                1;
            <<"cet">> ->
                2;
            <<"edt">> ->    %% New York
                -4
        end,
    Date = unitime_lib:add_hour(calendar:universal_time(), Offset),
    unitime_lib:format_date(Date).
