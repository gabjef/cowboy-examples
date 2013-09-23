-module(welcome_middleware).
-behaviour(cowboy_middleware).

-export([execute/2]).

execute(Req, Env) ->
    {Path, Req} = cowboy_req:path(Req),
    
    error_logger:info_msg("~p", [Path]),
    NewPath =
        case re:run(Path, "/$") of
            {match, _} ->
                << Path/binary, <<"index.html">>/binary >>;
            _ ->
                Path
        end,
        
    error_logger:info_msg("~p", [cowboy_req:set([{path, NewPath}], Req)]),  
    {ok, cowboy_req:set([{path, NewPath}], Req), Env}.
