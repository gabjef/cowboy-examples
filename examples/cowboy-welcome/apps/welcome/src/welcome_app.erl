-module(welcome_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    Dispatch = cowboy_router:compile([{'_',
        [{"/[...]", cowboy_static, [
            {directory, {priv_dir, welcome, []}},
            {mimetypes, {fun mimetypes:path_to_mimes/2, default}}
            ]}
        ]
    }]),
    cowboy:start_http(welcome, 10, [{port, 8080}], [
        {env, [{dispatch, Dispatch}]},
        {middlewares, [welcome_middleware, cowboy_router, cowboy_handler]}
    ]),

    welcome_sup:start_link().

stop(_State) ->
    cowboy:stop_listener(welcome),
    ok.
