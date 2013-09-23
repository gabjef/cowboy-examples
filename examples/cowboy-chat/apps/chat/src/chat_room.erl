-module(chat_room).
-behaviour(gen_server).
-define(SERVER, ?MODULE).

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_link/0, join/2, leave/1, say/2]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {
          buddies = []
         }).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

join(Nick, WS) ->
    gen_server:call(?SERVER, {join, Nick, WS}).

leave(Nick) ->
    gen_server:call(?SERVER, {leave, Nick}).

say(Nick, Msg) ->
    gen_server:call(?SERVER, {say, Nick, Msg}).

%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------

init(Args) ->
    {ok, #state{}}.

handle_call({join, Nick, WS}, _From, #state{buddies = Buddies} = State) ->
    case lists:keyfind(Nick, 1, Buddies) of
        false ->
            NewBuddies = [{Nick, WS} | Buddies],
            
            [WS ! {joined, Nick} || {_, WS} <- Buddies],
            {reply, ok, State#state{buddies = NewBuddies}};
        _ ->
            {reply, already_here, State}
    end;

handle_call({leave, Nick}, _From, #state{buddies = Buddies} = State) ->
    case lists:keyfind(Nick, 1, Buddies) of
        false ->
            {reply, ok, State};
        {_, WS} ->
            NewBuddies = Buddies -- [{Nick, WS}],
            
            [WS ! {left, Nick} || {_, WS} <- NewBuddies],
            {reply, ok, State#state{buddies = NewBuddies}}
    end;

handle_call({say, Nick, Msg}, _From, #state{buddies = Buddies} = State) ->
    [WS ! {said, Nick, Msg} 
        || {OtherNick, WS} <- Buddies, OtherNick =/= Nick],
    {reply, ok, State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------

