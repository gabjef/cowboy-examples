-module(unitime_protocol).
-behaviour(ranch_protocol).

-compile(export_all).

-export([start_link/4, init/4]).

start_link(Ref, Socket, Transport, Opts) ->
    Pid = spawn_link(?MODULE, init, [Ref, Socket, Transport, Opts]),
    {ok, Pid}.

init(Ref, Socket, Transport, _Opts = []) ->
    ok = ranch:accept_ack(Ref),
    loop(Socket, Transport).

loop(Socket, Transport) ->
    case Transport:recv(Socket, 0, 5000) of
        {ok, Data} ->
            Response = handle_request(chomp(Data, <<>>)),
            Transport:send(Socket, <<Response/binary, $\n>>),
            loop(Socket, Transport);
        _ ->
            ok = Transport:close(Socket)
    end.

chomp(<<>>, Result) ->
    Result;
chomp(<<$\n>>, Result) ->
    Result;
chomp(<<$\n, _>>, Result) ->
    Result;
chomp(<<B, Remain/binary>>, Result) ->
    chomp(Remain, <<Result/binary, B>>).

handle_request(<<"get">>) ->
    format_date(calendar:universal_time());
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
    format_date(add_hour(calendar:universal_time(), Offset)).

add_hour(Date, Hours) ->
    Sec = calendar:datetime_to_gregorian_seconds(Date),
    calendar:gregorian_seconds_to_datetime(Sec + Hours * 60 * 60).

format_date({{Y, Mo, D}, {H, Mi, S}}) ->
    list_to_binary(
        io_lib:format("~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B",
                     [Y, Mo, D, H, Mi, S])).
