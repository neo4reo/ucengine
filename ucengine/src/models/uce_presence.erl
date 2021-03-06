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
-module(uce_presence).

-author('tbomandouki@af83.com').

-export([add/2,
         all/1,
         get/2,
         delete/2,
         update/2,
         exists/2,
         check/3,
         assert/3,
         join/3,
         leave/3]).

-include("uce.hrl").

add(Domain, #uce_presence{id=none}=Presence) ->
    add(Domain, Presence#uce_presence{id=utils:random()});
add(Domain, #uce_presence{last_activity=0}=Presence) ->
    add(Domain, Presence#uce_presence{last_activity=utils:now()});
add(Domain, #uce_presence{timeout=0}=Presence) ->
    add(Domain, Presence#uce_presence{timeout=config:get(presence_timeout)});
add(Domain, #uce_presence{}=Presence) ->
    (db:get(?MODULE, Domain)):add(Domain, Presence).

get(Domain, Id) ->
    (db:get(?MODULE, Domain)):get(Domain, Id).

all(Domain) ->
    (db:get(?MODULE, Domain)):all(Domain).

delete(Domain, Id) ->
    case exists(Domain, Id) of
        false ->
            throw({error, not_found});
        true ->
            (db:get(?MODULE, Domain)):delete(Domain, Id)
    end.

update(Domain, #uce_presence{id=Id}=Presence) ->
    case exists(Domain, Id) of
        false ->
            throw({error, not_found});
        true ->
            (db:get(?MODULE, Domain)):update(Domain, Presence)
    end.

exists(Domain, Id) ->
    case catch get(Domain, Id) of
        {error, not_found} ->
            false;
        {error, Reason} ->
            throw({error, Reason});
        {ok, _} ->
            true
    end.

assert(Domain, Uid, Sid) ->
    case check(Domain, Uid, Sid) of
        {ok, true} ->
            {ok, true};
        {ok, false} ->
            throw({error, unauthorized})
    end.

check(Domain, Uid, Sid) ->
    {ok, Presence} = uce_presence:get(Domain, Sid),
    case Presence#uce_presence.user of
        Uid ->
            uce_presence:update(Domain, Presence#uce_presence{last_activity=utils:now()}),
            {ok, true};
        _OtherUser ->
            {ok, false}
    end.

join(Domain, Sid, Meeting) ->
    {ok, Presence} = (db:get(?MODULE, Domain)):get(Domain, Sid),
    case lists:member(Meeting, Presence#uce_presence.meetings) of
        true ->
            {ok, updated};
        false ->
            Meetings = [Meeting|Presence#uce_presence.meetings],
            (db:get(?MODULE, Domain)):update(Domain, Presence#uce_presence{meetings=Meetings})
    end.

leave(Domain, Sid, Meeting) ->
    {ok, Record} = (db:get(?MODULE, Domain)):get(Domain, Sid),
    Meetings = lists:delete(Meeting, Record#uce_presence.meetings),
    (db:get(?MODULE, Domain)):update(Domain, Record#uce_presence{meetings=Meetings}).
