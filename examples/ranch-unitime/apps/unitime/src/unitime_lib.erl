-module(unitime_lib).

-export([chomp/1, add_hour/2, format_date/1]).

chomp(Data) ->
    chomp(Data, <<>>).

chomp(<<>>, Result) ->
    Result;
chomp(<<$\n>>, Result) ->
    Result;
chomp(<<$\n, _>>, Result) ->
    Result;
chomp(<<B, Remain/binary>>, Result) ->
    chomp(Remain, <<Result/binary, B>>).

add_hour(Date, Hours) ->
    Sec = calendar:datetime_to_gregorian_seconds(Date),
    calendar:gregorian_seconds_to_datetime(Sec + Hours * 60 * 60).

format_date({{Y, Mo, D}, {H, Mi, S}}) ->
    list_to_binary(
        io_lib:format("~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B",
                     [Y, Mo, D, H, Mi, S])).
