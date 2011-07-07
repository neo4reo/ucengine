%%
%%  U.C.Engine - Unified Colloboration Engine
%%  Copyright (C) 2011 af83
%%
%%  This program is free software: you can redistribute it and/or modify
%%  it under the terms of the GNU Affero General Public License as published by
%%  the Free Software Foundation, either version 3 of the License, or
%%  (at your option) any later version.
%%
%%  This program is distributed in the hope that it will be useful,
%%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%  GNU Affero General Public License for more details.
%%
%%  You should have received a copy of the GNU Affero General Public License
%%  along with this program.  If not, see <http://www.gnu.org/licenses/>.
%%
-module(mnesia_db).

-author('victor.goya@af83.com').

-export([init/2,
         drop/0,
         terminate/0]).

-include("uce.hrl").

call_mnesia_modules(Fun) ->
    lists:foreach(fun(Module) ->
                          (list_to_atom(lists:concat([Module, "_mnesia"]))):Fun()
                  end,
                  [uce_role, uce_user, uce_meeting, uce_file, uce_event, uce_infos]).

init(_Domain, undefined) ->
    call_mnesia_modules(init).

drop() ->
    call_mnesia_modules(drop),
    ok.

terminate() ->
    ok.
