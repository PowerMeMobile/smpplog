-module(smpplog_app).

-behaviour(application).

%% application callbacks
-export([start/2, stop/1]).

-include("application_spec.hrl").

%% ===================================================================
%% application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    smpplog_sup:start_link().

stop(_State) ->
    ok.
